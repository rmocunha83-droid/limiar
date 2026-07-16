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
        // ciclo escolhido. Apagá-la aqui faria um re-registro do monitor pausar
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

        if policyStore.hasCompletedPauseInCurrentCycle() {
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
    private static let defaultCycleStartHour = 5
    private static let cycleStartHourKey = "cycleStartHour"
    private static let activeCycleStartHourKey = "cycleStartHour.active"
    private static let cycleStartHourEffectiveAtKey = "cycleStartHour.effectiveAt"
    private static let validCycleStartHours = Set([5, 13, 19])

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

    func hasCompletedPauseInCurrentCycle(now: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Bool {
        guard let completedAt = loadMorningPauseCompletedAt() else { return false }
        return completedAt >= currentCycleStart(now: now, calendar: calendar)
    }

    private func currentCycleStart(now: Date, calendar: Calendar) -> Date {
        let hour = effectiveCycleStartHour(now: now)
        let todayStart = calendar.startOfDay(for: now)
        let boundaryToday = calendar.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: todayStart
        ) ?? todayStart
        if now >= boundaryToday {
            return boundaryToday
        }
        return calendar.date(byAdding: .day, value: -1, to: boundaryToday) ?? boundaryToday
    }

    private func effectiveCycleStartHour(now: Date) -> Int {
        let selected = normalizedHour(defaults.object(forKey: Self.cycleStartHourKey) as? Int)
        let active = normalizedHour(defaults.object(forKey: Self.activeCycleStartHourKey) as? Int)
        guard let effectiveAt = defaults.object(forKey: Self.cycleStartHourEffectiveAtKey) as? Date,
              now < effectiveAt
        else {
            return selected
        }
        return active
    }

    private func normalizedHour(_ hour: Int?) -> Int {
        guard let hour, Self.validCycleStartHours.contains(hour) else {
            return Self.defaultCycleStartHour
        }
        return hour
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
