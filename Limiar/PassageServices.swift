import Foundation

enum LimiarReadingConstants {
    static let targetItemCount = 3
}

enum LimiarAIDiagnostics {
    static func log(_ event: String, values: [String: String]) {
        var payload = values
        payload["event"] = event
        debugPrint("limiar_ai_diagnostic", payload)
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
            id: "john-14-catholic",
            tradition: .catholic,
            title: "Paz para o coração",
            reference: "João 14, 27",
            text: "Deixo-vos a paz, dou-vos a minha paz. Não se perturbe o vosso coração, nem se atemorize.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "matthew-6-catholic",
            tradition: .catholic,
            title: "Buscar primeiro",
            reference: "Mateus 6, 33",
            text: "Buscai primeiro o Reino de Deus e a sua justiça, e todas essas coisas vos serão dadas por acréscimo.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "psalm-46-catholic",
            tradition: .catholic,
            title: "Aquietar e confiar",
            reference: "Salmo 46",
            text: "Aquietai-vos e reconhecei que eu sou Deus. Ele é refúgio e força, auxílio sempre presente na tribulação.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "luke-6-catholic",
            tradition: .catholic,
            title: "Misericórdia concreta",
            reference: "Lucas 6, 36",
            text: "Sede misericordiosos, como também vosso Pai é misericordioso. A misericórdia começa na próxima escolha.",
            estimatedMinutes: 5,
            theme: .forgiveness,
            section: .gospels,
            book: .luke
        ),
        ScripturePassage(
            id: "proverbs-4-catholic",
            tradition: .catholic,
            title: "Guardar o coração",
            reference: "Provérbios 4, 23",
            text: "Com todo cuidado guarda o teu coração, porque dele brotam as fontes da vida.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "romans-12-catholic",
            tradition: .catholic,
            title: "Mente renovada",
            reference: "Romanos 12, 2",
            text: "Transformai-vos pela renovação da mente, para discernir o que é bom, agradável e perfeito diante de Deus.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .paulineLetters,
            book: .romans
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
            id: "philippians-4-protestant",
            tradition: .protestant,
            title: "Paz que guarda",
            reference: "Filipenses 4:6-7",
            text: "Não andem ansiosos por coisa alguma. Apresentem seus pedidos a Deus, e a paz de Deus guardará o coração e a mente.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .paulineLetters,
            book: .corinthians
        ),
        ScripturePassage(
            id: "psalm-46-protestant",
            tradition: .protestant,
            title: "Aquietem-se",
            reference: "Salmo 46:10",
            text: "Aquietem-se e saibam que eu sou Deus. Ele é refúgio e fortaleza, socorro bem presente na angústia.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "john-14-protestant",
            tradition: .protestant,
            title: "Paz deixada por Cristo",
            reference: "João 14:27",
            text: "Deixo-lhes a paz; a minha paz lhes dou. Não se perturbe o coração de vocês, nem tenham medo.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "proverbs-4-protestant",
            tradition: .protestant,
            title: "Guardar o coração",
            reference: "Provérbios 4:23",
            text: "Acima de tudo, guarde o seu coração, pois dele depende toda a sua vida.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "luke-10-protestant",
            tradition: .protestant,
            title: "Uma coisa necessária",
            reference: "Lucas 10:41-42",
            text: "Você está preocupada e inquieta com muitas coisas; todavia, apenas uma é necessária.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .gospels,
            book: .luke
        ),
        ScripturePassage(
            id: "isaiah-40-protestant",
            tradition: .protestant,
            title: "Forças renovadas",
            reference: "Isaías 40:31",
            text: "Aqueles que esperam no Senhor renovam as suas forças; caminham e não se fatigam.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .prophets,
            book: .isaiah
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
            id: "deuteronomy-6-jewish",
            tradition: .jewish,
            title: "Coração inteiro",
            reference: "Devarim / Deuteronômio 6:5",
            text: "Amarás o Eterno teu Deus com todo o teu coração, com toda a tua alma e com toda a tua força.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .torah,
            book: .deuteronomy
        ),
        ScripturePassage(
            id: "psalm-46-jewish",
            tradition: .jewish,
            title: "Refúgio e força",
            reference: "Tehillim / Salmo 46:10",
            text: "Aquietai-vos e sabei que eu sou Deus. O Eterno é refúgio e força em tempos de aperto.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "micah-6-jewish",
            tradition: .jewish,
            title: "Justiça e humildade",
            reference: "Miquéias 6:8",
            text: "Foi-te declarado o que é bom: praticar a justiça, amar a bondade e caminhar humildemente com o Eterno.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "joshua-1-jewish",
            tradition: .jewish,
            title: "Coragem no caminho",
            reference: "Yehoshua / Josué 1:9",
            text: "Sê forte e corajoso. Não temas, pois o Eterno teu Deus estará contigo por onde quer que andares.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .historicalBooks,
            book: .genesis
        ),
        ScripturePassage(
            id: "psalm-34-jewish",
            tradition: .jewish,
            title: "Paz procurada",
            reference: "Tehillim / Salmo 34:14",
            text: "Afasta-te do mal e faze o bem; procura a paz e segue-a com firmeza.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "proverbs-16-jewish",
            tradition: .jewish,
            title: "Planos confiados",
            reference: "Mishlei / Provérbios 16:3",
            text: "Entrega tuas obras ao Eterno, e teus planos serão estabelecidos.",
            estimatedMinutes: 5,
            theme: .work,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "matthew-5-spiritist",
            tradition: .spiritist,
            title: "Bem-aventurados os mansos",
            reference: "Mateus 5:5",
            text: "Bem-aventurados os mansos, porque herdarão a terra. A mansidão aqui não é fraqueza: é domínio de si antes da resposta impulsiva.",
            estimatedMinutes: 5,
            theme: .patience,
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
            theme: .consolationHope,
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
            theme: .innerReform,
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
            theme: .patience,
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
            theme: .innerReform,
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
            theme: .charity,
            section: .paulineLetters,
            book: .corinthians
        ),
        ScripturePassage(
            id: "matthew-6-spiritist",
            tradition: .spiritist,
            title: "Tesouro do coração",
            reference: "Mateus 6:21",
            text: "Onde está o teu tesouro, aí estará também o teu coração. A atenção revela aquilo que estamos alimentando.",
            estimatedMinutes: 5,
            theme: .moralApplication,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "proverbs-4-spiritist",
            tradition: .spiritist,
            title: "Vigiar o coração",
            reference: "Provérbios 4:23",
            text: "Guarda o teu coração, porque dele procedem as fontes da vida. Vigiar a atenção também é educar a alma.",
            estimatedMinutes: 5,
            theme: .moralApplication,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "luke-10-spiritist",
            tradition: .spiritist,
            title: "Uma só coisa necessária",
            reference: "Lucas 10:41-42",
            text: "Tu te inquietas por muitas coisas; uma só é necessária. A pausa ajuda a escolher o essencial.",
            estimatedMinutes: 5,
            theme: .prayer,
            section: .gospels,
            book: .luke
        ),
        ScripturePassage(
            id: "matthew-5-peace-spiritist",
            tradition: .spiritist,
            title: "Pacificadores",
            reference: "Mateus 5:9",
            text: "Bem-aventurados os pacificadores. A paz começa quando a resposta deixa de ser automática.",
            estimatedMinutes: 5,
            theme: .charity,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "galatians-6-spiritist",
            tradition: .spiritist,
            title: "Semear o bem",
            reference: "Gálatas 6:9",
            text: "Não nos cansemos de fazer o bem. Pequenas escolhas repetidas educam a vontade no caminho da caridade.",
            estimatedMinutes: 5,
            theme: .spiritualEvolution,
            section: .paulineLetters,
            book: .corinthians
        ),
        ScripturePassage(
            id: "john-15-spiritist",
            tradition: .spiritist,
            title: "Permanecer no bem",
            reference: "João 15:5",
            text: "Quem permanece em mim produz fruto. A permanência no bem transforma intenção em atitude concreta.",
            estimatedMinutes: 5,
            theme: .gospelOfJesus,
            section: .gospels,
            book: .john
        ),

