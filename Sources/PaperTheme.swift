import SwiftUI
import UIKit

// MARK: - Дизайн-система «Бумага и чернила»
// Светлая тема: тёплая бумага и чернила, как страница рукописи.
// Тёмная тема — основная, «Sacred Dark»: тёмный камень (#17120E), карточки (#292019),
// старое золото (#B69A68), терракота (#A66D61), тёплый светлый текст. Чистого белого,
// яркого жёлтого и насыщенных цветов в ней нет.
// Контраст тёмной темы по WCAG (на фоне / на карточке): ink 14.6 / 12.5, inkSecondary 7.8 / 6.7,
// gold 6.9 / 5.9, cinnabar (терракота для текста) 6.4 / 5.5, пигменты категорий ≥ 5.8.
enum Paper {
    // MARK: UIKit-цвета (для NSAttributedString и UIKit-компонентов)
    static let uiPage = dynamic(light: 0xF4EEE3, dark: 0x17120E)
    static let uiSheet = dynamic(light: 0xFCF9F3, dark: 0x292019)
    /// Вторичная поверхность «приподнятая»: выбранный сегмент, всплывающие подсказки.
    /// Ещё две вторичные поверхности — подложки `fillSubtle` и `fillMuted` поверх карточки.
    static let uiSheetRaised = dynamic(light: 0xFCF9F3, dark: 0x33281F)
    static let uiInk = dynamic(light: 0x2B241D, dark: 0xECE3D2)
    static let uiInkSecondary = dynamic(light: 0x6E6152, dark: 0xB5A690)
    static let uiInkTertiary = dynamic(light: 0x9C8E7C, dark: 0x8F8270)
    /// Киноварь; в тёмной теме — светлый тон терракоты: он читается мелким текстом и в значках
    static let uiCinnabar = dynamic(light: 0x9E3226, dark: 0xC4897B)
    /// Терракота для заливок (кнопки, плашки). Мелким текстом на тёмном её не пишем: контраст 3.8:1
    static let uiTerracotta = dynamic(light: 0x9E3226, dark: 0xA66D61)
    static let uiGold = dynamic(light: 0x8F6B2A, dark: 0xB69A68)
    /// Тонкие линии: в тёмной теме — старое золото низкой интенсивности
    static let uiHairline = dynamic(light: 0x2B241D, lightAlpha: 0.10, dark: 0xB69A68, darkAlpha: 0.20)
    static let uiShadow = dynamic(light: 0x4A3517, lightAlpha: 0.08, dark: 0x000000, darkAlpha: 0.35)
    static let uiMoss = dynamic(light: 0x4F6B45, dark: 0x9BAF8A)
    static let uiOnAccent = dynamic(light: 0xFCF9F3, dark: 0x17120E)
    static let uiLapis = dynamic(light: 0x3D5A8C, dark: 0x8C9DBD)
    static let uiIndigo = dynamic(light: 0x4B4F8F, dark: 0x9D9FC4)
    static let uiPlum = dynamic(light: 0x6E4B73, dark: 0xB59AB6)
    static let uiOchre = dynamic(light: 0xA4622A, dark: 0xC9996A)
    static let uiUmber = dynamic(light: 0x6B5238, dark: 0xBFA688)
    static let uiTeal = dynamic(light: 0x2F6F6B, dark: 0x8CB3AC)
    static let uiFillSubtle = dynamic(light: 0x2B241D, lightAlpha: 0.045, dark: 0xECE3D2, darkAlpha: 0.06)
    static let uiFillMuted = dynamic(light: 0x2B241D, lightAlpha: 0.08, dark: 0xECE3D2, darkAlpha: 0.11)

