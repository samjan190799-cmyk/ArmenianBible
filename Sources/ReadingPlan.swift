import Foundation
import SwiftUI

// MARK: - Категория плана чтения
enum PlanCategory: String, CaseIterable, Identifiable, Codable {
    case gospels = "gospels"
    case psalms = "psalms"
    case wisdom = "wisdom"
    case epistles = "epistles"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .gospels: return "cross.fill"
        case .psalms: return "music.note"
        case .wisdom: return "lightbulb.fill"
        case .epistles: return "envelope.fill"
        }
    }
    
    func localizedName(for language: AppLanguage) -> String {
        switch self {
        case .gospels:
            switch language {
            case .armenian: return "Ավետարաններ"
            case .russian: return "Евангелия"
            case .english: return "Gospels"
            }
        case .psalms:
            switch language {
            case .armenian: return "Սաղմոսներ"
            case .russian: return "Псалмы"
            case .english: return "Psalms"
            }
        case .wisdom:
            switch language {
            case .armenian: return "Իմաստություն"
            case .russian: return "Мудрость"
            case .english: return "Wisdom"
            }
        case .epistles:
            switch language {
            case .armenian: return "Թղթեր"
            case .russian: return "Послания"
            case .english: return "Epistles"
            }
        }
    }
}

// MARK: - Цель чтения (Книга и глава)
struct PlanReadingTarget: Identifiable, Codable, Hashable {
    var id: String { "\(bookId)_\(chapter)" }
    let bookId: Int
    let chapter: Int
    let titleHy: String
    let titleRu: String
    let titleEn: String
    
    func title(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return titleHy
        case .russian: return titleRu
        case .english: return titleEn
        }
    }
}

// MARK: - День плана чтения
struct ReadingPlanDay: Identifiable, Codable, Hashable {
    var id: Int { dayNumber }
    let dayNumber: Int
    let titleHy: String
    let titleRu: String
    let titleEn: String
    let descHy: String
    let descRu: String
    let descEn: String
    let target: PlanReadingTarget
    
    func title(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return titleHy
        case .russian: return titleRu
        case .english: return titleEn
        }
    }
    
    func desc(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return descHy
        case .russian: return descRu
        case .english: return descEn
        }
    }
}

// MARK: - Модель Плана Чтения Библии
struct ReadingPlan: Identifiable, Codable, Hashable {
    let id: String
    let category: PlanCategory
    let icon: String
    let gradientColors: [String]
    let daysCount: Int
    
    let titleHy: String
    let titleRu: String
    let titleEn: String
    
    let descHy: String
    let descRu: String
    let descEn: String
    
    let days: [ReadingPlanDay]
    
