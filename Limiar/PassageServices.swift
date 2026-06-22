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
            id: "luke-10-catholic",
            tradition: .catholic,
            title: "Uma só coisa necessária",
            reference: "Lucas 10, 41-42",
            text: "Marta, Marta, tu te inquietas e te agitas por muitas coisas. No entanto, uma só coisa é necessária.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .gospels,
            book: .luke
        ),
        ScripturePassage(
            id: "matthew-11-catholic",
            tradition: .catholic,
            title: "Descanso para a alma",
            reference: "Mateus 11, 28-30",
            text: "Vinde a mim, todos vós que estais cansados, e eu vos darei descanso. Aprendei de mim, porque sou manso e humilde de coração.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "psalm-121-catholic",
            tradition: .catholic,
            title: "Ele guarda teus passos",
            reference: "Salmo 121",
            text: "Ele não permitirá que teus pés vacilem. O Senhor te guarda; ele guarda tua saída e tua entrada.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "proverbs-3-catholic",
            tradition: .catholic,
            title: "Confia de todo coração",
            reference: "Provérbios 3, 5-6",
            text: "Confia no Senhor de todo o teu coração e não te apoies apenas em teu próprio entendimento. Reconhece-o em teus caminhos.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "romans-8-catholic",
            tradition: .catholic,
            title: "Nada pode separar",
            reference: "Romanos 8, 38-39",
            text: "Nem a morte, nem a vida, nem o presente, nem o futuro poderão nos separar do amor de Deus.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .paulineLetters,
            book: .romans
        ),
        ScripturePassage(
            id: "isaiah-40-catholic",
            tradition: .catholic,
            title: "Forças renovadas",
            reference: "Isaías 40, 31",
            text: "Os que esperam no Senhor renovam suas forças. Caminham sem se cansar e seguem sem desfalecer.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .prophets,
            book: .isaiah
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
            id: "john-8-protestant",
            tradition: .protestant,
            title: "A verdade liberta",
            reference: "João 8:31-32",
            text: "Se vocês permanecerem na minha palavra, verdadeiramente serão meus discípulos. Então conhecerão a verdade, e a verdade os libertará.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "psalm-1-protestant",
            tradition: .protestant,
            title: "Como árvore junto às águas",
            reference: "Salmo 1:1-3",
            text: "Bem-aventurado aquele que tem prazer na lei do Senhor. Ele é como árvore plantada junto a correntes de águas.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "proverbs-16-protestant",
            tradition: .protestant,
            title: "Entregar os planos",
            reference: "Provérbios 16:3",
            text: "Consagre ao Senhor tudo o que você faz, e os seus planos serão bem-sucedidos.",
            estimatedMinutes: 5,
            theme: .work,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "matthew-11-protestant",
            tradition: .protestant,
            title: "Alívio para o cansaço",
            reference: "Mateus 11:28-30",
            text: "Venham a mim todos os que estão cansados e sobrecarregados, e eu lhes darei descanso.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "isaiah-41-protestant",
            tradition: .protestant,
            title: "Não temas",
            reference: "Isaías 41:10",
            text: "Não temas, porque eu sou contigo. Não te assombres, porque eu sou o teu Deus. Eu te fortaleço e te ajudo.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "corinthians-13-protestant",
            tradition: .protestant,
            title: "O amor permanece",
            reference: "1 Coríntios 13:4-7",
            text: "O amor é paciente, o amor é bondoso. Não se irrita facilmente, não guarda rancor e tudo sofre, tudo crê, tudo espera.",
            estimatedMinutes: 5,
            theme: .family,
            section: .paulineLetters,
            book: .corinthians
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
            id: "genesis-12-jewish",
            tradition: .jewish,
            title: "Caminhar com confiança",
            reference: "Bereshit / Gênesis 12:1-2",
            text: "Vai para a terra que eu te mostrarei. Farei de ti uma grande nação e tu serás uma bênção.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .torah,
            book: .genesis
        ),
        ScripturePassage(
            id: "exodus-14-jewish",
            tradition: .jewish,
            title: "Ficar firme",
            reference: "Shemot / Êxodo 14:13-14",
            text: "Não temais. Permanecei firmes e vede o livramento que o Eterno realizará. O Eterno lutará por vós.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .torah,
            book: .exodus
        ),
        ScripturePassage(
            id: "psalm-121-jewish",
            tradition: .jewish,
            title: "O guardião de Israel",
            reference: "Tehillim / Salmo 121",
            text: "Elevo os meus olhos para os montes: de onde virá o meu socorro? O meu socorro vem do Eterno, que fez céus e terra.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "proverbs-3-jewish",
            tradition: .jewish,
            title: "Caminhos endireitados",
            reference: "Mishlei / Provérbios 3:5-6",
            text: "Confia no Eterno de todo o teu coração. Reconhece-o em todos os teus caminhos, e ele endireitará tuas veredas.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "isaiah-40-jewish",
            tradition: .jewish,
            title: "Esperança que renova",
            reference: "Yeshayahu / Isaías 40:31",
            text: "Os que esperam no Eterno renovarão as forças. Subirão com asas como águias, correrão e não se cansarão.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "psalm-27-jewish",
            tradition: .jewish,
            title: "Luz e salvação",
            reference: "Tehillim / Salmo 27:1",
            text: "O Eterno é minha luz e minha salvação; a quem temerei? O Eterno é a força da minha vida.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .psalms,
            book: .psalms
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
        ),
        ScripturePassage(
            id: "matthew-7-spiritist",
            tradition: .spiritist,
            title: "Olhar com caridade",
            reference: "Mateus 7:12",
            text: "Tudo o que quereis que os homens vos façam, fazei-o também a eles. A regra simples começa na escolha de agora.",
            estimatedMinutes: 5,
            theme: .family,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "luke-6-spiritist",
            tradition: .spiritist,
            title: "Misericórdia nas escolhas",
            reference: "Lucas 6:36",
            text: "Sede misericordiosos, como também vosso Pai é misericordioso. A pausa ajuda a responder com mais bondade.",
            estimatedMinutes: 5,
            theme: .forgiveness,
            section: .gospels,
            book: .luke
        ),
        ScripturePassage(
            id: "john-8-spiritist",
            tradition: .spiritist,
            title: "Verdade que educa",
            reference: "João 8:32",
            text: "Conhecereis a verdade, e a verdade vos libertará. A liberdade começa quando a consciência volta a dirigir o impulso.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "matthew-11-spiritist",
            tradition: .spiritist,
            title: "Mansidão e alívio",
            reference: "Mateus 11:29",
            text: "Aprendei de mim, que sou manso e humilde de coração. A mansidão transforma a pressa em escolha lúcida.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "romans-12-spiritist",
            tradition: .spiritist,
            title: "Renovar a mente",
            reference: "Romanos 12:2",
            text: "Transformai-vos pela renovação da vossa mente. Cada pausa consciente educa a vontade e fortalece o bem.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .paulineLetters,
            book: .romans
        ),
        ScripturePassage(
            id: "corinthians-13-spiritist",
            tradition: .spiritist,
            title: "Caridade que permanece",
            reference: "1 Coríntios 13:4-7",
            text: "A caridade é paciente e benigna. Antes de reagir, escolha o gesto que mais se aproxima do amor.",
            estimatedMinutes: 5,
            theme: .forgiveness,
            section: .paulineLetters,
            book: .corinthians
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
        recentlyShownPassageIDs: [String] = [],
        minimumCount: Int = 5
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
            for passage in passages where !plan.contains(where: { $0.id == passage.id }) {
                plan.append(passage)
                if plan.count >= minimumCount { break }
            }
        }

        return plan.isEmpty ? Array(passages.prefix(minimumCount)) : plan
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
        let recentIDs = Set(completedIDs + recentlyShownPassageIDs.prefix(18))
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
        return scored.sorted(by: { $0.score > $1.score }).map(\.passage)
            + passages.filter { passage in
                !traditionMatches.contains(where: { $0.id == passage.id })
            }
    }
}

