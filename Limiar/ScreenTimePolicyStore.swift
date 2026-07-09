import Foundation
import FamilyControls

struct ScreenTimePolicyStore {
    static let appGroupIdentifier = "group.com.romeucunha.Limiar"
    static let morningTimeZone = TimeZone.current
    static var morningCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = morningTimeZone
        return calendar
    }

    private enum Key {
        static let onboarding = "onboarding"
        static let profile = "faithProfile"
        static let blockingEnabled = "blockingEnabled"
        static let pauseAccessEnabled = "pauseAccessEnabled"
        static let selection = "familySelection"
        static let morningPauseCompletedAt = "morningPauseCompletedAt"
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

    func loadBlockingEnabled() -> Bool {
        defaults.object(forKey: Key.blockingEnabled) as? Bool ?? true
    }

    func saveBlockingEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Key.blockingEnabled)
    }

    func loadPauseAccessEnabled() -> Bool {
        defaults.object(forKey: Key.pauseAccessEnabled) as? Bool ?? false
    }

    func savePauseAccessEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Key.pauseAccessEnabled)
    }

    func loadSelection() -> FamilyActivitySelection {
        load(FamilyActivitySelection.self, key: Key.selection) ?? FamilyActivitySelection()
    }

    func saveSelection(_ selection: FamilyActivitySelection) {
        save(selection, key: Key.selection)
    }

    func loadMorningPauseCompletedAt() -> Date? {
        defaults.object(forKey: Key.morningPauseCompletedAt) as? Date
    }

    func saveMorningPauseCompletedAt(_ date: Date?) {
        if let date {
            defaults.set(date, forKey: Key.morningPauseCompletedAt)
        } else {
            defaults.removeObject(forKey: Key.morningPauseCompletedAt)
        }
    }

    func clearMorningPauseCompletedAt() {
        defaults.removeObject(forKey: Key.morningPauseCompletedAt)
    }

    func hasCompletedMorningPauseToday(now: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Bool {
        guard let completedAt = loadMorningPauseCompletedAt() else { return false }
        return completedAt >= Self.currentMorningCycleStart(now: now, calendar: calendar)
    }

    static func currentMorningCycleStart(now: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Date {
        let todayStart = calendar.startOfDay(for: now)
        let fiveToday = calendar.date(byAdding: .hour, value: 5, to: todayStart) ?? todayStart
        if now >= fiveToday {
            return fiveToday
        }
        return calendar.date(byAdding: .day, value: -1, to: fiveToday) ?? fiveToday
    }

    static func nextMorningCycleStart(after date: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Date {
        let currentStart = currentMorningCycleStart(now: date, calendar: calendar)
        let nextStart = calendar.date(byAdding: .day, value: 1, to: currentStart) ?? currentStart
        return date < currentStart ? currentStart : nextStart
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
