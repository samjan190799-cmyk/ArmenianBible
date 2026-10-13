import Foundation

// MARK: - «Нарек утешает»: подбор главы «Книги скорбных песнопений» под состояние человека
// Человек одной фразой говорит, что на сердце. Приложение находит в 95 главах Нарекаци ту,
// что ближе всего по настроению, показывает строки и включает озвучку. Подбор работает без сети
// и без ключа ИИ: по словам человека и по темам глав. ИИ (если у человека свой ключ) только
// добавляет личное слово утешения по нажатию кнопки.

/// Состояние души, под которое подбирается глава
enum ConsolationTheme: String, CaseIterable, Identifiable, Hashable {
    case sorrow, fear, guilt, loneliness, weariness, sickness, doubt, anger, hope, gratitude

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .sorrow: return language.pick(hy: "Վիշտ", ru: "Скорбь", en: "Sorrow")
        case .fear: return language.pick(hy: "Վախ", ru: "Тревога", en: "Fear")
        case .guilt: return language.pick(hy: "Մեղք", ru: "Вина", en: "Guilt")
        case .loneliness: return language.pick(hy: "Մենակություն", ru: "Одиночество", en: "Loneliness")
        case .weariness: return language.pick(hy: "Հոգնածություն", ru: "Усталость", en: "Weariness")
        case .sickness: return language.pick(hy: "Հիվանդություն", ru: "Болезнь", en: "Illness")
        case .doubt: return language.pick(hy: "Կասկած", ru: "Сомнение", en: "Doubt")
        case .anger: return language.pick(hy: "Բարկություն", ru: "Обида", en: "Resentment")
        case .hope: return language.pick(hy: "Հույս", ru: "Надежда", en: "Hope")
        case .gratitude: return language.pick(hy: "Շնորհակալություն", ru: "Благодарность", en: "Gratitude")
        }
    }

    var symbol: String {
        switch self {
        case .sorrow: return "cloud.rain"
        case .fear: return "wind"
        case .guilt: return "hands.sparkles"
        case .loneliness: return "moon"
        case .weariness: return "bed.double"
        case .sickness: return "cross.case"
        case .doubt: return "questionmark.circle"
        case .anger: return "flame"
        case .hope: return "sunrise"
        case .gratitude: return "sparkles"
        }
    }

    /// Корни слов на трёх языках (строчные): по ним ищется состояние и в словах человека, и в главах
    var stems: [String] {
        switch self {
        case .sorrow:
            return ["скорб", "печал", "горе", "горю", "плач", "слез", "рыда", "стон", "вздох", "сокруш", "уныни", "грустн", "тоск", "потер", "умер", "скуча",
                    "sorrow", "grief", "weep", "tear", "lament", "mourn", "sigh", "anguish", "sad", "lost my", "died",
                    "ողբ", "արցունք", "տրտում", "վիշտ", "հառաչ", "հեծ", "սգ", "կարոտ"]
        case .fear:
            return ["страх", "боюсь", "боять", "страшн", "ужас", "тревог", "трепет", "опасн", "паник", "беспокой", "волную",
                    "fear", "afraid", "terror", "anxi", "tremb", "dread", "danger", "panic", "worr", "scared",
                    "վախ", "սարսափ", "երկյուղ", "տագնապ", "սարս", "անհանգիստ"]
        case .guilt:
            return ["грех", "виновн", "вина", "вину", "вины", "виной", "покая", "раска", "прости", "беззакон", "согреш", "нечист", "стыд", "совест",
                    "sins", "sinful", "sinner", "sinned", "guilt", "repent", "forgive", "iniquit", "transgress", "unclean", "shame", "ashamed", "regret",
                    "մեղ", "ապաշխար", "թող", "անօրէն", "անօրեն", "ամօթ", "ամոթ"]
        case .loneliness:
            return ["одинок", "покинут", "оставлен", "сирот", "изгна", "никому не нуж", "никого нет", "пустот", "чужой",
                    "alone", "lonely", "forsaken", "abandon", "orphan", "exile", "empty", "nobody",
                    "մենակ", "լքված", "լքուած", "որբ", "աքսոր", "դատարկ"]
        case .weariness:
            return ["устал", "утомл", "изнемог", "бремя", "тяжест", "тяжело", "изнур", "слаб", "бессил", "выгор", "нет сил", "сил нет",
                    "tired", "weary", "exhaust", "burden", "weak", "faint", "heavy", "burnout", "no strength",
                    "հոգնած", "հոգնել", "ուժաթափ", "բեռ", "թուլ", "ծանր"]
        case .sickness:
            return ["болез", "недуг", "исцел", "больн", "болит", "болью", "боли ", " рана", " рану", " раны", "язв", "врач", "целите", "диагноз", "операци",
                    "sick", "disease", "heal ", "healing", "healed", "illness", "wound", "physician", "pain", "cancer", "surgery",
                    "հիվանդ", "բժշկ", "վէր", "վերք", "ցավ", "ցաւ", "ախտ"]
        case .doubt:
            return ["сомнен", "сомнева", "неверие", "маловер", "блужда", "потерял путь", "заблуд", "смысл", "зачем", "не понимаю", "где бог",
                    "doubt", "unbelief", "wander", "stray", "confus", "meaning", "why god", "where is god",
                    "կասկած", "թերահավատ", "մոլոր", "իմաստ"]
        case .anger:
            return ["гнев", "ярост", "злоб", "обид", "месть", "раздраж", "злюсь", "зол ", "несправедлив", "предал",
                    "anger", "angry", "wrath", "rage", "resent", "bitter", "revenge", "betray", "unfair",
                    "բարկ", "զայր", "ոխ", "դառն", "դավաճան"]
        case .hope:
            return ["надежд", "упова", "свет", "утеш", "рассвет", "воскрес", "избав", "вера", "верю", "поддержк",
                    "hope", "trust", "light", "comfort", "dawn", "deliver", "salvation", "faith", "believe", "strength",
                    "յոյս", "հույս", "լոյս", "լույս", "մխիթար", "փրկ", "յարութ", "հավատ", "հաւատ"]
        case .gratitude:
            return ["благодар", "славл", "хвал", "дарова", "дарует", "дары", "благослов", "радост", "воспо", "счастл", " рад ",
                    "thank", "praise", "glory", "gift", "bless", "joy", "rejoice", "happy", "grateful",
                    "գոհ", "փառ", "օրհն", "ուրախ", "շնորհ"]
        }
    }
}

