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
        var start = DateComponents()
        start.calendar = ScreenTimePolicyStore.morningCalendar
        start.timeZone = ScreenTimePolicyStore.morningTimeZone
        start.hour = 5
        start.minute = 0

        var end = DateComponents()
        end.calendar = ScreenTimePolicyStore.morningCalendar
        end.timeZone = ScreenTimePolicyStore.morningTimeZone
        end.hour = 23
        end.minute = 59

        let schedule = DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: true
        )

        do {
            try center.startMonitoring(.limiarDaily, during: schedule)
            LimiarAIDiagnostics.log("screen_time_daily_monitor_scheduled", values: [
                "activity": "limiar.daily",
                "start": "05:00",
                "end": "23:59"
            ])
        } catch {
            LimiarAIDiagnostics.log("screen_time_daily_monitor_failed", values: ["error": "\(error)"])
        }
    }

    func scheduleShieldReapplicationForNextMorning(now: Date = Date()) {
        let nextStart = ScreenTimePolicyStore.nextMorningCycleStart(after: now)
        scheduleDailyMonitoring()
        stopUnlockMonitoring()
        LimiarAIDiagnostics.log("screen_time_reapply_uses_daily_monitor", values: [
            "activity": "limiar.daily",
            "nextStart": "\(nextStart)",
            "timeZone": ScreenTimePolicyStore.morningTimeZone.identifier
        ])
    }

    func stopUnlockMonitoring() {
        DeviceActivityCenter().stopMonitoring([.limiarUnlockWindow])
    }
}

extension DeviceActivityName {
    static var limiarDaily: Self { Self("limiar.daily") }
    static var limiarUnlockWindow: Self { Self("limiar.unlockWindow") }
}
