import ActivityKit
import Foundation

// MARK: - Свеча в Dynamic Island и на экране блокировки (Live Activity)
/// Подключается и к приложению, и к расширению виджетов. Всё, что зависит от языка,
/// приложение подставляет при запуске активности: расширение ничего не переводит.
@available(iOS 16.2, *)
struct CandleActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isLit: Bool
    }

    var candleId: String
    var personName: String
    var tierRaw: String
    var intentionIcon: String
    var intentionTitle: String
    /// Подпись перед оставшимся временем («Осталось»)
    var remainingLabel: String
    /// Язык приложения: по нему система форматирует «4 дня, 4 часа»
    var localeIdentifier: String
    var litDate: Date
    var expirationDate: Date

    var tier: CandleTier { CandleTier(rawValue: tierRaw) ?? .rewarded }

    /// Стабильная для свечи «поза» пламени: hashValue у строки меняется от запуска к запуску
    var flameSeed: Double {
        Double(candleId.utf8.reduce(0) { ($0 &* 31 &+ Int($1)) % 9973 })
    }

    /// Доля сгоревшей свечи на указанный момент (0 — только зажжена, 1 — догорела)
    func burn(at date: Date = Date()) -> Double {
        let total = expirationDate.timeIntervalSince(litDate)
        guard total > 0 else { return 1 }
        return min(1, max(0, date.timeIntervalSince(litDate) / total))
    }
}
