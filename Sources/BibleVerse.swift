import Foundation

// MARK: - Модель библейского текста (стиха или молитвы)
struct BibleVerse: Identifiable, Codable, Hashable {
    let id: UUID
    let textHy: String
    let textRu: String
    let textEn: String
    let refHy: String
    let refRu: String
    let refEn: String
    let isPrayer: Bool
    
    var text: String {
        let savedLang = UserDefaults(suiteName: "group.com.samvel.ArmenianBible")?.string(forKey: "app_language")
        let lang = savedLang ?? Bundle.main.preferredLocalizations.first ?? "hy"
        if lang.hasPrefix("ru") || lang == "russian" {
            return textRu
        } else if lang.hasPrefix("en") || lang == "english" {
            return textEn
        } else {
            return textHy
        }
    }
    
    var reference: String {
        let savedLang = UserDefaults(suiteName: "group.com.samvel.ArmenianBible")?.string(forKey: "app_language")
        let lang = savedLang ?? Bundle.main.preferredLocalizations.first ?? "hy"
        if lang.hasPrefix("ru") || lang == "russian" {
            return refRu
        } else if lang.hasPrefix("en") || lang == "english" {
            return refEn
        } else {
            return refHy
        }
    }
    
    init(id: UUID = UUID(), textHy: String, textRu: String, textEn: String, refHy: String, refRu: String, refEn: String, isPrayer: Bool = false) {
        self.id = id
        self.textHy = textHy
        self.textRu = textRu
        self.textEn = textEn
        self.refHy = refHy
        self.refRu = refRu
        self.refEn = refEn
        self.isPrayer = isPrayer
    }
    
    // Для обратной совместимости с UserDefaults (когда сохранены старые стихи)
    init(id: UUID = UUID(), text: String, reference: String, isPrayer: Bool = false) {
        self.id = id
        self.textHy = text
        self.textRu = text
        self.textEn = text
        self.refHy = reference
        self.refRu = reference
        self.refEn = reference
        self.isPrayer = isPrayer
    }
    
    enum CodingKeys: String, CodingKey {
        case id, textHy, textRu, textEn, refHy, refRu, refEn, isPrayer, text, reference
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.isPrayer = try container.decodeIfPresent(Bool.self, forKey: .isPrayer) ?? false
        
        if let hyText = try container.decodeIfPresent(String.self, forKey: .textHy),
           let ruText = try container.decodeIfPresent(String.self, forKey: .textRu),
           let enText = try container.decodeIfPresent(String.self, forKey: .textEn),
           let hyRef = try container.decodeIfPresent(String.self, forKey: .refHy),
           let ruRef = try container.decodeIfPresent(String.self, forKey: .refRu),
           let enRef = try container.decodeIfPresent(String.self, forKey: .refEn) {
            self.textHy = hyText
            self.textRu = ruText
            self.textEn = enText
            self.refHy = hyRef
            self.refRu = ruRef
            self.refEn = enRef
        } else {
            let text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
            let reference = try container.decodeIfPresent(String.self, forKey: .reference) ?? ""
            self.textHy = text
            self.textRu = text
            self.textEn = text
            self.refHy = reference
            self.refRu = reference
            self.refEn = reference
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(textHy, forKey: .textHy)
        try container.encode(textRu, forKey: .textRu)
        try container.encode(textEn, forKey: .textEn)
        try container.encode(refHy, forKey: .refHy)
        try container.encode(refRu, forKey: .refRu)
        try container.encode(refEn, forKey: .refEn)
        try container.encode(isPrayer, forKey: .isPrayer)
        // Для совместимости при чтении старым кодом
        try container.encode(text, forKey: .text)
        try container.encode(reference, forKey: .reference)
    }
}

// MARK: - Языки приложения
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case armenian = "armenian"
    case russian = "russian"
    case english = "english"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .armenian: return "Հայերեն"
        case .russian: return "Русский"
        case .english: return "English"
        }
    }
    
    var localeCode: String {
        switch self {
        case .armenian: return "hy"
        case .russian: return "ru"
        case .english: return "en"
        }
    }
}

// MARK: - Провайдеры искусственного интеллекта
enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case gemini = "gemini"
    case chatgpt = "chatgpt"
    case claude = "claude"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .gemini: return "Gemini"
        case .chatgpt: return "ChatGPT"
        case .claude: return "Claude"
        }
    }
}

// MARK: - Категория отображаемого текста
enum TextCategory: String, CaseIterable, Identifiable, Codable {
    case verses = "verses"
    case prayers = "prayers"
    case favorites = "favorites"
    case both = "both"
    
    var id: String { self.rawValue }
    
    var titleArmenian: String {
        switch self {
        case .verses: return "Աստվածաշունչ"
        case .prayers: return "Աղոթքներ"
        case .favorites: return "Ընտրյալներ"
        case .both: return "Խառը"
        }
    }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .verses: return "category_verses".localized(for: language)
        case .prayers: return "category_prayers".localized(for: language)
        case .favorites: return "category_favorites".localized(for: language)
        case .both: return "category_both".localized(for: language)
        }
    }
}

// MARK: - Цветовые темы оформления
enum AccentColorTheme: String, CaseIterable, Identifiable, Codable {
    case indigo = "indigo"
    case gold = "gold"
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    
    var id: String { self.rawValue }
    
    func localizedName(for language: AppLanguage) -> String {
        switch self {
        case .indigo: return "color_indigo".localized(for: language)
        case .gold: return "color_gold".localized(for: language)
        case .blue: return "color_blue".localized(for: language)
        case .green: return "color_green".localized(for: language)
        case .purple: return "color_purple".localized(for: language)
        }
    }
    
    var colorHex: String {
        switch self {
        case .indigo: return "6366F1"
        case .gold: return "D97706"
        case .blue: return "0EA5E9"
        case .green: return "10B981"
        case .purple: return "8B5CF6"
        }
    }
    
    var secondaryColorHex: String {
        switch self {
        case .indigo: return "818CF8"
        case .gold: return "FBBF24"
        case .blue: return "38BDF8"
        case .green: return "34D399"
        case .purple: return "A78BFA"
        }
    }
}

// MARK: - Интервал обновления стихов
enum UpdateInterval: String, CaseIterable, Identifiable, Codable {
    case everyHour = "everyHour"
    case every6Hours = "every6Hours"
    case every12Hours = "every12Hours"
    case every24Hours = "every24Hours"
    case onScreenActivation = "onScreenActivation"
    case onTapOnly = "onTapOnly"
    
    var id: String { self.rawValue }
    
    var titleArmenian: String {
        switch self {
        case .everyHour: return "Ամեն ժամ"
        case .every6Hours: return "6 ժամը մեկ"
        case .every12Hours: return "12 ժամը մեկ"
        case .every24Hours: return "Օրական 1 անգամ"
        case .onScreenActivation: return "Ակտիվացումով (հավելվածում)"
        case .onTapOnly: return "Միայն հպումով"
        }
    }
    
    func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .everyHour: return "interval_every_hour".localized(for: language)
        case .every6Hours: return "interval_every_6_hours".localized(for: language)
        case .every12Hours: return "interval_every_12_hours".localized(for: language)
        case .every24Hours: return "interval_every_24_hours".localized(for: language)
        case .onScreenActivation: return "interval_on_screen_activation".localized(for: language)
        case .onTapOnly: return "interval_on_tap_only".localized(for: language)
        }
    }
}

