import Foundation
import SwiftUI
import Combine

// MARK: - Стадии Роста Гранатового Древа (Pomegranate Growth Stage)
enum PomegranateStage: Int, CaseIterable, Codable, Comparable, Identifiable {
    case seed = 1         // 1-2 дня: Семя веры
    case sprout = 2       // 3-6 дней: Нежный росток
    case youngTree = 3    // 7-13 дней: Крепнущее деревце
    case bloomingTree = 4 // 14-29 дней: Цветущий гранат (алые цветы)
    case fruitfulTree = 5 // 30-59 дней: Плодоносящее древо (спелые плоды)
    case treeOfLife = 6   // 60+ дней: Величественное Древо Жизни

    var id: Int { rawValue }

    static func < (lhs: PomegranateStage, rhs: PomegranateStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func stage(forDays days: Int) -> PomegranateStage {
        switch days {
        case ..<3: return .seed
        case 3...6: return .sprout
        case 7...13: return .youngTree
        case 14...29: return .bloomingTree
        case 30...59: return .fruitfulTree
        default: return .treeOfLife
        }
    }

    var requiredDays: Int {
        switch self {
        case .seed: return 1
        case .sprout: return 3
        case .youngTree: return 7
        case .bloomingTree: return 14
        case .fruitfulTree: return 30
        case .treeOfLife: return 60
        }
    }

    var nextStageTargetDays: Int {
        switch self {
        case .seed: return 3
        case .sprout: return 7
        case .youngTree: return 14
        case .bloomingTree: return 30
        case .fruitfulTree: return 60
        case .treeOfLife: return 100
        }
    }

    func title(for lang: AppLanguage) -> String {
        switch self {
        case .seed:
            switch lang {
            case .armenian: return "Հավատքի Սերմ"
            case .russian: return "Зёрнышко веры"
            case .english: return "Seed of Faith"
            }
        case .sprout:
            switch lang {
            case .armenian: return "Դալար Ծիլ"
            case .russian: return "Нежный росток"
            case .english: return "Tender Sprout"
            }
        case .youngTree:
            switch lang {
            case .armenian: return "Զորացող Տնկի"
            case .russian: return "Крепнущее деревце"
            case .english: return "Growing Tree"
            }
        case .bloomingTree:
            switch lang {
            case .armenian: return "Ծաղկած Նռնենի"
            case .russian: return "Цветущий гранат"
            case .english: return "Blooming Pomegranate"
            }
        case .fruitfulTree:
            switch lang {
            case .armenian: return "Պտղաբեր Նռնենի"
            case .russian: return "Плодоносящее древо"
            case .english: return "Fruitful Pomegranate"
            }
        case .treeOfLife:
            switch lang {
            case .armenian: return "Կենաց Ծառ"
            case .russian: return "Древо Жизни"
            case .english: return "Sacred Tree of Life"
            }
        }
    }

    func description(for lang: AppLanguage) -> String {
        switch self {
        case .seed:
            switch lang {
            case .armenian: return "Սերմը խոնարհաբար արմատավորվում է բարեբեր հողում:"
            case .russian: return "Семя слова Божьего пускает первые корни в доброй почве сердца."
            case .english: return "The seed of God's Word takes root in the faithful ground of the heart."
            }
        case .sprout:
            switch lang {
            case .armenian: return "Առաջին կանաչ տերևները ձգվում են դեպի Երկնային Լույսը:"
            case .russian: return "Первые изумрудные листья тянутся к небесному свету. Ваша вера крепнет."
            case .english: return "Tender green leaves stretch toward Heavenly Light. Faith is taking root."
            }
        case .youngTree:
            switch lang {
            case .armenian: return "Ճյուղերը զորանում են՝ դիմանալով կյանքի հողմերին:"
            case .russian: return "Ветви крепнут и выдерживают ветра суеты. На ветвях завязываются бутоны."
            case .english: return "Branches grow strong against life's winds. First buds begin to form."
            }
        case .bloomingTree:
            switch lang {
            case .armenian: return "Հրաշագեղ նռան կարմիր ծաղիկները բուրում են աղոթքի մեջ:"
            case .russian: return "Дерево покрылось дивными рубиновыми цветами граната. Аура молитвы наполняет дом."
            case .english: return "The tree bursts with royal ruby blossoms. Prayer fills your days with grace."
            }
        case .fruitfulTree:
            switch lang {
            case .armenian: return "Հասունացել են 365 հատիկներով օրհնված նռան պտուղները:"
            case .russian: return "Созрели царственные плоды с рубиновыми зёрнами. Ваше постоянство приносит плоды."
            case .english: return "Blessed ruby fruits are ripe with grace. Faithfulness yields holy harvest."
            }
        case .treeOfLife:
            switch lang {
            case .armenian: return "Անսասան Կենաց Ծառ՝ ոսկեզօծ լույսով և երկնային օրհնությամբ:"
            case .russian: return "Непоколебимое Древо Жизни в золотом сиянии благодати. «Праведник цветет, как пальма»."
            case .english: return "Unshakable Tree of Life radiating golden grace. 'The righteous flourish like palm trees'."
            }
        }
    }
}

// MARK: - Плоды Святого Духа (Галатам 5:22-23)
struct SpiritualFruit: Identifiable, Codable, Hashable {
    let id: Int
    let icon: String
    let nameHy: String
    let nameRu: String
    let nameEn: String
    let scriptureRef: String
    let scriptureHy: String
    let scriptureRu: String
    let scriptureEn: String
    let blessingHy: String
    let blessingRu: String
    let blessingEn: String

