import Foundation
import FamilyControls

enum PauseCycleTurn: Int, CaseIterable, Codable, Identifiable {
    case morning = 5
    case afternoon = 13
    case evening = 19

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .morning: "Manhã"
        case .afternoon: "Tarde"
        case .evening: "Noite"
        }
    }

    var onboardingSubtitle: String {
        switch self {
        case .morning: "Antes das distrações do dia"
        case .afternoon: "Um respiro no meio do dia"
        case .evening: "Para encerrar o dia na Palavra"
        }
    }

    var hourLabel: String { "\(rawValue)h" }
}

struct ScreenTimePolicyStore {
    static let appGroupIdentifier = "group.com.romeucunha.Limiar"
    static let defaultCycleStartHour = PauseCycleTurn.morning.rawValue
    static let cycleStartHourKey = "cycleStartHour"
    static let activeCycleStartHourKey = "cycleStartHour.active"
    static let cycleStartHourEffectiveAtKey = "cycleStartHour.effectiveAt"
    static var cycleTimeZone: TimeZone { .current }
    static var cycleCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = cycleTimeZone
        return calendar
    }
    static var morningTimeZone: TimeZone { cycleTimeZone }
    static var morningCalendar: Calendar { cycleCalendar }

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

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
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

    func hasCompletedPauseInCurrentCycle(now: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Bool {
        guard let completedAt = loadMorningPauseCompletedAt() else { return false }
        return completedAt >= Self.currentCycleStart(now: now, calendar: calendar)
    }

    func hasCompletedMorningPauseToday(now: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Bool {
        hasCompletedPauseInCurrentCycle(now: now, calendar: calendar)
    }

    func loadSelectedCycleTurn() -> PauseCycleTurn {
        Self.validTurn(defaults.object(forKey: Self.cycleStartHourKey) as? Int) ?? .morning
    }

    func loadEffectiveCycleTurn(now: Date = Date()) -> PauseCycleTurn {
        Self.validTurn(Self.effectiveCycleStartHour(now: now)) ?? .morning
    }

    /// Persiste a escolha imediatamente, mas só muda a janela efetiva no próximo
    /// ciclo. Assim, trocar de turno nunca reabre uma pausa já concluída.
    func saveSelectedCycleTurn(
        _ turn: PauseCycleTurn,
        now: Date = Date(),
        calendar: Calendar = Self.morningCalendar
    ) {
        let activeHour = Self.effectiveCycleStartHour(now: now, defaults: defaults)
        defaults.set(turn.rawValue, forKey: Self.cycleStartHourKey)

        guard turn.rawValue != activeHour else {
            defaults.set(activeHour, forKey: Self.activeCycleStartHourKey)
            defaults.removeObject(forKey: Self.cycleStartHourEffectiveAtKey)
            return
        }

        let effectiveAt = Self.transitionEffectiveDate(
            now: now,
            activeHour: activeHour,
            selectedHour: turn.rawValue,
            calendar: calendar
        )
        defaults.set(activeHour, forKey: Self.activeCycleStartHourKey)
        defaults.set(effectiveAt, forKey: Self.cycleStartHourEffectiveAtKey)
    }

    static func currentCycleStart(
        now: Date = Date(),
        calendar: Calendar = Self.morningCalendar,
        hour: Int? = nil
    ) -> Date {
        cycleStart(
            now: now,
            hour: normalizedHour(hour ?? effectiveCycleStartHour(now: now)),
            calendar: calendar
        )
    }

    static func nextCycleStart(
        after date: Date = Date(),
        calendar: Calendar = Self.morningCalendar
    ) -> Date {
        if let effectiveAt = sharedDefaults.object(forKey: cycleStartHourEffectiveAtKey) as? Date,
           date < effectiveAt {
            return effectiveAt
        }

        let currentStart = currentCycleStart(now: date, calendar: calendar)
        return calendar.date(byAdding: .day, value: 1, to: currentStart) ?? currentStart
    }

    static func cycleDayKey(
        now: Date = Date(),
        calendar: Calendar = Self.cycleCalendar,
        hour: Int? = nil
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: currentCycleStart(now: now, calendar: calendar, hour: hour))
    }

    // Compatibilidade com os chamadores antigos durante a migração de nomenclatura.
    static func currentMorningCycleStart(now: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Date {
        currentCycleStart(now: now, calendar: calendar)
    }

    static func nextMorningCycleStart(after date: Date = Date(), calendar: Calendar = Self.morningCalendar) -> Date {
        nextCycleStart(after: date, calendar: calendar)
    }

    private static func validTurn(_ hour: Int?) -> PauseCycleTurn? {
        guard let hour else { return nil }
        return PauseCycleTurn(rawValue: hour)
    }

    private static func normalizedHour(_ hour: Int) -> Int {
        validTurn(hour)?.rawValue ?? defaultCycleStartHour
    }

    private static func effectiveCycleStartHour(
        now: Date,
        defaults: UserDefaults = sharedDefaults
    ) -> Int {
        let selected = normalizedHour(defaults.object(forKey: cycleStartHourKey) as? Int ?? defaultCycleStartHour)
        let active = normalizedHour(defaults.object(forKey: activeCycleStartHourKey) as? Int ?? defaultCycleStartHour)
        guard let effectiveAt = defaults.object(forKey: cycleStartHourEffectiveAtKey) as? Date,
              now < effectiveAt
        else {
            return selected
        }
        return active
    }

    private static func cycleStart(now: Date, hour: Int, calendar: Calendar) -> Date {
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

    private static func transitionEffectiveDate(
        now: Date,
        activeHour: Int,
        selectedHour: Int,
        calendar: Calendar
    ) -> Date {
        let activeStart = cycleStart(now: now, hour: normalizedHour(activeHour), calendar: calendar)
        let nextCycleDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: activeStart))
            ?? calendar.startOfDay(for: activeStart)
        return calendar.date(
            bySettingHour: normalizedHour(selectedHour),
            minute: 0,
            second: 0,
            of: nextCycleDay
        ) ?? nextCycleDay
    }

#if DEBUG
    static func runCycleMathDebugAssertions() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 7, day: day, hour: hour, minute: minute))!
        }

        assert(cycleStart(now: date(16, 10), hour: 5, calendar: calendar) == date(16, 5))
        assert(cycleStart(now: date(16, 10), hour: 13, calendar: calendar) == date(15, 13))
        assert(cycleStart(now: date(16, 23), hour: 19, calendar: calendar) == date(16, 19))
        assert(cycleStart(now: date(17, 1), hour: 19, calendar: calendar) == date(16, 19))
        assert(cycleStart(now: date(17, 19, 1), hour: 19, calendar: calendar) == date(17, 19))
        assert(cycleDayKey(now: date(16, 10), calendar: calendar, hour: 5) == "2026-07-16")
        assert(cycleDayKey(now: date(16, 10), calendar: calendar, hour: 13) == "2026-07-15")
        assert(cycleDayKey(now: date(16, 23), calendar: calendar, hour: 19) == "2026-07-16")
        assert(cycleDayKey(now: date(17, 1), calendar: calendar, hour: 19) == "2026-07-16")
        assert(cycleDayKey(now: date(17, 19, 1), calendar: calendar, hour: 19) == "2026-07-17")

        // Mudar de manhã para tarde às 10h só entra em vigor no dia seguinte.
        assert(
            transitionEffectiveDate(
                now: date(16, 10),
                activeHour: 5,
                selectedHour: 13,
                calendar: calendar
            ) == date(17, 13)
        )
    }
#endif

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
