import Foundation

struct PassageRecommendationService {
    private let passages: [ScripturePassage] = [
        ScripturePassage(
            id: "psalm-23",
            tradition: .catholic,
            title: "O Senhor conduz",
            reference: "Salmo 23",
            text: "O Senhor é meu pastor: nada me faltará. Em verdes pastagens me faz repousar, para fontes tranquilas me conduz, e restaura minhas forças.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "john-15",
            tradition: .catholic,
            title: "Permanecer no essencial",
            reference: "João 15, 4-5",
            text: "Permanecei em mim e eu permanecerei em vós. Como o ramo não pode dar fruto por si mesmo, se não permanecer na videira, assim também vós.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "matthew-6",
            tradition: .protestant,
            title: "Buscar primeiro",
            reference: "Mateus 6:33",
            text: "Busquem, pois, em primeiro lugar o Reino de Deus e a sua justiça, e todas essas coisas lhes serão acrescentadas.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "romans-12",
            tradition: .protestant,
            title: "Mente renovada",
            reference: "Romanos 12:2",
            text: "Não se amoldem ao padrão deste mundo, mas transformem-se pela renovação da sua mente, para que sejam capazes de experimentar a boa vontade de Deus.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .paulineLetters,
            book: .romans
        ),
        ScripturePassage(
            id: "proverbs-4",
            tradition: .jewish,
            title: "Guardar o coração",
            reference: "Mishlei / Provérbios 4:23",
            text: "Acima de tudo, guarda o teu coração, porque dele procedem as fontes da vida.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "isaiah-58",
            tradition: .jewish,
            title: "Luz que nasce",
            reference: "Yeshayahu / Isaías 58:8",
            text: "Então a tua luz romperá como a aurora, e a tua cura brotará sem demora.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "matthew-5-spiritist",
            tradition: .spiritist,
            title: "Bem-aventurados os mansos",
            reference: "Mateus 5:5",
            text: "Bem-aventurados os mansos, porque herdarão a terra. A mansidão aqui não é fraqueza: é domínio de si antes da resposta impulsiva.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "john-14-spiritist",
            tradition: .spiritist,
            title: "Paz antes do impulso",
            reference: "João 14:27",
            text: "Deixo-vos a paz, a minha paz vos dou. Não se turbe o vosso coração, nem se atemorize.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .gospels,
            book: .john
        )
    ]

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
        targetMinutes: Int = 10
    ) -> [ScripturePassage] {
        let ranked = rankedPassages(for: profile, history: history, avoiding: currentPassageID)
        var plan: [ScripturePassage] = []
        var totalMinutes = 0

        for passage in ranked {
            guard !plan.contains(where: { $0.id == passage.id }) else { continue }
            plan.append(passage)
            totalMinutes += passage.estimatedMinutes
            if totalMinutes >= targetMinutes { break }
        }

        return plan.isEmpty ? Array(passages.prefix(1)) : plan
    }

    private func rankedPassages(
        for profile: UserFaithProfile,
        history: [ReadingHistoryItem],
        avoiding currentPassageID: String? = nil
    ) -> [ScripturePassage] {
        let lastID = history.first?.passageID
        let recentIDs = Set(history.prefix(5).map(\.passageID))
        let traditionMatches = passages.filter { $0.tradition == profile.tradition }
        let scored: [(passage: ScripturePassage, score: Int)] = traditionMatches.map { passage in
            var score = 0
            if profile.favoriteBooks.contains(passage.book) { score += 4 }
            if profile.favoriteBibleSections.contains(passage.section) { score += 3 }
            if profile.favoriteThemes.contains(passage.theme) { score += 2 }
            if lastID?.contains(passage.id) == true { score -= 10 }
            if recentIDs.contains(where: { $0.contains(passage.id) }) { score -= 4 }
            if passage.id == currentPassageID { score -= 8 }
            return (passage, score)
        }
        return scored.sorted(by: { $0.score > $1.score }).map(\.passage)
            + passages.filter { passage in
                !traditionMatches.contains(where: { $0.id == passage.id })
            }
    }
}

struct AIReflectionRequest: Codable, Hashable {
    let tradition: FaithTradition
    let passageReference: String
    let passageText: String
    let favoriteThemes: [SpiritualTheme]
    let explanationDepth: ExplanationDepth