struct AISpiritualReadingRequest: Codable, Hashable {
    let tradition: FaithTradition
    let favoriteSections: [BibleSection]
    let favoriteBooks: [BibleBook]
    let favoriteThemes: [SpiritualTheme]
    let explanationDepth: ExplanationDepth
    let candidateReferences: [String]

    var cacheKey: String {
        let rawKey = [
            tradition.rawValue,
            favoriteSections.map(\.rawValue).sorted().joined(separator: ","),
            favoriteBooks.map(\.rawValue).sorted().joined(separator: ","),
            favoriteThemes.map(\.rawValue).sorted().joined(separator: ","),
            explanationDepth.rawValue,
            candidateReferences.joined(separator: "+")
        ].joined(separator: "|")
        return Data(rawKey.utf8).base64EncodedString()
    }

    var compactPrompt: String {
        let sections = favoriteSections.map(\.title).joined(separator: ", ")
        let books = favoriteBooks.map(\.title).joined(separator: ", ")
        let themes = favoriteThemes.map(\.title).joined(separator: ", ")
        let references = candidateReferences.joined(separator: "; ")
        return """
        Gere uma leitura espiritual para um usuário \(tradition.title). Use pelo menos 5 trechos. Seja acolhedor, simples e pastoral, em tom de homilia. Retorne itens com referência, texto religioso, explicação e conclusão prática. Não invente conteúdo bíblico.
        Seções: \(sections)
        Livros: \(books)
        Temas: \(themes)
        Profundidade: \(explanationDepth.title)
        Referências sugeridas: \(references)
        """
    }
}

