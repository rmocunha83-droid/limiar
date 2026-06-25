import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let policyStore = ExtensionPolicyStore()
    private let settingsStore = ManagedSettingsStore(named: ManagedSettingsStore.Name("Limiar"))

    override func intervalDidEnd(for activity: DeviceActivityName) {
        if activity == .limiarUnlockWindow {
            policyStore.saveUnlockedUntil(nil)
        }
        reapplyShieldIfNeeded()
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        reapplyShieldIfNeeded()
    }

    private func reapplyShieldIfNeeded() {
        guard policyStore.loadBlockingEnabled() else {
            settingsStore.clearAllSettings()
            return
        }

        if let unlockedUntil = policyStore.loadUnlockedUntil(), unlockedUntil > Date() {
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
    private let defaults = UserDefaults(suiteName: "group.com.romeucunha.Limiar") ?? .standard

    func loadBlockingEnabled() -> Bool {
        defaults.object(forKey: "blockingEnabled") as? Bool ?? true
    }

    func loadUnlockedUntil() -> Date? {
        defaults.object(forKey: "unlockedUntil") as? Date
    }

    func saveUnlockedUntil(_ date: Date?) {
        defaults.set(date, forKey: "unlockedUntil")
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
    static var limiarUnlockWindow: Self { Self("limiar.unlockWindow") }
}
