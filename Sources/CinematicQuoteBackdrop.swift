import SwiftUI
import UIKit

// MARK: - Кинематографический фон карточки цитаты
// Фотографии лежат в Assets.xcassets (QuoteLight1…QuotePeace7): они уже уменьшены до 1080×1350 и сжаты,
// поэтому работают без интернета и не тянут тяжёлых оригиналов. Список авторов: PHOTO_CREDITS.md.
//
// Как устроено (пункты 1–3 лежат в QuoteMood.swift: он общий с виджетами):
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
    /// Старое золото ссылки (#D6BD87): светлее золота интерфейса, чтобы читаться на затемнённом кадре,
    /// но без яркой желтизны
    static let gold = Color(red: 0.84, green: 0.74, blue: 0.53)
    /// Тёплый светлый текст (#F5EDDE) вместо чистого белого
    static let text = Color(red: 0.96, green: 0.93, blue: 0.87)
    static let secondary = text.opacity(0.78)
    static let hairline = text.opacity(0.18)
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
