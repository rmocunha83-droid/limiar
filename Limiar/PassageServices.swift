import Foundation
import os

enum LimiarAIDiagnostics {
    private static let logger = Logger(subsystem: "com.romeucunha.Limiar", category: "ai")

    static func log(
        _ event: String,
        values: [String: String],
        persistForDiagnostics: Bool = false
    ) {
        let values = safeValues(values)
        let detailText = values
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        logger.info("\(event, privacy: .public) \(detailText, privacy: .public)")
        if persistForDiagnostics {
            LimiarEventLog(source: "ai").log(event, values)
        }
    }

    static func profileSnapshot(_ profile: UserFaithProfile) -> [String: String] {
        [:]
    }

    static func safeValues(_ values: [String: String]) -> [String: String] {
        LimiarEventLog.safeAIDetails(values)
    }
}


/// Catálogo de trechos empacotado no app (Resources/passages.json).
/// Editar/expandir o catálogo não exige mudança de código: basta atualizar o
/// JSON (validado por scripts/validate_passages.py) e recompilar.
enum PassageCatalog {
    static let shared: [ScripturePassage] = load()

    private static func load() -> [ScripturePassage] {
        guard let url = Bundle.main.url(forResource: "passages", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ScripturePassage].self, from: data),
              !decoded.isEmpty else {
            LimiarAIDiagnostics.log("passage_catalog_load_failed", values: [:])
            return emergencyFallback
        }
        return decoded
    }

    // Reserva mínima caso o JSON empacotado falhe em carregar (não deveria
    // acontecer; existe para o app nunca abrir sem nenhum trecho).
    private static let emergencyFallback: [ScripturePassage] = [
        ScripturePassage(id: "psalm-23", tradition: .catholic, title: "O Senhor conduz", reference: "Salmo 23", text: "O Senhor é meu pastor: nada me faltará. Em verdes pastagens me faz repousar, para fontes tranquilas me conduz, e restaura minhas forças.", estimatedMinutes: 5, theme: .hope, section: .psalms, book: .psalms),
        ScripturePassage(id: "matthew-6-catholic", tradition: .catholic, title: "Buscar primeiro", reference: "Mateus 6, 33", text: "Buscai primeiro o Reino de Deus e a sua justiça, e todas essas coisas vos serão dadas por acréscimo.", estimatedMinutes: 5, theme: .purpose, section: .gospels, book: .matthew),
        ScripturePassage(id: "proverbs-3-catholic", tradition: .catholic, title: "Confia de todo coração", reference: "Provérbios 3, 5-6", text: "Confia no Senhor de todo o teu coração e não te apoies apenas em teu próprio entendimento. Reconhece-o em teus caminhos.", estimatedMinutes: 5, theme: .wisdom, section: .wisdomBooks, book: .proverbs),
        ScripturePassage(id: "matthew-6", tradition: .protestant, title: "Buscar primeiro", reference: "Mateus 6:33", text: "Busquem, pois, em primeiro lugar o Reino de Deus e a sua justiça, e todas essas coisas lhes serão acrescentadas.", estimatedMinutes: 5, theme: .purpose, section: .gospels, book: .matthew),
        ScripturePassage(id: "psalm-1-protestant", tradition: .protestant, title: "Como árvore junto às águas", reference: "Salmo 1:1-3", text: "Bem-aventurado aquele que tem prazer na lei do Senhor. Ele é como árvore plantada junto a correntes de águas.", estimatedMinutes: 5, theme: .discipline, section: .psalms, book: .psalms),
        ScripturePassage(id: "proverbs-16-protestant", tradition: .protestant, title: "Entregar os planos", reference: "Provérbios 16:3", text: "Consagre ao Senhor tudo o que você faz, e os seus planos serão bem-sucedidos.", estimatedMinutes: 5, theme: .work, section: .wisdomBooks, book: .proverbs),
        ScripturePassage(id: "psalm-121-jewish", tradition: .jewish, title: "O guardião de Israel", reference: "Tehillim / Salmo 121", text: "Elevo os meus olhos para os montes: de onde virá o meu socorro? O meu socorro vem do Eterno, que fez céus e terra.", estimatedMinutes: 5, theme: .hope, section: .psalms, book: .psalms),
        ScripturePassage(id: "proverbs-3-jewish", tradition: .jewish, title: "Caminhos endireitados", reference: "Mishlei / Provérbios 3:5-6", text: "Confia no Eterno de todo o teu coração. Reconhece-o em todos os teus caminhos, e ele endireitará tuas veredas.", estimatedMinutes: 5, theme: .wisdom, section: .wisdomBooks, book: .proverbs),
        ScripturePassage(id: "deuteronomy-6-jewish", tradition: .jewish, title: "Coração inteiro", reference: "Devarim / Deuteronômio 6:5", text: "Amarás o Eterno teu Deus com todo o teu coração, com toda a tua alma e com toda a tua força.", estimatedMinutes: 5, theme: .faith, section: .torah, book: .deuteronomy),
        ScripturePassage(id: "matthew-5-spiritist", tradition: .spiritist, title: "Bem-aventurados os mansos", reference: "Mateus 5:5", text: "Bem-aventurados os mansos, porque herdarão a terra. A mansidão aqui não é fraqueza: é domínio de si antes da resposta impulsiva.", estimatedMinutes: 5, theme: .patience, section: .gospels, book: .matthew),
        ScripturePassage(id: "john-14-spiritist", tradition: .spiritist, title: "Paz antes do impulso", reference: "João 14:27", text: "Deixo-vos a paz, a minha paz vos dou. Não se turbe o vosso coração, nem se atemorize.", estimatedMinutes: 5, theme: .consolationHope, section: .gospels, book: .john),
        ScripturePassage(id: "romans-12-spiritist", tradition: .spiritist, title: "Renovar a mente", reference: "Romanos 12:2", text: "Transformai-vos pela renovação da vossa mente. Cada pausa consciente educa a vontade e fortalece o bem.", estimatedMinutes: 5, theme: .innerReform, section: .paulineLetters, book: .romans)
    ]
}

