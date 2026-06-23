import Foundation
import FamilyControls

struct ScreenTimePolicyStore {
    static let appGroupIdentifier = "group.com.romeucunha.Limiar"

    private enum Key {
        static let onboarding = "onboarding"
        static let profile = "faithProfile"
        static let unlockDuration = "unlockDuration"
        static let blockingEnabled = "blockingEnabled"
        static let selection = "familySelection"
        static let unlockedUntil = "unlockedUntil"
        static let history = "readingHistory"
        static let favorites = "favoritePassages"
        static let screenTimeAuthorized = "screenTimeAuthorized"
        static let recentPassageIDs = "recentPassageIDs"
        static let recentAIReflections = "recentAIReflections"
        static let valueDemoSeen = "valueDemoSeen"
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupIdentifier) ?? .standard
    }

    func loadOnboardingState() -> Bool {
        defaults.bool(forKey: Key.onboarding)
    }

    func saveOnboardingState(_ value: Bool) {
        defaults.set(value, forKey: Key.onboarding)
    }

    func loadFaithProfile() -> UserFaithProfile? {
        load(UserFaithProfile.self, key: Key.profile)
    }

    func saveFaithProfile(_ profile: UserFaithProfile) {
        save(profile, key: Key.profile)
    }

    func loadUnlockDuration() -> Int {
        let saved = defaults.integer(forKey: Key.unlockDuration)
        return saved == 0 ? 30 : saved
    }

    func saveUnlockDuration(_ minutes: Int) {
        defaults.set(minutes, forKey: Key.unlockDuration)
    }

    func loadBlockingEnabled() -> Bool {
        defaults.object(forKey: Key.blockingEnabled) as? Bool ?? true
    }

    func saveBlockingEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Key.blockingEnabled)
    }

    func loadSelection() -> FamilyActivitySelection {
        load(FamilyActivitySelection.self, key: Key.selection) ?? FamilyActivitySelection()
    }

    func saveSelection(_ selection: FamilyActivitySelection) {
        save(selection, key: Key.selection)
    }

    func loadUnlockedUntil() -> Date? {
        defaults.object(forKey: Key.unlockedUntil) as? Date
    }

    func saveUnlockedUntil(_ date: Date?) {
        defaults.set(date, forKey: Key.unlockedUntil)
    }

    func loadHistory() -> [ReadingHistoryItem] {
        load([ReadingHistoryItem].self, key: Key.history) ?? []
    }

    func saveHistory(_ history: [ReadingHistoryItem]) {
        save(history, key: Key.history)
    }

    func loadFavorites() -> [FavoritePassageItem] {
        load([FavoritePassageItem].self, key: Key.favorites) ?? []
    }

    func saveFavorites(_ favorites: [FavoritePassageItem]) {
        save(favorites, key: Key.favorites)
    }

    func loadScreenTimeAuthorized() -> Bool {
        defaults.object(forKey: Key.screenTimeAuthorized) as? Bool ?? false
    }

    func saveScreenTimeAuthorized(_ value: Bool) {
        defaults.set(value, forKey: Key.screenTimeAuthorized)
    }

    func loadRecentPassageIDs() -> [String] {
        load([String].self, key: Key.recentPassageIDs) ?? []
    }

    func saveRecentPassageIDs(_ ids: [String]) {
        save(ids, key: Key.recentPassageIDs)
    }

    func loadRecentAIReflections() -> [RecentAIReflectionDigest] {
        load([RecentAIReflectionDigest].self, key: Key.recentAIReflections) ?? []
    }

    func saveRecentAIReflections(_ reflections: [RecentAIReflectionDigest]) {
        save(reflections, key: Key.recentAIReflections)
    }

    func loadValueDemoSeen() -> Bool {
        defaults.bool(forKey: Key.valueDemoSeen)
    }

    func saveValueDemoSeen(_ value: Bool) {
        defaults.set(value, forKey: Key.valueDemoSeen)
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
