import Foundation
import FamilyControls
import Observation

enum FaithTradition: String, Codable, CaseIterable, Identifiable {
    case catholic
    case protestant
    case jewish
    case spiritist

    var id: String { rawValue }

    var title: String {
        switch self {
        case .catholic: "Católica"
        case .protestant: "Evangélica"
        case .jewish: "Judaica"
        case .spiritist: "Espírita"
        }
    }

    var subtitle: String {
        switch self {
        case .catholic: "Bíblia católica e tom pastoral."
        case .protestant: "Canon protestante e estudo devocional."
        case .jewish: "Tanakh, sem referências ao Novo Testamento."
        case .spiritist: "Evangelho, reforma íntima e aplicação moral."
        }
    }
}

enum BibleSection: String, Codable, CaseIterable, Identifiable {
    case gospels
    case psalms
    case proverbs
    case paulineLetters
    case prophets
    case torah
    case historicalBooks
    case wisdomBooks
    case deuterocanonical
    case ketuvim
    case ethicalWisdom
    case sermonOnMount
    case parablesOfJesus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gospels: "Evangelhos"
        case .psalms: "Salmos"
        case .proverbs: "Provérbios"
        case .paulineLetters: "Cartas de Paulo"
        case .prophets: "Profetas"
        case .torah: "Pentateuco / Torá"
        case .historicalBooks: "Históricos"
        case .wisdomBooks: "Sapienciais"
        case .deuterocanonical: "Deuterocanônicos"
        case .ketuvim: "Escritos — Ketuvim"
        case .ethicalWisdom: "Sabedoria e ética"
        case .sermonOnMount: "Sermão da Montanha"
        case .parablesOfJesus: "Parábolas de Jesus"
        }
    }
}

enum BibleBook: String, Codable, CaseIterable, Identifiable {
    case genesis
    case exodus
    case psalms
    case proverbs
    case isaiah
    case matthew
    case luke
    case john
    case romans
    case corinthians
    case revelation
    case tobias
    case wisdom
    case sirach
    case maccabees
    case leviticus
    case numbers
    case deuteronomy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .genesis: "Gênesis"
        case .exodus: "Êxodo"
        case .psalms: "Salmos"
        case .proverbs: "Provérbios"
        case .isaiah: "Isaías"
        case .matthew: "Mateus"
        case .luke: "Lucas"
        case .john: "João"
        case .romans: "Romanos"
        case .corinthians: "Coríntios"
        case .revelation: "Apocalipse"
        case .tobias: "Tobias"
        case .wisdom: "Sabedoria"
        case .sirach: "Eclesiástico"
        case .maccabees: "Macabeus"
        case .leviticus: "Levítico / Vayikra"
        case .numbers: "Números / Bamidbar"
        case .deuteronomy: "Deuteronômio / Devarim"
        }
    }
}

enum SpiritualTheme: String, Codable, CaseIterable, Identifiable {
    case faith
    case hope
    case forgiveness
    case discipline
    case wisdom
    case family
    case work
    case anxiety
    case presence
    case purpose
    case gospelOfJesus
    case innerReform
    case charity
    case prayer
    case patience
    case spiritualEvolution
    case consolationHope
    case moralApplication
    case practiceGood
    case prosperityWithPurpose
    case financialBalance

    var id: String { rawValue }

    static let standaloneOptions: [SpiritualTheme] = [
        .faith,
        .hope,
        .forgiveness,
        .discipline,
        .wisdom,
        .family,
        .work,
        .anxiety,
        .presence,
        .purpose,
        .charity,
        .prayer,
        .patience,
        .innerReform,
        .consolationHope,
        .spiritualEvolution,
        .practiceGood,
        .prosperityWithPurpose,
        .financialBalance
    ]

    var title: String {
        switch self {
        case .faith: "Fé"
        case .hope: "Esperança"
        case .forgiveness: "Perdão"
        case .discipline: "Disciplina"
        case .wisdom: "Sabedoria"
        case .family: "Família"
        case .work: "Trabalho"
        case .anxiety: "Ansiedade"
        case .presence: "Presença"
        case .purpose: "Propósito"
        case .gospelOfJesus: "Evangelho de Jesus"
        case .innerReform: "Reforma íntima"
        case .charity: "Caridade"
        case .prayer: "Prece"
        case .patience: "Paciência"
        case .spiritualEvolution: "Evolução espiritual"
        case .consolationHope: "Consolação"
        case .moralApplication: "Aplicação moral"
        case .practiceGood: "Prática do bem"
        case .prosperityWithPurpose: "Prosperidade com propósito"
        case .financialBalance: "Vida financeira e equilíbrio"
        }
    }
}

enum ReadingPreferenceCategory: String, Hashable {
    case section
    case book
    case theme
}

struct ReadingPreferenceOption: Identifiable, Hashable {
    let id: String
    let title: String
    let category: ReadingPreferenceCategory
    let tradition: FaithTradition
    let section: BibleSection?
    let book: BibleBook?
    let theme: SpiritualTheme?