struct PassageRecommendationService {
    private let passages: [ScripturePassage]
    private let passagesByID: [String: ScripturePassage]
    private let passagesByTraditionAndReference: [String: ScripturePassage]

    init(passages: [ScripturePassage] = PassageCatalog.shared) {
        self.passages = passages
        self.passagesByID = passages.reduce(into: [:]) { result, passage in
            result[passage.id] = passage
        }
        self.passagesByTraditionAndReference = passages.reduce(into: [:]) { result, passage in
            result[Self.referenceKey(passage.reference, tradition: passage.tradition)] = passage
        }
    }

    func nextPassage(
        for profile: UserFaithProfile,
        history: [ReadingHistoryItem],
        avoiding currentPassageID: String? = nil
    ) -> ScripturePassage? {
        readingPlan(for: profile, history: history, avoiding: currentPassageID).first
    }

    func readingPlan(
        for profile: UserFaithProfile,
        history: [ReadingHistoryItem],
        avoiding currentPassageID: String? = nil,
        recentlyShownPassageIDs: [String] = [],
        minimumCount: Int? = nil,
        feedback: [String: ReadingFeedback] = [:]
    ) -> [ScripturePassage] {
        let minimumCount = minimumCount ?? profile.explanationDepth.readingItemCount
        guard minimumCount > 0 else { return [] }
        let ranked = rankedPassages(
            for: profile,
            history: history,
            avoiding: currentPassageID,
            recentlyShownPassageIDs: recentlyShownPassageIDs,
            feedback: feedback
        )
        var plan: [ScripturePassage] = []

        for passage in ranked {
            guard !plan.contains(where: { $0.id == passage.id }) else { continue }
            plan.append(passage)
            if plan.count >= minimumCount { break }
        }

        return plan
    }