    func name(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return nameHy
        case .russian: return nameRu
        case .english: return nameEn
        }
    }

    func scripture(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return scriptureHy
        case .russian: return scriptureRu
        case .english: return scriptureEn
        }
    }

    func blessing(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return blessingHy
        case .russian: return blessingRu
        case .english: return blessingEn
        }
    }
}

// MARK: - Центральный Менеджер Гранатового Древа Духовного Роста
@MainActor
final class PomegranateTreeManager: ObservableObject {
    static let shared = PomegranateTreeManager()

    // MARK: - Хранилище (UserDefaults / AppGroup)
    private var defaults: UserDefaults {
        AppGroupConstants.sharedDefaults
    }

    private let kTotalSeedsKey = "pomegranate_total_seeds_count"
    private let kLastWateredDateKey = "pomegranate_last_watered_date"
    private let kCollectedFruitsKey = "pomegranate_collected_fruit_ids"
    private let kTreeDaysStreakKey = "pomegranate_tree_days_streak"

    // MARK: - Опубликованные свойства
    @Published var totalSeeds: Int = 0
    @Published var daysStreak: Int = 0
    @Published var isWateredToday: Bool = false
    @Published var isThirstingForDew: Bool = false
    @Published var selectedFruit: SpiritualFruit? = nil
    @Published var isShowingSanctuarySheet: Bool = false
    @Published var newlyWateredTrigger: Bool = false

