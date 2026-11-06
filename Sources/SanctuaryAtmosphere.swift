import SwiftUI
import UIKit

// MARK: - Атмосфера главного экрана: «святилище при свечах»
// Тёмная тема: глубокая тёплая темнота (#120F0C), над ней едва заметный янтарный свет сверху,
// мягкие пятна света и тонкое зерно, как у плёнки. Светлая тема: та же композиция на бумаге,
// свет теплее и слабее. Фон статичен: ни анимаций, ни размытия, поэтому прокрутка его не перерисовывает.
//
// Второстепенные карточки главного экрана (все они оформлены через `.paperSheet`) получают
// «тёплую поверхность» через окружение `paperSurface`: её включает только главный экран,
// остальные экраны приложения остаются как были.

// MARK: - Палитра
enum SanctuaryPalette {
    /// Основной фон: тёплая темнота / бумага
    static let uiBase = dynamic(light: 0xF4EEE3, dark: 0x120F0C)
    /// Поверхность карточек
    static let uiSurface = dynamic(light: 0xFCF9F3, dark: 0x211C16)
    /// Верх поверхности карточки: на тон светлее, будто на неё падает свет сверху
    static let uiSurfaceLit = dynamic(light: 0xFEFBF6, dark: 0x262019)
    /// Тонкие рамки
    static let uiBorder = dynamic(light: 0x2B241D, lightAlpha: 0.10, dark: 0x393025)
    /// Тёплое золото: свет сверху, выбранная вкладка
    static let uiGold = dynamic(light: 0xB8893F, dark: 0xC6A66B)

    static let base = Color(uiColor: uiBase)
    static let surface = Color(uiColor: uiSurface)
    static let surfaceLit = Color(uiColor: uiSurfaceLit)
    static let border = Color(uiColor: uiBorder)
    static let gold = Color(uiColor: uiGold)

    private static func dynamic(light: UInt32, lightAlpha: CGFloat = 1, dark: UInt32, darkAlpha: CGFloat = 1) -> UIColor {
        UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let rgb = isDark ? dark : light
            return UIColor(
                red: CGFloat((rgb >> 16) & 0xFF) / 255,
                green: CGFloat((rgb >> 8) & 0xFF) / 255,
                blue: CGFloat(rgb & 0xFF) / 255,
                alpha: isDark ? darkAlpha : lightAlpha
            )
        }
    }
}

// MARK: - Фон главного экрана
struct SanctuaryBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let dark = colorScheme == .dark
        let toneColors: [Color] = dark
            ? [Color(red: 0.10, green: 0.08, blue: 0.06), Color.clear, Color.black.opacity(0.28)]
            : [Color(red: 0.97, green: 0.92, blue: 0.83).opacity(0.7), Color.clear, Color(red: 0.55, green: 0.42, blue: 0.26).opacity(0.06)]
        GeometryReader { proxy in
            let size = proxy.size
            let span = max(size.width, size.height)

            ZStack {
                SanctuaryPalette.base

                // Мягкий переход тонов сверху вниз: верх чуть теплее, низ уходит в глубину
                LinearGradient(colors: toneColors, startPoint: .top, endPoint: .bottom)

                // Янтарный свет сверху, как от свечи над страницей
                RadialGradient(
                    colors: [SanctuaryPalette.gold.opacity(dark ? 0.16 : 0.22), SanctuaryPalette.gold.opacity(0)],
                    center: UnitPoint(x: 0.5, y: -0.06),
                    startRadius: 0,
                    endRadius: span * 0.62
                )

                // Едва заметные пятна света: неровное, «живое» освещение без явных форм
                RadialGradient(
                    colors: [Color(red: 0.80, green: 0.55, blue: 0.28).opacity(dark ? 0.06 : 0.07), Color.clear],
                    center: UnitPoint(x: 0.08, y: 0.38),
                    startRadius: 0,
                    endRadius: span * 0.42
                )
                RadialGradient(
                    colors: [Color(red: 0.72, green: 0.50, blue: 0.30).opacity(dark ? 0.045 : 0.05), Color.clear],
                    center: UnitPoint(x: 0.95, y: 0.70),
                    startRadius: 0,
                    endRadius: span * 0.45
                )

                // Виньетка: края темнее, взгляд остаётся в центре
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(dark ? 0.38 : 0.07)],
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: span * 0.30,
                    endRadius: span * 0.85
                )

                // Тонкое зерно: одна маленькая плитка, размноженная по экрану
                Image(uiImage: SanctuaryGrain.tile)
                    .resizable(resizingMode: .tile)
                    .opacity(dark ? 0.55 : 0.40)
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Зерно
/// Плитка шума 128×128 px (64×64 pt): создаётся один раз при первом показе, в бандл ничего не добавляет.
/// Точки светлые и тёмные с прозрачностью 2–5 %, поэтому зерно видно только вблизи и не спорит с текстом.
enum SanctuaryGrain {
    static let tile: UIImage = makeTile()

    private static func makeTile() -> UIImage {
        let side = 128
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        // Детерминированный генератор: зерно одинаковое при каждом запуске
        var state: UInt64 = 0x4C75_7973_5361_6E63
        func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let random = next()
            let light = random & 1 == 0
            // Прозрачность 5…13 из 255 (2–5 %), цвет уже умножен на неё (premultiplied)
            let alpha = UInt8(5 + (random >> 8) % 9)
            let value: UInt8 = light ? alpha : 0
            pixels[index] = value
            pixels[index + 1] = value
            pixels[index + 2] = value
            pixels[index + 3] = alpha
        }
        let image: CGImage? = pixels.withUnsafeMutableBytes { buffer in
            CGContext(
                data: buffer.baseAddress,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )?.makeImage()
        }
        guard let image else { return UIImage() }
        return UIImage(cgImage: image, scale: 2, orientation: .up)
    }
}

// MARK: - Поверхность карточек
/// Как выглядит `.paperSheet`: обычный лист бумаги или тёплая поверхность главного экрана
enum PaperSurfaceStyle {
    case paper
    case sanctuary
}

private struct PaperSurfaceStyleKey: EnvironmentKey {
    static let defaultValue: PaperSurfaceStyle = .paper
}

extension EnvironmentValues {
    var paperSurface: PaperSurfaceStyle {
        get { self[PaperSurfaceStyleKey.self] }
        set { self[PaperSurfaceStyleKey.self] = newValue }
    }
}

/// Тёплая поверхность карточки: свет падает сверху, рамка тонкая, тень сдержанная
struct SanctuarySurface: View {
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(
                LinearGradient(
                    colors: [SanctuaryPalette.surfaceLit, SanctuaryPalette.surface],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.32) : Color(red: 0.29, green: 0.21, blue: 0.09).opacity(0.07),
                radius: 12, x: 0, y: 6
            )
    }
}

/// Рамка тёплой поверхности: ровная линия и чуть более светлый верхний край
struct SanctuarySurfaceBorder: View {
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            shape.strokeBorder(SanctuaryPalette.border, lineWidth: 1)
            shape.strokeBorder(
                LinearGradient(
                    colors: [SanctuaryPalette.gold.opacity(0.16), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                ),
                lineWidth: 1
            )
        }
        .allowsHitTesting(false)
    }
}
