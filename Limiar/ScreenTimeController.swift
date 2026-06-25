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
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        try? center.startMonitoring(.limiarDaily, during: schedule)
    }

    func scheduleUnlockExpiration(at date: Date) {
        let center = DeviceActivityCenter()
        let calendar = Calendar.current
        let now = Date()
        guard date > now else {
            center.stopMonitoring([.limiarUnlockWindow])
            applyShield(selection: ScreenTimePolicyStore().loadSelection())
            return
        }

        center.stopMonitoring([.limiarUnlockWindow])

        let start = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        let end = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let schedule = DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: false
        )

        try? center.startMonitoring(.limiarUnlockWindow, during: schedule)
    }
}

extension DeviceActivityName {
    static var limiarDaily: Self { Self("limiar.daily") }
    static var limiarUnlockWindow: Self { Self("limiar.unlockWindow") }
}
