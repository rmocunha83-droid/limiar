@preconcurrency import BackgroundTasks
import Foundation

/// Centraliza o contrato do BGAppRefresh. O sistema decide se e quando executa
/// a tarefa; por isso o foreground continua sendo o gatilho principal e a
/// geração ao vivo permanece como fallback final.
@MainActor
final class LimiarPrewarmCoordinator {
    static let shared = LimiarPrewarmCoordinator()
    static let taskIdentifier = "com.romeucunha.Limiar.prewarm"

    private weak var model: LimiarAppModel?
    private var didRegister = false
    private var activeRunID: UUID?
    private var activeOperation: Task<Void, Never>?

    private init() {}

    func attach(model: LimiarAppModel) {
        self.model = model
    }

    func register() {
        guard !didRegister else { return }
        didRegister = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                LimiarPrewarmCoordinator.shared.handle(refreshTask)
            }
        }
    }

    func schedule(now: Date = Date()) {
        guard ScreenTimePolicyStore().loadOnboardingState() else { return }

        let nextCycleStart = ScreenTimePolicyStore.nextCycleStart(after: now)
        let preferredStart = nextCycleStart.addingTimeInterval(-45 * 60)
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = max(now.addingTimeInterval(60), preferredStart)

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
        do {
            try BGTaskScheduler.shared.submit(request)
            LimiarAIDiagnostics.log(
                "prewarm_bg_scheduled",
                values: ["result": "submitted"],
                persistForDiagnostics: true
            )
        } catch {
            // BGAppRefresh é uma otimização oportunista. Falhar ao agendar não
            // afeta a sessão atual nem remove a geração ao vivo de segurança.
            LimiarAIDiagnostics.log(
                "prewarm_bg_scheduled",
                values: ["result": "failed"],
                persistForDiagnostics: true
            )
        }
    }

    private func handle(_ task: BGAppRefreshTask) {
        activeOperation?.cancel()

        let runID = UUID()
        let appModel = model ?? LimiarAppModel()
        activeRunID = runID

        task.expirationHandler = { [weak self, appModel] in
            Task { @MainActor in
                appModel.cancelPrewarmSession()
                self?.activeOperation?.cancel()
                self?.finish(
                    task,
                    runID: runID,
                    result: .cancelled,
                    success: false
                )
            }
        }

        activeOperation = Task { @MainActor [weak self, appModel] in
            let result = await appModel.runBackgroundPrewarm()
            guard !Task.isCancelled else {
                self?.finish(
                    task,
                    runID: runID,
                    result: .cancelled,
                    success: false
                )
                return
            }
            self?.finish(
                task,
                runID: runID,
                result: result,
                success: result.completedSuccessfully
            )
        }
    }

    private func finish(
        _ task: BGAppRefreshTask,
        runID: UUID,
        result: LimiarPrewarmResult,
        success: Bool
    ) {
        guard activeRunID == runID else { return }
        activeRunID = nil
        activeOperation = nil
        task.expirationHandler = nil
        LimiarAIDiagnostics.log(
            "prewarm_bg_run",
            values: ["result": result.rawValue],
            persistForDiagnostics: true
        )
        task.setTaskCompleted(success: success)
        schedule()
    }
}