        // MARK: Catálogo expandido — Católica

        ScripturePassage(
            id: "psalm-27-catholic",
            tradition: .catholic,
            title: "Luz e salvação",
            reference: "Salmo 27, 1",
            text: "O Senhor é minha luz e minha salvação: a quem temerei? O Senhor é a fortaleza da minha vida.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-37-catholic",
            tradition: .catholic,
            title: "Entregar o caminho",
            reference: "Salmo 37, 5",
            text: "Entrega teu caminho ao Senhor, confia nele, e ele agirá.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-34-catholic",
            tradition: .catholic,
            title: "Provai e vede",
            reference: "Salmo 34, 9",
            text: "Provai e vede como o Senhor é bom; feliz quem nele encontra o seu refúgio.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-90-catholic",
            tradition: .catholic,
            title: "Coração sábio",
            reference: "Salmo 90, 12",
            text: "Ensina-nos a contar os nossos dias, para alcançarmos um coração sábio.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-103-catholic",
            tradition: .catholic,
            title: "Não esquecer os benefícios",
            reference: "Salmo 103, 1-2",
            text: "Bendize, ó minha alma, ao Senhor, e não esqueças nenhum de seus benefícios.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-118-catholic",
            tradition: .catholic,
            title: "O dia que o Senhor fez",
            reference: "Salmo 118, 24",
            text: "Este é o dia que o Senhor fez: exultemos e alegremo-nos nele.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-139-catholic",
            tradition: .catholic,
            title: "Conhecido por inteiro",
            reference: "Salmo 139, 1-3",
            text: "Senhor, tu me sondas e me conheces. Sabes quando me sento e quando me levanto; de longe penetras meus pensamentos.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "proverbs-15-catholic",
            tradition: .catholic,
            title: "Resposta branda",
            reference: "Provérbios 15, 1",
            text: "A resposta branda acalma o furor, mas a palavra dura excita a ira.",
            estimatedMinutes: 5,
            theme: .family,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "proverbs-16-catholic",
            tradition: .catholic,
            title: "Passos firmados",
            reference: "Provérbios 16, 9",
            text: "O coração do homem traça o seu caminho, mas é o Senhor quem firma os seus passos.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "proverbs-17-catholic",
            tradition: .catholic,
            title: "Coração alegre",
            reference: "Provérbios 17, 22",
            text: "O coração alegre é bom remédio, mas o espírito abatido resseca os ossos.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "proverbs-19-catholic",
            tradition: .catholic,
            title: "O desígnio que permanece",
            reference: "Provérbios 19, 21",
            text: "Muitos são os projetos no coração do homem, mas é o desígnio do Senhor que permanece.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "isaiah-26-catholic",
            tradition: .catholic,
            title: "Paz para o coração firme",
            reference: "Isaías 26, 3",
            text: "Tu conservas na paz o coração firme, porque em ti ele confia.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "isaiah-30-catholic",
            tradition: .catholic,
            title: "Força na serenidade",
            reference: "Isaías 30, 15",
            text: "Na conversão e na calma está a vossa salvação; na serenidade e na confiança está a vossa força.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "isaiah-43-catholic",
            tradition: .catholic,
            title: "Chamado pelo nome",
            reference: "Isaías 43, 1-2",
            text: "Não temas, pois eu te resgatei; chamei-te pelo teu nome: tu és meu. Quando atravessares as águas, estarei contigo.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "isaiah-55-catholic",
            tradition: .catholic,
            title: "Caminhos mais altos",
            reference: "Isaías 55, 8-9",
            text: "Meus pensamentos não são os vossos pensamentos, e vossos caminhos não são os meus caminhos, diz o Senhor.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "matthew-5-light-catholic",
            tradition: .catholic,
            title: "Luz do mundo",
            reference: "Mateus 5, 14-16",
            text: "Vós sois a luz do mundo. Brilhe a vossa luz diante dos homens, para que vejam as vossas boas obras.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "matthew-6-34-catholic",
            tradition: .catholic,
            title: "A cada dia basta seu cuidado",
            reference: "Mateus 6, 34",
            text: "Não vos inquieteis com o dia de amanhã, pois o amanhã terá suas próprias inquietações. A cada dia basta o seu cuidado.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "matthew-7-catholic",
            tradition: .catholic,
            title: "Pedi, buscai, batei",
            reference: "Mateus 7, 7",
            text: "Pedi e vos será dado; buscai e achareis; batei e vos será aberto.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "luke-12-catholic",
            tradition: .catholic,
            title: "A inquietação não acrescenta",
            reference: "Lucas 12, 25-26",
            text: "Quem de vós, com sua inquietação, pode acrescentar um só instante à duração de sua vida?",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .gospels,
            book: .luke
        ),
        ScripturePassage(
            id: "john-8-catholic",
            tradition: .catholic,
            title: "A luz da vida",
            reference: "João 8, 12",
            text: "Eu sou a luz do mundo. Quem me segue não andará nas trevas, mas terá a luz da vida.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "john-13-catholic",
            tradition: .catholic,
            title: "Mandamento novo",
            reference: "João 13, 34",
            text: "Amai-vos uns aos outros como eu vos amei.",
            estimatedMinutes: 5,
            theme: .family,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "john-16-catholic",
            tradition: .catholic,
            title: "Coragem provada",
            reference: "João 16, 33",
            text: "No mundo tereis aflições. Mas tende coragem: eu venci o mundo.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "romans-8-28-catholic",
            tradition: .catholic,
            title: "Tudo contribui para o bem",
            reference: "Romanos 8, 28",
            text: "Deus faz com que tudo contribua para o bem daqueles que o amam.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .paulineLetters,
            book: .romans
        ),
        ScripturePassage(
            id: "romans-15-catholic",
            tradition: .catholic,
            title: "Deus da esperança",
            reference: "Romanos 15, 13",
            text: "Que o Deus da esperança vos encha de toda alegria e paz na fé.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .paulineLetters,
            book: .romans
        ),
        ScripturePassage(
            id: "corinthians-13-catholic",
            tradition: .catholic,
            title: "O amor é paciente",
            reference: "1 Coríntios 13, 4-7",
            text: "O amor é paciente, o amor é prestativo; não é invejoso, não se ostenta. Tudo desculpa, tudo crê, tudo espera.",
            estimatedMinutes: 5,
            theme: .family,
            section: .paulineLetters,
            book: .corinthians
        ),
        ScripturePassage(
            id: "corinthians-16-catholic",
            tradition: .catholic,
            title: "Tudo no amor",
            reference: "1 Coríntios 16, 14",
            text: "Tudo o que fizerdes, fazei-o no amor.",
            estimatedMinutes: 5,
            theme: .charity,
            section: .paulineLetters,
            book: .corinthians
        ),
        ScripturePassage(
            id: "genesis-28-catholic",
            tradition: .catholic,
            title: "Guardado no caminho",
            reference: "Gênesis 28, 15",
            text: "Eis que estou contigo e te guardarei por onde quer que fores.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .torah,
            book: .genesis
        ),
        ScripturePassage(
            id: "exodus-33-catholic",
            tradition: .catholic,
            title: "Presença e descanso",
            reference: "Êxodo 33, 14",
            text: "Minha presença irá contigo, e eu te darei descanso.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .torah,
            book: .exodus
        ),
        ScripturePassage(
            id: "wisdom-6-catholic",
            tradition: .catholic,
            title: "Sabedoria radiante",
            reference: "Sabedoria 6, 12",
            text: "A Sabedoria é radiante e não fenece; deixa-se ver facilmente por aqueles que a amam.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .deuterocanonical,
            book: .wisdom
        ),
        ScripturePassage(
            id: "sirach-6-catholic",
            tradition: .catholic,
            title: "Amigo fiel",
            reference: "Eclesiástico 6, 14",
            text: "O amigo fiel é abrigo seguro: quem o encontrou, encontrou um tesouro.",
            estimatedMinutes: 5,
            theme: .family,
            section: .deuterocanonical,
            book: .sirach
        ),
        ScripturePassage(
            id: "sirach-2-catholic",
            tradition: .catholic,
            title: "Firmeza na provação",
            reference: "Eclesiástico 2, 1-2",
            text: "Filho, se te apresentas para servir ao Senhor, prepara a tua alma para a provação. Torna reto o teu coração e sê firme.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .deuterocanonical,
            book: .sirach
        ),
        ScripturePassage(
            id: "tobias-4-catholic",
            tradition: .catholic,
            title: "Não desviar o rosto",
            reference: "Tobias 4, 7",
            text: "Não desvies o teu rosto de nenhum pobre, e o rosto de Deus não se desviará de ti.",
            estimatedMinutes: 5,
            theme: .charity,
            section: .deuterocanonical,
            book: .tobias
        ),