    func title(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return titleHy
        case .russian: return titleRu
        case .english: return titleEn
        }
    }
    
    func desc(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return descHy
        case .russian: return descRu
        case .english: return descEn
        }
    }
    
    var gradient: LinearGradient {
        let colors = gradientColors.map { Color(hex: $0) }
        return LinearGradient(
            colors: colors.isEmpty ? [.blue, .purple] : colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Встроенная база планов чтения (Catalog)
extension ReadingPlan {
    static let allPlans: [ReadingPlan] = [
        makeGospels30Plan(),
        makePsalms14Plan(),
        makeProverbs14Plan(),
        makeEpistles30Plan()
    ]
    
    static func getPlan(by id: String) -> ReadingPlan? {
        return allPlans.first { $0.id == id }
    }
    
    // 1. Четыре Евангелия за 30 дней
    private static func makeGospels30Plan() -> ReadingPlan {
        let gospelsTargets: [(bookId: Int, ch: Int, ru: String, hy: String, en: String, descRu: String, descHy: String, descEn: String)] = [
            (40, 1, "От Матфея 1", "Մատթեոս 1", "Matthew 1", "Родословие и Рождество Иисуса Христа", "Հիսուս Քրիստոսի ծնունդը", "Genealogy and Birth of Jesus"),
            (40, 5, "От Матфея 5", "Մատթեոս 5", "Matthew 5", "Нагорная проповедь: Заповеди блаженства", "Լեռան քարոզը՝ Երանիները", "Sermon on the Mount: Beatitudes"),
            (40, 6, "От Матфея 6", "Մատթեոս 6", "Matthew 6", "Молитва «Отче наш» и упование на Бога", "«Հայր մեր» աղոթքը", "The Lord's Prayer"),
            (40, 7, "От Матфея 7", "Մատթեոս 7", "Matthew 7", "Золотое правило и узкие врата", "Ոսկե կանոնը և նեղ դուռը", "Ask, Seek, Knock"),
            (40, 13, "От Матфея 13", "Մատթեոս 13", "Matthew 13", "Притчи о Царстве Небесном", "Առակներ Երկնքի Արքայության մասին", "Parables of the Kingdom"),
            (40, 18, "От Матфея 18", "Մատթեոս 18", "Matthew 18", "Истинное величие и прощение", "Մեծությունը և ներումը", "True Greatness and Forgiveness"),
            (40, 26, "От Матфея 26", "Մատթեոս 26", "Matthew 26", "Тайная Вечеря и Гефсимания", "Վերջին Ընթրիքը և Գեթսեմանին", "The Last Supper and Gethsemane"),
            (40, 28, "От Матфея 28", "Մատթեոս 28", "Matthew 28", "Славное Воскресение и Великое поручение", "Հարությունը և Մեծ հանձնարարականը", "Resurrection and Great Commission"),
            (41, 1, "От Марка 1", "Մարկոս 1", "Mark 1", "Крещение Иисуса и начало благовестия", "Հիսուսի մկրտությունը", "John the Baptist and Jesus' Baptism"),
            (41, 2, "От Марка 2", "Մարկոս 2", "Mark 2", "Исцеление расслабленного", "Անդամալույծի բժշկությունը", "Healing of the Paralytic"),
            (41, 4, "От Марка 4", "Մարկոս 4", "Mark 4", "Укрощение бури на море", "Փոթորկի հանդարտեցումը", "Calming of the Storm"),
            (41, 8, "От Марка 8", "Մարկոս 8", "Mark 8", "Исповедание Петра и крестоношение", "Պետրոսի դավանությունը", "Peter's Confession of Christ"),
            (41, 10, "От Марка 10", "Մարկոս 10", "Mark 10", "Служение ближним и слепой Вартимей", "Ծառայություն և կույր Բարտիմեոսը", "The Son of Man Came to Serve"),
            (41, 16, "От Марка 16", "Մարկոս 16", "Mark 16", "Воскресение и свидетельство учеников", "Քրիստոսի Հարությունը", "The Resurrection of Jesus"),
            (42, 1, "От Луки 1", "Մատթեոս 1", "Luke 1", "Благовещение Пресвятой Девы Марии", "Ավետումը Սուրբ Կույսին", "Annunciation to Mary"),
            (42, 2, "От Луки 2", "Ղուկաս 2", "Luke 2", "Рождество Спасителя в Вифлееме", "Փրկչի Ծնունդը Բեթղեհեմում", "Birth of Jesus and the Shepherds"),
            (42, 4, "От Луки 4", "Ղուկաս 4", "Luke 4", "Искушение в пустыне и весть в Назарете", "Փորձությունը անապատում", "Temptation in the Wilderness"),
            (42, 10, "От Луки 10", "Ղուկաս 10", "Luke 10", "Притча о добром Самарянине", "Բարի Սամարացու առակը", "Parable of the Good Samaritan"),
            (42, 15, "От Луки 15", "Ղուկաս 15", "Luke 15", "Притчи о потерянной овце и блудном сыне", "Անառակ որդու առակը", "Parable of the Prodigal Son"),
            (42, 19, "От Луки 19", "Ղուկաս 19", "Luke 19", "Закхей мытарь и въезд в Иерусалим", "Զաքեոսը և մուտքը Երուսաղեմ", "Zacchaeus and Triumphal Entry"),
            (42, 23, "От Луки 23", "Ղուկաս 23", "Luke 23", "Крестные страдания Спасителя", "Խաչելությունը", "The Crucifixion"),
            (42, 24, "От Луки 24", "Ղուկաս 24", "Luke 24", "Дорога в Эммаус и Вознесение", "Ճանապարհը դեպի Էմմաուս", "The Road to Emmaus"),
            (43, 1, "От Иоанна 1", "Հովհաննես 1", "John 1", "В начале было Слово: Свет миру", "Ի սկզբանե էր Բանը", "The Word Became Flesh"),
            (43, 3, "От Иоанна 3", "Հովհաննես 3", "John 3", "Беседа с Никодимом: рождение свыше", "Նիկոդեմոսը և վերստին ծնունդը", "Nicodemus and God So Loved the World"),
            (43, 4, "От Иоанна 4", "Հովհաննես 4", "John 4", "Живая вода: самарянка у колодца", "Կենդանի ջուրը", "Living Water at the Well"),
            (43, 10, "От Иоанна 10", "Հովհաննես 10", "John 10", "Пастырь Добрый полагает жизнь за овец", "Բարի Հովիվը", "The Good Shepherd"),
            (43, 11, "От Иоанна 11", "Հովհաննես 11", "John 11", "Я есмь Воскресение и Жизнь: Лазарь", "Ես եմ Հարությունը և Կյանքը", "I Am the Resurrection and the Life"),
            (43, 14, "От Иоанна 14", "Հովհաննես 14", "John 14", "Я есмь Путь, Истина и Жизнь", "Ես եմ Ճանապարհը, Ճշմարտությունը և Կյանքը", "The Way, the Truth, and the Life"),
            (43, 15, "От Иоанна 15", "Հովհաննես 15", "John 15", "Истинная Виноградная Лоза", "Ճշմարիտ Որթատունկը", "I Am the True Vine"),
            (43, 21, "От Иоанна 21", "Հովհաննես 21", "John 21", "Явление на Тивериадском озере: паси овец Моих", "«Արածեցրո՛ւ իմ գառներին»", "Jesus Reinstates Peter")
        ]
        
        let days = gospelsTargets.enumerated().map { index, t in
            ReadingPlanDay(
                dayNumber: index + 1,
                titleHy: t.hy,
                titleRu: t.ru,
                titleEn: t.en,
                descHy: t.descHy,
                descRu: t.descRu,
                descEn: t.descEn,
                target: PlanReadingTarget(bookId: t.bookId, chapter: t.ch, titleHy: t.hy, titleRu: t.ru, titleEn: t.en)
            )
        }
        
        return ReadingPlan(
            id: "gospels_30",
            category: .gospels,
            icon: "cross.fill",
            gradientColors: ["#3B82F6", "#1D4ED8"],
            daysCount: 30,
            titleHy: "Չորս Ավետարանները (30 օր)",
            titleRu: "Четыре Евангелия (30 дней)",
            titleEn: "Four Gospels (30 Days)",
            descHy: "Հիսուս Քրիստոսի կյանքի, հրաշքների և հարության կարևորագույն գլուխները:",
            descRu: "Ключевые главы о земном служении, притчах, кресте и воскресении Христа.",
            descEn: "Journey through the life, teachings, cross, and resurrection of Jesus Christ.",
            days: days
        )
    }
    
    // 2. Псалмы надежды и утешения (14 дней)
    private static func makePsalms14Plan() -> ReadingPlan {
        let psalmsList: [(ch: Int, ru: String, hy: String, en: String, descRu: String, descHy: String, descEn: String)] = [
            (1, "Псалом 1", "Սաղմոս 1", "Psalm 1", "Блажен муж, ходящий в законе Господнем", "Երանելի է այն մարդը", "Blessed is the one who delights in the law"),
            (23, "Псалом 23", "Սաղմոս 23", "Psalm 23", "Господь — Пастырь мой, я ни в чем не буду нуждаться", "Տերն է իմ հովիվը", "The Lord is my Shepherd, I lack nothing"),
            (27, "Псалом 27", "Սաղմոս 27", "Psalm 27", "Господь — свет мой и спасение мое", "Տերն իմ լույսն է և փրկիչը", "The Lord is my light and my salvation"),
            (34, "Псалом 34", "Սաղմոս 34", "Psalm 34", "Вкусите и увидите, как благ Господь", "Ճաշակեցե՛ք և տեսե՛ք", "Taste and see that the Lord is good"),
            (46, "Псалом 46", "Սաղմոս 46", "Psalm 46", "Бог нам прибежище и сила, скорый помощник", "Աստված մեր ապավենն է և զորությունը", "God is our refuge and strength"),
            (51, "Псалом 50 (51)", "Սաղմոս 50", "Psalm 51", "Помилуй меня, Боже: покаянная молитва Давида", "Ողորմեա՛ ինձ, Աստված", "Create in me a pure heart, O God"),
            (63, "Псалом 62 (63)", "Սաղմոս 62", "Psalm 63", "Боже, Ты Бог мой, Тебя от ранней зари ищу я", "Աստված, դո՛ւ ես իմ Աստվածը", "My soul thirsts for You"),
            (91, "Псалом 90 (91)", "Սաղմոս 90", "Psalm 91", "Живущий под кровом Всевышнего", "Ով բնակվում է Բարձրյալի ծածկոցի տակ", "He who dwells in the shelter of the Most High"),
            (103, "Псалом 102 (103)", "Սաղմոս 102", "Psalm 103", "Благослови, душа моя, Господа", "Օրհնի՛ր, անձն իմ, Տիրոջը", "Praise the Lord, my soul"),
            (119, "Псалом 118 (119)", "Սաղմոս 118", "Psalm 119", "Слово Твое — светильник ноге моей", "Քո խոսքը ճրագ է իմ ոտքերի համար", "Your word is a lamp to my feet"),
            (121, "Псалом 120 (121)", "Սաղմոս 120", "Psalm 121", "Помощь моя от Господа, сотворившего небо и землю", "Իմ օգնությունը Տիրոջից է", "My help comes from the Lord"),
            (139, "Псалом 138 (139)", "Սաղմոս 138", "Psalm 139", "Господи, Ты испытал меня и знаешь", "Տե՛ր, դու քննեցիր ինձ", "You have searched me, Lord, and You know me"),
            (145, "Псалом 144 (145)", "Սաղմոս 144", "Psalm 145", "Буду превозносить Тебя, Боже мой, Царь мой", "Պիտի փառաբանեմ Քեզ, Աստվա՛ծ իմ", "I will exalt You, my God and King"),
            (150, "Псалом 150", "Սաղմոս 150", "Psalm 150", "Все дышащее да хвалит Господа! Аллилуия", "Ամեն շունչ թող օրհնի Տիրոջը", "Let everything that has breath praise the Lord")
        ]
        
        let days = psalmsList.enumerated().map { index, t in
            ReadingPlanDay(
                dayNumber: index + 1,
                titleHy: t.hy,
                titleRu: t.ru,
                titleEn: t.en,
                descHy: t.descHy,
                descRu: t.descRu,
                descEn: t.descEn,
                target: PlanReadingTarget(bookId: 19, chapter: t.ch, titleHy: t.hy, titleRu: t.ru, titleEn: t.en)
            )
        }
        
        return ReadingPlan(
            id: "psalms_14",
            category: .psalms,
            icon: "heart.text.square.fill",
            gradientColors: ["#D97706", "#F59E0B"],
            daysCount: 14,
            titleHy: "Սաղմոսների Մխիթարություն (14 օր)",
            titleRu: "Псалмы утешения и надежды (14 дней)",
            titleEn: "Psalms of Comfort & Hope (14 Days)",
            descHy: "Դավիթ թագավորի ամենահզոր սաղմոսները հոգու խաղաղության և Աստծո զորության համար:",
            descRu: "Избранные псалмы царя Давида для мира в сердце, укрепления веры и благодарения.",
            descEn: "Discover peace, divine protection, and joy through the most beloved Psalms of David.",
            days: days
        )
    }
    
    // 3. Мудрость царя Соломона (14 дней)
    private static func makeProverbs14Plan() -> ReadingPlan {
        let days = (1...14).map { ch in
            ReadingPlanDay(
                dayNumber: ch,
                titleHy: "Առակներ \(ch)",
                titleRu: "Притчи \(ch)",
                titleEn: "Proverbs \(ch)",
                descHy: "Իմաստություն, խոհեմություն և Տիրոջ երկյուղը կյանքի ճանապարհին:",
                descRu: "Мудрость, рассудительность и страх Господень для каждого дня.",
                descEn: "Wisdom, understanding, and righteousness for daily decisions.",
                target: PlanReadingTarget(
                    bookId: 20,
                    chapter: ch,
                    titleHy: "Առակներ \(ch)",
                    titleRu: "Притчи \(ch)",
                    titleEn: "Proverbs \(ch)"
                )
            )
        }
        
        return ReadingPlan(
            id: "proverbs_14",
            category: .wisdom,
            icon: "lightbulb.fill",
            gradientColors: ["#10B981", "#059669"],
            daysCount: 14,
            titleHy: "Սողոմոնի Իմաստությունը (14 օր)",
            titleRu: "Мудрость Соломона (14 дней)",
            titleEn: "Wisdom of Solomon (14 Days)",
            descHy: "Առակաց գրքի 14 գլուխները՝ կյանքի, ընտանիքի և խոսքի իմաստնության համար:",
            descRu: "14 глав из Книги Притчей для мудрости в делах, словах и отношениях.",
            descEn: "14 chapters of Proverbs to guide your heart, speech, and choices.",
            days: days
        )
    }
    
    // 4. Послания Нового Завета (30 дней)
    private static func makeEpistles30Plan() -> ReadingPlan {
        let epistlesList: [(bookId: Int, ch: Int, ru: String, hy: String, en: String, descRu: String, descHy: String, descEn: String)] = [
            (45, 8, "К Римлянам 8", "Հռոմեացիներին 8", "Romans 8", "Жизнь по Духу и неизменная любовь Божия", "Կյանք Հոգով և Աստծո սերը", "Life in the Spirit and God's Everlasting Love"),
            (45, 12, "К Римлянам 12", "Հռոմեացիներին 12", "Romans 12", "Жертва живая и христианская любовь", "Կենդանի պատարագ", "Living Sacrifices and True Love"),
            (46, 13, "1 Коринфянам 13", "Ա Կորնթացիներին 13", "1 Corinthians 13", "Гимн любви: любовь никогда не перестает", "Սիրո օրհներգը", "The Hymn of Love"),
            (46, 15, "1 Коринфянам 15", "Ա Կորնթացիներին 15", "1 Corinthians 15", "Тайна воскресения мертвых и победа", "Հարության խորհուրդը", "The Resurrection of Christ and Us"),
            (47, 4, "2 Коринфянам 4", "Բ Կորնթացիներին 4", "2 Corinthians 4", "Сокровище в глиняных сосудах", "Գանձը հողեղեն անոթներում", "Treasure in Jars of Clay"),
            (47, 5, "2 Коринфянам 5", "Բ Կորնթացիներին 5", "2 Corinthians 5", "Новое творение во Христе", "Նոր արարած Քրիստոսով", "New Creation in Christ"),
            (48, 5, "К Галатам 5", "Գաղատացիներին 5", "Galatians 5", "Плод Святого Духа и свобода во Христе", "Սուրբ Հոգու պտուղները", "Fruit of the Spirit"),
            (49, 2, "К Ефесянам 2", "Եփեսացիներին 2", "Ephesians 2", "Спасены благодатью через веру", "Փրկված շնորհով՝ հավատի միջոցով", "Saved by Grace Through Faith"),
            (49, 6, "К Ефесянам 6", "Եփեսացիներին 6", "Ephesians 6", "Всеоружие Божие для духовной брани", "Աստծո սպառազինությունը", "The Whole Armor of God"),
            (50, 2, "К Филиппийцам 2", "Փիլիպեցիներին 2", "Philippians 2", "Смирение Христа и Его возвышение", "Քրիստոսի խոնարհությունը", "Christ's Humility and Exaltation"),
            (50, 4, "К Филиппийцам 4", "Փիլիպեցիներին 4", "Philippians 4", "Все могу в укрепляющем меня Христе", "Ամեն ինչ կարող եմ ինձ զորացնող Քրիստոսով", "I Can Do All Things Through Christ"),
            (51, 3, "К Колоссянам 3", "Կողոսացիներին 3", "Colossians 3", "Ищите горнего и облекитесь в любовь", "Փնտրեցե՛ք վերինը", "Set Your Minds on Things Above"),
            (52, 5, "1 Фессалоникийцам 5", "Ա Թեսաղոնիկեցիներին 5", "1 Thessalonians 5", "Всегда радуйтесь, непрестанно молитесь", "Միշտ ուրախ եղեք, անդադար աղոթեցեք", "Rejoice Always, Pray Continually"),
            (54, 6, "1 Тимофею 6", "Ա Տիմոթեոսին 6", "1 Timothy 6", "Великое приобретение — быть благочестивым", "Բարեպաշտությունը մեծ շահ է", "Fight the Good Fight of Faith"),
            (55, 1, "2 Тимофею 1", "Բ Տիմոթեոսին 1", "2 Timothy 1", "Дух силы, любви и целомудрия", "Զորության, սիրո և ողջախոհության Հոգին", "Spirit of Power, Love, and Self-Discipline"),
            (58, 11, "К Евреям 11", "Եբրայեցիներին 11", "Hebrews 11", "Герои веры: вера есть осуществление ожидаемого", "Հավատի հերոսները", "Heroes of Faith"),
            (58, 12, "К Евреям 12", "Եբրայեցիներին 12", "Hebrews 12", "Взирая на Начальника и Совершителя веры", "Նայելով հավատի Առաջնորդին", "Fixing Our Eyes on Jesus"),
            (59, 1, "Иакова 1", "Հակոբոս 1", "James 1", "Испытание веры и будьте исполнителями слова", "Հավատի փորձությունը", "Faith and Endurance"),
            (59, 2, "Иакова 2", "Հակոբոս 2", "James 2", "Вера без дел мертва", "Հավատն առանց գործերի մեռած է", "Faith Without Deeds is Dead"),
            (59, 3, "Иакова 3", "Հակոբոս 3", "James 3", "Обуздание языка и небесная мудрость", "Լեզվի զսպումը", "Taming the Tongue"),
            (60, 1, "1 Петра 1", "Ա Պետրոս 1", "1 Peter 1", "Живое упование и святость жизни", "Կենդանի հույս", "Living Hope"),
            (60, 5, "1 Петра 5", "Ա Պետրոս 5", "1 Peter 5", "Все заботы возложите на Него", "Ձեր ամբողջ հոգսը Նրա վրա գցեք", "Cast All Your Anxiety on Him"),
            (62, 1, "1 Иоанна 1", "Ա Հովհաննես 1", "1 John 1", "Бог есть Свет, и нет в Нем тьмы", "Աստված լույս է", "Walking in the Light"),
            (62, 3, "1 Иоанна 3", "Ա Հովհաննես 3", "1 John 3", "Дети Божии и братская любовь", "Աստծո որդիները", "Children of God"),
            (62, 4, "1 Иоанна 4", "Ա Հովհաննես 4", "1 John 4", "Бог есть Любовь", "Աստված սեր է", "God is Love"),
            (65, 1, "Иуды 1", "Հուդա 1", "Jude 1", "Подвизаться за веру и сохранять себя в любви", "Մնացե՛ք Աստծո սիրո մեջ", "Contending for the Faith"),
            (66, 1, "Откровение 1", "Հայտնություն 1", "Revelation 1", "Я есмь Альфа и Омега, Первый и Последний", "Ես եմ Ալֆան և Օմեգան", "The Revelation of Jesus Christ"),
            (66, 7, "Откровение 7", "Հայտնություն 7", "Revelation 7", "Великое множество искупленных у престола", "Փրկվածների բազմությունը", "The Great Multitude in White Robes"),
            (66, 21, "Откровение 21", "Հայտնություն 21", "Revelation 21", "Новое небо и новая земля: Новый Иерусалим", "Նոր երկինք և նոր երկիր", "A New Heaven and a New Earth"),
            (66, 22, "Откровение 22", "Հայտնություն 22", "Revelation 22", "Река воды жизни: Ей, гряди, Господи Иисусе!", "Կենաց ջրի գետը", "The River of Life and Final Blessing")
        ]
        
        let days = epistlesList.enumerated().map { index, t in
            ReadingPlanDay(
                dayNumber: index + 1,
                titleHy: t.hy,
                titleRu: t.ru,
                titleEn: t.en,
                descHy: t.descHy,
                descRu: t.descRu,
                descEn: t.descEn,
                target: PlanReadingTarget(bookId: t.bookId, chapter: t.ch, titleHy: t.hy, titleRu: t.ru, titleEn: t.en)
            )
        }
        
        return ReadingPlan(
            id: "epistles_30",
            category: .epistles,
            icon: "envelope.fill",
            gradientColors: ["#8B5CF6", "#6D28D9"],
            daysCount: 30,
            titleHy: "Առաքյալների Թղթերը (30 օր)",
            titleRu: "Послания Апостолов (30 дней)",
            titleEn: "Epistles & Revelation (30 Days)",
            descHy: "Պողոս, Պետրոս, Հովհաննես առաքյալների կարևորագույն գլուխները և Հայտնությունը:",
            descRu: "Ключевые главы апостольских посланий: вера, любовь, Дух Святой и надежда.",
            descEn: "Inspiring chapters from Romans, Corinthians, Hebrews, Peter, John, and Revelation.",
            days: days
        )
    }
}