// MARK: - База данных библейских стихов и молитв (на армянском, русском и английском)
extension BibleVerse {
    static let database: [BibleVerse] = [
        BibleVerse(
            textHy: "Որովհետև Աստված այնքան սիրեց աշխարհը, որ իր միածին Որդուն տվեց, որպեսզի ամեն նրան հավատացողը չկորչի, այլ հավիտենական կյանք ունենա։",
            textRu: "Ибо так возлюбил Бог мир, что отдал Сына Своего Единородного, дабы всякий верующий в Него не погиб, но имел жизнь вечную.",
            textEn: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            refHy: "Հովհաննես 3:16",
            refRu: "Иоанна 3:16",
            refEn: "John 3:16"
        ),
        BibleVerse(
            textHy: "Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։ Կանաչ մարգագետիններում նա ինձ պառկեցնում է և հանդարտ ջрերի մոտ է տանում ինձ։",
            textRu: "Господь — Пастырь мой; я ни в чем не буду нуждаться. Он покоит меня на злачных пажитях и водит меня к водам тихим.",
            textEn: "The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters.",
            refHy: "Սաղմոսներ 23:1-2",
            refRu: "Псалом 22:1-2",
            refEn: "Psalm 23:1-2"
        ),
        BibleVerse(
            textHy: "Չէ՞ որ ես քեզ պատվիրեցի. զորացի՛ր և քա՛ջ եղիր, մի՛ վախեցիր և մի՛ զարհուրիր, որովհետև քո Տեր Աստվածը քեզ հետ է ամեն տեղ, ուր էլ որ գնաս։",
            textRu: "Вот Я повелеваю тебе: будь тверд и мужествен, не страшись и не ужасаяся; ибо с тобою Господь Бог твой везде, куда ни пойдешь.",
            textEn: "Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the Lord thy God is with thee whithersoever thou goest.",
            refHy: "Հեսու 1:9",
            refRu: "Иисус Навин 1:9",
            refEn: "Joshua 1:9"
        ),
        BibleVerse(
            textHy: "Ամբողջ սրտովդ Տիրոջն ապավինիր և քո սեփական հասկացողությանը մի՛ վստահիր։ Քո բոլոր ճանապարհներին ճանաչի՛ր նրան, և նա կուղղի քո շավիղները։",
            textRu: "Надейся на Господа всем сердцем твоим, и не полагайся на разум твой. Во всех путях твоих познавай Его, и Он направит стези твои.",
            textEn: "Trust in the Lord with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.",
            refHy: "Առակաց 3:5-6",
            refRu: "Притчи 3:5-6",
            refEn: "Proverbs 3:5-6"
        ),
        BibleVerse(
            textHy: "Ամեն ինչ կարող եմ ինձ զորացնող Քրիստոսի միջոցով։",
            textRu: "Все могу в укрепляющем меня Иисусе Христе.",
            textEn: "I can do all things through Christ which strengtheneth me.",
            refHy: "Փիլիպպեցիներին 4:13",
            refRu: "Филиппийцам 4:13",
            refEn: "Philippians 4:13"
        ),
        BibleVerse(
            textHy: "Գիտենք նաև, որ Աստծուն սիրողներին ամեն ինչ գործակից է լինում բարու համար, նրանց, որ կանչվեցին նրա նախասահմանումով։",
            textRu: "Притом знаем, что любящим Бога, призванным по Его изволению, все содействует ко благу.",
            textEn: "And we know that all things work together for good to them that love God, to them who are the called according to his purpose.",
            refHy: "Հռոմեացիներին 8:28",
            refRu: "Римлянам 8:28",
            refEn: "Romans 8:28"
        ),
        BibleVerse(
            textHy: "Որովհետև ես գիտեմ այն խորհուրդները, որ խորհում եմ ձեր մասին,- ասում է Տերը,- խաղաղության խորհուրդներ և ոչ թե չարիքի, որպեսզի ձեզ ապագա և հույս տամ։",
            textRu: "Ибо только Я знаю намерения, какие имею о вас, говорит Господь, намерения во благо, а не на зло, чтобы дать вам будущность и надежду.",
            textEn: "For I know the thoughts that I think toward you, saith the Lord, thoughts of peace, and not of evil, to give you an expected end.",
            refHy: "Երեմիա 29:11",
            refRu: "Иеремия 29:11",
            refEn: "Jeremiah 29:11"
        ),
        BibleVerse(
            textHy: "Եվ մի՛ կերպարանվեք այս աշխարհի կերպարանքով, այլ նորոգվե՛ք ձեր մտքի նորոգությամբ, որպեսզի քննեք, թե ի՛նչ է Աստծու կամքը՝ բարին, հաճելին և կատարյալը։",
            textRu: "И не сообразуйтесь с веком сим, но преобразуйтесь обновлением ума вашего, чтобы вам познавать, что есть воля Божия, благая, угодная и совершенная.",
            textEn: "And be not conformed to this world: but be ye transformed by the renewing of your mind, that ye may prove what is that good, and acceptable, and perfect, will of God.",
            refHy: "Հռոմեացիներին 12:2",
            refRu: "Римлянам 12:2",
            refEn: "Romans 12:2"
        ),
        BibleVerse(
            textHy: "Իսկ Հոգու պտուղն է՝ սեր, ուրախություն, խաղաղություն, երկայնամտություն, քաղցրություն, բարություն, հավատարմություն, հեզություն, ժուժկալություն։",
            textRu: "Плод же духа: любовь, радость, мир, долготерпение, благость, милосердие, вера, кротость, воздержание.",
            textEn: "But the fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith, meekness, temperance.",
            refHy: "Գաղատացիներին 5:22-23",
            refRu: "Галатам 5:22-23",
            refEn: "Galatians 5:22-23"
        ),
        BibleVerse(
            textHy: "Քո խոսքը ճրագ է իմ ոտքերի համար և լույս՝ իմ շավիղների համար։",
            textRu: "Слово Твое — светильник ноге моей и свет стезе моей.",
            textEn: "Thy word is a lamp unto my feet, and a light unto my path.",
            refHy: "Սաղմոսներ 119:105",
            refRu: "Псалом 118:105",
            refEn: "Psalm 119:105"
        ),
        BibleVerse(
            textHy: "Ինձ մո՛տ եկեք, բոլոր հոգնածներ ու բեռնավորվածներ, և ես ձեզ կհանգստացնեմ։",
            textRu: "Придите ко Мне все труждающиеся и обремененные, и Я успокою вас.",
            textEn: "Come unto me, all ye that labour and are heavy laden, and I will give you rest.",
            refHy: "Մատթեոս 11:28",
            refRu: "Матфея 11:28",
            refEn: "Matthew 11:28"
        ),
        BibleVerse(
            textHy: "Հիսուսը նրան ասաց. «Ես եմ ճանապարհը, ճշմարտությունը և կյանքը. ոչ ոք չի գալիս Հոր մոտ, եթե ոչ իմ միջոցով»։",
            textRu: "Иисус сказал ему: Я есмь путь и истина и жизнь; никто не приходит к Отцу, как только через Меня.",
            textEn: "Jesus saith unto him, I am the way, the truth, and the life: no man cometh unto the Father, but by me.",
            refHy: "Հովհաննես 14:6",
            refRu: "Иоанна 14:6",
            refEn: "John 14:6"
        ),
        BibleVerse(
            textHy: "Սերը համբերող է, քաղցրաբարո է. սերը չի նախանձում, սերը չի գոռոզանում, չի հպարտանում, անվայել վարմունք չի ունենում, իրենը չի փնտրում, բարկությամբ չի գրգռվում, չար բան չի խորհում։",
            textRu: "Любовь долготерпит, милосердствует, любовь не завидует, любовь не превозносится, не гордится, не бесчинствует, не ищет своего, не раздражается, не умышляет зла.",
            textEn: "Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself, is not puffed up, Doth not behave itself unseemly, seeketh not her own, is not easily provoked, thinketh no evil.",
            refHy: "Ա Կորնթացիներին 13:4-5",
            refRu: "1 Коринфянам 13:4-5",
            refEn: "1 Cor 13:4-5"
        ),
        BibleVerse(
            textHy: "Որովհետև Աստված մեզ երկչոտության հոգի չտվեց, այլ զորության, սիրո և զգաստության հոգի։",
            textRu: "Ибо дал нам Бог духа не боязни, но силы и любви и целомудрия.",
            textEn: "For God hath not given us the spirit of fear; but of power, and of love, and of a sound mind.",
            refHy: "Բ Տիմոթեոս 1:7",
            refRu: "2 Тимофею 1:7",
            refEn: "2 Timothy 1:7"
        ),
        BibleVerse(
            textHy: "Իսկ Տիրոջն սպասողները նոր ուժ կստանան, արծիվների պես թևերով վեր կսլանան, կվազեն ու չեն հոգնի, կքայլեն ու չեն նվաղի։",
            textRu: "А надеющиеся на Господа обновятся в силе: поднимут крылья, как орлы, потекут — и не устанут, пойдут — и не утомятся.",
            textEn: "But they that wait upon the Lord shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.",
            refHy: "Եսայիա 40:31",
            refRu: "Исаия 40:31",
            refEn: "Isaiah 40:31"
        ),
        BibleVerse(
            textHy: "Հավատն այն բաների հաստատումն է, որոնց հույսն ունենք, և ապացույցն այն բաների, որոնք չեն երևում։",
            textRu: "Вера же есть осуществление ожидаемого и уверенность в невидимом.",
            textEn: "Now faith is the substance of things hoped for, the evidence of things not seen.",
            refHy: "Եբրայեցիներին 11:1",
            refRu: "Евреям 11:1",
            refEn: "Hebrews 11:1"
        ),
        BibleVerse(
            textHy: "Աստված մեր ապավենն ու զորությունն է, նեղությունների մեջ мեր պատրաստ օգնականը։",
            textRu: "Бог нам прибежище и сила, скорый помощник в бедах.",
            textEn: "God is our refuge and strength, a very present help in trouble.",
            refHy: "Սաղմոսներ 46:1",
            refRu: "Псалом 45:2",
            refEn: "Psalm 46:1"
        ),
        BibleVerse(
            textHy: "Սիրո մեջ վախ չկա, այլ կատարյալ սերը դուրս է վանում վախը, որովհետև վախը տանջանք ունի իր մեջ. ով վախենում է, կատարյալ չէ սիրո մեջ։",
            textRu: "В любви нет страха, но совершенная любовь изгоняет страх, потому что в страхе есть мучение. Боящийся несовершенен в любви.",
            textEn: "There is no fear in love; but perfect love casteth out fear: because fear hath torment. He that feareth is not made perfect in love.",
            refHy: "Ա Հովհաննես 4:18",
            refRu: "1 Иоанна 4:18",
            refEn: "1 John 4:18"
        ),
        BibleVerse(
            textHy: "Տիրոջով ուրախացի՛ր, և նա կկատարի քո սրտի խնդրանքները։",
            textRu: "Утешайся Господом, и Он исполнит желания сердца твоего.",
            textEn: "Delight thyself also in the Lord; and he shall give thee the desires of thine heart.",
            refHy: "Սաղմոսներ 37:4",
            refRu: "Псалом 36:4",
            refEn: "Psalm 37:4"
        ),
        BibleVerse(
            textHy: "Բայց նախ խնդրեցե՛ք Աստծու արքայությունը և նրա արդարությունը, և այդ ամենը ձեզ կտրվի ավելիով։",
            textRu: "Ищите же прежде Царства Божия и правды Его, и это все приложится вам.",
            textEn: "But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.",
            refHy: "Մատթեոս 6:33",
            refRu: "Матфея 6:33",
            refEn: "Matthew 6:33"
        ),
        BibleVerse(
            textHy: "Ավելի մեծ սեր ոչ ոք ունի, քան այն, որ մեկն իր կյանքը դնի իր բարեկամների համար։",
            textRu: "Нет больше той любви, как если кто положит душу свою за друзей своих.",
            textEn: "Greater love hath no man than this, that a man lay down his life for his friends.",
            refHy: "Հովհաննես 15:13",
            refRu: "Иоанна 15:13",
            refEn: "John 15:13"
        ),
        BibleVerse(
            textHy: "Այսուհետև զորացե՛ք Տիրոջով և նրա ուժի կարողությամբ։",
            textRu: "Наконец, братия мои, укрепляйтесь Господом и могуществом силы Его.",
            textEn: "Finally, my brethren, be strong in the Lord, and in the power of his might.",
            refHy: "Եֆեսացիներին 6:10",
            refRu: "Ефесянам 6:10",
            refEn: "Ephesians 6:10"
        ),
        BibleVerse(
            textHy: "Եվ հույսի Աստվածը թող ձեզ լցնի ամենայն ուրախությամբ և խաղաղությամբ՝ հավատալու մեջ, որպեսզի հույսով առատանաք Սուրբ Հոգու զորությամբ։",
            textRu: "Бог же надежды да исполнит вас всякого радости и мира во вере, дабы вы изобиловали надеждою, силою Духа Святаго.",
            textEn: "Now the God of hope fill you with all joy and peace in believing, that ye may abound in hope, through the power of the Holy Ghost.",
            refHy: "Հռոմեացիներին 15:13",
            refRu: "Римлянам 15:13",
            refEn: "Romans 15:13"
        ),
        BibleVerse(
            textHy: "Եթե ձեզնից որևէ մեկն իմաստության պակաս ունի, թող խնդրի Աստծուց, որ բոլորին տալիս է առատությամբ և չի նախատում, և նրան կտրվի։",
            textRu: "Если же у кого из вас недостает мудрости, да просит у Бога, дающего всем просто и без упреков, — и дастся ему.",
            textEn: "If any of you lack wisdom, let him ask of God, that giveth to all men liberally, and upbraideth not; and it shall be given him.",
            refHy: "Հակոբոս 1:5",
            refRu: "Иакова 1:5",
            refEn: "James 1:5"
        ),
        BibleVerse(
            textHy: "Ձեր ամբողջ հոգսը նրա վրա՛ գցեք, որովհետև նա հոգ է տանում ձեր մասին։",
            textRu: "Все заботы ваши возложите на Него, ибо Он печется о вас.",
            textEn: "Casting all your care upon him; for he careth for you.",
            refHy: "Ա Պետրоս 5:7",
            refRu: "1 Петра 5:7",
            refEn: "1 Peter 5:7"
        ),
        BibleVerse(
            textHy: "Տերն է իմ լույսը և իմ փրկությունը, ումի՞ց վախենամ. Տերն է իմ կյանքի ամրությունը, ումի՞ց սարսափեմ։",
            textRu: "Господь — свет мой и спасение мое: кого мне бояться? Господь крепость жизни моей: кого мне страшиться?",
            textEn: "The Lord is my light and my salvation; whom shall I fear? the Lord is the strength of my life; of whom shall I be afraid?",
            refHy: "Սաղմոսներ 27:1",
            refRu: "Псалом 26:1",
            refEn: "Psalm 27:1"
        ),
        BibleVerse(
            textHy: "Երանի՜ նրանց, որ սրտով մաքուր են, որովհետև նրանք Աստծուն պիտի տեսնեն։",
            textRu: "Блаженны чистые сердцем, ибо они Бога узрят.",
            textEn: "Blessed are the pure in heart: for they shall see God.",
            refHy: "Մատթեոս 5:8",
            refRu: "Матфея 5:8",
            refEn: "Matthew 5:8"
        ),
        BibleVerse(
            textHy: "Երանի՜ խաղաղարարներին, որովհետև նրանք Աստծու որդիներ պիտի կոչվեն։",
            textRu: "Блаженны миротворцы, ибо они сынами Божиими нарекутся.",
            textEn: "Blessed are the peacemakers: for they shall be called the children of God.",
            refHy: "Մատթեոս 5:9",
            refRu: "Матфея 5:9",
            refEn: "Matthew 5:9"
        ),
        BibleVerse(
            textHy: "Այդպես թող ձեր լույսը փայլի մարդկանց առաջ, որպեսզի տեսնեն ձեր բարի գործերը և փառավորեն ձեր Հորը, որ երկնքում է։",
            textRu: "Так да светит свет ваш пред людьми, чтобы они видели ваши добрые дела и прославляли Отца вашего Небесного.",
            textEn: "Let your light so shine before men, that they may see your good works, and glorify your Father which is in heaven.",
            refHy: "Մատթեոս 5:16",
            refRu: "Матфея 5:16",
            refEn: "Matthew 5:16"
        ),
        BibleVerse(
            textHy: "Խնդրեցե՛ք, և կտրվի ձեզ, փնտրեցե՛ք և կգտնեք, բախեցե՛ք, և կբացվի ձեզ։",
            textRu: "Просите, и дано будет вам; ищите, и найдете; стучите, и отворят вам.",
            textEn: "Ask, and it shall be given you; seek, and ye shall find; knock, and it shall be opened unto you.",
            refHy: "Մատթեոս 7:7",
            refRu: "Матфея 7:7",
            refEn: "Matthew 7:7"
        ),
        BibleVerse(
            textHy: "Հիսուսը նայեց նրանց և ասաց. «Մարդկանց համար դա անհնար է, բայց Աստծու համար ամեն ինչ հնարավոր է»։",
            textRu: "А Иисус, воззрев, сказал им: человекам это невозможно, Богу же все возможно.",
            textEn: "But Jesus beheld them, and said unto them, With men this is impossible; but with God all things are possible.",
            refHy: "Մատթեոս 19:26",
            refRu: "Матфея 19:26",
            refEn: "Matthew 19:26"
        ),
        BibleVerse(
            textHy: "Հիսուսը նրան ասաց. «Սիրի՛ր քо Տեր Աստծուն քո ամբողջ սրտով, քո ամբողջ հոգով և քո ամբողջ մտքով»։",
            textRu: "Иисус сказал ему: возлюби Господа Бога твоего всем сердцем твоим и всею душею твоею и всем разумением твоим.",
            textEn: "Jesus said unto him, Thou shalt love the Lord thy God with all thy heart, and with all thy soul, and with all thy mind.",
            refHy: "Մատթեոս 22:37",
            refRu: "Матфея 22:37",
            refEn: "Matthew 22:37"
        ),
        BibleVerse(
            textHy: "Եվ ահա ես ձեզ հետ եմ ամեն օր՝ մինչև աշխարհի վախճանը։",
            textRu: "И се, Я с вами во все дни до скончания века. Аминь.",
            textEn: "And, lo, I am with you alway, even unto the end of the world. Amen.",
            refHy: "Մատթեոս 28:20",
            refRu: "Матфея 28:20",
            refEn: "Matthew 28:20"
        ),
        BibleVerse(
            textHy: "Սկզբում էր Խոսքը, և Խոսքը Աստծու մոտ էր, և Խոսքը Աստված էր։",
            textRu: "В начале было Слово, и Слово было у Бога, и Слово было Бог.",
            textEn: "In the beginning was the Word, and the Word was with God, and the Word was God.",
            refHy: "Հովհաննես 1:1",
            refRu: "Иоанна 1:1",
            refEn: "John 1:1"
        ),
        BibleVerse(
            textHy: "Հիսուսը դարձյալ խոսեց նրանց հետ ու ասաց. «Ես եմ աշխարհի լույսը. ով իմ հետևից գա, խավարի մեջ չի քայլի, այլ կունենա կյանքի լույսը»։",
            textRu: "Опять говорил Иисус к народу и сказал им: Я свет миру; кто последует за Мною, тот не будет ходить во тьме, но будет иметь свет жизни.",
            textEn: "Then spake Jesus again unto them, saying, I am the light of the world: he that followeth me shall not walk in darkness, but shall have the light of life.",
            refHy: "Հովհաննես 8:12",
            refRu: "Иоанна 8:12",
            refEn: "John 8:12"
        ),
        BibleVerse(
            textHy: "Եվ կճանաչեք ճշմարտությունը, և ճշմարտությունը կազատի ձեզ։",
            textRu: "И познаете истину, и истина сделает вас свободными.",
            textEn: "And ye shall know the truth, and the truth shall make you free.",
            refHy: "Հովհաննես 8:32",
            refRu: "Иоанна 8:32",
            refEn: "John 8:32"
        ),
        BibleVerse(
            textHy: "Խաղաղություն եմ թողնում ձեզ, իմ խաղաղությունն եմ տալիս ձեզ. ոչ թե ինչպես այս աշխարհն է տալիս, ես տալիս եմ ձեզ։ Ձեր սրտերը թող չխռովվեն և չվախենան։",
            textRu: "Мир оставляю вам, мир Мой даю вам; не так, как мир дает, Я даю вам. Да не смущается сердце ваше и да не устрашается.",
            textEn: "Peace I leave with you, my peace I give unto you: not as the world giveth, give I unto you. Let not your heart be troubled, neither let it be afraid.",
            refHy: "Հովհաննես 14:27",
            refRu: "Иоанна 14:27",
            refEn: "John 14:27"
        ),
        BibleVerse(
            textHy: "Աշխարհում նեղություն պիտի ունենաք, բայց քաջալերվեցե՛ք, ես հաղթել եմ աշխարհին։",
            textRu: "В мире будете иметь скорбь; но мужайтесь: Я победил мир.",
            textEn: "In the world ye shall have tribulation: but be of good cheer; I have overcome the world.",
            refHy: "Հովհաննես 16:33",
            refRu: "Иоанна 16:33",
            refEn: "John 16:33"
        ),
        BibleVerse(
            textHy: "Իսկ արդ, ի՞նչ ասենք այս բաների մասին։ Եթե Աստված մեր կողմն է, ո՞վ կլինի մեզ հակառակ։",
            textRu: "Что же сказать на это? Если Бог за нас, кто против нас?",
            textEn: "What shall we then say to these things? If God be for us, who can be against us?",
            refHy: "Հռոմեացիներին 8:31",
            refRu: "Римлянам 8:31",
            refEn: "Romans 8:31"
        ),
        BibleVerse(
            textHy: "Մի՛ հաղթվիր չարից, այլ բարիո՛վ հաղթիր չարին։",
            textRu: "Не будь побежден злом, но побеждай зло добром.",
            textEn: "Be not overcome of evil, but overcome evil with good.",
            refHy: "Հռոմեացիներին 12:21",
            refRu: "Римлянам 12:21",
            refEn: "Romans 12:21"
        ),
        BibleVerse(
            textHy: "Ձեր ամեն գործ սիրո՛վ թող լինի։",
            textRu: "Все у вас да будет с любовью.",
            textEn: "Let all your things be done with charity.",
            refHy: "Ա Կորնթացիներին 16:14",
            refRu: "1 Коринфянам 16:14",
            refEn: "1 Corinthians 16:14"
        ),
        BibleVerse(
            textHy: "Ուստի եթե մեկը Քրիստոսի մեջ է, նա նոր արարած է. հինն անցավ, և ահա ամեն ինչ նոր եղավ։",
            textRu: "Итак, кто во Христе, тот новая тварь; древнее прошло, теперь все новое.",
            textEn: "Therefore if any man be in Christ, he is a new creature: old things are passed away; behold, all things are become new.",
            refHy: "Բ Կորնթացիներին 5:17",
            refRu: "2 Коринфянам 5:17",
            refEn: "2 Corinthians 5:17"
        ),
        BibleVerse(
            textHy: "Որովհետև շնորհով եք փրկված հավատի միջոցով, և սա ոչ թե ձեզնից է, այլ Աստծու պարգևն է։",
            textRu: "Ибо благодатью вы спасены через веру, и сие не от вас, Божий дар.",
            textEn: "For by grace are ye saved through faith; and that not of yourselves: it is the gift of God.",
            refHy: "Եփեսացիներին 2:8",
            refRu: "Ефесянам 2:8",
            refEn: "Ephesians 2:8"
        ),
        BibleVerse(
            textHy: "Ոչ մի բանի համար հոգս մի՛ արեք, այլ ամեն ինչում աղոթքով և աղաչանքով, գոհությամբ հանդերձ, ձեր խնդրանքները թող հայտնի լինեն Աստծուն։",
            textRu: "Не заботьтесь ни о чем, но всегда в молитве и прошении с благодарением открывайте свои желания пред Богом.",
            textEn: "Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God.",
            refHy: "Փիլիպպեցիներին 4:6",
            refRu: "Филиппийцам 4:6",
            refEn: "Philippians 4:6"
        ),
        BibleVerse(
            textHy: "Ամեն ժամ ուրա՛խ եղեք։ Անդադա՛ր աղոթեցեք։ Ամեն ինչի համար գոհությո՛ւն հայտնեցեք, որովհետև սա է Աստծու կամքը ձեր հանդեպ Քրիստոս Հիսուսով։",
            textRu: "Всегда радуйтесь. Непрестанно молитесь. За все благодарите: ибо такова о вас воля Божия во Христе Иисусе.",
            textEn: "Rejoice evermore. Pray without ceasing. In every thing give thanks: for this is the will of God in Christ Jesus concerning you.",
            refHy: "Ա Թեսաղոնիկեցիներին 5:16-18",
            refRu: "1 Фессалоникийцам 5:16-18",
            refEn: "1 Thess 5:16-18"
        ),
        BibleVerse(
            textHy: "Հիսուս Քրիստոսը նույնն է երեկ, այսօր և հավիտյան։",
            textRu: "Иисус Христос вчера и сегодня и вовеки Тот же.",
            textEn: "Jesus Christ the same yesterday, and to day, and for ever.",
            refHy: "Եբրայեցիներին 13:8",
            refRu: "Евреям 13:8",
            refEn: "Hebrews 13:8"
        ),
        BibleVerse(
            textHy: "Ով չի սիրում, նա չի ճանաչում Աստծուն, որովհետև Աստված սեր է։",
            textRu: "Кто не любит, тот не познал Boga, потому что Бог есть любовь.",
            textEn: "He that loveth not knoweth not God; for God is love.",
            refHy: "Ա Հովհաննես 4:8",
            refRu: "1 Иоанна 4:8",
            refEn: "1 John 4:8"
        ),
        BibleVerse(
            textHy: "Բերանիս խոսքերն ու սրտիս խորհուրդները հաճելի թող լինեն քո առաջ, Տե՛ր, իմ Վե՛մ և իմ Փրկի՛չ։",
            textRu: "Да будут слова уст моих и помышление сердца моего благоугодны пред Тобою, Господи, твердыня моя и Избавитель мой!",
            textEn: "Let the words of my mouth, and the meditation of my heart, be acceptable in thy sight, O Lord, my strength, and my redeemer.",
            refHy: "Սաղմոսներ 19:14",
            refRu: "Псалом 18:15",
            refEn: "Psalm 19:14"
        ),
        BibleVerse(
            textHy: "Քո ճանապարհը Տիրո՛ջը հանձնիր և նրա՛ն հուսա. նա կկատարի այն։",
            textRu: "Предай Господу путь твой и уповай на Него, и Он совершит.",
            textEn: "Commit thy way unto the Lord; trust also in him; and he shall bring it to pass.",
            refHy: "Սաղմոսներ 37:5",
            refRu: "Псалом 36:5",
            refEn: "Psalm 37:5"
        ),
        BibleVerse(
            textHy: "Մի՛ վախեցիր, որովհետև ես քեզ հետ եմ. մի՛ զարհուրիր, որովհետև ես քո Աստվածն եմ. ես կզորացնեմ քեզ և կօգնեմ քեզ...",
            textRu: "Не бойся, ибо Я с тобою; не смущайся, ибо Я Бог твой; Я укреплю тебя, и помогу тебе...",
            textEn: "Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee...",
            refHy: "Եսայիա 41:10",
            refRu: "Исаия 41:10",
            refEn: "Isaiah 41:10"
        ),
        BibleVerse(
            textHy: "Տերը մոտ է սրտով կոտրվածներին և փրկում է հոգով խոնարհներին։",
            textRu: "Близко Господь к сокрушенным сердцем и смиренных духом спасет.",
            textEn: "The Lord is nigh unto them that are of a broken heart; and saveth such as be of a contrite spirit.",
            refHy: "Սաղմոսներ 34:18",
            refRu: "Псалом 33:19",
            refEn: "Psalm 34:18"
        ),
        BibleVerse(
            textHy: "Համբերությամբ սպասեցի Տիրոջը, և նա հակվեց դեպի ինձ ու լսեց իմ աղաղակը։",
            textRu: "Твердо уповал я на Господа, и Он приклонился ко мне и услышал вопль мой.",
            textEn: "I waited patiently for the Lord; and he inclined unto me, and heard my cry.",
            refHy: "Սաղմոսներ 40:1",
            refRu: "Псалом 39:2",
            refEn: "Psalm 40:1"
        ),
        BibleVerse(
            textHy: "Քո հոգսը Տիրո՛ջ վրա գցիր, և նա կհոգա քեզ. նա երբեք թույլ չի տա, որ արդարը սասանվի։",
            textRu: "Возложи на Господа заботы твои, и Он поддержит тебя. Никогда не даст Он поколебаться праведнику.",
            textEn: "Cast thy burden upon the Lord, and he shall sustain thee: he shall never suffer the righteous to be moved.",
            refHy: "Սաղմոսներ 55:22",
            refRu: "Псалом 54:23",
            refEn: "Psalm 55:22"
        ),
        BibleVerse(
            textHy: "Միայն Աստծով է հանդարտվում իմ անձը, նրանից է իմ փրկությունը։",
            textRu: "Только в Боге успокаивается душа моя: от Него спасение мое.",
            textEn: "Truly my soul waiteth upon God: from him cometh my salvation.",
            refHy: "Սաղմոսներ 62:1",
            refRu: "Псалом 61:2",
            refEn: "Psalm 62:1"
        ),
        BibleVerse(
            textHy: "Որովհետև Տեր Աստվածը արև է և վահան. Տերը շնորհ և փառք է տալիս, ոչ մի բարիք չի զլանում ուղղությամբ ընթացողներից։",
            textRu: "Ибо Господь Бог есть солнце и щит, Господь дает благодать и славу; ходящих в непорочности Он не лишает благ.",
            textEn: "For the Lord God is a sun and shield: the Lord will give grace and glory: no good thing will he withhold from them that walk uprightly.",
            refHy: "Սաղմոսներ 84:11",
            refRu: "Псалом 83:12",
            refEn: "Psalm 84:11"
        ),
        BibleVerse(
            textHy: "Բայց Դու, Տե՛ր, գթած և ողորմած Աստված ես, երկայնամիտ և բազումողորմ ու ճշմարիտ։",
            textRu: "Но Ты, Господи, Бог щедрый и благосердный, долготерпеливый и многомилостивый и истинный.",
            textEn: "But thou, O Lord, art a God full of compassion, and gracious, longsuffering, and plenteous in mercy and truth.",
            refHy: "Սաղմոսներ 86:15",
            refRu: "Псалом 85:15",
            refEn: "Psalm 86:15"
        ),
        BibleVerse(
            textHy: "Բարձրյալի ծածկոցի տակ բնակվողը Ամենակարողի հովանու տակ կհանգստանա։ Կասեմ Տիրոջը. «Իմ ապավեն և իմ ամրոց, իմ Աստված, որին ես հույսս դրել եմ»։",
            textRu: "Живущий под кровом Всевышнего под сению Всемогущего покоится. Говорит Господу: «прибежище мое и защита моя, Бог мой, на Которого я уповаю!»",
            textEn: "He that dwelleth in the secret place of the most High shall abide under the shadow of the Almighty. I will say of the Lord, He is my refuge and my fortress: my God; in him will I trust.",
            refHy: "Սաղմոսներ 91:1-2",
            refRu: "Псалом 90:1-2",
            refEn: "Psalm 91:1-2"
        ),
        BibleVerse(
            textHy: "Որովհետև Տերը բարի է, նրա ողորմությունը հավիտենական է, և նրա հավատարմությունը՝ ազգից մինչև ազգ։",
            textRu: "Ибо благ Господь: милость Его вовек, и истина Его в род и род.",
            textEn: "For the Lord is good; his mercy is everlasting; and his truth endureth to all generations.",
            refHy: "Սաղմոսներ 100:5",
            refRu: "Псалом 99:5",
            refEn: "Psalm 100:5"
        ),
        BibleVerse(
            textHy: "Գոհացե՛ք Տիրոջից, որովհետև բարի է, որովհետև հավիտենական է նրա ողորմությունը։",
            textRu: "Славьте Господа, ибо Он благ, ибо вовек милость Его.",
            textEn: "O give thanks unto the Lord; for he is good: for his mercy endureth for ever.",
            refHy: "Սաղմոսներ 107:1",
            refRu: "Псалом 106:1",
            refEn: "Psalm 107:1"
        ),
        BibleVerse(
            textHy: "Փառաբանեցե՛ք Տիրոջը, որովհետև բարի է, որովհետև հավիտենական է նրա ողորմությունը։",
            textRu: "Славьте Господа, ибо Он благ, ибо вовек милость Его.",
            textEn: "O give thanks unto the Lord; for he is good: because his mercy endureth for ever.",
            refHy: "Սաղմոսներ 118:1",
            refRu: "Псалом 117:1",
            refEn: "Psalm 118:1"
        ),
        BibleVerse(
            textHy: "Ինչո՞վ կմաքրի երիտասարդն իր ճանապարհը. Քո խոսքի համեմատ զգուշանալով։",
            textRu: "Как юноше содержать в чистоте путь свой? — Хранением себя по слову Твоему.",
            textEn: "Wherewithal shall a young man cleanse his way? by taking heed thereto according to thy word.",
            refHy: "Սաղմոսներ 119:9",
            refRu: "Псалом 118:9",
            refEn: "Psalm 119:9"
        ),
        BibleVerse(
            textHy: "Դու ստեղծեցիր իմ երկամունքները, ծածկեցիր ինձ իմ մոր որովայնում։ Փառաբանում եմ Քեզ, որ ահավոր և զարմանալի կերպով ստեղծվեցի։",
            textRu: "Ибо Ты устроил внутренности мои и соткал меня во чреве матери моей. Славлю Тебя, потому что я дивно устроен.",
            textEn: "For thou hast possessed my reins: thou hast covered me in my mother's womb. I will praise thee; for I am fearfully and wonderfully made.",
            refHy: "Սաղմոսներ 139:13-14",
            refRu: "Псалом 138:13-14",
            refEn: "Psalm 139:13-14"
        ),
        BibleVerse(
            textHy: "Սովորեցրո՛ւ ինձ կատարել Քո կամքը, որովհետև Դու ես իմ Աստվածը. Քո բարի Հոգին թող ինձ առաջնորդի դեպի ուղիղ երկիր։",
            textRu: "Научи меня исполнять волю Твою, потому что Ты Бог мой; Дух Твой благий да ведет меня в землю правды.",
            textEn: "Teach me to do thy will; for thou art my God: thy spirit is good; lead me into the land of uprightness.",
            refHy: "Սաղմոսներ 143:10",
            refRu: "Псалом 142:10",
            refEn: "Psalm 143:10"
        ),
        BibleVerse(
            textHy: "Քո գործերը Տիրո՛ջը հանձնիր, և քո ծրագրերը կհաստատվեն։",
            textRu: "Предай Господу дела твои, и предприятия твои совершатся.",
            textEn: "Commit thy works unto the Lord, and thy thoughts shall be established.",
            refHy: "Առակաց 16:3",
            refRu: "Притчи 16:3",
            refEn: "Proverbs 16:3"
        ),
        BibleVerse(
            textHy: "Տիրոջ անունը ամուր աշտարակ է. արդարը փախչում է դեպի այն և ապահով լինում։",
            textRu: "Имя Господа — крепкая башня: убегает в нее праведник, и безопасен.",
            textEn: "The name of the Lord is a strong tower: the righteous runneth into it, and is safe.",
            refHy: "Առակաց 18:10",
            refRu: "Притчи 18:10",
            refEn: "Proverbs 18:10"
        ),
        BibleVerse(
            textHy: "Ահա Աստված է իմ փրկությունը. ես կվստահեմ և չեմ վախենա, որովհետև Տեր Եհովան է իմ զորությունը և իմ օրհնությունը, և նա եղավ իմ փրկությունը։",
            textRu: "Вот, Бог — спасение мое: уповаю на Него и не боюсь; ибо Господь Бог — сила моя и пение мое; и Он был мне во спасение.",
            textEn: "Behold, God is my salvation; I will trust, and not be afraid: for the Lord JEHOVAH is my strength and my song; he also is become my salvation.",
            refHy: "Եսայիա 12:2",
            refRu: "Исаия 12:2",
            refEn: "Isaiah 12:2"
        ),
        BibleVerse(
            textHy: "Նա հոգնածին ուժ է տալիս և թույլին՝ մեծ կարողություն։",
            textRu: "Он дает утомленному силу, и изнемогшему дарует крепость.",
            textEn: "He giveth power to the faint; and to them that have no might he increaseth strength.",
            refHy: "Եսայիա 40:29",
            refRu: "Исаия 40:29",
            refEn: "Isaiah 40:29"
        ),
        BibleVerse(
            textHy: "Երբ ջրերի միջով անցնես, ես քեզ հետ կլինեմ, և գետերը քեզ չեն խեղդի. երբ կրակի միջով քայլես, չես այրվի, և բոցը քեզ չի կիզի։",
            textRu: "Будешь ли переходить через воды, Я с тобою, — через реки ли, они не потопят тебя; пойдешь ли через огонь, не обожжешься, и пламя не опалит тебя.",
            textEn: "When thou passest through the waters, I will be with thee; and through the rivers, they shall not overflow thee: when thou walkest through the fire, thou shalt not be burned; neither shall the flame kindle upon thee.",
            refHy: "Եսայիա 43:2",
            refRu: "Исаия 43:2",
            refEn: "Isaiah 43:2"
        ),
        BibleVerse(
            textHy: "Երանի՜ ողորմածներին, որովհետև նրանք ողորմություն պիտի գտնեն։",
            textRu: "Блаженны милостивые, ибо они помилованы будут.",
            textEn: "Blessed are the merciful: for they shall obtain mercy.",
            refHy: "Մատթեոս 5:7",
            refRu: "Матфея 5:7",
            refEn: "Matthew 5:7"
        ),
        BibleVerse(
            textHy: "Որովհետև ուր որ երկու կամ երեք հոգի հավաքված լինեն իմ անունով, այնտեղ եմ ես՝ նրանց մեջ։",
            textRu: "Ибо, где двое или трое собраны во имя Мое, там Я посреди них.",
            textEn: "For where two or three are gathered together in my name, there am I in the midst of them.",
            refHy: "Մատթեոս 18:20",
            refRu: "Матфея 18:20",
            refEn: "Matthew 18:20"
        ),
        BibleVerse(
            textHy: "Երկինքն ու երկիրը կանցնեն, բայց իմ խոսքերը երբեք չեն անցնի։",
            textRu: "Небо и земля прейдут, но слова Мои не прейдут.",
            textEn: "Heaven and earth shall pass away, but my words shall not pass away.",
            refHy: "Մատթեոս 24:35",
            refRu: "Матфея 24:35",
            refEn: "Matthew 24:35"
        ),
        BibleVerse(
            textHy: "Որովհետև Աստծու համար անհնարին ոչ մի բան չկա։",
            textRu: "Ибо у Boga не останется бессильным никакое слово.",
            textEn: "For with God nothing shall be impossible.",
            refHy: "Ղուկաս 1:37",
            refRu: "Луки 1:37",
            refEn: "Luke 1:37"
        ),
        BibleVerse(
            textHy: "Գողը գալիս է միայն գողանալու, սպանելու և կորստյան մատնելու համար։ Ես եկա, որ կյանք ունենան և ավելիով ունենան։",
            textRu: "Вор приходит только для того, чтобы украсть, убить и погубить. Я пришел для того, чтобы имели жизнь и имели с избытком.",
            textEn: "The thief cometh not, but for to steal, and to kill, and to destroy: I am come that they might have life, and that they might have it more abundantly.",
            refHy: "Հովհաննես 10:10",
            refRu: "Иоанна 10:10",
            refEn: "John 10:10"
        ),
        BibleVerse(
            textHy: "Բայց Աստված իր սերն է հայտնում մեր հանդեպ նրանով, որ դեռ մեղավոր էինք, երբ Քրիստոսը մեռավ մեզ համար։",
            textRu: "Но Бог Свою любовь к нам доказывает тем, что Христос умер за нас, когда мы были еще грешниками.",
            textEn: "But God commendeth his love toward us, in that, while we were yet sinners, Christ died for us.",
            refHy: "Հռոմեացիներին 5:8",
            refRu: "Римлянам 5:8",
            refEn: "Romans 5:8"
        ),
        BibleVerse(
            textHy: "Հույսով ուրախացե՛ք, նեղության մեջ համբերեցե՛ք, աղոթքի մեջ հարատևեցե՛ք։",
            textRu: "Утешайтесь надеждою; в скорби будьте терпеливы, в молитве постоянны.",
            textEn: "Rejoicing in hope; patient in tribulation; continuing instant in prayer.",
            refHy: "Հռոմեացիներին 12:12",
            refRu: "Римлянам 12:12",
            refEn: "Romans 12:12"
        ),
        // --- МОЛИТВЫ ---
        BibleVerse(
            textHy: "Հա՛յր մեր, որ երկնքում ես, սուրբ թող լինի Քո անունը. Քո արքայությունը թող գա, Քո կամքը թող լինի երկրի վրա, ինչպես երկնքում։ Մեր հանապազօրյա հացը տո՛ւր մեզ այսօր։ Եվ ներե՛ր մեզ мեր պարտքերը, ինչպես և մենք ենք ներում մեր պարտապաններին։ Եվ մի՛ տանիր մեզ փորձության, այլ փրկի՛ր մեզ չարից։ Որովհետև Քոնն է արքայությունը և զորությունը և փառքը հավիտյանս։ Ամեն։",
            textRu: "Отче наш, сущий на небесах! да святится имя Твое; да приидет Царствие Твое; да будет воля Твоя и на земле, как на небе; хлеб наш насущный дай нам на сей день; и прости нам долги наши, как и мы прощаем должникам нашим; и не введи нас в искушение, но избавь нас от лукавого. Ибо Твое есть Царство и сила и слава вовеки. Аминь.",
            textEn: "Our Father which art in heaven, Hallowed be thy name. Thy kingdom come. Thy will be done in earth, as it is in heaven. Give us this day our daily bread. And forgive us our debts, as we forgive our debtors. And lead us not into temptation, but deliver us from evil: For thine is the kingdom, and the power, and the glory, for ever. Amen.",
            refHy: "Տերունական աղոթք",
            refRu: "Молитва Господня",
            refEn: "The Lord's Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Պահապա՛ն ամենայնի Քրիստոս, աջ Քո հովանի լիցի ի վերայ իմ, ի տուէ և ի գիշերի, ի նստիլ ի տան, ի գնալ ի ճանապարհ, ի ննջել և ի յառնել, զի մի՛ երբեք սասանեցայց. և ողորմեա՛ Քո արարածոց և ինձ՝ բազմամեղիս։",
            textRu: "Хранитель всех, Христос! Да будет десница Твоя сенью надо мною днем и ночью, дома и в пути, во время сна и бодрствования, чтобы никогда не поколебался я. И помилуй Творения Твои и меня, многогрешного.",
            textEn: "O Christ, guardian of all, let Thy right hand be a shadow over me day and night, at home and on the way, in sleep and in waking, that I may never stumble. And have mercy upon Thy creations, and upon me, a manifold sinner.",
            refHy: "Սուրբ Ներսես Շնորհալի",
            refRu: "Св. Нерсес Шнорали",
            refEn: "St. Nerses the Gracious",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Իմաստո՛ւթիւն Հօր Յիսուս, տո՛ւր ինձ իմաստութիւն՝ զբարիս խորհել և խօսել և գործել առաջի Քո յամենայն ժամ. ի չար խորհրդոց, ի բանից և ի գործոց փրկեա՛ զիս. և ողորմեա՛ Քո արարածոց և ինձ՝ բազմամեղիս։",
            textRu: "Премудрость Отца, Иисус! Даруй мне мудрость помышлять, говорить и творить благое пред Тобою во всякое время. Избавь меня от злых помыслов, слов и дел. И помилуй Творения Твои и меня, многогрешного.",
            textEn: "O Jesus, Wisdom of the Father, grant me wisdom to think, speak, and do that which is good in Thy sight at all times. Deliver me from evil thoughts, words, and deeds. And have mercy upon Thy creations, and upon me, a manifold sinner.",
            refHy: "Սուրբ Ներսես Շնորհալի",
            refRu: "Св. Нерсес Шнорали",
            refEn: "St. Nerses the Gracious",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տե՛ր իմ և Աստվա՛ծ իմ, Քո սիրո և ողորմության համար ներիր իմ բոլոր մեղքերը, որոնք գործել եմ Քո սուրբ կամքի դեմ։ Լվա՛ ինձ իմ անօրենությունից և մաքրիր ինձ իմ մեղքերից։ Ամեն։",
            textRu: "Господи мой и Бог мой! Ради Твоей любви и милосердия прости все грехи мои, содеянные против Твоей святой воли. Омой меня от беззакония моего и очисти меня от грехов моих. Аминь.",
            textEn: "My Lord and my God, for the sake of Thy love and mercy, forgive all my sins which I have committed against Thy holy will. Wash me thoroughly from my iniquity, and cleanse me from my sins. Amen.",
            refHy: "Աղոթագիրք (Զղջման)",
            refRu: "Молитвослов (Покаянная)",
            refEn: "Prayer Book (Repentance)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Փա՛ռք Քեզ, Տե՛ր Աստված իմ, որ արժանացրիր ինձ այս առավոտյան լույսին։ Տո՛ւր ինձ այսօր խաղաղությամբ և առանց փորձության անցկացնել օրը, պահպանիր իմ մտքերը և գործերը Քո սիրո մեջ։ Ամեն։",
            textRu: "Слава Тебе, Господи Боже мой, сподобившему меня сего утреннего света! Даруй мне провести этот день в мире и без искушений, сохрани помыслы мои и дела в любви Твоей. Аминь.",
            textEn: "Glory to Thee, my Lord and God, Who hast made me worthy of this morning light! Grant me to pass this day in peace and without temptation, keep my thoughts and deeds in Thy love. Amen.",
            refHy: "Սուրբ Հովհաննես Գառնեցի",
            refRu: "Св. Иоанн Гарнеци",
            refEn: "St. John of Garni",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տերը կպահպանի քեզ ամեն չարից, Տերը կպահպանի քո անձը։ Տերը կպահպանի քո մուտքն ու ելքը այսուհետև մինչև հավիտյան։ Ամեն։",
            textRu: "Господь сохранит тебя от всякого зла; сохранит душу твою Господь. Господь будет охранять выхождение твое и вхождение твое отныне и вовек. Аминь.",
            textEn: "The Lord shall preserve thee from all evil: he shall preserve thy soul. The Lord shall preserve thy going out and thy coming in from this time forth, and even for evermore. Amen.",
            refHy: "Ճանապարհորդի Աղոթք",
            refRu: "Молитва путешественника",
            refEn: "Traveler's Prayer",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Տո՛ւր մեզ Քո խաղաղությունը, Տե՛ր, որը վեր է ամեն մտքից։ Խաղաղեցրու մեր սրտերը, հեռացրու մեր վախերը և տուր մեզ Քո ներկայության ապահովությունը։ Ամեն։",
            textRu: "Даруй нам мир Твой, Господи, который превыше всякого ума. Умиротвори сердца наши, отгони страхи наши и даруй нам уверенность в Твоем присутствии. Аминь.",
            textEn: "Grant us Thy peace, O Lord, which passeth all understanding. Pacify our hearts, take away our fears, and grant us the security of Thy presence. Amen.",
            refHy: "Աղոթագիրք (Խաղաղության)",
            refRu: "Молитвослов (О мире)",
            refEn: "Prayer Book (For Peace)",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Ընկա՛լ քաղցրությամբ, Տեր Աստված հզոր, զդառնացողիս աղաչանս, մատի՛ր գթությամբ առ պատկառեալս դիմոք։ Փարատեա՛, ամենապարգև, զամոթական տխրութիւնս, բա՛րձ յինէն զծանր հեծութիւնս։ Ամեն։",
            textRu: "Прими с благоволением, Господи Боже Вседержитель, горькие моления мои, обрати милостивый взор на кающегося. Рассей, Всеблагой, постыдную скорбь мою, сними с меня тяжелое бремя уныния. Аминь.",
            textEn: "Receive with sweetness, Lord God Almighty, my bitter prayers, look with compassion upon my contrite face. Dispel, O All-Giver, my shameful sadness, lift from me this heavy sighing. Amen.",
            refHy: "Սուրբ Գրիգոր Նարեկացի",
            refRu: "Св. Григор Нарекаци",
            refEn: "St. Gregory of Narek",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Շնորհակալ եմ Քեզնից, Տե՛ր իմ և Աստվա՛ծ իմ, Քո բոլոր բարիքների, կյանքի, առողջության և Քո անսահման սիրո համար, որով շրջապատում ես ինձ ամեն օր։ Ամեն։",
            textRu: "Благодарю Тебя, Господи мой и Бог мой, за все Твои благодеяния, за жизнь, здоровье и за безграничную Твою любовь, которой Ты окружаешь меня каждый день. Аминь.",
            textEn: "Thank Thee, my Lord and God, for all Thy blessings, for life, health, and for Thy boundless love with which Thou surroundest me every day. Amen.",
            refHy: "Շնորհակալական Աղոթք",
            refRu: "Благодарственная молитва",
            refEn: "Prayer of Thanksgiving",
            isPrayer: true
        ),
        BibleVerse(
            textHy: "Բժշկի՛ր ինձ, Տե՛ր, և ես կբժշկվեմ. փրկի՛ր ինձ, և ես կփրկվեմ, որովհետև Դու ես իմ փառքը։ Տո՛ւր առողջություն մարմնիս և խաղաղություն հոգուս։ Ամեն։",
            textRu: "Исцели меня, Господи, и исцелен буду; спаси меня, и спасен буду; ибо Ты хвала моя. Даруй здравие телу моему и мир душе моей. Аминь.",
            textEn: "Heal me, O Lord, and I shall be healed; save me, and I shall be saved: for thou art my praise. Grant health to my body and peace to my soul. Amen.",
            refHy: "Բժշկության Աղոթք",
            refRu: "Молитва об исцелении",
            refEn: "Prayer for Healing",
            isPrayer: true
        )
    ]
}
