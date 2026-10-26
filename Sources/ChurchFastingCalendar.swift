import Foundation

// MARK: - Постные дни Армянской Церкви (по каждому дню года)
//
// Правила сведены из независимых публикаций Армянской Апостольской Церкви: епархии, приходы,
// опубликованные календари на 2025–2027 годы (английский, русский и армянский языки).
// Проверка шла по поисковым выдержкам, без первоисточников, поэтому действует правило
// осторожности: день называется постным, ТОЛЬКО если постным его считают ВСЕ найденные
// варианты правила. Спорные границы оставлены БЕЗ утверждения — для них fastDay возвращает nil,
// то есть приложение ничего не говорит о таком дне (ни «пост», ни «не пост»).
//
// Спорные места (сверить с календарём Первопрестольного Святого Эчмиадзина):
//  • Окно отмены поста по средам и пятницам после Пасхи: до Вознесения (Пасха…Пасха+39) либо
//    до Пятидесятницы (Пасха…Пасха+49). Среды и пятницы Пасха+40…+49 → nil.
//  • Конец Великого поста: пятница перед Лазаревой субботой (Пасха−9), суббота (Пасха−8) либо
//    Пасха−1. Утверждаются только будни Пасха−48…Пасха−9; Страстная седмица (Пасха−6…−1) —
//    отдельным периодом; субботы и воскресенья Великого поста → nil.
//  • Конец поста Рождества и Богоявления: 4 января (6 дней) либо вечер 5 января (7 дней).
//    Утверждается 30 декабря…4 января, 5 января → nil.
//  • Передовой пост: пять дней (пн–пт), по другим источникам три дня (пн–ср) или пн–чт.
//    Утверждаются только пн–ср; четверг → nil, пятница считается обычным еженедельным постом.
//  • Хисначк (Адвент, «пятьдесят дней») — молитвенное время, а не строгий пост: начало (воскресенье,
//    ближайшее к 18 ноября) показано в списке праздников, но постными днями не объявляется.
//  • Посты св. Иакова Мцбинского и Варагского Креста — пять дней, пн–пт, перед праздником
//    (по календарю Армянской Церкви в Грузии, сверенному с рядом дат 2021–2030).
//  • Послабления в попразднства Богоявления (6–13 или 6–14 января), Преображения и Успения
//    (девять дней) упомянуты не всеми источниками: среды и пятницы в эти окна → nil,
//    то есть день не называется постным. Пятидесятница покрыта неделей поста Илии.
//  • Господский праздник в среду или пятницу празднуется без поста (один русскоязычный
//    источник) — такой день тоже → nil.

// MARK: - Вид поста
enum ChurchFastKind: String, CaseIterable, Sendable {
    case weekly                // Օրապահք: среда и пятница
    case catechumens           // Առաջավորաց պահք: пн–ср за три недели до Великого поста
    case greatLent             // Մեծ պահք
    case holyWeek              // Ավագ շաբաթ
    case elijah                // Եղիայի պահք: неделя после Пятидесятницы
    case gregoryIlluminator    // Սուրբ Գրիգոր Լուսավորչի պահք
    case transfiguration       // Վարդավառի պահք: неделя перед Преображением
    case assumption            // Աստվածածնի Վերափոխման պահք: неделя перед Успением
    case exaltation            // Խաչվերացի պահք: неделя перед Воздвижением
    case varak                 // Վարագա Սուրբ Խաչի պահք: неделя перед праздником Варагского Креста
    case jacob                 // Սուրբ Հակոբ Մծբնա Հայրապետի պահք: неделя перед памятью св. Иакова Низибийского
    case nativity              // Սուրբ Ծննդյան և Աստվածահայտնության պահք