    static func section(_ section: BibleSection, title: String? = nil, tradition: FaithTradition) -> ReadingPreferenceOption {
        ReadingPreferenceOption(
            id: "\(tradition.rawValue).section.\(section.rawValue)",
            title: title ?? section.title,
            category: .section,
            tradition: tradition,
            section: section,
            book: nil,
            theme: nil
        )
    }

    static func book(_ book: BibleBook, title: String? = nil, tradition: FaithTradition) -> ReadingPreferenceOption {
        ReadingPreferenceOption(
            id: "\(tradition.rawValue).book.\(book.rawValue)",
            title: title ?? book.title,
            category: .book,
            tradition: tradition,
            section: nil,
            book: book,
            theme: nil
        )
    }

    static func theme(_ theme: SpiritualTheme, title: String? = nil, tradition: FaithTradition) -> ReadingPreferenceOption {
        ReadingPreferenceOption(
            id: "\(tradition.rawValue).theme.\(theme.rawValue)",
            title: title ?? theme.title,
            category: .theme,
            tradition: tradition,
            section: nil,
            book: nil,
            theme: theme
        )
    }
}

struct ReadingPreferenceSection: Identifiable, Hashable {
    let title: String
    let subtitle: String?
    let options: [ReadingPreferenceOption]

    var id: String { title }

    init(title: String, subtitle: String? = nil, options: [ReadingPreferenceOption]) {
        self.title = title
        self.subtitle = subtitle
        self.options = options
    }
}

extension FaithTradition {
    var readingPreferenceSections: [ReadingPreferenceSection] {
        switch self {
        case .catholic:
            [
                ReadingPreferenceSection(
                    title: "Tipos de leitura",
                    options: [
                        .section(.gospels, tradition: self),
                        .section(.psalms, title: "Salmos e Orações", tradition: self),
                        .section(.proverbs, title: "Sabedoria", tradition: self),
                        .section(.paulineLetters, tradition: self),
                        .section(.prophets, tradition: self),
                        .section(.historicalBooks, title: "Histórias Bíblicas", tradition: self),
                        .section(.torah, title: "Leis e Origens", tradition: self),
                        .section(.wisdomBooks, title: "Reflexões e Sabedoria", tradition: self),
                        .section(.deuterocanonical, title: "Livros Católicos", tradition: self)
                    ]
                ),
                ReadingPreferenceSection(
                    title: "Livros que mais inspiram você",
                    options: [
                        .book(.genesis, tradition: self),
                        .book(.exodus, tradition: self),
                        .book(.psalms, tradition: self),
                        .book(.proverbs, tradition: self),
                        .book(.isaiah, tradition: self),
                        .book(.matthew, tradition: self),
                        .book(.luke, tradition: self),
                        .book(.john, tradition: self),
                        .book(.romans, tradition: self),
                        .book(.corinthians, tradition: self),
                        .book(.tobias, tradition: self),
                        .book(.wisdom, tradition: self),
                        .book(.sirach, tradition: self),
                        .book(.maccabees, tradition: self)
                    ]
                )
            ]
        case .protestant:
            [
                ReadingPreferenceSection(
                    title: "Tipos de leitura",
                    options: [
                        .section(.gospels, tradition: self),
                        .section(.psalms, title: "Salmos e Orações", tradition: self),
                        .section(.proverbs, title: "Sabedoria", tradition: self),
                        .section(.paulineLetters, tradition: self),
                        .section(.prophets, tradition: self),
                        .section(.historicalBooks, title: "Histórias Bíblicas", tradition: self),
                        .section(.torah, title: "Leis e Origens", tradition: self),
                        .section(.wisdomBooks, title: "Reflexões e Sabedoria", tradition: self)
                    ]
                ),
                ReadingPreferenceSection(
                    title: "Livros que mais inspiram você",
                    options: [
                        .book(.genesis, tradition: self),
                        .book(.exodus, tradition: self),
                        .book(.psalms, tradition: self),
                        .book(.proverbs, tradition: self),
                        .book(.isaiah, tradition: self),
                        .book(.matthew, tradition: self),
                        .book(.luke, tradition: self),
                        .book(.john, tradition: self),
                        .book(.romans, tradition: self),
                        .book(.corinthians, tradition: self),
                        .book(.revelation, tradition: self)
                    ]
                )
            ]
        case .jewish:
            [
                ReadingPreferenceSection(
                    title: "Tipos de leitura",
                    options: [
                        .section(.torah, title: "Torá — Leis e origens", tradition: self),
                        .section(.prophets, title: "Profetas — Nevi’im", tradition: self),
                        .section(.ketuvim, title: "Escritos — Ketuvim", tradition: self),
                        .section(.psalms, title: "Salmos e Orações — Tehilim", tradition: self),
                        .section(.proverbs, title: "Sabedoria — Mishlei", tradition: self),
                        .section(.ethicalWisdom, title: "Ética e vida prática", tradition: self)
                    ]
                ),
                ReadingPreferenceSection(
                    title: "Livros que mais inspiram você",
                    options: [
                        .book(.genesis, title: "Gênesis / Bereshit", tradition: self),
                        .book(.exodus, title: "Êxodo / Shemot", tradition: self),
                        .book(.leviticus, title: "Levítico / Vayikra", tradition: self),
                        .book(.numbers, title: "Números / Bamidbar", tradition: self),
                        .book(.deuteronomy, title: "Deuteronômio / Devarim", tradition: self),
                        .book(.psalms, title: "Salmos / Tehilim", tradition: self),
                        .book(.proverbs, title: "Provérbios / Mishlei", tradition: self),
                        .book(.isaiah, title: "Isaías / Yeshayahu", tradition: self)
                    ]
                )
            ]
        case .spiritist:
            [
                ReadingPreferenceSection(
                    title: "Temas de reflexão",
                    subtitle: "Assuntos espirituais e morais para orientar as leituras.",
                    options: [
                        .theme(.gospelOfJesus, tradition: self),
                        .theme(.innerReform, tradition: self),
                        .theme(.charity, tradition: self),
                        .theme(.forgiveness, tradition: self),
                        .theme(.prayer, tradition: self),
                        .theme(.family, tradition: self),
                        .theme(.patience, tradition: self),
                        .theme(.spiritualEvolution, tradition: self),
                        .theme(.consolationHope, tradition: self),
                        .theme(.moralApplication, title: "Vida prática e moral", tradition: self)
                    ]
                ),
                ReadingPreferenceSection(
                    title: "Textos de apoio",
                    subtitle: "Fontes que podem apoiar as reflexões espíritas.",
                    options: [
                        .section(.gospels, tradition: self),
                        .section(.psalms, title: "Salmos e Orações", tradition: self),
                        .section(.proverbs, title: "Sabedoria", tradition: self),
                        .section(.sermonOnMount, tradition: self),
                        .section(.parablesOfJesus, tradition: self)
                    ]
                )
            ]
        }
    }