// MARK: - Найденная глава
struct NarekMatch: Identifiable {
    let prayer: NarekPrayer
    let score: Double
    var id: Int { prayer.id }

    /// Первая строфа главы: её читают вслух и кладут на рукопись
    func firstStanza(for language: AppLanguage) -> String {
        let text = prayer.text(for: language).trimmingCharacters(in: .whitespacesAndNewlines)
        let stanza = text.components(separatedBy: "\n\n").first ?? text
        return stanza.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func restOfText(for language: AppLanguage) -> String {
        let text = prayer.text(for: language).trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = text.components(separatedBy: "\n\n")
        guard parts.count > 1 else { return "" }
        return parts.dropFirst().joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Подбор
enum NarekConsolationEngine {
    /// Насколько каждая тема выражена в каждой главе (считается один раз)
    private static let profiles: [Int: [ConsolationTheme: Double]] = {
        var result: [Int: [ConsolationTheme: Double]] = [:]
        for prayer in NarekatsiDatabase.shared.prayers {
            let haystack = [prayer.titleHy, prayer.titleRu, prayer.titleEn, prayer.textHy, prayer.textRu, prayer.textEn]
                .joined(separator: " ")
                .lowercased()
            var profile: [ConsolationTheme: Double] = [:]
            for theme in ConsolationTheme.allCases {
                var hits = 0
                for stem in theme.stems {
                    hits += haystack.components(separatedBy: stem).count - 1
                }
                profile[theme] = min(1.0, Double(hits) / 2.0)
            }
            result[prayer.id] = profile
        }
        return result
    }()

    /// Состояния, которые угадываются по тексту человека
    static func themes(in text: String) -> [ConsolationTheme: Double] {
        let lowered = text.lowercased()
        var result: [ConsolationTheme: Double] = [:]
        for theme in ConsolationTheme.allCases {
            var hits = 0
            for stem in theme.stems where lowered.contains(stem) {
                hits += 1
            }
            if hits > 0 { result[theme] = Double(min(hits, 3)) }
        }
        return result
    }

    /// Пять лучших глав; если ни слова, ни состояния не опознаны — «слово дня»
    static func rank(text: String, chips: Set<ConsolationTheme>, language: AppLanguage, now: Date = Date()) -> [NarekMatch] {
        let prayers = NarekatsiDatabase.shared.prayers
        guard !prayers.isEmpty else { return [] }

        var wanted = themes(in: text)
        for chip in chips { wanted[chip, default: 0] += 2.0 }

        // Значимые слова человека: пять первых букв достаточно, чтобы поймать разные формы слова
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count >= 5 }
            .map { String($0.prefix(5)) }

        let dayOfYear = Calendar(identifier: .gregorian).ordinality(of: .day, in: .year, for: now) ?? 1
        var scored: [NarekMatch] = []
        for prayer in prayers {
            let profile = profiles[prayer.id] ?? [:]
            var score = 0.0
            for (theme, weight) in wanted {
                score += weight * (profile[theme] ?? 0)
            }
            if !words.isEmpty {
                let haystack = [prayer.titleHy, prayer.titleRu, prayer.titleEn, prayer.textHy, prayer.textRu, prayer.textEn]
                    .joined(separator: " ")
                    .lowercased()
                let overlap = words.filter { haystack.contains($0) }.count
                score += 0.35 * Double(min(overlap, 4))
            }
            // Равные по очкам главы чередуются по дням, чтобы слово не повторялось изо дня в день
            score += Double((prayer.id + dayOfYear) % 95) / 100_000
            scored.append(NarekMatch(prayer: prayer, score: score))
        }
        scored.sort { $0.score > $1.score }

        let hasSignal = (scored.first?.score ?? 0) >= 0.3
        if !hasSignal {
            let index = (dayOfYear * 7) % prayers.count
            let daily = prayers[index]
            var rest = scored.filter { $0.prayer.id != daily.id }
            rest.insert(NarekMatch(prayer: daily, score: 0), at: 0)
            return Array(rest.prefix(5))
        }
        return Array(scored.prefix(5))
    }

    /// Слова, при которых утешение не должно быть «автоматическим»: человеку важнее живой человек рядом
    static func needsGentleCare(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let markers = ["не хочу жить", "покончить с собой", "суицид", "убить себя", "лучше умереть", "хочу умереть",
                       "kill myself", "suicide", "end my life", "don't want to live", "want to die",
                       "ինքնասպան", "չեմ ուզում ապրել", "ուզում եմ մեռնել"]
        return markers.contains { lowered.contains($0) }
    }
}

// MARK: - Бесплатная проба Premium-функции: одно использование в день
enum PremiumTaste {
    private static func keys(_ feature: String) -> (date: String, count: String) {
        ("taste_\(feature)_date", "taste_\(feature)_count")
    }

    private static func today() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    static func usesToday(_ feature: String) -> Int {
        let k = keys(feature)
        guard UserDefaults.standard.string(forKey: k.date) == today() else { return 0 }
        return UserDefaults.standard.integer(forKey: k.count)
    }

    @MainActor
    static func isAllowed(_ feature: String, freePerDay: Int) -> Bool {
        SubscriptionManager.shared.isPremium || usesToday(feature) < freePerDay
    }

    /// Только для скриншотов в CI (-consolation_reset YES)
    static func reset(_ feature: String) {
        let k = keys(feature)
        UserDefaults.standard.removeObject(forKey: k.date)
        UserDefaults.standard.removeObject(forKey: k.count)
    }

    static func record(_ feature: String) {
        let k = keys(feature)
        let count = usesToday(feature) + 1
        UserDefaults.standard.set(today(), forKey: k.date)
        UserDefaults.standard.set(count, forKey: k.count)
    }
}
