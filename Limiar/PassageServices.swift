import Foundation
import os

enum LimiarReadingConstants {
    static let targetItemCount = 3
}

enum LimiarAIDiagnostics {
    private static let logger = Logger(subsystem: "com.romeucunha.Limiar", category: "ai")

    static func log(_ event: String, values: [String: String]) {
        let detailText = values
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        logger.info("\(event, privacy: .public) \(detailText, privacy: .public)")
    }

    static func profileSnapshot(_ profile: UserFaithProfile) -> [String: String] {
        [
            "tradition": profile.tradition.rawValue,
            "depth": profile.explanationDepth.rawValue,
            "sections": profile.favoriteBibleSections.map(\.rawValue).sorted().joined(separator: ","),
            "books": profile.favoriteBooks.map(\.rawValue).sorted().joined(separator: ","),
            "themes": profile.favoriteThemes.map(\.rawValue).sorted().joined(separator: ",")
        ]
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

    init(passages: [ScripturePassage] = PassageCatalog.shared) {
        self.passages = passages
    }

    func nextPassage(
        for profile: UserFaithProfile,
        history: [ReadingHistoryItem],
        avoiding currentPassageID: String? = nil
    ) -> ScripturePassage {
        readingPlan(for: profile, history: history, avoiding: currentPassageID).first
            ?? passages[0]
    }

    func readingPlan(
        for profile: UserFaithProfile,
        history: [ReadingHistoryItem],
        avoiding currentPassageID: String? = nil,
        recentlyShownPassageIDs: [String] = [],
        minimumCount: Int = LimiarReadingConstants.targetItemCount
    ) -> [ScripturePassage] {
        let ranked = rankedPassages(
            for: profile,
            history: history,
            avoiding: currentPassageID,
            recentlyShownPassageIDs: recentlyShownPassageIDs
        )
        var plan: [ScripturePassage] = []

        for passage in ranked {
            guard !plan.contains(where: { $0.id == passage.id }) else { continue }
            plan.append(passage)
            if plan.count >= minimumCount { break }
        }

        if plan.count < minimumCount {
            for passage in passages where passage.tradition == profile.tradition && !plan.contains(where: { $0.id == passage.id }) {
                plan.append(passage)
                if plan.count >= minimumCount { break }
            }
        }

        if plan.isEmpty {
            let fallback = passages.filter { $0.tradition == profile.tradition }
            return Array((fallback.isEmpty ? passages : fallback).shuffled().prefix(minimumCount))
        }

        return plan
    }

    private func rankedPassages(
        for profile: UserFaithProfile,
        history: [ReadingHistoryItem],
        avoiding currentPassageID: String? = nil,
        recentlyShownPassageIDs: [String] = []
    ) -> [ScripturePassage] {
        let lastID = history.first?.passageID
        let completedIDs = history.prefix(8).flatMap { item in
            item.passageID.split(separator: "+").map(String.init)
        }
        let recentIDs = Set(completedIDs + recentlyShownPassageIDs.prefix(36))
        let traditionMatches = passages.filter { $0.tradition == profile.tradition }
        let scored: [(passage: ScripturePassage, score: Int)] = traditionMatches.map { passage in
            var score = 0
            if profile.favoriteBooks.contains(passage.book) { score += 4 }
            if profile.favoriteBibleSections.contains(passage.section) { score += 3 }
            if profile.favoriteThemes.contains(passage.theme) { score += 2 }
            if lastID?.contains(passage.id) == true { score -= 10 }
            if recentIDs.contains(passage.id) { score -= 12 }
            if passage.id == currentPassageID { score -= 8 }
            return (passage, score)
        }
        let rankedMatches = scored.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.passage.id < rhs.passage.id
            }
            return lhs.score > rhs.score
        }
        let freshMatches = rankedMatches.filter { entry in
            !recentIDs.contains(entry.passage.id) && entry.passage.id != currentPassageID
        }
        let olderMatches = rankedMatches.filter { entry in
            recentIDs.contains(entry.passage.id) || entry.passage.id == currentPassageID
        }

        // Variedade sem perder personalização: embaralha apenas dentro de cada
        // faixa de pontuação, preservando a ordem ditada pelas preferências.
        let freshOrdered = Dictionary(grouping: freshMatches, by: \.score)
            .sorted { $0.key > $1.key }
            .flatMap { $0.value.shuffled() }
            .map(\.passage)

        return freshOrdered + olderMatches.shuffled().map(\.passage)
    }

    func passage(withID id: String) -> ScripturePassage? {
        passages.first { $0.id == id }
    }

    func passage(matchingReference reference: String, tradition: FaithTradition) -> ScripturePassage? {
        let normalized = Self.normalizedReference(reference)
        return passages.first { passage in
            passage.tradition == tradition && Self.normalizedReference(passage.reference) == normalized
        }
    }

    static func normalizedReference(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
            .replacingOccurrences(of: ":", with: ",")
            .replacingOccurrences(of: " ", with: "")
    }
}

struct DailyReadingSessionSnapshot: Codable {
    let dayKey: String
    let profileKey: String
    let items: [SpiritualReadingItem]
    let reflection: AIReflection
}