    var allowedReadingPreferenceOptions: [ReadingPreferenceOption] {
        readingPreferenceSections.flatMap(\.options)
    }

    var aiToneGuidance: String {
        switch self {
        case .catholic:
            "Tom católico pastoral, com espaço para Evangelhos, Salmos e deuterocanônicos quando selecionados."
        case .protestant:
            "Tom evangélico devocional, sem livros deuterocanônicos."
        case .jewish:
            "Tom judaico baseado no Tanakh, sem referências ao Novo Testamento."
        case .spiritist:
            "Tom espírita com foco em aplicação moral, reforma íntima, caridade e vida prática."
        }
    }

    var avoidedSectionTitlesForAI: [String] {
        switch self {
        case .catholic, .spiritist:
            []
        case .protestant:
            ["Deuterocanônicos"]
        case .jewish:
            ["Evangelhos", "Cartas de Paulo"]
        }
    }

    var avoidedBookTitlesForAI: [String] {
        switch self {
        case .catholic, .spiritist:
            []
        case .protestant:
            ["Tobias", "Sabedoria", "Eclesiástico", "Macabeus"]
        case .jewish:
            ["Mateus", "Lucas", "João", "Romanos", "Coríntios", "Apocalipse"]
        }
    }
}

enum ExplanationDepth: String, Codable, CaseIterable, Identifiable {
    case short
    case medium
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .short: "Curta"
        case .medium: "Média"
        case .deep: "Mais profunda"
        }
    }
}

struct UserFaithProfile: Codable, Equatable {
    var tradition: FaithTradition
    var favoriteBibleSections: [BibleSection]
    var favoriteBooks: [BibleBook]
    var favoriteThemes: [SpiritualTheme]
    var explanationDepth: ExplanationDepth

    static let starter = UserFaithProfile(
        tradition: .catholic,
        favoriteBibleSections: [.psalms, .gospels],
        favoriteBooks: [.psalms, .john],
        favoriteThemes: [.presence, .discipline],
        explanationDepth: .medium
    )

    var selectedReadingPreferenceCount: Int {
        tradition.allowedReadingPreferenceOptions.filter { contains($0) }.count
    }

    var hasSelectedReadingPreferences: Bool {
        selectedReadingPreferenceCount > 0
    }

    var selectedSectionOptionIds: [String] {
        favoriteBibleSections.map(\.rawValue).sorted()
    }

    var selectedBookOptionIds: [String] {
        favoriteBooks.map(\.rawValue).sorted()
    }

    var selectedThemeOptionIds: [String] {
        favoriteThemes.map(\.rawValue).sorted()
    }

    func contains(_ option: ReadingPreferenceOption) -> Bool {
        switch option.category {
        case .section:
            guard let section = option.section else { return false }
            return favoriteBibleSections.contains(section)
        case .book:
            guard let book = option.book else { return false }
            return favoriteBooks.contains(book)
        case .theme:
            guard let theme = option.theme else { return false }
            return favoriteThemes.contains(theme)
        }
    }