    private func rankedPassages(
        for profile: UserFaithProfile,
        history: [ReadingHistoryItem],
        avoiding currentPassageID: String? = nil,
        recentlyShownPassageIDs: [String] = [],
        feedback: [String: ReadingFeedback] = [:]
    ) -> [ScripturePassage] {
        let presented = PassagePresentationHistory.merging(recentlyShownPassageIDs, completed: history)
        let ranks = Dictionary(presented.enumerated().map { ($0.element, $0.offset) }, uniquingKeysWith: min)
        func rank(_ passage: ScripturePassage) -> Int? {
            if passage.id == currentPassageID { return -1 }
            return [ranks[passage.id], ranks[passage.reference]].compactMap { $0 }.min()
        }
        // Only themes may expand. Refined books remain a preference within the
        // eligible books, never a reason to skip an unseen preferred theme.
        var remaining = passages.filter { passage in
            passage.tradition == profile.tradition
                && (profile.favoriteBooks.isEmpty || profile.favoriteBooks.contains(passage.book))
                && (profile.favoriteBibleSections.isEmpty || profile.favoriteBibleSections.contains(passage.section))
        }
        func tier(_ passage: ScripturePassage) -> Int {
            if rank(passage) != nil { return 2 }
            return profile.favoriteThemes.isEmpty || profile.favoriteThemes.contains(passage.theme) ? 0 : 1
        }
        var ordered: [ScripturePassage] = []
        let helpfulThemes = Set(passages.filter { feedback[$0.id] == .helpful }.map(\.theme))
        var previousTheme = presented.compactMap { passagesByID[$0]?.theme }.first
        remaining.sort { lhs, rhs in
            let leftTier = tier(lhs), rightTier = tier(rhs)
            if leftTier != rightTier { return leftTier < rightTier }
            if leftTier == 2, rank(lhs) != rank(rhs) {
                return (rank(lhs) ?? -1) > (rank(rhs) ?? -1)
            }
            if (feedback[lhs.id] == .preferAnother) != (feedback[rhs.id] == .preferAnother) {
                return feedback[lhs.id] != .preferAnother
            }
            let leftPriority = profile.refinedBooks?.contains(lhs.book) == true
            let rightPriority = profile.refinedBooks?.contains(rhs.book) == true
            if leftPriority != rightPriority { return leftPriority }
            if helpfulThemes.contains(lhs.theme) != helpfulThemes.contains(rhs.theme) {
                return helpfulThemes.contains(lhs.theme)
            }
            return lhs.id < rhs.id
        }
        while let first = remaining.first {
            // Variety breaks ties only, never precedence or least-recent order.
            let nextIndex = remaining.firstIndex {
                tier($0) == tier(first) && rank($0) == rank(first) && $0.theme != previousTheme
            } ?? 0
            let next = remaining.remove(at: nextIndex)
            ordered.append(next)
            previousTheme = next.theme
        }
        return ordered
    }

    func passage(withID id: String) -> ScripturePassage? {
        passagesByID[id]
    }

    func passage(matchingReference reference: String, tradition: FaithTradition) -> ScripturePassage? {
        passagesByTraditionAndReference[Self.referenceKey(reference, tradition: tradition)]
    }

    private static func referenceKey(_ reference: String, tradition: FaithTradition) -> String {
        "\(tradition.rawValue)|\(normalizedReference(reference))"
    }

    static func normalizedReference(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
            .replacingOccurrences(of: ":", with: ",")
            .replacingOccurrences(of: " ", with: "")
    }
}

enum PassagePresentationHistory {
    // Most recent first. Recover every surviving legacy completion, not just
    // the recent window; already-discarded history cannot be reconstructed.
    static func merging(_ ids: [String], completed: [ReadingHistoryItem]) -> [String] {
        var seen = Set<String>()
        return (ids + completed.sorted { $0.completedAt > $1.completedAt }.flatMap {
            $0.passageID.split(separator: "+").reversed().map(String.init)
        }).filter { seen.insert($0).inserted }
    }

