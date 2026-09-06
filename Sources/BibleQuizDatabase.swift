import Foundation

// MARK: - Категория Викторины
enum QuizCategory: String, CaseIterable, Identifiable, Codable {
    case all = "all"
    case oldTestament = "old_testament"
    case gospels = "gospels"
    case newTestament = "new_testament"
    case churchHistory = "church_history"
    case verses = "verses"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "sparkles"
        case .oldTestament: return "scroll.fill"
        case .gospels: return "book.closed.fill"
        case .newTestament: return "cross.fill"
        case .churchHistory: return "building.columns.fill"
        case .verses: return "quote.bubble.fill"
        }
    }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .all:
            return "quiz_cat_all".localized(for: language)
        case .oldTestament:
            return "quiz_cat_old".localized(for: language)
        case .gospels:
            return "quiz_cat_gospels".localized(for: language)
        case .newTestament:
            return "quiz_cat_new".localized(for: language)
        case .churchHistory:
            return "quiz_cat_church_history".localized(for: language)
        case .verses:
            return "quiz_cat_verses".localized(for: language)
        }
    }
}

// MARK: - Уровень сложности
enum QuizDifficulty: String, CaseIterable, Identifiable, Codable {
    case all = "all"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var id: String { rawValue }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .all:
            return "quiz_diff_all".localized(for: language)
        case .easy:
            return "quiz_diff_easy".localized(for: language)
        case .medium:
            return "quiz_diff_medium".localized(for: language)
        case .hard:
            return "quiz_diff_hard".localized(for: language)
        }
    }
}

// MARK: - Модель вопроса Викторины
struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    let category: QuizCategory
    let difficulty: QuizDifficulty
    
    let questionHy: String
    let questionRu: String
    let questionEn: String
    
    let optionsHy: [String]
    let optionsRu: [String]
    let optionsEn: [String]
    
    let correctAnswerIndex: Int
    let explanationHy: String
    let explanationRu: String
    let explanationEn: String
    let verseRefHy: String
    let verseRefRu: String
    let verseRefEn: String
    
    var isAIGenerated: Bool = false
    var aiProviderName: String? = nil
    
    init(
        id: UUID = UUID(),
        category: QuizCategory,
        difficulty: QuizDifficulty = .medium,
        questionHy: String,
        questionRu: String,
        questionEn: String,
        optionsHy: [String],
        optionsRu: [String],
        optionsEn: [String],
        correctAnswerIndex: Int,
        explanationHy: String,
        explanationRu: String,
        explanationEn: String,
        verseRefHy: String,
        verseRefRu: String,
        verseRefEn: String,
        isAIGenerated: Bool = false,
        aiProviderName: String? = nil
    ) {
        self.id = id
        self.category = category
        self.difficulty = difficulty
        self.questionHy = questionHy
        self.questionRu = questionRu
        self.questionEn = questionEn
        self.optionsHy = optionsHy
        self.optionsRu = optionsRu
        self.optionsEn = optionsEn
        self.correctAnswerIndex = correctAnswerIndex
        self.explanationHy = explanationHy
        self.explanationRu = explanationRu
        self.explanationEn = explanationEn
        self.verseRefHy = verseRefHy
        self.verseRefRu = verseRefRu
        self.verseRefEn = verseRefEn
        self.isAIGenerated = isAIGenerated
        self.aiProviderName = aiProviderName
    }
    
    func question(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return questionHy
        case .russian: return questionRu
        case .english: return questionEn
        }
    }
    
    func options(for lang: AppLanguage) -> [String] {
        switch lang {
        case .armenian: return optionsHy
        case .russian: return optionsRu
        case .english: return optionsEn
        }
    }
    
    func explanation(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return explanationHy
        case .russian: return explanationRu
        case .english: return explanationEn
        }
    }
    
    func verseRef(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return verseRefHy
        case .russian: return verseRefRu
        case .english: return verseRefEn
        }
    }
}

