import Foundation
import SwiftUI
import StoreKit

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
    
    private let kCandlesStorageKey = "luys_saved_prayer_candles_v1"
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
    
    // MARK: - Покупка и зажжение свечи (Consumable In-App Purchase)
    func purchaseAndLightCandle(
        tier: CandleTier,
        name: String,
        intention: CandleIntention,
        customPrayer: String?
    ) async -> Bool {
        if tier.isFree {
            return lightFreeDailyCandle(name: name, intention: intention, customPrayer: customPrayer)
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
    
    // MARK: - Хранилище свечей
    private func saveCandles() {
        if let data = try? JSONEncoder().encode(activeCandles) {
            UserDefaults.standard.set(data, forKey: kCandlesStorageKey)
        }
    }
    
    private func loadSavedCandles() {
        guard let data = UserDefaults.standard.data(forKey: kCandlesStorageKey),
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
            return
        }
        self.activeCandles = list
    }
}