    static func recording(_ passages: [ScripturePassage], in ids: [String]) -> [String] {
        let shown = passages.reversed().flatMap { [$0.id, $0.reference] }
        return merging(shown + ids, completed: [])
    }
}

enum DailyReadingSessionSource: String, Codable {
    case remote
    case local
}

struct DailyReadingSessionSnapshot: Codable {
    let dayKey: String
    let profileKey: String
    let items: [SpiritualReadingItem]
    let reflection: AIReflection
    let source: DailyReadingSessionSource
    let failureReason: String?
    let reflectionOrderVersion: Int

    init(
        dayKey: String,
        profileKey: String,
        items: [SpiritualReadingItem],
        reflection: AIReflection,
        source: DailyReadingSessionSource = .remote,
        failureReason: String? = nil
    ) {
        self.dayKey = dayKey
        self.profileKey = profileKey
        self.items = items
        self.reflection = reflection
        self.source = source
        self.failureReason = failureReason
        self.reflectionOrderVersion = 1
    }

    private enum CodingKeys: String, CodingKey {
        case dayKey
        case profileKey
        case items
        case reflection
        case source
        case failureReason
        case reflectionOrderVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dayKey = try container.decode(String.self, forKey: .dayKey)
        profileKey = try container.decode(String.self, forKey: .profileKey)
        items = try container.decode([SpiritualReadingItem].self, forKey: .items)
        reflection = try container.decode(AIReflection.self, forKey: .reflection)
        source = try container.decodeIfPresent(DailyReadingSessionSource.self, forKey: .source) ?? .remote
        failureReason = try container.decodeIfPresent(String.self, forKey: .failureReason)
        reflectionOrderVersion = try container.decodeIfPresent(Int.self, forKey: .reflectionOrderVersion) ?? 0
    }
}

enum LocalReadingSessionFactory {
    static func items(from passages: [ScripturePassage], itemCount: Int) -> [SpiritualReadingItem] {
        guard itemCount > 0 else { return [] }
        return passages.prefix(itemCount).map { passage in
            SpiritualReadingItem(
                id: "local.\(passage.id)",
                reference: passage.reference,
                text: passage.text,
                homily: "",
                practicalConclusion: "",
                passageID: passage.id
            )
        }
    }
}

enum LocalSessionUpgradePolicy {
    static func shouldAttempt(
        source: DailyReadingSessionSource,
        isReadingSessionActive: Bool,
        hasCompletedCurrentCycle: Bool
    ) -> Bool {
        source == .local && !isReadingSessionActive && !hasCompletedCurrentCycle
    }
}

/// Guarda até duas sessões: a de hoje e a pré-gerada para o próximo ciclo
/// (criada em background após a travessia ser concluída). Assim o próximo
/// ciclo abre instantaneamente mesmo em cold start.
struct DailyReadingSessionStore {
    private let defaults: UserDefaults
    private let key = "limiar.dailyReadingSession.v2"
    private let legacyKey = "limiar.dailyReadingSession.v1"

    init(defaults: UserDefaults = UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard) {
        self.defaults = defaults
    }

    static func todayKey(_ date: Date = Date()) -> String {
        ScreenTimePolicyStore.cycleDayKey(now: date)
    }

