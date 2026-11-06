import SwiftUI
import UIKit

// MARK: - Кинематографический фон карточки цитаты
// Фотографии лежат в Assets.xcassets (QuoteLight1…QuotePeace7): они уже уменьшены до 1080×1350 и сжаты,
// поэтому работают без интернета и не тянут тяжёлых оригиналов. Список авторов: PHOTO_CREDITS.md.
//
// Как устроено:
// 1. QuoteMood: настроение цитаты (свет, любовь, мудрость, испытание, молитва, сила, покой) и её фотографии.
// 2. QuoteMood.of(_:): настроение определяется по смыслу русского и английского текста стиха и по книге.
//    Армянский текст не трогается и не анализируется: у каждого стиха есть все три перевода.
// 3. QuoteBackdrop.choice(for:avoiding:): фотография выбирается по стабильному ключу стиха,
//    поэтому один и тот же стих всегда получает один и тот же кадр (и на экране, и в открытке).
// 4. QuoteBackdropCache: раскодирует фото в фоне, кэширует и считает его яркость, чтобы затемнение
//    подстраивалось под кадр: на светлом небе темнее, на ночных свечах легче.
// 5. CinematicQuoteBackground: само изображение с плавным появлением, сменой кадров, медленным
//    наездом камеры и лёгким параллаксом при прокрутке; без фото остаётся градиент настроения.
//
// Чтобы добавить фото: положить imageset «Quote<Настроение><N>» в Assets.xcassets и увеличить photoCount.

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
        case .light: return 6
        case .love: return 5
        case .wisdom: return 5
        case .trial: return 5
        case .prayer: return 6
        case .strength: return 4
        case .peace: return 7
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

// MARK: - Кэш раскодированных фотографий
final class QuoteBackdropCache {
    static let shared = QuoteBackdropCache()

    /// Неизменяемый после создания: его можно передавать из фоновой задачи раскодирования
    final class Entry: @unchecked Sendable {
        let image: UIImage
        /// Средняя яркость кадра 0…1: по ней подбирается сила затемнения под текстом
        let luminance: CGFloat

        init(image: UIImage, luminance: CGFloat) {
            self.image = image
            self.luminance = luminance
        }
    }

    private let cache: NSCache<NSString, Entry> = {
        let cache = NSCache<NSString, Entry>()
        // Кадр 1080×1350 в памяти занимает около 5,8 МБ: держим до восьми последних
        cache.countLimit = 8
        return cache
    }()

    /// Уже раскодированное фото, без ожидания (для мгновенного показа)
    func cached(_ name: String) -> Entry? {
        cache.object(forKey: name as NSString)
    }

    /// Раскодирует фото вне главного потока и кладёт в кэш. Повторное открытие экрана берёт его из памяти.
    func load(_ name: String) async -> Entry? {
        if let entry = cached(name) { return entry }
        let entry = await Task.detached(priority: .userInitiated) { () -> Entry? in
            Self.decode(name)
        }.value
        if let entry {
            cache.setObject(entry, forKey: name as NSString)
        }
        return entry
    }

    /// Синхронная загрузка для открытки: она рисуется один раз по нажатию «Поделиться»
    func loadNow(_ name: String) -> Entry? {
        if let entry = cached(name) { return entry }
        guard let entry = Self.decode(name) else { return nil }
        cache.setObject(entry, forKey: name as NSString)
        return entry
    }

    private static func decode(_ name: String) -> Entry? {
        guard let image = UIImage(named: name) else { return nil }
        // preparingForDisplay раскодирует JPEG сразу, а не при первом кадре прокрутки
        let prepared = image.preparingForDisplay() ?? image
        return Entry(image: prepared, luminance: averageLuminance(of: prepared))
    }

    /// Средняя яркость по уменьшенной до 12×15 копии: дёшево и достаточно, чтобы отличить светлое небо от ночи
    private static func averageLuminance(of image: UIImage) -> CGFloat {
        guard let cgImage = image.cgImage else { return 0.5 }
        let width = 12, height = 15
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .low
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return 0.5 }
        var total: CGFloat = 0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let r = CGFloat(pixels[index]) / 255
            let g = CGFloat(pixels[index + 1]) / 255
            let b = CGFloat(pixels[index + 2]) / 255
            total += 0.2126 * r + 0.7152 * g + 0.0722 * b
        }
        return total / CGFloat(width * height)
    }
}