    mutating func toggle(_ option: ReadingPreferenceOption) {
        switch option.category {
        case .section:
            guard let section = option.section else { return }
            if favoriteBibleSections.contains(section) {
                favoriteBibleSections.removeAll { $0 == section }
            } else {
                favoriteBibleSections.append(section)
            }
        case .book:
            guard let book = option.book else { return }
            if favoriteBooks.contains(book) {
                favoriteBooks.removeAll { $0 == book }
            } else {
                favoriteBooks.append(book)
            }
        case .theme:
            guard let theme = option.theme else { return }
            if favoriteThemes.contains(theme) {
                favoriteThemes.removeAll { $0 == theme }
            } else {
                favoriteThemes.append(theme)
            }
        }
    }

    mutating func normalizeReadingPreferencesForTradition() {
        let allowed = tradition.allowedReadingPreferenceOptions
        let allowedSections = Set(allowed.compactMap(\.section))
        let allowedBooks = Set(allowed.compactMap(\.book))
        let allowedThemes = Set(allowed.compactMap(\.theme))
        if !allowedSections.isEmpty {
            favoriteBibleSections = favoriteBibleSections.filter { allowedSections.contains($0) }
        }
        if !allowedBooks.isEmpty || tradition == .spiritist {
            favoriteBooks = favoriteBooks.filter { allowedBooks.contains($0) }
        }
        if !allowedThemes.isEmpty {
            favoriteThemes = favoriteThemes.filter { allowedThemes.contains($0) }
        }
    }

    mutating func normalizeStandaloneThemesForCurrentTradition() {
        guard tradition != .spiritist else { return }
        let allowedThemes = Set(SpiritualTheme.standaloneOptions)
        favoriteThemes = favoriteThemes.filter { allowedThemes.contains($0) }
    }
}

struct ScripturePassage: Identifiable, Codable, Equatable {
    let id: String
    let tradition: FaithTradition
    let title: String
    let reference: String
    let text: String
    let estimatedMinutes: Int
    let theme: SpiritualTheme
    let section: BibleSection
    let book: BibleBook
}

struct AIReflection: Codable, Equatable {
    let summary: String
    let spiritualMeaning: String
    let practicalApplication: String
    let conclusion: String
    let meditationQuestion: String
}

struct RecentAIReflectionDigest: Codable, Hashable {
    let reference: String
    let summary: String
    let meditationQuestion: String
    let createdAt: Date
}

struct SpiritualReadingItem: Identifiable, Codable, Equatable {
    let id: String
    let reference: String
    let text: String
    let homily: String
    let practicalConclusion: String
}

struct ReadingHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let passageID: String
    let passageTitle: String
    let reference: String
    let completedAt: Date
}

struct FavoritePassageItem: Identifiable, Codable, Equatable {
    let id: UUID
    let passageID: String
    let passageTitle: String
    let reference: String
    let savedAt: Date
}

enum LockState: Equatable {
    case locked
    case readingPause
    case unlockedUntil(Date)
}

enum AIContentState: Equatable {
    case localReady
    case generating
    case remoteReady
    case fallback
    case essentialMode

    var title: String {
        switch self {
        case .localReady:
            "Preparando leitura"
        case .generating:
            "Gerando reflexão com IA"
        case .remoteReady:
            "Reflexão gerada por IA"
        case .fallback:
            "Atualização indisponível"
        case .essentialMode:
            "Modo Essencial"
        }
    }

    var subtitle: String {
        switch self {
        case .localReady:
            "A leitura será atualizada pela IA assim que você começar."
        case .generating:
            "O ChatGPT está preparando novos trechos e explicações para este momento."
        case .remoteReady:
            "Texto atualizado com novos trechos e uma reflexão nova."
        case .fallback:
            "Não foi possível buscar uma nova leitura agora. Tente novamente em instantes."
        case .essentialMode:
            "Você está lendo os trechos principais. Reflexões, narração e maior variedade estão disponíveis no Limiar completo."
        }
    }
}

@MainActor
@Observable
final class LimiarAppModel {
    static let defaultUnlockDurationMinutes = 30

    var hasCompletedOnboarding = false
    var hasSeenValueDemo = false
    var hasPremiumAccess = false
    var isEssentialMode = false
    var faithProfile = UserFaithProfile.starter
    var unlockDurationMinutes = LimiarAppModel.defaultUnlockDurationMinutes
    var blockingEnabled = true
    var selection = FamilyActivitySelection()
    var currentReadingPlan: [ScripturePassage] = []
    var currentSpiritualReadingItems: [SpiritualReadingItem] = []
    var currentPassage = ScripturePassage(
        id: "starter",
        tradition: .catholic,
        title: "O Senhor conduz",
        reference: "Salmo 23",
        text: "O Senhor é meu pastor: nada me faltará.",
        estimatedMinutes: 10,
        theme: .hope,
        section: .psalms,
        book: .psalms
    )
    var currentReflection = AIReflection(
        summary: "Uma pausa breve para lembrar que a atenção pode ganhar direção.",
        spiritualMeaning: "Voltar ao essencial e uma escolha espiritual pequena, mas concreta.",
        practicalApplication: "Respire, leia e escolha atravessar com consciência.",
        conclusion: "O limiar transforma impulso em decisão.",
        meditationQuestion: "O que merece minha atenção agora?"
    )
    var readingProgress = 0.0
    var readingStartedAt = Date()
    var isReadingSessionActive = false
    var history: [ReadingHistoryItem] = []
    var favoritePassages: [FavoritePassageItem] = []
    var unlockedUntil: Date?
    var unlockNote = ""
    var hasAuthorizedScreenTime = false
    var recentPassageIDs: [String] = []
    var recentAIReflections: [RecentAIReflectionDigest] = []
    var aiContentState = AIContentState.localReady
    var readingTopResetID = UUID()

