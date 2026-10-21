import SwiftUI
import UIKit
import WidgetKit

// MARK: - Длина цитаты по месту показа
/// Экран блокировки и малый виджет — короткие фразы, средний — фраза в две-три строки, большой — целые отрывки.
/// Длина считается в знаках на том языке, который показывает виджет: по-армянски текст короче, по-русски и по-английски длиннее.
enum QuoteTier {
    case lockScreen
    case small
    case medium
    case large

    init?(family: WidgetFamily) {
        switch family {
        case .accessoryRectangular, .accessoryInline, .accessoryCircular: self = .lockScreen
        case .systemSmall: self = .small
        case .systemMedium: self = .medium
        case .systemLarge: self = .large
        default: return nil
        }
    }

    /// Желаемая длина цитаты
    var range: ClosedRange<Int> {
        switch self {
        case .lockScreen: return 10...40
        case .small: return 14...40
        case .medium: return 56...90
        case .large: return 101...340
        }
    }

    /// Допустимая длина, если в подборке мало цитат нужной длины: крупнее буквы уже не получить, но и не помещаться она не будет
    var limit: ClosedRange<Int> {
        switch self {
        case .lockScreen: return 10...46
        case .small: return 12...55
        case .medium: return 45...110
        case .large: return 80...430
        }
    }

    /// Сколько цитат нужно иметь «в самый раз», чтобы не расширять подборку
    private static let enoughQuotes = 6

    private func distance(of length: Int) -> Int {
        if length < range.lowerBound { return range.lowerBound - length }
        if length > range.upperBound { return length - range.upperBound }
        return 0
    }

    /// Оставляет из подборки цитаты, подходящие по длине на языке показа.
    /// Если таких мало, добавляет допустимые по длине (подходящие встречаются чаще); если и их нет, берёт ближайшие.
    func pick(from pool: [BibleVerse], lang: AppLanguage) -> [BibleVerse] {
        let sized = pool.map { (verse: $0, length: QuoteLength.of($0, lang: lang)) }
        let exact = sized.filter { range.contains($0.length) }.map { $0.verse }
        if exact.count >= Self.enoughQuotes { return exact }
        let near = sized.filter { limit.contains($0.length) }.map { $0.verse }
        if !near.isEmpty { return exact + near }
        let closest = sized.sorted { distance(of: $0.length) < distance(of: $1.length) }
        return closest.prefix(Self.enoughQuotes).map { $0.verse }
    }
}

// MARK: - Длина текста на языке показа
/// Длина запоминается: в приложении для армянского текста без своей записи (старые подборки) `text(for:)` каждый раз
/// спрашивает базу, а подборка из сотен цитат просматривается несколько раз при каждой синхронизации виджетов.
enum QuoteLength {
    private static var cache: [String: Int] = [:]
    private static let lock = NSLock()

    static func of(_ verse: BibleVerse, lang: AppLanguage) -> Int {
        let edition = lang == .armenian ? isAraratEditionSelected() : false
        let key = "\(verse.id.uuidString)|\(lang.rawValue)|\(edition)"
        lock.lock()
        let known = cache[key]
        lock.unlock()
        if let known { return known }
        let length = verse.text(for: lang).count
        lock.lock()
        if cache.count > 4000 { cache.removeAll() }  // избранное создаёт стихи с новыми id при каждом запросе
        cache[key] = length
        lock.unlock()
        return length
    }
}

extension BibleVerse {
    /// Подборка цитат для места показа. Экран блокировки и малый виджет берут короткие подборки (lockCategory),
    /// средний и большой — подборки домашних виджетов (homeCategory).
    static func quotes(
        for tier: QuoteTier,
        lang: AppLanguage,
        isPremium: Bool,
        lockCategory: LockScreenCategory,
        homeCategory: HomeWidgetCategory
    ) -> [BibleVerse] {
        switch tier {
        case .lockScreen, .small:
            let category = (isPremium || !lockCategory.isPremiumRequired) ? lockCategory : .pearls
            var pool = tier.pick(from: lockScreenVerses(for: category), lang: lang)
            if pool.isEmpty { pool = tier.pick(from: shortPearls, lang: lang) }
            return pool.isEmpty ? shortPearls : pool
        case .medium, .large:
            var pool = tier.pick(from: verses(for: homeCategory, isPremium: isPremium), lang: lang)
            if pool.isEmpty { pool = tier.pick(from: database, lang: lang) }
            return pool.isEmpty ? database : pool
        }
    }
}

