import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

@MainActor
struct ScreenTimeController {
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("Limiar"))
    private let eventLog = LimiarEventLog(source: "app")

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    func applyShield(selection: FamilyActivitySelection) {
        clearHiddenAppRestrictions()
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        eventLog.log("shield_applied", [
            "apps": "\(selection.applicationTokens.count)",
            "categories": "\(selection.categoryTokens.count)",
            "webDomains": "\(selection.webDomainTokens.count)"
        ])
        scheduleDailyMonitoring()
    }

    func clearShield() {
        store.clearAllSettings()
        eventLog.log("shield_cleared")
    }

    func clearHiddenAppRestrictions() {
        store.application.blockedApplications = nil
        store.application.denyAppInstallation = nil
        store.application.denyAppRemoval = nil
    }

    func scheduleDailyMonitoring() {
        let center = DeviceActivityCenter()
        var start = DateComponents()
        start.hour = 5
        start.minute = 0

        var end = DateComponents()
        end.hour = 23
        end.minute = 59

        let schedule = DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: true
        )

        // startMonitoring substitui o schedule existente para o mesmo nome.
        // Evitar stop/start reduz callbacks artificiais dentro do intervalo
        // ativo e preserva a conclusão registrada para o ciclo atual.
        do {
            try center.startMonitoring(.limiarDaily, during: schedule)
            eventLog.log("daily_monitor_scheduled", ["start": "05:00", "end": "23:59"])
        } catch {
            eventLog.log("daily_monitor_failed", ["error": "\(error)"])
        }
    }

    func scheduleShieldReapplicationForNextMorning(now: Date = Date()) {
        scheduleDailyMonitoring()
    }
}

extension DeviceActivityName {
    static var limiarDaily: Self { Self("limiar.daily") }
}