    private let recommender = PassageRecommendationService()
    private let policyStore = ScreenTimePolicyStore()
    private let screenTimeController = ScreenTimeController()
    private var lastForegroundRefreshAt = Date.distantPast
    private var aiGenerationTask: Task<Void, Never>?
    private var aiGenerationID = UUID()
    private var lastRemoteAIRequestKey = ""
    private var lastRemoteAIRequestAt = Date.distantPast
    @ObservationIgnored private var unlockExpirationTask: Task<Void, Never>?

    init() {
        var savedProfile = policyStore.loadFaithProfile() ?? .starter
        savedProfile.normalizeReadingPreferencesForTradition()
        savedProfile.normalizeStandaloneThemesForCurrentTradition()
        policyStore.saveFaithProfile(savedProfile)
        faithProfile = savedProfile
        hasCompletedOnboarding = policyStore.loadOnboardingState()
        hasSeenValueDemo = policyStore.loadValueDemoSeen()
        unlockDurationMinutes = Self.defaultUnlockDurationMinutes
        policyStore.saveUnlockDuration(Self.defaultUnlockDurationMinutes)
        blockingEnabled = policyStore.loadBlockingEnabled()
        selection = policyStore.loadSelection()
        unlockedUntil = policyStore.loadUnlockedUntil()
        history = policyStore.loadHistory()
        favoritePassages = policyStore.loadFavorites()
        hasAuthorizedScreenTime = policyStore.loadScreenTimeAuthorized()
        recentPassageIDs = policyStore.loadRecentPassageIDs()
        recentAIReflections = policyStore.loadRecentAIReflections()

        setReadingPlan(
            recommender.readingPlan(
                for: savedProfile,
                history: history,
                recentlyShownPassageIDs: recentPassageIDs
            ),
            profile: savedProfile
        )
        reapplyBlockIfNeeded()
    }

    var lockState: LockState {
        guard blockingEnabled else { return .unlockedUntil(.distantFuture) }
        if let unlockedUntil, unlockedUntil > Date() {
            return .unlockedUntil(unlockedUntil)
        }
        return history.isEmpty ? .readingPause : .locked
    }

    var canCompleteReading: Bool {
        readingProgress >= 0.78 || readingElapsedSeconds >= minimumReadingSeconds
    }

    var readingElapsedSeconds: TimeInterval {
        max(0, Date().timeIntervalSince(readingStartedAt))
    }

    var minimumReadingSeconds: TimeInterval {
        min(120, max(75, TimeInterval(currentReadingEstimatedMinutes * 10)))
    }

    var isCurrentPassageFavorite: Bool {
        favoritePassages.contains { $0.passageID == currentReadingSessionID }
    }

    var currentReadingSessionID: String {
        currentReadingPlan.map(\.id).joined(separator: "+")
    }

    var currentReadingTitle: String {
        currentReadingPlan.count > 1 ? "Caminho de leitura" : currentPassage.title
    }

    var currentReadingReference: String {
        currentReadingPlan.map(\.reference).joined(separator: " + ")
    }

    var currentReadingEstimatedMinutes: Int {
        max(1, currentReadingPlan.reduce(0) { $0 + $1.estimatedMinutes })
    }

    var currentReadingText: String {
        currentSpiritualReadingItems.enumerated().map { index, item in
            "\(index + 1). \(item.reference)\n\(item.text)"
        }
        .joined(separator: "\n\n")
    }

    var currentReadingNarrationText: String {
        guard hasPremiumAccess else { return "" }

        let passageBlocks = currentSpiritualReadingItems.enumerated().map { index, item in
            """
            Texto \(index + 1).
            \(item.reference).
            \(item.text)
            """
        }
        .joined(separator: "\n\n")

        let reflectionBlock = """
        Explicação espiritual.
        \(currentReflection.summary)
        \(currentReflection.spiritualMeaning)

        Aplicação prática.
        \(currentReflection.practicalApplication)
        \(currentReflection.conclusion)
        """

        return [passageBlocks, reflectionBlock]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")
    }

    var unlockDurationDescription: String {
        "\(unlockDurationMinutes) minutos"
    }

