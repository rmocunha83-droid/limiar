import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let policyStore = ExtensionPolicyStore()
    private let settingsStore = ManagedSettingsStore(named: ManagedSettingsStore.Name("Limiar"))

    override func intervalDidEnd(for activity: DeviceActivityName) {
        if activity == .limiarUnlockWindow {
            policyStore.clearMorningPauseCompletedAt()
        }
        reapplyShieldIfNeeded()
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        if activity == .limiarDaily {
            policyStore.clearMorningPauseCompletedAt()
        }
        reapplyShieldIfNeeded()
    }

    private func reapplyShieldIfNeeded() {
        guard policyStore.loadPauseAccessEnabled() else {
            settingsStore.clearAllSettings()
            return
        }

        guard policyStore.loadBlockingEnabled() else {
            settingsStore.clearAllSettings()
            return
        }

        if policyStore.hasCompletedMorningPauseToday() {
            settingsStore.clearAllSettings()
            return
        }

        let selection = policyStore.loadSelection()
        clearHiddenAppRestrictions()
        settingsStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        settingsStore.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        settingsStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    private func clearHiddenAppRestrictions() {
        settingsStore.application.blockedApplications = nil
        settingsStore.application.denyAppInstallation = nil
        settingsStore.application.denyAppRemoval = nil
    }
}

private struct ExtensionPolicyStore {
    private static let morningTimeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
    private static var morningCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = morningTimeZone
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

    func clearMorningPauseCompletedAt() {
        defaults.removeObject(forKey: "morningPauseCompletedAt")
        defaults.synchronize()
    }

    func hasCompletedMorningPauseToday(now: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Bool {
        guard let completedAt = loadMorningPauseCompletedAt() else { return false }
        return completedAt >= currentMorningCycleStart(now: now, calendar: calendar)
    }

    private func currentMorningCycleStart(now: Date, calendar: Calendar) -> Date {
        let todayStart = calendar.startOfDay(for: now)
        let fiveToday = calendar.date(byAdding: .hour, value: 5, to: todayStart) ?? todayStart
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
    static var limiarUnlockWindow: Self { Self("limiar.unlockWindow") }
}
