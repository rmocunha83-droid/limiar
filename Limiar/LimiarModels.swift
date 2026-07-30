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

// Contrato compartilhado com api/_limiar-ai.js: o áudio estático de cada
// trecho é sempre solicitado como "{reference}.\n{text}". Não acrescente
// número da sessão, perfil ou data, pois isso invalidaria o cache pré-aquecido.
func canonicalPassageNarrationText(reference: String, text: String) -> String {
    let canonicalReference = reference.trimmingCharacters(in: .whitespacesAndNewlines)
    let canonicalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return "\(canonicalReference).\n\(canonicalText)"
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
    case mark
    case job
    case ecclesiastes
    case songOfSongs
    case galatians
    case ephesians
    case hebrews
    case james
    case peter
    case jeremiah
    case ezekiel
    case daniel
    case joshua
    case judges
    case ruth
    case esther
    case judith
    case baruch

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
        case .mark: "Marcos"
        case .job: "Jó"
        case .ecclesiastes: "Eclesiastes"
        case .songOfSongs: "Cantares"
        case .galatians: "Gálatas"
        case .ephesians: "Efésios"
        case .hebrews: "Hebreus"
        case .james: "Tiago"
        case .peter: "Pedro"
        case .jeremiah: "Jeremias"
        case .ezekiel: "Ezequiel"
        case .daniel: "Daniel"
        case .joshua: "Josué"
        case .judges: "Juízes"
        case .ruth: "Rute"
        case .esther: "Ester"
        case .judith: "Judite"
        case .baruch: "Baruque"
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

    static func standaloneOptions(for tradition: FaithTradition) -> [SpiritualTheme] {
        guard tradition == .spiritist else { return standaloneOptions }
        return [
            .gospelOfJesus,
            .innerReform,
            .charity,
            .forgiveness,
            .prayer,
            .family,
            .patience,
            .spiritualEvolution,
            .consolationHope,
            .moralApplication,
            .practiceGood
        ]
    }

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

/// Categoria de estilo de leitura mostrada no passo "Leituras" do onboarding
/// e em Configurações. Dirigida por dados: a mesma tela funciona para as 4
/// tradições trocando apenas o config. `books` alimenta a geração (filtro
/// forte) e fica restrito aos livros com conteúdo no catálogo.
struct ReadingStyleCategory: Identifiable, Hashable {
    let id: String
    let label: String
    let hint: String
    let sections: [BibleSection]
    let books: [BibleBook]
    var defaultSelected: Bool = false
}

struct TraditionReadingConfig {
    let question: String
    let subtitle: String
    let categories: [ReadingStyleCategory]
    let optionalBooks: [BibleBook]
    let minSelected: Int

    func category(id: String) -> ReadingStyleCategory? {
        categories.first { $0.id == id }
    }

    var defaultCategoryIDs: [String] {
        categories.filter(\.defaultSelected).map(\.id)
    }

    /// Título de exibição de um livro no passo opcional (nomes hebraicos na
    /// tradição judaica; título padrão nas demais).
    func bookDisplayTitle(_ book: BibleBook, tradition: FaithTradition) -> String {
        guard tradition == .jewish else { return book.title }
        switch book {
        case .genesis: return "Gênesis / Bereshit"
        case .exodus: return "Êxodo / Shemot"
        case .psalms: return "Salmos / Tehilim"
        case .proverbs: return "Provérbios / Mishlei"
        case .isaiah: return "Isaías / Yeshayahu"
        case .jeremiah: return "Jeremias / Yirmiyahu"
        case .ezekiel: return "Ezequiel / Yechezkel"
        case .joshua: return "Josué / Yehoshua"
        case .judges: return "Juízes / Shoftim"
        case .job: return "Jó / Iyov"
        case .ecclesiastes: return "Eclesiastes / Kohelet"
        default: return book.title
        }
    }
}

extension FaithTradition {
    var readingConfig: TraditionReadingConfig {
        switch self {
        case .catholic:
            TraditionReadingConfig(
                question: "O que você quer ler nas pausas?",
                subtitle: "Escolha pelo menos 3 estilos que falam com você. Você pode mudar depois.",
                categories: [
                    ReadingStyleCategory(id: "evangelhos", label: "Evangelhos", hint: "Mateus, Marcos, Lucas e João", sections: [.gospels], books: [.matthew, .mark, .luke, .john], defaultSelected: true),
                    ReadingStyleCategory(id: "salmos", label: "Salmos e orações", hint: "Salmos e cânticos", sections: [.psalms], books: [.psalms], defaultSelected: true),
                    ReadingStyleCategory(id: "sabedoria", label: "Sabedoria e provérbios", hint: "Provérbios, Jó, Sabedoria e Sirácida", sections: [.proverbs, .wisdomBooks], books: [.proverbs, .job, .ecclesiastes, .wisdom, .sirach], defaultSelected: true),
                    ReadingStyleCategory(id: "cartas", label: "Cartas dos apóstolos", hint: "Paulo, Tiago, Pedro e João", sections: [.paulineLetters], books: [.romans, .corinthians, .galatians, .ephesians, .james, .peter]),
                    ReadingStyleCategory(id: "profetas", label: "Profetas", hint: "Isaías, Jeremias, Ezequiel e Daniel", sections: [.prophets], books: [.isaiah, .jeremiah, .ezekiel, .daniel]),
                    ReadingStyleCategory(id: "historias", label: "Histórias e origens", hint: "Gênesis, Êxodo, Josué e Juízes", sections: [.torah, .historicalBooks], books: [.genesis, .exodus, .joshua, .judges]),
                    ReadingStyleCategory(id: "deuterocanon", label: "Livros deuterocanônicos", hint: "Tobias, Judite, Macabeus e Baruque", sections: [.deuterocanonical], books: [.tobias, .judith, .maccabees, .baruch])
                ],
                optionalBooks: [.genesis, .exodus, .joshua, .judges, .psalms, .proverbs, .job, .ecclesiastes, .wisdom, .sirach, .isaiah, .jeremiah, .ezekiel, .daniel, .matthew, .mark, .luke, .john, .romans, .corinthians, .galatians, .ephesians, .james, .peter, .tobias, .judith, .maccabees, .baruch],
                minSelected: 3
            )
        case .protestant:
            TraditionReadingConfig(
                question: "O que você quer ler nas pausas?",
                subtitle: "Escolha pelo menos 3 estilos que falam com você. Você pode mudar depois.",
                categories: [
                    ReadingStyleCategory(id: "evangelhos", label: "Evangelhos", hint: "Mateus, Marcos, Lucas e João", sections: [.gospels], books: [.matthew, .mark, .luke, .john], defaultSelected: true),
                    ReadingStyleCategory(id: "salmos", label: "Salmos e louvor", hint: "Salmos", sections: [.psalms], books: [.psalms], defaultSelected: true),
                    ReadingStyleCategory(id: "sabedoria", label: "Sabedoria e provérbios", hint: "Provérbios, Jó, Eclesiastes e Cantares", sections: [.proverbs, .wisdomBooks], books: [.proverbs, .job, .ecclesiastes, .songOfSongs], defaultSelected: true),
                    ReadingStyleCategory(id: "cartas", label: "Cartas de Paulo", hint: "Romanos, Coríntios, Gálatas e Efésios", sections: [.paulineLetters], books: [.romans, .corinthians, .galatians, .ephesians]),
                    ReadingStyleCategory(id: "cartas-apoc", label: "Cartas gerais e Apocalipse", hint: "Hebreus, Tiago, Pedro e Apocalipse", sections: [.paulineLetters], books: [.hebrews, .james, .peter, .revelation]),
                    ReadingStyleCategory(id: "profetas", label: "Profetas", hint: "Isaías, Jeremias, Ezequiel e Daniel", sections: [.prophets], books: [.isaiah, .jeremiah, .ezekiel, .daniel]),
                    ReadingStyleCategory(id: "historias", label: "Histórias e origens", hint: "Gênesis, Êxodo e livros históricos", sections: [.torah, .historicalBooks], books: [.genesis, .exodus, .joshua, .judges, .ruth, .esther])
                ],
                optionalBooks: [.genesis, .exodus, .joshua, .judges, .ruth, .esther, .psalms, .proverbs, .job, .ecclesiastes, .songOfSongs, .isaiah, .jeremiah, .ezekiel, .daniel, .matthew, .mark, .luke, .john, .romans, .corinthians, .galatians, .ephesians, .hebrews, .james, .peter, .revelation],
                minSelected: 3
            )
        case .jewish:
            TraditionReadingConfig(
                question: "O que você quer ler nas pausas?",
                subtitle: "Vamos criar leituras próximas da sua tradição. Escolha pelo menos 3 estilos — você pode mudar depois.",
                categories: [
                    ReadingStyleCategory(id: "tora", label: "Torá — Leis e origens", hint: "Bereshit, Shemot, Vayikra e Devarim", sections: [.torah], books: [.genesis, .exodus, .leviticus, .numbers, .deuteronomy], defaultSelected: true),
                    ReadingStyleCategory(id: "neviim", label: "Profetas — Nevi\u{2019}im", hint: "Yeshayahu, Yirmiyahu e Yechezkel", sections: [.prophets], books: [.isaiah, .jeremiah, .ezekiel, .joshua, .judges]),
                    ReadingStyleCategory(id: "ketuvim", label: "Escritos — Ketuvim", hint: "Mishlei, Iyov, Kohelet e Ester", sections: [.ketuvim], books: [.psalms, .proverbs, .job, .ecclesiastes, .ruth, .esther, .daniel]),
                    ReadingStyleCategory(id: "tehilim", label: "Salmos e orações — Tehilim", hint: "Tehilim / Salmos", sections: [.psalms], books: [.psalms], defaultSelected: true),
                    ReadingStyleCategory(id: "sabedoria", label: "Sabedoria — Mishlei", hint: "Mishlei, Kohelet e Iyov", sections: [.proverbs, .wisdomBooks], books: [.proverbs, .ecclesiastes, .job], defaultSelected: true),
                    ReadingStyleCategory(id: "etica", label: "Ética e vida prática", hint: "Trechos morais e de conduta", sections: [.ethicalWisdom], books: [.proverbs, .ecclesiastes, .leviticus, .deuteronomy])
                ],
                optionalBooks: [.genesis, .exodus, .leviticus, .numbers, .deuteronomy, .joshua, .judges, .isaiah, .jeremiah, .ezekiel, .psalms, .proverbs, .job, .ecclesiastes, .ruth, .esther, .daniel],
                minSelected: 3
            )
        case .spiritist:
            TraditionReadingConfig(
                question: "Quais textos inspiram sua leitura?",
                subtitle: "Escolha pelo menos 3 fontes que orientam suas reflexões. Você pode mudar depois.",
                categories: [
                    ReadingStyleCategory(id: "evangelho", label: "Evangelho de Jesus", hint: "Mateus, Marcos, Lucas e João", sections: [.gospels], books: [.matthew, .mark, .luke, .john], defaultSelected: true),
                    ReadingStyleCategory(id: "sermao", label: "Sermão da Montanha e parábolas", hint: "Mateus 5–7 e parábolas", sections: [.sermonOnMount, .parablesOfJesus], books: [.matthew, .luke], defaultSelected: true),
                    ReadingStyleCategory(id: "salmos", label: "Salmos e orações", hint: "Salmos e cânticos", sections: [.psalms], books: [.psalms], defaultSelected: true),
                    ReadingStyleCategory(id: "sabedoria", label: "Sabedoria e provérbios", hint: "Provérbios, Eclesiastes e Jó", sections: [.proverbs], books: [.proverbs, .ecclesiastes, .job]),
                    ReadingStyleCategory(id: "cartas", label: "Cartas dos apóstolos", hint: "Paulo, Tiago, Pedro e João", sections: [.paulineLetters], books: [.romans, .corinthians, .james, .peter])
                ],
                optionalBooks: [.matthew, .mark, .luke, .john, .psalms, .proverbs, .ecclesiastes, .job, .romans, .corinthians, .james, .peter],
                minSelected: 3
            )
        }
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

    var readingItemCount: Int {
        switch self {
        case .short: 1
        case .medium: 2
        case .deep: 3
        }
    }
}

struct UserFaithProfile: Codable, Equatable {
    var tradition: FaithTradition
    var favoriteBibleSections: [BibleSection]
    var favoriteBooks: [BibleBook]
    var favoriteThemes: [SpiritualTheme]
    var explanationDepth: ExplanationDepth
    /// Categorias de estilo selecionadas no passo "Leituras". Opcional para
    /// decodificar perfis antigos (nil = migrar inferindo pelos livros salvos).
    var selectedReadingCategoryIDs: [String]?
    /// Afinação opcional por livros específicos. Quando presente, vale como
    /// filtro forte no lugar da união das categorias. Não conta para o mínimo.
    var refinedBooks: [BibleBook]?

    static let starter = UserFaithProfile(
        tradition: .catholic,
        favoriteBibleSections: [.psalms, .gospels],
        favoriteBooks: [.psalms, .john],
        favoriteThemes: [.presence, .discipline],
        explanationDepth: .medium,
        selectedReadingCategoryIDs: ["evangelhos", "salmos", "sabedoria"]
    )

    var selectedReadingCategoryCount: Int {
        (selectedReadingCategoryIDs ?? []).count
    }

    var hasSelectedReadingPreferences: Bool {
        selectedReadingCategoryCount >= tradition.readingConfig.minSelected
    }

    func isCategorySelected(_ id: String) -> Bool {
        selectedReadingCategoryIDs?.contains(id) ?? false
    }

    func isRefinedBookSelected(_ book: BibleBook) -> Bool {
        refinedBooks?.contains(book) ?? false
    }

    /// Livros elegíveis para a afinação opcional: todos os livros da tradição
    /// com conteúdo no catálogo. As categorias são escolha em grupo; aqui a
    /// pessoa escolhe individualmente, se quiser.
    var refinementBookPool: [BibleBook] {
        tradition.readingConfig.optionalBooks
    }

    var selectedCategories: [ReadingStyleCategory] {
        let config = tradition.readingConfig
        let ids = selectedReadingCategoryIDs ?? []
        let selected = config.categories.filter { ids.contains($0.id) }
        // Perfil sem nenhuma categoria (estado transitório da UI): a geração
        // segue funcionando com os defaults da tradição.
        return selected.isEmpty ? config.categories.filter(\.defaultSelected) : selected
    }

    var selectedSectionOptionIds: [String] {
        favoriteBibleSections.map(\.rawValue).sorted()
    }

    var selectedBookOptionIds: [String] {
        favoriteBooks.map(\.rawValue).sorted()
    }

    var selectedPriorityBookOptionIds: [String] {
        (refinedBooks ?? []).map(\.rawValue).sorted()
    }

    var selectedThemeOptionIds: [String] {
        favoriteThemes.map(\.rawValue).sorted()
    }

    mutating func toggleReadingCategory(_ id: String) {
        var ids = selectedReadingCategoryIDs ?? []
        if ids.contains(id) {
            ids.removeAll { $0 == id }
        } else {
            ids.append(id)
        }
        selectedReadingCategoryIDs = ids
    }

    mutating func toggleRefinedBook(_ book: BibleBook) {
        var books = refinedBooks ?? []
        if books.contains(book) {
            books.removeAll { $0 == book }
        } else {
            books.append(book)
        }
        refinedBooks = books.isEmpty ? nil : books
    }

    /// Deriva favoriteBibleSections/favoriteBooks das categorias selecionadas
    /// (união dedupada) e valida tudo contra o config da tradição atual.
    /// Migra perfis antigos (sem selectedReadingCategoryIDs) inferindo as
    /// categorias pelas escolhas de livros/seções já salvas.
    mutating func normalizeReadingPreferencesForTradition() {
        let config = tradition.readingConfig
        let validIDs = Set(config.categories.map(\.id))

        if let stored = selectedReadingCategoryIDs {
            selectedReadingCategoryIDs = stored.filter { validIDs.contains($0) }
        } else {
            // Migração: inferir categorias a partir dos livros/seções antigos
            // e preservar a escolha estreita original como afinação.
            let inferred = config.categories.filter { category in
                category.books.contains(where: favoriteBooks.contains)
                    || category.sections.contains(where: favoriteBibleSections.contains)
            }.map(\.id)
            selectedReadingCategoryIDs = inferred.isEmpty ? config.defaultCategoryIDs : inferred
            let inferredUnion = Set(selectedCategories.flatMap(\.books))
            if !favoriteBooks.isEmpty, Set(favoriteBooks).isStrictSubset(of: inferredUnion) {
                refinedBooks = favoriteBooks
            }
        }

        let unionBooks = Self.orderedUnion(selectedCategories.flatMap(\.books))
        let unionSections = Self.orderedUnion(selectedCategories.flatMap(\.sections))
        // O afinamento aceita qualquer livro da tradição e viaja separado como
        // prioridade. A união das categorias continua sendo o pool normal,
        // preservando variedade mesmo quando a pessoa escolhe um livro pequeno.
        let pool = Set(config.optionalBooks)
        let refined = Self.orderedUnion((refinedBooks ?? []).filter { pool.contains($0) })
        refinedBooks = refined.isEmpty ? nil : refined

        favoriteBibleSections = unionSections
        favoriteBooks = unionBooks
    }

    mutating func normalizeStandaloneThemesForCurrentTradition() {
        let allowedThemes = Set(SpiritualTheme.standaloneOptions(for: tradition))
        favoriteThemes = favoriteThemes.filter { allowedThemes.contains($0) }
    }

    private static func orderedUnion<T: Hashable>(_ values: [T]) -> [T] {
        var seen = Set<T>()
        return values.filter { seen.insert($0).inserted }
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
    // ID do trecho no catálogo local, quando o backend informa. Permite
    // recuperar livro/seção/tema reais em vez de metadados sintéticos.
    var passageID: String? = nil

    var hasExplanationContent: Bool {
        !homily.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !practicalConclusion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
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
    let text: String?
    let savedAt: Date
}

enum LockState: Equatable {
    case locked
    case readingPause
    case availableToday
}

enum AIContentState: Equatable {
    case localReady
    case generating
    case remoteReady
    case localSession
    case fallback
    case essentialMode

    var title: String {
        switch self {
        case .localReady:
            "Preparando leitura"
        case .generating:
            "Criando suas reflexões"
        case .remoteReady:
            "Reflexão personalizada"
        case .localSession:
            "Leitura disponível offline"
        case .fallback:
            "Não foi possível preparar sua reflexão agora"
        case .essentialMode:
            "Modo Essencial"
        }
    }

    var subtitle: String {
        switch self {
        case .localReady:
            "A leitura será atualizada assim que você começar."
        case .generating:
            "Estamos preparando sua travessia bíblica com explicações para este momento."
        case .remoteReady:
            "Texto atualizado com novos trechos e uma reflexão nova."
        case .localSession:
            "Sua leitura está disponível. As explicações voltam quando a conexão for restabelecida."
        case .fallback:
            "Tente novamente em instantes. Confira sua conexão com a internet antes de tentar outra vez."
        case .essentialMode:
            "Você está lendo os trechos principais com explicações essenciais. Narração, maior variedade e experiência sem anúncios ficam no Limiar completo."
        }
    }
}

enum LimiarPrewarmResult: String {
    case generated
    case localFallback = "local_fallback"
    case alreadyAvailable = "already_available"
    case alreadyRunning = "already_running"
    case activeTraversal = "active_traversal"
    case notEligible = "not_eligible"
    case profileChanged = "profile_changed"
    case failed
    case cancelled

    var completedSuccessfully: Bool {
        self == .generated || self == .localFallback || self == .alreadyAvailable || self == .alreadyRunning
    }
}

@MainActor
@Observable
final class LimiarAppModel {
    let profileImageStore = ProfileImageStore()
    var hasCompletedOnboarding = false
    var hasSeenValueDemo = false
    var hasPremiumAccess = false
    var isEssentialMode = false
    var faithProfile = UserFaithProfile.starter
    var pauseCycleTurn = PauseCycleTurn.morning
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
    var unlockNote = ""
    var hasAuthorizedScreenTime = false
    var recentPassageIDs: [String] = []
    var recentAIReflections: [RecentAIReflectionDigest] = []
    var aiContentState = AIContentState.localReady
    var isRetryingLocalSession = false
    var readingTopResetID = UUID()

    private let recommender = PassageRecommendationService()
    private let policyStore = ScreenTimePolicyStore()
    private let dailySessionStore = DailyReadingSessionStore()
    private let screenTimeController = ScreenTimeController()
    private var lastForegroundRefreshAt = Date.distantPast
    private var aiGenerationTask: Task<Void, Never>?
    private var prewarmTask: Task<LimiarPrewarmResult, Never>?
    private var prewarmRequestID: UUID?
    private var prewarmDayKeyInFlight: String?
    // Dia a que pertence a sessão exibida: detecta a virada de dia no
    // foreground para trocar pela sessão pré-gerada do novo ciclo.
    private var currentSessionDayKey = DailyReadingSessionStore.todayKey()
    private var aiGenerationID = UUID()
    private var localSessionFailureReason: String?

    init() {
#if DEBUG
        ScreenTimePolicyStore.runCycleMathDebugAssertions()
#endif
        var savedProfile = policyStore.loadFaithProfile() ?? .starter
        savedProfile.normalizeReadingPreferencesForTradition()
        savedProfile.normalizeStandaloneThemesForCurrentTradition()
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let depthIndex = arguments.firstIndex(of: "-LimiarExplanationDepth"),
           arguments.indices.contains(depthIndex + 1) {
            switch arguments[depthIndex + 1].folding(options: .diacriticInsensitive, locale: .current).lowercased() {
            case "curta", "short":
                savedProfile.explanationDepth = .short
            case "media", "medium":
                savedProfile.explanationDepth = .medium
            case "profunda", "deep":
                savedProfile.explanationDepth = .deep
            default:
                break
            }
        }
#endif
        policyStore.saveFaithProfile(savedProfile)
        faithProfile = savedProfile
        pauseCycleTurn = policyStore.loadSelectedCycleTurn()
        hasCompletedOnboarding = policyStore.loadOnboardingState()
        hasSeenValueDemo = policyStore.loadValueDemoSeen()
        blockingEnabled = policyStore.loadBlockingEnabled()
        selection = policyStore.loadSelection()
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
        // O acesso ainda não foi restaurado pelo SubscriptionManager neste
        // ponto. O ContentView reaplica a política assim que o estado local de
        // trial/assinatura estiver disponível, evitando uma janela sem shield.
    }

    var lockState: LockState {
        guard blockingEnabled else { return .availableToday }
        if policyStore.hasCompletedPauseInCurrentCycle() {
            return .availableToday
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

    var currentReadingNarrationSegments: [String] {
        guard hasPremiumAccess else { return [] }

        let passageSegments = currentSpiritualReadingItems.map {
            canonicalPassageNarrationText(reference: $0.reference, text: $0.text)
        }

        let explanationText = [
            currentReflection.summary,
            currentReflection.spiritualMeaning
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

        let practiceText = [
            currentReflection.practicalApplication,
            currentReflection.conclusion
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

        let reflectionBlock = [
            explanationText.isEmpty ? "" : "Explicação espiritual.\n\(explanationText)",
            practiceText.isEmpty ? "" : "Aplicação prática.\n\(practiceText)"
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: "\n\n")

        return passageSegments + [reflectionBlock]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var currentReadingNarrationText: String {
        currentReadingNarrationSegments.joined(separator: "\n\n")
    }

    var hasVisibleReadingExplanations: Bool {
        (hasPremiumAccess || isEssentialMode) && currentSpiritualReadingItems.contains { $0.hasExplanationContent }
    }

    var hasVisibleReflection: Bool {
        guard hasPremiumAccess else { return false }
        return [
            currentReflection.summary,
            currentReflection.spiritualMeaning,
            currentReflection.practicalApplication,
            currentReflection.conclusion,
            currentReflection.meditationQuestion
        ].contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var canNarrateCurrentReading: Bool {
        hasPremiumAccess && !currentReadingNarrationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var unlockDurationDescription: String {
        "\(pauseCycleTurn.title), a partir das \(pauseCycleTurn.hourLabel)"
    }

    var hasBlockedAppsSelection: Bool {
        !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }

    var hasPauseAccess: Bool {
        hasPremiumAccess || isEssentialMode
    }

    var showsAds: Bool {
        isEssentialMode
    }

    var isPreparingReadingContent: Bool {
        aiContentState == .generating || (hasPauseAccess && currentSpiritualReadingItems.isEmpty && aiContentState != .fallback)
    }

    var estimatedFocusTimeText: String {
        "\(history.count)"
    }

    func completeOnboarding() {
        let wasCompleted = hasCompletedOnboarding
        hasCompletedOnboarding = true
        policyStore.saveOnboardingState(true)
        saveProfile()
        beginNewReading(avoidingCurrent: true)
        if hasPauseAccess {
            applyBlocking()
        }

        if !wasCompleted {
            MetaAppEvents.trackCompletedRegistration()
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
        policyStore.savePauseAccessEnabled(hasPauseAccess)

        if hasPauseAccess {
            if !hadPauseAccess || currentSpiritualReadingItems.isEmpty || hadFullAccess != isActive || hadEssentialMode != isEssentialMode {
                beginNewReading(avoidingCurrent: true)
            }
            applyBlocking()
        } else {
            aiContentState = .localReady
            aiGenerationTask?.cancel()
            screenTimeController.clearShield()
        }
    }

    func saveProfile() {
        faithProfile.normalizeReadingPreferencesForTradition()
        faithProfile.normalizeStandaloneThemesForCurrentTradition()
        policyStore.saveFaithProfile(faithProfile)
        policyStore.saveBlockingEnabled(blockingEnabled)
        policyStore.saveSelection(selection)
        policyStore.savePauseAccessEnabled(hasPauseAccess)
        var values = LimiarAIDiagnostics.profileSnapshot(faithProfile)
        values["cycleStartHour"] = "\(pauseCycleTurn.rawValue)"
        values["blockingEnabled"] = "\(blockingEnabled)"
        values["hasBlockedAppsSelection"] = "\(hasBlockedAppsSelection)"
        LimiarAIDiagnostics.log("preferences_saved", values: values)
    }

    func selectTradition(_ tradition: FaithTradition) {
        let didChangeTradition = faithProfile.tradition != tradition
        faithProfile.tradition = tradition
        if didChangeTradition {
            // Nova tradição, novo ponto de partida: defaults dela, sem afinação.
            faithProfile.selectedReadingCategoryIDs = tradition.readingConfig.defaultCategoryIDs
            faithProfile.refinedBooks = nil
        }
        faithProfile.normalizeReadingPreferencesForTradition()
        faithProfile.normalizeStandaloneThemesForCurrentTradition()
        saveProfile()
        if didChangeTradition {
            beginNewReading(avoidingCurrent: true)
        }
    }

    func toggleReadingCategory(_ id: String) {
        faithProfile.toggleReadingCategory(id)
        saveProfile()
    }

    func toggleRefinedBook(_ book: BibleBook) {
        faithProfile.toggleRefinedBook(book)
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

    func selectPauseCycleTurn(_ turn: PauseCycleTurn) {
        guard pauseCycleTurn != turn else { return }
        pauseCycleTurn = turn
        policyStore.saveSelectedCycleTurn(turn)
        // O monitor acompanha o novo horário, mas a conclusão e o shield do
        // ciclo corrente permanecem intactos até a próxima janela.
        screenTimeController.scheduleDailyMonitoring()
        LimiarAIDiagnostics.log(
            "pause_cycle_turn_changed",
            values: ["hour": "\(turn.rawValue)", "effective": "next_cycle"]
        )
    }

    func beginNewReading(avoidingCurrent: Bool = false) {
        readingProgress = 0
        readingStartedAt = Date()
        let targetItemCount = faithProfile.explanationDepth.readingItemCount
        let candidates = recommender.readingPlan(
            for: faithProfile,
            history: history,
            avoiding: avoidingCurrent ? currentPassage.id : nil,
            recentlyShownPassageIDs: recentPassageIDs,
            minimumCount: hasPauseAccess ? 36 : targetItemCount
        )
        setReadingPlan(
            Array(candidates.prefix(targetItemCount)),
            profile: faithProfile,
            remoteCandidatePool: candidates
        )
    }

    func retryReadingGeneration() {
        if aiContentState == .localSession {
            attemptLocalSessionUpgrade(trigger: "manual")
            return
        }
        dailySessionStore.clear()
        beginNewReading(avoidingCurrent: true)
    }

    /// Pré-gera e persiste uma sessão em background, sem tocar no que está em
    /// tela. Usada (1) no passo de ativação do onboarding, enquanto o usuário
    /// autoriza o Tempo de Uso, e (2) após concluir a travessia, para que a
    /// o próximo ciclo abra instantaneamente mesmo em cold start.
    @discardableResult
    func prewarmSessionIfNeeded(
        dayKey: String = DailyReadingSessionStore.todayKey()
    ) -> Task<LimiarPrewarmResult, Never>? {
        let profile = faithProfile
        let profileKey = sessionProfileKey(for: profile)
        guard dailySessionStore.load(
            profileKey: profileKey,
            dayKey: dayKey,
            expectedItemCount: profile.explanationDepth.readingItemCount
        ) == nil else { return nil }
        // Há uma única geração especulativa por modelo. Além de economizar rede,
        // isso impede que foreground, conclusão e BGAppRefresh consumam trechos
        // diferentes para o mesmo ciclo quando chegam quase juntos.
        guard prewarmTask == nil else { return nil }

        let candidates = recommender.readingPlan(
            for: profile,
            history: history,
            recentlyShownPassageIDs: recentPassageIDs,
            minimumCount: 36
        )
        let recents = recentPassageIDs
        let reflections = recentAIReflections
        let requestID = UUID()
        prewarmRequestID = requestID
        prewarmDayKeyInFlight = dayKey

        LimiarAIDiagnostics.log(
            "prewarm_started",
            values: ["dayKey": dayKey, "candidates": "\(candidates.count)"]
                .merging(LimiarAIDiagnostics.profileSnapshot(profile)) { current, _ in current }
        )

        let task = Task<LimiarPrewarmResult, Never> { [weak self, candidates, profile, profileKey, dayKey, recents, reflections] in
            let service = RemoteAIReadingSessionService()
            let outcome = await service.readingSession(
                for: Array(candidates.prefix(36)),
                profile: profile,
                recentPassageIDs: recents,
                recentReflections: reflections
            )

            guard let self else { return .cancelled }
            guard !Task.isCancelled else {
                clearPrewarmRequest(requestID)
                return .cancelled
            }

            let session: RemoteReadingSessionResult
            let source: DailyReadingSessionSource
            let failureReason: String?
            switch outcome {
            case .success(let remoteSession):
                session = remoteSession
                source = .remote
                failureReason = nil
            case .failure(let reason):
                let localItems = LocalReadingSessionFactory.items(
                    from: candidates,
                    itemCount: profile.explanationDepth.readingItemCount
                )
                guard !localItems.isEmpty else {
                    LimiarAIDiagnostics.log("prewarm_failed", values: ["dayKey": dayKey, "reason": reason])
                    clearPrewarmRequest(requestID)
                    return .failed
                }
                session = RemoteReadingSessionResult(items: localItems, reflection: emptyReflection())
                source = .local
                failureReason = reason
            }
            // Se as preferências mudaram durante a geração, descarta:
            // o fluxo normal gera de novo com o perfil atual.
            guard sessionProfileKey(for: faithProfile) == profileKey else {
                LimiarAIDiagnostics.log("prewarm_discarded", values: ["reason": "profile_changed"])
                clearPrewarmRequest(requestID)
                return .profileChanged
            }
            dailySessionStore.save(
                DailyReadingSessionSnapshot(
                    dayKey: dayKey,
                    profileKey: profileKey,
                    items: session.items,
                    reflection: session.reflection,
                    source: source,
                    failureReason: failureReason
                )
            )
            LimiarAIDiagnostics.log("prewarm_saved", values: [
                "dayKey": dayKey,
                "items": "\(session.items.count)",
                "source": source.rawValue
            ])
            clearPrewarmRequest(requestID)
            return source == .remote ? .generated : .localFallback
        }
        prewarmTask = task
        return task
    }

    /// Executa a tentativa de foreground uma única vez por ativação (o debounce
    /// da ativação vive no ContentView) e nunca interfere numa travessia aberta.
    func prewarmNextCycleFromForeground(now: Date = Date()) {
        guard hasCompletedOnboarding else {
            LimiarAIDiagnostics.log("prewarm_foreground_skipped", values: ["reason": "onboarding"], persistForDiagnostics: true)
            return
        }
        guard !isReadingSessionActive else {
            LimiarAIDiagnostics.log("prewarm_foreground_skipped", values: ["reason": "active_traversal"], persistForDiagnostics: true)
            return
        }

        let nextCycleKey = DailyReadingSessionStore.todayKey(
            ScreenTimePolicyStore.nextCycleStart(after: now)
        )
        guard !hasCachedSession(dayKey: nextCycleKey) else {
            LimiarAIDiagnostics.log("prewarm_foreground_skipped", values: ["reason": "already_available"], persistForDiagnostics: true)
            return
        }
        guard prewarmTask == nil else {
            LimiarAIDiagnostics.log("prewarm_foreground_skipped", values: ["reason": "in_flight"], persistForDiagnostics: true)
            return
        }

        LimiarAIDiagnostics.log("prewarm_foreground_started", values: ["target": "next_cycle"], persistForDiagnostics: true)
        if prewarmSessionIfNeeded(dayKey: nextCycleKey) == nil {
            LimiarAIDiagnostics.log("prewarm_foreground_skipped", values: ["reason": "guarded"], persistForDiagnostics: true)
        }
    }

    /// BGAppRefresh prioriza a sessão do ciclo corrente quando o sistema só
    /// entrega a tarefa depois da virada; caso ela exista, prepara a próxima.
    func runBackgroundPrewarm(now: Date = Date()) async -> LimiarPrewarmResult {
        guard hasCompletedOnboarding else { return .notEligible }
        guard !isReadingSessionActive else { return .activeTraversal }

        let currentKey = DailyReadingSessionStore.todayKey(now)
        if !hasCachedSession(dayKey: currentKey) {
            return await prewarmSessionAndWaitIfNeeded(dayKey: currentKey)
        }

        let nextKey = DailyReadingSessionStore.todayKey(
            ScreenTimePolicyStore.nextCycleStart(after: now)
        )
        if !hasCachedSession(dayKey: nextKey) {
            return await prewarmSessionAndWaitIfNeeded(dayKey: nextKey)
        }
        return .alreadyAvailable
    }

    func cancelPrewarmSession() {
        prewarmTask?.cancel()
    }

    private func prewarmSessionAndWaitIfNeeded(dayKey: String) async -> LimiarPrewarmResult {
        if hasCachedSession(dayKey: dayKey) { return .alreadyAvailable }

        if let runningTask = prewarmTask {
            let runningDayKey = prewarmDayKeyInFlight
            let result = await runningTask.value
            guard !Task.isCancelled else { return .cancelled }
            if runningDayKey == dayKey || hasCachedSession(dayKey: dayKey) {
                return result
            }
        }

        guard let task = prewarmSessionIfNeeded(dayKey: dayKey) else {
            return hasCachedSession(dayKey: dayKey) ? .alreadyAvailable : .alreadyRunning
        }
        return await task.value
    }

    private func hasCachedSession(dayKey: String) -> Bool {
        dailySessionStore.load(
            profileKey: sessionProfileKey(for: faithProfile),
            dayKey: dayKey,
            expectedItemCount: faithProfile.explanationDepth.readingItemCount
        ) != nil
    }

    private func clearPrewarmRequest(_ requestID: UUID) {
        guard prewarmRequestID == requestID else { return }
        prewarmRequestID = nil
        prewarmDayKeyInFlight = nil
        prewarmTask = nil
    }

    func prepareFreshPassageForForeground() {
        reapplyBlockIfNeeded()
        guard hasCompletedOnboarding else { return }
        readingTopResetID = UUID()
        guard aiContentState != .generating else { return }
        // Sessão utilizável em tela: não regenera a cada retorno ao foreground.
        // Isso mantém a leitura do dia estável, evita custo repetido de IA e
        // impede que o pool de trechos seja consumido sem o usuário ler.
        // Exceção: virada de dia — troca pela sessão pré-gerada do novo ciclo.
        if currentSpiritualReadingItems.count >= faithProfile.explanationDepth.readingItemCount,
           aiContentState != .fallback,
           currentSessionDayKey == DailyReadingSessionStore.todayKey() {
            if aiContentState == .localSession {
                attemptLocalSessionUpgrade(trigger: "foreground")
            }
            return
        }
        guard Date().timeIntervalSince(lastForegroundRefreshAt) > 8 else { return }
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

    func isFavorite(_ item: SpiritualReadingItem) -> Bool {
        favoritePassages.contains { $0.passageID == item.id }
    }

    func favoritePassageText(for item: FavoritePassageItem) -> String {
        if let storedText = item.text?.trimmingCharacters(in: .whitespacesAndNewlines),
           !storedText.isEmpty {
            return storedText
        }

        let catalogText = item.passageID
            .split(separator: "+")
            .compactMap { recommender.passage(withID: String($0))?.text }
            .joined(separator: "\n\n")
        if !catalogText.isEmpty {
            return catalogText
        }

        return recommender.passage(
            matchingReference: item.reference,
            tradition: faithProfile.tradition
        )?.text ?? ""
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
                    text: item.text,
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
            unlockNote = "Inicie o acesso inicial para ativar a pausa antes dos apps selecionados."
            screenTimeController.clearShield()
            return
        }

        isReadingSessionActive = false
        let completedAt = Date()
        history.insert(
            ReadingHistoryItem(
                id: UUID(),
                passageID: currentReadingSessionID,
                passageTitle: currentReadingTitle,
                reference: currentReadingReference,
                completedAt: completedAt
            ),
            at: 0
        )
        history = Array(history.prefix(365))
        policyStore.saveHistory(history)
        // Leitura concluída: agora sim os trechos entram no histórico de
        // recentes (anti-repetição). A sessão de hoje permanece salva — ela é
        // o conteúdo concluído do dia; regenerar aqui só queimaria trechos.
        rememberShownPassages(currentReadingPlan)
        policyStore.saveMorningPauseCompletedAt(completedAt)
        screenTimeController.clearShield()
        if blockingEnabled && hasBlockedAppsSelection {
            screenTimeController.scheduleShieldReapplicationForNextCycle(now: completedAt)
        }
        unlockNote = "Travessia concluída. A pausa volta no próximo ciclo, às \(pauseCycleTurn.hourLabel)."
        // Pré-gera a sessão do próximo ciclo em background para o app abrir
        // com a travessia pronta, mesmo em cold start.
        let nextCycleDayKey = DailyReadingSessionStore.todayKey(
            ScreenTimePolicyStore.nextCycleStart(after: completedAt)
        )
        prewarmSessionIfNeeded(dayKey: nextCycleDayKey)
        LimiarPrewarmCoordinator.shared.schedule(now: completedAt)
        MetaAppEvents.trackReadingCompleted()
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

        policyStore.savePauseAccessEnabled(true)

        guard hasBlockedAppsSelection else {
            screenTimeController.clearShield()
            return
        }

        MetaAppEvents.trackPauseConfigured()

        if policyStore.hasCompletedPauseInCurrentCycle() {
            screenTimeController.clearShield()
            screenTimeController.scheduleShieldReapplicationForNextCycle()
            return
        }

        screenTimeController.applyShield(selection: selection)
    }

    func reapplyBlockIfNeeded() {
        guard hasPauseAccess else {
            screenTimeController.clearShield()
            return
        }

        guard blockingEnabled else {
            screenTimeController.clearShield()
            return
        }

        policyStore.savePauseAccessEnabled(true)

        guard hasBlockedAppsSelection else {
            screenTimeController.clearShield()
            return
        }

        if policyStore.hasCompletedPauseInCurrentCycle() {
            screenTimeController.clearShield()
            screenTimeController.scheduleShieldReapplicationForNextCycle()
        } else {
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

    private func setReadingPlan(
        _ plan: [ScripturePassage],
        profile: UserFaithProfile,
        remoteCandidatePool: [ScripturePassage]? = nil
    ) {
        let resolvedPlan = plan.isEmpty ? [currentPassage] : plan
        let candidatePool = remoteCandidatePool?.isEmpty == false ? remoteCandidatePool! : resolvedPlan
        aiGenerationTask?.cancel()
        isRetryingLocalSession = false
        let generationID = UUID()
        aiGenerationID = generationID
        currentReadingPlan = resolvedPlan
        currentPassage = resolvedPlan[0]

        var planValues = LimiarAIDiagnostics.profileSnapshot(profile)
        planValues["references"] = resolvedPlan.map(\.reference).joined(separator: " + ")
        planValues["passages"] = resolvedPlan.map(\.id).joined(separator: ",")
        planValues["recentReflections"] = "\(recentAIReflections.count)"
        LimiarAIDiagnostics.log("reading_plan_prepared", values: planValues)

        guard hasPauseAccess else {
            currentSpiritualReadingItems = []
            currentReflection = emptyReflection()
            aiContentState = .localReady
            var values = LimiarAIDiagnostics.profileSnapshot(profile)
            values["source"] = "none"
            values["reason"] = "no_pause_access"
            LimiarAIDiagnostics.log("remote_ai_skipped", values: values)
            return
        }

#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-LimiarForceLocalSession") {
            installLocalSession(
                from: candidatePool,
                profile: profile,
                reason: "debug_forced_local_session"
            )
            return
        }
#endif

        // Reaproveita a sessão do dia quando ela existe para este perfil:
        // nada de nova geração (nem novo consumo de trechos) a cada abertura.
        if let saved = dailySessionStore.load(
            profileKey: sessionProfileKey(for: profile),
            expectedItemCount: profile.explanationDepth.readingItemCount
        ) {
            applyGeneratedSession(items: saved.items, reflection: saved.reflection, profile: profile)
            localSessionFailureReason = saved.failureReason
            aiContentState = saved.source == .local
                ? .localSession
                : (isEssentialMode ? .essentialMode : .remoteReady)
            var cachedValues = LimiarAIDiagnostics.profileSnapshot(profile)
            cachedValues["source"] = "daily-session"
            cachedValues["sessionSource"] = saved.source.rawValue
            cachedValues["items"] = "\(saved.items.count)"
            LimiarAIDiagnostics.log("ai_reading_session_loaded", values: cachedValues)
            if saved.source == .local {
                logLocalSessionShown(reason: saved.failureReason ?? "unknown", items: saved.items.count)
            }
            return
        }

        currentSpiritualReadingItems = []
        currentReflection = emptyReflection()
        let remoteRequestKey = remoteAIRequestKey(for: candidatePool, profile: profile)
        aiContentState = .generating
        var values = LimiarAIDiagnostics.profileSnapshot(profile)
        values["source"] = "remote"
        values["requestKey"] = remoteRequestKey
        values["mode"] = isEssentialMode ? "essential" : "full"
        LimiarAIDiagnostics.log("remote_ai_started", values: values)
        refreshRemoteAIContent(
            for: Array(candidatePool.prefix(36)),
            fallbackPlan: resolvedPlan,
            profile: profile,
            generationID: generationID
        )
    }

    private func sessionProfileKey(for profile: UserFaithProfile) -> String {
        [
            profile.tradition.rawValue,
            profile.explanationDepth.rawValue,
            "item-count:\(profile.explanationDepth.readingItemCount)",
            profile.favoriteBibleSections.map(\.rawValue).sorted().joined(separator: ","),
            profile.favoriteBooks.map(\.rawValue).sorted().joined(separator: ","),
            // Afinamento entra na chave: mudar só os livros prioritários deve
            // gerar sessão nova no mesmo dia, não recarregar a antiga.
            (profile.refinedBooks ?? []).map(\.rawValue).sorted().joined(separator: ","),
            profile.favoriteThemes.map(\.rawValue).sorted().joined(separator: ",")
        ].joined(separator: "|")
    }

    private func applyGeneratedSession(items: [SpiritualReadingItem], reflection: AIReflection, profile: UserFaithProfile) {
        currentSpiritualReadingItems = items
        let selectedPassages = scripturePassages(from: items, profile: profile)
        currentReadingPlan = selectedPassages
        if let first = selectedPassages.first {
            currentPassage = first
        }
        currentReflection = reflection
        currentSessionDayKey = DailyReadingSessionStore.todayKey()
    }

    private func emptyReflection() -> AIReflection {
        AIReflection(
            summary: "",
            spiritualMeaning: "",
            practicalApplication: "",
            conclusion: "",
            meditationQuestion: ""
        )
    }

    private func remoteAIRequestKey(for passages: [ScripturePassage], profile: UserFaithProfile) -> String {
        [
            passages.map(\.id).joined(separator: "+"),
            profile.tradition.rawValue,
            profile.explanationDepth.rawValue,
            "item-count:\(profile.explanationDepth.readingItemCount)",
            profile.favoriteBibleSections.map(\.rawValue).sorted().joined(separator: ","),
            profile.favoriteBooks.map(\.rawValue).sorted().joined(separator: ","),
            (profile.refinedBooks ?? []).map(\.rawValue).sorted().joined(separator: ","),
            profile.favoriteThemes.map(\.rawValue).sorted().joined(separator: ",")
        ].joined(separator: "|")
    }

    private func rememberShownPassages(_ passages: [ScripturePassage]) {
        let ids = passages.flatMap { passage in
            [passage.id, passage.reference]
        }
        recentPassageIDs.removeAll { ids.contains($0) }
        recentPassageIDs.insert(contentsOf: ids, at: 0)
        recentPassageIDs = Array(recentPassageIDs.prefix(60))
        policyStore.saveRecentPassageIDs(recentPassageIDs)
    }

    private func refreshRemoteAIContent(
        for passages: [ScripturePassage],
        fallbackPlan: [ScripturePassage],
        profile: UserFaithProfile,
        generationID: UUID
    ) {
        let recentPassageIDs = recentPassageIDs
        let recentReflections = recentAIReflections
        aiGenerationTask = Task { [passages, fallbackPlan, profile, recentPassageIDs, recentReflections] in
            let readingSessionService = RemoteAIReadingSessionService()

            let outcome = await readingSessionService.readingSession(
                for: passages,
                profile: profile,
                recentPassageIDs: recentPassageIDs,
                recentReflections: recentReflections
            )

            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard aiGenerationID == generationID else { return }
                switch outcome {
                case .success(let session):
                    applyGeneratedSession(items: session.items, reflection: session.reflection, profile: profile)
                    // Persiste a sessão do dia. Os trechos só entram no
                    // histórico de recentes quando a leitura for concluída
                    // (finishReading) — gerar não é ler.
                    dailySessionStore.save(
                        DailyReadingSessionSnapshot(
                            dayKey: DailyReadingSessionStore.todayKey(),
                            profileKey: sessionProfileKey(for: profile),
                            items: session.items,
                            reflection: session.reflection,
                            source: .remote
                        )
                    )
                    rememberReflection(reference: currentReadingReference, reflection: session.reflection)
                    localSessionFailureReason = nil
                    aiContentState = isEssentialMode ? .essentialMode : .remoteReady
                case .failure(let reason):
                    installLocalSession(
                        from: fallbackPlan,
                        profile: profile,
                        reason: reason
                    )
                }
            }
        }
    }

    private func attemptLocalSessionUpgrade(trigger: String) {
        let hasCompletedCurrentCycle = policyStore.hasCompletedPauseInCurrentCycle()
        guard LocalSessionUpgradePolicy.shouldAttempt(
            source: .local,
            isReadingSessionActive: isReadingSessionActive,
            hasCompletedCurrentCycle: hasCompletedCurrentCycle
        ),
        aiContentState == .localSession,
        currentSessionDayKey == DailyReadingSessionStore.todayKey(),
        !isRetryingLocalSession else {
            return
        }

        let profile = faithProfile
        let profileKey = sessionProfileKey(for: profile)
        let candidates = recommender.readingPlan(
            for: profile,
            history: history,
            recentlyShownPassageIDs: recentPassageIDs,
            minimumCount: 36
        )
        let recents = recentPassageIDs
        let reflections = recentAIReflections
        let generationID = UUID()
        aiGenerationID = generationID
        isRetryingLocalSession = true

        aiGenerationTask = Task { [candidates, profile, profileKey, recents, reflections] in
            let outcome = await RemoteAIReadingSessionService().readingSession(
                for: Array(candidates.prefix(36)),
                profile: profile,
                recentPassageIDs: recents,
                recentReflections: reflections
            )

            guard !Task.isCancelled else {
                await MainActor.run {
                    if aiGenerationID == generationID {
                        isRetryingLocalSession = false
                    }
                }
                return
            }

            await MainActor.run {
                guard aiGenerationID == generationID else { return }
                isRetryingLocalSession = false
                guard aiContentState == .localSession,
                      sessionProfileKey(for: faithProfile) == profileKey,
                      currentSessionDayKey == DailyReadingSessionStore.todayKey() else {
                    return
                }

                switch outcome {
                case .success(let session):
                    guard LocalSessionUpgradePolicy.shouldAttempt(
                        source: .local,
                        isReadingSessionActive: isReadingSessionActive,
                        hasCompletedCurrentCycle: policyStore.hasCompletedPauseInCurrentCycle()
                    ) else {
                        return
                    }
                    applyGeneratedSession(items: session.items, reflection: session.reflection, profile: profile)
                    dailySessionStore.save(
                        DailyReadingSessionSnapshot(
                            dayKey: DailyReadingSessionStore.todayKey(),
                            profileKey: profileKey,
                            items: session.items,
                            reflection: session.reflection,
                            source: .remote
                        )
                    )
                    rememberReflection(reference: currentReadingReference, reflection: session.reflection)
                    localSessionFailureReason = nil
                    aiContentState = isEssentialMode ? .essentialMode : .remoteReady
                    LimiarAIDiagnostics.log(
                        "ai_local_session_upgraded",
                        values: ["trigger": trigger, "items": "\(session.items.count)"],
                        persistForDiagnostics: true
                    )
                case .failure(let reason):
                    localSessionFailureReason = reason
                    dailySessionStore.save(
                        DailyReadingSessionSnapshot(
                            dayKey: DailyReadingSessionStore.todayKey(),
                            profileKey: profileKey,
                            items: currentSpiritualReadingItems,
                            reflection: currentReflection,
                            source: .local,
                            failureReason: reason
                        )
                    )
                }
            }
        }
    }

    private func installLocalSession(
        from passages: [ScripturePassage],
        profile: UserFaithProfile,
        reason: String
    ) {
        let items = LocalReadingSessionFactory.items(
            from: passages,
            itemCount: profile.explanationDepth.readingItemCount
        )
        guard !items.isEmpty else {
            currentSpiritualReadingItems = []
            currentReflection = emptyReflection()
            aiContentState = .fallback
            return
        }

        let reflection = emptyReflection()
        applyGeneratedSession(items: items, reflection: reflection, profile: profile)
        localSessionFailureReason = reason
        dailySessionStore.save(
            DailyReadingSessionSnapshot(
                dayKey: DailyReadingSessionStore.todayKey(),
                profileKey: sessionProfileKey(for: profile),
                items: items,
                reflection: reflection,
                source: .local,
                failureReason: reason
            )
        )
        aiContentState = .localSession
        logLocalSessionShown(reason: reason, items: items.count)
    }

    private func logLocalSessionShown(reason: String, items: Int) {
        LimiarAIDiagnostics.log(
            "ai_local_session_shown",
            values: ["reason": reason, "items": "\(items)"],
            persistForDiagnostics: true
        )
    }

    nonisolated private func scripturePassages(from items: [SpiritualReadingItem], profile: UserFaithProfile) -> [ScripturePassage] {
        let fallbackTheme = profile.favoriteThemes.first ?? .faith
        let fallbackSection = profile.favoriteBibleSections.first ?? .gospels
        let fallbackBook = profile.favoriteBooks.first ?? .psalms

        return items.enumerated().map { index, item in
            // Preferência: resolver o trecho real do catálogo (livro/seção/tema
            // corretos) pelo ID informado pelo backend ou pela referência.
            if let passageID = item.passageID,
               let match = recommender.passage(withID: passageID) {
                return match
            }
            if let match = recommender.passage(matchingReference: item.reference, tradition: profile.tradition) {
                return match
            }
            let stableReferenceID = item.reference
                .lowercased()
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR"))
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: "–", with: "-")
                .replacingOccurrences(of: "—", with: "-")
            return ScripturePassage(
                id: "remote-\(stableReferenceID)-\(index)",
                tradition: profile.tradition,
                title: item.reference,
                reference: item.reference,
                text: item.text,
                estimatedMinutes: 5,
                theme: fallbackTheme,
                section: fallbackSection,
                book: fallbackBook
            )
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
