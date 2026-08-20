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
        verseRefEn: String
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
        )
    ]
}