    // MARK: SwiftUI-цвета
    /// Фон страницы
    static let page = Color(uiColor: uiPage)
    /// Лист бумаги (карточки) — чуть светлее страницы
    static let sheet = Color(uiColor: uiSheet)
    /// Вторичная поверхность «приподнятая» (выбранное, всплывающее)
    static let sheetRaised = Color(uiColor: uiSheetRaised)
    /// Основной текст — чернила
    static let ink = Color(uiColor: uiInk)
    /// Вторичный текст — выцветшие чернила
    static let inkSecondary = Color(uiColor: uiInkSecondary)
    /// Декоративные элементы: шевроны, неактивные иконки
    static let inkTertiary = Color(uiColor: uiInkTertiary)
    /// Киноварь — красные чернила рубрик армянских рукописей
    static let cinnabar = Color(uiColor: uiCinnabar)
    /// Терракота для заливок: кнопки и плашки с текстом `onAccent`
    static let terracotta = Color(uiColor: uiTerracotta)
    /// Золото орнаментов
    static let gold = Color(uiColor: uiGold)
    /// Тонкие линии и рамки
    static let hairline = Color(uiColor: uiHairline)
    /// Мягкая тень листа
    static let shadow = Color(uiColor: uiShadow)
    /// Текст на залитой акцентной плашке (светлый на светлой теме, тёмный на ночной)
    static let onAccent = Color(uiColor: uiOnAccent)
    /// Тёплый светлый знак на цветном медальоне с постоянным цветом (обложки, значки планов и наград).
    /// Заменяет чистый белый; для заливок цветами `Paper.*`, которые меняются с темой, берётся `onAccent`.
    static let onPigment = Color(red: 0.97, green: 0.94, blue: 0.89)
    // Пигменты рукописи: приглушённые цвета для категорий (теги, праздники, ИИ)
    static let lapis = Color(uiColor: uiLapis)
    static let indigo = Color(uiColor: uiIndigo)
    static let plum = Color(uiColor: uiPlum)
    static let ochre = Color(uiColor: uiOchre)
    static let umber = Color(uiColor: uiUmber)
    static let teal = Color(uiColor: uiTeal)
    /// Мох — «успех», «прочитано», «выполнено» (вместо ярко-зелёного)
    static let moss = Color(uiColor: uiMoss)
    /// Едва заметная подложка (чипы, поля ввода, неактивные кнопки)
    static let fillSubtle = Color(uiColor: uiFillSubtle)
    /// Заметная подложка (выбранный чип, активный сегмент)
    static let fillMuted = Color(uiColor: uiFillMuted)
    /// Затемнение под модальными окнами
    static let scrim = Color.black.opacity(0.45)

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
    var color: Color { Color(uiColor: uiColor) }

    var uiColor: UIColor {
        switch self {
        case .cinnabar: return Paper.uiCinnabar
        case .indigo: return Paper.uiIndigo
        case .gold: return Paper.uiGold
        case .blue: return Paper.uiLapis
        case .green: return Paper.uiMoss
        case .purple: return Paper.uiPlum
        }
    }

    /// Цвет заливки под текст `Paper.onAccent` (кнопки, выбранные чипы).
    /// У киновари это терракота #A66D61, у остальных акцентов заливка совпадает с цветом текста.
    var fillColor: Color {
        switch self {
        case .cinnabar: return Paper.terracotta
        default: return color
        }
    }
}

extension Paper {
    /// Заливка в цвет выбранного пользователем акцента (см. `AccentColorTheme.fillColor`)
    static var accentFill: Color {
        BibleManager.shared.accentTheme.fillColor
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
    /// В светлой теме тёплую поверхность «святилища» включает главный экран (SanctuaryAtmosphere.swift)
    @Environment(\.paperSurface) private var surface
    @Environment(\.colorScheme) private var colorScheme

    /// В тёмной теме поверхность карточек одна на всё приложение
    private var resolvedSurface: PaperSurfaceStyle {
        colorScheme == .dark ? .sanctuary : surface
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        switch resolvedSurface {
        case .paper:
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
        case .sanctuary:
            content
                .background(SanctuarySurface(cornerRadius: cornerRadius))
                .overlay(SanctuarySurfaceBorder(cornerRadius: cornerRadius))
        }
    }
}

// MARK: - Поле / чип / строка: лист без тени, только тонкая линия
struct PaperFieldModifier: ViewModifier {
    var cornerRadius: CGFloat
    var stroke: Color
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Paper.sheet)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1)
            )
    }
}

extension View {
    func paperSheet(cornerRadius: CGFloat = 18) -> some View {
        modifier(PaperSheetModifier(cornerRadius: cornerRadius))
    }
    
    func paperField(cornerRadius: CGFloat = 12, stroke: Color = Paper.hairline) -> some View {
        modifier(PaperFieldModifier(cornerRadius: cornerRadius, stroke: stroke))
    }
}