    // 9 Плодов Духа
    let spiritualFruits: [SpiritualFruit] = [
        SpiritualFruit(
            id: 1,
            icon: "heart.fill",
            nameHy: "Սեր",
            nameRu: "Любовь",
            nameEn: "Love",
            scriptureRef: "Ա Կորնթ. 13:4-7",
            scriptureHy: "«Սէրը երկայնամիտ է, քաղցր է. սէրը չի նախանձում, չի ամբարտաւանանում...»",
            scriptureRu: "«Любовь долготерпит, милосердствует, любовь не завидует, любовь не превозносится...»",
            scriptureEn: "«Love is patient, love is kind. It does not envy, it does not boast...»",
            blessingHy: "Թող Աստծո անսահման սերը ջերմացնի ձեր սիրտն ու ընտանիքը:",
            blessingRu: "Пусть безграничная любовь Христа согревает ваше сердце и близких.",
            blessingEn: "May the boundless love of Christ warm your heart and household."
        ),
        SpiritualFruit(
            id: 2,
            icon: "sun.max.fill",
            nameHy: "Խնդություն",
            nameRu: "Радость",
            nameEn: "Joy",
            scriptureRef: "Փիլիպ. 4:4",
            scriptureHy: "«Ուրա՛խ եղէք Տիրոջով ամէն ժամ. դարձեալ ասում եմ՝ ուրա՛խ եղէք:»",
            scriptureRu: "«Радуйтесь всегда в Господе; и еще говорю: радуйтесь.»",
            scriptureEn: "«Rejoice in the Lord always. I will say it again: Rejoice!»",
            blessingHy: "Երկնային խնդությունը թող փարատի ամեն տխրություն ձեր հոգուց:",
            blessingRu: "Пусть небесная радость развеет всякую печаль и уныние из вашей души.",
            blessingEn: "May divine joy dispel every sorrow and anxiety from your soul."
        ),
        SpiritualFruit(
            id: 3,
            icon: "water.waves",
            nameHy: "Խաղաղություն",
            nameRu: "Мир",
            nameEn: "Peace",
            scriptureRef: "Յովհ. 14:27",
            scriptureHy: "«Խաղաղութիւն եմ թողնում ձեզ, իմ խաղաղութիւնն եմ տալիս ձեզ...»",
            scriptureRu: "«Мир оставляю вам, мир Мой даю вам; не так, как мир дает, Я даю вам.»",
            scriptureEn: "«Peace I leave with you; my peace I give you. I do not give as the world gives.»",
            blessingHy: "Տիրոջ խաղաղությունը, որ վեր է ամեն մտքից, թող պահպանի ձեզ:",
            blessingRu: "Мир Божий, который превыше всякого ума, да сохранит ваше сердце.",
            blessingEn: "May the peace of God, which transcends all understanding, guard your heart."
        ),
        SpiritualFruit(
            id: 4,
            icon: "hourglass",
            nameHy: "Երկայնամտություն",
            nameRu: "Долготерпение",
            nameEn: "Patience",
            scriptureRef: "Եփես. 4:2",
            scriptureHy: "«Կատարեալ խոնարհութեամբ, հեզութեամբ եւ համբերատարութեամբ հանդուրժելով միմեանց...»",
            scriptureRu: "«Со всяким смиренномудрием и кротостью и долготерпением, снисходя друг ко другу с любовью...»",
            scriptureEn: "«Be completely humble and gentle; be patient, bearing with one another in love...»",
            blessingHy: "Համբերությունը ձեր հոգուն տալիս է անսասան զորություն և իմաստություն:",
            blessingRu: "Божественное терпение дарует вашей душе непоколебимую мудрость и силу.",
            blessingEn: "Divine patience grants your spirit unyielding wisdom and inner strength."
        ),
        SpiritualFruit(
            id: 5,
            icon: "hand.raised.fill",
            nameHy: "Քաղցրություն",
            nameRu: "Благость",
            nameEn: "Kindness",
            scriptureRef: "Հռոմ. 12:21",
            scriptureHy: "«Մի՛ յաղթուիր չարից, այլ բարիո՛վ յաղթիր չարին:»",
            scriptureRu: "«Не будь побежден злом, но побеждай зло добром.»",
            scriptureEn: "«Do not be overcome by evil, but overcome evil with good.»",
            blessingHy: "Քաղցրությունը թող դառնա ձեր ամեն մի խոսքի և գործի լույսը:",
            blessingRu: "Пусть сердечная доброта будет светом каждого вашего поступка.",
            blessingEn: "May gentle kindness be the radiant light of your words and deeds."
        ),
        SpiritualFruit(
            id: 6,
            icon: "gift.fill",
            nameHy: "Բարություն",
            nameRu: "Милосердие",
            nameEn: "Goodness",
            scriptureRef: "Միքիա 6:8",
            scriptureHy: "«Մարդ, քեզ յայտնուել է, թէ ինչն է բարին... արդարութի՛ւն անել, սիրե՛լ ողորմութիւնը...»",
            scriptureRu: "«О, человек! сказано тебе, что — добро и чего требует от тебя Господь: действовать справедливо, любить дела милосердия...»",
            scriptureEn: "«He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy...»",
            blessingHy: "Ձեր բարի գործերը երկնքում թող պտուղներ տան և փառավորեն Տիրոջը:",
            blessingRu: "Ваши дела милосердия да принесут вечный плод в Царствии Небесном.",
            blessingEn: "May your deeds of merciful goodness bear eternal fruit before God."
        ),
        SpiritualFruit(
            id: 7,
            icon: "sparkles",
            nameHy: "Հավատ",
            nameRu: "Вера",
            nameEn: "Faithfulness",
            scriptureRef: "Եբր. 11:1",
            scriptureHy: "«Հաւատն ապացոյցն է այն բաների, որոնք չեն երեւում, բայց յուսացւում են:»",
            scriptureRu: "«Вера же есть осуществление ожидаемого и уверенность в невидимом.»",
            scriptureEn: "«Now faith is confidence in what we hope for and assurance about what we do not see.»",
            blessingHy: "Անսասան հավատքը թող լինի ձեր կյանքի ամուր վահանն ու հենարանը:",
            blessingRu: "Непоколебимая вера да пребудет вашим щитом и твердой опорой во всем.",
            blessingEn: "Unshakable faith will ever be your fortress, shield, and constant guide."
        ),
        SpiritualFruit(
            id: 8,
            icon: "leaf.fill",
            nameHy: "Հեզություն",
            nameRu: "Кротость",
            nameEn: "Gentleness",
            scriptureRef: "Մատթ. 11:29",
            scriptureHy: "«Եկէք ինձ մօտ... սորվեցէ՛ք ինձնից, որ հեզ եմ եւ սրտով խոնարհ...»",
            scriptureRu: "«Возьмите иго Мое на себя и научитесь от Меня, ибо Я кроток и смирен сердцем, и найдете покой душам вашим.»",
            scriptureEn: "«Take my yoke upon you and learn from me, for I am gentle and humble in heart, and you will find rest for your souls.»",
            blessingHy: "Խոնարհ ու հեզ սիրտը գտնում է խորագույն խաղաղություն Տիրոջ մոտ:",
            blessingRu: "Кроткое и смиренное сердце обретает истинный небесный покой.",
            blessingEn: "A gentle and humble spirit finds restful serenity in the Lord."
        ),
        SpiritualFruit(
            id: 9,
            icon: "shield.fill",
            nameHy: "Ժուժկալություն",
            nameRu: "Воздержание",
            nameEn: "Self-control",
            scriptureRef: "Բ Տիմոթ. 1:7",
            scriptureHy: "«Որովհետեւ Աստուած մեզ երկչոտութեան ոգի չտուեց, այլ՝ զօրութեան, սիրոյ եւ ողջախոհութեան:»",
            scriptureRu: "«Ибо дал нам Бог духа не боязни, но силы и любви и целомудрия.»",
            scriptureEn: "«For the Spirit God gave us does not make us timid, but gives us power, love and self-discipline.»",
            blessingHy: "Հոգու զորությունն ու ժուժկալությունը ձեզ տանում են դեպի սրբություն:",
            blessingRu: "Духовная трезвость и целомудрие сохранят ваш путь чистым и благословенным.",
            blessingEn: "Spiritual strength and sober self-discipline guard your sacred journey."
        )
    ]

