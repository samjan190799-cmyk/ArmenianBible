import SwiftUI
import UIKit

// MARK: - Фотографии для обоев экрана блокировки
// У каждой темы три вертикальных кадра 1290×2796 (Assets.xcassets: WallpaperArarat1…WallpaperRoyal3),
// снятых на месте: Арарат, монастыри, хачкары, рукописи, звёздное небо, закаты, горы.
// Фото лежат в приложении и работают без интернета, поэтому автоматизации Команд не зависят от сети.
// Авторы перечислены в PHOTO_CREDITS.md.

extension WallpaperTheme {
    /// Сколько кадров у каждой темы
    static let photoCount = 3

    /// Имя кадра в Assets.xcassets (index по модулю числа кадров)
    func photoName(at index: Int) -> String {
        let base = "Wallpaper" + rawValue.prefix(1).uppercased() + String(rawValue.dropFirst())
        let count = Self.photoCount
        return base + String(((index % count) + count) % count + 1)
    }

    /// Кадр для стиха, когда его не выбрали вручную (Команды, автоматизация):
    /// один стих всегда получает один и тот же кадр, разные стихи — разные
    func photoIndex(for verse: BibleVerse) -> Int {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in (verse.refEn + "|" + rawValue).utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return Int(hash % UInt64(Self.photoCount))
    }

    /// Цвет украшения и ссылки поверх фотографии: светлый, чтобы читался на затемнённом кадре
    var photoAccentColor: Color {
        switch self {
        case .tatev: return Color(hex: "7DD3FC")
        case .bethlehem: return Color(hex: "C7D2FE")
        case .graphite: return Color(hex: "E2E8F0")
        case .royal: return Color(hex: "E9D5FF")
        case .ararat, .khachkar, .parchment, .sunset: return Color(hex: "E8C67E")
        }
    }
}

// MARK: - Загрузка и кэш кадров
/// Полный кадр нужен только при сохранении обоев. Для превью и кружков выбора темы
/// берутся уменьшенные копии: десяток полных кадров занял бы в памяти больше 100 МБ.
enum WallpaperPhotoStore {
    enum Size {
        /// Кружок выбора темы (44 pt)
        case chip
        /// Превью телефона в конструкторе (220×440 pt)
        case preview
        /// Сохранение обоев 1170×2532
        case full

        fileprivate var pixelSize: CGSize? {
            switch self {
            case .chip: return CGSize(width: 150, height: 150)
            case .preview: return CGSize(width: 700, height: 1517)
            case .full: return nil
            }
        }
    }

    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 48 * 1024 * 1024
        return cache
    }()

    /// Кадр нужного размера или nil, если такого ассета нет (тогда рисуется прежний фон темы)
    static func image(_ name: String, size: Size) -> UIImage? {
        guard let pixelSize = size.pixelSize else {
            return UIImage(named: name)
        }
        let key = "\(name)@\(Int(pixelSize.width))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let original = UIImage(named: name) else { return nil }
        // Пропорции кадра сохраняются: уменьшаем по большей стороне
        let scale = max(pixelSize.width / original.size.width, pixelSize.height / original.size.height)
        let target = CGSize(width: (original.size.width * scale).rounded(), height: (original.size.height * scale).rounded())
        let thumbnail = original.preparingThumbnail(of: target) ?? original
        cache.setObject(thumbnail, forKey: key, cost: Int(target.width * target.height * 4))
        return thumbnail
    }
}

// MARK: - Кадр-фотография на всю площадь обоев
struct WallpaperPhotoLayer: View {
    let image: UIImage

    var body: some View {
        GeometryReader { proxy in
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
    }
}

// MARK: - Затемнение кадра под часы и стих
/// Сверху лёгкое затемнение под часы, к середине (где стих) плотнее, снизу снова мягче.
/// Поверх ещё лежит радиальная подложка холста (тёмный центр) и тень текста,
/// поэтому здесь затемнение умеренное: стих читается, а кадр не уходит в черноту.
struct WallpaperPhotoScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.black.opacity(0.34), location: 0),
                .init(color: Color.black.opacity(0.12), location: 0.22),
                .init(color: Color.black.opacity(0.26), location: 0.42),
                .init(color: Color.black.opacity(0.34), location: 0.62),
                .init(color: Color.black.opacity(0.28), location: 0.86),
                .init(color: Color.black.opacity(0.50), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
