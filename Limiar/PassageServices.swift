import Foundation

enum LimiarReadingConstants {
    static let targetItemCount = 4
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
        let rankedMatches = scored.sorted(by: { $0.score > $1.score }).map(\.passage)
        let freshMatches = rankedMatches.filter { passage in
            !recentIDs.contains(passage.id) && passage.id != currentPassageID
        }
        let olderMatches = rankedMatches.filter { passage in
            recentIDs.contains(passage.id) || passage.id == currentPassageID
        }

        return freshMatches + olderMatches
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
    let recentPassageIDs: [String]
    let recentReflections: [RecentAIReflectionDigest]

    var cacheKey: String {
        let rawKey = [
            "reading-content-v3-four-items",
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

        return "\(traditionOpening) \(themeLine)"
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
            return "No próximo período, \(action); deixe o versículo orientar uma escolha pequena."
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
            "escolha um limite concreto para proteger sua atenção"
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
            return cached
        }

        let items = generator.generateReadingItems(for: request, passages: passages)
        cache.save(items, for: request)
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
            cache.save(items, for: request)
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
        Explique este trecho para um usuário \(tradition.title) [id: \(tradition.rawValue)]. Seja claro, breve e pastoral. Não invente conteúdo bíblico. Retorne: resumo, significado espiritual, aplicação prática, conclusão e pergunta de meditação.
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
            return cached
        }

        let reflection = generator.generateReflection(for: request)
        cache.save(reflection, for: request)
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
            cache.save(reflection, for: request)
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
    var timeout: TimeInterval = 14
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

struct RemoteSpiritualReadingResponse: Codable {
    let items: [RemoteSpiritualReadingItemResponse]
}

struct RemoteSpiritualReadingItemResponse: Codable {
    let reference: String
    let passageText: String
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
            practicalConclusion: practicalText
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

private extension ExplanationDepth {
    var remoteValue: String {
        switch self {
        case .short:
            "curta"
        case .medium:
            "média"
        case .deep:
            "grande"
        }
    }
}

private extension String {
    var trimmedForAI: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
