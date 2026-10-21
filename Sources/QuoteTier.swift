import SwiftUI
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
        case .large: return 101...300
        }
    }

    /// Допустимая длина, если в подборке мало цитат нужной длины: крупнее буквы уже не получить, но и не помещаться она не будет
    var limit: ClosedRange<Int> {
        switch self {
        case .lockScreen: return 10...46
        case .small: return 12...55
        case .medium: return 45...110
        case .large: return 80...340
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
        let exact = pool.filter { range.contains($0.text(for: lang).count) }
        if exact.count >= Self.enoughQuotes { return exact }
        let near = pool.filter { limit.contains($0.text(for: lang).count) }
        if !near.isEmpty { return exact + near }
        let closest = pool.sorted { distance(of: $0.text(for: lang).count) < distance(of: $1.text(for: lang).count) }
        return Array(closest.prefix(Self.enoughQuotes))
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

// MARK: - Текст, который занимает всё отведённое место
/// Берёт самый крупный размер, при котором цитата помещается целиком: короткая фраза выходит огромной, длинная — помельче.
/// Место задаёт вызывающий (frame с maxHeight: .infinity), поэтому на любом телефоне буквы максимально крупные.
struct FittedQuoteText: View {
    let text: String
    let maxSize: CGFloat
    var weight: Font.Weight = .bold
    var design: Font.Design = .default
    var lineSpacing: CGFloat = 2

    private func label(_ scale: CGFloat) -> some View {
        Text(text)
            .font(.system(size: (maxSize * scale).rounded(), weight: weight, design: design))
            .lineSpacing(lineSpacing * scale)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            label(1.0)
            label(0.94)
            label(0.88)
            label(0.82)
            label(0.76)
            label(0.70)
            label(0.64)
            label(0.58)
            label(0.52).minimumScaleFactor(0.8)
        }
    }
}