    func load(
        profileKey: String,
        dayKey: String = DailyReadingSessionStore.todayKey(),
        expectedItemCount: Int
    ) -> DailyReadingSessionSnapshot? {
        guard let snapshot = allSnapshots().first(where: { snapshot in
            snapshot.dayKey == dayKey
                && snapshot.profileKey == profileKey
                && snapshot.items.count >= expectedItemCount
        }) else { return nil }
        guard snapshot.reflectionOrderVersion == 0 else { return snapshot }

        // O formato antigo salvava os cards reordenados pelo iOS, mas a reflexão
        // podia continuar numerada segundo a ordem do servidor. Mantém os
        // mesmos versículos e suas homilias, oculta só a reflexão conjunta e
        // permite explicá-los novamente antes de iniciar a travessia.
        let needsNewReflection = snapshot.source == .remote && snapshot.items.count > 1
        let reflection = needsNewReflection
            ? AIReflection(summary: "", spiritualMeaning: "", practicalApplication: "", conclusion: "", meditationQuestion: "")
            : snapshot.reflection
        let migrated = DailyReadingSessionSnapshot(
            dayKey: snapshot.dayKey,
            profileKey: snapshot.profileKey,
            items: snapshot.items,
            reflection: reflection,
            source: needsNewReflection ? .local : snapshot.source,
            failureReason: needsNewReflection ? "legacy_reflection_order" : snapshot.failureReason
        )
        save(migrated)
        return migrated
    }

    func save(_ snapshot: DailyReadingSessionSnapshot) {
        var snapshots = allSnapshots().filter { $0.dayKey != snapshot.dayKey }
        snapshots.append(snapshot)
        persist(snapshots)
    }

    /// A resposta tardia do prewarm nunca substitui a sessão já apresentada.
    @discardableResult
    func saveIfAbsent(_ snapshot: DailyReadingSessionSnapshot, expectedItemCount: Int) -> Bool {
        guard load(profileKey: snapshot.profileKey, dayKey: snapshot.dayKey, expectedItemCount: expectedItemCount) == nil else {
            return false
        }
        save(snapshot)
        return true
    }

    func clear(dayKey: String = DailyReadingSessionStore.todayKey()) {
        persist(allSnapshots().filter { $0.dayKey != dayKey })
    }

    func clearAll() {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: legacyKey)
    }

    private func allSnapshots() -> [DailyReadingSessionSnapshot] {
        if let data = defaults.data(forKey: key),
           let snapshots = try? JSONDecoder().decode([DailyReadingSessionSnapshot].self, from: data) {
            return prune(snapshots)
        }
        // Migração do formato antigo (um único snapshot).
        if let data = defaults.data(forKey: legacyKey),
           let snapshot = try? JSONDecoder().decode(DailyReadingSessionSnapshot.self, from: data) {
            return prune([snapshot])
        }
        return []
    }

    private func prune(_ snapshots: [DailyReadingSessionSnapshot]) -> [DailyReadingSessionSnapshot] {
        // Mantém apenas hoje e dias futuros (chaves yyyy-MM-dd ordenam
        // lexicograficamente); no máximo 2 sessões.
        let today = Self.todayKey()
        return Array(snapshots.filter { $0.dayKey >= today }.sorted { $0.dayKey < $1.dayKey }.prefix(2))
    }

    private func persist(_ snapshots: [DailyReadingSessionSnapshot]) {
        guard let data = try? JSONEncoder().encode(prune(snapshots)) else { return }
        defaults.set(data, forKey: key)
        defaults.removeObject(forKey: legacyKey)
    }
}

enum RemoteAIError: Error {
    case invalidURL
    case invalidResponse
    case invalidPayload
    case emptyContent
}

struct RemoteAIBackendClient {
    var baseURL = URL(string: "https://limiar-five.vercel.app")!
    var timeout: TimeInterval = 36
    var session: URLSession = .shared

    // Opcional e injetado no build por LIMIAR_APP_SECRET. Nunca manter o valor
    // no código-fonte: uma constante dentro do binário não é um segredo real.
    private static var appKey: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "LimiarAppSecret") as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("$(") else { return nil }
        return trimmed
    }

    private static var clientID: String {
        let defaults = UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
        let key = "limiar.ai.clientID"
        if let saved = defaults.string(forKey: key), !saved.isEmpty {
            return saved
        }

        let generated = UUID().uuidString
        defaults.set(generated, forKey: key)
        return generated
    }

    func post<Request: Encodable, Response: Decodable>(
        _ path: String,
        body: Request,
        responseType: Response.Type = Response.self
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw RemoteAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.clientID, forHTTPHeaderField: "X-Limiar-Client-ID")
        if let appKey = Self.appKey {
            request.setValue(appKey, forHTTPHeaderField: "X-Limiar-App-Key")
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw RemoteAIError.invalidResponse
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }

    func postData<Request: Encodable>(_ path: String, body: Request, accept: String) async throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw RemoteAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue(Self.clientID, forHTTPHeaderField: "X-Limiar-Client-ID")
        if let appKey = Self.appKey {
            request.setValue(appKey, forHTTPHeaderField: "X-Limiar-App-Key")
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              !data.isEmpty else {
            throw RemoteAIError.invalidResponse
        }

        return data
    }
}

