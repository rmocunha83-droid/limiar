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
        clearHiddenAppRestrictions()
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        scheduleDailyMonitoring()
    }

    func clearShield() {
        store.clearAllSettings()
    }

    func clearHiddenAppRestrictions() {
        store.application.blockedApplications = nil
        store.application.denyAppInstallation = nil
        store.application.denyAppRemoval = nil
    }

    func scheduleDailyMonitoring() {
        let center = DeviceActivityCenter()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 5, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(.limiarDaily, during: schedule)
        } catch {
            LimiarAIDiagnostics.log("screen_time_daily_monitor_failed", values: ["error": "\(error)"])
        }
    }

    func stopLegacyUnlockMonitoring() {
        DeviceActivityCenter().stopMonitoring([.limiarUnlockWindow])
    }
}

extension DeviceActivityName {
    static var limiarDaily: Self { Self("limiar.daily") }
    static var limiarUnlockWindow: Self { Self("limiar.unlockWindow") }
}