/// Guarda até duas sessões: a de hoje e a pré-gerada para o próximo ciclo
/// (criada em background após a travessia ser concluída). Assim a manhã
/// seguinte abre instantânea mesmo em cold start.
struct DailyReadingSessionStore {
    private let defaults = UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    private let key = "limiar.dailyReadingSession.v2"
    private let legacyKey = "limiar.dailyReadingSession.v1"

    static func todayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = ScreenTimePolicyStore.morningTimeZone
        let cycleStart = ScreenTimePolicyStore.currentMorningCycleStart(now: date)
        return formatter.string(from: cycleStart)
    }

    func load(profileKey: String, dayKey: String = DailyReadingSessionStore.todayKey()) -> DailyReadingSessionSnapshot? {
        allSnapshots().first { snapshot in
            snapshot.dayKey == dayKey
                && snapshot.profileKey == profileKey
                && snapshot.items.count >= LimiarReadingConstants.targetItemCount
        }
    }

    func save(_ snapshot: DailyReadingSessionSnapshot) {
        var snapshots = allSnapshots().filter { $0.dayKey != snapshot.dayKey }
        snapshots.append(snapshot)
        persist(snapshots)
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
    let favoriteThemes: [String]
    let favoriteThemeIDs: [String]
    let explanationDepth: String
    let avoidedSections: [String]
    let avoidedBooks: [String]
    let toneGuidance: String

    init(profile: UserFaithProfile) {
        tradition = profile.tradition.title
        traditionID = profile.tradition.rawValue
        favoriteSections = profile.favoriteBibleSections.map(\.title)
        favoriteSectionIDs = profile.selectedSectionOptionIds
        favoriteBooks = profile.favoriteBooks.map(\.title)
        favoriteBookIDs = profile.selectedBookOptionIds
        favoriteThemes = profile.favoriteThemes.map(\.title)
        favoriteThemeIDs = profile.selectedThemeOptionIds
        explanationDepth = profile.explanationDepth.remoteValue
        avoidedSections = profile.tradition.avoidedSectionTitlesForAI
        avoidedBooks = profile.tradition.avoidedBookTitlesForAI
        toneGuidance = profile.tradition.aiToneGuidance
    }
}

struct RemoteAIReflectionDigestPayload: Codable {
    let reference: String
    let summary: String
    let meditationQuestion: String

    init(_ digest: RecentAIReflectionDigest) {
        reference = digest.reference
        summary = digest.summary
        meditationQuestion = digest.meditationQuestion
    }
}

struct RemoteReadingSessionRequestPayload: Codable {
    let profile: RemoteAIProfilePayload
    let passages: [RemotePassagePayload]
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
            passageID: passageID?.trimmedForAI
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

struct RemoteAIReadingSessionService {
    private let client: RemoteAIBackendClient

    init(client: RemoteAIBackendClient = RemoteAIBackendClient(timeout: 34)) {
        self.client = client
    }

    func readingSession(
        for passages: [ScripturePassage],
        profile: UserFaithProfile,
        recentPassageIDs: [String],
        recentReflections: [RecentAIReflectionDigest]
    ) async -> RemoteReadingSessionResult? {
        let payload = RemoteReadingSessionRequestPayload(
            profile: RemoteAIProfilePayload(profile: profile),
            passages: passages.map(RemotePassagePayload.init),
            recentPassageIDs: Array(recentPassageIDs.prefix(40)),
            recentReflections: recentReflections.prefix(8).map(RemoteAIReflectionDigestPayload.init)
        )

        do {
            let response = try await client.post(
                "/api/reading-session",
                body: payload,
                responseType: RemoteReadingSessionResponse.self
            )
            let items = try response.items.enumerated().map { index, item in
                try item.validatedItem(cacheKey: "session", index: index)
            }
            guard items.count >= min(LimiarReadingConstants.targetItemCount, max(1, passages.count)) else {
                LimiarAIDiagnostics.log("ai_fallback", values: [
                    "endpoint": "reading-session",
                    "reason": "unexpected_item_count",
                    "count": "\(items.count)"
                ])
                return nil
            }
            let reflection = try response.reflection.validatedReflection()
            var values = LimiarAIDiagnostics.profileSnapshot(profile)
            values["source"] = "remote"
            values["endpoint"] = "reading-session"
            values["items"] = "\(items.count)"
            LimiarAIDiagnostics.log("ai_reading_session_loaded", values: values)
            return RemoteReadingSessionResult(items: items, reflection: reflection)
        } catch {
            LimiarAIDiagnostics.log("ai_fallback", values: [
                "endpoint": "reading-session",
                "reason": String(describing: error)
            ])
            return nil
        }
    }
}

struct RemoteAISpeechService {
    private static let limiarNarrationVoiceID = "21m00Tcm4TlvDq8ikWAM"
    private let client: RemoteAIBackendClient

    init(client: RemoteAIBackendClient = RemoteAIBackendClient(timeout: 30)) {
        self.client = client
    }

    func audioData(for text: String) async throws -> Data {
        let payload = RemoteSpeechRequestPayload(
            text: text,
            voice: Self.limiarNarrationVoiceID,
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

private extension String {
    var trimmedForAI: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
