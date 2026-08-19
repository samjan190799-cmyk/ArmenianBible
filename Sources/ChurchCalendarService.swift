import Foundation
import UIKit

// MARK: - Тип церковного праздника / события
enum FeastType: String, Codable, CaseIterable, Identifiable, Sendable {
    case daghavar = "daghavar"       // 5 Главных праздников (Տաղավար տոներ)
    case dominical = "dominical"     // Господские и Богородичные праздники (Տերունական տոներ)
    case fasting = "fasting"         // Постные периоды (Պահք)
    case saints = "saints"           // Память святых (Սրբոց տոներ)
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .daghavar: return "👑"
        case .dominical: return "✨"
        case .fasting: return "🕯️"
        case .saints: return "🕊️"
        }
    }
    
    var colorHex: String {
        switch self {
        case .daghavar: return "F59E0B" // Золотой
        case .dominical: return "38BDF8" // Голубой
        case .fasting: return "8B5CF6"   // Фиолетовый
        case .saints: return "10B981"    // Зеленый
        }
    }
    
    func localizedTitle(for lang: AppLanguage) -> String {
        switch self {
        case .daghavar:
            switch lang {
            case .armenian: return "Տաղավար տոներ"
            case .russian: return "Великие праздники"
            case .english: return "Major Feasts"
            }
        case .dominical:
            switch lang {
            case .armenian: return "Տերունական տոներ"
            case .russian: return "Господские праздники"
            case .english: return "Dominical Feasts"
            }
        case .fasting:
            switch lang {
            case .armenian: return "Պահք"
            case .russian: return "Посты"
            case .english: return "Fasting Days"
            }
        case .saints:
            switch lang {
            case .armenian: return "Սրբոց տոներ"
            case .russian: return "Дни святых"
            case .english: return "Saints' Days"
            }
        }
    }
}

// MARK: - Модель церковного праздника
struct ArmenianChurchFeast: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let type: FeastType
    let date: Date
    let titleHy: String
    let titleRu: String
    let titleEn: String
    let descriptionHy: String
    let descriptionRu: String
    let descriptionEn: String
    let scriptureReading: String
    let prayerHy: String
    let prayerRu: String
    let prayerEn: String
    let isFasting: Bool
    
    func title(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return titleHy
        case .russian: return titleRu
        case .english: return titleEn
        }
    }
    
    func description(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return descriptionHy
        case .russian: return descriptionRu
        case .english: return descriptionEn
        }
    }
    
    func prayer(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return prayerHy
        case .russian: return prayerRu
        case .english: return prayerEn
        }
    }
    
    var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "hy_AM")
        return formatter.string(from: date)
    }
    
    func formattedDate(for lang: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM, EEEE"
        formatter.locale = Locale(identifier: lang.localeCode)
        return formatter.string(from: date)
    }
}

// MARK: - Сервис Церковного календаря и Пасхалии
final class ChurchCalendarService: @unchecked Sendable {
    static let shared = ChurchCalendarService()
    
    private init() {}
    
