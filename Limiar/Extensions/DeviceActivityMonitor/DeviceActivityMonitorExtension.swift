import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let policyStore = ExtensionPolicyStore()
    private let settingsStore = ManagedSettingsStore(named: ManagedSettingsStore.Name("Limiar"))
    private let eventLog = LimiarEventLog(source: "monitor")

    override func intervalDidStart(for activity: DeviceActivityName) {
        eventLog.log("interval_did_start", ["activity": activity.rawValue])
        // A conclusão expira naturalmente pela comparação com o início do
        // ciclo das 5h. Apagá-la aqui faria um re-registro do monitor pausar
        // novamente os apps no mesmo dia.
        reapplyShieldIfNeeded()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        eventLog.log("interval_did_end", ["activity": activity.rawValue])
        reapplyShieldIfNeeded()
    }

    private func reapplyShieldIfNeeded() {
        guard policyStore.loadPauseAccessEnabled() else {
            settingsStore.clearAllSettings()
            eventLog.log("shield_skipped", ["reason": "pause_access_disabled"])
            return
        }

        guard policyStore.loadBlockingEnabled() else {
            settingsStore.clearAllSettings()
            eventLog.log("shield_skipped", ["reason": "blocking_disabled"])
            return
        }

        if policyStore.hasCompletedMorningPauseToday() {
            settingsStore.clearAllSettings()
            eventLog.log("shield_skipped", ["reason": "pause_completed_today"])
            return
        }

        let selection = policyStore.loadSelection()
        clearHiddenAppRestrictions()
        settingsStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        settingsStore.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        settingsStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        eventLog.log("shield_reapplied", [
            "apps": "\(selection.applicationTokens.count)",
            "categories": "\(selection.categoryTokens.count)",
            "webDomains": "\(selection.webDomainTokens.count)"
        ])
    }

    private func clearHiddenAppRestrictions() {
        settingsStore.application.blockedApplications = nil
        settingsStore.application.denyAppInstallation = nil
        settingsStore.application.denyAppRemoval = nil
    }
}

private struct ExtensionPolicyStore {
    private static var morningCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private let defaults = UserDefaults(suiteName: "group.com.romeucunha.Limiar") ?? .standard

    func loadBlockingEnabled() -> Bool {
        defaults.object(forKey: "blockingEnabled") as? Bool ?? true
    }

    func loadPauseAccessEnabled() -> Bool {
        defaults.object(forKey: "pauseAccessEnabled") as? Bool ?? false
    }

    func loadMorningPauseCompletedAt() -> Date? {
        defaults.object(forKey: "morningPauseCompletedAt") as? Date
    }

    func hasCompletedMorningPauseToday(now: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Bool {
        guard let completedAt = loadMorningPauseCompletedAt() else { return false }
        return completedAt >= currentMorningCycleStart(now: now, calendar: calendar)
    }

    private func currentMorningCycleStart(now: Date, calendar: Calendar) -> Date {
        let todayStart = calendar.startOfDay(for: now)
        let fiveToday = calendar.date(
            bySettingHour: 5,
            minute: 0,
            second: 0,
            of: todayStart
        ) ?? todayStart
        if now >= fiveToday {
            return fiveToday
        }
        return calendar.date(byAdding: .day, value: -1, to: fiveToday) ?? fiveToday
    }

    func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: "familySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection()
        }
        return selection
    }
}

private extension DeviceActivityName {
    static var limiarDaily: Self { Self("limiar.daily") }
}
