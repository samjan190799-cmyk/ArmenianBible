import SwiftUI

// MARK: - Настроение цитаты и выбор кадра
// Файл общий для приложения и виджетов (project.yml: оба таргета): в нём нет ничего, что есть только в одном из них.
// Фотографии лежат в Assets.xcassets обоих таргетов под одними именами (QuoteLight1…QuoteWisdom8, QuoteStrength12); у виджета они меньше.

// MARK: - Настроение цитаты
enum QuoteMood: String, CaseIterable {
    case light      // надежда, вера, спасение: рассвет, лучи, крест на фоне неба
    case love       // любовь, милосердие, радость: мягкий тёплый свет, цветущие поля
    case wisdom     // мудрость, Слово, учение: Библия при свечах, книги, окна монастыря
    case trial      // испытания, терпение, скорбь: дороги в тумане, грозовое небо
    case prayer     // молитва, хвала, святость: свечи, армянские храмы
    case strength   // сила, мужество, Божье величие: Арарат, горы
    case peace      // покой, утешение, Пастырь: тихое море, лес в лучах

    /// Сколько фотографий этого настроения лежит в Assets.xcassets
    var photoCount: Int {
        switch self {
        case .light: return 11
        case .love: return 10
        case .wisdom: return 8
        case .trial: return 11
        case .prayer: return 9
        case .strength: return 12
        case .peace: return 12
        }
    }

    var imageNames: [String] {
        let base = "Quote" + rawValue.prefix(1).uppercased() + String(rawValue.dropFirst())
        return (1...max(photoCount, 1)).map { "\(base)\($0)" }
    }

    /// Резервный фон, пока фото грузится или если его нет: тёмный градиент в цветах настроения
    var fallbackColors: [Color] {
        switch self {
        case .light:
            return [Color(red: 0.16, green: 0.13, blue: 0.10), Color(red: 0.45, green: 0.31, blue: 0.16), Color(red: 0.09, green: 0.07, blue: 0.06)]
        case .love:
            return [Color(red: 0.20, green: 0.12, blue: 0.10), Color(red: 0.46, green: 0.27, blue: 0.16), Color(red: 0.10, green: 0.06, blue: 0.05)]
        case .wisdom:
            return [Color(red: 0.10, green: 0.08, blue: 0.06), Color(red: 0.30, green: 0.21, blue: 0.12), Color(red: 0.05, green: 0.04, blue: 0.03)]
        case .trial:
            return [Color(red: 0.12, green: 0.14, blue: 0.17), Color(red: 0.24, green: 0.27, blue: 0.30), Color(red: 0.06, green: 0.07, blue: 0.09)]
        case .prayer:
            return [Color(red: 0.08, green: 0.06, blue: 0.04), Color(red: 0.36, green: 0.22, blue: 0.08), Color(red: 0.04, green: 0.03, blue: 0.02)]
        case .strength:
            return [Color(red: 0.12, green: 0.15, blue: 0.22), Color(red: 0.32, green: 0.30, blue: 0.34), Color(red: 0.07, green: 0.08, blue: 0.12)]
        case .peace:
            return [Color(red: 0.10, green: 0.15, blue: 0.18), Color(red: 0.30, green: 0.36, blue: 0.38), Color(red: 0.06, green: 0.09, blue: 0.11)]
        }
    }
}

// MARK: - Определение настроения по смыслу стиха
extension QuoteMood {
    /// Признаки настроения: начала слов (русские и английские), отдельные слова и фразы.
    /// Слова сравниваются по началу, поэтому «надежд» находит «надежда», «надежду», «надеждой».
    private struct Signals {
        let stems: [String]
        let words: Set<String>
        let phrases: [String]
    }

