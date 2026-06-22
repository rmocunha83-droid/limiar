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

    var id: String { rawValue }

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

@MainActor
@Observable
final class LimiarAppModel {
    var hasCompletedOnboarding = false
    var faithProfile = UserFaithProfile.starter
    var unlockDurationMinutes = 30
    var blockingEnabled = true
    var selection = FamilyActivitySelection()
    var currentReadingPlan: [ScripturePassage] = []
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

    private let recommender = PassageRecommendationService()
    private let reflectionService = AIReflectionService()
    private let policyStore = ScreenTimePolicyStore()
    private let screenTimeController = ScreenTimeController()
    private var lastForegroundRefreshAt = Date.distantPast

    init() {
        let savedProfile = policyStore.loadFaithProfile() ?? .starter
        faithProfile = savedProfile
        hasCompletedOnboarding = policyStore.loadOnboardingState()
        unlockDurationMinutes = policyStore.loadUnlockDuration()
        blockingEnabled = policyStore.loadBlockingEnabled()
        selection = policyStore.loadSelection()
        unlockedUntil = policyStore.loadUnlockedUntil()
        history = policyStore.loadHistory()
        favoritePassages = policyStore.loadFavorites()

        setReadingPlan(recommender.readingPlan(for: savedProfile, history: history), profile: savedProfile)
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
        readingProgress >= 0.78 || Date().timeIntervalSince(readingStartedAt) >= 90
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
        currentReadingPlan.enumerated().map { index, passage in
            if currentReadingPlan.count == 1 {
                return passage.text
            }
            return "\(index + 1). \(passage.reference)\n\(passage.text)"
        }
        .joined(separator: "\n\n")
    }

    var currentReadingNarrationText: String {
        "\(currentReadingTitle). \(currentReadingReference). \(currentReadingText)"
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        policyStore.saveOnboardingState(true)
        saveProfile()
        applyBlocking()
    }

    func saveProfile() {
        policyStore.saveFaithProfile(faithProfile)
        policyStore.saveUnlockDuration(unlockDurationMinutes)
        policyStore.saveBlockingEnabled(blockingEnabled)
        policyStore.saveSelection(selection)
    }

    func beginNewReading(avoidingCurrent: Bool = false) {
        readingProgress = 0
        readingStartedAt = Date()
        setReadingPlan(recommender.readingPlan(
            for: faithProfile,
            history: history,
            avoiding: avoidingCurrent ? currentPassage.id : nil
        ), profile: faithProfile)
    }

    func prepareFreshPassageForForeground() {
        reapplyBlockIfNeeded()
        guard hasCompletedOnboarding else { return }
        guard !isReadingSessionActive else { return }
        guard readingProgress == 0 else { return }
        guard Date().timeIntervalSince(lastForegroundRefreshAt) > 2 else { return }
        lastForegroundRefreshAt = Date()
        beginNewReading(avoidingCurrent: true)
    }

    func startReadingSession() {
        isReadingSessionActive = true
        readingProgress = 0
        readingStartedAt = Date()
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

    func finishReading() {
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
        unlockNote = "Liberado até \(until.formatted(date: .omitted, time: .shortened))."
        beginNewReading()
    }

    func applyBlocking() {
        guard blockingEnabled else {
            screenTimeController.clearShield()
            return
        }
        if let unlockedUntil, unlockedUntil > Date() {
            screenTimeController.clearShield()
            screenTimeController.scheduleUnlockExpiration(at: unlockedUntil)
            return
        }
        screenTimeController.applyShield(selection: selection)
    }

    func reapplyBlockIfNeeded() {
        guard blockingEnabled else { return }
        if let unlockedUntil, unlockedUntil > Date() {
            screenTimeController.clearShield()
            screenTimeController.scheduleUnlockExpiration(at: unlockedUntil)
        } else {
            self.unlockedUntil = nil
            policyStore.saveUnlockedUntil(nil)
            screenTimeController.applyShield(selection: selection)
        }
    }

    func requestAuthorization() async -> String {
        do {
            try await screenTimeController.requestAuthorization()
            return "Permissão concedida."
        } catch {
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
        currentReadingPlan = resolvedPlan
        currentPassage = resolvedPlan[0]
        currentReflection = reflectionService.reflection(for: resolvedPlan, profile: profile)
    }
}