        // MARK: Catálogo expandido — Evangélica

        ScripturePassage(
            id: "psalm-119-protestant",
            tradition: .protestant,
            title: "Lâmpada para os pés",
            reference: "Salmo 119:105",
            text: "Lâmpada para os meus pés é a tua palavra e luz para o meu caminho.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-37-protestant",
            tradition: .protestant,
            title: "Confiar e agir",
            reference: "Salmo 37:5",
            text: "Entregue o seu caminho ao Senhor; confie nele, e ele agirá.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-27-protestant",
            tradition: .protestant,
            title: "De quem terei temor?",
            reference: "Salmo 27:1",
            text: "O Senhor é a minha luz e a minha salvação; de quem terei temor?",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-91-protestant",
            tradition: .protestant,
            title: "À sombra do Altíssimo",
            reference: "Salmo 91:1-2",
            text: "Aquele que habita no abrigo do Altíssimo descansará à sombra do Todo-poderoso.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-34-protestant",
            tradition: .protestant,
            title: "Provem e vejam",
            reference: "Salmo 34:8",
            text: "Provem e vejam como o Senhor é bom; como é feliz quem nele se refugia.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "proverbs-18-protestant",
            tradition: .protestant,
            title: "Torre forte",
            reference: "Provérbios 18:10",
            text: "O nome do Senhor é torre forte; o justo corre para ela e está seguro.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "proverbs-15-protestant",
            tradition: .protestant,
            title: "Resposta calma",
            reference: "Provérbios 15:1",
            text: "A resposta calma desvia a fúria, mas a palavra ríspida desperta a ira.",
            estimatedMinutes: 5,
            theme: .family,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "proverbs-19-protestant",
            tradition: .protestant,
            title: "O propósito permanece",
            reference: "Provérbios 19:21",
            text: "Muitos são os planos no coração do homem, mas o propósito do Senhor permanece.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "isaiah-26-protestant",
            tradition: .protestant,
            title: "Perfeita paz",
            reference: "Isaías 26:3",
            text: "Tu guardarás em perfeita paz aquele cujo propósito está firme, porque em ti confia.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "isaiah-43-protestant",
            tradition: .protestant,
            title: "Pelas águas",
            reference: "Isaías 43:2",
            text: "Quando você atravessar as águas, eu estarei com você; os rios não o encobrirão.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "isaiah-55-protestant",
            tradition: .protestant,
            title: "Buscar enquanto é tempo",
            reference: "Isaías 55:6",
            text: "Busquem o Senhor enquanto é possível achá-lo; clamem por ele enquanto está perto.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "matthew-6-34-protestant",
            tradition: .protestant,
            title: "Um dia de cada vez",
            reference: "Mateus 6:34",
            text: "Não se preocupem com o amanhã, pois o amanhã trará as suas próprias preocupações. Basta a cada dia o seu próprio mal.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "matthew-5-16-protestant",
            tradition: .protestant,
            title: "Boas obras que brilham",
            reference: "Mateus 5:16",
            text: "Que a luz de vocês brilhe diante dos homens, para que vejam as suas boas obras e glorifiquem ao Pai.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "matthew-7-protestant",
            tradition: .protestant,
            title: "A porta será aberta",
            reference: "Mateus 7:7",
            text: "Peçam, e será dado; busquem, e encontrarão; batam, e a porta será aberta.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "john-3-protestant",
            tradition: .protestant,
            title: "O amor que deu tudo",
            reference: "João 3:16",
            text: "Porque Deus tanto amou o mundo que deu o seu Filho unigênito, para que todo o que nele crer não pereça, mas tenha a vida eterna.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "john-16-protestant",
            tradition: .protestant,
            title: "Tenham ânimo",
            reference: "João 16:33",
            text: "Neste mundo vocês terão aflições; contudo, tenham ânimo! Eu venci o mundo.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "john-15-protestant",
            tradition: .protestant,
            title: "A videira e os ramos",
            reference: "João 15:5",
            text: "Eu sou a videira; vocês são os ramos. Quem permanece em mim, e eu nele, dá muito fruto.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "luke-6-38-protestant",
            tradition: .protestant,
            title: "Deem e será dado",
            reference: "Lucas 6:38",
            text: "Deem e lhes será dado: uma boa medida, calcada, sacudida e transbordante.",
            estimatedMinutes: 5,
            theme: .charity,
            section: .gospels,
            book: .luke
        ),
        ScripturePassage(
            id: "romans-8-28-protestant",
            tradition: .protestant,
            title: "Para o bem dos que amam",
            reference: "Romanos 8:28",
            text: "Sabemos que Deus age em todas as coisas para o bem daqueles que o amam.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .paulineLetters,
            book: .romans
        ),
        ScripturePassage(
            id: "romans-12-12-protestant",
            tradition: .protestant,
            title: "Perseverar na oração",
            reference: "Romanos 12:12",
            text: "Alegrem-se na esperança, sejam pacientes na tribulação, perseverem na oração.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .paulineLetters,
            book: .romans
        ),
        ScripturePassage(
            id: "corinthians-10-protestant",
            tradition: .protestant,
            title: "Deus é fiel",
            reference: "1 Coríntios 10:13",
            text: "Deus é fiel; ele não permitirá que vocês sejam tentados além do que podem suportar.",
            estimatedMinutes: 5,
            theme: .discipline,
            section: .paulineLetters,
            book: .corinthians
        ),
        ScripturePassage(
            id: "revelation-3-protestant",
            tradition: .protestant,
            title: "À porta e bato",
            reference: "Apocalipse 3:20",
            text: "Eis que estou à porta e bato. Se alguém ouvir a minha voz e abrir a porta, entrarei.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .prophets,
            book: .revelation
        ),
        ScripturePassage(
            id: "revelation-21-protestant",
            tradition: .protestant,
            title: "Toda lágrima enxugada",
            reference: "Apocalipse 21:4",
            text: "Ele enxugará dos seus olhos toda lágrima. Não haverá mais morte, nem tristeza, nem choro, nem dor.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .prophets,
            book: .revelation
        ),
        ScripturePassage(
            id: "exodus-14-protestant",
            tradition: .protestant,
            title: "O Senhor lutará",
            reference: "Êxodo 14:14",
            text: "O Senhor lutará por vocês; tão somente acalmem-se.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .torah,
            book: .exodus
        ),
        ScripturePassage(
            id: "genesis-28-protestant",
            tradition: .protestant,
            title: "Cuidado em todo lugar",
            reference: "Gênesis 28:15",
            text: "Estou com você e cuidarei de você aonde quer que vá.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .torah,
            book: .genesis
        ),

        // MARK: Catálogo expandido — Judaica