    func title(for language: AppLanguage) -> String {
        switch self {
        case .weekly:
            switch language {
            case .armenian: return "Օրապահք"
            case .russian: return "Постный день"
            case .english: return "Fast day"
            }
        case .catechumens:
            switch language {
            case .armenian: return "Առաջավորաց պահք"
            case .russian: return "Передовой пост (Араджаворац)"
            case .english: return "Fast of the Catechumens"
            }
        case .greatLent:
            switch language {
            case .armenian: return "Մեծ պահք"
            case .russian: return "Великий пост"
            case .english: return "Great Lent"
            }
        case .holyWeek:
            switch language {
            case .armenian: return "Ավագ շաբաթ"
            case .russian: return "Страстная седмица"
            case .english: return "Holy Week"
            }
        case .elijah:
            switch language {
            case .armenian: return "Եղիայի պահք"
            case .russian: return "Пост пророка Илии"
            case .english: return "Fast of the Prophet Elijah"
            }
        case .gregoryIlluminator:
            switch language {
            case .armenian: return "Սուրբ Գրիգոր Լուսավորչի պահք"
            case .russian: return "Пост св. Григория Просветителя"
            case .english: return "Fast of St. Gregory the Illuminator"
            }
        case .transfiguration:
            switch language {
            case .armenian: return "Վարդավառի (Պայծառակերպության) պահք"
            case .russian: return "Пост перед Преображением (Вардавар)"
            case .english: return "Fast of the Transfiguration"
            }
        case .assumption:
            switch language {
            case .armenian: return "Աստվածածնի Վերափոխման պահք"
            case .russian: return "Пост перед Успением"
            case .english: return "Fast of the Assumption"
            }
        case .exaltation:
            switch language {
            case .armenian: return "Խաչվերացի պահք"
            case .russian: return "Пост перед Воздвижением"
            case .english: return "Fast of the Exaltation of the Holy Cross"
            }
        case .varak:
            switch language {
            case .armenian: return "Վարագա Սուրբ Խաչի պահք"
            case .russian: return "Пост Варагского Креста"
            case .english: return "Fast of the Holy Cross of Varak"
            }
        case .jacob:
            switch language {
            case .armenian: return "Սուրբ Հակոբ Մծբնա Հայրապետի պահք"
            case .russian: return "Пост св. Иакова Низибийского"
            case .english: return "Fast of St. James of Nisibis"
            }
        case .nativity:
            switch language {
            case .armenian: return "Սուրբ Ծննդյան և Աստվածահայտնության պահք"
            case .russian: return "Пост перед Рождеством и Богоявлением"
            case .english: return "Fast of the Nativity and Theophany"
            }
        }
    }

    /// Текст напоминания накануне постного дня
    func reminderBody(for language: AppLanguage) -> String {
        let title = self.title(for: language)
        switch language {
        case .armenian: return "Վաղը՝ \(title)"
        case .russian: return "Завтра: \(title)"
        case .english: return "Tomorrow: \(title)"
        }
    }
}

// MARK: - Постный день
struct ChurchFastDay: Equatable, Sendable {
    let kind: ChurchFastKind
}