    // MARK: - Алгоритм вычисления даты Пасхи (Григорианская Пасхалия для ААЦ)
    func calculateEaster(for year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31 // 3 = Март, 4 = Апрель
        let day = ((h + l - 7 * m + 114) % 31) + 1
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "Asia/Yerevan") ?? TimeZone.current
        
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // Вспомогательная функция сдвига даты на N дней
    private func dateByAdding(days: Int, to baseDate: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: baseDate) ?? baseDate
    }
    
    // Воскресенье, ближайшее к указанной дате (день и месяц)
    private func sundayNearest(toMonth month: Int, day: Int, inYear year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        let calendar = Calendar.current
        guard let targetDate = calendar.date(from: components) else { return Date() }
        
        let weekday = calendar.component(.weekday, from: targetDate) // 1 = Sunday
        let diff = (1 - weekday) // сдвиг до воскресенья
        // Ближайшее воскресенье (в пределах +/- 3 дней)
        let adjustedDiff = (diff > 3) ? (diff - 7) : ((diff < -3) ? (diff + 7) : diff)
        return calendar.date(byAdding: .day, value: adjustedDiff, to: targetDate) ?? targetDate
    }
    
    // Вторая суббота указанного месяца
    private func secondSaturday(ofMonth month: Int, inYear year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 12
        let calendar = Calendar.current
        guard let firstDay = calendar.date(from: components) else { return Date() }
        
        let weekday = calendar.component(.weekday, from: firstDay) // 7 = Saturday
        var daysToFirstSat = (7 - weekday) % 7
        if daysToFirstSat < 0 { daysToFirstSat += 7 }
        let firstSat = calendar.date(byAdding: .day, value: daysToFirstSat, to: firstDay) ?? firstDay
        return calendar.date(byAdding: .day, value: 7, to: firstSat) ?? firstSat
    }
    
    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.timeZone = TimeZone(identifier: "Asia/Yerevan") ?? TimeZone.current
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // MARK: - Список всех праздников на указанный год
    func feasts(for year: Int) -> [ArmenianChurchFeast] {
        let easter = calculateEaster(for: year)
        var list: [ArmenianChurchFeast] = []
        
        // 1. Սուրբ Ծնունդ և Աստվածահայտնություն (Рождество и Богоявление — 6 января) [ТАГАВАР 1]
        list.append(ArmenianChurchFeast(
            id: "\(year)_christmas",
            type: .daghavar,
            date: createDate(year: year, month: 1, day: 6),
            titleHy: "Սուրբ Ծնունդ և Աստվածահայտնություն",
            titleRu: "Рождество Христово и Богоявление",
            titleEn: "Holy Nativity and Theophany",
            descriptionHy: "Հայ Առաքելական Եկեղեցին Քրիստոսի Ծնունդը և Մկրտությունը նշում է միասին՝ հունվարի 6-ին: Ողջույնը՝ «Քրիստոս ծնաւ եւ յայտնեցաւ: Ձեզ եւ մեզ մեծ աւետիս»:",
            descriptionRu: "Армянская Апостольская Церковь празднует Рождество и Крещение Господне в один день — 6 января. Приветствие: «Христос родился и явился! Вам и нам благая весть!»",
            descriptionEn: "The Armenian Apostolic Church celebrates the Nativity and Theophany (Baptism) of Jesus Christ together on January 6. Greeting: 'Christ is born and revealed! Blessed is the revelation of Christ!'",
            scriptureReading: "Մատթեոս 1:18-25, Ղուկաս 2:1-20",
            prayerHy: "Փա՜ռք ի բարձունս Աստուծոյ, եւ յերկիր խաղաղութիւն, ի մարդիկ հաճութիւն: Օրհնեալ ես, Տէր Աստուած մեր, որ յայտնեցար ի փրկութիւն աշխարհի:",
            prayerRu: "Слава в вышних Богу, и на земле мир, в человеках благоволение! Благословен Ты, Господи Боже наш, явившийся для спасения мира.",
            prayerEn: "Glory to God in the highest, and on earth peace, good will toward men! Blessed art Thou, Lord our God, who appeared for the salvation of the world.",
            isFasting: false
        ))
        
        // 2. Տյառնընդառաջ (Сретение Господне — 14 февраля)
        list.append(ArmenianChurchFeast(
            id: "\(year)_candlemas",
            type: .dominical,
            date: createDate(year: year, month: 2, day: 14),
            titleHy: "Տյառնընդառաջ (Տրնդեզ)",
            titleRu: "Сретение Господне (Трндез)",
            titleEn: "Feast of the Presentation of the Lord (Trndez)",
            descriptionHy: "Քառասուն օրական Հիսուսի ընծայումը Տաճարին: Լույսի, ջերմության և նորապսակների օրհնության տոն:",
            descriptionRu: "Принесение 40-дневного Младенца Иисуса в Иерусалимский Храм старцу Симеону. Праздник благословения молодоженов и небесного огня Веры.",
            descriptionEn: "The presentation of the 40-day-old infant Jesus to the Temple in Jerusalem. A feast celebrating the Light of Christ and blessing of newly-wed couples.",
            scriptureReading: "Ղուկաս 2:22-40",
            prayerHy: "Լոյս ի յայտնութիւն հեթանոսաց եւ փառք ժողովրդեան քում Իսրայէլի: Տէր Յիսուս, լուսաւորեա՛ զհոգիս մեր Քո ճշմարիտ լոյսով:",
            prayerRu: "Свет к просвещению язычников и славу народа Твоего Израиля. Господи Иисусе, просвети души наши Своим Божественным светом!",
            prayerEn: "A light to lighten the Gentiles, and the glory of Thy people Israel. Lord Jesus, enlighten our souls with Thy true divine light!",
            isFasting: false
        ))
        
        // 3. Սուրբ Սարգիս (День св. Саркиса — суббота за 63 дня до Пасхи)
        let stSarkisDate = dateByAdding(days: -63, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_sarkis",
            type: .saints,
            date: stSarkisDate,
            titleHy: "Սուրբ Սարգիս զորավար",
            titleRu: "День святого полководца Саркиса",
            titleEn: "Feast of St. Sarkis the General",
            descriptionHy: "Երիտասարդների և սիրո բարեխոս Սուրբ Սարգիս զորավարի հիշատակության օր: Նախորդում է 5-օրյա Առաջավորաց պահքը:",
            descriptionRu: "День памяти святого полководца Саркиса — покровителя молодежи, воинов и чистой любви. Предшествует 5-дневному Передовому посту.",
            descriptionEn: "Commemoration of St. Sarkis the General, the patron saint of youth and true love. Preceded by the 5-day Fast of the Catechumens.",
            scriptureReading: "Եփեսացիս 6:10-18",
            prayerHy: "Սուրբդ Աստուծոյ Սարգիս զօրավար, բարեխօսեա՛ առ Քրիստոս Աստուած մեր, փրկել զանձինս մեր ի փորձութեանց:",
            prayerRu: "Святой Божий полководец Саркис, моли Христа Бога нашего о спасении душ наших от всяких искушений и невзгод!",
            prayerEn: "Holy Saint Sarkis, intercede with Christ our God to save our souls from temptation and grant us faith and love!",
            isFasting: false
        ))
        
        // 4. Բուն Բարեկենդան (Истинная Масленица — за 49 дней до Пасхи)
        let barekendanDate = dateByAdding(days: -49, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_barekendan",
            type: .dominical,
            date: barekendanDate,
            titleHy: "Բուն Բարեկենդան",
            titleRu: "Истинная Масленица (Бун Барекендан)",
            titleEn: "Great Barekendan (True Carnival)",
            descriptionHy: "Մեծ Պահքին նախորդող ուրախության և բարի կենդանության տոն, որը խորհրդանշում է մարդու երանական կյանքը Դրախտում:",
            descriptionRu: "Канун Великого Поста, день духовной радости и примирения, символизирующий райскую жизнь прародителей до грехопадения.",
            descriptionEn: "The eve of Great Lent, a joyful celebration representing humanity's blessed life in the Garden of Eden.",
            scriptureReading: "Մատթեոս 6:1-21",
            prayerHy: "Տէր, տուր մեզ զղջում եւ արթնութիւն հոգւոյ, զի արժանապէս մտցուք ի սուրբ պահս Քո:",
            prayerRu: "Господи, даруй нам покаяние и духовную бодрость, чтобы достойно вступить во дни Святого Поста!",
            prayerEn: "Lord, grant us true repentance and vigilance of soul to enter worthily into Thy Holy Fast!",
            isFasting: false
        ))
        
        // 5. Մեծ Պահքի սկիզբ (Начало Великого Поста — понедельник за 48 дней до Пасхи)
        let lentStartDate = dateByAdding(days: -48, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_lent_start",
            type: .fasting,
            date: lentStartDate,
            titleHy: "Մեծ Պահքի սկիզբ",
            titleRu: "Начало Великого Поста",
            titleEn: "Beginning of Great Lent",
            descriptionHy: "Քառասնօրյա ապաշխարության, աղոթքի և հոգևոր մաքրագործման շրջան մինչև Սուրբ Զատիկ:",
            descriptionRu: "Начало 40-дневного периода покаяния, сугубой молитвы, воздержания и духовного очищения перед Светлым Воскресением.",
            descriptionEn: "The beginning of the 40-day period of repentance, prayer, and spiritual purification leading to Holy Easter.",
            scriptureReading: "Եսայի 58:1-14",
            prayerHy: "Բա՛ց մեզ, Տէր, զդուռն ողորմութեան Քո, որ ողբալով կարդամք առ Քեզ:",
            prayerRu: "Отверзи нам, Господи, двери милосердия Твоего, ибо с плачем взываем к Тебе!",
            prayerEn: "Open to us, O Lord, the door of Thy mercy, as we cry out to Thee with tears of repentance!",
            isFasting: true
        ))
        
        // 6. Ավետումն Սուրբ Աստվածածնի (Благовещение — 7 апреля)
        list.append(ArmenianChurchFeast(
            id: "\(year)_annunciation",
            type: .dominical,
            date: createDate(year: year, month: 4, day: 7),
            titleHy: "Ավետումն Սուրբ Աստվածածնի",
            titleRu: "Благовещение Пресвятой Богородицы",
            titleEn: "Annunciation of the Holy Mother of God",
            descriptionHy: "Գաբրիել հրեշտակապետի ավետիսը Կույս Մարիամին Փրկչի ծննդյան մասին: Մայրության և գեղեցկության օրհնության օր:",
            descriptionRu: "Благая весть архангела Гавриила Деве Марии о рождении Спасителя мира. День благословения материнства и женской святости.",
            descriptionEn: "Archangel Gabriel's announcement to the Virgin Mary of the birth of the Savior. Day of Blessing of Motherhood and Beauty.",
            scriptureReading: "Ղուկաս 1:26-38",
            prayerHy: "Ուրախացի՛ր, բերկրեալդ, Տէրն ընդ քեզ. օրհնեալ ես դու ի կանայս եւ օրհնեալ է պտուղ որովայնի քո:",
            prayerRu: "Радуйся, Благодатная! Господь с Тобою; благословенна Ты между женами и благословен плод чрева Твоего!",
            prayerEn: "Hail, Mary, full of grace, the Lord is with thee: blessed art thou among women, and blessed is the fruit of thy womb!",
            isFasting: false
        ))
        
        // 7. Ծաղկազարդ (Вербное Воскресенье — за 7 дней до Пасхи)
        let palmSundayDate = dateByAdding(days: -7, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_palm_sunday",
            type: .dominical,
            date: palmSundayDate,
            titleHy: "Ծաղկազարդ (Ծառզարդար)",
            titleRu: "Вербное Воскресенье (Цахказард)",
            titleEn: "Palm Sunday (Tsakhkazard)",
            descriptionHy: "Հիսուս Քրիստոսի հաղթական մուտքը Երուսաղեմ: Մանուկների օրհնության տոն:",
            descriptionRu: "Торжественный вход Господень в Иерусалим. Праздник благословения детей и вербовых ветвей.",
            descriptionEn: "The Triumphal Entry of Jesus Christ into Jerusalem. Day of blessing of children and olive/palm branches.",
            scriptureReading: "Մատթեոս 21:1-11",
            prayerHy: "Օվսաննա՜ ի բարձունս, օրհնեալ որ գաս յանուն Տեառն: Թագաւոր Իսրայէլի, փրկեա՛ զմեզ:",
            prayerRu: "Осанна в вышних! Благословен Грядущий во имя Господне! Царь Израилев, спаси нас!",
            prayerEn: "Hosanna in the highest! Blessed is He who comes in the name of the Lord! O King of Glory, save us!",
            isFasting: false
        ))
        
        // 8. Ավագ Ուրբաթ (Великая Пятница — за 2 дня до Пасхи)
        let goodFridayDate = dateByAdding(days: -2, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_good_friday",
            type: .fasting,
            date: goodFridayDate,
            titleHy: "Ավագ Ուրբաթ (Խաչելության օր)",
            titleRu: "Великая Пятница (Страсти Господни)",
            titleEn: "Great and Holy Friday (Crucifixion)",
            descriptionHy: "Տեր Հիսուս Քրիստոսի չարչարանքների, խաչելության, մահվան և թաղման հիշատակության ամենախորհրդավոր օրը:",
            descriptionRu: "Воспоминание святых спасительных Страстей, распятия, крестной смерти и погребения Господа нашего Иисуса Христа.",
            descriptionEn: "Commemoration of the holy and salvific Passion, Crucifixion, Death, and Burial of our Lord Jesus Christ.",
            scriptureReading: "Հովհաննես 19:1-37, Մատթեոս 27:1-61",
            prayerHy: "Խաչի Քո, Քրիստոս, երկիրպագանեմք, եւ զսուրբ զԹաղումն Քո մեծացուցանեմք, եւ զսուրբ զՅարութիւն Քո փառաւորեմք:",
            prayerRu: "Кресту Твоему поклоняемся, Владыко, и святое погребение Твое величаем, и святое Воскресение Твое славим!",
            prayerEn: "We bow before Thy Cross, O Christ, we magnify Thy Holy Burial, and we glorify Thy Holy Resurrection!",
            isFasting: true
        ))
        
        // 9. ՍՈՒՐԲ ՀԱՐՈՒԹՅՈՒՆ / ԶԱՏԻԿ (СВЯТАЯ ПАСХА) [ТАГАВАР 2]
        list.append(ArmenianChurchFeast(
            id: "\(year)_easter",
            type: .daghavar,
            date: easter,
            titleHy: "Սուրբ Հարություն (Սուրբ Զատիկ)",
            titleRu: "Светлое Христово Воскресение (Пасха)",
            titleEn: "Feast of the Glorious Resurrection (Holy Easter)",
            descriptionHy: "Քրիստոնեական մեծագույն տոնը՝ Հիսուս Քրիստոսի Հարությունը մեռելներից: Ողջույնը՝ «Քրիստոս յարեաւ ի մեռելոց: Օրհնեալ է յարութիւնն Քրիստոսի»:",
            descriptionRu: "Величайший христианский праздник — Воскресение Господа Иисуса Христа из мертвых, победа над смертью и адом. «Христос воскрес из мертвых! Благословенно Воскресение Христово!»",
            descriptionEn: "The greatest Christian feast — the Resurrection of Jesus Christ from the dead. Greeting: 'Christ is risen from the dead! Blessed is the Resurrection of Christ!'",
            scriptureReading: "Մատթեոս 28:1-20, Հովհաննես 20:1-18",
            prayerHy: "Քրիստոս յարեաւ ի մեռելոց, մահուամբ զմահ կոխեաց, եւ որոց ի գերեզմանս էին՝ կեանս պարգեւեաց:",
            prayerRu: "Христос воскрес из мертвых, смертию смерть поправ, и сущим во гробех жизнь даровав!",
            prayerEn: "Christ is risen from the dead, trampling down death by death, and upon those in the tombs bestowing life!",
            isFasting: false
        ))
        
        // 10. Համբարձում (Вознесение Господне — 40-й день после Пасхи)
        let ascensionDate = dateByAdding(days: 39, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_ascension",
            type: .dominical,
            date: ascensionDate,
            titleHy: "Համբարձում Տեառն",
            titleRu: "Вознесение Господне",
            titleEn: "Feast of the Ascension of the Lord",
            descriptionHy: "Հիսուս Քրիստոսի երկինք համբարձվելու և Հոր աջ կողմը նստելու տոնը:",
            descriptionRu: "Празднование восшествия Господа Иисуса Христа во плоти на Небеса к Престолу Бога Отца.",
            descriptionEn: "Commemoration of the bodily Ascension of Jesus Christ into Heaven in the presence of His disciples.",
            scriptureReading: "Գործք Առաքելոց 1:1-11",
            prayerHy: "Համբարձաւ Աստուած օրհնութեամբ, եւ Տէր մեր ձայնիւ փողոյ: Փա՜ռք Համբարձման Քո, Տէր:",
            prayerRu: "Восшел Бог при восклицаниях, Господь при звуке трубном. Слава Вознесению Твоему, Господи!",
            prayerEn: "God is gone up with a shout, the Lord with the sound of a trumpet. Glory to Thy Ascension, O Lord!",
            isFasting: false
        ))
        
        // 11. Հոգեգալուստ (Пятидесятница — 50-й день после Пасхи)
        let pentecostDate = dateByAdding(days: 49, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_pentecost",
            type: .dominical,
            date: pentecostDate,
            titleHy: "Հոգեգալուստ (Պենտեկոստե)",
            titleRu: "Пятидесятница (Сошествие Святого Духа)",
            titleEn: "Pentecost (Descent of the Holy Spirit)",
            descriptionHy: "Սուրբ Հոգու էջքը առաքյալների վրա և Քրիստոսի Եկեղեցու հիմնադրման տոնը:",
            descriptionRu: "Сошествие Святого Духа на апостолов в виде огненных языков. День рождения Церкви Христовой.",
            descriptionEn: "The descent of the Holy Spirit upon the Apostles in the form of fiery tongues. Birthday of the Church.",
            scriptureReading: "Գործք Առաքելոց 2:1-21",
            prayerHy: "Ե՛կ, Հոգի՛ Սուրբ, եւ լի՛ց զսիրտս հաւատացելոց Քոց, եւ զհուր սիրոյ Քո բորբոքեա՛ ի նոսա:",
            prayerRu: "Царю Небесный, Утешителю, Душе истины, прииди и вселися в ны, и очисти ны от всякия скверны!",
            prayerEn: "O Heavenly King, the Comforter, the Spirit of Truth, come and abide in us and cleanse us from all impurity!",
            isFasting: false
        ))
        
        // 12. ՊԱՅԾԱՌԱԿԵՐՊՈՒԹՅՈՒՆ / ՎԱՐԴԱՎԱՌ (Преображение Господне / Вардавар — 14-е воскресенье после Пасхи / 98-й день) [ТАГАВАР 3]
        let vardavarDate = dateByAdding(days: 98, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_vardavar",
            type: .daghavar,
            date: vardavarDate,
            titleHy: "Պայծառակերպություն (Վարդավառ)",
            titleRu: "Преображение Господне (Вардавар)",
            titleEn: "Transfiguration of the Lord (Vardavar)",
            descriptionHy: "Քրիստոսի աստվածային փառքի պայծառացումը Թաբոր լեռան վրա: Ավանդական ջրցանի և հոգևոր մաքրության տոն:",
            descriptionRu: "Явление Божественного величия и славы Спасителя на горе Фавор перед апостолами. Праздник духовного преображения и благословения водой.",
            descriptionEn: "The revelation of Christ's divine glory on Mount Tabor. Traditional Armenian celebration with sprinkling of water.",
            scriptureReading: "Մատթեոս 17:1-9, Ղուկաս 9:28-36",
            prayerHy: "Պայծառացո՛, Տէր, զխաւարեալ հոգիս մեր Թաբորական լուսով Քո, եւ արժանի արա՛ տեսանել զփառս Քո:",
            prayerRu: "Преобразился еси на горе, Христе Боже, показавый учеником Твоим славу Твою. Просвети и нас светом Твоим присносущным!",
            prayerEn: "Thou wast transfigured on the mountain, O Christ God, revealing Thy glory to Thy disciples. Shine Thy eternal light upon us!",
            isFasting: false
        ))
        
        // 13. ՎԵՐԱՓՈԽՈՒՄՆ ՍՈՒՐԲ ԱՍՏՎԱԾԱԾՆԻ (Успение Пресвятой Богородицы — воскресенье, ближайшее к 15 августа) [ТАГАВАР 4]
        let asdvadzadzinDate = sundayNearest(toMonth: 8, day: 15, inYear: year)
        list.append(ArmenianChurchFeast(
            id: "\(year)_assumption",
            type: .daghavar,
            date: asdvadzadzinDate,
            titleHy: "Վերափոխումն Սուրբ Աստվածածնի",
            titleRu: "Успение Пресвятой Богородицы",
            titleEn: "Assumption of the Holy Mother of God",
            descriptionHy: "Աստվածամոր երկինք վերափոխման տոնը: Ավանդական խաղողօրհնեքի և բերքի օրհնության մեծ հանդիսություն:",
            descriptionRu: "Вознесение Божией Матери с душой и телом на Небеса. Традиционный чин освящения винограда и начатков плодов.",
            descriptionEn: "The Dormition and bodily Assumption of the Holy Mother of God into Heaven. Blessing of the Grapes ceremony.",
            scriptureReading: "Ղուկաս 1:39-56, Գաղատացիս 4:4-7",
            prayerHy: "Անկանիմք առաջի քո, Սուրբ Աստուածածին, եւ աղաչեմք զանարատ զկոյսդ. բարեխօսեա՛ վասն անձանց մերոց:",
            prayerRu: "Под твою милость прибегаем, Богородице Дево, молитв наших не презри в скорбех, но от бед избави нас!",
            prayerEn: "We fly to thy patronage, O holy Mother of God; despise not our petitions in our necessities, but deliver us from all dangers!",
            isFasting: false
        ))
        
        // 14. ԽԱՉՎԵՐԱՑ (Воздвижение Креста Господня — воскресенье, ближайшее к 14 сентября) [ТАГАВАР 5]
        let khachveratsDate = sundayNearest(toMonth: 9, day: 14, inYear: year)
        list.append(ArmenianChurchFeast(
            id: "\(year)_exaltation_cross",
            type: .daghavar,
            date: khachveratsDate,
            titleHy: "Խաչվերաց",
            titleRu: "Воздвижение Честного Креста (Хачверац)",
            titleEn: "Exaltation of the Holy Cross (Khachverats)",
            descriptionHy: "Քրիստոսի Սուրբ Խաչափայտի պարսկական գերությունից ազատագրման և հանդիսավոր բարձրացման (վերացման) տոնը:",
            descriptionRu: "Возвращение Животворящего Креста Господня из персидского плена в Иерусалим и его торжественное воздвижение в храме Воскресения.",
            descriptionEn: "The recovery of the True Cross of Christ from Persian captivity and its elevation for veneration.",
            scriptureReading: "Հովհաննես 19:16-37, 1 Կորնթացիս 1:18-25",
            prayerHy: "Խաչ քո եղիցի մեզ ապաւէն, Տէր Յիսուս, յորժամ գաս փառօք Հօր դատել զերկիր:",
            prayerRu: "Крест Твой да будет нам прибежищем и защитой, Господи Иисусе, когда придешь судить вселенную!",
            prayerEn: "May Thy Holy Cross be our refuge and protection, Lord Jesus, when Thou comest in glory to judge the world!",
            isFasting: false
        ))
        
        // 15. Սուրբ Թարգմանչաց տոն (День святых Переводчиков — 2-я суббота октября)
        let targmanchatsDate = secondSaturday(ofMonth: 10, inYear: year)
        list.append(ArmenianChurchFeast(
            id: "\(year)_targmanchats",
            type: .saints,
            date: targmanchatsDate,
            titleHy: "Սուրբ Թարգմանչաց տոն",
            titleRu: "День святых Переводчиков (Таргманчац)",
            titleEn: "Feast of the Holy Translators",
            descriptionHy: "Սուրբ Մեսրոպ Մաշտոցի, Սահակ Պարթևի և նրանց աշակերտների հիշատակության օրը, որոնք հայերեն թարգմանեցին Սուրբ Գիրքը («Թարգմանությունների Թագուհին»):",
            descriptionRu: "Праздник создателей армянской письменности и переводчиков Библии на армянский язык — святых Месропа Маштоца, Саака Партева и их учеников.",
            descriptionEn: "Commemoration of Holy Translators Sts. Mesrop Mashtots and Sahak Partev, who translated the Bible into Armenian ('Queen of Translations').",
            scriptureReading: "Առակաց 1:1-7, 1 Կորնթացիս 14:1-19",
            prayerHy: "Որք զարդարեցին զիմաստս Անեղին, յօրինելով զգիրս հայկականս. բարեխօսեցէ՛ք առ Տէր վասն մեր:",
            prayerRu: "Украсившие мудростью Создателя письмена армянские, святые переводчики, молите Бога о нашем просвещении!",
            prayerEn: "You who adorned the wisdom of the Uncreated God by creating the Armenian alphabet, pray to the Lord for our spiritual enlightenment!",
            isFasting: false
        ))
        
        return list.sorted { $0.date < $1.date }
    }
    
    // MARK: - Праздник на сегодня (если есть)
    func todayFeast() -> ArmenianChurchFeast? {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let allFeasts = feasts(for: year)
        
        return allFeasts.first { calendar.isDate($0.date, inSameDayAs: today) }
    }
    
    // MARK: - Ближайший Великий праздник (Тагавар)
    func nextDaghavarFeast() -> (feast: ArmenianChurchFeast, daysLeft: Int)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let year = calendar.component(.year, from: today)
        
        var candidates = feasts(for: year).filter { $0.type == .daghavar && calendar.startOfDay(for: $0.date) >= today }
        
        if candidates.isEmpty {
            // Если в этом году все тагавары прошли, берем Рождество следующего года
            candidates = feasts(for: year + 1).filter { $0.type == .daghavar }
        }
        
        guard let next = candidates.first else { return nil }
        let nextDay = calendar.startOfDay(for: next.date)
        let diff = calendar.dateComponents([.day], from: today, to: nextDay).day ?? 0
        return (next, max(0, diff))
    }
    
    // MARK: - Генератор iCalendar (.ics) файла для Apple Calendar / Google Calendar
    func generateICSFile(for year: Int, language: AppLanguage) -> URL? {
        let allFeasts = feasts(for: year)
        var icsString = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Samvel//Armenian Bible Church Calendar//HY
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        X-WR-CALNAME:\("church_calendar_title".localized(for: language)) \(year)
        X-WR-TIMEZONE:Asia/Yerevan
        
        """
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Yerevan")
        
        let nowFormatter = DateFormatter()
        nowFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        nowFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let nowStr = nowFormatter.string(from: Date())
        
        for feast in allFeasts {
            let dtStart = dateFormatter.string(from: feast.date)
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: feast.date) ?? feast.date
            let dtEnd = dateFormatter.string(from: nextDay)
            
            let summary = "\(feast.type.icon) \(feast.title(for: language))"
            var desc = feast.description(for: language)
            if !feast.scriptureReading.isEmpty {
                desc += "\\n\\n📖 \("scripture_readings_title".localized(for: language)): \(feast.scriptureReading)"
            }
            if !feast.prayer(for: language).isEmpty {
                desc += "\\n\\n🙏 \("prayer_title".localized(for: language)): \(feast.prayer(for: language))"
            }
            
            icsString += """
            BEGIN:VEVENT
            UID:\(feast.id)_\(year)@armenianbible.app
            DTSTAMP:\(nowStr)
            DTSTART;VALUE=DATE:\(dtStart)
            DTEND;VALUE=DATE:\(dtEnd)
            SUMMARY:\(summary)
            DESCRIPTION:\(desc)
            STATUS:CONFIRMED
            TRANSP:TRANSPARENT
            BEGIN:VALARM
            ACTION:DISPLAY
            DESCRIPTION:\(summary)
            TRIGGER:-P1D
            END:VALARM
            END:VEVENT
            
            """
        }
        
        icsString += "END:VCALENDAR"
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("ArmenianChurchCalendar_\(year).ics")
        
        do {
            try icsString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing .ics file: \(error)")
            return nil
        }
    }
}
