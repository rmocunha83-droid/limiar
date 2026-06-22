import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let policyStore = ExtensionPolicyStore()
    private let settingsStore = ManagedSettingsStore(named: ManagedSettingsStore.Name("Limiar"))

    override func intervalDidEnd(for activity: DeviceActivityName) {
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
        settingsStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        settingsStore.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        settingsStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
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

    func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: "familySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection()
        }
        return selection
    }
}
