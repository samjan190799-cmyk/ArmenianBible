import Foundation
import SwiftUI
import StoreKit
import WidgetKit

// MARK: - Центральный менеджер виртуальных свечей и пожертвований (CandleManager)
/// Управляет зажженными свечами, бесплатной ежедневной молитвой и разовыми покупками StoreKit 2.
@MainActor
final class CandleManager: ObservableObject {
    static let shared = CandleManager()
    
    @Published private(set) var activeCandles: [PrayerCandle] = []
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var hasUsedDailyFreeCandle: Bool = false
    @Published private(set) var candleProducts: [Product] = []
    @Published var errorMessage: String? = nil
    
    private let kCandlesStorageKey = CandleConstants.candlesStorageKey
    private let kLastFreeCandleDateKey = "luys_last_free_candle_date"
    
    private init() {
        loadSavedCandles()
        checkDailyFreeStatus()
        
        #if !targetEnvironment(simulator)
        Task {
            await fetchStoreProducts()
        }
        #endif
    }
    
    // MARK: - Загрузка продуктов из App Store (StoreKit 2)
    func fetchStoreProducts() async {
        let consumableIds = [
            CandleTier.small.rawValue,
            CandleTier.temple.rawValue,
            CandleTier.generous.rawValue
        ]
        
        do {
            let products = try await Product.products(for: Set(consumableIds))
            self.candleProducts = products.sorted { $0.price < $1.price }
        } catch {
            print("Failed to fetch candle products: \(error)")
        }
    }
    
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
        
        UserDefaults.standard.set(Date(), forKey: kLastFreeCandleDateKey)
        hasUsedDailyFreeCandle = true
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return true
    }
    
    // MARK: - Покупка и зажжение свечи (Consumable In-App Purchase или Rewarded Video)
    func purchaseAndLightCandle(
        tier: CandleTier,
        name: String,
        intention: CandleIntention,
        customPrayer: String?
    ) async -> Bool {
        if tier.isFree {
            return lightFreeDailyCandle(name: name, intention: intention, customPrayer: customPrayer)
        }
        
        if tier.isRewarded {
            return await lightRewardedCandle(name: name, intention: intention, customPrayer: customPrayer)
        }
        
        isPurchasing = true
        errorMessage = nil
        
        #if targetEnvironment(simulator)
        // В симуляторе симулируем успешную транзакцию для тестов верстки
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        let candle = PrayerCandle(
            personName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            intention: intention,
            customPrayer: customPrayer,
            tier: tier,
            litDate: Date()
        )
        activeCandles.insert(candle, at: 0)
        saveCandles()
        isPurchasing = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return true
        #else
        do {
            var targetProduct = candleProducts.first(where: { $0.id == tier.rawValue })
            if targetProduct == nil {
                let fetched = try await Product.products(for: [tier.rawValue])
                targetProduct = fetched.first
            }
            
            guard let product = targetProduct else {
                errorMessage = "Продукт временно недоступен в App Store."
                isPurchasing = false
                return false
            }
            
            let purchaseResult = try await product.purchase()
            switch purchaseResult {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    
                    let candle = PrayerCandle(
                        personName: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        intention: intention,
                        customPrayer: customPrayer,
                        tier: tier,
                        litDate: Date()
                    )
                    activeCandles.insert(candle, at: 0)
                    saveCandles()
                    
                    isPurchasing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    return true
                    
                case .unverified(_, let error):
                    errorMessage = "Не удалось подтвердить покупку: \(error.localizedDescription)"
                    isPurchasing = false
                    return false
                }
                
            case .userCancelled:
                isPurchasing = false
                return false
                
            case .pending:
                errorMessage = "Транзакция ожидает подтверждения родительского контроля."
                isPurchasing = false
                return false
                
            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            isPurchasing = false
            return false
        }
        #endif
    }
    
    // MARK: - Зажжение свечи за просмотр видеорекламы (Meta Rewarded Video)
    func lightRewardedCandle(
        name: String,
        intention: CandleIntention,
        customPrayer: String?
    ) async -> Bool {
        // Если у пользователя активна PRO-подписка, свеча зажигается сразу без рекламы
        if SubscriptionManager.shared.isPremium {
            let candle = PrayerCandle(
                personName: name.trimmingCharacters(in: .whitespacesAndNewlines),
                intention: intention,
                customPrayer: customPrayer,
                tier: .rewarded,
                litDate: Date()
            )
            activeCandles.insert(candle, at: 0)
            saveCandles()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return true
        }
        
        isPurchasing = true
        errorMessage = nil
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            let resumeOnce: (Bool) -> Void = { result in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: result)
            }
            
            let isShown = LuysAdManager.shared.showRewardedAd(
                onReward: { [weak self] in
                    guard let self = self else {
                        resumeOnce(false)
                        return
                    }
                    let candle = PrayerCandle(
                        personName: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        intention: intention,
                        customPrayer: customPrayer,
                        tier: .rewarded,
                        litDate: Date()
                    )
                    self.activeCandles.insert(candle, at: 0)
                    self.saveCandles()
                    self.isPurchasing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    resumeOnce(true)
                },
                onDismissWithoutReward: { [weak self] in
                    guard let self = self else {
                        resumeOnce(false)
                        return
                    }
                    self.isPurchasing = false
                    self.errorMessage = "Для зажжения свечи необходимо досмотреть видеоролик до конца."
                    resumeOnce(false)
                }
            )
            
            if !isShown {
                self.isPurchasing = false
                self.errorMessage = "Реклама подготавливается. Пожалуйста, подождите пару секунд и нажмите снова."
                resumeOnce(false)
            }
        }
    }
    
    // MARK: - Автоматическая очистка угасших свечей
    func cleanExpiredCandles() {
        let initialCount = activeCandles.count
        activeCandles.removeAll { !$0.isLit }
        if activeCandles.count != initialCount {
            saveCandles()
        }
    }
    
    // MARK: - Хранилище свечей
    private func saveCandles() {
        if let data = try? JSONEncoder().encode(activeCandles) {
            UserDefaults.standard.set(data, forKey: kCandlesStorageKey)
            AppGroupConstants.syncToAll { defaults in
                defaults.set(data, forKey: self.kCandlesStorageKey)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func loadSavedCandles() {
        let savedData = AppGroupConstants.sharedDefaults.data(forKey: kCandlesStorageKey)
            ?? UserDefaults.standard.data(forKey: kCandlesStorageKey)
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