// MARK: - Фон страницы
// Тёмная тема: единый фон «Sacred Dark» (SanctuaryAtmosphere.swift), один и тот же на всех экранах.
// Светлая тема: бумага с лёгкой виньеткой по краям.
struct PaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .dark {
            SanctuaryBackground()
        } else {
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

// MARK: - Глобальный внешний вид системных компонентов (навигация, вкладки, сегменты)
enum PaperAppearance {
    static func apply() {
        // Навигационная панель: книжный заголовок, чернила и тонкая линия
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        // Цвет считается под текущую тему в момент показа: приложение может быть тёмным при светлой системе
        nav.backgroundColor = UIColor { traits in
            Paper.uiPage.resolvedColor(with: traits).withAlphaComponent(0.94)
        }
        nav.shadowColor = Paper.uiHairline
        nav.titleTextAttributes = [
            .font: PaperFont.uiFont(size: 17, weight: .semibold),
            .foregroundColor: Paper.uiInk
        ]
        nav.largeTitleTextAttributes = [
            .font: PaperFont.uiFont(size: 32, weight: .semibold),
            .foregroundColor: Paper.uiInk
        ]
        let navScrollEdge = UINavigationBarAppearance()
        navScrollEdge.configureWithTransparentBackground()
        navScrollEdge.shadowColor = .clear
        navScrollEdge.titleTextAttributes = nav.titleTextAttributes
        navScrollEdge.largeTitleTextAttributes = nav.largeTitleTextAttributes
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = navScrollEdge
        
        // Панель вкладок: подписи книжным шрифтом. Неактивные вкладки — вторичный цвет текста
        // (контраст на тёмном фоне 7.8:1, прежний третичный давал 3.6:1 и читался плохо),
        // у выбранной вкладки подпись плотнее, а цвет даёт .tint у TabView (ContentView.swift).
        let tabTitleNormal: [NSAttributedString.Key: Any] = [
            .font: PaperFont.uiFont(size: 11, weight: .medium)
        ]
        let tabTitleSelected: [NSAttributedString.Key: Any] = [
            .font: PaperFont.uiFont(size: 11, weight: .semibold)
        ]
        UITabBarItem.appearance().setTitleTextAttributes(tabTitleNormal, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(tabTitleSelected, for: .selected)
        UITabBar.appearance().unselectedItemTintColor = Paper.uiInkSecondary
        if #unavailable(iOS 26.0) {
            // Плотная панель в тон фону с тонкой линией старого золота сверху. Вид один и тот же
            // и в покое, и при прокрутке (standard = scrollEdge), поэтому панель не «мигает»,
            // когда содержимое доходит до края. На iOS 26 панель — системное «жидкое стекло»,
            // его фон не трогаем: подложку под ним даёт `.sacredTabBarFade()`.
            let tab = UITabBarAppearance()
            tab.configureWithDefaultBackground()
            tab.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
            tab.backgroundColor = UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? SanctuaryPalette.uiDepth.resolvedColor(with: traits).withAlphaComponent(0.92)
                    : Paper.uiPage.resolvedColor(with: traits).withAlphaComponent(0.86)
            }
            tab.shadowColor = SanctuaryPalette.uiBorder
            for layout in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
                layout.normal.iconColor = Paper.uiInkSecondary
                var normalAttributes = tabTitleNormal
                normalAttributes[.foregroundColor] = Paper.uiInkSecondary
                layout.normal.titleTextAttributes = normalAttributes
                layout.selected.titleTextAttributes = tabTitleSelected
            }
            UITabBar.appearance().standardAppearance = tab
            UITabBar.appearance().scrollEdgeAppearance = tab
        }
        
        // Сегментированные переключатели: приподнятый лист на тёплой подложке
        let segmented = UISegmentedControl.appearance()
        segmented.backgroundColor = Paper.uiFillMuted
        segmented.selectedSegmentTintColor = Paper.uiSheetRaised
        segmented.setTitleTextAttributes([
            .font: PaperFont.uiFont(size: 14, weight: .medium),
            .foregroundColor: Paper.uiInkSecondary
        ], for: .normal)
        segmented.setTitleTextAttributes([
            .font: PaperFont.uiFont(size: 14, weight: .semibold),
            .foregroundColor: Paper.uiInk
        ], for: .selected)
    }
}

// MARK: - Цвета категорий в палитре рукописи
extension VerseTag {
    var color: Color {
        switch self {
        case .faith: return Paper.lapis
        case .hope: return Paper.moss
        case .love: return Paper.cinnabar
        case .grief: return Paper.plum
        case .gratitude: return Paper.gold
        case .wisdom: return Paper.teal
        case .prayer: return Paper.umber
        }
    }
}

extension VerseTag {
    /// Символ SF вместо эмодзи: тонкая линия в тон рукописи
    var symbol: String {
        switch self {
        case .faith: return "cross"
        case .hope: return "sunrise"
        case .love: return "heart"
        case .grief: return "flame"
        case .gratitude: return "sparkles"
        case .wisdom: return "text.book.closed"
        case .prayer: return "hands.sparkles"
        }
    }
}

extension FeastType {
    var color: Color {
        switch self {
        case .daghavar: return Paper.gold
        case .dominical: return Paper.lapis
        case .fasting: return Paper.plum
        case .saints: return Paper.moss
        }
    }
}

extension AIProvider {
    var color: Color {
        switch self {
        case .gemini: return Paper.lapis
        case .chatgpt: return Paper.teal
        case .claude: return Paper.ochre
        }
    }
}

extension AITheologicalTone {
    var color: Color {
        switch self {
        case .patristic: return Paper.gold
        case .pastoral: return Paper.cinnabar
        case .historical: return Paper.lapis
        case .simple: return Paper.moss
        }
    }
}