// MARK: - Цвета текста поверх фотографии
enum CinematicPalette {
    /// Тёплое золото ссылки: хорошо видно и на тёмном, и на затемнённом светлом кадре
    static let gold = Color(red: 0.97, green: 0.83, blue: 0.55)
    static let text = Color.white
    static let secondary = Color.white.opacity(0.78)
    static let hairline = Color.white.opacity(0.18)
    static let textShadow = Color.black.opacity(0.45)
}

// MARK: - Затемнение под текстом
/// Тёмный градиент сверху вниз плюс виньетка. Чем светлее кадр, тем он плотнее: текст читается на любом фото.
struct CinematicScrim: View {
    /// Средняя яркость кадра 0…1 (для градиента без фото — 0)
    let luminance: CGFloat

    private var boost: Double {
        Double(max(0, min(1, luminance) - 0.30)) * 0.55
    }

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.30 + boost * 0.6), location: 0),
                    .init(color: Color.black.opacity(0.42 + boost), location: 0.45),
                    .init(color: Color.black.opacity(0.62 + boost * 0.6), location: 0.80),
                    .init(color: Color.black.opacity(0.78 + boost * 0.4), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.35)],
                center: .center,
                startRadius: 80,
                endRadius: 420
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Фон карточки цитаты
struct CinematicQuoteBackground: View {
    let choice: QuoteBackdropChoice?
    /// Медленный наезд камеры и параллакс при прокрутке. Выключаются в режиме «Уменьшение движения»
    var animated: Bool = true

    @State private var entry: QuoteBackdropCache.Entry?
    @State private var shownName: String?

    private var mood: QuoteMood { choice?.mood ?? .light }
    private var motionAllowed: Bool { animated && !PaperMotion.reduceMotion }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            // Параллакс: кадр чуть отстаёт от карточки при прокрутке (не больше 14 pt в обе стороны)
            let shift = motionAllowed ? max(-14, min(14, -proxy.frame(in: .global).minY * 0.05)) : 0

            ZStack {
                LinearGradient(colors: mood.fallbackColors, startPoint: .topLeading, endPoint: .bottomTrailing)

                if let entry, let shownName {
                    DriftingPhoto(image: entry.image, size: size, drifts: motionAllowed)
                        .offset(y: shift)
                        .id(shownName)
                        .transition(.opacity)
                }

                CinematicScrim(luminance: entry?.luminance ?? 0)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .accessibilityHidden(true)
        .onAppear {
            // Уже раскодированный кадр показываем сразу, без мигания градиента
            if entry == nil, let name = choice?.imageName, let cached = QuoteBackdropCache.shared.cached(name) {
                entry = cached
                shownName = name
            }
        }
        .task(id: choice?.imageName) {
            guard let name = choice?.imageName else {
                withAnimation(.easeInOut(duration: 0.6)) {
                    entry = nil
                    shownName = nil
                }
                return
            }
            guard name != shownName else { return }
            let loaded = await QuoteBackdropCache.shared.load(name)
            guard !Task.isCancelled, choice?.imageName == name else { return }
            // Плавное появление и мягкая смена кадров: старый растворяется, новый проступает
            withAnimation(Animation.easeInOut(duration: PaperMotion.reduceMotion ? 0.3 : 0.9)) {
                entry = loaded
                shownName = loaded == nil ? nil : name
            }
        }
    }
}

// MARK: - Кадр с медленным наездом камеры
/// Каждый новый кадр начинает свой наезд заново: 5 % → 10 % увеличения за 22 секунды туда и обратно.
/// Запас увеличения нужен ещё и параллаксу: при сдвиге на 14 pt края кадра не открываются.
private struct DriftingPhoto: View {
    let image: UIImage
    let size: CGSize
    let drifts: Bool

    @State private var drift = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .scaleEffect(drift ? 1.10 : 1.05)
            .onAppear {
                guard drifts, !drift else { return }
                withAnimation(Animation.easeInOut(duration: 22).loops()) {
                    drift = true
                }
            }
    }
}