    var cacheKey: String {
        let themes = favoriteThemes.map(\.rawValue).sorted().joined(separator: ",")
        let rawKey = [
            tradition.rawValue,
            passageReference,
            explanationDepth.rawValue,
            themes
        ].joined(separator: "|")
        return Data(rawKey.utf8).base64EncodedString()
    }

    var compactPrompt: String {
        let themes = favoriteThemes.map(\.title).joined(separator: ", ")
        let compactText = String(passageText.prefix(1200))
        return """
        Explique este trecho para um usuário \(tradition.title). Seja claro, breve e pastoral. Não invente conteúdo bíblico. Retorne: resumo, significado espiritual, aplicação prática, conclusão e pergunta de meditação.
        Referência: \(passageReference)
        Temas: \(themes)
        Profundidade: \(explanationDepth.title)
        Texto: \(compactText)
        """
    }
}

protocol AIReflectionGenerating {
    func generateReflection(for request: AIReflectionRequest) -> AIReflection
}

struct LocalLightweightReflectionGenerator: AIReflectionGenerating {
    func generateReflection(for request: AIReflectionRequest) -> AIReflection {
        let tone = switch request.tradition {
        case .catholic: "O trecho pode ser acolhido como uma pequena homilia para voltar ao essencial com serenidade."
        case .protestant: "O trecho funciona como devocional breve para reorganizar prioridades diante de Deus."
        case .jewish: "O trecho pode ser lido como sabedoria prática do Tanakh para orientar a próxima escolha."
        case .spiritist: "O trecho convida à reforma íntima, responsabilidade e caridade nas escolhas concretas."
        }

        let practical = switch request.explanationDepth {
        case .short:
            "Antes de seguir, escolha uma atitude simples que proteja sua atenção."
        case .medium:
            "Antes de seguir, respire, observe o impulso e escolha uma atitude simples que proteja sua atenção nos próximos minutos."
        case .deep:
            "Antes de seguir, observe o impulso sem brigar com ele, nomeie o que está buscando e escolha uma atitude concreta que aproxime sua atenção do que você considera mais importante."
        }

        return AIReflection(
            summary: "Este trecho abre um pequeno espaço entre o impulso e a escolha.",
            spiritualMeaning: tone,
            practicalApplication: practical,
            conclusion: "O limiar não interrompe a vida; ele ajuda você a atravessar com mais presença.",
            meditationQuestion: "Que escolha pequena deixa este próximo momento mais consciente?"
        )
    }
}

struct AIReflectionCache {
    private let defaults = UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    private let keyPrefix = "aiReflectionCache."

    func reflection(for request: AIReflectionRequest) -> AIReflection? {
        guard let data = defaults.data(forKey: keyPrefix + request.cacheKey) else { return nil }
        return try? JSONDecoder().decode(AIReflection.self, from: data)
    }

    func save(_ reflection: AIReflection, for request: AIReflectionRequest) {
        guard let data = try? JSONEncoder().encode(reflection) else { return }
        defaults.set(data, forKey: keyPrefix + request.cacheKey)
    }
}

struct AIReflectionService {
    private let cache: AIReflectionCache
    private let generator: any AIReflectionGenerating

    init(
        cache: AIReflectionCache = AIReflectionCache(),
        generator: any AIReflectionGenerating = LocalLightweightReflectionGenerator()
    ) {
        self.cache = cache
        self.generator = generator
    }

    func reflection(for passage: ScripturePassage, profile: UserFaithProfile) -> AIReflection {
        reflection(for: [passage], profile: profile)
    }

    func reflection(for passages: [ScripturePassage], profile: UserFaithProfile) -> AIReflection {
        let passageReference = passages.map(\.reference).joined(separator: " + ")
        let passageText = passages.map { "\($0.reference): \($0.text)" }.joined(separator: "\n\n")
        let request = AIReflectionRequest(
            tradition: profile.tradition,
            passageReference: passageReference,
            passageText: passageText,
            favoriteThemes: profile.favoriteThemes,
            explanationDepth: profile.explanationDepth
        )
        if let cached = cache.reflection(for: request) {
            return cached
        }

        let reflection = generator.generateReflection(for: request)
        cache.save(reflection, for: request)
        return reflection
    }
}