// MARK: - База Данных Вопросов Викторины
struct QuizDatabase {
    static let allQuestions: [QuizQuestion] = [
        // =========================================================================
        // MARK: - 1. ВЕТХИЙ ЗАВЕТ (OLD TESTAMENT)
        // =========================================================================
        QuizQuestion(
            category: .oldTestament,
            difficulty: .easy,
            questionHy: "Քանի՞ օրում Աստված արարեց աշխարհը և հանգստացավ յոթերորդ օրը։",
            questionRu: "За сколько дней Бог сотворил мир, после чего почил в день седьмой?",
            questionEn: "In how many days did God create the world before resting on the seventh day?",
            optionsHy: ["5 օրում", "6 օրում", "7 օրում", "40 օրում"],
            optionsRu: ["За 5 дней", "За 6 дней", "За 7 дней", "За 40 дней"],
            optionsEn: ["In 5 days", "In 6 days", "In 7 days", "In 40 days"],
            correctAnswerIndex: 1,
            explanationHy: "Աստված արարեց երկինքն ու երկիրը 6 օրում, իսկ յոթերորդ օրը հանգստացավ Իր բոլոր գործերից։",
            explanationRu: "Бог сотворил небо и землю за 6 дней, а в седьмой день почил от всех дел Своих.",
            explanationEn: "God created the heavens and the earth in 6 days, and rested on the seventh day from all His work.",
            verseRefHy: "Ծննդոց 2:2",
            verseRefRu: "Бытие 2:2",
            verseRefEn: "Genesis 2:2"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .easy,
            questionHy: "Ո՞վ տապան կառուցեց ջրհեղեղից փրկվելու համար։",
            questionRu: "Кто построил ковчег для спасения от Великого потопа?",
            questionEn: "Who built the ark to survive the Great Flood?",
            optionsHy: ["Աբրահամը", "Մովսեսը", "Նոյը", "Դավիթը"],
            optionsRu: ["Авраам", "Моисей", "Ной", "Давид"],
            optionsEn: ["Abraham", "Moses", "Noah", "David"],
            correctAnswerIndex: 2,
            explanationHy: "Աստված պատվիրեց Նոյին տապան շինել, որպեսզի նա և իր ընտանիքը փրկվեն ջրհեղեղից։",
            explanationRu: "Бог повелел Ною построить ковчег, чтобы спасти свою семью и животных от потопа.",
            explanationEn: "God commanded Noah to build an ark to save his family and animals from the flood.",
            verseRefHy: "Ծննդոց 6:14",
            verseRefRu: "Бытие 6:14",
            verseRefEn: "Genesis 6:14"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .easy,
            questionHy: "Ո՞ր լեռան վրա կանգ առավ Նոյան Տապանը ջրհեղեղից հետո։",
            questionRu: "На каких горах остановился Ноев Ковчег после потопа?",
            questionEn: "Upon which mountains did Noah's Ark come to rest after the flood?",
            optionsHy: ["Սինա", "Արարատ", "Ձիթենյաց", "Թաբոր"],
            optionsRu: ["Синай", "Арарат", "Елеонская", "Фавор"],
            optionsEn: ["Sinai", "Ararat", "Mount Olivet", "Tabor"],
            correctAnswerIndex: 1,
            explanationHy: "Տապանը կանգ առավ Արարատի լեռների վրա (Ծննդոց 8:4)։",
            explanationRu: "Ковчег остановился на горах Араратских (Бытие 8:4).",
            explanationEn: "The ark came to rest upon the mountains of Ararat (Genesis 8:4).",
            verseRefHy: "Ծննդոց 8:4",
            verseRefRu: "Бытие 8:4",
            verseRefEn: "Genesis 8:4"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .easy,
            questionHy: "Ո՞վ սպանեց Գողիաթին պարսատիկով և քարով։",
            questionRu: "Кто победил великана Голиафа с помощью пращи и камня?",
            questionEn: "Who defeated the giant Goliath using a sling and a stone?",
            optionsHy: ["Սավուղը", "Սողոմոնը", "Դավիթը", "Սամսոնը"],
            optionsRu: ["Саул", "Соломон", "Давид", "Самсон"],
            optionsEn: ["Saul", "Solomon", "David", "Samson"],
            correctAnswerIndex: 2,
            explanationHy: "Երիտասարդ Դավիթը հավատով ելավ փղշտացի Գողիաթի դեմ և հաղթեց նրան Տիրոջ անունով։",
            explanationRu: "Молодой Давид выступил с верою против филистимлянина Голиафа и победил во имя Господа.",
            explanationEn: "Young David confronted Goliath in faith and defeated him in the name of the Lord.",
            verseRefHy: "Ա Թագավորաց 17:50",
            verseRefRu: "1 Царств 17:50",
            verseRefEn: "1 Samuel 17:50"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .easy,
            questionHy: "Ո՞վ ստացավ 10 Պատվիրանները Սինա լեռան վրա։",
            questionRu: "Кто получил 10 Заповедей на горе Синай?",
            questionEn: "Who received the 10 Commandments on Mount Sinai?",
            optionsHy: ["Աբրահամը", "Մովսեսը", "Հեսուն", "Ահարոնը"],
            optionsRu: ["Авраам", "Моисей", "Иисус Навин", "Аарон"],
            optionsEn: ["Abraham", "Moses", "Joshua", "Aaron"],
            correctAnswerIndex: 1,
            explanationHy: "Մովսեսը բարձրացավ Սինա լեռը և ստացավ տասը պատվիրանները Աստծո մատով գրված։",
            explanationRu: "Моисей взошел на Синай и принял скрижали с десятью заповедями от Бога.",
            explanationEn: "Moses ascended Mount Sinai and received the ten commandments inscribed by the finger of God.",
            verseRefHy: "Ելք 20:1-17",
            verseRefRu: "Исход 20:1-17",
            verseRefEn: "Exodus 20:1-17"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .easy,
            questionHy: "Ո՞վ էր Աստվածաշնչում ամենաիմաստուն թագավորը։",
            questionRu: "Кто был самым мудрым царем в Библии?",
            questionEn: "Who was the wisest king in the Bible?",
            optionsHy: ["Սավուղը", "Դավիթը", "Սողոմոնը", "Եզեկիան"],
            optionsRu: ["Саул", "Давид", "Соломон", "Езекия"],
            optionsEn: ["Saul", "David", "Solomon", "Hezekiah"],
            correctAnswerIndex: 2,
            explanationHy: "Աստված Սողոմոնին տվեց անգերազանցելի իմաստություն և հանճարեղ միտք։",
            explanationRu: "Бог даровал Соломону сердце мудрое и разумное, равного которому не было.",
            explanationEn: "God gave Solomon a wise and discerning heart greater than anyone before or after.",
            verseRefHy: "Գ Թագավորաց 3:12",
            verseRefRu: "3 Царств 3:12",
            verseRefEn: "1 Kings 3:12"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ո՞ւմ վաճառեցին իր եղբայրները Եգիպտոսի ստրկության։",
            questionRu: "Кого братья продали в рабство в Египет?",
            questionEn: "Whom did his brothers sell into slavery in Egypt?",
            optionsHy: ["Բենիամինին", "Հովսեփին", "Հուդային", "Ռուբենին"],
            optionsRu: ["Вениамина", "Иосифа", "Иуду", "Рувима"],
            optionsEn: ["Benjamin", "Joseph", "Judah", "Reuben"],
            correctAnswerIndex: 1,
            explanationHy: "Հովսեփի եղբայրները նախանձից վաճառեցին նրան իսմայելացիներին 20 արծաթով։",
            explanationRu: "Братья Иосифа из зависти продали его каравану купцов за 20 серебреников.",
            explanationEn: "Joseph's brothers sold him out of jealousy to Midianite merchants for 20 pieces of silver.",
            verseRefHy: "Ծննդոց 37:28",
            verseRefRu: "Бытие 37:28",
            verseRefEn: "Genesis 37:28"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ո՞ր մարգարեին կուլ տվեց մեծ կետ-ձուկը 3 օր ու 3 գիշեր։",
            questionRu: "Какого пророка поглотила большая рыба на три дня и три ночи?",
            questionEn: "Which prophet was swallowed by a great fish for 3 days and 3 nights?",
            optionsHy: ["Եսայի", "Հովնան", "Երեմիա", "Դանիել"],
            optionsRu: ["Исаия", "Иона", "Иеремия", "Даниил"],
            optionsEn: ["Isaiah", "Jonah", "Jeremiah", "Daniel"],
            correctAnswerIndex: 1,
            explanationHy: "Հովնանը փորձեց փախչել Նինվեից, բայց փոթորկից հետո հայտնվեց կետի փորում։",
            explanationRu: "Пророк Иона пытался уклониться от проповеди в Ниневии и провел три дня во чреве кита.",
            explanationEn: "Prophet Jonah fled from the Lord's calling to Nineveh and spent three days inside the fish.",
            verseRefHy: "Հովնան 2:1",
            verseRefRu: "Иона 2:1",
            verseRefEn: "Jonah 1:17"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ո՞ր մարգարեին նետեցին առյուծների գուբը, բայց Աստված փակեց առյուծների բերանը։",
            questionRu: "Какого пророка бросили в ров ко львам, но Бог заградил пасть зверям?",
            questionEn: "Which prophet was thrown into the lions' den, but God shut the lions' mouths?",
            optionsHy: ["Եզեկիել", "Դանիել", "Ամովս", "Միքիա"],
            optionsRu: ["Иезекииль", "Даниил", "Амос", "Михей"],
            optionsEn: ["Ezekiel", "Daniel", "Amos", "Micah"],
            correctAnswerIndex: 1,
            explanationHy: "Դանիել մարգարեն հավատարիմ մնաց Աղոթքին և անվնաս մնաց առյուծների գբում։",
            explanationRu: "Даниил не перестал молиться истинному Богу и был спасен ангелом от львов.",
            explanationEn: "Daniel remained faithful in prayer and God sent His angel to shut the lions' mouths.",
            verseRefHy: "Դանիել 6:22",
            verseRefRu: "Даниил 6:22",
            verseRefEn: "Daniel 6:22"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ո՞վ էր Իսրայելի առաջին թագավորը։",
            questionRu: "Кто был первым царем Израиля?",
            questionEn: "Who was the first king of Israel?",
            optionsHy: ["Դավիթը", "Սողոմոնը", "Սավուղը", "Հերովդեսը"],
            optionsRu: ["Давид", "Соломон", "Саул", "Ирод"],
            optionsEn: ["David", "Solomon", "Saul", "Herod"],
            correctAnswerIndex: 2,
            explanationHy: "Սամուել մարգարեն օծեց Սավուղին որպես Իսրայելի առաջին թագավոր։",
            explanationRu: "Пророк Самуил по повелению Бога помазал Саула первым царем Израиля.",
            explanationEn: "Prophet Samuel anointed Saul as the first king over Israel.",
            verseRefHy: "Ա Թագավորաց 10:1",
            verseRefRu: "1 Царств 10:1",
            verseRefEn: "1 Samuel 10:1"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .hard,
            questionHy: "Քանի՞ գլուխ ունի Սաղմոսների գիրքը։",
            questionRu: "Сколько глав (псалмов) содержит Книга Псалтирь?",
            questionEn: "How many chapters (psalms) does the Book of Psalms contain?",
            optionsHy: ["100", "120", "150", "180"],
            optionsRu: ["100", "120", "150", "180"],
            optionsEn: ["100", "120", "150", "180"],
            correctAnswerIndex: 2,
            explanationHy: "Սաղմոսարանը բաղկացած է 150 սաղմոսներից (կանոնական հաշվարկով)։",
            explanationRu: "Псалтирь содержит 150 вдохновенных молитвенных псалмов.",
            explanationEn: "The canonical Book of Psalms consists of 150 psalms.",
            verseRefHy: "Սաղմոսներ 150:6",
            verseRefRu: "Псалтирь 150:6",
            verseRefEn: "Psalm 150:6"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .hard,
            questionHy: "Ո՞ր մարգարեն հրեղեն կառքով երկինք համբարձվեց։",
            questionRu: "Какой пророк был вознесен на небо в огненной колеснице?",
            questionEn: "Which prophet was taken up to heaven in a chariot of fire?",
            optionsHy: ["Եղիսե", "Եղիա", "Եսայի", "Եզեկիել"],
            optionsRu: ["Елисей", "Илия", "Исаия", "Иезекииль"],
            optionsEn: ["Elisha", "Elijah", "Isaiah", "Ezekiel"],
            correctAnswerIndex: 1,
            explanationHy: "Եղիա մարգարեն հրեղեն կառքով և մրրիկով տարվեց երկինք։",
            explanationRu: "Пророк Илия был взят на небо в огненной колеснице с огненными конями в вихре.",
            explanationEn: "Prophet Elijah ascended into heaven in a chariot of fire with horses of fire.",
            verseRefHy: "Դ Թագավորաց 2:11",
            verseRefRu: "4 Царств 2:11",
            verseRefEn: "2 Kings 2:11"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ո՞ր ծովը բաժանեց Մովսեսը Տիրոջ զորությամբ, որպեսզի ժողովուրդն անցնի։",
            questionRu: "Какое море расступилось по слову Моисея и силе Божьей для исхода народа?",
            questionEn: "Which sea parted through Moses by God's power for the Israelites to cross?",
            optionsHy: ["Մեռյալ ծովը", "Կարմիր ծովը", "Միջերկրական ծովը", "Գալիլեայի ծովը"],
            optionsRu: ["Мертвое море", "Красное (Чермное) море", "Средиземное море", "Галилейское море"],
            optionsEn: ["Dead Sea", "Red Sea", "Mediterranean Sea", "Sea of Galilee"],
            correctAnswerIndex: 1,
            explanationHy: "Կարմիր ծովի ջրերը բաժանվեցին, և Իսրայելի որդիներն անցան ցամաքով։",
            explanationRu: "Воды Чермного (Красного) моря расступились стеною, и народ прошел посуху.",
            explanationEn: "The waters of the Red Sea divided and the Israelites crossed on dry ground.",
            verseRefHy: "Ելք 14:21-22",
            verseRefRu: "Исход 14:21-22",
            verseRefEn: "Exodus 14:21-22"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .hard,
            questionHy: "Ո՞վ էր Աբրահամի խոստացված որդին, որին նա պատրաստ էր զոհաբերել Մորիա լեռան վրա։",
            questionRu: "Кто был обетованным сыном Авраама, которого он готов был принести в жертву на горе Мориа?",
            questionEn: "Who was Abraham's son of promise whom he was willing to sacrifice on Mount Moriah?",
            optionsHy: ["Իսմայելը", "Իսահակը", "Հակոբը", "Եսավը"],
            optionsRu: ["Измаил", "Исаак", "Иаков", "Исав"],
            optionsEn: ["Ishmael", "Isaac", "Jacob", "Esau"],
            correctAnswerIndex: 1,
            explanationHy: "Աստված փորձեց Աբրահամի հավատը Իսահակի միջոցով և տեղը խոյ տրամադրեց։",
            explanationRu: "Авраам явил абсолютную веру в послушании принести Исаака, но Бог предоставил овна.",
            explanationEn: "God tested Abraham's faith regarding Isaac and provided a ram caught in the thicket.",
            verseRefHy: "Ծննդոց 22:9-13",
            verseRefRu: "Бытие 22:9-13",
            verseRefEn: "Genesis 22:9-13"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ի՞նչ սնունդ էր իջնում երկնքից 40 տարի անապատում Իսրայելի համար։",
            questionRu: "Какая пища сходила с неба для насыщения народа Израиля в пустыне?",
            questionEn: "What bread rained from heaven to sustain the Israelites in the desert?",
            optionsHy: ["Մանանա", "Նուռ", "Խուրմա", "Գարի"],
            optionsRu: ["Манна", "Гранат", "Финики", "Ячмень"],
            optionsEn: ["Manna", "Pomegranate", "Dates", "Barley"],
            correctAnswerIndex: 0,
            explanationHy: "Աստված երկնքից տալիս էր մանանա՝ «հրեշտակների հացը»։",
            explanationRu: "Каждое утро Бог посылал с небес манну для пропитания народа.",
            explanationEn: "God rained down manna every morning to feed the people in the wilderness.",
            verseRefHy: "Ելք 16:15",
            verseRefRu: "Исход 16:15",
            verseRefEn: "Exodus 16:15"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .hard,
            questionHy: "Ո՞վ էր այն քաջ կինը, որը փրկեց իր ողջ հրեա ժողովրդին Համանի դավադրությունից։",
            questionRu: "Какая благочестивая царица спасла свой еврейский народ от истребления Аманом?",
            questionEn: "Which brave queen saved her people from Haman's plot of extermination?",
            optionsHy: ["Հռութը", "Եսթերը", "Դեբորան", "Աննան"],
            optionsRu: ["Руфь", "Есфирь", "Девора", "Анна"],
            optionsEn: ["Ruth", "Esther", "Deborah", "Hannah"],
            correctAnswerIndex: 1,
            explanationHy: "Եսթեր թագուհին ծոմապահությամբ և քաջությամբ կանգնեց թագավորի առաջ և փրկեց ժողովրդին։",
            explanationRu: "Царица Есфирь с постом и молитвой обратилась к царю и спасла соплеменников.",
            explanationEn: "Queen Esther risked her life, fasting and petitioning the king to save her people.",
            verseRefHy: "Եսթեր 4:16",
            verseRefRu: "Есфирь 4:16",
            verseRefEn: "Esther 4:16"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .hard,
            questionHy: "Ո՞վ էր աստվածաշնչյան այն արդար մարդը, որը համբերությամբ կրեց բոլոր փորձությունները և չմեղանչեց։",
            questionRu: "Какой праведник стойко перенес тяжелейшие испытания и потери, оставшись верным Богу?",
            questionEn: "Which righteous man endured immense suffering and loss while remaining faithful to God?",
            optionsHy: ["Հոբը", "Նոյը", "Ենոքը", "Լովտը"],
            optionsRu: ["Иов", "Ной", "Енох", "Лот"],
            optionsEn: ["Job", "Noah", "Enoch", "Lot"],
            correctAnswerIndex: 0,
            explanationHy: "Հոբ Երանելին փորձությունների մեջ ասաց. «Տերը տվեց, Տերն էլ առավ, օրհնյալ լինի Տիրոջ անունը»։",
            explanationRu: "Многострадальный Иов сохранил верность: «Господь дал, Господь и взял; да будет имя Господне благословенно!»",
            explanationEn: "Righteous Job persevered: «The Lord gave, and the Lord has taken away; blessed be the name of the Lord.»",
            verseRefHy: "Հոբ 1:21",
            verseRefRu: "Иов 1:21",
            verseRefEn: "Job 1:21"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ի՞նչ ազդանշան տվեց Աստված Նոյին որպես ուխտ, որ այլևս համաշխարհային ջրհեղեղ չի լինի։",
            questionRu: "Что Бог поставил на небе в знак вечного завета, что воды потопа больше не истребят землю?",
            questionEn: "What sign did God place in the sky as a covenant that waters would never again flood the earth?",
            optionsHy: ["Ծիածան", "Բևեռափայլ", "Արշալույս", "Գիսաստղ"],
            optionsRu: ["Радугу", "Северное сияние", "Утреннюю зарю", "Комету"],
            optionsEn: ["Rainbow", "Aurora", "Morning dawn", "Comet"],
            correctAnswerIndex: 0,
            explanationHy: "«Իմ ծիածանը դրի ամպերի մեջ, որպեսզի լինի ուխտի նշան Իմ և երկրի միջև»։",
            explanationRu: "«Я полагаю радугу Мою в облаке, чтоб она была знамением завета между Мною и между землею».",
            explanationEn: "«I set My rainbow in the cloud, and it shall be for the sign of the covenant between Me and the earth.»",
            verseRefHy: "Ծննդոց 9:13",
            verseRefRu: "Бытие 9:13",
            verseRefEn: "Genesis 9:13"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ո՞վ ունեցավ երազում աստիճան, որը հասնում էր երկինք, և հրեշտակները բարձրանում ու իջնում էին։",
            questionRu: "Кто увидел во сне лестницу до небес, по которой восходили и нисходили ангелы Божьи?",
            questionEn: "Who dreamed of a ladder reaching to heaven with angels ascending and descending on it?",
            optionsHy: ["Հակոբը", "Իսահակը", "Աբրահամը", "Հովսեփը"],
            optionsRu: ["Иаков", "Исаак", "Авраам", "Иосиф"],
            optionsEn: ["Jacob", "Isaac", "Abraham", "Joseph"],
            correctAnswerIndex: 0,
            explanationHy: "Հակոբը Բեթելում տեսավ երկնային սանդուղքը և ստացավ Աստծո օրհնությունը։",
            explanationRu: "Иаков в Вефиле увидел небесную лестницу («Лествицу Иакова») и дал обет Богу.",
            explanationEn: "Jacob saw the stairway to heaven at Bethel and received God's blessing.",
            verseRefHy: "Ծննդոց 28:12",
            verseRefRu: "Бытие 28:12",
            verseRefEn: "Genesis 28:12"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .hard,
            questionHy: "Ի՞նչ էր այն հրաշալի բույսը, որի միջից Աստված կանչեց Մովսեսին Հորեբ լեռան վրա։",
            questionRu: "Из какого горящего, но несгорающего куста Бог воззвал к Моисею на горе Хорив?",
            questionEn: "From what burning bush that was not consumed did God call Moses on Mount Horeb?",
            optionsHy: ["Անկեզ Մորենի", "Ձիթենի", "Արմավենի", "Մայրի"],
            optionsRu: ["Неопалимая Купина (терновый куст)", "Маслина", "Пальма", "Кедр"],
            optionsEn: ["Burning Bush (Thornbush)", "Olive tree", "Palm tree", "Cedar"],
            correctAnswerIndex: 0,
            explanationHy: "Մորենին վառվում էր կրակով, բայց չէր այրվում (Ելք 3:2)։",
            explanationRu: "Терновый куст горел огнем, но не сгорал — прообраз Богоматери и Божественной святости.",
            explanationEn: "The bush was on fire but did not burn up (Exodus 3:2).",
            verseRefHy: "Ելք 3:2",
            verseRefRu: "Исход 3:2",
            verseRefEn: "Exodus 3:2"
        ),

        // =========================================================================
        // MARK: - 2. ЕВАНГЕЛИЯ (GOSPELS)
        // =========================================================================
        QuizQuestion(
            category: .gospels,
            difficulty: .easy,
            questionHy: "Ո՞ր քաղաքում ծնվեց Հիսուս Քրիստոս։",
            questionRu: "В каком городе родился Иисус Христос?",
            questionEn: "In which city was Jesus Christ born?",
            optionsHy: ["Նազարեթ", "Երուսաղեմ", "Բեթղեհեմ", "Կափառնաում"],
            optionsRu: ["Назарет", "Иерусалим", "Вифлеем", "Капернаум"],
            optionsEn: ["Nazareth", "Jerusalem", "Bethlehem", "Capernaum"],
            correctAnswerIndex: 2,
            explanationHy: "Հիսուս ծնվեց Հուդայի Բեթղեհեմ քաղաքում, ինչպես մարգարեացվել էր Միքիա մարգարեի կողմից։",
            explanationRu: "Иисус родился в Вифлееме Иудейском, во исполнение древнего пророчества Михея.",
            explanationEn: "Jesus was born in Bethlehem of Judea, fulfilling the prophecy of Micah.",
            verseRefHy: "Մատթեոս 2:1",
            verseRefRu: "Матфея 2:1",
            verseRefEn: "Matthew 2:1"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .easy,
            questionHy: "Ո՞ր գետում մկրտվեց Հիսուս Քրիստոս Հովհաննես Մկրտչի կողմից։",
            questionRu: "В какой реке крестился Иисус Христос от Иоанна Крестителя?",
            questionEn: "In which river was Jesus baptized by John the Baptist?",
            optionsHy: ["Եփրատ", "Տիգրիս", "Հորդանան", "Նեղոս"],
            optionsRu: ["Евфрат", "Тигр", "Иордан", "Нил"],
            optionsEn: ["Euphrates", "Tigris", "Jordan", "Nile"],
            correctAnswerIndex: 2,
            explanationHy: "Հիսուս մկրտվեց Հորդանան գետում, և Սուրբ Հոգին աղավնակերպ իջավ Նրա վրա։",
            explanationRu: "Иисус принял крещение в реке Иордан, и Дух Святой сошел на Него в виде голубя.",
            explanationEn: "Jesus was baptized in the Jordan River, and the Holy Spirit descended like a dove upon Him.",
            verseRefHy: "Մատթեոս 3:13-16",
            verseRefRu: "Матфея 3:13-16",
            verseRefEn: "Matthew 3:13-16"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .easy,
            questionHy: "Քանի՞ առաքյալ ընտրեց Հիսուսը։",
            questionRu: "Сколько ближайших апостолов избрал Иисус?",
            questionEn: "How many primary apostles did Jesus choose?",
            optionsHy: ["7", "10", "12", "70"],
            optionsRu: ["7", "10", "12", "70"],
            optionsEn: ["7", "10", "12", "70"],
            correctAnswerIndex: 2,
            explanationHy: "Հիսուս ընտրեց տասներկու աշակերտների, որոնց նաև առաքյալներ անվանեց։",
            explanationRu: "Иисус призвал двенадцать учеников, которых нарек Апостолами.",
            explanationEn: "Jesus called His twelve disciples, whom He also named apostles.",
            verseRefHy: "Ղուկաս 6:13",
            verseRefRu: "Луки 6:13",
            verseRefEn: "Luke 6:13"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ո՞րն էր Հիսուսի կատարած առաջին հրաշքը։",
            questionRu: "Какое первое чудо совершил Иисус Христос?",
            questionEn: "What was the first miracle performed by Jesus?",
            optionsHy: ["Կույրի բժշկումը", "Ջուրը գինի դարձնելը Կանայում", "Հացերի բազմացումը", "Ղազարոսի հարությունը"],
            optionsRu: ["Исцеление слепого", "Претворение воды в вино в Кане", "Умножение хлебов", "Воскрешение Лазаря"],
            optionsEn: ["Healing the blind man", "Turning water into wine at Cana", "Multiplying loaves", "Raising of Lazarus"],
            correctAnswerIndex: 1,
            explanationHy: "Գալիլեայի Կանա քաղաքի հարսանիքում Հիսուսը ջուրը փոխակերպեց ընտիր գինու։",
            explanationRu: "На брачном пире в Кане Галилейской Иисус претворил воду в превосходное вино.",
            explanationEn: "At the wedding in Cana of Galilee, Jesus turned water into fine wine.",
            verseRefHy: "Հովհաննես 2:11",
            verseRefRu: "Иоанна 2:11",
            verseRefEn: "John 2:11"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .easy,
            questionHy: "Քանի՞ հացով և ձկով Հիսուսը կերակրեց 5000 մարդկանց։",
            questionRu: "Сколькими хлебами и рыбами Иисус накормил 5000 человек?",
            questionEn: "How many loaves and fish did Jesus use to feed the 5,000?",
            optionsHy: ["5 հաց և 2 ձուկ", "7 հաց և 3 ձուկ", "3 հաց և 5 ձուկ", "12 հաց և 2 ձուկ"],
            optionsRu: ["5 хлебов и 2 рыбы", "7 хлебов и 3 рыбы", "3 хлеба и 5 рыб", "12 хлебов и 2 рыбы"],
            optionsEn: ["5 loaves and 2 fish", "7 loaves and 3 fish", "3 loaves and 5 fish", "12 loaves and 2 fish"],
            correctAnswerIndex: 0,
            explanationHy: "Հիսուս օրհնեց 5 նկանակն ու 2 ձուկը, կերակրեց բազմությանը, և մնաց 12 լիքը կողով։",
            explanationRu: "Иисус благословил 5 хлебов и 2 рыбы, насытил 5000 человек и собрали 12 полных коробов.",
            explanationEn: "Jesus blessed five loaves and two fish, feeding 5,000 men with twelve baskets left over.",
            verseRefHy: "Մատթեոս 14:19-20",
            verseRefRu: "Матфея 14:19-20",
            verseRefEn: "Matthew 14:19-20"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Քանի՞ օր էր Ղազարոսը գերեզմանում, երբ Հիսուսը նրան հարություն տվեց։",
            questionRu: "Сколько дней Лазарь находился во гробе, прежде чем Иисус воскресил его?",
            questionEn: "How many days had Lazarus been in the tomb when Jesus raised him from the dead?",
            optionsHy: ["1 օր", "2 օր", "3 օր", "4 օր"],
            optionsRu: ["1 день", "2 дня", "3 дня", "4 дня"],
            optionsEn: ["1 day", "2 days", "3 days", "4 days"],
            correctAnswerIndex: 3,
            explanationHy: "Ղազարոսն արդեն չորս օրվա մեռյալ էր, երբ Հիսուսն ասաց. «Ղազարո՛ս, դո՛ւրս արի»։",
            explanationRu: "Лазарь был во гробе уже четыре дня, когда Господь воззвал: «Лазарь! иди вон».",
            explanationEn: "Lazarus had already been in the tomb four days when Jesus called: «Lazarus, come out!»",
            verseRefHy: "Հովհաննես 11:39-44",
            verseRefRu: "Иоанна 11:39-44",
            verseRefEn: "John 11:39-44"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .easy,
            questionHy: "Ո՞րն է Աստվածաշնչի ամենակարճ համարը։",
            questionRu: "Какой самый короткий стих во всей Библии?",
            questionEn: "What is the shortest verse in the entire Bible?",
            optionsHy: ["«Հիսուս լաց եղավ»", "«Աղոթեցեք»", "«Փառք Աստծո»", "«Սիրեցեք միմյանց»"],
            optionsRu: ["«Иисус прослезился»", "«Непрестанно молитесь»", "«Слава Богу»", "«Любите друг друга»"],
            optionsEn: ["«Jesus wept»", "«Pray continually»", "«Glory to God»", "«Love one another»"],
            correctAnswerIndex: 0,
            explanationHy: "«Հիսուս լաց եղավ» (Հովհաննես 11:35)՝ Ղազարոսի գերեզմանի մոտ։",
            explanationRu: "«Иисус прослезился» (Иоанна 11:35) у гробницы Своего друга Лазаря.",
            explanationEn: "«Jesus wept» (John 11:35) as He stood near the tomb of His friend Lazarus.",
            verseRefHy: "Հովհաննես 11:35",
            verseRefRu: "Иоанна 11:35",
            verseRefEn: "John 11:35"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ո՞ր առակում է հայրը գրկաբաց ընդունում զղջացող որդուն։",
            questionRu: "В какой притче отец с любовью и всепрощением принимает вернувшегося сына?",
            questionEn: "In which parable does a father embrace and forgive his returning repentant son?",
            optionsHy: ["Անառակ որդու առակը", "Բարի սամարացու առակը", "Սերմնացանի առակը", "Տասը կույսերի առակը"],
            optionsRu: ["Притча о блудном сыне", "Притча о добром самарянине", "Притча о сеятеле", "Притча о десяти девах"],
            optionsEn: ["Parable of the Prodigal Son", "Parable of the Good Samaritan", "Parable of the Sower", "Parable of the Ten Virgins"],
            correctAnswerIndex: 0,
            explanationHy: "Անառակ որդու առակը ցույց է տալիս Երկնային Հոր անսահման ողորմությունն ու սերը։",
            explanationRu: "Притча о блудном сыне являет безграничную любовь и милосердие Небесного Отца к кающимся.",
            explanationEn: "The Parable of the Prodigal Son illustrates the boundless mercy and joy of the Heavenly Father.",
            verseRefHy: "Ղուկաս 15:11-32",
            verseRefRu: "Луки 15:11-32",
            verseRefEn: "Luke 15:11-32"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ո՞վ օգնեց ավազակների ձեռքն ընկած վիրավոր մարդուն ճանապարհին։",
            questionRu: "Кто оказал милость и перевязал раны избитому разбойниками путнику?",
            questionEn: "Who showed mercy and bandaged the wounds of the man beaten by robbers?",
            optionsHy: ["Քահանան", "Ղևտացին", "Բարի Սամարացին", "Փարիսեցին"],
            optionsRu: ["Священник", "Левит", "Добрый Самарянин", "Фарисей"],
            optionsEn: ["The Priest", "The Levite", "The Good Samaritan", "The Pharisee"],
            correctAnswerIndex: 2,
            explanationHy: "Բարի Սամարացին խղճաց, բուժեց նրա վերքերը և հոգ տարավ նրա մասին իջևանատանը։",
            explanationRu: "Добрый Самарянин сжалился, перевязал раны, отвез в гостиницу и позаботился о нем.",
            explanationEn: "The Good Samaritan had compassion, bound his wounds, and provided for his recovery.",
            verseRefHy: "Ղուկաս 10:33-35",
            verseRefRu: "Луки 10:33-35",
            verseRefEn: "Luke 10:33-35"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .hard,
            questionHy: "Քանի՞ անգամ Պետրոսը ուրացավ Քրիստոսին նախքան աքաղաղի կանչելը։",
            questionRu: "Сколько раз апостол Петр отрекся от Христа, прежде чем пропел петух?",
            questionEn: "How many times did Peter deny Christ before the rooster crowed?",
            optionsHy: ["1 անգամ", "2 անգամ", "3 անգամ", "7 անգամ"],
            optionsRu: ["1 раз", "2 раза", "3 раза", "7 раз"],
            optionsEn: ["1 time", "2 times", "3 times", "7 times"],
            correctAnswerIndex: 2,
            explanationHy: "Պետրոսը երեք անգամ ասաց, որ չի ճանաչում Հիսուսին, ապա դառնորեն լաց եղավ։",
            explanationRu: "Петр трижды отрекся от Учителя, после чего вспомнил предсказание Христа и горько плакал.",
            explanationEn: "Peter denied knowing Jesus three times, and then went out and wept bitterly.",
            verseRefHy: "Մատթեոս 26:75",
            verseRefRu: "Матфея 26:75",
            verseRefEn: "Matthew 26:75"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ո՞վ մատնեց Հիսուսին 30 արծաթով։",
            questionRu: "Кто предал Иисуса первосвященникам за 30 серебреников?",
            questionEn: "Who betrayed Jesus to the chief priests for 30 pieces of silver?",
            optionsHy: ["Հուդա Իսկարիովտացին", "Թովմասը", "Պիղատոսը", "Կայիափան"],
            optionsRu: ["Иуда Искариот", "Фома", "Понтий Пилат", "Каиафа"],
            optionsEn: ["Judas Iscariot", "Thomas", "Pontius Pilate", "Caiaphas"],
            correctAnswerIndex: 0,
            explanationHy: "Հուդա Իսկարիովտացին համբույրով մատնեց Ուսուցչին Գեթսեմանիի պարտեզում։",
            explanationRu: "Иуда Искариот предал Спасителя за 30 монет, указав на Него лицемерным целованием.",
            explanationEn: "Judas Iscariot betrayed the Lord for 30 silver coins with a kiss in Gethsemane.",
            verseRefHy: "Մատթեոս 26:14-15",
            verseRefRu: "Матфея 26:14-15",
            verseRefEn: "Matthew 26:14-15"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .hard,
            questionHy: "Ի՞նչ էր գրված Հիսուսի Խաչի վերնագրի տախտակին (ՏԻՏԼՈՍ)։",
            questionRu: "Какая надпись была начертана на дощечке над распятым Иисусом?",
            questionEn: "What inscription was placed on the placard above Jesus on the Cross?",
            optionsHy: ["«Հիսուս Նազովրեցի՝ Հրեաների Թագավոր»", "«Մարգարե Նազարեթից»", "«Աշխարհի Փրկիչ»", "«Որդի Դավթի»"],
            optionsRu: ["«Иисус Назорей, Царь Иудейский»", "«Пророк из Назарета»", "«Спаситель мира»", "«Сын Давидов»"],
            optionsEn: ["«Jesus of Nazareth, King of the Jews»", "«Prophet from Nazareth»", "«Savior of the World»", "«Son of David»"],
            correctAnswerIndex: 0,
            explanationHy: "Պիղատոսը գրեց եբրայերեն, հունարեն և լատիներեն՝ «Հիսուս Նազովրեցի՝ Թագավոր Հրեից» (INRI)։",
            explanationRu: "Пилат сделал надпись на трех языках: «Иисус Назорей, Царь Иудейский» (INRI).",
            explanationEn: "Pilate wrote the title in Hebrew, Greek, and Latin: «Jesus of Nazareth, King of the Jews».",
            verseRefHy: "Հովհաննես 19:19",
            verseRefRu: "Иоанна 19:19",
            verseRefEn: "John 19:19"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ո՞վ էր առաջինը, որ գնաց Հիսուսի գերեզմանը հարության առավոտյան և տեսավ հարուցյալ Տիրոջը։",
            questionRu: "Кто первым пришел ко гробу воскресшего Спасителя ранним утром?",
            questionEn: "Who was the first to arrive at Jesus' tomb on resurrection morning and see the risen Lord?",
            optionsHy: ["Մարիամ Մագդաղենացին", "Մարթան", "Սալոմեն", "Մարիամ Կղեոպասը"],
            optionsRu: ["Мария Магдалина", "Марфа", "Саломия", "Мария Клеопова"],
            optionsEn: ["Mary Magdalene", "Martha", "Salome", "Mary of Clopas"],
            correctAnswerIndex: 0,
            explanationHy: "Մարիամ Մագդաղենացին տեսավ դատարկ գերեզմանը և հարուցյալ Քրիստոսին։",
            explanationRu: "Мария Магдалина первой увидела отваленный камень и воскресшего Христа.",
            explanationEn: "Mary Magdalene came early to the tomb and was the first to see the risen Christ.",
            verseRefHy: "Հովհաննես 20:1-16",
            verseRefRu: "Иоанна 20:1-16",
            verseRefEn: "John 20:1-16"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .hard,
            questionHy: "Ո՞ր առաքյալը չհավատաց Քրիստոսի հարությանը, մինչև չտեսավ գամերի հետքերը Նրա ձեռքերին։",
            questionRu: "Какой апостол усомнился в воскресении Христа, пока лично не увидел раны от гвоздей?",
            questionEn: "Which apostle doubted Jesus' resurrection until he saw the nail marks in His hands?",
            optionsHy: ["Թովմասը", "Անդրեասը", "Փիլիպպոսը", "Բարդուղիմեոսը"],
            optionsRu: ["Фома", "Андрей", "Филипп", "Варфоломей"],
            optionsEn: ["Thomas", "Andrew", "Philip", "Bartholomew"],
            correctAnswerIndex: 0,
            explanationHy: "Թովմասն ասաց. «Տեր իմ և Աստված իմ», երբ տեսավ Հիսուսի խոցված կողն ու ձեռքերը։",
            explanationRu: "Фома воскликнул: «Господь мой и Бог мой!», увидев раны воскресшего Христа.",
            explanationEn: "Thomas confessed: «My Lord and my God!» after seeing Jesus' wounds.",
            verseRefHy: "Հովհաննես 20:27-28",
            verseRefRu: "Иоанна 20:27-28",
            verseRefEn: "John 20:27-28"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ի՞նչ աղոթք սովորեցրեց Հիսուսը Իր աշակերտներին Լեռան Քարոզում։",
            questionRu: "Какую молитву преподал Иисус Своим ученикам в Нагорной проповеди?",
            questionEn: "Which prayer did Jesus teach His disciples in the Sermon on the Mount?",
            optionsHy: ["«Հայր Մեր» (Տերունական աղոթք)", "«Սուրբ Աստված»", "«Հավատամք»", "«Փառք ի բարձունս»"],
            optionsRu: ["«Отче наш» (Молитва Господня)", "«Трисвятое»", "«Символ Веры»", "«Великое славословие»"],
            optionsEn: ["«The Lord's Prayer» (Our Father)", "«Trisagion»", "«Nicene Creed»", "«Gloria in Excelsis»"],
            correctAnswerIndex: 0,
            explanationHy: "Հիսուս ուսուցանեց Տերունական աղոթքը՝ «Հա՛յր մեր, որ երկնքում ես...»։",
            explanationRu: "Христос заповедал Молитву Господню: «Отче наш, сущий на небесах...».",
            explanationEn: "Jesus gave the model prayer: «Our Father in heaven, hallowed be Your name...».",
            verseRefHy: "Մատթեոս 6:9-13",
            verseRefRu: "Матфея 6:9-13",
            verseRefEn: "Matthew 6:9-13"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .hard,
            questionHy: "Ո՞ր հինկտակարանյան մարգարեները հայտնվեցին Հիսուսի Պայծառակերպության (Թաբոր լեռան) ժամանակ։",
            questionRu: "Какие ветхозаветные пророки явились во славе во время Преображения Господня на Фаворе?",
            questionEn: "Which Old Testament prophets appeared in glory during the Transfiguration of Jesus?",
            optionsHy: ["Մովսեսը և Եղիան", "Աբրահամը և Դավիթը", "Եսային և Երեմիան", "Նոյը և Դանիելը"],
            optionsRu: ["Моисей и Илия", "Авраам и Давид", "Исаия и Иеремия", "Ной и Даниил"],
            optionsEn: ["Moses and Elijah", "Abraham and David", "Isaiah and Jeremiah", "Noah and Daniel"],
            correctAnswerIndex: 0,
            explanationHy: "Մովսեսը (օրենքի խորհրդանիշ) և Եղիան (մարգարեների խորհրդանիշ) զրուցում էին Հիսուսի հետ։",
            explanationRu: "Моисей (представитель Закона) и Илия (представитель Пророков) беседовали с преобразившимся Спасителем.",
            explanationEn: "Moses and Elijah appeared in glory, talking with Jesus about His departure.",
            verseRefHy: "Մատթեոս 17:3",
            verseRefRu: "Матфея 17:3",
            verseRefEn: "Matthew 17:3"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ի՞նչ նվերներ բերեցին արևելքից եկած մոգերը մանուկ Հիսուսին։",
            questionRu: "Какие три дара принесли восточные волхвы-мудрецы родившемуся Богомладенцу?",
            questionEn: "What three gifts did the Magi bring to the infant Jesus?",
            optionsHy: ["Ոսկի, կնդրուկ և զմուռս", "Արծաթ, գինի և ձեթ", "Մետաքս, ադամանդ և հաց", "Մեղր, նուռ և խունկ"],
            optionsRu: ["Золото, ладан и смирну", "Серебро, вино и елей", "Шелк, драгоценности и хлеб", "Мед, гранат и фимиам"],
            optionsEn: ["Gold, frankincense, and myrrh", "Silver, wine, and oil", "Silk, jewels, and bread", "Honey, pomegranates, and incense"],
            correctAnswerIndex: 0,
            explanationHy: "Ոսկի՝ որպես Թագավորի, կնդրուկ (խունկ)՝ որպես Աստծո, և զմուռս՝ որպես մահկանացու Փրկչի։",
            explanationRu: "Золото как Царю, ладан как Богу, и смирну как Спасителю, грядущему на искупительную смерть.",
            explanationEn: "Gold as to a King, frankincense as to God, and myrrh for His burial.",
            verseRefHy: "Մատթեոս 2:11",
            verseRefRu: "Матфея 2:11",
            verseRefEn: "Matthew 2:11"
        ),

        // =========================================================================
        // MARK: - 3. НОВЫЙ ЗАВЕТ И АПОСТОЛЫ (NEW TESTAMENT)
        // =========================================================================
        QuizQuestion(
            category: .newTestament,
            difficulty: .easy,
            questionHy: "Ո՞վ էր Պողոս առաքյալը նախքան Քրիստոնեություն ընդունելը։",
            questionRu: "Кем был апостол Павел до своего обращения ко Христу?",
            questionEn: "Who was the Apostle Paul before his conversion to Christ?",
            optionsHy: ["Ձկնորս", "Սավուղ (հալածող)", "Մաքսավոր", "Քահանայապետ"],
            optionsRu: ["Рыбак", "Савл (гонитель христиан)", "Мытарь", "Первосвященник"],
            optionsEn: ["Fisherman", "Saul (persecutor of Christians)", "Tax collector", "High Priest"],
            correctAnswerIndex: 1,
            explanationHy: "Սավուղը հալածում էր եկեղեցին, մինչև Դամասկոսի ճանապարհին հանդիպեց Տեր Հիսուսին։",
            explanationRu: "Савл яростно преследовал христиан, пока на пути в Дамаск не встретил явившегося Христа.",
            explanationEn: "Saul persecuted the early Church until the risen Lord appeared to him on the Damascus road.",
            verseRefHy: "Գործք 9:3-5",
            verseRefRu: "Деяния 9:3-5",
            verseRefEn: "Acts 9:3-5"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .easy,
            questionHy: "Ո՞ր քաղաքում Քրիստոսի հետևորդները առաջին անգամ կոչվեցին «Քրիստոնյաներ»։",
            questionRu: "В каком городе ученики Христа впервые стали называться «Христианами»?",
            questionEn: "In which city were the disciples first called «Christians»?",
            optionsHy: ["Երուսաղեմ", "Անտիոք", "Հռոմ", "Կորնթոս"],
            optionsRu: ["Иерусалим", "Антиохия", "Рим", "Коринф"],
            optionsEn: ["Jerusalem", "Antioch", "Rome", "Corinth"],
            correctAnswerIndex: 1,
            explanationHy: "Անտիոքում աշակերտները առաջին անգամ կոչվեցին Քրիստոնյաներ (Գործք 11:26)։",
            explanationRu: "В сирийской Антиохии верующие впервые получили имя «христиане».",
            explanationEn: "It was in Antioch that the disciples were first called Christians.",
            verseRefHy: "Գործք 11:26",
            verseRefRu: "Деяния 11:26",
            verseRefEn: "Acts 11:26"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Ո՞վ էր Առաջին Քրիստոնյա Նահատակը (Նախասարկավագը)։",
            questionRu: "Кто был первым христианским мучеником (первомучеником и архидиаконом)?",
            questionEn: "Who was the first Christian martyr (protomartyr and archdeacon)?",
            optionsHy: ["Սուրբ Ստեփանոսը", "Սուրբ Պետրոսը", "Սուրբ Հակոբոսը", "Սուրբ Պողոսը"],
            optionsRu: ["Святой Стефан", "Святой Пётр", "Святой Иаков", "Святой Павел"],
            optionsEn: ["Saint Stephen", "Saint Peter", "Saint James", "Saint Paul"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Ստեփանոս Նախավկան քարկոծվեց Քրիստոսի վկայության համար՝ ներելով իրեն քարկոծողներին։",
            explanationRu: "Святой Стефан был побит камнями за исповедание веры, молясь: «Господи! не вмени им греха сего».",
            explanationEn: "Saint Stephen was stoned for witnessing to Christ, praying for his executioners.",
            verseRefHy: "Գործք 7:59-60",
            verseRefRu: "Деяния 7:59-60",
            verseRefEn: "Acts 7:59-60"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .easy,
            questionHy: "Ի՞նչ հրաշալի իրադարձություն տեղի ունեցավ Պենտեկոստեի (Հոգեգալուստի) օրը։",
            questionRu: "Какое великое событие произошло в день Пятидесятницы?",
            questionEn: "What miraculous event took place on the Day of Pentecost?",
            optionsHy: ["Սուրբ Հոգու Էջքը առաքյալների վրա", "Ջրհեղեղը", "Տաճարի կառուցումը", "Հիսուսի ծնունդը"],
            optionsRu: ["Сошествие Святого Духа на апостолов", "Великий потоп", "Освящение храма", "Рождество Христа"],
            optionsEn: ["Descent of the Holy Spirit on apostles", "Great Flood", "Temple dedication", "Nativity of Christ"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Հոգին իջավ հրեղեն լեզուներով, և առաքյալները սկսեցին խոսել տարբեր լեզուներով։",
            explanationRu: "Дух Святой сошел в виде огненных языков, наделив апостолов даром проповеди на всех языках.",
            explanationEn: "The Holy Spirit descended like tongues of fire, empowering the apostles to preach globally.",
            verseRefHy: "Գործք 2:1-4",
            verseRefRu: "Деяния 2:1-4",
            verseRefEn: "Acts 2:1-4"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .hard,
            questionHy: "Ո՞րն է Նոր Կտակարանի վերջին գիրքը։",
            questionRu: "Какая последняя пророческая книга Нового Завета?",
            questionEn: "What is the final prophetic book of the New Testament?",
            optionsHy: ["Հայտնություն (Ապոկալիպսիս)", "Եբրայեցիներ", "Հուդա", "Գործք Առաքելոց"],
            optionsRu: ["Откровение Иоанна Богослова (Апокалипсис)", "Послание к Евреям", "Послание Иуды", "Деяния Апостолов"],
            optionsEn: ["Book of Revelation (Apocalypse)", "Hebrews", "Jude", "Acts of the Apostles"],
            correctAnswerIndex: 0,
            explanationHy: "Հովհաննես առաքյալի Հայտնությունը Պատմոս կղզում եզրափակում է Սուրբ Գիրքը։",
            explanationRu: "Книга Откровения святого Иоанна Богослова на острове Патмос завершает библейский канон.",
            explanationEn: "The Book of Revelation by John on Patmos concludes the Holy Scriptures.",
            verseRefHy: "Հայտնություն 22:20",
            verseRefRu: "Откровение 22:20",
            verseRefEn: "Revelation 22:20"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .hard,
            questionHy: "Ո՞ր գլխում է Պողոս առաքյալը գրել Սիրո հայտնի Օրհներգը («Եթե սեր չունենամ, ոչինչ եմ»)։",
            questionRu: "В какой главе апостол Павел воспел бессмертный Гимн Любви («Если я любви не имею, то я ничто»)?",
            questionEn: "In which chapter did Paul write the famous Hymn to Love («If I have not love, I am nothing»)?",
            optionsHy: ["Ա Կորնթացիս 13", "Հռոմեացիս 8", "Գաղատացիս 5", "Եփեսացիս 4"],
            optionsRu: ["1 Коринфянам 13", "Римлянам 8", "Галатам 5", "Ефесянам 4"],
            optionsEn: ["1 Corinthians 13", "Romans 8", "Galatians 5", "Ephesians 4"],
            correctAnswerIndex: 0,
            explanationHy: "«Սերը համբերող է, քաղցրաբարո է... Սերը երբեք չի անհետանում» (Ա Կորնթացիս 13:4-8)։",
            explanationRu: "«Любовь долготерпит, милосердствует... Любовь никогда не перестает» (1 Кор 13:4-8).",
            explanationEn: "«Love is patient, love is kind... Love never fails» (1 Corinthians 13:4-8).",
            verseRefHy: "Ա Կորնթացիս 13:1-13",
            verseRefRu: "1 Коринфянам 13:1-13",
            verseRefEn: "1 Corinthians 13:1-13"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Ի՞նչ մասնագիտություն ուներ Ղուկաս Ավետարանիչը։",
            questionRu: "Какую профессию имел святой евангелист Лука?",
            questionEn: "What profession did Saint Luke the Evangelist have?",
            optionsHy: ["Բժիշկ", "Զինվոր", "Ձկնորս", "Շինարար"],
            optionsRu: ["Врач", "Воин", "Рыбак", "Строитель"],
            optionsEn: ["Physician (Doctor)", "Soldier", "Fisherman", "Builder"],
            correctAnswerIndex: 0,
            explanationHy: "Պողոս առաքյալը նրան անվանում է «Ղուկասը՝ սիրելի բժիշկը» (Կողոսացիս 4:14)։",
            explanationRu: "Апостол Павел приветствует общину: «Приветствует вас Лука, врач возлюбленный» (Кол 4:14).",
            explanationEn: "Paul calls him «our dear friend Luke, the doctor» (Colossians 4:14).",
            verseRefHy: "Կողոսացիս 4:14",
            verseRefRu: "Колоссянам 4:14",
            verseRefEn: "Colossians 4:14"
        ),

        // =========================================================================
        // MARK: - 4. АРМЯНСКАЯ ЦЕРКОВЬ И СВЯТЫЕ (CHURCH HISTORY)
        // =========================================================================
        QuizQuestion(
            category: .churchHistory,
            difficulty: .easy,
            questionHy: "Ո՞ր երկու առաքյալներն են համարվում Հայաստանյայց Առաքելական Եկեղեցու Առաջին Լուսավորիչները։",
            questionRu: "Какие два святых апостола из 12 считаются Первопросветителями Армении?",
            questionEn: "Which two apostles of the 12 are recognized as the First Illuminators of Armenia?",
            optionsHy: ["Սուրբ Թադեոս և Սուրբ Բարդուղիմեոս", "Սուրբ Պետրոս և Սուրբ Պողոս", "Սուրբ Հովհաննես և Սուրբ Անդրեաս", "Սուրբ Մատթեոս և Սուրբ Ղուկաս"],
            optionsRu: ["Святой Фаддей и Святой Варфоломей", "Святой Петр и Святой Павел", "Святой Иоанн и Святой Андрей", "Святой Матфей и Святой Лука"],
            optionsEn: ["Saint Thaddeus and Saint Bartholomew", "Saint Peter and Saint Paul", "Saint John and Saint Andrew", "Saint Matthew and Saint Luke"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Թադեոս և Սուրբ Բարդուղիմեոս առաքյալները 1-ին դարում բերեցին Քրիստոնեությունը Հայաստան։",
            explanationRu: "Апостолы Фаддей и Варфоломей принесли свет Евангелия в Армению в I веке.",
            explanationEn: "Apostles Thaddeus and Bartholomew preached the Gospel and were martyred in Armenia in the 1st century.",
            verseRefHy: "Հայոց Եկեղեցու Պատմություն (1-ին դար)",
            verseRefRu: "История Армянской Церкви (I век)",
            verseRefEn: "History of the Armenian Church (1st Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .easy,
            questionHy: "Ո՞ր թվականին Հայաստանը ընդունեց Քրիստոնեությունը որպես պետական կրոն (առաջինը աշխարհում)։",
            questionRu: "В каком году Армения первой в мире провозгласила христианство государственной религией?",
            questionEn: "In which year did Armenia adopt Christianity as its state religion (first in the world)?",
            optionsHy: ["301 թ.", "313 թ.", "325 թ.", "451 թ."],
            optionsRu: ["301 г.", "313 г.", "325 г.", "451 г."],
            optionsEn: ["301 AD", "313 AD", "325 AD", "451 AD"],
            correctAnswerIndex: 0,
            explanationHy: "301 թվականին Սուրբ Գրիգոր Լուսավորչի և Տրդատ Գ Մեծ արքայի շնորհիվ Հայաստանը դարձավ առաջին քրիստոնյա պետությունը։",
            explanationRu: "В 301 году при святом Григории Просветителе и царе Трдате III Армения стала первым христианским государством.",
            explanationEn: "In 301 AD, under Saint Gregory the Illuminator and King Tiridates III, Armenia became the first Christian nation.",
            verseRefHy: "Հայոց Պատմություն 301 թ.",
            verseRefRu: "История Армении 301 г.",
            verseRefEn: "History of Armenia 301 AD"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Քանի՞ տարի անցկացրեց Սուրբ Գրիգոր Լուսավորիչը Խոր Վիրապի խոր փոսում։",
            questionRu: "Сколько лет святой Григорий Просветитель провел в заточении в темнице Хор Вирап?",
            questionEn: "How many years was Saint Gregory the Illuminator imprisoned in the pit of Khor Virap?",
            optionsHy: ["7 տարի", "10 տարի", "13-14 տարի", "40 տարի"],
            optionsRu: ["7 лет", "10 лет", "13-14 лет", "40 лет"],
            optionsEn: ["7 years", "10 years", "13-14 years", "40 years"],
            correctAnswerIndex: 2,
            explanationHy: "Սուրբ Գրիգորը մոտ 14 տարի հրաշքով ապրեց Խոր Վիրապի խորխորատում՝ հավատարիմ մնալով Քրիստոսին։",
            explanationRu: "Святой Григорий провел около 14 лет в темнице Хор Вирап, поддерживаемый молитвой и помощью благочестивой женщины.",
            explanationEn: "Saint Gregory miraculously survived approximately 14 years in the deep dungeon pit of Khor Virap.",
            verseRefHy: "Ագաթանգեղոս, Պատմություն Հայոց",
            verseRefRu: "Агафангел, «История Армении»",
            verseRefEn: "Agathangelos, History of the Armenians"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .easy,
            questionHy: "Ո՞վ ստեղծեց Հայոց Այբուբենը 405 թվականին Աստվածաշունչը թարգմանելու համար։",
            questionRu: "Кто создал армянский алфавит в 405 году для перевода Священного Писания?",
            questionEn: "Who created the Armenian alphabet in 405 AD to translate the Holy Bible?",
            optionsHy: ["Սուրբ Մեսրոպ Մաշտոցը", "Սուրբ Գրիգոր Նարեկացին", "Մովսես Խորենացին", "Սուրբ Սահակ Պարթևը"],
            optionsRu: ["Святой Месроп Маштоц", "Святой Григор Нарекаци", "Мовсес Хоренаци", "Святой Саак Партев"],
            optionsEn: ["Saint Mesrop Mashtots", "Saint Gregory of Narek", "Movses Khorenatsi", "Saint Sahak Partev"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Մեսրոպ Մաշտոցը Աստծո ներշնչանքով ստեղծեց 36 հայերեն տառերը 405 թվականին։",
            explanationRu: "Святой Месроп Маштоц при поддержке католикоса Саака и царя Врамшапуха создал армянские письмена.",
            explanationEn: "Saint Mesrop Mashtots, inspired by God, invented the Armenian alphabet in 405 AD.",
            verseRefHy: "Կորյուն, «Վարք Մաշտոցի»",
            verseRefRu: "Корюн, «Житие Маштоца»",
            verseRefEn: "Koryun, The Life of Mashtots"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Ո՞րն էր հայերեն թարգմանված առաջին նախադասությունը Աստվածաշնչից։",
            questionRu: "Какое первое предложение было переведено на армянский язык из Библии?",
            questionEn: "What was the very first sentence translated into Armenian from the Bible?",
            optionsHy: [
                "«Ճանաչել զիմաստութիւն եւ զխրատ, իմանալ զբանս հանճարոյ»",
                "«Ի սկզբանէ էր Բանն, եւ Բանն էր առ Աստուած»",
                "«Սկզբում Աստված ստեղծեց երկինքն ու երկիրը»",
                "«Տէրն իմ հովիւն է, եւ ինձ ոչինչ չի պակասիլ»"
            ],
            optionsRu: [
                "«Познать мудрость и наставление, понять изречения разума»",
                "«В начале было Слово, и Слово было у Бога»",
                "«В начале сотворил Бог небо и землю»",
                "«Господь — Пастырь мой; я ни в чем не буду нуждаться»"
            ],
            optionsEn: [
                "«To know wisdom and instruction; to perceive the words of understanding»",
                "«In the beginning was the Word, and the Word was with God»",
                "«In the beginning God created the heavens and the earth»",
                "«The Lord is my shepherd; I shall not want»"
            ],
            correctAnswerIndex: 0,
            explanationHy: "Սողոմոնի Առակաց գրքի առաջին տողն էր՝ «Ճանաչել զիմաստութիւն եւ զխրատ...»։",
            explanationRu: "Священное Писание на армянском началось со стиха Притчей Соломона 1:2.",
            explanationEn: "The Armenian translation of the Scriptures opened with Proverbs 1:2.",
            verseRefHy: "Առակաց 1:2",
            verseRefRu: "Притчи 1:2",
            verseRefEn: "Proverbs 1:2"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .hard,
            questionHy: "Ինչպե՞ս է կոչվում Աստվածաշնչի հայերեն թարգմանությունը համաշխարհային մշակույթում։",
            questionRu: "Как в мировом христианском богословии называют армянский перевод Библии V века?",
            questionEn: "How is the 5th-century Armenian translation of the Bible revered in world scholarship?",
            optionsHy: ["«Թարգմանությունների Թագուհի»", "«Արծաթե Գիրք»", "«Ոսկեդարյան Մատյան»", "«Արևելյան Ավետարան»"],
            optionsRu: ["«Царица переводов» (Queen of Translations)", "«Серебряная Книга»", "«Летопись Золотого века»", "«Восточное Евангелие»"],
            optionsEn: ["«Queen of Translations»", "«Silver Codex»", "«Golden Age Tome»", "«Gospel of the Orient»"],
            correctAnswerIndex: 0,
            explanationHy: "Իր անկրկնելի ճշգրտության և գեղեցկության շնորհիվ հայերեն Աստվածաշունչը կոչվում է «Թարգմանությունների Թագուհի»։",
            explanationRu: "За непревзойденную точность, поэтичность и чистоту армянский перевод назван «Царицей переводов».",
            explanationEn: "Due to its unmatched accuracy and literary beauty, the Armenian Bible is called the «Queen of Translations».",
            verseRefHy: "Ոսկեդար (V դար)",
            verseRefRu: "Золотой Век Армении (V век)",
            verseRefEn: "Golden Age of Armenia (5th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Ո՞վ է հեղինակել հանճարեղ «Մատյան Ողբերգության» (Նարեկ) աղոթագրքի գլուխգործոցը։",
            questionRu: "Кто является автором великой молитвенной книги «Книга скорбных песнопений» (Нарек)?",
            questionEn: "Who authored the spiritual masterpiece «Book of Lamentations» (Narek)?",
            optionsHy: ["Սուրբ Գրիգոր Նարեկացին", "Սուրբ Ներսես Շնորհալին", "Եղիշեն", "Գրիգոր Տաթևացին"],
            optionsRu: ["Святой Григор Нарекаци", "Святой Нерсес Шнорали", "Егише", "Григор Татеваци"],
            optionsEn: ["Saint Gregory of Narek", "Saint Nerses the Gracious", "Yeghishe", "Gregory of Tatev"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Գրիգոր Նարեկացին 10-րդ դարում գրեց «Մատյան Ողբերգության» աղոթագիրքը («Ի խորոց սրտի»)։",
            explanationRu: "Святой монах Григор Нарекаци в X веке создал бессмертную «Книгу скорбных песнопений» («Из глубин сердца»).",
            explanationEn: "Saint Gregory of Narek composed the «Book of Lamentations» in the 10th century at Narekavank.",
            verseRefHy: "Մատյան Ողբերգության (X դար)",
            verseRefRu: "Книга скорбных песнопений (X век)",
            verseRefEn: "Book of Lamentations (10th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Ո՞վ գրեց հայտնի 24-ժամյա աղոթքը՝ «Հավատով Խոստովանիմ»։",
            questionRu: "Кто написал знаменитую молитву на каждый час дня «С верою исповедую» (Հաւատով խոստովանիմ)?",
            questionEn: "Who composed the beloved 24-hour prayer «With Faith I Confess» (Havadov Khosdovanim)?",
            optionsHy: ["Սուրբ Ներսես Շնորհալի Կաթողիկոսը", "Սուրբ Գրիգոր Լուսավորիչը", "Սուրբ Մեսրոպ Մաշտոցը", "Սուրբ Հովհան Օձնեցին"],
            optionsRu: ["Святой Нерсес Шнорали (Благодатный)", "Святой Григорий Просветитель", "Святой Месроп Маштоц", "Святой Ован Одзнеци"],
            optionsEn: ["Saint Nerses the Gracious (Shnorhali)", "Saint Gregory the Illuminator", "Saint Mesrop Mashtots", "Saint John of Otzun"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Ներսես Շնորհալի Հայրապետը (12-րդ դար) գրեց «Հավատով Խոստովանիմ» 24 տներից բաղկացած աղոթքը։",
            explanationRu: "Святой католикос Нерсес Шнорали (XII век) сложил 24 вдохновенные строфы молитвы «С верою исповедую».",
            explanationEn: "Catholicos Saint Nerses Shnorhali composed the 24-stanza prayer «With Faith I Confess» in the 12th century.",
            verseRefHy: "Հավատով Խոստովանիմ (XII դար)",
            verseRefRu: "«С верою исповедую» (XII век)",
            verseRefEn: "With Faith I Confess (12th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Ի՞նչ նշանաբանով առաջնորդվեց Սուրբ Վարդան Մամիկոնյանը Ավարայրի ճակատամարտում (451 թ.)։",
            questionRu: "С каким бессмертным заветом вел воинов святой Вардан Мамиконян на Аварайрском поле (451 г.)?",
            questionEn: "With what motto did Saint Vardan Mamikonian lead the defenders at Avarayr (451 AD)?",
            optionsHy: [
                "«Մահ ոչ իմացեալ՝ մահ է, մահ իմացեալ՝ անմահութիւն»",
                "«Հաղթանակ կամ մահ»",
                "«Խաղաղություն ամենեցուն»",
                "«Ազատություն և պատիվ»"
            ],
            optionsRu: [
                "«Смерть неосознанная есть смерть, смерть осознанная — бессмертие»",
                "«Победа или смерть»",
                "«Мир всем народам»",
                "«Свобода и честь»"
            ],
            optionsEn: [
                "«Unconscious death is death, conscious death is immortality»",
                "«Victory or death»",
                "«Peace to all nations»",
                "«Freedom and honor»"
            ],
            correctAnswerIndex: 0,
            explanationHy: "Վարդանանց քաջերը պաշտպանեցին քրիստոնեական հավատը՝ «Վասն Յիսուսի, վասն հայրենեաց»։",
            explanationRu: "Святые Вардананц пали за веру Христову и свободу совести под девизом осознанного бессмертия.",
            explanationEn: "Saint Vardan and his companions defended the Christian faith at Avarayr with the immortal words on conscious sacrifice.",
            verseRefHy: "Եղիշե, «Վարդանի և Հայոց պատերազմի մասին»",
            verseRefRu: "Егише, «О Вардане и войне армянской»",
            verseRefEn: "Yeghishe, The History of Vardan and the Armenian War"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .hard,
            questionHy: "Ո՞ր սուրբ կույսերի նահատակության վայրերում կառուցվեցին Վաղարշապատի հոյակապ տաճարները։",
            questionRu: "В честь каких святых дев-мучениц воздвигнуты великие храмы Эчмиадзина?",
            questionEn: "In honor of which holy virgin-martyrs were the great temples of Vagharshapat built?",
            optionsHy: ["Սուրբ Հռիփսիմե և Սուրբ Գայանե", "Սուրբ Շուշանիկ և Սուրբ Սանդուխտ", "Սուրբ Աննա և Սուրբ Եղիսաբեթ", "Սուրբ Մարիամ և Սուրբ Մարթա"],
            optionsRu: ["Святая Рипсиме и Святая Гаяне", "Святая Шушаник и Святая Сандухт", "Святая Анна и Святая Елисавета", "Святая Мария и Святая Марфа"],
            optionsEn: ["Saint Hripsime and Saint Gayane", "Saint Shushanik and Saint Sandukht", "Saint Anna and Saint Elizabeth", "Saint Mary and Saint Martha"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Հռիփսիմյանց կույսերի նահատակության վայրերում Սուրբ Գրիգոր Լուսավորիչը հիմնեց վկայարանները։",
            explanationRu: "На местах мученического подвига святых дев Рипсиме, Гаяне и Мариамне были воздвигнуты святые храмы.",
            explanationEn: "Saint Gregory the Illuminator established chapels on the martyrdom sites of Saint Hripsime and Saint Gayane.",
            verseRefHy: "Ագաթանգեղոս (IV դար)",
            verseRefRu: "Агафангел (IV век)",
            verseRefEn: "Agathangelos (4th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .hard,
            questionHy: "Ի՞նչ է նշանակում «Էջմիածին» բառը։",
            questionRu: "Что означает священное название первопрестольного собора «Эчмиадзин» (Էջմիածին)?",
            questionEn: "What does the sacred name of the Holy See «Echmiadzin» (Էջմիածին) mean?",
            optionsHy: ["«Իջավ Միածինը» (Միածին Որդին)", "«Սուրբ Լույս»", "«Աստծո Տուն»", "«Հավերժական Խաչ»"],
            optionsRu: ["«Сошел Единородный» (Сын Божий)", "«Святой Свет»", "«Дом Божий»", "«Вечный Крест»"],
            optionsEn: ["«The Only Begotten Descended»", "«Holy Light»", "«House of God»", "«Eternal Cross»"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Գրիգոր Լուսավորչի տեսիլքում Հիսուս Քրիստոս իջավ ոսկե մուրճով և ցույց տվեց Մայր Տաճարի տեղը։",
            explanationRu: "В видении святого Григория Сам Единородный Сын Божий сошел с небес и золотым молотом указал место храма.",
            explanationEn: "In Saint Gregory's vision, Christ the Only Begotten descended with a golden hammer to strike the location of the Cathedral.",
            verseRefHy: "Մայր Աթոռ Սուրբ Էջմիածին",
            verseRefRu: "Первопрестольный Святой Эчмиадзин",
            verseRefEn: "Mother See of Holy Etchmiadzin"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .hard,
            questionHy: "Ո՞ր սրբությունն է պահվում Էջմիածնի գանձատանը, որով խոցել էին Քրիստոսի կողը Խաչի վրա։",
            questionRu: "Какая великая святыня хранится в Эчмиадзине, которой сотник пронзил ребро Христа на Кресте?",
            questionEn: "Which holy relic is preserved in Echmiadzin, with which Christ's side was pierced on the Cross?",
            optionsHy: ["Սուրբ Գեղարդը (Հռոմեացի զինվորի նիզակը)", "Փշե Պսակը", "Սուրբ Պատանքը", "Սուրբ Գավաթը"],
            optionsRu: ["Святой Гегард (Копье Лонгина)", "Терновый венец", "Плащаница", "Святой Грааль"],
            optionsEn: ["Holy Lance (Spear of Longinus / Geghard)", "Crown of Thorns", "Holy Shroud", "Holy Grail"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Թադեոս առաքյալը Սուրբ Գեղարդը բերեց Հայաստան, որը դարեր շարունակ պահվել է Գեղարդավանքում, ապա Էջմիածնում։",
            explanationRu: "Апостол Фаддей принес Святое Копье в Армению, давшее имя монастырю Гегардаванк.",
            explanationEn: "Apostle Thaddeus brought the Holy Lance to Armenia, where it is venerated at Holy Etchmiadzin.",
            verseRefHy: "Սուրբ Էջմիածնի Գանձեր",
            verseRefRu: "Сокровищница Святого Эчмиадзина",
            verseRefEn: "Treasury of Holy Etchmiadzin"
        ),

        // =========================================================================
        // MARK: - РАСШИРЕНИЕ 1: НОВЫЙ ЗАВЕТ (NEW TESTAMENT EXPANSION)
        // =========================================================================
        QuizQuestion(
            category: .newTestament,
            difficulty: .easy,
            questionHy: "Ո՞վ էր առաջին քրիստոնյա նահատակը, որին քարկոծեցին հավատքի համար։",
            questionRu: "Кто был первым христианским мучеником (первомучеником), побитым камнями за проповедь Христа?",
            questionEn: "Who was the first Christian martyr (protomartyr) stoned for his faith?",
            optionsHy: ["Սուրբ Ստեփանոս Նախավկան", "Սուրբ Պողոսը", "Սուրբ Պետրոսը", "Սուրբ Բառնաբասը"],
            optionsRu: ["Святой архидиакон Стефан", "Святой Павел", "Святой Петр", "Святой Варнава"],
            optionsEn: ["Saint Stephen the Protomartyr", "Saint Paul", "Saint Peter", "Saint Barnabas"],
            correctAnswerIndex: 0,
            explanationHy: "Ստեփանոս Նախավկան աղոթեց իրեն քարկոծողների համար. «Տե՛ր, այս մեղքը դրանց վրա մի՛ դիր» (Գործք 7:60)։",
            explanationRu: "Святой Стефан молился за своих мучителей: «Господи! не вмени им греха сего» (Деяния 7:60).",
            explanationEn: "Saint Stephen prayed for his executioners: «Lord, do not hold this sin against them» (Acts 7:60).",
            verseRefHy: "Գործք 7:54-60",
            verseRefRu: "Деяния 7:54-60",
            verseRefEn: "Acts 7:54-60"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .easy,
            questionHy: "Ի՞նչ պատահեց Սողոսին (ապագա Պողոս առաքյալին) Դամասկոսի ճանապարհին։",
            questionRu: "Что произошло с Савлом (будущим апостолом Павлом) по дороге в Дамаск?",
            questionEn: "What happened to Saul (the future Apostle Paul) on the road to Damascus?",
            optionsHy: ["Երկնքից լույս փայլեց և Հիսուս կանչեց նրան", "Նա նավաբեկության ենթարկվեց", "Նա տեսավ հրեշտակ Գաբրիելին", "Նա հանդիպեց Պետրոս առաքյալին"],
            optionsRu: ["Его осиял небесный свет и Христос призвал его", "Он потерпел кораблекрушение", "Ему явился архангел Гавриил", "Он встретил апостола Петра"],
            optionsEn: ["A heavenly light shone and Jesus called him", "He was shipwrecked", "Archangel Gabriel appeared to him", "He met Apostle Peter"],
            correctAnswerIndex: 0,
            explanationHy: "Հիսուս հարցրեց. «Սավո՛ւղ, Սավո՛ւղ, ինչո՞ւ ես ինձ հալածում» (Գործք 9:4)։",
            explanationRu: "Господь обратился к нему: «Савл, Савл! что ты гонишь Меня?» (Деяния 9:4).",
            explanationEn: "Jesus called out: «Saul, Saul, why do you persecute me?» (Acts 9:4).",
            verseRefHy: "Գործք 9:1-9",
            verseRefRu: "Деяния 9:1-9",
            verseRefEn: "Acts 9:1-9"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Որո՞նք են Սուրբ Հոգու պտուղները՝ ըստ Գաղատացիս թղթի։",
            questionRu: "Какие добродетели апостол Павел называет «плодами Духа» в Послании к Галатам?",
            questionEn: "Which virtues does Paul list as the «fruit of the Spirit» in Galatians?",
            optionsHy: [
                "Սեր, խնդություն, խաղաղություն, համբերատարություն",
                "Հարստություն, իշխանություն, փառք",
                "Զայրույթ, խանդ, հպարտություն",
                "Լռություն, միայնություն, վախ"
            ],
            optionsRu: [
                "Любовь, радость, мир, долготерпение, благость, вера",
                "Богатство, земная власть, слава",
                "Гнев, соперничество, гордость",
                "Молчание, одиночество, страх"
            ],
            optionsEn: [
                "Love, joy, peace, forbearance, kindness, goodness, faithfulness",
                "Wealth, earthly power, fame",
                "Anger, jealousy, pride",
                "Silence, solitude, fear"
            ],
            correctAnswerIndex: 0,
            explanationHy: "«Հոգու պտուղն է՝ սեր, խնդություն, խաղաղություն, երկայնամտություն...» (Գաղատացիս 5:22)։",
            explanationRu: "«Плод же духа: любовь, радость, мир, долготерпение, благость, милосердие, вера» (Гал 5:22).",
            explanationEn: "«The fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness» (Gal 5:22).",
            verseRefHy: "Գաղատացիս 5:22-23",
            verseRefRu: "Галатам 5:22-23",
            verseRefEn: "Galatians 5:22-23"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Ինչի՞ հետ է համեմատում Պողոս առաքյալը հավատքը Աստծո սպառազինության մեջ (Եփեսացիս 6)։",
            questionRu: "С каким предметом духовного всеоружия сравнивает веру апостол Павел в Послании к Ефесянам?",
            questionEn: "With which piece of spiritual armor does Paul compare faith in Ephesians 6?",
            optionsHy: ["Վահանի հետ (Հավատքի վահան)", "Սաղավարտի հետ", "Սրի հետ", "Գոտու հետ"],
            optionsRu: ["Со щитом («Щит веры»)", "Со шлемом", "С мечом", "С поясом"],
            optionsEn: ["With a shield («Shield of faith»)", "With a helmet", "With a sword", "With a belt"],
            correctAnswerIndex: 0,
            explanationHy: "«Ամեն ինչից առաջ վերցրե՛ք հավատքի վահանը, որով կկարողանաք հանգցնել չարի բոլոր բոցավառ նետերը» (Եփես. 6:16)։",
            explanationRu: "«А паче всего возьмите щит веры, которым возможете угасить все раскаленные стрелы лукавого» (Еф 6:16).",
            explanationEn: "«Take up the shield of faith, with which you can extinguish all the flaming arrows of the evil one» (Eph 6:16).",
            verseRefHy: "Եփեսացիս 6:16",
            verseRefRu: "Ефесянам 6:16",
            verseRefEn: "Ephesians 6:16"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .easy,
            questionHy: "Ո՞ր կղզում էր աքսորված Հովհաննես առաքյալը, երբ գրեց Հայտնության գիրքը։",
            questionRu: "На каком острове находился в ссылке святой апостол Иоанн Богослов, когда получил Откровение?",
            questionEn: "On which island was the Apostle John exiled when he wrote the Book of Revelation?",
            optionsHy: ["Պատմոս կղզում", "Կրետե կղզում", "Կիպրոսում", "Մալթայում"],
            optionsRu: ["На острове Патмос", "На острове Крит", "На Кипре", "На Мальте"],
            optionsEn: ["On the Island of Patmos", "On Crete", "On Cyprus", "On Malta"],
            correctAnswerIndex: 0,
            explanationHy: "«Ես՝ Հովհաննեսս... գտնվում էի Պատմոս կոչվող կղզում Աստծո խոսքի համար» (Հայտն. 1:9)։",
            explanationRu: "«Я, Иоанн... был на острове, называемом Патмос, за слово Божие» (Откр 1:9).",
            explanationEn: "«I, John... was on the island of Patmos because of the word of God» (Rev 1:9).",
            verseRefHy: "Հայտնություն 1:9",
            verseRefRu: "Откровение 1:9",
            verseRefEn: "Revelation 1:9"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Ո՞վ էր առաջին հեթանոս հարյուրապետը, որը մկրտվեց Պետրոս առաքյալի կողմից։",
            questionRu: "Кто был первым языческим римским сотником, принявшим крещение от апостола Петра?",
            questionEn: "Who was the first Gentile centurion baptized by the Apostle Peter?",
            optionsHy: ["Կոռնելիոսը", "Հուլիոսը", "Լոնգինոսը", "Պիղատոսը"],
            optionsRu: ["Корнилий сотник", "Сотник Юлий", "Сотник Лонгин", "Понтий Пилат"],
            optionsEn: ["Cornelius the Centurion", "Centurion Julius", "Centurion Longinus", "Pontius Pilate"],
            correctAnswerIndex: 0,
            explanationHy: "Կոռնելիոսը բարեպաշտ և ողորմած մարդ էր, որի տանը Սուրբ Հոգին իջավ հեթանոսների վրա (Գործք 10)։",
            explanationRu: "Корнилий был благочестивым воином в Кесарии, на дом которого сошел Святой Дух (Деяния 10).",
            explanationEn: "Cornelius was a devout centurion in Caesarea whose conversion opened the door to the Gentiles (Acts 10).",
            verseRefHy: "Գործք 10:1-48",
            verseRefRu: "Деяния 10:1-48",
            verseRefEn: "Acts 10:1-48"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Ինչպե՞ս է սահմանում Եբրայեցիներին ուղղված թուղթը Հավատքը (Եբր. 11:1)։",
            questionRu: "Как определяется вера в Послании к Евреям (Евр. 11:1)?",
            questionEn: "How is faith defined in Hebrews 11:1?",
            optionsHy: [
                "Հույս ունեցած բաների հաստատություն և չերևացող բաների ապացույց",
                "Միայն մտավոր համաձայնություն",
                "Երկրային հարստության ակնկալիք",
                "Առանց գործերի զգացմունք"
            ],
            optionsRu: [
                "Осуществление ожидаемого и уверенность в невидимом",
                "Простое знание фактов о Боге",
                "Ожидание материального благополучия",
                "Эмоциональное переживание без дел"
            ],
            optionsEn: [
                "Confidence in what we hope for and assurance about what we do not see",
                "Simple mental knowledge",
                "Expectation of earthly wealth",
                "Feelings without works"
            ],
            correctAnswerIndex: 0,
            explanationHy: "«Հավատքը հուսացած բաների հաստատությունն է և չերևացող բաների ապացույցը» (Եբրայեցիս 11:1)։",
            explanationRu: "«Вера же есть осуществление ожидаемого и уверенность в невидимом» (Евр 11:1).",
            explanationEn: "«Now faith is confidence in what we hope for and assurance about what we do not see» (Heb 11:1).",
            verseRefHy: "Եբրայեցիս 11:1",
            verseRefRu: "Евреям 11:1",
            verseRefEn: "Hebrews 11:1"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .hard,
            questionHy: "Ինչի՞ հետ է համեմատում Հակոբոս առաքյալը մարդու լեզուն (Հակոբոս 3)։",
            questionRu: "С чем сравнивает человеческий язык апостол Иаков в своем послании?",
            questionEn: "What does James compare the human tongue to in James 3?",
            optionsHy: ["Փոքր կրակի և նավի ղեկի հետ", "Սրածայր դաշույնի հետ", "Հոսող գետի հետ", "Ծաղկած ծառի հետ"],
            optionsRu: ["С небольшим огнем и корабельным рулем", "С острым мечом", "С бурным потоком", "С цветущим деревом"],
            optionsEn: ["With a small spark and a ship's rudder", "With a sharp dagger", "With a flowing river", "With a blooming tree"],
            correctAnswerIndex: 0,
            explanationHy: "Լեզուն փոքր անդամ է, բայց կարող է մեծ անտառ հրդեհել և ղեկավարել ամբողջ մարմինը (Հակոբոս 3:4-5)։",
            explanationRu: "Язык — малый член, но держит руль корабля и может зажечь великий лес (Иак 3:4-5).",
            explanationEn: "The tongue is a small part of the body, but it makes great boasts like a small spark setting a forest on fire (James 3:4-5).",
            verseRefHy: "Հակոբոս 3:2-8",
            verseRefRu: "Иакова 3:2-8",
            verseRefEn: "James 3:2-8"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .hard,
            questionHy: "Ո՞ր քաղաքի Արեոպագոսում Պողոս առաքյալը քարոզեց «Անծանոթ Աստծո» մասին։",
            questionRu: "В каком знаменитом городе на холме Ареопаг апостол Павел проповедовал о «Неведомом Боге»?",
            questionEn: "In which city on Mars Hill (Areopagus) did Paul preach about the «Unknown God»?",
            optionsHy: ["Աթենքում", "Հռոմում", "Կորնթոսում", "Եփեսոսում"],
            optionsRu: ["В Афинах", "В Риме", "В Коринфе", "В Ефесе"],
            optionsEn: ["In Athens", "In Rome", "In Corinth", "In Ephesus"],
            correctAnswerIndex: 0,
            explanationHy: "Պողոսը տեսավ զոհասեղան «Անծանոթ Աստծուն» գրությամբ և Աթենքի փիլիսոփաներին ավետեց Կենդանի Տիրոջը (Գործք 17:23)։",
            explanationRu: "Апостол Павел благовествовал греческим философам об Истинном Создателе у жертвенника «Неведомому Богу» (Деяния 17:23).",
            explanationEn: "Paul addressed the Athenian philosophers at the Areopagus regarding their altar to an «Unknown God» (Acts 17:23).",
            verseRefHy: "Գործք 17:22-31",
            verseRefRu: "Деяния 17:22-31",
            verseRefEn: "Acts 17:22-31"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .hard,
            questionHy: "Ո՞վ էր Պողոս առաքյալի հավատարիմ աշակերտը, որին նա անվանեց «հարազատ որդի հավատքի մեջ»։",
            questionRu: "Кого апостол Павел называл своим «истинным сыном по вере» и посвятил ему два пастырских послания?",
            questionEn: "Whom did Paul call his «true son in the faith» and dedicate two pastoral epistles to?",
            optionsHy: ["Տիմոթեոսին", "Տիտոսին", "Փիլիմոնին", "Սիղային"],
            optionsRu: ["Тимофея", "Тита", "Филимона", "Силу"],
            optionsEn: ["Timothy", "Titus", "Philemon", "Silas"],
            correctAnswerIndex: 0,
            explanationHy: "Տիմոթեոսը մանկուց դաստիարակվել էր Սուրբ Գրքով իր մոր՝ Եվնիկեի և տատի՝ Լոիդայի կողմից (Բ Տիմ. 1:5)։",
            explanationRu: "Юный Тимофей с детства наставлялся в Писании матерью Евникой и бабушкой Лоидой (2 Тим 1:5).",
            explanationEn: "Timothy was nurtured in faith by his mother Eunice and grandmother Lois (2 Tim 1:5).",
            verseRefHy: "Ա Տիմոթեոս 1:2",
            verseRefRu: "1 Тимофею 1:2",
            verseRefEn: "1 Timothy 1:2"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .easy,
            questionHy: "Ի՞նչ խորհրդավոր անուն ունի Երկնային Քաղաքը Հայտնության գրքի 21-րդ գլխում։",
            questionRu: "Как называется Небесный Град святости в 21-й главе Откровения Иоанна Богослова?",
            questionEn: "What is the name of the holy heavenly city in Revelation 21?",
            optionsHy: ["Նոր Երուսաղեմ", "Նոր Սիոն", "Եդեմի Պարտեզ", "Արարատ"],
            optionsRu: ["Новый Иерусалим", "Новый Сион", "Сад Эдемский", "Гора Арарат"],
            optionsEn: ["New Jerusalem", "New Zion", "Garden of Eden", "Mount Ararat"],
            correctAnswerIndex: 0,
            explanationHy: "«Եվ տեսա Սուրբ Քաղաքը՝ Նոր Երուսաղեմը, որ իջնում էր երկնքից՝ Աստծո մոտից» (Հայտն. 21:2)։",
            explanationRu: "«И я, Иоанн, увидел святый город Иерусалим, новый, сходящий от Бога с неба» (Откр 21:2).",
            explanationEn: "«I saw the Holy City, the new Jerusalem, coming down out of heaven from God» (Rev 21:2).",
            verseRefHy: "Հայտնություն 21:1-4",
            verseRefRu: "Откровение 21:1-4",
            verseRefEn: "Revelation 21:1-4"
        ),

        // =========================================================================
        // MARK: - РАСШИРЕНИЕ 2: АРМЯНСКАЯ ЦЕРКОВЬ И СВЯТЫЕ (CHURCH HISTORY EXPANSION)
        // =========================================================================
        QuizQuestion(
            category: .churchHistory,
            difficulty: .easy,
            questionHy: "Ո՞վ ստեղծեց հայոց գրերը 405 թվականին՝ Աստվածաշունչը թարգմանելու համար։",
            questionRu: "Кто создал армянский алфавит в 405 году для перевода Священного Писания?",
            questionEn: "Who created the Armenian alphabet in 405 AD to translate the Holy Bible?",
            optionsHy: ["Սուրբ Մեսրոպ Մաշտոցը", "Սուրբ Սահակ Պարթևը", "Մովսես Խորենացին", "Եզնիկ Կողբացին"],
            optionsRu: ["Святой Месроп Маштоц", "Святой Саак Партев", "Мовсес Хоренаци", "Езник Кохбаци"],
            optionsEn: ["Saint Mesrop Mashtots", "Saint Sahak Partev", "Movses Khorenatsi", "Yeznik of Koghb"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Մեսրոպ Մաշտոցը աստվածատուր տեսիլքով ստեղծեց 36 հայկական տառերը 405 թվականին։",
            explanationRu: "Святой Месроп Маштоц в 405 году создал 36 армянских букв, начав Золотой Век письменности.",
            explanationEn: "Saint Mesrop Mashtots created the 36 Armenian letters in 405 AD through divine inspiration.",
            verseRefHy: "Կորյուն, «Վարք Մաշտոցի»",
            verseRefRu: "Корюн, «Житие Маштоца»",
            verseRefEn: "Koryun, The Life of Mashtots"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .easy,
            questionHy: "Ո՞րն է հայերեն թարգմանված առաջին նախադասությունը պատմության մեջ։",
            questionRu: "Какое первое предложение в истории было написано и переведено на армянский язык?",
            questionEn: "What was the very first sentence translated and written in the Armenian language?",
            optionsHy: [
                "«Ճանաչել զիմաստութիւն և զխրատ, իմանալ զբանս հանճարոյ» (Առակաց 1:2)",
                "«Սկզբումն էր Բանը»",
                "«Հայր մեր, որ յերկինս ես»",
                "«Տերն իմ հովիվն է»"
            ],
            optionsRu: [
                "«Познать мудрость и наставление, понять изречения разума» (Притчи 1:2)",
                "«В начале было Слово»",
                "«Отче наш, сущий на небесах»",
                "«Господь — Пастырь мой»"
            ],
            optionsEn: [
                "«To know wisdom and instruction, to perceive the words of understanding» (Proverbs 1:2)",
                "«In the beginning was the Word»",
                "«Our Father who art in heaven»",
                "«The Lord is my shepherd»"
            ],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Մեսրոպ Մաշտոցը թարգմանությունը սկսեց Սողոմոնի Առակներից՝ «Ճանաչել զիմաստութիւն և զխրատ...»։",
            explanationRu: "Первыми армянскими словами стали стихи из Притчей Соломона (Притчи 1:2).",
            explanationEn: "The translation began with Proverbs 1:2: «To know wisdom and instruction...».",
            verseRefHy: "Առակաց 1:2",
            verseRefRu: "Притчи 1:2",
            verseRefEn: "Proverbs 1:2"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Ինչպե՞ս են անվանում հայերեն Աստվածաշնչի թարգմանությունը համաշխարհային մշակույթում։",
            questionRu: "Какое почетное звание носит армянский перевод Библии V века в мировом богословии?",
            questionEn: "What honorary title is given to the 5th-century Armenian translation of the Bible?",
            optionsHy: ["«Թարգմանությունների Թագուհի»", "«Արևելքի Մարգարիտ»", "«Ոսկե Մատյան»", "«Սրբության Աղբյուր»"],
            optionsRu: ["«Царица переводов» (Queen of Translations)", "«Жемчужина Востока»", "«Золотая Книга»", "«Источник Святости»"],
            optionsEn: ["«Queen of the Translations»", "«Pearl of the Orient»", "«Golden Book»", "«Fountain of Holiness»"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Սահակ Պարթևի և Մեսրոպ Մաշտոցի թարգմանությունն իր բացառիկ ճշգրտությամբ կոչվեց «Թարգմանությունների Թագուհի»։",
            explanationRu: "За непревзойденное изящество и точность армянскую Библию именуют «Царицей переводов».",
            explanationEn: "European scholars named the Armenian 5th-century version the «Queen of Translations» for its accuracy.",
            verseRefHy: "Ոսկեդար (V դար)",
            verseRefRu: "Золотой Век (V век)",
            verseRefEn: "Golden Age (5th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Քանի՞ տարի անցկացրեց Սուրբ Գրիգոր Լուսավորիչը Խոր Վիրապի խոր փոսում։",
            questionRu: "Сколько лет святой Григорий Просветитель провел в заточении в темнице Хор Вирап?",
            questionEn: "How many years did Saint Gregory the Illuminator spend imprisoned in Khor Virap?",
            optionsHy: ["13 տարի", "7 տարի", "40 օր", "3 տարի"],
            optionsRu: ["13 лет", "7 лет", "40 дней", "3 года"],
            optionsEn: ["13 years", "7 years", "40 days", "3 years"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Գրիգորը 13 տարի մնաց Խոր Վիրապի վիհում՝ աղոթքով և բարեպաշտ կնոջ գաղտնի օգնությամբ պահպանվելով։",
            explanationRu: "Святой Григорий 13 лет молился в глубокой яме Хор Вирапа, пока не исцелил царя Трдата III.",
            explanationEn: "Saint Gregory endured 13 years of imprisonment in the pit of Khor Virap before baptizing King Trdat III.",
            verseRefHy: "Ագաթանգեղոս (IV դար)",
            verseRefRu: "Агафангел (IV век)",
            verseRefEn: "Agathangelos (4th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .hard,
            questionHy: "Ո՞վ է հայտնի որպես «Հայոց Պատմահայր» (Քերթողահայր)։",
            questionRu: "Кто вошел в историю как «Отец армянской историографии» (Патмахайр)?",
            questionEn: "Who is celebrated as the «Father of Armenian History» (Patmahayr)?",
            optionsHy: ["Սուրբ Մովսես Խորենացին", "Եղիշեն", "Ղազար Փարպեցին", "Փավստոս Բուզանդը"],
            optionsRu: ["Святой Мовсес Хоренаци", "Егише", "Лазарь Парпеци", "Фавстос Бузанд"],
            optionsEn: ["Saint Movses Khorenatsi", "Yeghishe", "Ghazar Parpetsi", "Pavstos Buzand"],
            correctAnswerIndex: 0,
            explanationHy: "Մովսես Խորենացին 5-րդ դարում գրեց «Հայոց Պատմություն» հիմնարար աշխատությունը՝ սկսելով արարչագործությունից։",
            explanationRu: "Святой Мовсес Хоренаци в V веке создал монументальную «Историю Армении».",
            explanationEn: "Movses Khorenatsi wrote the foundational «History of Armenia» in the 5th century.",
            verseRefHy: "Մովսես Խորենացի, «Հայոց Պատմություն»",
            verseRefRu: "Мовсес Хоренаци, «История Армении»",
            verseRefEn: "Movses Khorenatsi, History of the Armenians"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .hard,
            questionHy: "Ո՞ր միջնադարյան հռչակավոր վանքում և համալսարանում էր գործում Սուրբ Գրիգոր Տաթևացին։",
            questionRu: "В каком великом средневековом монастыре и университете творил святой Григор Татеваци?",
            questionEn: "In which renowned medieval monastery and university did Saint Gregory of Tatev teach?",
            optionsHy: ["Տաթևի Վանքում", "Սանահինում", "Գեղարդում", "Հաղպատում"],
            optionsRu: ["В Татевском монастыре", "В Санаине", "В Гегарде", "В Ахпате"],
            optionsEn: ["In Tatev Monastery", "In Sanahin", "In Geghard", "In Haghpat"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Գրիգոր Տաթևացին 14-րդ դարում Տաթևի համալսարանի մեծ րաբունապետն ու աստվածաբանն էր։",
            explanationRu: "Святой Григор Татеваци (XIV век) был выдающимся ректором Татевского университета и автором «Книги вопрошений».",
            explanationEn: "Saint Gregory of Tatev led the famous University of Tatev in the 14th century.",
            verseRefHy: "Տաթևի Համալսարան (XIV դար)",
            verseRefRu: "Татевский Университет (XIV век)",
            verseRefEn: "University of Tatev (14th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Քանի՞ Տաղավար (Գլխավոր Մեծ) տոներ ունի Հայ Առաքելական Եկեղեցին։",
            questionRu: "Сколько Великих (Главных Господских) праздников — Тагаваронк — отмечает Армянская Церковь?",
            questionEn: "How many Major Tabernacle Feasts (Daghavar Feasts) does the Armenian Church celebrate?",
            optionsHy: ["5 Տաղավար տոն", "7 տոն", "12 տոն", "3 տոն"],
            optionsRu: ["5 праздников (Тагаваронк)", "7 праздников", "12 праздников", "3 праздника"],
            optionsEn: ["5 Major Feasts (Daghavar)", "7 Feasts", "12 Feasts", "3 Feasts"],
            correctAnswerIndex: 0,
            explanationHy: "5 Տաղավար տոներն են՝ Սուրբ Ծնունդ, Սուրբ Զատիկ, Պայծառակերպություն (Վարդավառ), Վերափոխումն Սբ. Աստվածածնի և Խաչվերաց։",
            explanationRu: "5 Великих праздников: Рождество и Богоявление, Пасха (Затик), Преображение (Вардавар), Успение Богородицы и Воздвижение Креста.",
            explanationEn: "The 5 Tabernacle Feasts are: Nativity & Theophany, Easter (Zatik), Transfiguration (Vardavar), Assumption, and Exaltation of the Cross.",
            verseRefHy: "Հայ Եկեղեցու Տոնացույց",
            verseRefRu: "Церковный Календарь Армянской Церкви",
            verseRefEn: "Armenian Church Liturgical Calendar"
        ),

        // =========================================================================
        // MARK: - РАСШИРЕНИЕ 3: ЕВАНГЕЛИЯ (GOSPELS EXPANSION)
        // =========================================================================
        QuizQuestion(
            category: .gospels,
            difficulty: .easy,
            questionHy: "Ո՞րն էր Հիսուսի կատարած առաջին հրաշքը ըստ Հովհաննեսի Ավետարանի։",
            questionRu: "Какое первое чудо сотворил Иисус Христос согласно Евангелию от Иоанна?",
            questionEn: "What was Jesus' first miracle according to the Gospel of John?",
            optionsHy: ["Ջուրը գինու փոխելը Կանայի հարսանիքում", "Փոթորիկը հանդարտեցնելը", "5000 մարդու կերակրելը", "Ղազարոսին հարություն տալը"],
            optionsRu: ["Претворение воды в вино на браке в Кане Галилейской", "Укрощение бури", "Насыщение 5000 человек", "Воскрешение Лазаря"],
            optionsEn: ["Turning water into wine at the wedding in Cana", "Calming the storm", "Feeding the 5000", "Raising Lazarus"],
            correctAnswerIndex: 0,
            explanationHy: "Կանայի հարսանիքում Հիսուս ջուրը փոխեց ընտիր գինու՝ Իր մոր՝ Մարիամի խնդրանքով (Հովհ. 2:1-11)։",
            explanationRu: "В Кане Галилейской по просьбе Богородицы Христос совершил первое знамение (Иоанна 2:1-11).",
            explanationEn: "Jesus transformed water into wine at the wedding in Cana of Galilee (John 2:1-11).",
            verseRefHy: "Հովհաննես 2:1-11",
            verseRefRu: "Иоанна 2:1-11",
            verseRefEn: "John 2:1-11"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ո՞ւմ հարություն տվեց Հիսուսը Բեթանիայում՝ նրա մահից չորս օր անց։",
            questionRu: "Кого воскресил Иисус Христос в Вифании на четвертый день после его погребения?",
            questionEn: "Whom did Jesus raise from the dead in Bethany four days after his death?",
            optionsHy: ["Սուրբ Ղազարոսին", "Հայրոսի աղջկան", "Նայինի այրու որդուն", "Նիկոդեմոսին"],
            optionsRu: ["Праведного Лазаря Четверодневного", "Дочь Иаира", "Сына вдовы Наинской", "Никодима"],
            optionsEn: ["Righteous Lazarus Four-Days-Dead", "Jairus' daughter", "Widow of Nain's son", "Nicodemus"],
            correctAnswerIndex: 0,
            explanationHy: "Հիսուսն արտասվեց և ձայնեց. «Ղազարո՛ս, դո՛ւրս արի» (Հովհաննես 11:43)։",
            explanationRu: "Иисус воззвал громким голосом: «Лазарь! иди вон», и умерший вышел (Иоанна 11:43).",
            explanationEn: "Jesus called in a loud voice: «Lazarus, come out!» and the dead man emerged (John 11:43).",
            verseRefHy: "Հովհաննես 11:1-44",
            verseRefRu: "Иоанна 11:1-44",
            verseRefEn: "John 11:1-44"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .easy,
            questionHy: "Ո՞ր ծառի վրա բարձրացավ կարճահասակ մաքսավոր Զաքեոսը՝ Հիսուսին տեսնելու համար։",
            questionRu: "На какое дерево залез начальник мытарей Закхей в Иерихоне, чтобы увидеть Иисуса?",
            questionEn: "Which tree did Zacchaeus climb in Jericho to see Jesus passing by?",
            optionsHy: ["Ժանտաթզենու (Սիկոմորենու) վրա", "Ձիթենու վրա", "Արմավենու վրա", "Կաղնու վրա"],
            optionsRu: ["На смоковницу (сикомору)", "На маслину", "На пальму", "На дуб"],
            optionsEn: ["A sycamore-fig tree", "An olive tree", "A palm tree", "An oak tree"],
            correctAnswerIndex: 0,
            explanationHy: "Հիսուս տեսավ նրան և ասաց. «Զաքեո՛ս, շուտով իջի՛ր, որովհետև այսօր ես պետք է քո տանը մնամ» (Ղուկաս 19:5)։",
            explanationRu: "Иисус сказал ему: «Закхей! сойди скорее, ибо сегодня надобно Мне быть у тебя в доме» (Луки 19:5).",
            explanationEn: "Jesus said: «Zacchaeus, come down immediately. I must stay at your house today» (Luke 19:5).",
            verseRefHy: "Ղուկաս 19:1-10",
            verseRefRu: "Луки 19:1-10",
            verseRefEn: "Luke 19:1-10"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ի՞նչ արեց Հիսուսը Խորհրդավոր Ընթրիքի ժամանակ՝ խոնարհության օրինակ ցույց տալու համար։",
            questionRu: "Что совершил Иисус Христос на Тайной Вечери в знак совершенного смирения и любви?",
            questionEn: "What act of supreme humility and service did Jesus perform at the Last Supper?",
            optionsHy: ["Լվաց աշակերտների ոտքերը", "Օծեց նրանց գլուխները յուղով", "Բաժանեց Իր հագուստները", "Երգեց գոհության սաղմոս"],
            optionsRu: ["Умыл ноги Своим ученикам", "Помазал их головы елеем", "Раздал Свои одежды", "Воспел победный гимн"],
            optionsEn: ["Washed the disciples' feet", "Anointed their heads with oil", "Gave away His garments", "Sang a victory psalm"],
            correctAnswerIndex: 0,
            explanationHy: "«Եթե Ես՝ Տերս և Վարդապետս, լվացի ձեր ոտքերը, դուք էլ պարտավոր եք միմյանց ոտքերը լվանալ» (Հովհ. 13:14)։",
            explanationRu: "«Если Я, Господь и Учитель, умыл ноги вам, то и вы должны умывать ноги друг другу» (Иоанна 13:14).",
            explanationEn: "«Now that I, your Lord and Teacher, have washed your feet, you also should wash one another's feet» (John 13:14).",
            verseRefHy: "Հովհաննես 13:1-17",
            verseRefRu: "Иоанна 13:1-17",
            verseRefEn: "John 13:1-17"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .easy,
            questionHy: "Քանի՞ անգամ Պետրոս առաքյալը ուրացավ Հիսուսին նախքան աքաղաղի կանչելը։",
            questionRu: "Сколько раз апостол Петр отрекся от Христа во дворе первосвященника прежде, чем пропел петух?",
            questionEn: "How many times did Peter deny Jesus before the rooster crowed?",
            optionsHy: ["3 անգամ", "1 անգամ", "7 անգամ", "2 անգամ"],
            optionsRu: ["3 раза", "1 раз", "7 раз", "2 раза"],
            optionsEn: ["3 times", "1 time", "7 times", "2 times"],
            correctAnswerIndex: 0,
            explanationHy: "Աքաղաղը կանչեց, և Պետրոսը հիշեց Տիրոջ խոսքը ու դառնորեն լաց եղավ (Մատթեոս 26:75)։",
            explanationRu: "Вспомнив предсказание Иисуса, Петр вышел вон и горько заплакал (Матфея 26:75).",
            explanationEn: "Then Peter remembered the word Jesus had spoken and he went outside and wept bitterly (Matthew 26:75).",
            verseRefHy: "Մատթեոս 26:69-75",
            verseRefRu: "Матфея 26:69-75",
            verseRefEn: "Matthew 26:69-75"
        ),

        // =========================================================================
        // MARK: - РАСШИРЕНИЕ 4: ВЕТХИЙ ЗАВЕТ (OLD TESTAMENT EXPANSION)
        // =========================================================================
        QuizQuestion(
            category: .oldTestament,
            difficulty: .easy,
            questionHy: "Ի՞նչ տեսավ Հակոբ նահապետը երազում Բեթելում։",
            questionRu: "Что увидел патриарх Иаков в вещем сне в Вефиле?",
            questionEn: "What did Jacob see in his dream at Bethel?",
            optionsHy: ["Սանդուղք, որը հասնում էր երկինք և հրեշտակներ", "Այրվող մորենի", "Յոթ գեր և յոթ նիհար կովեր", "Կարմիր ծովի բացվելը"],
            optionsRu: ["Лестницу до небес, по которой восходили ангелы", "Неопалимую купину", "Семь тучных и семь тощих коров", "Разделившееся море"],
            optionsEn: ["A ladder reaching to heaven with angels ascending and descending", "A burning bush", "Seven fat and seven lean cows", "Parting of the Red Sea"],
            correctAnswerIndex: 0,
            explanationHy: "Հակոբը զարթնեց և ասաց. «Իսկապես Տերը այս տեղում է... սա Աստծո տունն է» (Ծննդոց 28:16-17)։",
            explanationRu: "Иаков воскликнул: «Истинно Господь присутствует на месте сем... это врата небесные!» (Бытие 28:16-17).",
            explanationEn: "Jacob awoke and declared: «Surely the Lord is in this place... this is the gate of heaven» (Genesis 28:16-17).",
            verseRefHy: "Ծննդոց 28:10-19",
            verseRefRu: "Бытие 28:10-19",
            verseRefEn: "Genesis 28:10-19"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ինչպե՞ս Եղիա մարգարեն համբարձվեց երկինք։",
            questionRu: "Каким чудесным образом ветхозаветный пророк Илия был взят на небо живым?",
            questionEn: "How was the Prophet Elijah taken up to heaven alive?",
            optionsHy: ["Հրեղեն կառքով և հրեղեն ձիերով մրրիկի մեջ", "Նավով", "Ամպերի վրա քնելով", "Հրեշտակի թևերով"],
            optionsRu: ["На огненной колеснице с огненными конями в вихре", "На золотом корабле", "Уснув на вершине горы", "На орлиных крыльях"],
            optionsEn: ["In a chariot of fire with horses of fire in a whirlwind", "On a golden boat", "Falling asleep on a mountain", "On eagle wings"],
            correctAnswerIndex: 0,
            explanationHy: "«Հրեղեն մի կառք և հրեղեն ձիեր երևացին, և Եղիան մրրիկով երկինք ելավ» (Դ Թագ. 2:11)։",
            explanationRu: "«Вдруг явилась колесница огненная и кони огненные... и понесся Илия в вихре на небо» (4 Царств 2:11).",
            explanationEn: "«A chariot of fire and horses of fire appeared... and Elijah went up by a whirlwind into heaven» (2 Kings 2:11).",
            verseRefHy: "Դ Թագավորաց 2:11",
            verseRefRu: "4 Царств 2:11",
            verseRefEn: "2 Kings 2:11"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .easy,
            questionHy: "Քանի՞ օր և գիշեր Հովնան մարգարեն մնաց մեծ ձկան փորում։",
            questionRu: "Сколько дней и ночей пророк Иона провел во чреве гигантской рыбы (кита)?",
            questionEn: "How many days and nights did the Prophet Jonah spend in the belly of the huge fish?",
            optionsHy: ["3 օր և 3 գիշեր", "7 օր և 7 գիշեր", "40 օր", "1 օր"],
            optionsRu: ["3 дня и 3 ночи", "7 дней и 7 ночей", "40 дней", "1 день"],
            optionsEn: ["3 days and 3 nights", "7 days and 7 nights", "40 days", "1 day"],
            correctAnswerIndex: 0,
            explanationHy: "Հովնանի 3-օրյա փորձությունը դարձավ Քրիստոսի եռօրյա թաղման և Հարության նախատիպը (Հովնան 2:1, Մատթ. 12:40)։",
            explanationRu: "Пребывание Ионы во чреве кита стало прообразом трехдневного погребения и Воскресения Спасителя (Иона 2:1).",
            explanationEn: "Jonah's three days in the fish foreshadowed Christ's resurrection on the third day (Jonah 1:17, Matthew 12:40).",
            verseRefHy: "Հովնան 2:1",
            verseRefRu: "Иона 2:1",
            verseRefEn: "Jonah 1:17"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Ո՞վ կառուցեց Երուսաղեմի Առաջին Շքեղ Տաճարը։",
            questionRu: "Кто из царей Израиля построил Первый Иерусалимский Храм?",
            questionEn: "Which King of Israel built the First Temple of Jerusalem?",
            optionsHy: ["Սողոմոն Իմաստուն արքան", "Դավիթ թագավորը", "Սավուղ թագավորը", "Եզեկիա թագավորը"],
            optionsRu: ["Царь Соломон Мудрый", "Царь Давид", "Царь Саул", "Царь Езекия"],
            optionsEn: ["King Solomon the Wise", "King David", "King Saul", "King Hezekiah"],
            correctAnswerIndex: 0,
            explanationHy: "Սողոմոն արքան կառուցեց Տիրոջ Տաճարը Լիբանանի մայրիներով և մաքուր ոսկով (Գ Թագ. 6)։",
            explanationRu: "Царь Соломон воздвиг великолепный Храм Господень на горе Мориа (3 Царств 6).",
            explanationEn: "King Solomon constructed the magnificent Temple for the Lord in Jerusalem (1 Kings 6).",
            verseRefHy: "Գ Թագավորաց 6:1-38",
            verseRefRu: "3 Царств 6:1-38",
            verseRefEn: "1 Kings 6:1-38"
        ),

        // =========================================================================
        // MARK: - РАСШИРЕНИЕ: ДОПОЛНИТЕЛЬНЫЕ ВОПРОСЫ (100+ ВОПРОСОВ)
        // =========================================================================
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Ո՞վ էր Պողոս առաքյալի ուղեկիցը, որի անունը նշանակում է «Մխիթարության որդի»։",
            questionRu: "Кто был верным спутником апостола Павла, чье имя означает «Сын утешения»?",
            questionEn: "Who was Paul's companion whose name means «Son of Encouragement»?",
            optionsHy: ["Սուրբ Բառնաբասը", "Սուրբ Սիղան", "Սուրբ Տիտոսը", "Սուրբ Մարկոսը"],
            optionsRu: ["Святой Варнава", "Святой Сила", "Святой Тит", "Святой Марк"],
            optionsEn: ["Saint Barnabas", "Saint Silas", "Saint Titus", "Saint Mark"],
            correctAnswerIndex: 0,
            explanationHy: "Հովսեփը, որ առաքյալների կողմից կոչվեց Բառնաբաս (որ թարգմանվում է Մխիթարության որդի) (Գործք 4:36)։",
            explanationRu: "Иосия, прозванный апостолами Варнавою (что значит — сын утешения) (Деяния 4:36).",
            explanationEn: "Joseph, a Levite from Cyprus, whom the apostles called Barnabas (which means «son of encouragement») (Acts 4:36).",
            verseRefHy: "Գործք 4:36",
            verseRefRu: "Деяния 4:36",
            verseRefEn: "Acts 4:36"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .hard,
            questionHy: "Ո՞ւմ մասին էր գրված Պողոս առաքյալի անձնական կարճ նամակը՝ Փիլիմոնին։",
            questionRu: "О чьей судьбе и прощении просил апостол Павел в кратком Послании к Филимону?",
            questionEn: "About whose reconciliation and forgiveness did Paul write in his Epistle to Philemon?",
            optionsHy: ["Փախստական ծառա Օնեսիմոսի", "Տիմոթեոսի", "Ղուկասի", "Ապողոսի"],
            optionsRu: ["О беглом рабе Онисиме, ставшем братом во Христе", "О Тимофее", "О Луке", "Об Аполлосе"],
            optionsEn: ["About Onesimus, the runaway slave who became a brother", "About Timothy", "About Luke", "About Apollos"],
            correctAnswerIndex: 0,
            explanationHy: "Պողոսը խնդրեց Փիլիմոնին ընդունել Օնեսիմոսին ոչ թե որպես ծառա, այլ «սիրելի եղբայր» (Փիլիմոն 1:16)։",
            explanationRu: "Павел просил принять Онисима «не как уже раба, но выше раба, брата возлюбленного» (Филимону 1:16).",
            explanationEn: "Paul urged Philemon to welcome Onesimus «no longer as a slave, but better than a slave, as a dear brother» (Philemon 1:16).",
            verseRefHy: "Փիլիմոն 1:10-18",
            verseRefRu: "Филимону 1:10-18",
            verseRefEn: "Philemon 1:10-18"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Ի՞նչ է ասում Պողոս առաքյալը մահացածների հարության մասին Ա Կորնթացիս 15-րդ գլխում։",
            questionRu: "С какими словами обращается апостол Павел к смерти в победной 15-й главе 1 Коринфянам?",
            questionEn: "With what victorious words does Paul address death in 1 Corinthians 15?",
            optionsHy: [
                "«Ո՞ւր է, մա՛հ, քո խայթոցը. ո՞ւր է, դժո՛խք, քո հաղթությունը»",
                "«Մահը հավերժական վերջ է»",
                "«Մենք չենք տեսնի հարություն»",
                "«Մահը անպարտելի է»"
            ],
            optionsRu: [
                "«Смерть! где твое жало? ад! где твоя победа?»",
                "«Смерть есть вечный конец всего»",
                "«Мы не увидим воскресения»",
                "«Смерть непобедима»"
            ],
            optionsEn: [
                "«Where, O death, is your victory? Where, O death, is your sting?»",
                "«Death is the final end»",
                "«We shall not see resurrection»",
                "«Death is unconquerable»"
            ],
            correctAnswerIndex: 0,
            explanationHy: "«Շնորհակալությո՛ւն Աստծուն, որ մեզ հաղթություն է տալիս մեր Տեր Հիսուս Քրիստոսի միջոցով» (Ա Կորնթ. 15:57)։",
            explanationRu: "«Благодарение Богу, даровавшему нам победу чрез Господа нашего Иисуса Христа!» (1 Кор 15:57).",
            explanationEn: "«Thanks be to God! He gives us the victory through our Lord Jesus Christ» (1 Cor 15:57).",
            verseRefHy: "Ա Կորնթացիս 15:55-57",
            verseRefRu: "1 Коринфянам 15:55-57",
            verseRefEn: "1 Corinthians 15:55-57"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .easy,
            questionHy: "Ինչպե՞ս է գալու Տիրոջ Օրը՝ ըստ Ա Թեսաղոնիկեցիս 5-րդ գլխի։",
            questionRu: "Как придет день Господень согласно 1-му Посланию к Фессалоникийцам?",
            questionEn: "How will the Day of the Lord come according to 1 Thessalonians 5?",
            optionsHy: ["Ինչպես գողը գիշերով (հանկարծակի)", "Որոտով ու ծանուցմամբ", "Հստակ հայտարարված ժամին", "Ամռան առաջին օրը"],
            optionsRu: ["Как тать (вор) ночью — внезапно", "С громом и предупреждением", "В строго объявленное время", "В первый день лета"],
            optionsEn: ["Like a thief in the night (suddenly)", "With prior thunder and warning", "At an announced time", "On the first day of summer"],
            correctAnswerIndex: 0,
            explanationHy: "«Դուք ինքներդ ստույգ գիտեք, որ Տիրոջ օրը գալիս է այնպես, ինչպես գողը գիշերով» (Ա Թեսաղ. 5:2)։",
            explanationRu: "«Ибо сами вы достоверно знаете, что день Господень так придет, как тать ночью» (1 Фесс 5:2).",
            explanationEn: "«For you know very well that the day of the Lord will come like a thief in the night» (1 Thess 5:2).",
            verseRefHy: "Ա Թեսաղոնիկեցիս 5:2",
            verseRefRu: "1 Фессалоникийцам 5:2",
            verseRefEn: "1 Thessalonians 5:2"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .hard,
            questionHy: "Քանի՞ ընդհանրական (կաթողիկե) թղթեր կան Նոր Կտակարանում։",
            questionRu: "Сколько Соборных посланий (Иакова, Петра, Иоанна, Иуды) входит в состав Нового Завета?",
            questionEn: "How many Catholic (General) Epistles are there in the New Testament?",
            optionsHy: ["7 թուղթ", "14 թուղթ", "4 թուղթ", "12 թուղթ"],
            optionsRu: ["7 посланий", "14 посланий", "4 послания", "12 посланий"],
            optionsEn: ["7 Epistles", "14 Epistles", "4 Epistles", "12 Epistles"],
            correctAnswerIndex: 0,
            explanationHy: "7 Ընդհանրական թղթերն են՝ Հակոբոսի (1), Պետրոսի (2), Հովհաննեսի (3) և Հուդայի (1)։",
            explanationRu: "7 Соборных посланий: Иакова (1), Петра (2), Иоанна (3) и Иуды (1).",
            explanationEn: "The 7 General Epistles include James (1), Peter (2), John (3), and Jude (1).",
            verseRefHy: "Նոր Կտակարանի Կանոն",
            verseRefRu: "Канон Нового Завета",
            verseRefEn: "New Testament Canon"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Ի՞նչ խորհուրդ տվեց Պողոս առաքյալը Հռոմեացիներին չարի դեմ պայքարելու համար (Հռոմ. 12:21)։",
            questionRu: "Какое наставление дает апостол Павел в борьбе со злом в Послании к Римлянам (Рим. 12:21)?",
            questionEn: "What instruction does Paul give for overcoming evil in Romans 12:21?",
            optionsHy: [
                "«Մի՛ հաղթվիր չարից, այլ բարիո՛վ հաղթիր չարին»",
                "«Չարին չարով պատասխանիր»",
                "«Հեռացիր աշխարհից»",
                "«Վրեժ լուծիր անհապաղ»"
            ],
            optionsRu: [
                "«Не будь побежден злом, но побеждай зло добром»",
                "«Отвечай злом на зло»",
                "«Убегай от людей»",
                "«Отомсти немедленно»"
            ],
            optionsEn: [
                "«Do not be overcome by evil, but overcome evil with good»",
                "«Repay evil with evil»",
                "«Flee from society»",
                "«Take revenge immediately»"
            ],
            correctAnswerIndex: 0,
            explanationHy: "«Մի՛ հաղթվիր չարից, այլ բարիո՛վ հաղթիր չարին» (Հռոմեացիս 12:21)։",
            explanationRu: "«Не будь побежден злом, но побеждай зло добром» (Рим 12:21).",
            explanationEn: "«Do not be overcome by evil, but overcome evil with good» (Romans 12:21).",
            verseRefHy: "Հռոմեացիս 12:21",
            verseRefRu: "Римлянам 12:21",
            verseRefEn: "Romans 12:21"
        ),
        QuizQuestion(
            category: .newTestament,
            difficulty: .medium,
            questionHy: "Ո՞ւմ հարություն տվեց Պետրոս առաքյալը Հոպպե քաղաքում (Գործք 9)։",
            questionRu: "Кого воскресил апостол Петр в Иоппии по горячим молитвам верующих?",
            questionEn: "Whom did Apostle Peter raise from the dead in Joppa through fervent prayer?",
            optionsHy: ["Բարեգործ Տաբիթային (Դորկասին)", "Մարիամին", "Սապֆիրային", "Եվնիկեին"],
            optionsRu: ["Благочестивую Тавифу (Серну)", "Марию", "Сапфиру", "Евнику"],
            optionsEn: ["Devout Tabitha (Dorcas)", "Mary", "Sapphira", "Eunice"],
            correctAnswerIndex: 0,
            explanationHy: "Տաբիթան լի էր բարի գործերով և ողորմությամբ. Պետրոսը աղոթեց և ասաց. «Տաբիթա՛, վե՛ր կաց» (Գործք 9:40)։",
            explanationRu: "Тавифа была полна добрых дел; Петр помолился, и она открыла глаза (Деяния 9:40).",
            explanationEn: "Tabitha was known for helping the poor; Peter prayed, saying: «Tabitha, get up!» (Acts 9:40).",
            verseRefHy: "Գործք 9:36-42",
            verseRefRu: "Деяния 9:36-42",
            verseRefEn: "Acts 9:36-42"
        ),

        // --- ДОПОЛНЕНИЕ АРМЯНСКОЙ ЦЕРКВИ ---
        QuizQuestion(
            category: .churchHistory,
            difficulty: .easy,
            questionHy: "Ո՞ր գետում Սուրբ Գրիգոր Լուսավորիչը մկրտեց Տրդատ արքային և հայ ժողովրդին։",
            questionRu: "В водах какой реки святой Григорий Просветитель крестил царя Трдата III, войско и армянский народ?",
            questionEn: "In the waters of which river did Saint Gregory the Illuminator baptize King Trdat III and the Armenian nation?",
            optionsHy: ["Արածանի (Եփրատի վտակ) գետում", "Արաքս գետում", "Հրազդան գետում", "Սևանա լճում"],
            optionsRu: ["В реке Арацани (Восточный Евфрат)", "В реке Аракс", "В реке Раздан", "В озере Севан"],
            optionsEn: ["In the Aratsani River (Eastern Euphrates)", "In the Aras River", "In the Hrazdan River", "In Lake Sevan"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Գրիգորը Արածանիի ջրերում մկրտեց արքայական ընտանիքին և հարյուր հազարավոր հայերի։",
            explanationRu: "В священных водах Арацани святитель крестил царя, царицу Ашхен, сестру Хосровадухт и народ.",
            explanationEn: "In the waters of the Aratsani River, Saint Gregory baptized the Royal Family and the army.",
            verseRefHy: "Ագաթանգեղոս (IV դար)",
            verseRefRu: "Агафангел (IV век)",
            verseRefEn: "Agathangelos (4th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Ո՞վ էր V դարի հայ առաջին կին սուրբ նահատակը, որը նախընտրեց հավատքը հանուն Քրիստոսի։",
            questionRu: "Какая святая армянская княгиня V века приняла мученический венец, отказавшись предать веру Христову?",
            questionEn: "Which 5th-century Armenian princess and saint chose martyrdom over renouncing her Christian faith?",
            optionsHy: ["Սուրբ Շուշանիկը", "Սուրբ Սանդուխտը", "Սուրբ Աշխենը", "Սուրբ Խոսրովիդուխտը"],
            optionsRu: ["Святая Шушаник (Вардени)", "Святая Сандухт", "Святая Ашхен", "Святая Хосровадухт"],
            optionsEn: ["Saint Shushanik (Vardeni)", "Saint Sandukht", "Saint Ashkhen", "Saint Khosrovidukht"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Շուշանիկը՝ Վարդան Մամիկոնյանի դուստրը, համբերատարությամբ կրեց չարչարանքները հանուն Քրիստոսի։",
            explanationRu: "Святая Шушаник, дочь Вардана Мамиконяна, явила образец несокрушимой стойкости веры.",
            explanationEn: "Saint Shushanik, daughter of Vardan Mamikonian, endured torture for her faith in Christ.",
            verseRefHy: "«Շուշանիկի Վկայաբանություն» (V դար)",
            verseRefRu: "«Мученичество Шушаник» (V век)",
            verseRefEn: "Martyrdom of Saint Shushanik (5th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .hard,
            questionHy: "Ո՞վ էր Հայ Եկեղեցու մեծ Իմաստասեր (Փիլիսոփա) Կաթողիկոսը (VIII դար)։",
            questionRu: "Какой католикос VIII века прозван «Философом» (Имастасер) и составил знаменитую «Книгу канонов» (Կանոնագիրք) Армянской Церкви?",
            questionEn: "Which 8th-century Catholicos was titled «The Philosopher» and compiled the «Book of Canons» of the Armenian Church?",
            optionsHy: ["Սուրբ Հովհան Օձնեցին", "Սուրբ Ներսես Շնորհալին", "Սուրբ Գրիգոր Լուսավորիչը", "Սուրբ Կոմիտասը"],
            optionsRu: ["Святой Ован Одзнеци", "Святой Нерсес Шнорали", "Святой Григорий Просветитель", "Святой Комитас Ахцеци"],
            optionsEn: ["Saint John of Otzun (Hovhan Odznetsi)", "Saint Nerses Shnorhali", "Saint Gregory the Illuminator", "Saint Komitas Akhtsetsi"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Հովհան Օձնեցի Հայրապետը համակարգեց Հայոց Կանոնագիրքը և գրեց հոգևոր շարականներ։",
            explanationRu: "Святой Иоанн Одзнеци составил Армянский Судебник-Канонагирк и созвал Двинский и Манцикертский соборы.",
            explanationEn: "Saint John of Otzun systematized the Armenian Book of Canons and composed deep spiritual hymns.",
            verseRefHy: "Հայոց Կանոնագիրք (VIII դար)",
            verseRefRu: "Армянский Канонагирк (VIII век)",
            verseRefEn: "Armenian Book of Canons (8th Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Ի՞նչ հոգևոր երգեր են «Շարականները» Հայ Առաքելական Եկեղեցում։",
            questionRu: "Что представляют собой священные «Шараканы» (Շարական) в богослужении Армянской Церкви?",
            questionEn: "What are «Sharakans» (Շարական) in the liturgical tradition of the Armenian Church?",
            optionsHy: ["Հոգևոր օրհներգեր և աղոթք-երգեր", "Եկեղեցական օրենքներ", "Պատմական տարեգրություններ", "Ճարտարապետական նախագծեր"],
            optionsRu: ["Канонические духовные песнопения и гимны", "Своды законов", "Летописные хроники", "Архитектурные чертежи"],
            optionsEn: ["Canonical spiritual hymns and canticles", "Legal codes", "Historical chronicles", "Architectural plans"],
            correctAnswerIndex: 0,
            explanationHy: "Շարականները (շարքով կանոնական երգեր) ստեղծվել են Մեսրոպ Մաշտոցի, Սահակ Պարթևի և Ներսես Շնորհալու կողմից։",
            explanationRu: "Шараканы — древние гимны, собранные в книге «Шаракноц», наполненные глубокой поэзией веры.",
            explanationEn: "Sharakans are ancient liturgical hymns composed by Armenian Church fathers and collected in the Sharaknots.",
            verseRefHy: "Շարակնոց (Հայ Եկեղեցու Երգարան)",
            verseRefRu: "Шаракноц (Книга Гимнов)",
            verseRefEn: "Sharaknots (Armenian Hymnal)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .hard,
            questionHy: "Ո՞ր հայոց արքայադուստրը դարձավ առաջին քրիստոնյա նահատակը 1-ին դարում՝ Թադեոս առաքյալի քարոզով։",
            questionRu: "Какая святая царевна стала первой мученицей в Армении в I веке, уверовав от проповеди апостола Фаддея?",
            questionEn: "Which royal princess became the first female martyr of Armenia in the 1st century through Apostle Thaddeus?",
            optionsHy: ["Սուրբ Սանդուխտ Կույսը", "Սուրբ Հռիփսիմեն", "Սուրբ Գայանեն", "Սուրբ Աշխենը"],
            optionsRu: ["Святая дева Сандухт (царевна)", "Святая Рипсиме", "Святая Гаяне", "Святая Ашхен"],
            optionsEn: ["Saint Sandukht the Virgin", "Saint Hripsime", "Saint Gayane", "Saint Ashkhen"],
            correctAnswerIndex: 0,
            explanationHy: "Սուրբ Սանդուխտը՝ Սանատրուկ թագավորի դուստրը, չուրացավ Քրիստոսին և նահատակվեց հավատքի համար։",
            explanationRu: "Святая Сандухт, дочь царя Санатрука, предпочла венец мученичества за Христа царским почестям.",
            explanationEn: "Saint Sandukht, daughter of King Sanatruk, embraced martyrdom for Christ in the 1st century.",
            verseRefHy: "Հայոց Վարք Սրբոց (I դար)",
            verseRefRu: "Жития Святых (I век)",
            verseRefEn: "Armenian Synaxarion (1st Century)"
        ),
        QuizQuestion(
            category: .churchHistory,
            difficulty: .medium,
            questionHy: "Ո՞ր տոնն է նվիրված Քրիստոսի Պայծառակերպությանը Հայ Եկեղեցում (ժողովրդական՝ Վարդավառ)։",
            questionRu: "Какой праздник Господень в Армянской Церкви посвящен Преображению Христа на горе Фавор (в народе Вардавар)?",
            questionEn: "Which Major Feast of the Armenian Church commemorates the Transfiguration of Jesus on Mount Tabor (Vardavar)?",
            optionsHy: ["Պայծառակերպություն Տեառն (Վարդավառ)", "Խաչվերաց", "Տյառնընդառաջ", "Համբարձում"],
            optionsRu: ["Преображение Господне (Вардавар)", "Воздвижение Креста", "Сретение (Тьярнэндарадж)", "Вознесение"],
            optionsEn: ["Feast of the Transfiguration (Vardavar)", "Exaltation of the Cross", "Presentation (Trndez)", "Ascension"],
            correctAnswerIndex: 0,
            explanationHy: "Պայծառակերպության տոնին Հիսուս Իր աստվածային փառքով պայծառացավ Թաբոր լեռան վրա (Մատթ. 17)։",
            explanationRu: "В праздник Преображения вспоминается явление Славы Божьей ученикам на горе Фавор (Матфея 17).",
            explanationEn: "The Transfiguration celebrates Christ revealing His divine glory to the apostles on Mount Tabor.",
            verseRefHy: "Մատթեոս 17:1-8",
            verseRefRu: "Матфея 17:1-8",
            verseRefEn: "Matthew 17:1-8"
        ),

        // --- ДОПОЛНЕНИЕ ЕВАНГЕЛИЙ И ВЕТХОГО ЗАВЕТА ---
        QuizQuestion(
            category: .gospels,
            difficulty: .easy,
            questionHy: "Ի՞նչ պատվիրեց Հիսուսը Երանիների մեջ՝ Լեռան Քարոզում (Մատթ. 5:3)։",
            questionRu: "Какое первое блаженство возвестил Спаситель в Нагорной проповеди (Матфея 5:3)?",
            questionEn: "What is the first Beatitude given by Jesus in the Sermon on the Mount (Matthew 5:3)?",
            optionsHy: [
                "«Երանի՜ հոգով աղքատներին, որովհետև նրանցն է երկնքի արքայությունը»",
                "«Երանի հարուստներին»",
                "«Երանի հզորներին»",
                "«Երանի հաղթողներին»"
            ],
            optionsRu: [
                "«Блаженны нищие духом, ибо их есть Царство Небесное»",
                "«Блаженны богатые»",
                "«Блаженны властвующие»",
                "«Блаженны победители»"
            ],
            optionsEn: [
                "«Blessed are the poor in spirit, for theirs is the kingdom of heaven»",
                "«Blessed are the rich»",
                "«Blessed are the mighty»",
                "«Blessed are the victors»"
            ],
            correctAnswerIndex: 0,
            explanationHy: "Հոգով աղքատ լինել նշանակում է լինել խոնարհ և ամեն բանում ապավինել Աստծո ողորմությանը։",
            explanationRu: "Нищета духа означает смирение, осознание своей зависимости от благодати Божьей.",
            explanationEn: "Poor in spirit refers to humble spiritual reliance on God's boundless grace.",
            verseRefHy: "Մատթեոս 5:3",
            verseRefRu: "Матфея 5:3",
            verseRefEn: "Matthew 5:3"
        ),
        QuizQuestion(
            category: .gospels,
            difficulty: .medium,
            questionHy: "Ի՞նչ հրաշք գործեց Հիսուսը Գենեսարեթի (Գալիլեայի) ծովի վրա փոթորկի ժամանակ։",
            questionRu: "Какое чудо совершил Иисус на Галилейском озере, когда лодка с учениками погибала от бури?",
            questionEn: "What miracle did Jesus perform on the Sea of Galilee during a violent storm?",
            optionsHy: ["Սաստեց քամուն և ալիքներին, և մեծ խաղաղություն տիրեց", "Լողալով ափ հասավ", "Նոր նավ ստեղծեց", "Կանչեց ձկներին"],
            optionsRu: ["Запретил ветру и волнам, и настала великая тишина", "Доплыл до берега вплавь", "Сотворил новый корабль", "Подозвал рыб"],
            optionsEn: ["Rebuked the wind and waves, and it was completely calm", "Swam to the shore", "Created a new boat", "Called the fish"],
            correctAnswerIndex: 0,
            explanationHy: "Հիսուսն ասաց. «Լռի՛ր, դադարի՛ր», և քամին դադարեց (Մարկոս 4:39)։",
            explanationRu: "Иисус сказал морю: «Умолкни, перестань!», и сделалась великая тишина (Марка 4:39).",
            explanationEn: "Jesus said to the waves: «Quiet! Be still!», and the wind died down (Mark 4:39).",
            verseRefHy: "Մարկոս 4:35-41",
            verseRefRu: "Марка 4:35-41",
            verseRefEn: "Mark 4:35-41"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .easy,
            questionHy: "Ո՞վ առաջնորդեց Իսրայելի ժողովրդին Եգիպտոսի ստրկությունից դեպի Կարմիր ծով։",
            questionRu: "Кто по повелению Божьему вывел израильский народ из египетского рабства через Красное море?",
            questionEn: "Who led the people of Israel out of Egyptian slavery through the parted Red Sea?",
            optionsHy: ["Սուրբ Մովսես մարգարեն", "Ահարոն քահանան", "Հեսու Նավեն", "Գեդեոնը"],
            optionsRu: ["Пророк Моисей Боговидец", "Аарон первосвященник", "Иисус Навин", "Гедеон"],
            optionsEn: ["Prophet Moses", "Aaron the Priest", "Joshua son of Nun", "Gideon"],
            correctAnswerIndex: 0,
            explanationHy: "Մովսեսը մեկնեց գավազանը, և Տերը բաժանեց Կարմիր ծովի ջրերը (Ելից 14)։",
            explanationRu: "Моисей простер руку свою на море, и расступились воды (Исход 14).",
            explanationEn: "Moses stretched out his hand over the sea, and the Lord divided the waters (Exodus 14).",
            verseRefHy: "Ելից 14:21-31",
            verseRefRu: "Исход 14:21-31",
            verseRefEn: "Exodus 14:21-31"
        ),
        QuizQuestion(
            category: .oldTestament,
            difficulty: .medium,
            questionHy: "Քանի՞ պատվիրաններ տվեց Աստված Մովսեսին Սինա լեռան վրա (Տասնաբանյա)։",
            questionRu: "Сколько священных заповедей (Декалог) начертал Господь на каменных скрижалях на горе Синай?",
            questionEn: "How many Commandments (the Decalogue) did God give Moses on Mount Sinai?",
            optionsHy: ["10 Պատվիրան", "12 պատվիրան", "7 պատվիրան", "40 պատվիրան"],
            optionsRu: ["10 Заповедей (Декалог)", "12 заповедей", "7 заповедей", "40 заповедей"],
            optionsEn: ["10 Commandments (Decalogue)", "12 commandments", "7 commandments", "40 commandments"],
            correctAnswerIndex: 0,
            explanationHy: "Տասը Պատվիրանները տրվեցին քարե տախտակների վրա Սինա լեռան վրա (Ելից 20)։",
            explanationRu: "Десять Заповедей стали священным нравственным законом Завета (Исход 20).",
            explanationEn: "The Ten Commandments were inscribed on stone tablets at Mount Sinai (Exodus 20).",
            verseRefHy: "Ելից 20:1-17",
            verseRefRu: "Исход 20:1-17",
            verseRefEn: "Exodus 20:1-17"
        )
    ]
}