    private static let signals: [QuoteMood: Signals] = [
        .light: Signals(
            stems: ["свет", "надежд", "надея", "упова", "спас", "спасен", "веруй", "верующ", "воскрес", "заря", "утрен", "сиян", "сияй", "озар",
                    "light", "hope", "faith", "believ", "salvation", "saviour", "savior", "resurrect", "dawn", "morning", "shine", "glory"],
            words: ["вера", "веры", "веру", "верой", "вере", "верит", "верь", "верьте", "save", "saved", "risen", "rise"],
            phrases: ["жизнь вечн", "eternal life", "everlasting life"]
        ),
        .love: Signals(
            stems: ["любов", "любит", "любящ", "возлюб", "милост", "милосерд", "благодат", "радост", "радуй", "радова", "сострада", "нежн", "ласк",
                    "love", "lovingkind", "merc", "grace", "compassion", "rejoic", "joy", "tender", "beloved"],
            words: ["люби", "любите", "любим", "loved", "loves", "kind", "kindness"],
            phrases: []
        ),
        .wisdom: Signals(
            stems: ["мудр", "разум", "знани", "учени", "наставл", "истин", "закон", "заповед", "позна", "уразум", "учит", "притч", "совет",
                    "wisdom", "wise", "understand", "knowledge", "instruct", "truth", "law", "command", "learn", "teach", "counsel", "proverb"],
            words: ["слово", "слова", "словом", "word", "words"],
            phrases: []
        ),
        .trial: Signals(
            stems: ["терпен", "терпел", "скорб", "испыта", "страда", "печал", "искуш", "тесн", "слез", "плач", "бур", "тьм", "мрак", "гоне", "стез",
                    "patien", "endur", "suffer", "trial", "tribulation", "afflict", "sorrow", "tear", "weep", "storm", "persever", "tempt", "darkness", "persecut"],
            words: ["путь", "пути", "путём", "путем", "дорога", "дороги", "дорогу", "path", "paths"],
            phrases: ["не бойс", "fear not", "do not fear", "be not afraid", "долина смерт", "valley of the shadow"]
        ),
        .prayer: Signals(
            stems: ["молит", "молис", "помоли", "моле", "взыва", "хвал", "поклон", "свят", "храм", "алтар", "благослов", "славосл", "воспой", "воспева",
                    "pray", "praise", "worship", "holy", "holiness", "temple", "altar", "bless", "sanctu", "sing"],
            words: ["просите", "аминь", "ask", "amen"],
            phrases: ["призову", "call upon", "call on the"]
        ),
        .strength: Signals(
            stems: ["сил", "крепк", "крепост", "укрепл", "мужеств", "мужай", "твердын", "скал", "щит", "побед", "могуч", "всемогущ", "держав", "вседерж",
                    "strength", "strong", "mighty", "power", "courage", "fortress", "shield", "victor", "almighty", "overcome"],
            words: ["гора", "горы", "гору", "горам", "горах", "rock", "mountain", "mountains"],
            phrases: []
        ),
        .peace: Signals(
            stems: ["покой", "поко", "успоко", "спокой", "тиш", "тих", "пастыр", "утеш", "отдых", "отдохн", "безмолв",
                    "peace", "rest", "quiet", "comfort", "shepherd", "calm", "still", "pasture"],
            words: ["мир", "мира", "миром", "мире", "миру", "пажит", "пажитях", "воды", "водам"],
            phrases: ["тихим вод", "still waters", "green pastures"]
        )
    ]

    /// Настроение стиха. Если по словам ничего не понятно, берётся «свет» или «покой» (по ключу стиха):
    /// небо, рассвет и тихая природа подходят почти любому стиху и не спорят с его смыслом.
    static func of(_ verse: BibleVerse) -> QuoteMood {
        var scores: [QuoteMood: Int] = [:]
        let text = (stripNotes(verse.textRu) + " " + stripNotes(verse.textEn)).lowercased()
        let tokens = text.split(whereSeparator: { !$0.isLetter }).map(String.init)

        for (mood, signal) in signals {
            var score = 0
            for stem in signal.stems where tokens.contains(where: { $0.hasPrefix(stem) }) { score += 2 }
            for word in signal.words where tokens.contains(word) { score += 2 }
            for phrase in signal.phrases where text.contains(phrase) { score += 3 }
            if score > 0 { scores[mood] = score }
        }

        // Книга подсказывает настроение так же, как подборки виджетов (BibleVerseDatabase+Filter.swift)
        let reference = (verse.refHy + " " + verse.refRu + " " + verse.refEn).lowercased()
        if verse.isPrayer { scores[.prayer, default: 0] += 4 }
        if reference.contains("սաղմոս") || reference.contains("псалом") || reference.contains("psalm") {
            scores[.prayer, default: 0] += 1
        }
        if reference.contains("նարեկ") || reference.contains("нарекаци") || reference.contains("narek") {
            scores[.prayer, default: 0] += 2
        }
        if reference.contains("առակ") || reference.contains("ժողովող") || reference.contains("իմաստութ") ||
            reference.contains("притч") || reference.contains("екклесиаст") || reference.contains("премудрост") ||
            reference.contains("proverbs") || reference.contains("ecclesiastes") || reference.contains("wisdom") {
            scores[.wisdom, default: 0] += 3
        }

        // При равенстве побеждает настроение, стоящее раньше в allCases: так результат не зависит от порядка словаря
        var best: QuoteMood = .light
        var bestScore = 0
        for mood in QuoteMood.allCases {
            let score = scores[mood] ?? 0
            if score > bestScore {
                best = mood
                bestScore = score
            }
        }
        if bestScore == 0 {
            return stableHash(verse.refEn + "|" + verse.textRu) % 2 == 0 ? .light : .peace
        }
        return best
    }

    /// Убирает пометки в фигурных скобках (в английском тексте они стоят в конце стиха)
    private static func stripNotes(_ text: String) -> String {
        var result = ""
        var depth = 0
        for character in text {
            if character == "{" { depth += 1; continue }
            if character == "}" { depth = max(0, depth - 1); continue }
            if depth == 0 { result.append(character) }
        }
        return result
    }
}

// MARK: - Выбор фотографии для стиха
struct QuoteBackdropChoice: Equatable {
    let mood: QuoteMood
    /// Имя изображения в Assets.xcassets; nil — только градиент настроения
    let imageName: String?
}

