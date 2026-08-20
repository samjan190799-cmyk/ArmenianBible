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
    let meaningHy: String
    let meaningRu: String
    let meaningEn: String
    let traditionsHy: String
    let traditionsRu: String
    let traditionsEn: String
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
    
    func meaning(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return meaningHy.isEmpty ? descriptionHy : meaningHy
        case .russian: return meaningRu.isEmpty ? descriptionRu : meaningRu
        case .english: return meaningEn.isEmpty ? descriptionEn : meaningEn
        }
    }
    
    func traditions(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return traditionsHy
        case .russian: return traditionsRu
        case .english: return traditionsEn
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
    
    func daysRemaining(from baseDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: baseDate)
        let startOfFeast = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfFeast).day ?? 0
    }
    
    func countdownBadge(for lang: AppLanguage, from baseDate: Date = Date()) -> (text: String, isToday: Bool, isUpcoming: Bool) {
        let diff = daysRemaining(from: baseDate)
        if diff == 0 {
            return ("days_left_today".localized(for: lang), true, true)
        } else if diff == 1 {
            return ("days_left_tomorrow".localized(for: lang), false, true)
        } else if diff > 1 {
            let format = "days_left_in".localized(for: lang)
            return (String(format: format, diff), false, true)
        } else {
            return ("days_left_passed".localized(for: lang), false, false)
        }
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
        
        let weekday = calendar.component(.weekday, from: targetDate)
        let diff = (1 - weekday)
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
        
        let weekday = calendar.component(.weekday, from: firstDay)
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
    
    // MARK: - Список абсолютно всех праздников на указанный год
    func feasts(for year: Int) -> [ArmenianChurchFeast] {
        let easter = calculateEaster(for: year)
        var list: [ArmenianChurchFeast] = []
        
        // --- 1. ЯНВАРЬ (ՀՈՒՆՎԱՐ) ---
        
        // Рождественский Сочельник (Ճրագալույց Սուրբ Ծննդյան — 5 января)
        list.append(ArmenianChurchFeast(
            id: "\(year)_christmas_eve",
            type: .dominical,
            date: createDate(year: year, month: 1, day: 5),
            titleHy: "Ճրագալույց Սուրբ Ծննդյան",
            titleRu: "Рождественский Сочельник (Чрагалуйц)",
            titleEn: "Christmas Eve (Jrakalouyts)",
            descriptionHy: "Սուրբ Ծննդյան նախատոնակը: Երեկոյան մատուցվում է Ճրագալույցի Սուրբ Պատարագ, և հավատացյալները տուն են տանում եկեղեցուց վառված կանթեղների լույսը:",
            descriptionRu: "Навечерие Рождества Христова. Вечером совершается торжественная Литургия Сочельника (Чрагалуйц — возжжение светильников), знаменующая сияние Вифлеемской звезды.",
            descriptionEn: "Eve of the Holy Nativity. The Jrakalouyts (lighting of the lamps) Divine Liturgy is celebrated in the evening, sharing the divine light of the Star of Bethlehem.",
            meaningHy: "«Ճրագալույց» նշանակում է ճրագ (լույս) լուցանել, վառել: Այն խորհրդանշում է Բեթղեհեմյան աստղի աստվածային լույսը, որն առաջնորդեց մոգերին դեպի Մանուկ Հիսուսը:",
            meaningRu: "«Чрагалуйц» означает возжжение лампад и свечей. Праздник напоминает о свете Вифлеемской звезды, приведшей волхвов к яслям Спасителя, рассеивая тьму греха.",
            meaningEn: "Jrakalouyts symbolizes the divine light of the Star of Bethlehem that guided the Magi to the Infant Jesus, dispersing spiritual darkness.",
            traditionsHy: "Պատարագից հետո տուն են տանում օրհնված կրակը: Ընտանիքները հավաքվում են տոնական սեղանի շուրջ՝ ձուկ, չամիչով փլավ և գինի ճաշակելու:",
            traditionsRu: "После Литургии верующие уносят домой частицу благодатного огня. За ужином вкушают рыбу, плов с изюмом и сухофруктами, зелень и красное вино.",
            traditionsEn: "Faithful take blessed candle flames to their homes. The traditional dinner includes fish, rice pilaf with raisins, greens, and wine.",
            scriptureReading: "Տիտոս 2:11-15, Մատթեոս 2:1-12",
            prayerHy: "Լոյս ի լուսոյ, Ճշմարիտ Աստուած, ծագեա՛ ի հոգիս մեր զլոյս Քոյիդ աստուածութեան:",
            prayerRu: "Свет от Света, Боже Истинный, озари сердца наши светом Твоего Богоявления!",
            prayerEn: "Light of Light, True God, shine into our hearts the radiant light of Thy divinity!",
            isFasting: false
        ))
        
        // 1. ՍՈՒՐԲ ԾՆՈՒՆԴ ԵՎ ԱՍՏՎԱԾԱՀԱՅՏՆՈՒԹՅՈՒՆ (6 января) [ТАГАВАР 1]
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
            meaningHy: "Աստված մարդացավ, որպեսզի մարդուն աստվածացնի: Քրիստոսի Ծնունդով և Հորդանանում Մկրտությամբ մարդկությանը բացվեց Սուրբ Երրորդության խորհուրդը:",
            meaningRu: "Бог стал человеком, чтобы человек обожился. В этот день вспоминается воплощение Сына Божия и явление Святой Троицы при Его крещении в реке Иордан.",
            meaningEn: "God became man so that man might unite with God. This feast commemorates both the Incarnation of Christ and the revelation of the Holy Trinity at the Jordan River.",
            traditionsHy: "Պատարագից հետո կատարվում է Ջրօրհնեքի կարգ (Հորդանանօրհնեք): Հավատացյալները խմում են օրհնված ջուրը և տանում տուն՝ որպես բժշկության և օրհնության աղբյուր:",
            traditionsRu: "Совершается чин Водоосвящения (Джрордзнек). Освященная крестом и миром вода раздается верующим для исцеления души и тела и освящения жилища.",
            traditionsEn: "The Blessing of the Water ceremony (Jrorhnek) is performed with the Holy Cross and Holy Chrism (Muron), distributing holy water for healing and blessings.",
            scriptureReading: "Մատթեոս 1:18-25, Ղուկաս 2:1-20, Մատթեոս 3:13-17",
            prayerHy: "Փա՜ռք ի բարձունս Աստուծոյ, եւ յերկիր խաղաղութիւն, ի մարդիկ հաճութիւն: Օրհնեալ ես, Տէր Աստուած մեր, որ յայտնեցար ի փրկութիւն աշխարհի:",
            prayerRu: "Слава в вышних Богу, и на земле мир, в человеках благоволение! Благословен Ты, Господи Боже наш, явившийся для спасения мира.",
            prayerEn: "Glory to God in the highest, and on earth peace, good will toward men! Blessed art Thou, Lord our God, who appeared for the salvation of the world.",
            isFasting: false
        ))
        
        // Поминовение усопших (Մեռելոց — 7 января)
        list.append(ArmenianChurchFeast(
            id: "\(year)_christmas_merelots",
            type: .dominical,
            date: createDate(year: year, month: 1, day: 7),
            titleHy: "Մեռելոց (Հիշատակ մեռելոց)",
            titleRu: "День поминовения усопших (Мерелоц)",
            titleEn: "Day of Remembrance of the Dead (Merelots)",
            descriptionHy: "Սուրբ Ծննդյան Տաղավար տոնին հաջորդող հիշատակության օր: Մատուցվում է հոգեհանգստյան Պատարագ բոլոր ննջեցյալների հոգիների խաղաղության համար:",
            descriptionRu: "День молитвы обо всех усопших, следующий за праздником Рождества. Служится заупокойная Литургия и панихида.",
            descriptionEn: "Memorial Day following Holy Nativity. Memorial Divine Liturgy and prayers for the repose of the souls of all departed loved ones.",
            meaningHy: "Մահը վերջ չէ, այլ անցում հավիտենական կյանք: Մենք աղոթում ենք մեր ննջեցյալների համար՝ նրանց փոխանցելով Քրիստոսի Ծննդյան ավետիսը:",
            meaningRu: "Христиане не скорбят как не имеющие надежды. Мы делимся благой вестью о Рождении Спасителя с душами усопших предков.",
            meaningEn: "Death is not the end but a passage to eternal life. We pray for our departed brothers and sisters, sharing the joyful news of Christ's coming.",
            traditionsHy: "Այցելություն գերեզմաններ, հոգեհանգստյան աղոթք և բարեգործություն ննջեցյալների հիշատակին:",
            traditionsRu: "Посещение могил близких, священническое благословение (Океханкист) и дела милосердия в память об усопших.",
            traditionsEn: "Visiting family resting places, graveside prayers by clergy, and charitable deeds in memory of the departed.",
            scriptureReading: "1 Կորնթացիս 15:12-28, Հովհաննես 5:24-30",
            prayerHy: "Քրիստոս Աստուած, հանգո՛ զհոգիս ննջեցելոց ծառայից Քոց ի լուսաւոր եւ ի հանգստեան օթեւանս Քո:",
            prayerRu: "Упокой, Господи, души усопших рабов Твоих в месте светле, в месте покойне, идеже несть болезнь, ни печаль, ни воздыхание!",
            prayerEn: "O Christ our God, grant rest to the souls of Thy departed servants in Thy mansions of light and peace!",
            isFasting: false
        ))
        
        // Наречение Имени Господня (Անվանակոչություն Տեառն — 13 января)
        list.append(ArmenianChurchFeast(
            id: "\(year)_naming_of_jesus",
            type: .dominical,
            date: createDate(year: year, month: 1, day: 13),
            titleHy: "Անվանակոչություն Տեառն",
            titleRu: "Наречение Имени Господня",
            titleEn: "Naming of Our Lord Jesus Christ",
            descriptionHy: "Սուրբ Ծննդից հետո 8-րդ օրը Մանուկ Հիսուսը թլփատվեց և ստացավ «Հիսուս» (Փրկիչ) անունը, ինչպես պատվիրել էր հրեշտակը:",
            descriptionRu: "На 8-й день по Рождестве Богомладенец принял наречение спасительного Имени «Иисус» (Яхве спасает), возвещенного Архангелом Гавриилом.",
            descriptionEn: "On the 8th day after Nativity, the Infant was circumcised and given the holy name 'Jesus' (Savior), as commanded by the angel.",
            meaningHy: "Հիսուսի Անունը զորություն է և փրկություն: Այս օրը հիշեցնում է, որ Նրա անունով է մարդկությունը ստանում մեղքերի թողություն:",
            meaningRu: "Имя Иисуса — источник спасения, исцеления и духовной победы для всякого верующего человека.",
            meaningEn: "The Name of Jesus is our salvation and strength; at His name every knee shall bow in heaven and on earth.",
            traditionsHy: "Եկեղեցում կատարվում է տոնական ժամերգություն և մանուկների օրհնություն:",
            traditionsRu: "Праздничное богослужение и молитва об именинниках.",
            traditionsEn: "Festive services and blessings for all named after the Lord.",
            scriptureReading: "Ղուկաս 2:21, Կողոսացիս 2:8-15",
            prayerHy: "Յանուն Յիսուսի Քրիստոսի ամենայն ծունր կրկնեսցի երկնաւորաց եւ երկրաւորաց:",
            prayerRu: "Пред Именем Иисуса да преклонится всякое колено небесных, земных и преисподних!",
            prayerEn: "At the name of Jesus every knee should bow, of things in heaven, and things in earth!",
            isFasting: false
        ))
        
        // Рождество св. Иоанна Предтечи (Ծնունդ Սուրբ Հովհաննու Կարապետի — 15 января)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_john_baptist",
            type: .saints,
            date: createDate(year: year, month: 1, day: 15),
            titleHy: "Ծնունդ Սուրբ Հովհաննու Կարապետի",
            titleRu: "Рождество святого Иоанна Предтечи",
            titleEn: "Nativity of St. John the Forerunner",
            descriptionHy: "Քրիստոսի Կարապետի և Մկրտչի հիշատակության օրը: Նա ճանապարհ հարթեց Տիրոջ գալստյան համար:",
            descriptionRu: "Память величайшего из пророков — Крестителя Господня Иоанна, проповедника покаяния и очищения сердец.",
            descriptionEn: "Commemoration of the greatest prophet and Forerunner of Christ, who prepared the way of the Lord.",
            meaningHy: "Հովհաննես Մկրտիչը կոչ էր անում ապաշխարության՝ սովորեցնելով մաքրել սիրտը Տիրոջը դիմավորելու համար:",
            meaningRu: "Святой Иоанн учит нас истинному покаянию, чистоте совести и верности истине даже перед лицом смерти.",
            meaningEn: "St. John calls us to true repentance, humility, and steadfast witness to God's truth.",
            traditionsHy: "Ուխտագնացություն Սուրբ Կարապետի անունը կրող վանքեր և եկեղեցիներ:",
            traditionsRu: "Особое почитание в монастырях Сурб Карапет, молитвы об укреплении в вере и посте.",
            traditionsEn: "Pilgrimages to churches dedicated to St. John the Baptist and prayers for spiritual courage.",
            scriptureReading: "Ղուկաս 1:57-80",
            prayerHy: "Կարապե՛տ Քրիստոսի եւ Մկրտի՛չ, բարեխօսեա՛ առ Տէր վասն անձանց մերոց:",
            prayerRu: "Крестителю Христов, покаяния проповедниче, моли Бога о нас грешных!",
            prayerEn: "Forerunner and Baptist of Christ, intercede with the Lord for the salvation of our souls!",
            isFasting: false
        ))
        
        // Преподобный Антоний Великий (Սուրբ Անտոն Անապատական — 18 января)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_anthony",
            type: .saints,
            date: createDate(year: year, month: 1, day: 18),
            titleHy: "Սուրբ Անտոն Անապատական",
            titleRu: "Преподобный Антоний Великий",
            titleEn: "St. Anthony the Great",
            descriptionHy: "Ճգնավորական կյանքի և վանականության հիմնադիր հայրերից մեծագույնը:",
            descriptionRu: "Основоположник христианского монашества и пустынножительства, великий учитель духовной брани.",
            descriptionEn: "The Father of Christian Monasticism and desert hermit life, renowned for spiritual wisdom.",
            meaningHy: "Աղոթքի, լռության և ինքնահաղթահարման օրինակ՝ աշխարհիկ գայթակղությունների դեմ:",
            meaningRu: "Пример победы над греховными помыслами и искушениями через непрестанную молитву и воздержание.",
            meaningEn: "An enduring example of victory over temptation through ceaseless prayer and humility.",
            traditionsHy: "Ճգնողական աղոթքների ընթերցում վանքերում:",
            traditionsRu: "Молитвы об избавлении от духовных недугов и уныния.",
            traditionsEn: "Reading of ascetic treatises and prayers for spiritual endurance.",
            scriptureReading: "Մատթեոս 19:16-26",
            prayerHy: "Սուրբ հայր Անտոն, ուսո՛ մեզ զաղօթս եւ զպահս ի փրկութիւն հոգւոյ:",
            prayerRu: "Преподобне отче Антоние, моли милостивого Бога о спасении душ наших!",
            prayerEn: "Holy Father Anthony, teach us true vigilance and prayer for the salvation of our souls!",
            isFasting: false
        ))
        
        // --- 2. ФЕВРАЛЬ (ՓԵՏՐՎԱՐ) & ПЕРЕДОВОЙ ПОСТ ---
        
        // Передовой пост (Առաջավորաց պահք — за 69 дней до Пасхи)
        let catechumensFastDate = dateByAdding(days: -69, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_fast_catechumens",
            type: .fasting,
            date: catechumensFastDate,
            titleHy: "Առաջավորաց պահքի սկիզբ",
            titleRu: "Начало Передового поста (Араджаворац)",
            titleEn: "Fast of the Catechumens (Arachavorats)",
            descriptionHy: "Հայ Եկեղեցու ամենահին 5-օրյա պահքը, որը հաստատել է Սուրբ Գրիգոր Լուսավորիչը Հայաստանի դարձի ժամանակ:",
            descriptionRu: "Уникальный 5-дневный пост Армянской Церкви, установленный св. Григорием Просветителем в память о всенародном покаянии царя Трдата и обращении Армении.",
            descriptionEn: "An ancient 5-day fast instituted by St. Gregory the Illuminator commemorating the repentance and baptism of Armenia.",
            meaningHy: "Առաջավորաց պահքը հիշեցնում է Նինվեի ապաշխարության և Հայոց ազգի մաքրագործման մասին մինչև քրիստոնեության ընդունումը:",
            meaningRu: "Символ глубокого покаяния, подобного покаянию ниневитян, открывающего путь к духовному возрождению.",
            meaningEn: "A profound call to national and personal repentance, opening the heart to God's grace.",
            traditionsHy: "Խիստ պահք երկուշաբթիից ուրբաթ՝ հրաժարվելով կենդանական սննդից:",
            traditionsRu: "Строгий пост с понедельника по пятницу с усердным чтением покаянных молитв.",
            traditionsEn: "Strict fasting from Monday through Friday with special penitential services.",
            scriptureReading: "Հովնան 3:1-10",
            prayerHy: "Տէ՛ր, որ ողորմեցար Նինուէացւոց ապաշխարութեամբ, ողորմեա՛ եւ մեզ բազմամեղացս:",
            prayerRu: "Господи, помиловавший ниневитян ради их покаяния, помилуй и нас, грешных!",
            prayerEn: "Lord, who showed mercy to the Ninevites in their repentance, have mercy upon us!",
            isFasting: true
        ))
        
        // 3. Սուրբ Սարգիս զորավար (за 63 дня до Пасхи — суббота)
        let stSarkisDate = dateByAdding(days: -63, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_sarkis",
            type: .saints,
            date: stSarkisDate,
            titleHy: "Սուրբ Սարգիս զորավար",
            titleRu: "День святого полководца Саркиса",
            titleEn: "Feast of St. Sarkis the General",
            descriptionHy: "Երիտասարդների, զինվորների և սիրո բարեխոս Սուրբ Սարգիս զորավարի, նրա որդի Մարտիրոսի և 14 զինվորների հիշատակության օրը:",
            descriptionRu: "Память святого полководца Саркиса, его сына Мартироса и 14 воинов. Покровитель молодежи, чистой любви, защитников отечества.",
            descriptionEn: "Commemoration of St. Sarkis the General, his son Mardiros, and 14 brave soldiers. Patron saint of youth and genuine love.",
            meaningHy: "Սուրբ Սարգիսը նահատակվեց հանուն Քրիստոսի՝ մերժելով կռապաշտությունը: Նա սովորեցնում է լինել անսասան հավատքի և ազնիվ սիրո մեջ:",
            meaningRu: "Святой Саркис явил пример несокрушимого мужества и верности Христу, защищая христиан от гонений.",
            meaningEn: "St. Sarkis exemplifies unshakeable courage, purity of heart, and dedication to God.",
            traditionsHy: "Երիտասարդների օրհնության կարգ եկեղեցիներում, աղի բլիթի ավանդույթ:",
            traditionsRu: "Благословение молодежи в храмах, народный обычай соленой лепешки (ахи блят) накануне праздника.",
            traditionsEn: "Blessing of youth in churches and traditional salt biscuit customs on the eve of the feast.",
            scriptureReading: "Եփեսացիս 6:10-18, Մատթեոս 10:37-42",
            prayerHy: "Սուրբդ Աստուծոյ Սարգիս զօրավար, բարեխօսեա՛ առ Քրիստոս Աստուած մեր, փրկել զանձինս մեր ի փորձութեանց:",
            prayerRu: "Святой Божий полководец Саркис, моли Христа Бога нашего о спасении душ наших от всяких искушений!",
            prayerEn: "Holy Saint Sarkis, intercede with Christ our God to save our souls from all tribulations!",
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
            descriptionHy: "Քառասուն օրական Հիսուսի ընծայումը Տաճարին: Լույսի, ջերմության և նորապսակների օրհնության մեծ տոն:",
            descriptionRu: "Принесение 40-дневного Младенца Иисуса в Иерусалимский Храм праведному Симеону Богоприимцу. Праздник благословения молодоженов.",
            descriptionEn: "The presentation of the 40-day-old infant Jesus to the Temple in Jerusalem. A feast celebrating the Light of Christ and blessing of newly-weds.",
            meaningHy: "«Տեառնընդառաջ» նշանակում է գնալ Տիրոջն ընդառաջ: Այն խորհրդանշում է մարդու հանդիպումը Աստծո հետ և Քրիստոսի լույսի ընդունումը:",
            meaningRu: "«Сретение» означает встречу Ветхого и Нового Заветов, встречу души с Богом. Старец Симеон узрел Спасение мира.",
            meaningEn: "The meeting of humanity with its Creator. St. Simeon received the Savior in his arms as the light to enlighten the world.",
            traditionsHy: "Եկեղեցու բակում վառվում է տոնական խարույկը, որից հավատացյալները լույս են տանում տուն: Նորապսակների օրհնության կարգ:",
            traditionsRu: "Зажжение костра во дворе церкви от благодатного огня алтаря, прыжки через огонь как символ очищения, чин благословения молодоженов.",
            traditionsEn: "Lighting the ceremonial fire in church courtyards and special blessings for newly married couples.",
            scriptureReading: "Ղուկաս 2:22-40",
            prayerHy: "Լոյս ի յայտնութիւն հեթանոսաց եւ փառք ժողովրդեան քում Իսրայէլի: Տէր Յիսուս, լուսաւորեա՛ զհոգիս մեր Քո ճշմարիտ լոյսով:",
            prayerRu: "Свет к просвещению язычников и славу народа Твоего Израиля. Господи Иисусе, просвети души наши Своим Божественным светом!",
            prayerEn: "A light to lighten the Gentiles, and the glory of Thy people Israel. Lord Jesus, enlighten our souls with Thy true divine light!",
            isFasting: false
        ))
        
        // Святые священномученики Гевондянцы (вторник перед Вардананц — за 54 дня до Пасхи)
        let ghevondianDate = dateByAdding(days: -54, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_ghevond",
            type: .saints,
            date: ghevondianDate,
            titleHy: "Սուրբ Ղևոնդյանց քահանաներ",
            titleRu: "Святые священномученики Гевондянцы",
            titleEn: "Feast of St. Ghevond the Priest and Companions",
            descriptionHy: "Ավարայրի ճակատամարտում հայոց բանակը ոգեշնչած և հանուն քրիստոնեական հավատքի նահատակված քահանաների հիշատակության օրը:",
            descriptionRu: "Память священников во главе с иереем Гевондом, вдохновлявших армянских воинов в Аварайрской битве 451 г. День армянского духовенства.",
            descriptionEn: "Commemoration of the holy priests who inspired the Armenian army at Avarayr (451 AD) and sacrificed their lives for the Christian faith.",
            meaningHy: "Հոգևորականության անձնվեր ծառայության, արիության և ճշմարիտ հովվական հավատարմության խորհրդանիշը:",
            meaningRu: "Символ верности священническому долгу, готовности положить душу за паству и чистоту веры Христовой.",
            meaningEn: "A testament to priestly fidelity and pastoral courage in defending the flock and the Orthodox faith.",
            traditionsHy: "Քահանայական դասի օրհնության և հոգևոր ծառայության գնահատման օր:",
            traditionsRu: "Благодарственные молебны о священнослужителях и пастырях Церкви.",
            traditionsEn: "Prayers of thanksgiving and blessing for all ordained clergy.",
            scriptureReading: "2 Տիմոթեոս 4:1-8",
            prayerHy: "Սուրբ քահանայապետք եւ մարտիրոսք, բարեխօսեցէ՛ք առ Քրիստոս վասն եկեղեցւոյ Հայաստանեայց:",
            prayerRu: "Священномученики Христовы, молите Господа о мире и непоколебимости Церкви Армянской!",
            prayerEn: "Holy martyr-priests, pray to Christ for the steadfastness of the Armenian Church!",
            isFasting: false
        ))
        
        // Святые воины Вардананц (четверг перед Масленицей — за 52 дня до Пасхи)
        let vardanantsDate = dateByAdding(days: -52, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_vardanants",
            type: .saints,
            date: vardanantsDate,
            titleHy: "Սուրբ Վարդանանց զորավարներ",
            titleRu: "День святых воинов Вардананц",
            titleEn: "Feast of St. Vardan and 1036 Companions (Vardanants)",
            descriptionHy: "451 թ. Ավարայրի ճակատամարտում հանուն հայրենիքի և հավատքի նահատակված Սուրբ Վարդան Մամիկոնյանի և 1036 մարտիրոսների հիշատակը:",
            descriptionRu: "Память спарапета Вардана Мамиконяна и 1036 мучеников Аварайрской битвы (451 г.), защитивших христианство от персидского зороастризма.",
            descriptionEn: "Commemoration of General Vardan Mamikonian and 1,036 martyrs of the Battle of Avarayr (451 AD) who defended Christianity in Armenia.",
            meaningHy: "«Չգիտակցված մահը մահ է, գիտակցված մահը՝ անմահություն»: Վարդանանք ապացուցեցին, որ հավատքն ու ազգային ինքնությունը անբաժանելի են:",
            meaningRu: "«Смерть неосознанная есть смерть, смерть осознанная — бессмертие!» Подвиг Вардананц утвердил право армянского народа исповедовать веру во Христа.",
            meaningEn: "'Death not understood is death, but death consciously embraced is immortality!' A heroic defense of religious freedom and identity.",
            traditionsHy: "Համազգային հանդիսություններ, բանակի և զինվորների օրհնության կարգ:",
            traditionsRu: "Праздничные богослужения, благословение воинов и защитников Отечества.",
            traditionsEn: "National celebrations and special prayers for the Armed Forces and defenders of the homeland.",
            scriptureReading: "Եբրայեցիս 11:32-40, Մատթեոս 10:16-22",
            prayerHy: "Վասն Յիսուսի եւ վասն հայրենեաց նահատակեալք, բարեխօսեցէ՛ք առ Տէր վասն անսասանութեան Հայաստան աշխարհի:",
            prayerRu: "Пострадавшие за Христа и за Отечество, молите Бога о мире и крепости земли Армянской!",
            prayerEn: "Martyrs for Christ and the homeland, intercede with the Lord for peace and prosperity in Armenia!",
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
            descriptionHy: "Մեծ Պահքին նախորդող ուրախության, սիրո և բարի կենդանության տոն, որը խորհրդանշում է մարդու երանական կյանքը Դրախտում:",
            descriptionRu: "Канун Великого Поста, день духовной радости и примирения, символизирующий райскую жизнь прародителей до грехопадения.",
            descriptionEn: "The eve of Great Lent, a joyful celebration representing humanity's blessed life in the Garden of Eden.",
            meaningHy: "«Բարի կենդանություն» նշանակում է բարի, առաքինի և ուրախ կյանք: Այն հիշեցնում է Դրախտային երանությունը և պատրաստում Մեծ Պահքի ապաշխարությանը:",
            meaningRu: "Праздник призывает к искреннему прощению обид, примирению с ближними перед вступлением в период Великого Поста.",
            meaningEn: "A joyful day reminding us of Paradise and calling for reconciliation with neighbors before entering Great Lent.",
            traditionsHy: "Տոնական սեղաններ, խաղեր, դիմակահանդեսներ և ողջույններ:",
            traditionsRu: "Обильные праздничные трапезы, угощения, игры и взаимное испрашивание прощения.",
            traditionsEn: "Festive family gatherings, masquerades, and asking for mutual forgiveness.",
            scriptureReading: "Մատթեոս 6:1-21, Հռոմեացիս 13:11-14:25",
            prayerHy: "Տէր, տուր մեզ զղջում եւ արթնութիւն հոգւոյ, զի արժանապէս մտցուք ի սուրբ պահս Քո:",
            prayerRu: "Господи, даруй нам покаяние и духовную бодрость, чтобы достойно вступить во дни Святого Поста!",
            prayerEn: "Lord, grant us true repentance and vigilance of soul to enter worthily into Thy Holy Fast!",
            isFasting: false
        ))
        
        // 5. Начало Великого Поста (Մեծ Պահքի սկիզբ — понедельник за 48 дней до Пасхи)
        let lentStartDate = dateByAdding(days: -48, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_lent_start",
            type: .fasting,
            date: lentStartDate,
            titleHy: "Մեծ Պահքի սկիզբ",
            titleRu: "Начало Великого Поста",
            titleEn: "Beginning of Great Lent",
            descriptionHy: "Քառասնօրյա ապաշխարության, աղոթքի և հոգևոր մաքրագործման շրջան մինչև Սուրբ Զատիկ: Խորանի վարագույրը փակվում է:",
            descriptionRu: "Начало 40-дневного периода покаяния, сугубой молитвы, воздержания и духовного очищения перед Светлым Воскресением. Алтарная завеса закрывается.",
            descriptionEn: "The beginning of the 40-day period of repentance, prayer, and spiritual purification leading to Holy Easter. The altar curtain remains closed.",
            meaningHy: "Մեծ Պահքը հոգևոր ճանապարհորդություն է: Փակ վարագույրը խորհրդանշում է մարդու արտաքսումը Դրախտից մեղքի պատճառով:",
            meaningRu: "Великий Пост — это весна духовная. Закрытая завеса алтаря напоминает об изгнании Адама из Рая и необходимости покаяния.",
            meaningEn: "Great Lent is a journey of spiritual renewal. The closed curtain represents Adam's expulsion from Paradise due to sin.",
            traditionsHy: "Հրաժարում կենդանական ծագման սննդից, ապաշխարության կարգ և Արևագալի ու Խաղաղական ժամերգություններ:",
            traditionsRu: "Воздержание от скоромной пищи, ежедневные покаянные богослужения Часов Мира и Покоя, благотворительность.",
            traditionsEn: "Abstinence from animal products, attending Sunrise and Peace Services, reading sacred scripture.",
            scriptureReading: "Եսայի 58:1-14, Մատթեոս 6:16-21",
            prayerHy: "Բա՛ց մեզ, Տէր, զդուռն ողորմութեան Քո, որ ողբալով կարդամք առ Քեզ:",
            prayerRu: "Отверзи нам, Господи, двери милосердия Твоего, ибо с плачем взываем к Тебе!",
            prayerEn: "Open to us, O Lord, the door of Thy mercy, as we cry out to Thee with tears of repentance!",
            isFasting: true
        ))
        
        // --- 3. МАРТ И АПРЕЛЬ (ՄԱՐՏ - ԱՊՐԻԼ) ---
        
        // Мичинк (Միջինք — 24-й день Великого Поста)
        let michinkDate = dateByAdding(days: -24, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_michink",
            type: .fasting,
            date: michinkDate,
            titleHy: "Միջինք (Մեծ Պահքի կեսը)",
            titleRu: "Мичинк (Преполовение Великого Поста)",
            titleEn: "Michink (Mid-Lent)",
            descriptionHy: "Մեծ Պահքի առաջին կեսի ավարտը: Ոգեշնչում է հավատացյալներին անսասան շարունակելու պահեցողության շրջանը:",
            descriptionRu: "Середина Великого Поста (24-й день), ободряющая постящихся продолжать подвиг воздержания и молитвы.",
            descriptionEn: "The midpoint of Great Lent (24th day), encouraging the faithful to persevere in prayer and fasting.",
            meaningHy: "Միջինքը ցույց է տալիս, որ պահքի կեսն արդեն անցել է, և Սուրբ Զատկի հաղթանակը մոտենում է:",
            meaningRu: "Напоминание о том, что половина пути пройдена, и впереди сияет свет Воскресения Христова.",
            meaningEn: "A reminder that half of the fasting journey is complete and the glory of Easter approaches.",
            traditionsHy: "Թխվում է հատուկ պահքային գաթա (բաղարջ), որի մեջ դրվում է մետաղադրամ:",
            traditionsRu: "Выпекание постной гаты (бахардж) с запеченной монетой внутри на счастье и благословение.",
            traditionsEn: "Baking traditional Lenten gata with a coin hidden inside as a symbol of fortune and blessing.",
            scriptureReading: "Եսայի 55:1-13",
            prayerHy: "Զօրացո՛ զմեզ, Տէր, ի պահպանութիւն պատուիրանաց Քոց:",
            prayerRu: "Укрепи нас, Господи, в соблюдении святых заповедей Твоих!",
            prayerEn: "Strengthen us, O Lord, to keep Thy holy commandments to the end!",
            isFasting: true
        ))
        
        // Сорок Севастийских мучеников (Քառասուն Մանկունք Սեբաստիո — суббота за 22 дня до Пасхи)
        let fortyMartyrsDate = dateByAdding(days: -22, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_forty_martyrs",
            type: .saints,
            date: fortyMartyrsDate,
            titleHy: "Քառասուն Մանկունք Սեբաստիո",
            titleRu: "Сорок мучеников Севастийских",
            titleEn: "Forty Martyrs of Sebaste",
            descriptionHy: "Սեբաստիայի սառցապատ լճում հանուն Քրիստոսի չարչարված և նահատակված 40 քաջարի հավատացյալ զինվորների հիշատակը:",
            descriptionRu: "Память 40 воинов-христиан, принявших мученическую смерть в ледяном озере Севастии за отказ отречься от Христа.",
            descriptionEn: "Commemoration of the 40 Christian soldiers who suffered martyrdom in the freezing lake of Sebaste.",
            meaningHy: "Միասնության և աննկուն հավատքի խորհրդանիշ: Նրանք ստացան 40 երկնային պսակներ:",
            meaningRu: "Образец духовного братства, стойкости в страданиях и верности Христу до последнего вздоха.",
            meaningEn: "An emblem of spiritual unity, endurance, and receiving the heavenly crowns of martyrdom.",
            traditionsHy: "Սուրբ Պատարագ և հավատքի ամրության աղոթքներ:",
            traditionsRu: "Молитвы об укреплении в вере и терпении во время жизненных испытаний.",
            traditionsEn: "Prayers for strength and perseverance through life's trials.",
            scriptureReading: "Մատթեոս 10:32-39",
            prayerHy: "Քառասուն սուրբ մանկունք, բարեխօսեցէ՛ք առ Տէր փրկել զմեզ ի սառնամանիքէ մեղաց:",
            prayerRu: "Святые сорок мучеников, молите Бога согреть наши охладевшие сердца благодатью Святого Духа!",
            prayerEn: "Holy forty martyrs, pray to the Lord to warm our hearts with the fire of divine love!",
            isFasting: false
        ))
        
        // 6. Благовещение Пресвятой Богородицы (Ավետումն — 7 апреля)
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
            meaningHy: "Աստծո և մարդու հաշտության սկիզբը: Մարիամի խոնարհ «Թող ինձ լինի ըստ քո խոսքի» պատասխանը բացեց փրկության դուռը:",
            meaningRu: "Начало нашего спасения: согласие Пресвятой Девы принять волю Божию открыло человечеству путь к избавлению от греха.",
            meaningEn: "The beginning of our salvation: Mary's humble acceptance of God's will made the Incarnation possible.",
            traditionsHy: "Մայրերի և կանանց օրհնության հատուկ կարգ բոլոր եկեղեցիներում:",
            traditionsRu: "Чин благословения матерей и женщин, поздравление матерей и дарение цветов.",
            traditionsEn: "Special blessings for mothers and women in all Armenian churches.",
            scriptureReading: "Ղուկաս 1:26-38",
            prayerHy: "Ուրախացի՛ր, բերկրեալդ, Տէրն ընդ քեզ. օրհնեալ ես դու ի կանայս եւ օրհնեալ է պտուղ որովայնի քո:",
            prayerRu: "Радуйся, Благодатная! Господь с Тобою; благословенна Ты между женами и благословен плод чрева Твоего!",
            prayerEn: "Hail, Mary, full of grace, the Lord is with thee: blessed art thou among women, and blessed is the fruit of thy womb!",
            isFasting: false
        ))
        
        // День святых мучеников Геноцида армян (24 апреля)
        list.append(ArmenianChurchFeast(
            id: "\(year)_genocide_martyrs",
            type: .saints,
            date: createDate(year: year, month: 4, day: 24),
            titleHy: "Սուրբ Նահատակաց հիշատակության օր",
            titleRu: "День памяти святых мучеников Геноцида армян",
            titleEn: "Feast of Holy Martyrs of the Armenian Genocide",
            descriptionHy: "1915 թ. Հայոց Ցեղասպանության 1.5 միլիոն սրբադասված նահատակների հիշատակության և բարեխոսության օրը:",
            descriptionRu: "День памяти 1,5 миллиона невинных жертв Геноцида армян 1915 года, причисленных Армянской Церковью к лику святых мучеников.",
            descriptionEn: "Commemoration of the 1.5 million holy martyrs of the 1915 Armenian Genocide canonized by the Armenian Apostolic Church.",
            meaningHy: "Մենք այլևս չենք ողբում որպես զոհեր, այլ հայցում ենք մեր սուրբ նահատակների բարեխոսությունը երկնքում:",
            meaningRu: "Святые мученики отдали жизнь за веру Христову и Отечество, став небесными предстателями за армянский народ.",
            meaningEn: "They sacrificed their lives for Christ and their faith, becoming heavenly intercessors for our nation and the world.",
            traditionsHy: "Ուխտագնացություն Ծիծեռնակաբերդ, զանգերի 100 ղողանջ և բարեխոսական աղոթքներ:",
            traditionsRu: "Торжественный колокольный звон во всех армянских церквях мира, возложение цветов, молебен о заступничестве святых.",
            traditionsEn: "100 bell chimes in Armenian churches worldwide, flower laying, and intercessory prayers.",
            scriptureReading: "Հայտնություն 7:9-17",
            prayerHy: "Սուրբ նահատակք վասն հաւատոյ եւ հայրենեաց, բարեխօսեցէ՛ք առ Քրիստոս վասն խաղաղութեան համայն աշխարհի:",
            prayerRu: "Святые мученики, за веру и Отечество пострадавшие, молите Христа о мире во всем мире!",
            prayerEn: "Holy Martyrs of Faith and Nation, intercede with Christ for peace in the world and protection of Armenia!",
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
            descriptionHy: "Հիսուս Քրիստոսի հաղթական մուտքը Երուսաղեմ: Բացվում է Խորանի վարագույրը և կատարվում է Մանուկների օրհնության կարգ:",
            descriptionRu: "Торжественный вход Господень в Иерусалим. Открытие алтарной завесы, освящение вербовых и оливковых ветвей, благословение детей.",
            descriptionEn: "The Triumphal Entry of Jesus Christ into Jerusalem. The altar curtain opens, olive/willow branches are blessed, along with children.",
            meaningHy: "Քրիստոս մտնում է մեր սրտի Երուսաղեմը որպես Խաղաղության Թագավոր: Մենք ողջունում ենք Նրան որպես մեր Փրկչի:",
            meaningRu: "Христос грядет на добровольные страдания ради спасения людей. Мы встречаем Его с ветвями добрых дел и чистотой детского сердца.",
            meaningEn: "Christ enters the Jerusalem of our hearts as the King of Peace, ready to lay down His life for our redemption.",
            traditionsHy: "Ուռենու և ձիթենու ճյուղերի օրհնություն, մանուկների գլխին ծաղկեպսակներ դնելու գեղեցիկ ավանդույթ:",
            traditionsRu: "Раздача освященных веточек ивы и вербы, венчание детей венками из веточек и цветов.",
            traditionsEn: "Blessing of willow branches and placing woven branch crowns on children's heads.",
            scriptureReading: "Մատթեոս 21:1-11, Հովհաննես 12:12-19",
            prayerHy: "Օվսաննա՜ ի բարձունս, օրհնեալ որ գաս յանուն Տեառն: Թագաւոր Իսրայէլի, փրկեա՛ զմեզ:",
            prayerRu: "Осанна в вышних! Благословен Грядущий во имя Господне! Царь Израилев, спаси нас!",
            prayerEn: "Hosanna in the highest! Blessed is He who comes in the name of the Lord! O King of Glory, save us!",
            isFasting: false
        ))
        
        // Великий Четверг (Ավագ Հինգշաբթի — за 3 дня до Пасхи)
        let holyThursdayDate = dateByAdding(days: -3, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_holy_thursday",
            type: .dominical,
            date: holyThursdayDate,
            titleHy: "Ավագ Հինգշաբթի (Վերջին Ընթրիք)",
            titleRu: "Великий Четверг (Тайная Вечеря)",
            titleEn: "Holy Thursday (Last Supper)",
            descriptionHy: "Սուրբ Հաղորդության խորհրդի հաստատումը, Ոտնլվայի կարգը և Խավարման գիշերվա ժամերգությունը (12 Ավետարանների ընթերցում):",
            descriptionRu: "Установление Таинства Святого Причастия (Евхаристии), чин Омовения ног (Вотнлва) и вечернее богослужение 12 Страстных Евангелий (Хаварум).",
            descriptionEn: "Institution of the Holy Eucharist, the Washing of the Feet ceremony (Votnlva), and the Service of Darkness (Khavarum).",
            meaningHy: "Քրիստոս տվեց Իր Մարմինն ու Արյունը որպես հավիտենական կյանքի հաց և խոնարհության օրինակ ծառայեց աշակերտների ոտքերը լվանալով:",
            meaningRu: "Пример совершенного смирения и любви Спасителя, даровавшего нам Свое Тело и Кровь во оставление грехов.",
            meaningEn: "Christ demonstrated supreme humility by washing His disciples' feet and giving His Body and Blood for eternal life.",
            traditionsHy: "Ոտնլվայի արարողություն, օրհնված յուղի բաշխում, Խավարման կարգի 12 մոմերի հանգցնելը:",
            traditionsRu: "Священник омывает ноги 12 служителям; зажжение и постепенное угасание 12 свечей на ночной службе Страстей Господних.",
            traditionsEn: "Priest washes the feet of 12 people; extinguishing 12 candles during the solemn Passion service.",
            scriptureReading: "Մատթեոս 26:17-30, Հովհաննես 13:1-17",
            prayerHy: "Տէ՛ր Յիսուս, լուա՛ զմեղս մեր եւ արա՛ զմեզ արժանի Սուրբ Հաղորդութեան Քում:",
            prayerRu: "Господи Иисусе, омой грехи наши и сподоби достойно причаститься Святых Твоих Таин!",
            prayerEn: "Lord Jesus, cleanse our sins and make us worthy to partake of Thy Holy Communion!",
            isFasting: true
        ))
        
        // 8. Великая Пятница (Ավագ Ուրբաթ — за 2 дня до Пасхи)
        let goodFridayDate = dateByAdding(days: -2, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_good_friday",
            type: .fasting,
            date: goodFridayDate,
            titleHy: "Ավագ Ուրբաթ (Խաչելության օր)",
            titleRu: "Великая Пятница (Страсти Господни)",
            titleEn: "Great and Holy Friday (Crucifixion)",
            descriptionHy: "Տեր Հիսուս Քրիստոսի չարչարանքների, խաչելության, մահվան և թաղման հիշատակության ամենախորհրդավոր օրը: Թաղման կարգ:",
            descriptionRu: "Воспоминание святых спасительных Страстей, распятия, крестной смерти и погребения Господа нашего Иисуса Христа. Чин Погребения.",
            descriptionEn: "Commemoration of the holy and salvific Passion, Crucifixion, Death, and Burial of our Lord Jesus Christ. Burial Service.",
            meaningHy: "Աստծո Գառը Իր կյանքը տվեց մարդկության փրկության համար՝ Խաչի վրա հաղթելով մեղքին ու սատանային:",
            meaningRu: "Крестная жертва Спасителя искупила первородный грех и открыла людям врата Царства Небесного.",
            meaningEn: "The Lamb of God sacrificed Himself on the Cross, reconciling humanity with God and conquering sin.",
            traditionsHy: "Խաչելության և Թաղման կարգ, ծաղիկներով զարդարված Դամբարանի շուրջ թափոր և խոնարհում:",
            traditionsRu: "Чин выноса и погребения Плащаницы (Гробницы Господней), украшение цветами и прохождение под Плащаницей.",
            traditionsEn: "Procession with the decorated Tomb of Christ and veneration of the Holy Epitaphios.",
            scriptureReading: "Հովհաննես 19:1-37, Մատթեոս 27:1-61",
            prayerHy: "Խաչի Քո, Քրիստոս, երկիրպագանեմք, եւ զսուրբ զԹաղումն Քո մեծացուցանեմք, եւ զսուրբ զՅարութիւն Քո փառաւորեմք:",
            prayerRu: "Кресту Твоему поклоняемся, Владыко, и святое погребение Твое величаем, и святое Воскресение Твое славим!",
            prayerEn: "We bow before Thy Cross, O Christ, we magnify Thy Holy Burial, and we glorify Thy Holy Resurrection!",
            isFasting: true
        ))
        
        // Великая Суббота / Пасхальный Сочельник (Ավագ Շաբաթ — 1 день до Пасхи)
        let holySaturdayDate = dateByAdding(days: -1, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_holy_saturday",
            type: .dominical,
            date: holySaturdayDate,
            titleHy: "Ավագ Շաբաթ (Ճրագալույց Զատկի)",
            titleRu: "Великая Суббота (Пасхальный Сочельник)",
            titleEn: "Holy Saturday (Easter Eve Jrakalouyts)",
            descriptionHy: "Դժոխքի ավերումը և Քրիստոսի Հարության ավետիսը: Երեկոյան Ճրագալույցի Պատարագով ավարտվում է Մեծ Պահքը:",
            descriptionRu: "Сошествие Спасителя во ад и освобождение душ праведников. Вечерняя Литургия Чрагалуйц возвещает о Воскресении Христовом.",
            descriptionEn: "The Harrowing of Hell and proclamation of Christ's Resurrection at the evening Easter Eve Divine Liturgy.",
            meaningHy: "Քրիստոս լուսավորեց դժոխքի խավարը և հարություն տվեց արդարներին: Մեծ Պահքի ավարտ և Զատկական ցնծության սկիզբ:",
            meaningRu: "Победа над смертью и адом: «Христос воскрес из мертвых! Благословенно Воскресение Христово!»",
            meaningEn: "Christ shatters the gates of hell and brings the light of resurrection to all souls waiting in darkness.",
            traditionsHy: "Եկեղեցուց վառվող մոմերով լույս տանելը, զատկական ձվերի ներկումը:",
            traditionsRu: "Освящение куличей, крашеных красных яиц и разговение после вечерней Литургии.",
            traditionsEn: "Lighting blessed candles, coloring Easter eggs red, and preparing the Easter table.",
            scriptureReading: "1 Կորնթացիս 15:1-11, Մատթեոս 28:1-20",
            prayerHy: "Քրիստոս յարեաւ ի մեռելոց: Օրհնեալ է յարութիւնն Քրիստոսի:",
            prayerRu: "Христос воскрес из мертвых! Воистину воскрес!",
            prayerEn: "Christ is risen from the dead! Blessed is the Resurrection of Christ!",
            isFasting: false
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
            descriptionRu: "Величайший христианский праздник — Воскресение Господа Иисуса Христа из мертвых, победа над смертью и адом.",
            descriptionEn: "The greatest Christian feast — the Resurrection of Jesus Christ from the dead, victory of life over death.",
            meaningHy: "Զատիկ նշանակում է զատում, ազատագրում մեղքից ու մահից: Քրիստոս Իր Հարությամբ բոլորիս պարգևեց հավիտենական կյանք:",
            meaningRu: "Пасха — праздник победы жизни над смертью, света над тьмой, надежды над отчаянием.",
            meaningEn: "Easter represents our liberation from sin and death into the glorious freedom of the children of God.",
            traditionsHy: "Կարմիր ներկված ձվեր (խորհրդանշում են Քրիստոսի թափած արյունը և նոր կյանքը), չամիչով փլավ, ձուկ և տոնական գինի:",
            traditionsRu: "Красные крашеные яйца (символ пролитой Крови Христа и новой жизни), рыба, сладкий плов с изюмом, куличи и вино.",
            traditionsEn: "Red colored eggs (symbolizing Christ's blood and new life), fish, sweet raisin pilaf, and Easter bread.",
            scriptureReading: "Մատթեոս 28:1-20, Հովհաննես 20:1-18",
            prayerHy: "Քրիստոս յարեաւ ի մեռելոց, մահուամբ զմահ կոխեաց, եւ որոց ի գերեզմանս էին՝ կեանս պարգեւեաց:",
            prayerRu: "Христос воскрес из мертвых, смертию смерть поправ, и сущим во гробех жизнь даровав!",
            prayerEn: "Christ is risen from the dead, trampling down death by death, and upon those in the tombs bestowing life!",
            isFasting: false
        ))
        
        // Пасхальный Мерелоц (Զատկի Մեռելոց — 1 день после Пасхи)
        let easterMerelots = dateByAdding(days: 1, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_easter_merelots",
            type: .dominical,
            date: easterMerelots,
            titleHy: "Զատկի Մեռելոց",
            titleRu: "Пасхальное поминовение усопших",
            titleEn: "Easter Remembrance of the Dead (Merelots)",
            descriptionHy: "Հարության տոնին հաջորդող հիշատակության օր: Հավատացյալները Զատկական ավետիսն են տանում իրենց ննջեցյալներին:",
            descriptionRu: "Поминовение усопших после праздника Пасхи с возвещением радостной вести о Воскресении Спасителя.",
            descriptionEn: "Memorial day following Easter, sharing the good news of Christ's resurrection with departed ancestors.",
            meaningHy: "Քրիստոս հարություն առավ ոչ միայն ապրողների, այլև բոլոր ննջեցյալների համար: Մահը այլևս իշխանություն չունի:",
            meaningRu: "Молитвенное поминовение в свете победы Христа над смертью: у Бога все живы.",
            meaningEn: "Christ is risen for the living and the dead; through Him we are assured of universal resurrection.",
            traditionsHy: "Այցելություն գերեզմաններ, հոգեհանգստյան կարգ և կարմիր ձվերի բաշխում:",
            traditionsRu: "Посещение могил с пасхальными яйцами, панихида и благотворительность.",
            traditionsEn: "Visiting graves with red eggs and having priests bless the resting places.",
            scriptureReading: "1 Կորնթացիս 15:20-28",
            prayerHy: "Յիշեա՛, Տէր, զհոգիս ննջեցելոց մերոց եւ արա՛ զնոսա ժառանգորդս արքայութեան Քո:",
            prayerRu: "Упокой, Господи, души усопших рабов Твоих в Небесном Твоем Царствии!",
            prayerEn: "Remember, O Lord, the souls of Thy servants and grant them rest in Thy heavenly Kingdom!",
            isFasting: false
        ))
        
        // Новое Воскресенье / Красная горка (Կրկնազատիկ — 7 дней после Пасхи)
        let newSundayDate = dateByAdding(days: 7, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_new_sunday",
            type: .dominical,
            date: newSundayDate,
            titleHy: "Կրկնազատիկ (Նոր Կիրակի)",
            titleRu: "Новое Воскресенье (Красная горка / Фомино)",
            titleEn: "New Sunday (Second Easter / St. Thomas)",
            descriptionHy: "Սուրբ Զատկի ութօրեքը և Թովմաս առաքյալի հավատքի հաստատումը («Տէր իմ եւ Աստուած իմ»):",
            descriptionRu: "Второе Воскресенье после Пасхи: уверение апостола Фомы и обновление веры во Христа Воскресшего.",
            descriptionEn: "The octave of Holy Easter and the affirmation of St. Thomas's faith ('My Lord and my God').",
            meaningHy: "Նոր Կիրակին խորհրդանշում է Եկեղեցու հաստատումը և հավատքի աներկբա վստահությունը Քրիստոսի Հարության նկատմամբ:",
            meaningRu: "Праздник учит нас искренней вере без сомнений: «Блаженны не видевшие и уверовавшие».",
            meaningEn: "Blessed are those who have not seen and yet have believed.",
            traditionsHy: "Եկեղեցական տոնակատարություններ և պսակադրությունների սկիզբ:",
            traditionsRu: "Возобновление венчаний после Великого Поста, народные гулянья.",
            traditionsEn: "Resumption of weddings after Great Lent and joyful parish gatherings.",
            scriptureReading: "Հովհաննես 20:19-31",
            prayerHy: "Տէր իմ եւ Աստուած իմ, զօրացո՛ զհաւատս մեր ի Քեզ:",
            prayerRu: "Господь мой и Бог мой! Укрепи веру нашу в Твое преславное Воскресение!",
            prayerEn: "My Lord and my God! Strengthen our faith in Thy holy Resurrection!",
            isFasting: false
        ))
        
        // Зеленое Воскресенье (Աշխարհամատրան Կիրակի / Կանաչ Կիրակի — 14 дней после Пасхи)
        let greenSundayDate = dateByAdding(days: 14, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_green_sunday",
            type: .dominical,
            date: greenSundayDate,
            titleHy: "Աշխարհամատրան Կիրակի (Կանաչ Կիրակի)",
            titleRu: "Зеленое Воскресенье (Ашхараматуран)",
            titleEn: "Green Sunday (Feast of the First Church of Jerusalem)",
            descriptionHy: "Երուսաղեմի առաջին քրիստոնեական եկեղեցու (Վերնատան) հիշատակության և բնության զարթոնքի տոնը:",
            descriptionRu: "Память основания первой христианской церкви (Сионской горницы) в Иерусалиме и весеннего обновления природы.",
            descriptionEn: "Commemoration of the first Christian chapel (Upper Room) in Jerusalem and spring spiritual renewal.",
            meaningHy: "Կանաչ գույնը խորհրդանշում է հոգևոր նորոգությունը, կյանքի ծաղկումը և Եկեղեցու մշտադալար պտղաբերությունը:",
            meaningRu: "Зеленый цвет — цвет надежды, духовной весны и благодатного роста Церкви Христовой.",
            meaningEn: "Green symbolizes spiritual youth, hope, and the fruitful growth of Christ's Church.",
            traditionsHy: "Եկեղեցիների զարդարում կանաչ ճյուղերով, ծաղիկներով:",
            traditionsRu: "Украшение храмов зеленью и весенними цветами.",
            traditionsEn: "Decorating churches with green branches and fresh flowers.",
            scriptureReading: "Գործք Առաքելոց 9:22-31, Հովհաննես 2:23-3:12",
            prayerHy: "Նորոգեա՛, Տէր, զհոգիս մեր կենարար շնորհօք Քոց:",
            prayerRu: "Обнови, Господи, сердца наши животворящей Твоею благодатью!",
            prayerEn: "Renew our souls, O Lord, with Thy life-giving and eternal grace!",
            isFasting: false
        ))
        
        // Красное Воскресенье (Կարմիր Կիրակի — 21 день после Пасхи)
        let redSundayDate = dateByAdding(days: 21, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_red_sunday",
            type: .dominical,
            date: redSundayDate,
            titleHy: "Կարմիր Կիրակի",
            titleRu: "Красное Воскресенье",
            titleEn: "Red Sunday",
            descriptionHy: "Քրիստոսի Եկեղեցու և մարտիրոսների թափած սուրբ արյան հիշատակության օրը:",
            descriptionRu: "Память святых мучеников, проливших кровь за веру во Христа, и утверждения Церкви.",
            descriptionEn: "Commemoration of the blood of martyrs shed for Christ and the establishment of the Church.",
            meaningHy: "Կարմիր գույնը խորհրդանշում է Քրիստոսի և Նրա սուրբ նահատակների փրկարար արյունը:",
            meaningRu: "Красный цвет напоминает о цене нашего спасения — жертвенной Крови Спасителя и мучеников.",
            meaningEn: "Red symbolizes the redeeming Blood of Christ and the victorious sacrifice of the martyrs.",
            traditionsHy: "Եկեղեցական կարմիր հանդերձներ և նահատակների հիշատակություն:",
            traditionsRu: "Красные облачения священнослужителей, молитвы об укреплении в исповедании веры.",
            traditionsEn: "Red liturgical vestments and prayers for steadfastness in faith.",
            scriptureReading: "Գործք 13:16-43, Հովհաննես 5:19-30",
            prayerHy: "Պահպանեա՛ զմեզ, Քրիստոս, պատուական Արեամբ Քոյով:",
            prayerRu: "Сохрани нас, Христе Боже, драгоценною Твоею Кровию!",
            prayerEn: "Protect us, O Christ, by Thy precious and life-giving Blood!",
            isFasting: false
        ))
        
        // Явление Святого Креста в Иерусалиме (Երևումն Սուրբ Խաչի — 28 дней после Пасхи)
        let apparitionCrossDate = dateByAdding(days: 28, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_apparition_cross",
            type: .dominical,
            date: apparitionCrossDate,
            titleHy: "Երևումն Սուրբ Խաչի",
            titleRu: "Явление Святого Креста в Иерусалиме",
            titleEn: "Apparition of the Holy Cross in Jerusalem",
            descriptionHy: "351 թ. Երուսաղեմի երկնքում Գողգոթայից մինչև Ձիթենյաց լեռը փայլատակած հրաշափառ լուսավոր Խաչի հիշատակը:",
            descriptionRu: "Воспоминание чудесного явления сияющего Креста на небе Иерусалима в 351 году, простиравшегося от Голгофы до Елеонской горы.",
            descriptionEn: "Commemoration of the miraculous luminous Cross that appeared in the sky over Jerusalem in 351 AD.",
            meaningHy: "Խաչը հաղթության նշան է: Երկնային այս նշանը բազմաթիվ մարդկանց դարձի բերեց դեպի քրիստոնեություն:",
            meaningRu: "Крест Господень — знамение победы над силами тьмы и залог вечного спасения.",
            meaningEn: "The Cross is the banner of divine victory, leading souls to faith in the True God.",
            traditionsHy: "Խաչի փառաբանության արարողություններ և Խաչվերացի շարականներ:",
            traditionsRu: "Торжественные молебны и поклонение Честному Кресту Господню.",
            traditionsEn: "Solemn hymns and veneration of the Holy Cross.",
            scriptureReading: "Մատթեոս 24:29-36",
            prayerHy: "Խաչի Քո, Քրիստոս, երկիրպագանեմք, որ եղեւ մեզ նշան յաղթութեան:",
            prayerRu: "Кресту Твоему поклоняемся, Христе, явившемуся нам знамением небесной победы!",
            prayerEn: "We venerate Thy Cross, O Christ, which was revealed as a sign of victory!",
            isFasting: false
        ))
        
        // 10. Вознесение Господне (Համբարձում — 39 дней после Пасхи, четверг)
        let ascensionDate = dateByAdding(days: 39, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_ascension",
            type: .dominical,
            date: ascensionDate,
            titleHy: "Համբարձում Տեառն",
            titleRu: "Вознесение Господне (Амбарцум)",
            titleEn: "Feast of the Ascension of the Lord",
            descriptionHy: "Հիսուս Քրիստոսի երկինք համբարձվելու և Հոր աջ կողմը նստելու տոնը: Ամենայն Հայոց Կաթողիկոսության հաստատման օրը (1441 թ.):",
            descriptionRu: "Празднование восшествия Господа Иисуса Христа во плоти на Небеса к Престолу Бога Отца. День возвращения Престола Католикоса в Эчмиадзин (1441 г.).",
            descriptionEn: "Commemoration of the bodily Ascension of Jesus Christ into Heaven. Also marks the re-establishment of the Catholicosate in Holy Etchmiadzin (1441).",
            meaningHy: "Քրիստոս մարդկային բնությունը բարձրացրեց երկինք՝ ճանապարհ բացելով մեզ համար դեպի հավիտենական երանություն:",
            meaningRu: "Вознесение Господне вознесло человеческое естество к Божественной славе, даровав нам надежду на вечное пребывание с Богом.",
            meaningEn: "Christ elevated human nature to the right hand of the Father, opening the path to eternity for all believers.",
            traditionsHy: "Ծաղկահավաք, վիճակահանություն (Ջանգյուլում), Էջմիածնի ուխտի օր:",
            traditionsRu: "Народный обычай сбора трав и цветов, песнопения Джан-Гюлюм, паломничество в Святой Эчмиадзин.",
            traditionsEn: "Flower-gathering folk songs (Jan Gyulum) and pilgrimages to Holy Etchmiadzin.",
            scriptureReading: "Գործք Առաքելոց 1:1-11, Ղուկաս 24:41-53",
            prayerHy: "Համբարձաւ Աստուած օրհնութեամբ, եւ Տէր մեր ձայնիւ փողոյ: Փա՜ռք Համբարձման Քո, Տէր:",
            prayerRu: "Восшел Бог при восклицаниях, Господь при звуке трубном. Слава Вознесению Твоему, Господи!",
            prayerEn: "God is gone up with a shout, the Lord with the sound of a trumpet. Glory to Thy Ascension, O Lord!",
            isFasting: false
        ))
        
        // 11. Пятидесятница (Հոգեգալուստ — 49 дней после Пасхи)
        let pentecostDate = dateByAdding(days: 49, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_pentecost",
            type: .dominical,
            date: pentecostDate,
            titleHy: "Հոգեգալուստ (Պենտեկոստե)",
            titleRu: "Пятидесятница (Сошествие Святого Духа)",
            titleEn: "Pentecost (Descent of the Holy Spirit)",
            descriptionHy: "Սուրբ Հոգու էջքը առաքյալների վրա հրեղեն լեզուների տեսքով և Քրիստոսի Եկեղեցու հիմնադրման տոնը:",
            descriptionRu: "Сошествие Святого Духа на апостолов в виде огненных языков. День рождения Христовой Церкви.",
            descriptionEn: "The descent of the Holy Spirit upon the Apostles in the form of fiery tongues. The birthday of the Church.",
            meaningHy: "Սուրբ Հոգին կենդանարար ուժ է, որը լուսավորում, սրբագործում և առաջնորդում է Եկեղեցին և յուրաքանչյուր հավատացյալի:",
            meaningRu: "Святой Дух — Утешитель и Источник благодати, оживотворяющий каждого верующего и созидающий Церковь.",
            meaningEn: "The Holy Spirit is the Comforter and Spirit of Truth who empowers and sanctifies the Church.",
            traditionsHy: "Եկեղեցում ընթերցվում է Անդաստանի կարգը՝ օրհնելով աշխարհի 4 կողմերը:",
            traditionsRu: "Чин Андастана (благословение четырех сторон света) и молитвы коленопреклонения.",
            traditionsEn: "The Blessing of the Four Corners of the Earth (Andastan) and kneeling prayers.",
            scriptureReading: "Գործք Առաքելոց 2:1-21, Հովհաննես 14:15-27",
            prayerHy: "Ե՛կ, Հոգի՛ Սուրբ, եւ լի՛ց զսիրտս հաւատացելոց Քոց, եւ զհուր սիրոյ Քո բորբոքեա՛ ի նոսա:",
            prayerRu: "Царю Небесный, Утешителю, Душе истины, прииди и вселися в ны, и очисти ны от всякия скверны!",
            prayerEn: "O Heavenly King, the Comforter, the Spirit of Truth, come and abide in us and cleanse us from all impurity!",
            isFasting: false
        ))
        
        // Святые девы Рипсиме и ее сподвижницы (понедельник после Пятидесятницы — за 41 день до Вардавара)
        let hripsimeDate = dateByAdding(days: 57, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_hripsime",
            type: .saints,
            date: hripsimeDate,
            titleHy: "Սուրբ Հռիփսիմյանց կույսեր",
            titleRu: "Святые девы Рипсимианки",
            titleEn: "Feast of St. Hripsime and Companions",
            descriptionHy: "Հանուն Քրիստոսի կուսության և հավատքի նահատակված Սուրբ Հռիփսիմեի և 32 կույսերի հիշատակը:",
            descriptionRu: "Память святой девы Рипсиме и ее 32 сподвижниц, принявших мученическую смерть за чистоту веры и целомудрие.",
            descriptionEn: "Commemoration of St. Hripsime and 32 virgin companions who gave their lives for Christ in Armenia.",
            meaningHy: "Կուսական մաքրության, հոգևոր աննկունության և անձնուրաց հավատքի վառ օրինակ:",
            meaningRu: "Святая Рипсиме явила пример несокрушимой чистоты, отвергнув почести мира ради Христа.",
            meaningEn: "A shining beacon of Christian virtue, purity, and steadfast refusal to compromise on faith.",
            traditionsHy: "Ուխտագնացություն Էջմիածնի Սուրբ Հռիփսիմե տաճար:",
            traditionsRu: "Паломничество в храм Сурб Рипсиме в Вагаршапате (Эчмиадзине).",
            traditionsEn: "Pilgrimage to St. Hripsime Church in Vagharshapat (Etchmiadzin).",
            scriptureReading: "Առակաց 31:10-31, Ղուկաս 12:4-12",
            prayerHy: "Սուրբ կոյսք եւ մարտիրոսք Հռիփսիմեանք, բարեխօսեցէ՛ք առ Քրիստոս վասն մաքրութեան հոգւոց մերոց:",
            prayerRu: "Святые девы-мученицы, молите Христа Бога о даровании чистоты и целомудрия душам нашим!",
            prayerEn: "Holy virgin martyrs, intercede with Christ for the purity and steadfastness of our souls!",
            isFasting: false
        ))
        
        // Святые девы Гаяне и ее сподвижницы (вторник после Рипсиме)
        let gayaneDate = dateByAdding(days: 58, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_gayane",
            type: .saints,
            date: gayaneDate,
            titleHy: "Սուրբ Գայանյանց կույսեր",
            titleRu: "Святые девы Гаянианки",
            titleEn: "Feast of St. Gayane and Companions",
            descriptionHy: "Սուրբ Հռիփսիմեի ուսուցչուհի և մայրապետ Սուրբ Գայանեի ու նրա ընկերուհիների նահատակության հիշատակը:",
            descriptionRu: "Память наставницы святых дев — игуменьи Гаяне и ее сподвижниц, пострадавших за Христа.",
            descriptionEn: "Commemoration of the spiritual mother St. Gayane and her companions who were martyred for Christ.",
            meaningHy: "Հոգևոր մայրության, իմաստության և առաջնորդության հրաշալի օրինակ:",
            meaningRu: "Пример духовного наставничества, мудрости и непреклонности в исповедании Христа.",
            meaningEn: "An enduring model of spiritual guidance, wisdom, and pastoral motherliness.",
            traditionsHy: "Ուխտագնացություն Էջմիածնի Սուրբ Գայանե տաճար:",
            traditionsRu: "Паломничество в монастырь Сурб Гаяне в Эчмиадзине.",
            traditionsEn: "Pilgrimage to St. Gayane Church in Etchmiadzin.",
            scriptureReading: "2 Կորնթացիս 6:16-7:1",
            prayerHy: "Սուրբ մայրապետ Գայանէ, աղօթեա՛ առ Տէր վասն հոգեւոր առաջնորդութեան մերոյ:",
            prayerRu: "Святая мати Гаяне, моли Господа о спасении и духовном просвещении народа нашего!",
            prayerEn: "Holy Mother Gayane, pray to the Lord for our spiritual illumination and guidance!",
            isFasting: false
        ))
        
        // Выход св. Григория Просветителя из Хор Вирапа (суббота после Пятидесятницы — за 36 дней до Вардавара)
        let khorVirapDeliveranceDate = dateByAdding(days: 62, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_khor_virap_exit",
            type: .saints,
            date: khorVirapDeliveranceDate,
            titleHy: "Ելն Սուրբ Գրիգոր Լուսավորչի ի Վիրապեն",
            titleRu: "Выход св. Григория Просветителя из Хор Вирапа",
            titleEn: "Deliverance of St. Gregory the Illuminator from Khor Virap",
            descriptionHy: "Սուրբ Գրիգոր Լուսավորչի 13 տարվա տառապանքներից հետո Խոր Վիրապի խոր փոսից ելքը և Հայաստանի մկրտությունը:",
            descriptionRu: "Освобождение св. Григория Просветителя из 13-летнего заточения в глубокой яме Хор Вирапа, исцеление царя Трдата и Крещение Армении в 301 г.",
            descriptionEn: "The miraculous deliverance of St. Gregory after 13 years in the pit of Khor Virap, leading to the Baptism of Armenia (301 AD).",
            meaningHy: "Խավարից դեպի լույս: Լուսավորչի հավատքը հաղթեց մահվանը և Հայաստանը դարձրեց աշխարհում առաջին քրիստոնյա պետությունը:",
            meaningRu: "Победа света над тьмой: страдания Просветителя стали семенем, взрастившим первое в мире христианское государство.",
            meaningEn: "From darkness to light: St. Gregory's endurance made Armenia the first nation to adopt Christianity as state religion.",
            traditionsHy: "Մեծ ուխտագնացություն Խոր Վիրապի վանք, Սուրբ Լուսավորչի Աջի դուրսբերում Էջմիածնում:",
            traditionsRu: "Всенародное паломничество в монастырь Хор Вирап у подножия Арарата, вынос Десницы св. Григория в Эчмиадзине.",
            traditionsEn: "Mass pilgrimage to Khor Virap Monastery and veneration of the Right Hand of St. Gregory in Etchmiadzin.",
            scriptureReading: "Գործք 26:19-32, Մատթեոս 19:27-29",
            prayerHy: "Հա՛յր մեր եւ Լուսաւորի՛չ, բարեխօսեա՛ առ Քրիստոս վասն հաւատացեալ ժողովրդեան Քո:",
            prayerRu: "Отче наш и Просветителю Григорие, моли Христа Бога о сохранении веры в сердцах чад твоих!",
            prayerEn: "Our Father and Illuminator Gregory, intercede with Christ for the steadfastness of the Armenian nation!",
            isFasting: false
        ))
        
        // Праздник Кафедрального Собора Святого Эчмиадзина (2-е воскресенье после Пятидесятницы — за 35 дней до Вардавара)
        let etchmiadzinFeastDate = dateByAdding(days: 63, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_holy_etchmiadzin",
            type: .dominical,
            date: etchmiadzinFeastDate,
            titleHy: "Տոն Կաթողիկե Սուրբ Էջմիածնի",
            titleRu: "Праздник Кафедрального Собора Святого Эчмиадзина",
            titleEn: "Feast of the Cathedral of Holy Etchmiadzin",
            descriptionHy: "Միածին Որդու էջքի տեսիլքի և Հայ Առաքելական Եկեղեցու Մայր Աթոռի հիմնադրման տոնը:",
            descriptionRu: "Празднование основания Первопрестольного Святого Эчмиадзина по видению св. Григория Просветителя («Сошел Единородный»).",
            descriptionEn: "Commemoration of the founding of the Mother See of Holy Etchmiadzin following St. Gregory's vision ('The Only Begotten Descended').",
            meaningHy: "«Էջ Միածինն ի Հօրէ եւ լոյս փառաց ընդ նմա»: Էջմիածինը հայ հավատքի, ինքնության և միասնության սիրտն է:",
            meaningRu: "Святой Эчмиадзин — духовное сердце армянского народа во всем мире, символ Божественного присутствия среди нас.",
            meaningEn: "Holy Etchmiadzin is the spiritual home and cornerstone of unity for Armenians worldwide.",
            traditionsHy: "Հայրապետական Սուրբ Պատարագ Էջմիածնում, աղոթք Ամենայն Հայոց Կաթողիկոսության համար:",
            traditionsRu: "Патриаршая Божественная Литургия в Первопрестольном Эчмиадзине, молебен о Церкви и народе.",
            traditionsEn: "Pontifical Divine Liturgy at the Mother See of Holy Etchmiadzin and prayers for the Catholicos.",
            scriptureReading: "Առակաց 9:1-6, Եբրայեցիս 9:1-10, Մատթեոս 16:13-19",
            prayerHy: "Էջ Միածինն ի Հօրէ, եւ լոյս փառաց ընդ նմա: Պահեա՛, Տէր, զՄայր Աթոռ Սուրբ Էջմիածին անսասան յաւիտեան:",
            prayerRu: "Сошел Единородный от Отца, и свет славы с Ним! Сохрани, Господи, Святой Эчмиадзин непоколебимым вовеки!",
            prayerEn: "The Only Begotten descended from the Father, and with Him the light of glory! Preserve Holy Etchmiadzin steadfast forever!",
            isFasting: false
        ))
        
        // Обретение мощей св. Григория Просветителя (суббота за 21 день до Вардавара)
        let relicsGregoryDate = dateByAdding(days: 77, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_relics_st_gregory",
            type: .saints,
            date: relicsGregoryDate,
            titleHy: "Գյուտ նշխարաց Սուրբ Գրիգոր Լուսավորչի",
            titleRu: "Обретение мощей св. Григория Просветителя",
            titleEn: "Discovery of the Relics of St. Gregory the Illuminator",
            descriptionHy: "Սեպուհ լեռան Մանյա այրում ճգնած և ննջած Լուսավորչի սուրբ նշխարների հրաշափառ հայտնաբերման օրը:",
            descriptionRu: "Празднование чудесного обретения нетленных мощей св. Григория Просветителя в пещере на горе Сепух.",
            descriptionEn: "Commemoration of the discovery of the holy relics of St. Gregory the Illuminator in the cave on Mount Sepuh.",
            meaningHy: "Սուրբ նշխարները Աստծո շնորհի և սրբության կենդանի վկայությունն են Եկեղեցում:",
            meaningRu: "Мощи святых свидетельствуют о преображении человеческого тела благодатью Святого Духа.",
            meaningEn: "The relics of the saints are living testimonies of God's sanctifying grace.",
            traditionsHy: "Սուրբ Պատարագ և հավատացյալների օրհնություն Լուսավորչի Աջով:",
            traditionsRu: "Поклонение святым реликвиям и мощам Просветителя.",
            traditionsEn: "Veneration of the holy relics of St. Gregory.",
            scriptureReading: "Իմաստութիւն 10:9-21, Ղուկաս 12:32-40",
            prayerHy: "Սուրբ Գրիգոր Լուսաւորիչ, քո սուրբ աղօթքներով պահպանեա՛ զմեզ ի բարեպաշտութեան:",
            prayerRu: "Святитель Христов Григорий, моли Господа о сохранении нас в истинной вере и благочестии!",
            prayerEn: "Holy Gregory the Illuminator, by your prayers preserve us in truth and piety!",
            isFasting: false
        ))
        
        // Святой царь Трдат, царица Ашхен и Хосровидухт (суббота за 14 дней до Вардавара)
        let kingTrdatDate = dateByAdding(days: 84, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_trdat",
            type: .saints,
            date: kingTrdatDate,
            titleHy: "Սուրբ Տրդատ թագավոր, Աշխեն թագուհի և Խոսրովիդուխտ",
            titleRu: "Святой царь Трдат, царица Ашхен и Хосровидухт",
            titleEn: "Feast of St. King Trdat, Queen Ashkhen and Khosrovidukht",
            descriptionHy: "Հայաստանում քրիստոնեությունը պետական կրոն հռչակած և առաջին եկեղեցիները կառուցած սուրբ թագավորական ընտանիքի հիշատակը:",
            descriptionRu: "Память святого царя Трдата III Великого, его супруги царицы Ашхен и сестры Хосровидухт, крестивших Армению вместе со св. Григорием.",
            descriptionEn: "Commemoration of King Trdat III the Great, Queen Ashkhen, and Princess Khosrovidukht, who proclaimed Christianity in Armenia.",
            meaningHy: "Առաջնորդների անձնական դարձի և հավատքով երկիրը կառավարելու հզոր օրինակ:",
            meaningRu: "Пример того, как искреннее покаяние правителя способно преобразить судьбу целого народа.",
            meaningEn: "A powerful example of how a ruler's repentance and faith can transform the destiny of an entire nation.",
            traditionsHy: "Աղոթք Հայոց պետականության և առաջնորդների իմաստության համար:",
            traditionsRu: "Молитвы о благоденствии государства и мудрости правителей.",
            traditionsEn: "Prayers for the prosperity of the homeland and wisdom for its leaders.",
            scriptureReading: "Իմաստութիւն 6:1-11, Ղուկաս 19:1-10",
            prayerHy: "Սուրբ արքայ Տրդատ եւ բարեպաշտ թագուհի Աշխէն, բարեխօսեցէ՛ք վասն հայրենեաց մերոց:",
            prayerRu: "Святые венценосные предстатели земли Армянской, молите Царя Небесного о мире и процветании нашей Родины!",
            prayerEn: "Holy Royal Martyrs, intercede with the King of Kings for peace and wisdom in our nation!",
            isFasting: false
        ))
        
        // --- 4. ИЮЛЬ (ՀՈՒԼԻՍ) & ВАРДАВАР ---
        
        // 12. ՊԱՅԾԱՌԱԿԵՐՊՈՒԹՅՈՒՆ / ՎԱՐԴԱՎԱՌ (14-е воскресенье после Пасхи / 98-й день) [ТАГАВАР 3]
        let vardavarDate = dateByAdding(days: 98, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_vardavar",
            type: .daghavar,
            date: vardavarDate,
            titleHy: "Պայծառակերպություն (Վարդավառ)",
            titleRu: "Преображение Господне (Вардавар)",
            titleEn: "Transfiguration of the Lord (Vardavar)",
            descriptionHy: "Քրիստոսի աստվածային փառքի պայծառացումը Թաբոր լեռան վրա: Ավանդական ջրցանի և հոգևոր մաքրության տոն:",
            descriptionRu: "Явление Божественного величия и славы Спасителя на горе Фавор перед апостолами Петром, Иаковом и Иоанном. Традиционный праздник обливания водой.",
            descriptionEn: "The revelation of Christ's divine glory on Mount Tabor before Peter, James, and John. Celebrated with joyful water sprinkling.",
            meaningHy: "Քրիստոս ցույց տվեց Իր անեղծ աստվածային լույսը՝ հիշեցնելով, որ մարդը կոչված է վերափոխվելու և լուսավորվելու աստվածային շնորհով:",
            meaningRu: "Преображение призывает каждого верующего очиститься от греховной тьмы и преобразиться в образ Божий.",
            meaningEn: "Christ revealed His uncreated divine light, calling all of us to inner transformation and holiness.",
            traditionsHy: "Միմյանց վրա ջուր ցողել (ջրցան)՝ ի նշան մեղքերի մաքրման և Նոյյան ջրհեղեղի հիշատակի, վարդեր նվիրել և աղավնիներ թռցնել:",
            traditionsRu: "Обливание друг друга чистой водой как символ духовного очищения, дарение роз, выпускание голубей.",
            traditionsEn: "Sprinkling each other with water as a symbol of purification, gifting roses, and releasing doves.",
            scriptureReading: "Մատթեոս 17:1-9, Ղուկաս 9:28-36",
            prayerHy: "Պայծառացո՛, Տէր, զխաւարեալ հոգիս մեր Թաբորական լուսով Քո, եւ արժանի արա՛ տեսանել զփառս Քո:",
            prayerRu: "Преобразился еси на горе, Христе Боже, показавый учеником Твоим славу Твою. Просвети и нас светом Твоим присносущным!",
            prayerEn: "Thou wast transfigured on the mountain, O Christ God, revealing Thy glory to Thy disciples. Shine Thy eternal light upon us!",
            isFasting: false
        ))
        
        // Мерелоц Вардавара (понедельник после Вардавара)
        let vardavarMerelots = dateByAdding(days: 99, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_vardavar_merelots",
            type: .dominical,
            date: vardavarMerelots,
            titleHy: "Վարդավառի Մեռելոց",
            titleRu: "Поминовение усопших после Вардавара",
            titleEn: "Remembrance of the Dead (Vardavar Merelots)",
            descriptionHy: "Պայծառակերպության Տաղավար տոնին հաջորդող համազգային հիշատակության և հոգեհանգստի օր:",
            descriptionRu: "День заупокойной молитвы обо всех усопших после праздника Преображения Господня.",
            descriptionEn: "Memorial Day following the Feast of the Transfiguration.",
            meaningHy: "Մենք հիշում ենք մեր ննջեցյալներին՝ աղոթելով, որ Թաբորական լույսը լուսավորի նրանց հոգիները:",
            meaningRu: "Молитва об упокоении душ усопших в обителях Божественного Света.",
            meaningEn: "Praying that the radiant light of Tabor will illuminate the souls of our departed loved ones.",
            traditionsHy: "Հոգեհանգստյան Պատարագ և գերեզմանների օրհնություն:",
            traditionsRu: "Заупокойная Литургия и освящение могил священником.",
            traditionsEn: "Memorial Divine Liturgy and blessing of graves.",
            scriptureReading: "1 Կորնթացիս 15:35-49",
            prayerHy: "Տէ՛ր, լուսաւորեա՛ զհոգիս ննջեցելոց մերոց աներեկոյ լուսով Քո:",
            prayerRu: "Упокой, Господи, души усопших в невечернем свете Твоем!",
            prayerEn: "Grant rest, O Lord, to the souls of our departed in Thine unwaning light!",
            isFasting: false
        ))
        
        // Святые апостолы Фаддей и Варфоломей (суббота через 2 недели после Вардавара)
        let apostlesThaddeusBartholomew = dateByAdding(days: 111, to: easter)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_thaddeus_bartholomew",
            type: .saints,
            date: apostlesThaddeusBartholomew,
            titleHy: "Սուրբ Թադեոս և Բարդուղիմեոս առաքյալներ",
            titleRu: "Святые апостолы Фаддей и Варфоломей",
            titleEn: "Feast of Holy Apostles Thaddeus and Bartholomew",
            descriptionHy: "Հայաստանի առաջին լուսավորիչների և Հայ Առաքելական Սուրբ Եկեղեցու հիմնադիր առաքյալների հիշատակության օրը:",
            descriptionRu: "Память святых 12 апостолов Христа — Фаддея и Варфоломея, первых просветителей Армении, основавших Апостольскую Церковь.",
            descriptionEn: "Commemoration of Holy Apostles Thaddeus and Bartholomew, the first enlighteners and founders of the Armenian Apostolic Church.",
            meaningHy: "Առաքելական հաջորդականության և հայոց հավատքի ակունքների տոնը: Նրանք Հայաստան բերեցին Սուրբ Գեղարդը և Աստվածամոր Պատկերը:",
            meaningRu: "Апостолы принесли в Армению свет Евангелия, Святое Копье (Гегард) и Нерукотворный образ Богородицы.",
            meaningEn: "They brought the Gospel to Armenia along with holy relics including the Holy Lance (Geghard).",
            traditionsHy: "Սուրբ Գեղարդի դուրսբերում Էջմիածնում և հավատացյալների օրհնություն:",
            traditionsRu: "Вынос Святого Копья (Сурб Гегард) в Первопрестольном Эчмиадзине для поклонения верующих.",
            traditionsEn: "Bringing out the Holy Lance (Geghard) in Etchmiadzin for blessing the faithful.",
            scriptureReading: "Մատթեոս 10:1-15, Գործք 1:12-14",
            prayerHy: "Սուրբ առաքեալք եւ առաջին լուսաւորիչք մեր Թադէոս եւ Բարդուղիմէոս, բարեխօսեցէ՛ք վասն մեր:",
            prayerRu: "Святые апостолы и первопросветители наши Фаддей и Варфоломей, молите Христа о непоколебимости Церкви Армянской!",
            prayerEn: "Holy Apostles and our First Illuminators Thaddeus and Bartholomew, intercede with Christ for us!",
            isFasting: false
        ))
        
        // --- 5. АВГУСТ (ՕԳՈՍՏՈՍ) & УСПЕНИЕ БОГОРОДИЦЫ ---
        
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
            descriptionRu: "Вознесение Божией Матери с телом на Небеса. Традиционный чин освящения винограда (Хахохордзнек) и начатков плодов.",
            descriptionEn: "The Dormition and bodily Assumption of the Holy Mother of God into Heaven. The Blessing of the Grapes ceremony.",
            meaningHy: "Աստվածամայրը առաջինն էր, որ Քրիստոսի նմանությամբ հարություն առավ և մարմնով փոխադրվեց Երկնային Արքայություն՝ դառնալով մեր գլխավոր բարեխոսը:",
            meaningRu: "Пресвятая Богородица первой из людей удостоилась телесного воскресения и славы в Царстве Своего Сына.",
            meaningEn: "The Theotokos was the first human to experience bodily resurrection and ascension into heavenly glory.",
            traditionsHy: "Սուրբ Պատարագից հետո կատարվում է Խաղողօրհնեքի կարգ: Մինչ այդ խաղող չուտելու բարեպաշտ սովորություն:",
            traditionsRu: "Чин освящения винограда. Благочестивый обычай воздерживаться от вкушения винограда нового урожая до праздничного освящения.",
            traditionsEn: "The Blessing of the Grapes ceremony; traditional abstinence from grapes until they are blessed at church.",
            scriptureReading: "Ղուկաս 1:39-56, Գաղատացիս 4:4-7",
            prayerHy: "Անկանիմք առաջի քո, Սուրբ Աստուածածին, եւ աղաչեմք զանարատ զկոյսդ. բարեխօսեա՛ վասն անձանց մերոց:",
            prayerRu: "Под твою милость прибегаем, Богородице Дево, молитв наших не презри в скорбех, но от бед избави нас!",
            prayerEn: "We fly to thy patronage, O holy Mother of God; despise not our petitions in our necessities, but deliver us from all dangers!",
            isFasting: false
        ))
        
        // Мерелоц Успения (понедельник после Успения)
        let asdvadzadzinMerelots = dateByAdding(days: 1, to: asdvadzadzinDate)
        list.append(ArmenianChurchFeast(
            id: "\(year)_assumption_merelots",
            type: .dominical,
            date: asdvadzadzinMerelots,
            titleHy: "Աստվածածնի Մեռելոց",
            titleRu: "Поминовение усопших после Успения",
            titleEn: "Remembrance of the Dead (Assumption Merelots)",
            descriptionHy: "Սուրբ Աստվածածնի Վերափոխման Տաղավար տոնին հաջորդող համազգային հիշատակության օր:",
            descriptionRu: "День молитвенного поминовения усопших после праздника Успения Пресвятой Богородицы.",
            descriptionEn: "Memorial Day following the Feast of the Assumption of the Theotokos.",
            meaningHy: "Աղոթք Աստվածամոր բարեխոսության համար՝ մեր ննջեցյալների հոգիների խաղաղության համար:",
            meaningRu: "Испрашивание заступничества Богородицы за души всех усопших христиан.",
            meaningEn: "Seeking the intercession of the Holy Mother of God for the souls of our departed loved ones.",
            traditionsHy: "Հոգեհանգստյան Պատարագ և օրհնված խաղողի բաշխում:",
            traditionsRu: "Заупокойная Литургия и раздача освященного винограда во здравие и упокой.",
            traditionsEn: "Memorial Liturgy and sharing of blessed grapes.",
            scriptureReading: "1 Թեսաղոնիկեցիս 4:13-18",
            prayerHy: "Սուրբ Աստուածածին, բարեխօսեա՛ առ Որդիդ քո Միածին վասն ննջեցելոց մերոց:",
            prayerRu: "Пресвятая Богородица, моли Сына Твоего об упокоении душ усопших сродников наших!",
            prayerEn: "Holy Mother of God, intercede with Thine Only Begotten Son for our departed brothers and sisters!",
            isFasting: false
        ))
        
        // Обретение Пояса Пресвятой Богородицы (3-е воскресенье после Успения)
        let beltOfMaryDate = dateByAdding(days: 21, to: asdvadzadzinDate)
        list.append(ArmenianChurchFeast(
            id: "\(year)_belt_of_theotokos",
            type: .dominical,
            date: beltOfMaryDate,
            titleHy: "Գյուտ Գոտու Սուրբ Աստվածածնի",
            titleRu: "Обретение Пояса Пресвятой Богородицы",
            titleEn: "Discovery of the Belt of the Holy Theotokos",
            descriptionHy: "Աստվածամոր սուրբ Գոտու հայտնաբերման և Եկեղեցում մեծարման հիշատակը:",
            descriptionRu: "Празднование обретения честного Пояса Божией Матери, врученного апостолу Фоме при Ее Успении.",
            descriptionEn: "Commemoration of the discovery of the Holy Belt of the Theotokos given to Apostle Thomas.",
            meaningHy: "Աստվածամոր մայրական հոգածության և պաշտպանության խորհրդանիշը:",
            meaningRu: "Пояс Богородицы — символ Ее непрестанной материнской защиты и покрова над верующими.",
            meaningEn: "The Belt of the Virgin Mary represents her maternal protection and prayers for the faithful.",
            traditionsHy: "Բարեխոսական աղոթքներ հիվանդությունների բժշկության և մայրության պարգևի համար:",
            traditionsRu: "Молитвы об исцелении недугов и даровании чадородия.",
            traditionsEn: "Prayers for healing and blessings of childbirth.",
            scriptureReading: "Ղուկաս 1:46-55",
            prayerHy: "Սուրբ Գօտիդ Աստուածածնի եղիցի մեզ պահապան յամենայն չարէ:",
            prayerRu: "Честный Пояс Твой, Пречистая Дева, да оградит нас от всякого зла и искушения!",
            prayerEn: "May the Holy Belt of the Theotokos be our shield and protection from all harm!",
            isFasting: false
        ))
        
        // --- 6. СЕНТЯБРЬ (ՍԵՊՏԵՄԲԵՐ) & ХАЧВЕРАЦ ---
        
        // Рождество Пресвятой Богородицы (Ծնունդ Սուրբ Աստվածածնի — 8 сентября)
        list.append(ArmenianChurchFeast(
            id: "\(year)_nativity_theotokos",
            type: .dominical,
            date: createDate(year: year, month: 9, day: 8),
            titleHy: "Ծնունդ Սուրբ Աստվածածնի",
            titleRu: "Рождество Пресвятой Богородицы",
            titleEn: "Nativity of the Holy Mother of God",
            descriptionHy: "Բարեպաշտ ծնողների՝ Հովակիմի և Աննայի աղոթքներով Կույս Մարիամի ծննդյան տոնը:",
            descriptionRu: "Рождение Преблагословенной Девы Марии у праведных Иоакима и Анны. Начало исполнения ветхозаветных пророчеств.",
            descriptionEn: "The birth of the Blessed Virgin Mary to righteous parents Joachim and Anna.",
            meaningHy: "Աստվածամոր ծնունդով աշխարհին ծագեց փրկության արշալույսը: Նա ընտրվեց դառնալու Աստծո Տաճարը:",
            meaningRu: "Рождество Богородицы предвещает спасение мира: от Нее родится Спаситель Иисус Христос.",
            meaningEn: "The dawn of our salvation: from her will be born the Savior of the world.",
            traditionsHy: "Սուրբ Պատարագ և ընտանիքների, մայրերի օրհնություն:",
            traditionsRu: "Праздничные богослужения, молитвы о семье и родителях.",
            traditionsEn: "Festive Divine Liturgy and prayers for families.",
            scriptureReading: "Ղուկաս 1:39-56",
            prayerHy: "Ծնունդ քո, Սուրբ Աստուածածին, ուրախութիւն աւետեաց ամենայն տիեզերաց:",
            prayerRu: "Рождество Твое, Богородице Дево, радость возвести всей вселенней!",
            prayerEn: "Thy Nativity, O Virgin Mother of God, proclaimed joy to the entire universe!",
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
            descriptionRu: "Возвращение Животворящего Креста Господня из персидского плена императором Ираклием и его торжественное воздвижение в храме Воскресения в Иерусалиме (628 г.).",
            descriptionEn: "The recovery of the True Cross of Christ from Persian captivity and its triumphant elevation for veneration.",
            meaningHy: "Խաչը քրիստոնյայի զենքն է, պարծանքը և փրկության խորհրդանիշը: Խաչվերացը հաղթության և հավատքի վերածննդի տոն է:",
            meaningRu: "Крест — знамя христианской победы над смертью, грехом и диаволом. Воздвижение Креста символизирует торжество веры.",
            meaningEn: "The Cross is our spiritual weapon and glory. Khachverats celebrates the triumph of faith over darkness.",
            traditionsHy: "Խաչվերացի թափոր ռեհանով (ռեհանը խորհրդանշում է Խաչի բուրմունքը), Խաչի օրհնություն և ջրօրհնեք:",
            traditionsRu: "Украшение Креста душистым базиликом (реханом), шествие с Крестом вокруг храма и окропление народа розовой водой.",
            traditionsEn: "Adorning the Cross with fragrant basil, procession around the church, and sprinkling blessed rosewater.",
            scriptureReading: "Հովհաննես 19:16-37, 1 Կորնթացիս 1:18-25",
            prayerHy: "Խաչ քո եղիցի մեզ ապաւէն, Տէր Յիսուս, յորժամ գաս փառօք Հօր դատել զերկիր:",
            prayerRu: "Крест Твой да будет нам прибежищем и защитой, Господи Иисусе, когда придешь судить вселенную!",
            prayerEn: "May Thy Holy Cross be our refuge and protection, Lord Jesus, when Thou comest in glory to judge the world!",
            isFasting: false
        ))
        
        // Мерелоц Хачвераца (понедельник после Хачвераца)
        let khachveratsMerelots = dateByAdding(days: 1, to: khachveratsDate)
        list.append(ArmenianChurchFeast(
            id: "\(year)_khachverats_merelots",
            type: .dominical,
            date: khachveratsMerelots,
            titleHy: "Խաչվերացի Մեռելոց",
            titleRu: "Поминовение усопших после Хачвераца",
            titleEn: "Remembrance of the Dead (Khachverats Merelots)",
            descriptionHy: "Խաչվերացի Տաղավար տոնին հաջորդող հիշատակության օր:",
            descriptionRu: "Заупокойное поминовение всех усопших после праздника Воздвижения Креста.",
            descriptionEn: "Memorial Day following the Feast of the Exaltation of the Holy Cross.",
            meaningHy: "Խաչի զորությամբ աղոթք մեր ննջեցյալների հոգիների խաղաղության և լուսավորության համար:",
            meaningRu: "Молитвенное предстательство у Креста Господня за души усопших предков.",
            meaningEn: "Praying through the power of the Holy Cross for the souls of our departed loved ones.",
            traditionsHy: "Հոգեհանգիստ և գերեզմանների օրհնություն:",
            traditionsRu: "Панихида и священническое освящение мест упокоения.",
            traditionsEn: "Memorial services and graveside prayers.",
            scriptureReading: "2 Կորնթացիս 1:3-11",
            prayerHy: "Քրիստոս Աստուած, Խաչիւդ Քո սրբով հանգո՛ զհոգիս ննջեցելոց մերոց:",
            prayerRu: "Господи, Крестом Твоим святым упокой души усопших раб Твоих!",
            prayerEn: "O Christ God, by Thy Holy Cross grant rest to the souls of our departed!",
            isFasting: false
        ))
        
        // Святой великомученик Георгий Победоносец (суббота перед Варага Хач — конец сентября)
        let stGeorgeDate = dateByAdding(days: 13, to: khachveratsDate)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_george",
            type: .saints,
            date: stGeorgeDate,
            titleHy: "Սուրբ Գևորգ զորավար",
            titleRu: "День святого великомученика Георгия Победоносца",
            titleEn: "Feast of St. George the General",
            descriptionHy: "Քրիստոնեական աշխարհի ամենասիրված սրբերից մեկի՝ քաջարի զորավար Սուրբ Գևորգի հիշատակության օրը:",
            descriptionRu: "Память святого великомученика Георгия Победоносца, покровителя воинов, защитника невинных и победителя зла.",
            descriptionEn: "Commemoration of St. George the General and Great Martyr, protector of soldiers and conqueror of evil.",
            meaningHy: "Հավատքի անվախություն և հաղթանակ չարի դեմ: Սուրբ Գևորգը նախընտրեց մարտիրոսական պսակը փառքի փոխարեն:",
            meaningRu: "Образец непобедимого мужества, стояния за правду Божию и защиты слабых.",
            meaningEn: "An enduring symbol of courage, spiritual victory over darkness, and protection of the innocent.",
            traditionsHy: "Ուխտագնացություն Մուղնու Սուրբ Գևորգ վանք և բոլոր Սուրբ Գևորգ եկեղեցիներ:",
            traditionsRu: "Паломничество в монастырь Мугни Сурб Геворг в Армении, праздничные молебны.",
            traditionsEn: "Pilgrimages to St. George Monastery in Mughni and St. George churches.",
            scriptureReading: "Ղուկաս 21:12-19",
            prayerHy: "Սուրբդ Աստուծոյ Գէորգ զօրավար, բարեխօսեա՛ առ Տէր փրկել զմեզ ի թշնամեաց հոգւոյ եւ մարմնոյ:",
            prayerRu: "Святый великомучениче Георгие, моли Бога избавить нас от врагов видимых и невидимых!",
            prayerEn: "Holy Saint George the Victorious, intercede with God to deliver us from all adversaries!",
            isFasting: false
        ))
        
        // Святой Крест Вараг (Վարագա Սուրբ Խաչ — 2 недели после Хачвераца)
        let varakCrossDate = dateByAdding(days: 14, to: khachveratsDate)
        list.append(ArmenianChurchFeast(
            id: "\(year)_varak_cross",
            type: .dominical,
            date: varakCrossDate,
            titleHy: "Վարագա Սուրբ Խաչ",
            titleRu: "Праздник Святого Креста Вараг (Варага Хач)",
            titleEn: "Feast of the Holy Cross of Varak",
            descriptionHy: "653 թ. Վարագա լեռան վրա Սուրբ Հռիփսիմեի թողած Տերունական Խաչափայտի մասունքի հրաշափառ հայտնաբերման տոնը:",
            descriptionRu: "Празднование чудесного явления частицы Животворящего Креста Господня на горе Вараг в Армении (653 г.). Истинно армянский праздник Креста.",
            descriptionEn: "Celebration of the miraculous appearance of the relic of the True Cross on Mount Varak in Armenia (653 AD).",
            meaningHy: "Աստծո օրհնության և ներկայության հատուկ նշանը Հայաստան աշխարհի համար:",
            meaningRu: "Свидетельство особой благодати Божией, осеняющей Армянскую землю через знамение Святого Креста.",
            meaningEn: "A testament to God's providence and blessing upon the Armenian nation through the True Cross.",
            traditionsHy: "Սուրբ Պատարագ և Խաչի օրհնություն:",
            traditionsRu: "Праздничная Литургия и поклонение Святому Кресту.",
            traditionsEn: "Festive Divine Liturgy and blessing with the Holy Cross.",
            scriptureReading: "Մատթեոս 24:30-36, Գաղատացիս 6:14-18",
            prayerHy: "Փա՜ռք Խաչի Քո, Տէր Յիսուս, որով լուսաւորեցեր զհողն Հայաստանեայց:",
            prayerRu: "Слава Кресту Твоему, Господи, озарившему светом спасения землю Армянскую!",
            prayerEn: "Glory to Thy Holy Cross, Lord Jesus, by which Thou didst enlighten the land of Armenia!",
            isFasting: false
        ))
        
        // --- 7. ОКТЯБРЬ (ՀՈԿՏԵՄԲԵՐ) & СВЯТЫЕ ПЕРЕВОДЧИКИ ---
        
        // 15. Святые Переводчики (Սուրբ Թարգմանչաց տոն — 2-я суббота октября)
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
            descriptionEn: "Commemoration of Holy Translators Sts. Mesrop Mashtots, Sahak Partev, and disciples who translated the Bible into Armenian ('Queen of Translations').",
            meaningHy: "«Ճանաչել զիմաստութիւն եւ զխրատ, իմանալ զբանս հանճարոյ»: Գրերի գյուտով և Աստվածաշնչի թարգմանությամբ հայ ազգը ստացավ հավերժական հոգևոր զենք:",
            meaningRu: "«Познать мудрость и наставление, понять изречения разума» (Притчи 1:1). Первые слова, написанные по-армянски. Перевод Библии спас армянскую нацию от ассимиляции.",
            meaningEn: "'To know wisdom and instruction; to perceive the words of understanding.' The Armenian Bible translation preserved the nation's spiritual soul.",
            traditionsHy: "Դպրության, մշակույթի և ուսուցիչների օրհնության տոն եկեղեցիներում և դպրոցներում:",
            traditionsRu: "Праздник армянской письменности, чествование учителей, переводчиков и деятелей культуры в Ошакане.",
            traditionsEn: "Blessing of teachers, students, and writers; pilgrimages to St. Mesrop Mashtots Church in Oshakan.",
            scriptureReading: "Առակաց 1:1-7, 1 Կորնթացիս 14:1-19",
            prayerHy: "Որք զարդարեցին զիմաստս Անեղին, յօրինելով զգիրս հայկականս. բարեխօսեցէ՛ք առ Տէր վասն մեր:",
            prayerRu: "Украсившие мудростью Создателя письмена армянские, святые переводчики, молите Бога о нашем просвещении!",
            prayerEn: "You who adorned the wisdom of the Uncreated God by creating the Armenian alphabet, pray to the Lord for our spiritual enlightenment!",
            isFasting: false
        ))
        
        // Обретение Креста царицей Еленой (Գյուտ Խաչի — 7-е воскресенье после Хачвераца)
        let discoveryCrossDate = dateByAdding(days: 49, to: khachveratsDate)
        list.append(ArmenianChurchFeast(
            id: "\(year)_discovery_cross",
            type: .dominical,
            date: discoveryCrossDate,
            titleHy: "Գյուտ Խաչի",
            titleRu: "Обретение Креста Господня царицей Еленой",
            titleEn: "Discovery of the Holy Cross by St. Helena",
            descriptionHy: "327 թ. Սուրբ Հեղինե թագուհու կողմից Երուսաղեմում Քրիստոսի Կենարար Խաչափայտի հայտնաբերման տոնը:",
            descriptionRu: "Воспоминание обретения Животворящего Креста Господня в Иерусалиме святой равноапостольной царицей Еленой в 327 году.",
            descriptionEn: "Commemoration of the discovery of the True Cross of Christ in Jerusalem by St. Helena in 327 AD.",
            meaningHy: "Խաչի հայտնաբերումը վկայում է, որ Աստծո ճշմարտությունը երբեք չի կորչում և միշտ հաղթում է:",
            meaningRu: "Животворящий Крест Господень был явлен миру через чудо воскрешения умершего при возложении древа Креста.",
            meaningEn: "The discovery of the True Cross affirms that God's truth is never lost and always triumphs.",
            traditionsHy: "Սուրբ Պատարագ և Խաչի մեծարում:",
            traditionsRu: "Праздничная Литургия и поклонение Животворящему Кресту.",
            traditionsEn: "Festive Liturgy and veneration of the Holy Cross.",
            scriptureReading: "1 Կորնթացիս 1:18-24, Մատթեոս 24:30",
            prayerHy: "Խաչիւ Քո, Քրիստոս, փրկեա՛ զմեզ ի թշնամւոյն որոգայթից:",
            prayerRu: "Крестом Твоим, Христе Спасителю, спаси нас от сетей лукавого!",
            prayerEn: "By Thy Cross, O Christ, save us from the snares of the enemy!",
            isFasting: false
        ))
        
        // Святые 4 Евангелиста (Մատթեոս, Մարկոս, Ղուկաս, Հովհաննես — конец октября)
        let evangelistsDate = dateByAdding(days: 41, to: khachveratsDate)
        list.append(ArmenianChurchFeast(
            id: "\(year)_evangelists",
            type: .saints,
            date: evangelistsDate,
            titleHy: "Սուրբ Ավետարանիչներ (Մատթեոս, Մարկոս, Ղուկաս, Հովհաննես)",
            titleRu: "Святые четыре Евангелиста",
            titleEn: "Feast of the Four Holy Evangelists",
            descriptionHy: "Չորս Սուրբ Ավետարանների հեղինակների՝ Մատթեոսի, Մարկոսի, Ղուկասի և Հովհաննեսի հիշատակության օրը:",
            descriptionRu: "Память святых апостолов и евангелистов Матфея, Марка, Луки и Иоанна Богослова, записавших спасительное Благовестие Христа.",
            descriptionEn: "Commemoration of the Four Holy Evangelists: Matthew, Mark, Luke, and John.",
            meaningHy: "Ավետարանը Քրիստոսի կենդանի Խոսքն է, որը տալիս է հավիտենական կյանքի առաջնորդություն:",
            meaningRu: "Четыре Евангелия — незыблемое основание христианской веры и путеводная звезда для спасения души.",
            meaningEn: "The Holy Gospels are the living Word of God guiding us on the path to eternal life.",
            traditionsHy: "Սուրբ Ավետարանի համբուրում և աղոթք Սուրբ Գրքի ընթերցանության համար:",
            traditionsRu: "Особое чтение Евангелия в храмах, молитвы о разумении Священного Писания.",
            traditionsEn: "Solemn reading of the Gospels and prayers for understanding Holy Scripture.",
            scriptureReading: "2 Տիմոթեոս 3:14-17, Մատթեոս 28:16-20",
            prayerHy: "Սուրբ աւետարանիչք Քրիստոսի, աղօթեցէ՛ք, զի խօսքն Աստուծոյ արմատանայ ի սիրտս մեր:",
            prayerRu: "Святые евангелисты Христовы, молите Бога, да укоренится Слово Божие в сердцах наших!",
            prayerEn: "Holy Evangelists of Christ, pray that the Word of God may take deep root in our hearts!",
            isFasting: false
        ))
        
        // --- 8. НОЯБРЬ (ՆՈՅԵՄԲԵՐ) & АРХАНГЕЛЫ ---
        
        // Святые Архангелы Михаил и Гавриил (суббота в начале ноября)
        let archangelsDate = createDate(year: year, month: 11, day: 7)
        list.append(ArmenianChurchFeast(
            id: "\(year)_archangels",
            type: .saints,
            date: archangelsDate,
            titleHy: "Սուրբ Հրեշտակապետաց Գաբրիելի և Միքայելի",
            titleRu: "Праздник святых Архангелов Гавриила и Михаила",
            titleEn: "Feast of Holy Archangels Gabriel and Michael",
            descriptionHy: "Երկնային անմարմին զորքերի, հրեշտակապետների և պահապան հրեշտակների հիշատակության օրը:",
            descriptionRu: "Празднование Собора святых Архангелов Михаила, Гавриила и всех Небесных Сил Бесплотных.",
            descriptionEn: "Commemoration of Holy Archangels Michael, Gabriel, and all the Heavenly Host.",
            meaningHy: "Հրեշտակները Աստծո պատգամաբերներն են և մեր պահապանները, որոնք պաշտպանում են մեզ չարից:",
            meaningRu: "Архангел Михаил — защитник веры и победитель сил тьмы; Архангел Гавриил — вестник Божественных тайн и радости.",
            meaningEn: "The Archangels are divine messengers and guardians defending us against spiritual evil.",
            traditionsHy: "Աղոթք պահապան հրեշտակին և երեխաների օրհնություն:",
            traditionsRu: "Молитвы к Ангелу-Хранителю о защите детей, дома и воинов.",
            traditionsEn: "Prayers to Guardian Angels for the protection of families and children.",
            scriptureReading: "Եբրայեցիս 1:6-14, Մատթեոս 18:1-10",
            prayerHy: "Սուրբ հրեշտակապետք Միքայէլ եւ Գաբրիէլ, պահպանեցէ՛ք զմեզ ընդ հովանեաւ թեւոց ձերոց:",
            prayerRu: "Святые Архангелы Михаиле и Гаврииле со всеми Небесными Силами, молите Бога о нас!",
            prayerEn: "Holy Archangels Michael and Gabriel, protect us under the shadow of your wings!",
            isFasting: false
        ))
        
        // Начало 50-дневного Рождественского поста / Иснакац (Յիսնակաց պահք — за 50 дней до Рождества, около 18 ноября)
        let adventFastDate = createDate(year: year, month: 11, day: 18)
        list.append(ArmenianChurchFeast(
            id: "\(year)_advent_fast",
            type: .fasting,
            date: adventFastDate,
            titleHy: "Յիսնակաց պահքի սկիզբ",
            titleRu: "Начало Рождественского поста (Иснакац)",
            titleEn: "Beginning of the 50-Day Fast of Advent (Yisnagats)",
            descriptionHy: "Հիսնօրյա պահքի շրջան, որով հավատացյալները պատրաստվում են դիմավորելու Քրիստոսի Սուրբ Ծնունդը:",
            descriptionRu: "Начало 50-дневного периода поста и молитвенного приготовления к великому празднику Рождества Христова.",
            descriptionEn: "The beginning of the 50-day period of fasting and prayer preparing the faithful for the Holy Nativity.",
            meaningHy: "Ինչպես մարգարեները սպասում էին Մեսիայի գալստյանը, այնպես էլ մենք սրբում ենք մեր սրտերը Փրկչին ընդունելու համար:",
            meaningRu: "Время духовного ожидания и очищения души перед пришествием в мир Спасителя.",
            meaningEn: "A season of joyful anticipation and spiritual preparation for the coming of Christ.",
            traditionsHy: "Պահեցողություն, աղոթք և բարեգործություն:",
            traditionsRu: "Воздержание от скоромной пищи, дела милосердия и духовное чтение.",
            traditionsEn: "Fasting, reading sacred scripture, and practicing charitable deeds.",
            scriptureReading: "Եսայի 9:1-7",
            prayerHy: "Տէ՛ր, մաքրեա՛ զմեզ, զի արժանապէս դիմաւորեսցուք զՍուրբ Ծնունդ Քո:",
            prayerRu: "Господи, очисти души наши, дабы достойно встретить Светлое Твое Рождество!",
            prayerEn: "Lord, cleanse our hearts that we may worthily welcome Thy Holy Nativity!",
            isFasting: true
        ))
        
        // Введение во храм Пресвятой Богородицы (Ընծայումն ի Տաճար — 21 ноября)
        list.append(ArmenianChurchFeast(
            id: "\(year)_presentation_theotokos",
            type: .dominical,
            date: createDate(year: year, month: 11, day: 21),
            titleHy: "Ընծայումն Սուրբ Աստվածածնի ի Տաճար",
            titleRu: "Введение во храм Пресвятой Богородицы",
            titleEn: "Presentation of the Holy Theotokos in the Temple",
            descriptionHy: "Երեք տարեկան Կույս Մարիամի ընծայումը Երուսաղեմի Տաճարին՝ Աստծուն ծառայելու համար:",
            descriptionRu: "Приведение 3-летней Отроковицы Марии праведными родителями в Иерусалимский Храм для посвящения Богу.",
            descriptionEn: "The entry of the 3-year-old Virgin Mary into the Temple of Jerusalem dedicated to the service of God.",
            meaningHy: "Աստծուն նվիրվելու և հոգևոր մաքրության մեջ աճելու խորհրդանիշը: Մարիամը պատրաստվեց դառնալու Աստծո Տաճարը:",
            meaningRu: "Посвящение всей жизни Богу. Пречистая Дева Сама соделалась одушевленным Храмом Спасителя.",
            meaningEn: "Dedication of life to God; Mary prepared her heart to become the living Temple of the Savior.",
            traditionsHy: "Երեխաների օրհնություն և աղոթք քրիստոնեական դաստիարակության համար:",
            traditionsRu: "Молитвы о христианском воспитании детей и благословение отроков.",
            traditionsEn: "Blessing of children and prayers for Christian education.",
            scriptureReading: "Ղուկաս 1:39-56",
            prayerHy: "Սուրբ Կոյս Մարիամ, տաճար Աստուծոյ, առաջնորդեա՛ մեզ ի տաճար արքայութեան Երկնից:",
            prayerRu: "Пречистая Дево, во Храм Божий введенная, приведи и нас к чертогам Небесным!",
            prayerEn: "Holy Virgin Mary, Temple of God, lead us into the heavenly sanctuary of eternal life!",
            isFasting: false
        ))
        
        // --- 9. ДЕКАБРЬ (ԴԵԿՏԵՄԲԵՐ) & СВЯТИТЕЛИ ---
        
        // Зачатие Пресвятой Богородицы св. Анной (Հղություն Սուրբ Աստվածածնի — 9 декабря)
        list.append(ArmenianChurchFeast(
            id: "\(year)_conception_theotokos",
            type: .dominical,
            date: createDate(year: year, month: 12, day: 9),
            titleHy: "Հղություն Սուրբ Աստվածածնի",
            titleRu: "Зачатие Пресвятой Богородицы святой Анной",
            titleEn: "Conception of the Holy Theotokos by St. Anna",
            descriptionHy: "Անզավակության տառապանքից հետո բարեպաշտ Աննայի հղիության հրաշքը և Կույս Մարիամի ծննդյան խոստումը:",
            descriptionRu: "Чудесное зачатие Богоотроковицы Марии у праведных богоотцов Иоакима и Анны после долгих лет бесплодия и усердных молитв.",
            descriptionEn: "The miraculous conception of the Virgin Mary by righteous Anna after years of faithful prayer.",
            meaningHy: "Աղոթքի զորությունը և Աստծո խոստումների անսասանությունը: Աստված լսում է համբերատար հավատացյալներին:",
            meaningRu: "Сила неотступной молитвы и упования на Бога, Который творит невозможное для людей.",
            meaningEn: "The power of steadfast prayer: God fulfills His promises to those who trust in Him.",
            traditionsHy: "Սուրբ Պատարագ և աղոթքներ զավակներ ունենալ ցանկացող ընտանիքների համար:",
            traditionsRu: "Молитвы о даровании детей бесплодным супругам и благословение беременных матерей.",
            traditionsEn: "Prayers for couples longing for children and blessing of expectant mothers.",
            scriptureReading: "Ղուկաս 1:26-38",
            prayerHy: "Սուրբ Աննա, որ արժանացար կրել զՄայրն Փրկչին, բարեխօսեա՛ վասն ընտանեաց մերոց:",
            prayerRu: "Праведная мати Анна, моли Господа о мире и благословении семей наших!",
            prayerEn: "Righteous Mother Anna, pray to the Lord for peace and blessings in our families!",
            isFasting: false
        ))
        
        // Святитель Николай Чудотворец (Սուրբ Նիկողայոս Հայրապետ — суббота в начале декабря)
        let stNicholasDate = createDate(year: year, month: 12, day: 6)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_nicholas",
            type: .saints,
            date: stNicholasDate,
            titleHy: "Սուրբ Նիկողայոս Հայրապետ",
            titleRu: "Святитель Николай Чудотворец",
            titleEn: "Feast of St. Nicholas the Wonderworker",
            descriptionHy: "Քրիստոնեական աշխարհի ամենասիրված հայրապետներից մեկի՝ բարության, գթասրտության և հրաշքների հայր Սուրբ Նիկողայոսի հիշատակը:",
            descriptionRu: "Память великого святителя Николая, архиепископа Мир Ликийских, чудотворца, скорого помощника в бедах и покровителя путешествующих.",
            descriptionEn: "Commemoration of St. Nicholas the Wonderworker, Archbishop of Myra, known for boundless charity and miracles.",
            meaningHy: "Անշահախնդիր գթասրտության, աղքատներին օգնելու և գաղտնի բարեգործության հրաշալի օրինակ:",
            meaningRu: "Образец деятельного милосердия, защиты гонимых, помощи нуждающимся и непоколебимой веры.",
            meaningEn: "An enduring model of selfless charity, helping the poor, and living faith.",
            traditionsHy: "Բարեգործություն, նվերներ երեխաներին և աղքատներին:",
            traditionsRu: "Дела милосердия, подарки детям и сиротам, молебны о путешествующих.",
            traditionsEn: "Acts of charity, giving gifts to children and those in need.",
            scriptureReading: "Եբրայեցիս 13:17-21, Հովհաննես 10:11-16",
            prayerHy: "Սուրբ հայրապետ Նիկողայոս, բարեխօսեա՛ առ Քրիստոս փրկել զմեզ ի նեղութեանց եւ չարեաց:",
            prayerRu: "Святителю отче Николае, моли Бога о нас и избави от всяких бед и скорбей!",
            prayerEn: "Holy Father Nicholas, intercede with Christ to deliver us from all tribulations and distress!",
            isFasting: false
        ))
        
        // Святой Иаков Низибийский (Սուրբ Հակոբ Մծբնա Հայրապետ — суббота в середине декабря)
        let stJamesDate = createDate(year: year, month: 12, day: 13)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_james_nisibis",
            type: .saints,
            date: stJamesDate,
            titleHy: "Սուրբ Հակոբ Մծբնա Հայրապետ",
            titleRu: "Святой Иаков Низибийский (Сурб Акоб)",
            titleEn: "Feast of St. James of Nisibis (Mtsbna)",
            descriptionHy: "Արարատ լեռը բարձրացած և Նոյյան Տապանի մասունքը հրեշտակից ստացած սուրբ հայրապետի հիշատակը:",
            descriptionRu: "Память святителя Иакова Низибийского, поднявшегося на гору Арарат и сподобившегося получить от ангела частицу Ноева Ковчега (хранится в Эчмиадзине).",
            descriptionEn: "Commemoration of St. James of Nisibis, who ascended Mount Ararat and received the relic of Noah's Ark from an angel.",
            meaningHy: "Անխոնջ որոնման և հավատքի պարգևի խորհրդանիշ: Նրա բերած Տապանի փայտը մինչ օրս պահպանվում է Էջմիածնում:",
            meaningRu: "Символ непоколебимой веры и духовного упорства. Частица Ноева Ковчега — святыня Армянской Церкви.",
            meaningEn: "A testament to perseverance in faith; the piece of Noah's Ark brought by him is venerated in Holy Etchmiadzin.",
            traditionsHy: "Սուրբ Պատարագ և Նոյյան Տապանի մասունքի դուրսբերում Էջմիածնում:",
            traditionsRu: "Праздничная Литургия и поклонение частице Ноева Ковчега в Эчмиадзине.",
            traditionsEn: "Solemn Liturgy and veneration of the relic of Noah's Ark.",
            scriptureReading: "Եբրայեցիս 11:1-10",
            prayerHy: "Սուրբ հայրապետ Հակոբ, քո աղօթքներով պահպանեա՛ զՀայաստան աշխարհ:",
            prayerRu: "Святителю Христов Иакове, моли Бога о мире и благословении земли нашей!",
            prayerEn: "Holy Father James, by your prayers preserve our land and grant us steadfast faith!",
            isFasting: false
        ))
        
        // Святой первомученик Стефан (Սուրբ Ստեփանոս Նախավկա — 25 декабря)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_stephen",
            type: .saints,
            date: createDate(year: year, month: 12, day: 25),
            titleHy: "Սուրբ Ստեփանոս Նախավկա",
            titleRu: "Святой первомученик архидиакон Стефан",
            titleEn: "Feast of St. Stephen the Protomartyr",
            descriptionHy: "Քրիստոնեական առաջին մարտիրոսի և սարկավագի հիշատակը: Հայ Եկեղեցու սարկավագների օրհնության տոն:",
            descriptionRu: "Память первого христианского мученика — архидиакона Стефана, побитого камнями за веру во Христа. Праздник диаконского служения.",
            descriptionEn: "Commemoration of the first Christian martyr, Archdeacon Stephen, stoned for preaching Christ. Day of Deacons.",
            meaningHy: "Ներման մեծագույն օրինակ: Քարկոծվելիս Ստեփանոսն աղոթում էր իրեն սպանողների համար՝ «Տեր, մի՛ համարիր նրանց այս մեղքը»:",
            meaningRu: "Вершина христианской любви: умирая под ударами камней, Стефан молился о прощении своих убийц.",
            meaningEn: "The supreme example of Christian forgiveness: while being stoned, Stephen prayed for his persecutors.",
            traditionsHy: "Սարկավագների օրհնության կարգ և տոնական Պատարագ:",
            traditionsRu: "Чин благословения диаконов Церкви, которым дозволяется надевать короны (таг) во время Литургии.",
            traditionsEn: "Blessing of all deacons and special liturgical honors.",
            scriptureReading: "Գործք Առաքելոց 6:8-7:60",
            prayerHy: "Սուրբ Ստեփանոս Նախավկայ, ուսո՛ մեզ սիրել եւ ներել թշնամիներին Քո օրինակով:",
            prayerRu: "Первомучениче Христов Стефане, моли Бога даровать нам дух кротости и всепрощения!",
            prayerEn: "Holy Protomartyr Stephen, teach us to love and forgive our enemies as Christ taught us!",
            isFasting: false
        ))
        
        // Святые апостолы Петр и Павел (Սուրբ Պետրոս և Պողոս — 27 декабря)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_peter_paul",
            type: .saints,
            date: createDate(year: year, month: 12, day: 27),
            titleHy: "Սուրբ Պետրոս և Պողոս առաքյալներ",
            titleRu: "Святые первоверховные апостолы Петр и Павел",
            titleEn: "Feast of Holy Apostles Peter and Paul",
            descriptionHy: "Եկեղեցու երկու մեծագույն սյուների՝ Պետրոս և Պողոս առաքյալների հիշատակության օրը:",
            descriptionRu: "Память первоверховных апостолов Петра и Павла, проповедавших Евангелие по всей вселенной и принявших мученическую кончину в Риме.",
            descriptionEn: "Commemoration of the preeminent leaders of the Apostles, Sts. Peter and Paul, who preached Christ worldwide.",
            meaningHy: "Պետրոսը հավատքի վեմն է, Պողոսը՝ իմաստության և ավետարանչության հզոր շեփորը:",
            meaningRu: "Апостол Петр явил твердость веры, апостол Павел — пламенную ревность в благовестии всем народам.",
            meaningEn: "Peter represents the rock of faith; Paul represents the tireless zeal for preaching the Gospel.",
            traditionsHy: "Սուրբ Պատարագ և առաքելական ծառայության գնահատում:",
            traditionsRu: "Праздничная Литургия и молитвы об укреплении в апостольской вере.",
            traditionsEn: "Festive Liturgy and prayers for apostolic missionary zeal.",
            scriptureReading: "2 Տիմոթեոս 4:6-18, Մատթեոս 16:13-19",
            prayerHy: "Սուրբ գլխաւոր առաքեալք Պետրոս եւ Պօղոս, աղօթեցէ՛ք վասն անսասանութեան Եկեղեցւոյ:",
            prayerRu: "Первоверховные апостолы Петре и Павле, молите Пастыреначальника Христа о мире Церкви Его!",
            prayerEn: "Holy Chief Apostles Peter and Paul, pray to the Chief Shepherd Christ for the unity of His Church!",
            isFasting: false
        ))
        
        // Святые апостолы Иаков Заведеев и Иоанн Богослов (Սուրբ Հակոբոս և Հովհաննես — 29 декабря)
        list.append(ArmenianChurchFeast(
            id: "\(year)_st_james_john",
            type: .saints,
            date: createDate(year: year, month: 12, day: 29),
            titleHy: "Սուրբ Հակոբոս և Հովհաննես առաքյալներ",
            titleRu: "Святые апостолы Иаков и Иоанн Богослов",
            titleEn: "Feast of Apostles James and John (Sons of Thunder)",
            descriptionHy: "Զեբեդեոսի որդիների («Որոտման որդիներ»)՝ Հակոբոսի և Քրիստոսի սիրելի աշակերտ Հովհաննես Ավետարանչի հիշատակը:",
            descriptionRu: "Память святых братьев апостолов Иакова Зеведеева и Иоанна Богослова («Сынов громовых»), ближайших учеников Спасителя.",
            descriptionEn: "Commemoration of the holy brothers Apostles James and John the Evangelist (Sons of Thunder).",
            meaningHy: "Հովհաննես Ավետարանիչը սիրո քարոզիչն է («Աստուած սէր է»), իսկ Հակոբոսը՝ առաջին նահատակված առաքյալը:",
            meaningRu: "Апостол Иоанн возвестил высшую тайну: «Бог есть любовь», а апостол Иаков первым из двенадцати запечатлел веру мученической смертью.",
            meaningEn: "St. John proclaimed that 'God is Love', while St. James was the first apostle to suffer martyrdom for Christ.",
            traditionsHy: "Սիրո և եղբայրության աղոթքներ:",
            traditionsRu: "Молитвы об умножении любви и согласия среди христиан.",
            traditionsEn: "Prayers for divine love, peace, and fraternal unity.",
            scriptureReading: "1 Հովհաննես 4:7-21, Մատթեոս 20:20-28",
            prayerHy: "Սուրբ առաքեալք Յակոբոս եւ Յովհաննէս, ուսուցէ՛ք մեզ սիրել զմիմեանս Քրիստոսի սիրով:",
            prayerRu: "Святые апостолы Иакове и Иоанне Богослове, молите Христа Бога научить нас искренней любви!",
            prayerEn: "Holy Apostles James and John, pray to Christ to teach us true and everlasting love!",
            isFasting: false
        ))
        
        return list.sorted { $0.date < $1.date }
    }
    
    // MARK: - Сортировка по дате приближения праздника (Ближайшие предстоящие первыми)
    func feastsSortedByApproaching(for year: Int, from baseDate: Date = Date()) -> [ArmenianChurchFeast] {
        let all = feasts(for: year)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: baseDate)
        
        let upcoming = all.filter { calendar.startOfDay(for: $0.date) >= today }
            .sorted { $0.date < $1.date }
        
        let passed = all.filter { calendar.startOfDay(for: $0.date) < today }
            .sorted { $0.date < $1.date }
        
        return upcoming + passed
    }
    
    // MARK: - Праздник на сегодня (если есть)
    func todayFeast(from baseDate: Date = Date()) -> ArmenianChurchFeast? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: baseDate)
        let allFeasts = feasts(for: year)
        return allFeasts.first { calendar.isDate($0.date, inSameDayAs: baseDate) }
    }
    
    // MARK: - Ближайший Великий праздник (Тагавар)
    func nextDaghavarFeast(from baseDate: Date = Date()) -> (feast: ArmenianChurchFeast, daysLeft: Int)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: baseDate)
        let year = calendar.component(.year, from: today)
        
        var candidates = feasts(for: year).filter { $0.type == .daghavar && calendar.startOfDay(for: $0.date) >= today }
        
        if candidates.isEmpty {
            candidates = feasts(for: year + 1).filter { $0.type == .daghavar }
        }
        
        guard let next = candidates.first else { return nil }
        let nextDay = calendar.startOfDay(for: next.date)
        let diff = calendar.dateComponents([.day], from: today, to: nextDay).day ?? 0
        return (next, max(0, diff))
    }
    
    // MARK: - Ближайший предстоящий любой праздник
    func nextUpcomingFeast(from baseDate: Date = Date()) -> (feast: ArmenianChurchFeast, daysLeft: Int)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: baseDate)
        let year = calendar.component(.year, from: today)
        
        var candidates = feasts(for: year).filter { calendar.startOfDay(for: $0.date) >= today }
        
        if candidates.isEmpty {
            candidates = feasts(for: year + 1)
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
            if !feast.meaning(for: language).isEmpty {
                desc += "\\n\\n🕊️ \("feast_meaning_section_spiritual".localized(for: language)): \(feast.meaning(for: language))"
            }
            if !feast.traditions(for: language).isEmpty {
                desc += "\\n\\n🕯️ \("feast_meaning_section_traditions".localized(for: language)): \(feast.traditions(for: language))"
            }
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
