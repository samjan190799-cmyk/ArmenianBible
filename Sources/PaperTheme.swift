import SwiftUI
import UIKit

// MARK: - Дизайн-система «Бумага и чернила»
// Светлая тема: тёплая бумага и чернила, как страница рукописи.
// Тёмная тема: «ночное чтение» в тех же тёплых тонах.
// Контраст основных пар проверен по WCAG: ink ≥ 13:1, inkSecondary ≥ 5:1, cinnabar ≥ 5.7:1.
enum Paper {
    // MARK: UIKit-цвета (для NSAttributedString и UIKit-компонентов)
    static let uiPage = dynamic(light: 0xF4EEE3, dark: 0x17130F)
    static let uiSheet = dynamic(light: 0xFCF9F3, dark: 0x211C17)
    static let uiInk = dynamic(light: 0x2B241D, dark: 0xECE3D2)
    static let uiInkSecondary = dynamic(light: 0x6E6152, dark: 0xA99C89)
    static let uiInkTertiary = dynamic(light: 0x9C8E7C, dark: 0x776C5E)
    static let uiCinnabar = dynamic(light: 0x9E3226, dark: 0xDB7B6D)
    static let uiGold = dynamic(light: 0x8F6B2A, dark: 0xCFAE6E)
    static let uiHairline = dynamic(light: 0x2B241D, lightAlpha: 0.10, dark: 0xECE3D2, darkAlpha: 0.09)
    static let uiShadow = dynamic(light: 0x4A3517, lightAlpha: 0.08, dark: 0x000000, darkAlpha: 0.35)

    // MARK: SwiftUI-цвета
    /// Фон страницы
    static let page = Color(uiColor: uiPage)
    /// Лист бумаги (карточки) — чуть светлее страницы
    static let sheet = Color(uiColor: uiSheet)
    /// Основной текст — чернила
    static let ink = Color(uiColor: uiInk)
    /// Вторичный текст — выцветшие чернила
    static let inkSecondary = Color(uiColor: uiInkSecondary)
    /// Декоративные элементы: шевроны, неактивные иконки
    static let inkTertiary = Color(uiColor: uiInkTertiary)
    /// Киноварь — красные чернила рубрик армянских рукописей
    static let cinnabar = Color(uiColor: uiCinnabar)
    /// Золото орнаментов
    static let gold = Color(uiColor: uiGold)
    /// Тонкие линии и рамки
    static let hairline = Color(uiColor: uiHairline)
    /// Мягкая тень листа
    static let shadow = Color(uiColor: uiShadow)

    private static func dynamic(light: UInt32, lightAlpha: CGFloat = 1, dark: UInt32, darkAlpha: CGFloat = 1) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(rgb: dark, alpha: darkAlpha)
                : UIColor(rgb: light, alpha: lightAlpha)
        }
    }
}

private extension UIColor {
    convenience init(rgb: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Акцент темы с учётом «Бумаги»
extension AccentColorTheme {
    /// Акцентный цвет. Для киновари — адаптивный к светлой/тёмной теме.
    var color: Color {
        self == .cinnabar ? Paper.cinnabar : Color(hex: colorHex)
    }

    var uiColor: UIColor {
        self == .cinnabar ? Paper.uiCinnabar : UIColor(Color(hex: colorHex))
    }
}

// MARK: - Книжный шрифт
// New York (системный serif) для латиницы, кириллицы и цифр
// + Noto Serif Armenian для армянских букв через cascade list.
enum PaperFont {
    static func uiFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let system = UIFont.systemFont(ofSize: size, weight: weight)
        let serif = system.fontDescriptor.withDesign(.serif) ?? system.fontDescriptor
        let armenian = UIFontDescriptor(name: armenianFontName(for: weight), size: size)
        let descriptor = serif.addingAttributes([.cascadeList: [armenian]])
        return UIFont(descriptor: descriptor, size: size)
    }

    static func font(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        Font(uiFont(size: size, weight: weight) as CTFont)
    }

    private static func armenianFontName(for weight: UIFont.Weight) -> String {
        if weight.rawValue >= UIFont.Weight.semibold.rawValue {
            return "NotoSerifArmenian-SemiBold"
        } else if weight.rawValue >= UIFont.Weight.medium.rawValue {
            return "NotoSerifArmenian-Medium"
        }
        return "NotoSerifArmenian-Regular"
    }
}

// MARK: - Лист бумаги (фон карточки)
struct PaperSheetModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Paper.sheet)
                    .shadow(color: Paper.shadow, radius: 14, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Paper.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func paperSheet(cornerRadius: CGFloat = 18) -> some View {
        modifier(PaperSheetModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Фон страницы с лёгкой виньеткой по краям
struct PaperBackground: View {
    var body: some View {
        ZStack {
            Paper.page
            RadialGradient(
                colors: [Color.clear, Paper.shadow],
                center: .center,
                startRadius: 180,
                endRadius: 720
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Орнамент: линия — крест — линия (золото)
struct PaperOrnament: View {
    var width: CGFloat = 36

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Paper.gold.opacity(0.45))
                .frame(width: width, height: 0.8)
            Image(systemName: "cross")
                .font(.system(size: 10, weight: .light))
                .foregroundColor(Paper.gold)
            Rectangle()
                .fill(Paper.gold.opacity(0.45))
                .frame(width: width, height: 0.8)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Строка списка внутри листа: мягкая подсветка при нажатии
struct PaperRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Paper.hairline : Color.clear)
    }
}

// MARK: - Иконка раздела в кружке (единый стиль для карточек главного экрана)
struct PaperIconBadge<Icon: View>: View {
    var tint: Color = Paper.gold
    @ViewBuilder var icon: () -> Icon

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.10))
            Circle()
                .strokeBorder(tint.opacity(0.25), lineWidth: 0.8)
            icon()
        }
        .frame(width: 46, height: 46)
    }
}