enum QuoteBackdrop {
    /// Фотография для стиха: настроение по смыслу, кадр внутри настроения по стабильному ключу стиха.
    /// `avoiding` — кадр предыдущей цитаты: если выпал тот же, берётся соседний, чтобы фон заметно сменился.
    static func choice(for verse: BibleVerse, avoiding previous: String? = nil) -> QuoteBackdropChoice {
        let mood = QuoteMood.of(verse)
        let names = mood.imageNames
        guard !names.isEmpty else { return QuoteBackdropChoice(mood: mood, imageName: nil) }
        // Сдвиг на 7 бит: младшие биты уже решили выбор между «светом» и «покоем» у нейтральных стихов
        var index = Int((stableHash(verse.refEn + "|" + verse.textRu) >> 7) % UInt64(names.count))
        if names.count > 1, names[index] == previous {
            index = (index + 1) % names.count
        }
        return QuoteBackdropChoice(mood: mood, imageName: names[index])
    }
}

/// FNV-1a: одинаков во всех запусках (в отличие от hashValue), поэтому стих не «прыгает» между кадрами
private func stableHash(_ string: String) -> UInt64 {
    var hash: UInt64 = 0xcbf29ce484222325
    for byte in string.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* 0x100000001b3
    }
    return hash
}


// MARK: - Яркость кадров
extension QuoteBackdrop {
    /// Средняя яркость каждого кадра 0…1, посчитанная заранее: по ней подбирается сила затемнения под текстом.
    /// Виджету нечем её мерить на лету (раскодировать кадр в расширении дорого), поэтому таблица готовая.
    /// Новый кадр без записи считается средним (0,45).
    static let luminanceTable: [String: Double] = [
        "QuoteLight1": 0.41,
        "QuoteLight2": 0.38,
        "QuoteLight3": 0.4,
        "QuoteLight4": 0.33,
        "QuoteLight5": 0.56,
        "QuoteLight6": 0.49,
        "QuoteLight7": 0.62,
        "QuoteLight8": 0.32,
        "QuoteLight9": 0.47,
        "QuoteLight10": 0.45,
        "QuoteLight11": 0.53,
        "QuoteLove1": 0.71,
        "QuoteLove2": 0.54,
        "QuoteLove3": 0.53,
        "QuoteLove4": 0.66,
        "QuoteLove5": 0.42,
        "QuoteLove6": 0.57,
        "QuoteLove7": 0.4,
        "QuoteLove8": 0.25,
        "QuoteLove9": 0.59,
        "QuoteLove10": 0.46,
        "QuotePeace1": 0.42,
        "QuotePeace2": 0.61,
        "QuotePeace3": 0.76,
        "QuotePeace4": 0.55,
        "QuotePeace5": 0.58,
        "QuotePeace6": 0.32,
        "QuotePeace7": 0.48,
        "QuotePeace8": 0.58,
        "QuotePeace9": 0.51,
        "QuotePeace10": 0.62,
        "QuotePeace11": 0.61,
        "QuotePeace12": 0.52,
        "QuotePrayer1": 0.18,
        "QuotePrayer2": 0.19,
        "QuotePrayer3": 0.13,
        "QuotePrayer4": 0.23,
        "QuotePrayer5": 0.37,
        "QuotePrayer6": 0.34,
        "QuotePrayer7": 0.45,
        "QuotePrayer8": 0.44,
        "QuotePrayer9": 0.43,
        "QuoteStrength1": 0.44,
        "QuoteStrength2": 0.63,
        "QuoteStrength3": 0.39,
        "QuoteStrength4": 0.43,
        "QuoteStrength5": 0.46,
        "QuoteStrength6": 0.5,
        "QuoteStrength7": 0.61,
        "QuoteStrength8": 0.39,
        "QuoteStrength9": 0.52,
        "QuoteStrength10": 0.46,
        "QuoteStrength11": 0.49,
        "QuoteStrength12": 0.41,
        "QuoteTrial1": 0.42,
        "QuoteTrial2": 0.38,
        "QuoteTrial3": 0.3,
        "QuoteTrial4": 0.35,
        "QuoteTrial5": 0.46,
        "QuoteTrial6": 0.29,
        "QuoteTrial7": 0.47,
        "QuoteTrial8": 0.29,
        "QuoteTrial9": 0.62,
        "QuoteTrial10": 0.63,
        "QuoteTrial11": 0.44,
        "QuoteWisdom1": 0.36,
        "QuoteWisdom2": 0.09,
        "QuoteWisdom3": 0.23,
        "QuoteWisdom4": 0.37,
        "QuoteWisdom5": 0.17,
        "QuoteWisdom6": 0.54,
        "QuoteWisdom7": 0.17,
        "QuoteWisdom8": 0.31
    ]

    static func luminance(of imageName: String?) -> Double {
        imageName.flatMap { luminanceTable[$0] } ?? 0.45
    }
}