// MARK: - Язык, на котором виджет показывает цитаты
/// Язык виджета из общих настроек: свой, если выбран, иначе язык приложения
func sharedWidgetLanguage() -> AppLanguage {
    let defaults = AppGroupConstants.sharedDefaults

    if let widgetLangRaw = defaults.string(forKey: "widget_language"),
       let widgetLang = WidgetLanguage(rawValue: widgetLangRaw) {
        switch widgetLang {
        case .followApp:
            break
        case .armenian:
            return .armenian
        case .russian:
            return .russian
        case .english:
            return .english
        }
    }

    if let savedRaw = defaults.string(forKey: "app_language"),
       let lang = AppLanguage(rawValue: savedRaw) {
        return lang
    }

    // Если настройки не найдены (или нет доступа к App Group), по умолчанию для ArmenianBible используем армянский язык
    return .armenian
}

// MARK: - Шрифт цитат
/// Системный serif (New York) для латиницы, кириллицы и цифр и Noto Serif Armenian для армянских букв.
/// Без второго армянский текст в виджете шёл системным рубленым шрифтом, а подпись рядом — с засечками, и виджет выглядел разнородно.
/// Если шрифта нет в пакете, остаётся системная подмена.
enum QuoteFont {
    static func serif(size: CGFloat, weight: Font.Weight) -> Font {
        let ui = uiWeight(weight)
        let system = UIFont.systemFont(ofSize: size, weight: ui)
        let serif = system.fontDescriptor.withDesign(.serif) ?? system.fontDescriptor
        let armenian = UIFontDescriptor(name: armenianName(for: ui), size: size)
        let descriptor = serif.addingAttributes([.cascadeList: [armenian]])
        return Font(UIFont(descriptor: descriptor, size: size) as CTFont)
    }

    private static func uiWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }

    private static func armenianName(for weight: UIFont.Weight) -> String {
        if weight.rawValue >= UIFont.Weight.semibold.rawValue { return "NotoSerifArmenian-SemiBold" }
        if weight.rawValue >= UIFont.Weight.medium.rawValue { return "NotoSerifArmenian-Medium" }
        return "NotoSerifArmenian-Regular"
    }
}

// MARK: - Текст, который занимает всё отведённое место
/// Берёт самый крупный размер, при котором цитата помещается целиком: короткая фраза выходит огромной, длинная — помельче.
/// Место задаёт вызывающий (frame с maxHeight: .infinity), поэтому на любом телефоне буквы максимально крупные.
struct FittedQuoteText: View {
    let text: String
    /// Размер для самой короткой фразы
    let maxSize: CGFloat
    /// Во сколько раз можно уменьшить размер для самой длинной фразы (maxSize * minScale — нижний предел)
    var minScale: CGFloat = 0.5
    var weight: Font.Weight = .bold
    var design: Font.Design = .default
    var lineSpacing: CGFloat = 2

    /// Девять равных ступеней от крупного к мелкому
    private func scale(_ step: Int) -> CGFloat {
        1 - (1 - minScale) * CGFloat(step) / 8
    }

    private func label(_ step: Int) -> some View {
        let k = scale(step)
        let size = (maxSize * k).rounded()
        let font: Font = design == .serif ? QuoteFont.serif(size: size, weight: weight) : .system(size: size, weight: weight, design: design)
        return Text(text)
            .font(font)
            .lineSpacing(lineSpacing * k)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            label(0)
            label(1)
            label(2)
            label(3)
            label(4)
            label(5)
            label(6)
            label(7)
            label(8).minimumScaleFactor(0.85)
        }
    }
}