struct RemotePassagePayload: Codable {
    let id: String
    let title: String
    let reference: String
    let text: String
    let theme: String
    let section: String
    let book: String

    init(_ passage: ScripturePassage) {
        id = passage.id
        title = passage.title
        reference = passage.reference
        text = passage.text
        theme = passage.theme.title
        section = passage.section.title
        book = passage.book.title
    }
}

struct RemoteAIProfilePayload: Codable {
    let tradition: String
    let traditionID: String
    let favoriteSections: [String]
    let favoriteSectionIDs: [String]
    let favoriteBooks: [String]
    let favoriteBookIDs: [String]
    let priorityBooks: [String]
    let priorityBookIDs: [String]
    let favoriteThemes: [String]
    let favoriteThemeIDs: [String]
    let explanationDepth: String
    let avoidedSections: [String]
    let avoidedBooks: [String]
    let toneGuidance: String
    let pauseTurn: String

    init(profile: UserFaithProfile, pauseTurn: PauseCycleTurn) {
        tradition = profile.tradition.title
        traditionID = profile.tradition.rawValue
        favoriteSections = profile.favoriteBibleSections.map(\.title)
        favoriteSectionIDs = profile.selectedSectionOptionIds
        favoriteBooks = profile.favoriteBooks.map(\.title)
        favoriteBookIDs = profile.selectedBookOptionIds
        priorityBooks = (profile.refinedBooks ?? []).map(\.title)
        priorityBookIDs = profile.selectedPriorityBookOptionIds
        favoriteThemes = profile.favoriteThemes.map(\.title)
        favoriteThemeIDs = profile.selectedThemeOptionIds
        explanationDepth = profile.explanationDepth.remoteValue
        avoidedSections = profile.tradition.avoidedSectionTitlesForAI
        avoidedBooks = profile.tradition.avoidedBookTitlesForAI
        toneGuidance = profile.tradition.aiToneGuidance
        self.pauseTurn = pauseTurn.remoteValue
    }
}

struct RemoteAIReflectionDigestPayload: Codable {
    let reference: String
    let summary: String
    let meditationQuestion: String
    let openings: [String]?
    let applications: [String]?

    init(_ digest: RecentAIReflectionDigest) {
        reference = digest.reference
        summary = digest.summary
        meditationQuestion = digest.meditationQuestion
        openings = digest.openings
        applications = digest.applications
    }
}

struct RemoteReadingSessionRequestPayload: Codable {
    var explanationDiversityVersion: Int? = 1
    let profile: RemoteAIProfilePayload
    let passages: [RemotePassagePayload]
    let itemCount: Int
    let recentPassageIDs: [String]
    let recentReflections: [RemoteAIReflectionDigestPayload]
}

struct RemoteSpeechRequestPayload: Codable {
    let text: String
    let voice: String?
    let speed: Double?
}

struct RemoteSpiritualReadingItemResponse: Codable {
    let reference: String
    let passageText: String
    let passageID: String?
    let homily: String
    let spiritualMeaning: String?
    let practicalApplication: String?
    let conclusion: String
    let meditationQuestion: String?