    var hasBlockedAppsSelection: Bool {
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    var hasPauseAccess: Bool {
        hasPremiumAccess || isEssentialMode
    }

    var estimatedFocusTimeText: String {
        let totalMinutes = max(0, history.count * unlockDurationMinutes)
        guard totalMinutes >= 60 else {
            return "\(totalMinutes) min"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes == 0 ? "\(hours) h" : "\(hours) h \(minutes) min"
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        policyStore.saveOnboardingState(true)
        saveProfile()
        beginNewReading(avoidingCurrent: true)
        if hasPauseAccess {
            applyBlocking()
        }
    }

    func markValueDemoSeen() {
        hasSeenValueDemo = true
        policyStore.saveValueDemoSeen(true)
    }

    func updatePremiumAccess(_ isActive: Bool) {
        updateAccess(hasPremiumAccess: isActive, isEssentialMode: false)
    }

    func updateAccess(hasPremiumAccess isActive: Bool, isEssentialMode essentialMode: Bool) {
        let hadPauseAccess = hasPauseAccess
        let hadFullAccess = hasPremiumAccess
        let hadEssentialMode = isEssentialMode

        hasPremiumAccess = isActive
        isEssentialMode = essentialMode && !isActive

        if hasPauseAccess {
            if !hadPauseAccess || currentSpiritualReadingItems.isEmpty || hadFullAccess != isActive || hadEssentialMode != isEssentialMode {
                beginNewReading(avoidingCurrent: true)
            }
            applyBlocking()
        } else {
            aiContentState = .localReady
            aiGenerationTask?.cancel()
            screenTimeController.clearShield()
            cancelLocalUnlockExpiration()
        }
    }

    func saveProfile() {
        faithProfile.normalizeReadingPreferencesForTradition()
        faithProfile.normalizeStandaloneThemesForCurrentTradition()
        policyStore.saveFaithProfile(faithProfile)
        unlockDurationMinutes = Self.defaultUnlockDurationMinutes
        policyStore.saveUnlockDuration(Self.defaultUnlockDurationMinutes)
        policyStore.saveBlockingEnabled(blockingEnabled)
        policyStore.saveSelection(selection)
        var values = LimiarAIDiagnostics.profileSnapshot(faithProfile)
        values["unlockDurationMinutes"] = "\(Self.defaultUnlockDurationMinutes)"
        values["blockingEnabled"] = "\(blockingEnabled)"
        values["hasBlockedAppsSelection"] = "\(hasBlockedAppsSelection)"
        LimiarAIDiagnostics.log("preferences_saved", values: values)
    }

    func selectTradition(_ tradition: FaithTradition) {
        let didChangeTradition = faithProfile.tradition != tradition
        faithProfile.tradition = tradition
        faithProfile.normalizeReadingPreferencesForTradition()
        faithProfile.normalizeStandaloneThemesForCurrentTradition()
        saveProfile()
        if didChangeTradition {
            beginNewReading(avoidingCurrent: true)
        }
    }

    func toggleReadingPreference(_ option: ReadingPreferenceOption) {
        faithProfile.toggle(option)
        faithProfile.normalizeReadingPreferencesForTradition()
        saveProfile()
    }

    func toggleTheme(_ theme: SpiritualTheme) {
        faithProfile.normalizeStandaloneThemesForCurrentTradition()
        if faithProfile.favoriteThemes.contains(theme) {
            faithProfile.favoriteThemes.removeAll { $0 == theme }
        } else {
            faithProfile.favoriteThemes.append(theme)
        }
        faithProfile.normalizeReadingPreferencesForTradition()
        faithProfile.normalizeStandaloneThemesForCurrentTradition()
        saveProfile()
    }

    func selectExplanationDepth(_ depth: ExplanationDepth) {
        faithProfile.explanationDepth = depth
        saveProfile()
    }

    func beginNewReading(avoidingCurrent: Bool = false) {
        readingProgress = 0
        readingStartedAt = Date()
        setReadingPlan(recommender.readingPlan(
            for: faithProfile,
            history: history,
            avoiding: avoidingCurrent ? currentPassage.id : nil,
            recentlyShownPassageIDs: recentPassageIDs
        ), profile: faithProfile)
    }

    func prepareFreshPassageForForeground() {
        reapplyBlockIfNeeded()
        guard hasCompletedOnboarding else { return }
        readingTopResetID = UUID()
        guard Date().timeIntervalSince(lastForegroundRefreshAt) > 2 else { return }
        lastForegroundRefreshAt = Date()
        beginNewReading(avoidingCurrent: true)
    }

    func startReadingSession() {
        isReadingSessionActive = true
        readingProgress = 0
        readingStartedAt = Date()
    }

    func updateReadingProgress(at date: Date = Date()) {
        guard isReadingSessionActive else { return }
        let elapsed = max(0, date.timeIntervalSince(readingStartedAt))
        let automaticProgress = min(1, elapsed / minimumReadingSeconds)
        readingProgress = max(readingProgress, automaticProgress)
    }

    func endReadingSession() {
        isReadingSessionActive = false
    }

    func toggleFavoriteCurrentPassage() {
        if isCurrentPassageFavorite {
            favoritePassages.removeAll { $0.passageID == currentReadingSessionID }
        } else {
            favoritePassages.insert(
                FavoritePassageItem(
                    id: UUID(),
                    passageID: currentReadingSessionID,
                    passageTitle: currentReadingTitle,
                    reference: currentReadingReference,
                    savedAt: Date()
                ),
                at: 0
            )
        }
        policyStore.saveFavorites(favoritePassages)
    }

    func isFavorite(_ item: SpiritualReadingItem) -> Bool {
        favoritePassages.contains { $0.passageID == item.id }
    }

    func toggleFavorite(_ item: SpiritualReadingItem) {
        if isFavorite(item) {
            favoritePassages.removeAll { $0.passageID == item.id }
        } else {
            favoritePassages.insert(
                FavoritePassageItem(
                    id: UUID(),
                    passageID: item.id,
                    passageTitle: item.reference,
                    reference: item.reference,
                    savedAt: Date()
                ),
                at: 0
            )
        }
        policyStore.saveFavorites(favoritePassages)
    }

    func finishReading() {
        guard hasPauseAccess else {
            isReadingSessionActive = false
            unlockNote = "Inicie o teste gratuito para ativar a pausa antes dos apps selecionados."
            screenTimeController.clearShield()
            return
        }

        isReadingSessionActive = false
        let until = Date().addingTimeInterval(TimeInterval(unlockDurationMinutes * 60))
        unlockedUntil = until
        history.insert(
            ReadingHistoryItem(
                id: UUID(),
                passageID: currentReadingSessionID,
                passageTitle: currentReadingTitle,
                reference: currentReadingReference,
                completedAt: Date()
            ),
            at: 0
        )
        policyStore.saveHistory(history)
        policyStore.saveUnlockedUntil(until)
        screenTimeController.clearShield()
        screenTimeController.scheduleUnlockExpiration(at: until)
        scheduleLocalUnlockExpiration(at: until)
        unlockNote = "Disponível até \(until.formatted(date: .omitted, time: .shortened))."
        beginNewReading()
    }

    func applyBlocking() {
        guard hasPauseAccess else {
            screenTimeController.clearShield()
            return
        }

        guard blockingEnabled else {
            screenTimeController.clearShield()
            return
        }
        if let unlockedUntil, unlockedUntil > Date() {
            screenTimeController.clearShield()
            screenTimeController.scheduleUnlockExpiration(at: unlockedUntil)
            scheduleLocalUnlockExpiration(at: unlockedUntil)
            return
        }
        cancelLocalUnlockExpiration()
        screenTimeController.applyShield(selection: selection)
    }

    func reapplyBlockIfNeeded() {
        guard hasPauseAccess else {
            screenTimeController.clearShield()
            cancelLocalUnlockExpiration()
            return
        }

        guard blockingEnabled else {
            screenTimeController.clearShield()
            cancelLocalUnlockExpiration()
            return
        }
        if let unlockedUntil, unlockedUntil > Date() {
            screenTimeController.clearShield()
            screenTimeController.scheduleUnlockExpiration(at: unlockedUntil)
            scheduleLocalUnlockExpiration(at: unlockedUntil)
        } else {
            self.unlockedUntil = nil
            policyStore.saveUnlockedUntil(nil)
            cancelLocalUnlockExpiration()
            screenTimeController.applyShield(selection: selection)
        }
    }

    func requestAuthorization() async -> String {
        do {
            try await screenTimeController.requestAuthorization()
            hasAuthorizedScreenTime = true
            policyStore.saveScreenTimeAuthorized(true)
            return "Permissão concedida."
        } catch {
            hasAuthorizedScreenTime = false
            policyStore.saveScreenTimeAuthorized(false)
            return "Não foi possível ativar agora: \(error.localizedDescription)"
        }
    }

    func resetHistory() {
        history.removeAll()
        policyStore.saveHistory(history)
        beginNewReading()
    }

    private func setReadingPlan(_ plan: [ScripturePassage], profile: UserFaithProfile) {
        let resolvedPlan = plan.isEmpty ? [currentPassage] : plan
        aiGenerationTask?.cancel()
        let generationID = UUID()
        aiGenerationID = generationID
        currentReadingPlan = resolvedPlan
        currentPassage = resolvedPlan[0]
        if isEssentialMode {
            currentSpiritualReadingItems = essentialReadingItems(for: resolvedPlan)
            currentReflection = AIReflection(
                summary: "",
                spiritualMeaning: "",
                practicalApplication: "",
                conclusion: "",
                meditationQuestion: ""
            )
            aiContentState = .essentialMode
            var values = LimiarAIDiagnostics.profileSnapshot(profile)
            values["source"] = "essential"
            values["references"] = resolvedPlan.map(\.reference).joined(separator: " + ")
            LimiarAIDiagnostics.log("essential_mode_reading_prepared", values: values)
            rememberShownPassages(resolvedPlan)
            return
        }

        let spiritualReadingService = AISpiritualReadingService()
        let reflectionService = AIReflectionService()
        currentSpiritualReadingItems = spiritualReadingService.readingItems(
            for: resolvedPlan,
            profile: profile,
            recentPassageIDs: recentPassageIDs,
            recentReflections: recentAIReflections
        )
        currentReflection = reflectionService.reflection(
            for: resolvedPlan,
            profile: profile,
            recentReflections: recentAIReflections
        )
        var planValues = LimiarAIDiagnostics.profileSnapshot(profile)
        planValues["references"] = resolvedPlan.map(\.reference).joined(separator: " + ")
        planValues["passages"] = resolvedPlan.map(\.id).joined(separator: ",")
        planValues["recentReflections"] = "\(recentAIReflections.count)"
        LimiarAIDiagnostics.log("reading_plan_prepared", values: planValues)
        rememberShownPassages(resolvedPlan)
        guard hasPremiumAccess else {
            aiContentState = .localReady
            var values = LimiarAIDiagnostics.profileSnapshot(profile)
            values["source"] = "none"
            values["reason"] = "no_active_subscription"
            LimiarAIDiagnostics.log("remote_ai_skipped", values: values)
            return
        }

        let remoteRequestKey = remoteAIRequestKey(for: resolvedPlan, profile: profile)
        lastRemoteAIRequestKey = remoteRequestKey
        lastRemoteAIRequestAt = Date()
        aiContentState = .generating
        var values = LimiarAIDiagnostics.profileSnapshot(profile)
        values["source"] = "remote"
        values["requestKey"] = remoteRequestKey
        LimiarAIDiagnostics.log("remote_ai_started", values: values)
        refreshRemoteAIContent(for: resolvedPlan, profile: profile, generationID: generationID)
    }

    private func essentialReadingItems(for passages: [ScripturePassage]) -> [SpiritualReadingItem] {
        passages.map { passage in
            SpiritualReadingItem(
                id: passage.id,
                reference: passage.reference,
                text: passage.text,
                homily: "",
                practicalConclusion: ""
            )
        }
    }

    private func remoteAIRequestKey(for passages: [ScripturePassage], profile: UserFaithProfile) -> String {
        [
            passages.map(\.id).joined(separator: "+"),
            profile.tradition.rawValue,
            profile.explanationDepth.rawValue,
            profile.favoriteBibleSections.map(\.rawValue).sorted().joined(separator: ","),
            profile.favoriteBooks.map(\.rawValue).sorted().joined(separator: ","),
            profile.favoriteThemes.map(\.rawValue).sorted().joined(separator: ",")
        ].joined(separator: "|")
    }

    private func scheduleLocalUnlockExpiration(at date: Date) {
        cancelLocalUnlockExpiration()
        let seconds = date.timeIntervalSinceNow
        guard seconds > 0 else {
            expireUnlockIfNeeded()
            return
        }

        let nanoseconds = UInt64(min(seconds, 86_400) * 1_000_000_000)
        unlockExpirationTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            await MainActor.run {
                self?.expireUnlockIfNeeded()
            }
        }
    }

    private func cancelLocalUnlockExpiration() {
        unlockExpirationTask?.cancel()
        unlockExpirationTask = nil
    }

    private func expireUnlockIfNeeded() {
        guard let unlockedUntil, unlockedUntil <= Date() else { return }
        self.unlockedUntil = nil
        policyStore.saveUnlockedUntil(nil)
        screenTimeController.applyShield(selection: selection)
        unlockNote = "O período de uso terminou. Faça uma nova leitura para retomar os apps selecionados com presença."
        cancelLocalUnlockExpiration()
    }

    private func rememberShownPassages(_ passages: [ScripturePassage]) {
        let ids = passages.map(\.id)
        recentPassageIDs.removeAll { ids.contains($0) }
        recentPassageIDs.insert(contentsOf: ids, at: 0)
        recentPassageIDs = Array(recentPassageIDs.prefix(isEssentialMode ? 12 : 40))
        policyStore.saveRecentPassageIDs(recentPassageIDs)
    }

    private func refreshRemoteAIContent(
        for passages: [ScripturePassage],
        profile: UserFaithProfile,
        generationID: UUID
    ) {
        let recentPassageIDs = recentPassageIDs
        let recentReflections = recentAIReflections
        aiGenerationTask = Task { [passages, profile, recentPassageIDs, recentReflections] in
            let spiritualReadingService = AISpiritualReadingService()
            let reflectionService = AIReflectionService()
            async let remoteItems = spiritualReadingService.remoteReadingItems(
                for: passages,
                profile: profile,
                recentPassageIDs: recentPassageIDs,
                recentReflections: recentReflections
            )
            async let remoteReflection = reflectionService.remoteReflection(
                for: passages,
                profile: profile,
                recentReflections: recentReflections
            )

            let result = await (remoteItems, remoteReflection)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard aiGenerationID == generationID else { return }
                if let items = result.0, let reflection = result.1 {
                    currentSpiritualReadingItems = items
                    currentReflection = reflection
                    aiContentState = .remoteReady
                    rememberReflection(reference: currentReadingReference, reflection: reflection)
                } else {
                    aiContentState = .fallback
                }
            }
        }
    }

    private func rememberReflection(reference: String, reflection: AIReflection) {
        let digest = RecentAIReflectionDigest(
            reference: reference,
            summary: reflection.summary,
            meditationQuestion: reflection.meditationQuestion,
            createdAt: Date()
        )
        recentAIReflections.removeAll {
            $0.reference == digest.reference
                && $0.summary == digest.summary
                && $0.meditationQuestion == digest.meditationQuestion
        }
        recentAIReflections.insert(digest, at: 0)
        recentAIReflections = Array(recentAIReflections.prefix(16))
        policyStore.saveRecentAIReflections(recentAIReflections)
    }
}
