import ActivityKit
import Foundation

// MARK: - Менеджер «свечи в острове» (Live Activity)
/// В острове и на экране блокировки одновременно живёт одна свеча. Система сама завершает
/// Live Activity через 8 часов, а свеча горит до недели, поэтому при возврате в приложение
/// активность поднимается заново, если пользователь её не убирал.
@MainActor
final class CandleIslandManager: ObservableObject {
    static let shared = CandleIslandManager()

    /// Свеча, которая сейчас показана в острове
    @Published private(set) var shownCandleId: String?

    private let kWantedKey = "luys_candle_island_wanted_id_v1"
    private let kStartedKey = "luys_candle_island_started_at_v1"
    /// Система сама заканчивает активность через 8 часов; с запасом считаем её «закончившейся по лимиту»
    private let systemLimit: TimeInterval = 7.5 * 3600

    private init() {
        if #available(iOS 16.2, *) {
            shownCandleId = currentActivityCandleId()
        }
    }

    /// Можно ли вообще показывать свечу в острове (iOS 16.2+ и Live Activities не выключены в настройках)
    var isAvailable: Bool {
        guard #available(iOS 16.2, *) else { return false }
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func isShowing(_ candle: PrayerCandle) -> Bool {
        shownCandleId == candle.id.uuidString
    }

    // MARK: Показать / убрать
    func show(_ candle: PrayerCandle, language: AppLanguage) {
        guard #available(iOS 16.2, *), candle.isLit, isAvailable else { return }
        UserDefaults.standard.set(candle.id.uuidString, forKey: kWantedKey)
        Task { await start(candle, language: language) }
    }

    func hide() {
        UserDefaults.standard.removeObject(forKey: kWantedKey)
        UserDefaults.standard.removeObject(forKey: kStartedKey)
        guard #available(iOS 16.2, *) else { return }
        shownCandleId = nil
        Task { await endAll() }
    }

    // MARK: Согласование с актуальным списком свечей
    /// Вызывается при возврате в приложение и после очистки догоревших свечей
    func sync(with candles: [PrayerCandle], language: AppLanguage) {
        guard #available(iOS 16.2, *) else { return }
        shownCandleId = currentActivityCandleId()

        // Свеча в острове догорела или была удалена
        if let shown = shownCandleId, !candles.contains(where: { $0.id.uuidString == shown && $0.isLit }) {
            hide()
            return
        }

        guard shownCandleId == nil,
              let wanted = UserDefaults.standard.string(forKey: kWantedKey),
              let candle = candles.first(where: { $0.id.uuidString == wanted && $0.isLit }) else {
            if shownCandleId == nil { UserDefaults.standard.removeObject(forKey: kWantedKey) }
            return
        }

        // Активности нет, а свеча ещё горит: либо лимит системы, либо пользователь смахнул её сам
        let startedAt = UserDefaults.standard.object(forKey: kStartedKey) as? Date ?? .distantFuture
        if Date().timeIntervalSince(startedAt) >= systemLimit {
            show(candle, language: language)
        } else {
            UserDefaults.standard.removeObject(forKey: kWantedKey)
        }
    }

    // MARK: ActivityKit
    @available(iOS 16.2, *)
    private func currentActivityCandleId() -> String? {
        Activity<CandleActivityAttributes>.activities.first?.attributes.candleId
    }

    @available(iOS 16.2, *)
    private func endAll() async {
        for activity in Activity<CandleActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    @available(iOS 16.2, *)
    private func start(_ candle: PrayerCandle, language: AppLanguage) async {
        await endAll()

        let attributes = CandleActivityAttributes(
            candleId: candle.id.uuidString,
            personName: candle.personName,
            tierRaw: candle.tier.rawValue,
            intentionIcon: candle.intention.icon,
            intentionTitle: candle.intention.title(for: language),
            remainingLabel: Self.remainingLabel(for: language),
            litDate: candle.litDate,
            expirationDate: candle.expirationDate
        )
        let content = ActivityContent(
            state: CandleActivityAttributes.ContentState(isLit: true),
            staleDate: candle.expirationDate
        )
        do {
            _ = try Activity<CandleActivityAttributes>.request(attributes: attributes, content: content, pushType: nil)
            shownCandleId = candle.id.uuidString
            UserDefaults.standard.set(Date(), forKey: kStartedKey)
        } catch {
            shownCandleId = nil
            UserDefaults.standard.removeObject(forKey: kWantedKey)
        }
    }

    private static func remainingLabel(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return "Մնացել է"
        case .russian: return "Осталось"
        case .english: return "Left"
        }
    }
}