    func validatedItem(cacheKey: String, index: Int) throws -> SpiritualReadingItem {
        let cleanReference = reference.trimmedForAI
        let cleanText = passageText.trimmedForAI
        let cleanHomily = homily.trimmedForAI
        let cleanPracticalApplication = practicalApplication?.trimmedForAI ?? ""
        let cleanConclusion = conclusion.trimmedForAI
        let practicalText = cleanPracticalApplication.isEmpty ? cleanConclusion : cleanPracticalApplication

        guard !cleanReference.isEmpty,
              !cleanText.isEmpty,
              !cleanHomily.isEmpty,
              !practicalText.isEmpty else {
            throw RemoteAIError.emptyContent
        }

        return SpiritualReadingItem(
            id: "\(cacheKey).remote.\(index).\(cleanReference)",
            reference: cleanReference,
            text: cleanText,
            homily: cleanHomily,
            practicalConclusion: practicalText,
            passageID: passageID?.trimmedForAI,
            meditationQuestion: meditationQuestion?.trimmedForAI
        )
    }
}

struct RemoteReflectionResponse: Codable {
    let reference: String
    let passageText: String
    let homily: String
    let spiritualMeaning: String
    let practicalApplication: String
    let conclusion: String
    let meditationQuestion: String

    func validatedReflection() throws -> AIReflection {
        let cleanHomily = homily.trimmedForAI
        let cleanMeaning = spiritualMeaning.trimmedForAI
        let cleanApplication = practicalApplication.trimmedForAI
        let cleanConclusion = conclusion.trimmedForAI
        let cleanQuestion = meditationQuestion.trimmedForAI

        guard !reference.trimmedForAI.isEmpty,
              !passageText.trimmedForAI.isEmpty,
              !cleanHomily.isEmpty,
              !cleanMeaning.isEmpty,
              !cleanApplication.isEmpty,
              !cleanConclusion.isEmpty,
              !cleanQuestion.isEmpty else {
            throw RemoteAIError.emptyContent
        }

        return AIReflection(
            summary: cleanHomily,
            spiritualMeaning: cleanMeaning,
            practicalApplication: cleanApplication,
            conclusion: cleanConclusion,
            meditationQuestion: cleanQuestion
        )
    }
}

struct RemoteReadingSessionResponse: Codable {
    let items: [RemoteSpiritualReadingItemResponse]
    let reflection: RemoteReflectionResponse
}

struct RemoteReadingSessionResult {
    let items: [SpiritualReadingItem]
    let reflection: AIReflection
}

enum RemoteReadingSessionOutcome {
    case success(RemoteReadingSessionResult)
    case failure(reason: String)
}

struct RemoteAIReadingSessionService {
    private let client: RemoteAIBackendClient

    init(client: RemoteAIBackendClient = RemoteAIBackendClient(timeout: 34)) {
        self.client = client
    }