protocol AISpiritualReadingGenerating {
    func generateReadingItems(
        for request: AISpiritualReadingRequest,
        passages: [ScripturePassage]
    ) -> [SpiritualReadingItem]
}

struct LocalSpiritualReadingGenerator: AISpiritualReadingGenerating {
    func generateReadingItems(
        for request: AISpiritualReadingRequest,
        passages: [ScripturePassage]
    ) -> [SpiritualReadingItem] {
        passages.prefix(max(5, passages.count)).map { passage in
            SpiritualReadingItem(
                id: "\(request.cacheKey).\(passage.id)",
                reference: passage.reference,
                text: passage.text,
                homily: homily(for: passage, request: request),
                practicalConclusion: practicalConclusion(for: passage, request: request)
            )
        }
    }

    private func homily(for passage: ScripturePassage, request: AISpiritualReadingRequest) -> String {
        let traditionOpening = switch request.tradition {
        case .catholic:
            "Este trecho pode ser acolhido como uma pequena homilia para o coração."
        case .protestant:
            "Este trecho pode ser acolhido como uma meditação devocional simples e fiel."
        case .jewish:
            "Este trecho pode ser acolhido como sabedoria do Tanakh para orientar a escolha presente."
        case .spiritist:
            "Este trecho pode ser acolhido como convite à reforma íntima e à caridade concreta."
        }

        let themeLine = switch passage.theme {
        case .faith:
            "Ele lembra que a fé amadurece quando a pessoa escolhe confiar antes de reagir."
        case .hope:
            "Ele reacende esperança sem pressa, como quem deixa a alma respirar antes do próximo passo."
        case .forgiveness:
            "Ele ensina que perdoar começa em pequenas respostas mais livres e menos impulsivas."
        case .discipline:
            "Ele mostra que disciplina espiritual não é peso, mas cuidado com aquilo que governa a atenção."
        case .wisdom:
            "Ele oferece sabedoria para perceber o que merece espaço e o que pode esperar."
        case .family:
            "Ele convida a levar mais mansidão e presença para os vínculos que importam."
        case .work:
            "Ele ajuda a recolocar os planos diante de Deus antes de voltar às tarefas."
        case .anxiety:
            "Ele fala ao coração inquieto e recorda que a paz também pode ser escolhida em passos pequenos."
        case .presence:
            "Ele chama a pessoa de volta ao presente, onde a graça pode ser reconhecida com simplicidade."
        case .purpose:
            "Ele ajuda a ordenar desejos e decisões ao redor de um propósito mais alto."
        }

        return "\(traditionOpening) \(themeLine)"
    }

    private func practicalConclusion(for passage: ScripturePassage, request: AISpiritualReadingRequest) -> String {
        switch request.explanationDepth {
        case .short:
            "Antes de voltar ao app, respire e escolha uma atitude concreta que proteja sua atenção."
        case .medium:
            "Leve este trecho como uma pequena decisão: use o próximo período com presença, sem deixar que o impulso escolha por você."
        case .deep:
            "Permaneça alguns instantes com a pergunta que este trecho abre: o que Deus, a consciência e a vida estão pedindo de você agora? Depois, volte ao app com mais liberdade interior."
        }
    }
}

struct AISpiritualReadingCache {
    private let defaults = UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    private let keyPrefix = "aiSpiritualReadingCache."

    func readingItems(for request: AISpiritualReadingRequest) -> [SpiritualReadingItem]? {
        guard let data = defaults.data(forKey: keyPrefix + request.cacheKey) else { return nil }
        return try? JSONDecoder().decode([SpiritualReadingItem].self, from: data)
    }

    func save(_ items: [SpiritualReadingItem], for request: AISpiritualReadingRequest) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: keyPrefix + request.cacheKey)
    }
}

struct AISpiritualReadingService {
    private let cache: AISpiritualReadingCache
    private let generator: any AISpiritualReadingGenerating

    init(
        cache: AISpiritualReadingCache = AISpiritualReadingCache(),
        generator: any AISpiritualReadingGenerating = LocalSpiritualReadingGenerator()
    ) {
        self.cache = cache
        self.generator = generator
    }

    func readingItems(for passages: [ScripturePassage], profile: UserFaithProfile) -> [SpiritualReadingItem] {
        let request = AISpiritualReadingRequest(
            tradition: profile.tradition,
            favoriteSections: profile.favoriteBibleSections,
            favoriteBooks: profile.favoriteBooks,
            favoriteThemes: profile.favoriteThemes,
            explanationDepth: profile.explanationDepth,
            candidateReferences: passages.map(\.reference)
        )

        if let cached = cache.readingItems(for: request), cached.count >= 5 {
            return cached
        }

        let items = generator.generateReadingItems(for: request, passages: passages)
        cache.save(items, for: request)
        return items
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
