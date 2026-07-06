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
            LimiarAIDiagnostics.log("screen_time_daily_monitor_scheduled", values: [
                "activity": "limiar.daily",
                "start": "05:00",
                "end": "23:59"
            ])
        } catch {
            LimiarAIDiagnostics.log("screen_time_daily_monitor_failed", values: ["error": "\(error)"])
        }
    }

    func scheduleShieldReapplicationForNextMorning(now: Date = Date(), calendar: Calendar = .current) {
        let nextStart = Self.nextMorningCycleStart(after: now, calendar: calendar)
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: nextStart)
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        do {
            try DeviceActivityCenter().startMonitoring(.limiarUnlockWindow, during: schedule)
            LimiarAIDiagnostics.log("screen_time_reapply_monitor_scheduled", values: [
                "activity": "limiar.unlockWindow",
                "nextStart": "\(nextStart)"
            ])
        } catch {
            LimiarAIDiagnostics.log("screen_time_reapply_monitor_failed", values: ["error": "\(error)"])
        }
    }

    func stopUnlockMonitoring() {
        DeviceActivityCenter().stopMonitoring([.limiarUnlockWindow])
    }

    private static func nextMorningCycleStart(after date: Date, calendar: Calendar) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let fiveToday = calendar.date(byAdding: .hour, value: 5, to: dayStart) ?? dayStart
        if date < fiveToday {
            return fiveToday
        }
        return calendar.date(byAdding: .day, value: 1, to: fiveToday) ?? fiveToday
    }
}

extension DeviceActivityName {
    static var limiarDaily: Self { Self("limiar.daily") }
    static var limiarUnlockWindow: Self { Self("limiar.unlockWindow") }
}
