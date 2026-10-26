import Foundation
import SwiftUI
import WidgetKit

// MARK: - Центральный менеджер виртуальных свечей (CandleManager)
/// Управляет зажженными свечами: бесплатная ежедневная свеча и молитвенные свечи Premium.
@MainActor
final class CandleManager: ObservableObject {
    static let shared = CandleManager()
    
    @Published private(set) var activeCandles: [PrayerCandle] = []
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var hasUsedDailyFreeCandle: Bool = false
    @Published private(set) var selectedWidgetCandleId: String? = nil
    @Published var errorMessage: String? = nil
    
    private let kCandlesStorageKey = CandleConstants.candlesStorageKey
    private let kLastFreeCandleDateKey = "luys_last_free_candle_date"
    
    private init() {
        self.selectedWidgetCandleId = AppGroupConstants.sharedString(forKey: CandleConstants.selectedWidgetCandleKey)
        loadSavedCandles()
        checkDailyFreeStatus()
    }
    
    #if DEBUG || targetEnvironment(simulator)
    /// Для скриншотов в CI (-candle_seed YES): четыре свечи на разных стадиях горения, без сохранения на диск
    func seedDemoCandlesIfRequested() {
        guard UserDefaults.standard.bool(forKey: "candle_seed") else { return }
        let demo: [(CandleTier, CandleIntention, String, Double)] = [
            (.freeDaily, .health, "Анна", 0.05),
            (.rewarded, .peace, "Армен", 0.40),
            (.temple, .memory, "Мария", 0.72),
            (.generous, .gratitude, "Давид", 0.90)
        ]
        activeCandles = demo.map { tier, intention, name, progress in
            PrayerCandle(
                personName: name,
                intention: intention,
                tier: tier,
                litDate: Date().addingTimeInterval(-Double(tier.burnHours) * 3600 * progress)
            )
        }
    }
    #endif

    /// Новая свеча сразу загорается в Dynamic Island и на экране блокировки
    private func showInIsland(_ candle: PrayerCandle) {
        guard !defersIslandStart else { return }
        CandleIslandManager.shared.show(candle, language: BibleManager.shared.appLanguage)
    }

    /// Форма свечи сама запускает остров, когда свеча долетит до него: анимация «свеча взлетает в остров»
    var defersIslandStart = false

    // MARK: - Проверка доступности бесплатной свечи дня
    func checkDailyFreeStatus() {
        guard let lastDate = UserDefaults.standard.object(forKey: kLastFreeCandleDateKey) as? Date else {
            self.hasUsedDailyFreeCandle = false
            return
        }
        self.hasUsedDailyFreeCandle = Calendar.current.isDateInToday(lastDate)
    }
    
    // MARK: - Зажжение бесплатной ежедневной свечи
    func lightFreeDailyCandle(name: String, intention: CandleIntention, customPrayer: String?) -> Bool {
        checkDailyFreeStatus()
        guard !hasUsedDailyFreeCandle else { return false }
        
        let candle = PrayerCandle(
            personName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            intention: intention,
            customPrayer: customPrayer,
            tier: .freeDaily,
            litDate: Date()
        )
        
        activeCandles.insert(candle, at: 0)
        saveCandles()
        showInIsland(candle)

        UserDefaults.standard.set(Date(), forKey: kLastFreeCandleDateKey)
        hasUsedDailyFreeCandle = true
        
        // Омовение Гранатового Древа Веры утренней росой за молитву
        PomegranateTreeManager.shared.record(.candle)
        
        Haptics.notify(.success)
        Funnel.track("feature_used", ["feature": "candle"])
        return true
    }
    
    // MARK: - Зажжение свечи (бесплатная ежедневная или Premium)
    func purchaseAndLightCandle(
        tier: CandleTier,
        name: String,
        intention: CandleIntention,
        customPrayer: String?
    ) async -> Bool {
        if tier.isFree {
            return lightFreeDailyCandle(name: name, intention: intention, customPrayer: customPrayer)
        }

        // Все остальные свечи только с Premium
        return lightPremiumCandle(name: name, intention: intention, customPrayer: customPrayer)
    }