    private init() {
        loadState()
        refreshDewAndStreakStatus()
    }

    // MARK: - Текущая Стадия Древа
    var currentStage: PomegranateStage {
        PomegranateStage.stage(forDays: max(1, daysStreak))
    }

    // Прогресс до следующей стадии (0.0 - 1.0)
    var progressToNextStage: Double {
        let currentReq = currentStage.requiredDays
        let nextTarget = currentStage.nextStageTargetDays
        guard nextTarget > currentReq else { return 1.0 }
        let currentInStage = max(0, daysStreak - currentReq)
        let totalSpan = nextTarget - currentReq
        return min(1.0, Double(currentInStage) / Double(totalSpan))
    }

    // Количество видимых созревших плодов на дереве
    var visibleFruitsCount: Int {
        switch currentStage {
        case .seed, .sprout: return 0
        case .youngTree: return 1
        case .bloomingTree: return 3
        case .fruitfulTree: return 6
        case .treeOfLife: return 9
        }
    }

    // MARK: - Загрузка состояния
    private func loadState() {
        self.totalSeeds = defaults.integer(forKey: kTotalSeedsKey)
        let savedStreak = defaults.integer(forKey: kTreeDaysStreakKey)
        
        // Синхронизируем со стриком планов чтения, если он больше
        let readingStreak = ReadingPlanManager.shared.currentStreak
        self.daysStreak = max(savedStreak, readingStreak)
        if self.daysStreak == 0 {
            self.daysStreak = 1 // Стартовое семя веры
        }
        if self.totalSeeds == 0 {
            self.totalSeeds = max(1, self.daysStreak)
        }
    }

    // MARK: - Проверка статуса росы и стрика (Закон Милосердия)
    func refreshDewAndStreakStatus() {
        guard let lastDate = defaults.object(forKey: kLastWateredDateKey) as? Date else {
            self.isWateredToday = false
            self.isThirstingForDew = false
            return
        }

        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) {
            self.isWateredToday = true
            self.isThirstingForDew = false
        } else if calendar.isDateInYesterday(lastDate) {
            // Вчера поливали, сегодня еще нет — дерево ждет росы
            self.isWateredToday = false
            self.isThirstingForDew = false
        } else {
            // Пропущено больше 1 дня: Дерево НЕ ПОГИБАЕТ, но переходит в режим «Жаждет росы»
            self.isWateredToday = false
            self.isThirstingForDew = true
        }
    }

    // MARK: - Омовение Древа Небесной Росой (Питание веры)
    /// Вызывается при чтении стиха дня, завершении чтения главы, зажжении свечи или по тапу на росу
    func nourishWithDew(amount: Int = 1) {
        let calendar = Calendar.current
        let today = Date()

        if !isWateredToday {
            daysStreak += 1
            isWateredToday = true
            isThirstingForDew = false
            defaults.set(today, forKey: kLastWateredDateKey)
            defaults.set(daysStreak, forKey: kTreeDaysStreakKey)
        }

        totalSeeds += amount
        defaults.set(totalSeeds, forKey: kTotalSeedsKey)

        // Мягкая праздничная анимация
        newlyWateredTrigger.toggle()

        // Тактильный благородный отклик
        Haptics.notify(.success)
    }

    // Открыть модальное окно Древа
    func openSanctuary() {
        Haptics.impact(.soft)
        self.isShowingSanctuarySheet = true
    }
}