        ScripturePassage(
            id: "psalm-90-jewish",
            tradition: .jewish,
            title: "Contar os dias",
            reference: "Tehillim / Salmo 90:12",
            text: "Ensina-nos a contar os nossos dias, para que alcancemos um coração sábio.",
            estimatedMinutes: 5,
            theme: .wisdom,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-118-jewish",
            tradition: .jewish,
            title: "O dia que o Eterno fez",
            reference: "Tehillim / Salmo 118:24",
            text: "Este é o dia que o Eterno fez; alegremo-nos e exultemos nele.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-130-jewish",
            tradition: .jewish,
            title: "Espera pela manhã",
            reference: "Tehillim / Salmo 130:5-6",
            text: "Minha alma espera pelo Eterno mais do que os vigias esperam pela manhã.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-37-jewish",
            tradition: .jewish,
            title: "Confiar o caminho",
            reference: "Tehillim / Salmo 37:5",
            text: "Confia o teu caminho ao Eterno; confia nele, e ele agirá.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "psalm-19-jewish",
            tradition: .jewish,
            title: "Os céus proclamam",
            reference: "Tehillim / Salmo 19:2",
            text: "Os céus proclamam a glória de Deus, e o firmamento anuncia a obra de suas mãos.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "proverbs-15-jewish",
            tradition: .jewish,
            title: "Resposta suave",
            reference: "Mishlei / Provérbios 15:1",
            text: "A resposta suave afasta a ira; a palavra dura desperta o furor.",
            estimatedMinutes: 5,
            theme: .family,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "proverbs-16-9-jewish",
            tradition: .jewish,
            title: "Passos firmados",
            reference: "Mishlei / Provérbios 16:9",
            text: "O coração do homem planeja o seu caminho, mas o Eterno firma os seus passos.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .wisdomBooks,
            book: .proverbs
        ),
        ScripturePassage(
            id: "isaiah-26-jewish",
            tradition: .jewish,
            title: "Paz firme",
            reference: "Yeshayahu / Isaías 26:3",
            text: "Ao que confia em ti, guardas em perfeita paz, porque o seu coração está firme.",
            estimatedMinutes: 5,
            theme: .anxiety,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "isaiah-30-jewish",
            tradition: .jewish,
            title: "Calma e confiança",
            reference: "Yeshayahu / Isaías 30:15",
            text: "No arrependimento e no repouso está a vossa salvação; na calma e na confiança está a vossa força.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "isaiah-55-jewish",
            tradition: .jewish,
            title: "Buscar o Eterno",
            reference: "Yeshayahu / Isaías 55:6",
            text: "Buscai o Eterno enquanto pode ser encontrado; invocai-o enquanto está perto.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .prophets,
            book: .isaiah
        ),
        ScripturePassage(
            id: "genesis-28-jewish",
            tradition: .jewish,
            title: "Guardado no caminho",
            reference: "Bereshit / Gênesis 28:15",
            text: "Eis que estou contigo e te guardarei por onde quer que andes.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .torah,
            book: .genesis
        ),
        ScripturePassage(
            id: "exodus-33-jewish",
            tradition: .jewish,
            title: "Presença e descanso",
            reference: "Shemot / Êxodo 33:14",
            text: "Minha presença irá contigo, e eu te darei descanso.",
            estimatedMinutes: 5,
            theme: .presence,
            section: .torah,
            book: .exodus
        ),
        ScripturePassage(
            id: "leviticus-19-jewish",
            tradition: .jewish,
            title: "Amar o próximo",
            reference: "Vayikra / Levítico 19:18",
            text: "Amarás o teu próximo como a ti mesmo.",
            estimatedMinutes: 5,
            theme: .family,
            section: .torah,
            book: .leviticus
        ),
        ScripturePassage(
            id: "numbers-6-jewish",
            tradition: .jewish,
            title: "Bênção e paz",
            reference: "Bamidbar / Números 6:24-26",
            text: "O Eterno te abençoe e te guarde; o Eterno faça brilhar sobre ti o seu rosto e te conceda a paz.",
            estimatedMinutes: 5,
            theme: .hope,
            section: .torah,
            book: .numbers
        ),
        ScripturePassage(
            id: "deuteronomy-30-jewish",
            tradition: .jewish,
            title: "Escolhe a vida",
            reference: "Devarim / Deuteronômio 30:19",
            text: "Pus diante de ti a vida e a morte, a bênção e a maldição. Escolhe, pois, a vida.",
            estimatedMinutes: 5,
            theme: .purpose,
            section: .torah,
            book: .deuteronomy
        ),
        ScripturePassage(
            id: "deuteronomy-31-jewish",
            tradition: .jewish,
            title: "Adiante de ti",
            reference: "Devarim / Deuteronômio 31:8",
            text: "O Eterno irá adiante de ti; ele estará contigo e não te deixará. Não temas.",
            estimatedMinutes: 5,
            theme: .faith,
            section: .torah,
            book: .deuteronomy
        ),

        // MARK: Catálogo expandido — Espírita