    // MARK: - Молитвенная свеча на 24 часа (Premium)
    func lightPremiumCandle(
        name: String,
        intention: CandleIntention,
        customPrayer: String?
    ) -> Bool {
        guard SubscriptionManager.shared.isPremium else {
            errorMessage = BibleManager.shared.appLanguage.pick(
                hy: "Այս մոմը հասանելի է Premium-ով",
                ru: "Эта свеча доступна с Premium",
                en: "This candle is available with Premium"
            )
            return false
        }

        errorMessage = nil
        let candle = PrayerCandle(
            personName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            intention: intention,
            customPrayer: customPrayer,
            tier: .rewarded,
            litDate: Date()
        )
        activeCandles.insert(candle, at: 0)
        saveCandles()
        showInIsland(candle)
        PomegranateTreeManager.shared.record(.candle)
        Haptics.notify(.success)
        Funnel.track("feature_used", ["feature": "candle"])
        return true
    }

    // MARK: - Выбор свечи для отображения в виджете
    func setSelectedWidgetCandle(id: String?) {
        let cleanedId = (id == nil || id == "latest" || id?.isEmpty == true) ? nil : id
        self.selectedWidgetCandleId = cleanedId
        
        if let cid = cleanedId {
            UserDefaults.standard.set(cid, forKey: CandleConstants.selectedWidgetCandleKey)
            AppGroupConstants.syncToAll { defaults in
                defaults.set(cid, forKey: CandleConstants.selectedWidgetCandleKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: CandleConstants.selectedWidgetCandleKey)
            AppGroupConstants.syncToAll { defaults in
                defaults.removeObject(forKey: CandleConstants.selectedWidgetCandleKey)
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
        Haptics.notify(.success)
    }
    
    // MARK: - Автоматическая очистка угасших свечей
    func cleanExpiredCandles() {
        let initialCount = activeCandles.count
        activeCandles.removeAll { !$0.isLit }
        if activeCandles.count != initialCount {
            saveCandles()
        }
        CandleIslandManager.shared.sync(with: activeCandles, language: BibleManager.shared.appLanguage)

        // Если выбранная для виджета свеча угасла, сбрасываем на автовыбор
        if let selectedId = selectedWidgetCandleId,
           !activeCandles.contains(where: { $0.id.uuidString == selectedId }) {
            setSelectedWidgetCandle(id: nil)
        }
    }
    
    // MARK: - Хранилище свечей
    private func saveCandles() {
        if let data = try? JSONEncoder().encode(activeCandles) {
            AppGroupConstants.syncDataToAll(data, forKey: kCandlesStorageKey)
            // Листы сгоревших свечей больше не нужны
            let kept = Set(activeCandles.compactMap { $0.pageImageFile })
            AppGroupConstants.removeSharedFiles(withPrefix: "candle_page_", keeping: kept)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Рисует лист с молитвой и кладёт картинку в общий контейнер: большой виджет показывает её
    func attachParchment(to candleId: UUID, page: ManuscriptPage) {
        guard let index = activeCandles.firstIndex(where: { $0.id == candleId }),
              let image = ManuscriptPageSnapshot.widgetImage(page: page, pen: ManuscriptPen.effective),
              let data = image.jpegData(compressionQuality: 0.88) else { return }
        let fileName = PrayerCandle.pageImageFileName(for: candleId)
        AppGroupConstants.syncFileToAll(data, named: fileName)
        activeCandles[index] = activeCandles[index].withPageImageFile(fileName)
        saveCandles()
    }
    
    private func loadSavedCandles() {
        let savedData = AppGroupConstants.sharedData(forKey: kCandlesStorageKey)
        guard let data = savedData,
              let list = try? JSONDecoder().decode([PrayerCandle].self, from: data) else {
            // Если сохраненных нет — добавляем 1 благоговейную свечу по умолчанию за мир
            let defaultCandle = PrayerCandle(
                personName: "Վասն խաղաղության աշխարհի",
                intention: .peace,
                customPrayer: "О мире и благоденствии во всем мире",
                tier: .generous,
                litDate: Date()
            )
            self.activeCandles = [defaultCandle]
            saveCandles()
            return
        }
        
        // Оставляем только горящие свечи
        let litCandles = list.filter { $0.isLit }
        self.activeCandles = litCandles
        if litCandles.count != list.count {
            saveCandles()
        }
    }
}