    func readingSession(
        for passages: [ScripturePassage],
        profile: UserFaithProfile,
        pauseTurn: PauseCycleTurn,
        recentPassageIDs: [String],
        recentReflections: [RecentAIReflectionDigest]
    ) async -> RemoteReadingSessionOutcome {
        let startedAt = Date()
        var deliveryOutcome = "failed"
        var deliveredCount = 0
        defer {
            LimiarAIDiagnostics.log("reading_delivery", values: [
                "outcome": deliveryOutcome,
                "durationMs": String(max(0, Int(Date().timeIntervalSince(startedAt) * 1000))),
                "items": String(deliveredCount)
            ], persistForDiagnostics: true)
        }
        // The complete persistent history is evaluated locally. Send only the
        // final selection so a server-side recent window cannot reselect it.
        let selected = Array(passages.prefix(profile.explanationDepth.readingItemCount))
        let payload = RemoteReadingSessionRequestPayload(
            profile: RemoteAIProfilePayload(profile: profile, pauseTurn: pauseTurn),
            passages: selected.map(RemotePassagePayload.init),
            itemCount: selected.count,
            recentPassageIDs: Array(recentPassageIDs.prefix(40)),
            recentReflections: recentReflections.prefix(8).map(RemoteAIReflectionDigestPayload.init)
        )

        do {
            let response = try await client.post(
                "/api/reading-session",
                body: payload,
                responseType: RemoteReadingSessionResponse.self
            )
            let receivedItems = try response.items.enumerated().map { index, item in
                try item.validatedItem(cacheKey: "session", index: index)
            }
            let items = try Self.orderedItems(receivedItems, for: selected)
            let expectedItemCount = min(profile.explanationDepth.readingItemCount, max(1, passages.count))
            guard items.count >= expectedItemCount else {
                LimiarAIDiagnostics.log("ai_fallback", values: [
                    "endpoint": "reading-session",
                    "reason": "unexpected_item_count",
                    "count": "\(items.count)"
                ])
                return .failure(reason: "unexpected_item_count")
            }
            let reflection = try response.reflection.validatedReflection()
            deliveryOutcome = "remote"
            deliveredCount = items.count
            var values = LimiarAIDiagnostics.profileSnapshot(profile)
            values["source"] = "remote"
            values["endpoint"] = "reading-session"
            values["items"] = "\(items.count)"
            LimiarAIDiagnostics.log("ai_reading_session_loaded", values: values)
            return .success(
                RemoteReadingSessionResult(
                    items: Array(items.prefix(expectedItemCount)),
                    reflection: reflection
                )
            )
        } catch {
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                deliveryOutcome = "cancelled"
            }
            let reason = diagnosticReason(for: error)
            LimiarAIDiagnostics.log("ai_fallback", values: [
                "endpoint": "reading-session",
                "reason": reason
            ])
            return .failure(reason: reason)
        }
    }

    static func orderedItems(_ items: [SpiritualReadingItem], for selected: [ScripturePassage]) throws -> [SpiritualReadingItem] {
        guard items.count == selected.count else { throw URLError(.cannotParseResponse) }
        for (item, passage) in zip(items, selected) {
            guard item.passageID == passage.id,
                  item.reference == passage.reference,
                  item.text == passage.text else {
                throw URLError(.cannotParseResponse)
            }
        }
        return items
    }

    private func diagnosticReason(for error: Error) -> String {
        if let urlError = error as? URLError {
            return "url_error_\(urlError.code.rawValue)"
        }
        if error is DecodingError {
            return "invalid_response_payload"
        }
        guard let remoteError = error as? RemoteAIError else {
            return "request_failed"
        }
        switch remoteError {
        case .invalidURL:
            return "invalid_url"
        case .invalidResponse:
            return "invalid_response"
        case .invalidPayload:
            return "invalid_payload"
        case .emptyContent:
            return "empty_content"
        }
    }
}

struct RemoteAISpeechService {
    private let client: RemoteAIBackendClient

    init(client: RemoteAIBackendClient = RemoteAIBackendClient(timeout: 90)) {
        self.client = client
    }

    func audioData(
        for text: String,
        voice: NarrationVoicePreference = .antonio
    ) async throws -> Data {
        let payload = RemoteSpeechRequestPayload(
            text: text,
            voice: voice.rawValue,
            speed: 0.92
        )

        return try await client.postData("/api/speech", body: payload, accept: "audio/mpeg")
    }
}

private extension ExplanationDepth {
    var remoteValue: String {
        switch self {
        case .short:
            "curta"
        case .medium:
            "média"
        case .deep:
            "profunda"
        }
    }

    var aiGenerationGuidance: String {
        switch self {
        case .short:
            "Curta: 1 parágrafo breve, linguagem direta e aplicação de uma frase."
        case .medium:
            "Média: 2 parágrafos equilibrados, com sentido espiritual e aplicação prática."
        case .deep:
            "Mais profunda: 3 ou mais parágrafos, com contexto do trecho, ligação com a vida do usuário e aplicação mais elaborada."
        }
    }
}

private extension PauseCycleTurn {
    var remoteValue: String {
        switch self {
        case .morning: "morning"
        case .afternoon: "afternoon"
        case .evening: "evening"
        }
    }
}

private extension String {
    var trimmedForAI: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