        ScripturePassage(
            id: "matthew-5-44-spiritist",
            tradition: .spiritist,
            title: "Amar além do fácil",
            reference: "Mateus 5:44",
            text: "Amai os vossos inimigos e orai pelos que vos perseguem. O perdão educa o coração para a paz.",
            estimatedMinutes: 5,
            theme: .forgiveness,
            section: .sermonOnMount,
            book: .matthew
        ),
        ScripturePassage(
            id: "matthew-6-14-spiritist",
            tradition: .spiritist,
            title: "Perdoar para seguir",
            reference: "Mateus 6:14",
            text: "Se perdoardes aos homens as suas faltas, também vosso Pai vos perdoará.",
            estimatedMinutes: 5,
            theme: .forgiveness,
            section: .sermonOnMount,
            book: .matthew
        ),
        ScripturePassage(
            id: "matthew-25-spiritist",
            tradition: .spiritist,
            title: "Nos pequeninos",
            reference: "Mateus 25:40",
            text: "Todas as vezes que fizestes isso a um destes meus pequeninos irmãos, foi a mim que o fizestes.",
            estimatedMinutes: 5,
            theme: .charity,
            section: .gospels,
            book: .matthew
        ),
        ScripturePassage(
            id: "matthew-7-1-spiritist",
            tradition: .spiritist,
            title: "Medida e julgamento",
            reference: "Mateus 7:1-2",
            text: "Não julgueis, para não serdes julgados. Com a medida com que medirdes, sereis medidos.",
            estimatedMinutes: 5,
            theme: .moralApplication,
            section: .sermonOnMount,
            book: .matthew
        ),
        ScripturePassage(
            id: "matthew-13-spiritist",
            tradition: .spiritist,
            title: "O grão de mostarda",
            reference: "Mateus 13:31-32",
            text: "O Reino dos céus é como um grão de mostarda: a menor das sementes, que cresce e se torna árvore.",
            estimatedMinutes: 5,
            theme: .spiritualEvolution,
            section: .parablesOfJesus,
            book: .matthew
        ),
        ScripturePassage(
            id: "matthew-5-luz-spiritist",
            tradition: .spiritist,
            title: "Luz pelas obras",
            reference: "Mateus 5:14-16",
            text: "Vós sois a luz do mundo. Que a vossa luz brilhe diante dos homens pelas boas obras.",
            estimatedMinutes: 5,
            theme: .practiceGood,
            section: .sermonOnMount,
            book: .matthew
        ),
        ScripturePassage(
            id: "luke-6-31-spiritist",
            tradition: .spiritist,
            title: "A regra simples",
            reference: "Lucas 6:31",
            text: "Como quereis que os homens vos façam, fazei-o também a eles.",
            estimatedMinutes: 5,
            theme: .moralApplication,
            section: .gospels,
            book: .luke
        ),
        ScripturePassage(
            id: "luke-10-samaritano-spiritist",
            tradition: .spiritist,
            title: "Compaixão que age",
            reference: "Lucas 10:33-34",
            text: "Um samaritano viu o homem ferido e moveu-se de compaixão: aproximou-se e cuidou dele.",
            estimatedMinutes: 5,
            theme: .charity,
            section: .parablesOfJesus,
            book: .luke
        ),
        ScripturePassage(
            id: "luke-15-spiritist",
            tradition: .spiritist,
            title: "O abraço do pai",
            reference: "Lucas 15:20",
            text: "Ainda estava longe, quando o pai o viu, moveu-se de compaixão, correu e o abraçou.",
            estimatedMinutes: 5,
            theme: .forgiveness,
            section: .parablesOfJesus,
            book: .luke
        ),
        ScripturePassage(
            id: "luke-17-spiritist",
            tradition: .spiritist,
            title: "O Reino dentro de vós",
            reference: "Lucas 17:21",
            text: "O Reino de Deus não vem com sinais visíveis: o Reino de Deus está dentro de vós.",
            estimatedMinutes: 5,
            theme: .innerReform,
            section: .gospels,
            book: .luke
        ),
        ScripturePassage(
            id: "john-13-spiritist",
            tradition: .spiritist,
            title: "Sinal de discipulado",
            reference: "João 13:34-35",
            text: "Amai-vos uns aos outros como eu vos amei. Nisto conhecerão que sois meus discípulos.",
            estimatedMinutes: 5,
            theme: .charity,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "john-14-moradas-spiritist",
            tradition: .spiritist,
            title: "Muitas moradas",
            reference: "João 14:2",
            text: "Na casa de meu Pai há muitas moradas. Vou preparar-vos um lugar.",
            estimatedMinutes: 5,
            theme: .consolationHope,
            section: .gospels,
            book: .john
        ),
        ScripturePassage(
            id: "romans-12-21-spiritist",
            tradition: .spiritist,
            title: "Vencer o mal com o bem",
            reference: "Romanos 12:21",
            text: "Não te deixes vencer pelo mal, mas vence o mal com o bem.",
            estimatedMinutes: 5,
            theme: .practiceGood,
            section: .paulineLetters,
            book: .romans
        ),
        ScripturePassage(
            id: "corinthians-13-13-spiritist",
            tradition: .spiritist,
            title: "A maior é a caridade",
            reference: "1 Coríntios 13:13",
            text: "Agora permanecem a fé, a esperança e a caridade; a maior delas é a caridade.",
            estimatedMinutes: 5,
            theme: .charity,
            section: .paulineLetters,
            book: .corinthians
        ),
        ScripturePassage(
            id: "psalm-23-spiritist",
            tradition: .spiritist,
            title: "O pastor que restaura",
            reference: "Salmo 23:1-3",
            text: "O Senhor é meu pastor, nada me faltará. Ele restaura as forças da minha alma.",
            estimatedMinutes: 5,
            theme: .consolationHope,
            section: .psalms,
            book: .psalms
        ),
        ScripturePassage(
            id: "proverbs-15-spiritist",
            tradition: .spiritist,
            title: "Mansidão na palavra",
            reference: "Provérbios 15:1",
            text: "A resposta branda desvia o furor. A mansidão na palavra é caridade na convivência.",
            estimatedMinutes: 5,
            theme: .patience,
            section: .wisdomBooks,
            book: .proverbs
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

struct AISpiritualReadingRequest: Codable, Hashable {
    let tradition: FaithTradition
    let favoriteSections: [BibleSection]
    let favoriteBooks: [BibleBook]
    let favoriteThemes: [SpiritualTheme]
    let explanationDepth: ExplanationDepth
    let candidateReferences: [String]
    let recentPassageIDs: [String]
    let recentReflections: [RecentAIReflectionDigest]

    var cacheKey: String {
        let rawKey = [
            "reading-content-v4-depth-aware",
            tradition.rawValue,
            favoriteSections.map(\.rawValue).sorted().joined(separator: ","),
            favoriteBooks.map(\.rawValue).sorted().joined(separator: ","),
            favoriteThemes.map(\.rawValue).sorted().joined(separator: ","),
            explanationDepth.rawValue,
            candidateReferences.joined(separator: "+"),
            recentPassageIDs.prefix(20).joined(separator: "+"),
            recentReflections.prefix(8).map { "\($0.reference):\($0.summary):\($0.meditationQuestion)" }.joined(separator: "+")
        ].joined(separator: "|")
        return Data(rawKey.utf8).base64EncodedString()
    }

    var compactPrompt: String {
        let sections = favoriteSections.map(\.title).joined(separator: ", ")
        let books = favoriteBooks.map(\.title).joined(separator: ", ")
        let themes = favoriteThemes.map(\.title).joined(separator: ", ")
        let sectionIDs = favoriteSections.map(\.rawValue).sorted().joined(separator: ", ")
        let bookIDs = favoriteBooks.map(\.rawValue).sorted().joined(separator: ", ")
        let themeIDs = favoriteThemes.map(\.rawValue).sorted().joined(separator: ", ")
        let avoidedSections = tradition.avoidedSectionTitlesForAI.joined(separator: ", ")
        let avoidedBooks = tradition.avoidedBookTitlesForAI.joined(separator: ", ")
        let references = candidateReferences.joined(separator: "; ")
        let recent = recentPassageIDs.prefix(20).joined(separator: ", ")
        let reflectionHistory = recentReflections.prefix(8)
            .map { "\($0.reference): \($0.summary) Pergunta: \($0.meditationQuestion)" }
            .joined(separator: "\n")
        return """
        Gere uma leitura espiritual para um usuário \(tradition.title) [id: \(tradition.rawValue)]. Use exatamente \(LimiarReadingConstants.targetItemCount) trechos. Seja acolhedor, simples e pastoral, em tom de homilia. Retorne itens com referência, texto religioso, explicação e conclusão prática. Não invente conteúdo bíblico.
        Para cada item, a explicação deve ser o parágrafo principal: explique o sentido espiritual do trecho e conecte com o tema escolhido.
        A conclusão prática deve ser curta, concreta e diferente em cada trecho. Ela precisa nascer do versículo e do tema, sem repetir fórmulas fixas como "Leve este trecho como uma pequena decisão".
        A profundidade precisa mudar visivelmente o tamanho e a densidade da explicação. \(explanationDepth.aiGenerationGuidance)
        Diretriz de tradição: \(tradition.aiToneGuidance)
        Seções preferidas: \(sections.isEmpty ? "Nenhuma" : sections)
        IDs das seções preferidas: \(sectionIDs.isEmpty ? "Nenhum" : sectionIDs)
        Livros preferidos: \(books.isEmpty ? "Nenhum" : books)
        IDs dos livros preferidos: \(bookIDs.isEmpty ? "Nenhum" : bookIDs)
        Temas preferidos: \(themes.isEmpty ? "Nenhum" : themes)
        IDs dos temas preferidos: \(themeIDs.isEmpty ? "Nenhum" : themeIDs)
        Evitar seções incompatíveis: \(avoidedSections.isEmpty ? "Nenhuma" : avoidedSections)
        Evitar livros incompatíveis: \(avoidedBooks.isEmpty ? "Nenhum" : avoidedBooks)
        Profundidade: \(explanationDepth.title)
        Referências sugeridas: \(references)
        Evite repetir estes trechos recentes: \(recent)
        Evite repetir estas reflexões recentes:
        \(reflectionHistory)
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
        passages.prefix(LimiarReadingConstants.targetItemCount).map { passage in
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
        let variation = abs((request.cacheKey + passage.id).hashValue) % 3
        let traditionOpening = switch (request.tradition, variation) {
        case (.catholic, 0):
            "Este trecho pode ser acolhido como uma pequena homilia para o coração."
        case (.catholic, 1):
            "Nesta passagem, a fé aparece como uma luz tranquila para reorganizar o interior."
        case (.catholic, _):
            "A leitura conduz a uma pausa orante, simples, mas capaz de devolver direção."
        case (.protestant, 0):
            "Este trecho pode ser acolhido como uma meditação devocional simples e fiel."
        case (.protestant, 1):
            "A Palavra aqui chama a atenção de volta para Deus antes da próxima decisão."
        case (.protestant, _):
            "Esta meditação ajuda a transformar impulso em discernimento diante do Senhor."
        case (.jewish, 0):
            "Este trecho pode ser acolhido como sabedoria do Tanakh para orientar a escolha presente."
        case (.jewish, 1):
            "A passagem oferece uma direção de sabedoria para caminhar com mais inteireza."
        case (.jewish, _):
            "A leitura recorda que cada escolha pode ser feita com memória, reverência e propósito."
        case (.spiritist, 0):
            "Este trecho pode ser acolhido como convite à reforma íntima e à caridade concreta."
        case (.spiritist, 1):
            "A mensagem favorece uma pausa de consciência, ajudando a educar desejo e vontade."
        case (.spiritist, _):
            "A reflexão aponta para uma decisão mais lúcida, fraterna e responsável."
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
        case .gospelOfJesus:
            "Ele recoloca o Evangelho de Jesus como medida concreta para a próxima atitude."
        case .innerReform:
            "Ele lembra que a reforma íntima começa em escolhas pequenas, repetidas e conscientes."
        case .charity:
            "Ele mostra que a caridade ganha corpo no modo como a pessoa responde agora."
        case .prayer:
            "Ele convida a transformar a pausa em prece simples, lúcida e sincera."
        case .patience:
            "Ele educa a paciência como força interior antes da reação automática."
        case .spiritualEvolution:
            "Ele recorda que a evolução espiritual passa por atenção, esforço e responsabilidade."
        case .consolationHope:
            "Ele oferece consolação sem fuga, reacendendo força interior para o próximo passo."
        case .moralApplication:
            "Ele pede aplicação moral concreta, para que a leitura vire atitude no cotidiano."
        case .practiceGood:
            "Ele transforma a leitura em prática do bem, com uma decisão concreta para hoje."
        case .prosperityWithPurpose:
            "Ele recorda que prosperidade ganha sentido quando serve a um propósito maior."
        case .financialBalance:
            "Ele ajuda a olhar a vida financeira com equilíbrio, responsabilidade e confiança."
        }

        switch request.explanationDepth {
        case .short:
            return "\(traditionOpening) \(themeLine)"
        case .medium:
            return """
            \(traditionOpening) \(themeLine)

            A referência \(passage.reference) foi priorizada dentro das preferências escolhidas para que a pausa tenha ligação real com a sua tradição e com o tema de \(passage.theme.title.lowercased()).
            """
        case .deep:
            return """
            \(traditionOpening) \(themeLine)

            Em \(passage.reference), a leitura não aparece apenas como uma frase bonita para acalmar o momento. Ela funciona como um convite a reconhecer o que está conduzindo a atenção antes de voltar aos apps selecionados.

            Como você escolheu uma reflexão mais profunda, vale permanecer mais um pouco com esta pergunta interior: que parte da sua rotina precisa ser educada por este trecho hoje? A resposta pode começar em uma atitude pequena, mas mais fiel ao que você deseja cultivar.
            """
        }
    }

    private func practicalConclusion(for passage: ScripturePassage, request: AISpiritualReadingRequest) -> String {
        let action = practicalAction(for: passage.theme)
        let variation = abs((request.cacheKey + passage.id + ".practice").hashValue) % 3

        switch (request.explanationDepth, variation) {
        case (.short, 0):
            return "Antes de voltar ao app, \(action)."
        case (.short, 1):
            return "Agora, \(action)."
        case (.short, _):
            return "Na próxima pausa, \(action)."
        case (.medium, 0):
            return "Para levar este trecho consigo, \(action)."
        case (.medium, 1):
            return "No restante do dia, \(action); deixe o versículo orientar uma escolha pequena."
        case (.medium, _):
            return "Transforme esta leitura em um gesto simples: \(action)."
        case (.deep, 0):
            return "Permaneça alguns instantes com o que este trecho desperta e, ao voltar ao app, \(action)."
        case (.deep, 1):
            return "Depois desta leitura, observe onde a Palavra toca sua rotina e \(action)."
        case (.deep, _):
            return "Deixe a pergunta do trecho acompanhar você por alguns minutos; em seguida, \(action)."
        }
    }

    private func practicalAction(for theme: SpiritualTheme) -> String {
        switch theme {
        case .faith:
            "confie um passo pequeno a Deus antes de reagir"
        case .hope:
            "procure um sinal de esperança no que ainda pode ser recomeçado"
        case .forgiveness:
            "responda com menos defesa e mais abertura ao perdão"
        case .discipline:
            "escolha um limite concreto para cuidar da sua atenção"
        case .wisdom:
            "separe o que é urgente do que é realmente importante"
        case .family:
            "ofereça mais presença a uma pessoa próxima"
        case .work:
            "retome uma tarefa com serenidade e intenção"
        case .anxiety:
            "respire antes de decidir e entregue a inquietação em prece"
        case .presence:
            "faça uma pausa consciente antes da próxima escolha"
        case .purpose:
            "alinhe uma decisão pequena ao propósito que você quer cultivar"
        case .gospelOfJesus:
            "olhe para Jesus como medida de uma atitude concreta"
        case .innerReform:
            "perceba um hábito que precisa ser educado com mansidão"
        case .charity:
            "transforme a pausa em um gesto discreto de caridade"
        case .prayer:
            "faça uma prece curta antes de retomar o que estava fazendo"
        case .patience:
            "espere alguns segundos antes de responder ao impulso"
        case .spiritualEvolution:
            "escolha uma atitude que favoreça seu crescimento espiritual"
        case .consolationHope:
            "receba consolo sem abandonar o próximo passo possível"
        case .moralApplication:
            "leve a leitura para uma atitude simples no cotidiano"
        case .practiceGood:
            "pratique o bem em uma escolha pequena e visível"
        case .prosperityWithPurpose:
            "use seus recursos com um propósito que também sirva ao bem"
        case .financialBalance:
            "olhe uma decisão financeira com equilíbrio e responsabilidade"
        }
    }
}

// Sessão do dia persistida: o app reutiliza a mesma leitura enquanto o usuário
// não conclui a travessia, em vez de gerar (e "gastar") trechos novos a cada
// abertura do app. Invalida automaticamente quando o dia ou o perfil mudam.
struct DailyReadingSessionSnapshot: Codable {
    let dayKey: String
    let profileKey: String
    let items: [SpiritualReadingItem]
    let reflection: AIReflection
}

struct DailyReadingSessionStore {
    private let defaults = UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    private let key = "limiar.dailyReadingSession.v1"

    static func todayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    func load(profileKey: String, dayKey: String = DailyReadingSessionStore.todayKey()) -> DailyReadingSessionSnapshot? {
        guard let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(DailyReadingSessionSnapshot.self, from: data),
              snapshot.dayKey == dayKey,
              snapshot.profileKey == profileKey,
              snapshot.items.count >= LimiarReadingConstants.targetItemCount else {
            return nil
        }
        return snapshot
    }

    func save(_ snapshot: DailyReadingSessionSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
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
    private let remoteService: RemoteAISpiritualReadingService

    init(
        cache: AISpiritualReadingCache = AISpiritualReadingCache(),
        generator: any AISpiritualReadingGenerating = LocalSpiritualReadingGenerator(),
        remoteService: RemoteAISpiritualReadingService = RemoteAISpiritualReadingService()
    ) {
        self.cache = cache
        self.generator = generator
        self.remoteService = remoteService
    }

    func readingItems(
        for passages: [ScripturePassage],
        profile: UserFaithProfile,
        recentPassageIDs: [String],
        recentReflections: [RecentAIReflectionDigest]
    ) -> [SpiritualReadingItem] {
        let request = AISpiritualReadingRequest(
            tradition: profile.tradition,
            favoriteSections: profile.favoriteBibleSections,
            favoriteBooks: profile.favoriteBooks,
            favoriteThemes: profile.favoriteThemes,
            explanationDepth: profile.explanationDepth,
            candidateReferences: passages.map(\.reference),
            recentPassageIDs: recentPassageIDs,
            recentReflections: recentReflections
        )

        if let cached = cache.readingItems(for: request), cached.count >= LimiarReadingConstants.targetItemCount {
            var values = LimiarAIDiagnostics.profileSnapshot(profile)
            values["source"] = "cache"
            values["endpoint"] = "spiritual-reading"
            values["items"] = "\(cached.count)"
            LimiarAIDiagnostics.log("ai_reading_items_loaded", values: values)
            return cached
        }

        let items = generator.generateReadingItems(for: request, passages: passages)
        cache.save(items, for: request)
        var values = LimiarAIDiagnostics.profileSnapshot(profile)
        values["source"] = "local"
        values["endpoint"] = "spiritual-reading"
        values["items"] = "\(items.count)"
        LimiarAIDiagnostics.log("ai_reading_items_loaded", values: values)
        return items
    }

    func remoteReadingItems(
        for passages: [ScripturePassage],
        profile: UserFaithProfile,
        recentPassageIDs: [String],
        recentReflections: [RecentAIReflectionDigest]
    ) async -> [SpiritualReadingItem]? {
        let request = AISpiritualReadingRequest(
            tradition: profile.tradition,
            favoriteSections: profile.favoriteBibleSections,
            favoriteBooks: profile.favoriteBooks,
            favoriteThemes: profile.favoriteThemes,
            explanationDepth: profile.explanationDepth,
            candidateReferences: passages.map(\.reference),
            recentPassageIDs: recentPassageIDs,
            recentReflections: recentReflections
        )

        do {
            let items = try await remoteService.readingItems(for: request, passages: passages)
            guard items.count >= min(LimiarReadingConstants.targetItemCount, max(1, passages.count)) else {
                debugPrint("limiar_ai_fallback_local", [
                    "endpoint": "spiritual-reading",
                    "reason": "unexpected_item_count",
                    "count": "\(items.count)"
                ])
                return nil
            }
            var values = LimiarAIDiagnostics.profileSnapshot(profile)
            values["source"] = "remote"
            values["endpoint"] = "spiritual-reading"
            values["items"] = "\(items.count)"
            LimiarAIDiagnostics.log("ai_reading_items_loaded", values: values)
            return items
        } catch {
            debugPrint("limiar_ai_fallback_local", [
                "endpoint": "spiritual-reading",
                "reason": String(describing: error)
            ])
            return nil
        }
    }
}

struct AIReflectionRequest: Codable, Hashable {
    let tradition: FaithTradition
    let passageReference: String
    let passageText: String
    let favoriteSections: [BibleSection]
    let favoriteBooks: [BibleBook]
    let favoriteThemes: [SpiritualTheme]
    let explanationDepth: ExplanationDepth
    let recentReflections: [RecentAIReflectionDigest]

    var cacheKey: String {
        let sections = favoriteSections.map(\.rawValue).sorted().joined(separator: ",")
        let books = favoriteBooks.map(\.rawValue).sorted().joined(separator: ",")
        let themes = favoriteThemes.map(\.rawValue).sorted().joined(separator: ",")
        let rawKey = [
            "reflection-content-v2-depth-aware",
            tradition.rawValue,
            passageReference,
            explanationDepth.rawValue,
            sections,
            books,
            themes,
            recentReflections.prefix(8).map { "\($0.reference):\($0.summary):\($0.meditationQuestion)" }.joined(separator: "+")
        ].joined(separator: "|")
        return Data(rawKey.utf8).base64EncodedString()
    }

    var compactPrompt: String {
        let sections = favoriteSections.map(\.title).joined(separator: ", ")
        let books = favoriteBooks.map(\.title).joined(separator: ", ")
        let themes = favoriteThemes.map(\.title).joined(separator: ", ")
        let sectionIDs = favoriteSections.map(\.rawValue).sorted().joined(separator: ", ")
        let bookIDs = favoriteBooks.map(\.rawValue).sorted().joined(separator: ", ")
        let themeIDs = favoriteThemes.map(\.rawValue).sorted().joined(separator: ", ")
        let avoidedSections = tradition.avoidedSectionTitlesForAI.joined(separator: ", ")
        let avoidedBooks = tradition.avoidedBookTitlesForAI.joined(separator: ", ")
        let compactText = String(passageText.prefix(1200))
        let reflectionHistory = recentReflections.prefix(8)
            .map { "\($0.reference): \($0.summary) Pergunta: \($0.meditationQuestion)" }
            .joined(separator: "\n")
        return """
        Explique este trecho para um usuário \(tradition.title) [id: \(tradition.rawValue)]. Seja claro, pastoral e respeite a profundidade selecionada. Não invente conteúdo bíblico. Retorne: resumo, significado espiritual, aplicação prática, conclusão e pergunta de meditação.
        A profundidade precisa mudar visivelmente o tamanho e a densidade da explicação. \(explanationDepth.aiGenerationGuidance)
        A aplicação prática deve ser curta, concreta, conectada ao trecho e ao tema do usuário, sem repetir fórmulas fixas entre respostas.
        Diretriz de tradição: \(tradition.aiToneGuidance)
        Referência: \(passageReference)
        Seções preferidas: \(sections.isEmpty ? "Nenhuma" : sections)
        IDs das seções preferidas: \(sectionIDs.isEmpty ? "Nenhum" : sectionIDs)
        Livros preferidos: \(books.isEmpty ? "Nenhum" : books)
        IDs dos livros preferidos: \(bookIDs.isEmpty ? "Nenhum" : bookIDs)
        Temas preferidos: \(themes.isEmpty ? "Nenhum" : themes)
        IDs dos temas preferidos: \(themeIDs.isEmpty ? "Nenhum" : themeIDs)
        Evitar seções incompatíveis: \(avoidedSections.isEmpty ? "Nenhuma" : avoidedSections)
        Evitar livros incompatíveis: \(avoidedBooks.isEmpty ? "Nenhum" : avoidedBooks)
        Profundidade: \(explanationDepth.title)
        Texto: \(compactText)
        Evite repetir estas reflexões recentes:
        \(reflectionHistory)
        """
    }
}

protocol AIReflectionGenerating {
    func generateReflection(for request: AIReflectionRequest) -> AIReflection
}

struct LocalLightweightReflectionGenerator: AIReflectionGenerating {
    func generateReflection(for request: AIReflectionRequest) -> AIReflection {
        let tone = traditionTone(for: request.tradition)
        let themeTitle = request.favoriteThemes.first?.title ?? "presença"
        let bookTitle = request.favoriteBooks.first?.title ?? "o trecho escolhido"
        let practical = practicalApplication(for: request, themeTitle: themeTitle)

        switch request.explanationDepth {
        case .short:
            return AIReflection(
                summary: "Este trecho abre um espaço breve entre o impulso e a escolha.",
                spiritualMeaning: "\(tone) O foco de hoje é \(themeTitle.lowercased()), vivido em uma decisão simples.",
                practicalApplication: practical,
                conclusion: "Atravesse este momento com presença.",
                meditationQuestion: "Que escolha ajuda você a cuidar da sua atenção agora?"
            )
        case .medium:
            return AIReflection(
                summary: "Este trecho ajuda a transformar a pausa em discernimento.",
                spiritualMeaning: """
                \(tone) A leitura convida você a olhar para \(themeTitle.lowercased()) sem pressa, deixando que a mensagem reorganize a próxima atitude.

                Como \(bookTitle) está entre suas preferências ou no caminho sugerido, a reflexão procura aproximar o texto da sua rotina real, especialmente antes de voltar aos apps selecionados.
                """,
                practicalApplication: practical,
                conclusion: "O Limiar ajuda a transformar o retorno ao celular em uma escolha mais consciente.",
                meditationQuestion: "Qual atitude pequena pode tornar o restante do dia mais fiel ao que você quer cultivar?"
            )
        case .deep:
            return AIReflection(
                summary: "Este trecho propõe uma pausa mais longa para reconhecer o que dirige sua atenção.",
                spiritualMeaning: """
                \(tone) Em uma reflexão mais profunda, a leitura não serve apenas para interromper o hábito; ela ajuda a perceber que cada retorno ao celular também revela desejos, inquietações e prioridades.

                O tema de \(themeTitle.lowercased()) pode ser acolhido como uma chave de interpretação: ele mostra onde sua vida pede mais cuidado espiritual, mais ordem interior e mais liberdade diante dos impulsos.

                Ao relacionar este caminho com \(bookTitle), a leitura procura respeitar a tradição escolhida e transformar o texto em uma meditação prática para o cotidiano, sem separar fé, atenção e decisão.
                """,
                practicalApplication: practical,
                conclusion: "Antes de retomar o uso, deixe este trecho tocar uma escolha concreta: voltar com mais intenção, menos automatismo e mais fidelidade ao que você quer formar em si.",
                meditationQuestion: "Que impulso costuma decidir por você, e que resposta mais livre este trecho convida você a praticar hoje?"
            )
        }
    }

    private func traditionTone(for tradition: FaithTradition) -> String {
        switch tradition {
        case .catholic:
            "O trecho pode ser acolhido como uma pequena homilia para voltar ao essencial com serenidade."
        case .protestant:
            "O trecho funciona como devocional para reorganizar prioridades diante de Deus."
        case .jewish:
            "O trecho pode ser lido como sabedoria prática do Tanakh para orientar a próxima escolha."
        case .spiritist:
            "O trecho convida à reforma íntima, responsabilidade e caridade nas escolhas concretas."
        }
    }

    private func practicalApplication(for request: AIReflectionRequest, themeTitle: String) -> String {
        switch request.explanationDepth {
        case .short:
            return "Antes de seguir, escolha uma atitude simples ligada a \(themeTitle.lowercased()) para cuidar da sua atenção."
        case .medium:
            return "Antes de seguir, respire, observe o impulso e escolha uma atitude ligada a \(themeTitle.lowercased()) para orientar os próximos minutos."
        case .deep:
            return "Antes de seguir, observe o impulso sem brigar com ele, nomeie o que está buscando e escolha uma atitude concreta de \(themeTitle.lowercased()) que aproxime sua atenção do que você considera mais importante."
        }
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
    private let remoteService: RemoteAIReflectionService

    init(
        cache: AIReflectionCache = AIReflectionCache(),
        generator: any AIReflectionGenerating = LocalLightweightReflectionGenerator(),
        remoteService: RemoteAIReflectionService = RemoteAIReflectionService()
    ) {
        self.cache = cache
        self.generator = generator
        self.remoteService = remoteService
    }

    func reflection(
        for passage: ScripturePassage,
        profile: UserFaithProfile,
        recentReflections: [RecentAIReflectionDigest]
    ) -> AIReflection {
        reflection(for: [passage], profile: profile, recentReflections: recentReflections)
    }

    func reflection(
        for passages: [ScripturePassage],
        profile: UserFaithProfile,
        recentReflections: [RecentAIReflectionDigest]
    ) -> AIReflection {
        let passageReference = passages.map(\.reference).joined(separator: " + ")
        let passageText = passages.map { "\($0.reference): \($0.text)" }.joined(separator: "\n\n")
        let request = AIReflectionRequest(
            tradition: profile.tradition,
            passageReference: passageReference,
            passageText: passageText,
            favoriteSections: profile.favoriteBibleSections,
            favoriteBooks: profile.favoriteBooks,
            favoriteThemes: profile.favoriteThemes,
            explanationDepth: profile.explanationDepth,
            recentReflections: recentReflections
        )
        if let cached = cache.reflection(for: request) {
            var values = LimiarAIDiagnostics.profileSnapshot(profile)
            values["source"] = "cache"
            values["endpoint"] = "reflection"
            values["reference"] = passageReference
            LimiarAIDiagnostics.log("ai_reflection_loaded", values: values)
            return cached
        }

        let reflection = generator.generateReflection(for: request)
        cache.save(reflection, for: request)
        var values = LimiarAIDiagnostics.profileSnapshot(profile)
        values["source"] = "local"
        values["endpoint"] = "reflection"
        values["reference"] = passageReference
        LimiarAIDiagnostics.log("ai_reflection_loaded", values: values)
        return reflection
    }

    func remoteReflection(
        for passages: [ScripturePassage],
        profile: UserFaithProfile,
        recentReflections: [RecentAIReflectionDigest]
    ) async -> AIReflection? {
        let passageReference = passages.map(\.reference).joined(separator: " + ")
        let passageText = passages.map { "\($0.reference): \($0.text)" }.joined(separator: "\n\n")
        let request = AIReflectionRequest(
            tradition: profile.tradition,
            passageReference: passageReference,
            passageText: passageText,
            favoriteSections: profile.favoriteBibleSections,
            favoriteBooks: profile.favoriteBooks,
            favoriteThemes: profile.favoriteThemes,
            explanationDepth: profile.explanationDepth,
            recentReflections: recentReflections
        )

        do {
            let reflection = try await remoteService.reflection(for: request, passages: passages)
            var values = LimiarAIDiagnostics.profileSnapshot(profile)
            values["source"] = "remote"
            values["endpoint"] = "reflection"
            values["reference"] = passageReference
            LimiarAIDiagnostics.log("ai_reflection_loaded", values: values)
            return reflection
        } catch {
            debugPrint("limiar_ai_fallback_local", [
                "endpoint": "reflection",
                "reason": String(describing: error)
            ])
            return nil
        }
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

struct RemoteSpiritualReadingRequestPayload: Codable {
    let profile: RemoteAIProfilePayload
    let passages: [RemotePassagePayload]
    let recentPassageIDs: [String]
    let recentReflections: [RemoteAIReflectionDigestPayload]
}

struct RemoteReflectionRequestPayload: Codable {
    let profile: RemoteAIProfilePayload
    let reference: String
    let passageText: String
    let passages: [RemotePassagePayload]
    let recentReflections: [RemoteAIReflectionDigestPayload]
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

struct RemoteSpiritualReadingResponse: Codable {
    let items: [RemoteSpiritualReadingItemResponse]
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

struct RemoteAISpiritualReadingService {
    private let client: RemoteAIBackendClient

    init(client: RemoteAIBackendClient = RemoteAIBackendClient()) {
        self.client = client
    }

    func readingItems(
        for request: AISpiritualReadingRequest,
        passages: [ScripturePassage]
    ) async throws -> [SpiritualReadingItem] {
        let payload = RemoteSpiritualReadingRequestPayload(
            profile: RemoteAIProfilePayload(
                profile: UserFaithProfile(
                    tradition: request.tradition,
                    favoriteBibleSections: request.favoriteSections,
                    favoriteBooks: request.favoriteBooks,
                    favoriteThemes: request.favoriteThemes,
                    explanationDepth: request.explanationDepth
                )
            ),
            passages: passages.map(RemotePassagePayload.init),
            recentPassageIDs: Array(request.recentPassageIDs.prefix(20)),
            recentReflections: request.recentReflections.prefix(8).map(RemoteAIReflectionDigestPayload.init)
        )

        let response = try await client.post(
            "/api/spiritual-reading",
            body: payload,
            responseType: RemoteSpiritualReadingResponse.self
        )
        let items = try response.items.enumerated().map { index, item in
            try item.validatedItem(cacheKey: request.cacheKey, index: index)
        }
        guard !items.isEmpty else { throw RemoteAIError.emptyContent }
        return items
    }
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
        let request = AISpiritualReadingRequest(
            tradition: profile.tradition,
            favoriteSections: profile.favoriteBibleSections,
            favoriteBooks: profile.favoriteBooks,
            favoriteThemes: profile.favoriteThemes,
            explanationDepth: profile.explanationDepth,
            candidateReferences: passages.map(\.reference),
            recentPassageIDs: recentPassageIDs,
            recentReflections: recentReflections
        )

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
                try item.validatedItem(cacheKey: request.cacheKey, index: index)
            }
            guard items.count >= min(LimiarReadingConstants.targetItemCount, max(1, passages.count)) else {
                debugPrint("limiar_ai_fallback_local", [
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
            debugPrint("limiar_ai_fallback_local", [
                "endpoint": "reading-session",
                "reason": String(describing: error)
            ])
            return nil
        }
    }
}

struct RemoteAIReflectionService {
    private let client: RemoteAIBackendClient

    init(client: RemoteAIBackendClient = RemoteAIBackendClient()) {
        self.client = client
    }

    func reflection(
        for request: AIReflectionRequest,
        passages: [ScripturePassage]
    ) async throws -> AIReflection {
        let payload = RemoteReflectionRequestPayload(
            profile: RemoteAIProfilePayload(
                profile: UserFaithProfile(
                    tradition: request.tradition,
                    favoriteBibleSections: request.favoriteSections,
                    favoriteBooks: request.favoriteBooks,
                    favoriteThemes: request.favoriteThemes,
                    explanationDepth: request.explanationDepth
                )
            ),
            reference: request.passageReference,
            passageText: request.passageText,
            passages: passages.map(RemotePassagePayload.init),
            recentReflections: request.recentReflections.prefix(8).map(RemoteAIReflectionDigestPayload.init)
        )

        let response = try await client.post(
            "/api/reflection",
            body: payload,
            responseType: RemoteReflectionResponse.self
        )
        return try response.validatedReflection()
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