// MARK: - Арифметика дат без часовых поясов
/// Все правила считаются на целых «номерах дней» (дни от 1970-01-01 по григорианскому календарю),
/// поэтому результат не зависит от часового пояса устройства.
enum ChurchFastRules {
    /// Число дней от 1970-01-01 для григорианской даты (алгоритм Говарда Хиннанта)
    static func dayNumber(year: Int, month: Int, day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yearOfEra = y - era * 400
        let monthFromMarch = (month + 9) % 12
        let dayOfYear = (153 * monthFromMarch + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146097 + dayOfEra - 719468
    }

    /// День недели номера дня: 0 = воскресенье … 6 = суббота (1970-01-01 был четвергом)
    static func weekday(of dayNumber: Int) -> Int {
        (((dayNumber + 4) % 7) + 7) % 7
    }

    /// Григорианская Пасха (та же пасхалия, что в ChurchCalendarService.calculateEaster)
    static func easterDayNumber(for year: Int) -> Int {
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
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return dayNumber(year: year, month: month, day: day)
    }

    /// Воскресенье, ближайшее к указанной дате
    static func sundayNearest(year: Int, month: Int, day: Int) -> Int {
        let number = dayNumber(year: year, month: month, day: day)
        let weekday = self.weekday(of: number)
        return weekday <= 3 ? number - weekday : number + (7 - weekday)
    }

    /// Постный статус григорианской даты; nil — приложение ничего не утверждает
    static func fastKind(year: Int, month: Int, day: Int) -> ChurchFastKind? {
        // Пост Рождества и Богоявления: 30 декабря – 4 января (через границу года)
        if (month == 12 && day >= 30) || (month == 1 && day <= 4) {
            return .nativity
        }

        let today = dayNumber(year: year, month: month, day: day)
        let delta = today - easterDayNumber(for: year)   // дней после Пасхи (Пасха — воскресенье)
        let weekday = self.weekday(of: today)

        // Периоды, привязанные к Пасхе
        switch delta {
        case -69 ... -67:
            return .catechumens                                      // пн–ср: входит во все варианты (3, 4 и 5 дней)
        case -48 ... -9 where (1 ... 5).contains(weekday):
            return .greatLent                                        // будни до пятницы перед Лазаревой субботой
        case -6 ... -1:
            return .holyWeek
        case 50 ... 54:
            return .elijah                                           // пн–пт после Пятидесятницы
        case 71 ... 75:
            return .gregoryIlluminator
        case 92 ... 96:
            return .transfiguration                                  // пн–пт перед Преображением (Пасха+98)
        default:
            break
        }

        // Недели поста перед Успением, Воздвижением и Варагским Крестом: пн–пт перед праздничным воскресеньем
        let assumptionSunday = sundayNearest(year: year, month: 8, day: 15)
        if (assumptionSunday - 6 ... assumptionSunday - 2).contains(today) {
            return .assumption
        }
        let exaltationSunday = sundayNearest(year: year, month: 9, day: 14)
        if (exaltationSunday - 6 ... exaltationSunday - 2).contains(today) {
            return .exaltation
        }
        let varakSunday = exaltationSunday + 14
        if (varakSunday - 6 ... varakSunday - 2).contains(today) {
            return .varak
        }

        // Пост св. Иакова Низибийского: пн–пт перед субботой памяти (начало Адвента + 27 дней)
        let adventStart = sundayNearest(year: year, month: 11, day: 18)
        let jacobSaturday = adventStart + 27
        if (jacobSaturday - 5 ... jacobSaturday - 1).contains(today) {
            return .jacob
        }

        // Еженедельный пост: среда и пятница
        guard weekday == 3 || weekday == 5 else { return nil }
        if (0 ... 49).contains(delta) { return nil }                 // Пасха…Пятидесятница: отмена / спорные дни
        if month == 1 && (6 ... 14).contains(day) { return nil }     // попразднство Богоявления (6–13 или 6–14)
        if (98 ... 108).contains(delta) { return nil }               // попразднство Преображения: длина не названа
        if (assumptionSunday ... assumptionSunday + 10).contains(today) { return nil }   // попразднство Успения (9 дней)
        return .weekly
    }
}

// MARK: - Публичный интерфейс календаря
extension ChurchCalendarService {
    /// Правила заданы по григорианским датам, поэтому считаем в григорианском календаре в часовом
    /// поясе пользователя — даже если системный календарь у него буддийский, еврейский и т. п.
    private var gregorianLocalCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Calendar.current.timeZone
        return calendar
    }

    /// Постный статус дня. nil — обычный либо спорный день: приложение ничего не утверждает.
    func fastDay(on date: Date) -> ChurchFastDay? {
        let calendar = gregorianLocalCalendar
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day,
              let kind = ChurchFastRules.fastKind(year: year, month: month, day: day) else { return nil }

        // Господский или великий праздник в среду/пятницу празднуется без поста — тогда не утверждаем
        if kind == .weekly {
            let isFeastDay = feasts(for: year).contains { feast in
                (feast.type == .daghavar || feast.type == .dominical)
                    && !feast.isFasting
                    && calendar.isDate(feast.date, inSameDayAs: date)
            }
            if isFeastDay { return nil }
        }
        return ChurchFastDay(kind: kind)
    }

    /// Постные дни, перед началом которых (накануне вечером) стоит напомнить: предыдущий день
    /// не был постом того же вида. Неделя поста даёт одно напоминание, а не пять.
    func fastReminderDays(from start: Date, horizonDays: Int) -> [(date: Date, fast: ChurchFastDay)] {
        let calendar = gregorianLocalCalendar
        let base = calendar.startOfDay(for: start)
        var result: [(date: Date, fast: ChurchFastDay)] = []
        guard horizonDays > 0 else { return result }
        for offset in 1 ... horizonDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: base),
                  let previous = calendar.date(byAdding: .day, value: -1, to: day),
                  let fast = fastDay(on: day),
                  fastDay(on: previous)?.kind != fast.kind else { continue }
            result.append((date: day, fast: fast))
        }
        return result
    }
}
