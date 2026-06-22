import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

@MainActor
struct ScreenTimeController {
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("Limiar"))

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    func applyShield(selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    func clearShield() {
        store.clearAllSettings()
    }

    func scheduleDailyMonitoring() {
        let center = DeviceActivityCenter()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        try? center.startMonitoring(.limiarDaily, during: schedule)
    }
}

extension DeviceActivityName {
    static var limiarDaily: Self { Self("limiar.daily") }
}
