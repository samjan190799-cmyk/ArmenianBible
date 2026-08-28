import Foundation
import StoreKit
import SwiftUI
import Combine

// MARK: - Модели подписок и тарифов
public enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly = "com.samvel.armenianbible.subscription.monthly"
    case yearly = "com.samvel.armenianbible.subscription.yearly"
    case lifetime = "com.samvel.armenianbible.lifetime"
    
    public var id: String { rawValue }
    
    public func localizedTitle(for language: AppLanguage) -> String {
        switch self {
        case .monthly:
            switch language {
            case .armenian: return "1 Ամիս"
            case .russian: return "1 Месяц"
            case .english: return "1 Month"
            }
        case .yearly:
            switch language {
            case .armenian: return "1 Տարի"
            case .russian: return "1 Год"
            case .english: return "1 Year"
            }
        case .lifetime:
            switch language {
            case .armenian: return "Հավերժ (Lifetime)"
            case .russian: return "Навсегда (Вечная)"
            case .english: return "Lifetime Access"
            }
        }
    }
    
    public func fallbackPrice(for language: AppLanguage) -> String {
        switch self {
        case .monthly:
            return "$1.99"
        case .yearly:
            return "$14.99 / տարի"
        case .lifetime:
            return "$29.99"
        }
    }
    
    public func localizedBadge(for language: AppLanguage) -> String? {
        switch self {
        case .yearly:
            switch language {
            case .armenian: return "Խնայեք 40% • 7 օր անվճար"
            case .russian: return "Скидка 40% • 7 дней Trial"
            case .english: return "Save 40% • 7 Days Free"
            }
        case .lifetime:
            switch language {
            case .armenian: return "Մեկընդմիշտ"
            case .russian: return "Единоразово"
            case .english: return "Best Value"
            }
        case .monthly:
            return nil
        }
    }
}

// MARK: - Главный Менеджер Подписок (StoreKit 2 + Offline Fallback)
@MainActor
public final class SubscriptionManager: ObservableObject {
    public static let shared = SubscriptionManager()
    
    @Published public private(set) var isPremium: Bool = false
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var isLoadingProducts: Bool = false
    @Published public private(set) var isPurchasing: Bool = false
    @Published public var purchaseErrorMessage: String? = nil
    
    // Ограничитель бесплатных ИИ запросов (3 вопроса в день)
    private let kDailyAiDateKey = "daily_ai_last_date_key"
    private let kDailyAiCountKey = "daily_ai_usage_count_key"
    private let maxFreeDailyAiQueries = 3
    
    private let kPremiumOverrideKey = "armenian_bible_is_premium_cached"
    private var updateListenerTask: Task<Void, Never>? = nil
    
    private init() {
        // Загружаем закэшированный статус
        self.isPremium = UserDefaults.standard.bool(forKey: kPremiumOverrideKey)
        
        // Запуск слушателя транзакций StoreKit 2
        updateListenerTask = listenForTransactions()
        
        // Загрузка продуктов и валидация прав
        Task {
            await requestProducts()
            await updatePurchasedStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - StoreKit 2 Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Загрузка продуктов из App Store
    
    public func requestProducts() async {
        isLoadingProducts = true
        let productIds = SubscriptionPlan.allCases.map { $0.rawValue }
        
        do {
            let storeProducts = try await Product.request(with: Set(productIds))
            self.products = storeProducts.sorted { p1, p2 in
                p1.price < p2.price
            }
        } catch {
            print("Failed to fetch StoreKit products: \(error)")
        }
        
        isLoadingProducts = false
    }
    
    // MARK: - Покупка продукта
    
    public func purchase(plan: SubscriptionPlan) async -> Bool {
        isPurchasing = true
        purchaseErrorMessage = nil
        
        // Ищем загруженный продукт
        guard let product = products.first(where: { $0.id == plan.rawValue }) else {
            // Если в симуляторе или без интернета нет продукта, проверим StoreKit
            do {
                let fetched = try await Product.request(with: [plan.rawValue])
                if let first = fetched.first {
                    return await executePurchase(product: first)
                }
            } catch {
                purchaseErrorMessage = error.localizedDescription
            }
            isPurchasing = false
            return false
        }
        
        return await executePurchase(product: product)
    }
    
    private func executePurchase(product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedStatus()
                await transaction.finish()
                isPurchasing = false
                return true
                
            case .userCancelled:
                isPurchasing = false
                return false
                
            case .pending:
                isPurchasing = false
                return false
                
            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
            isPurchasing = false
            return false
        }
    }
    
    // MARK: - Восстановление покупок (Restore Purchases)
    
    public func restorePurchases() async -> Bool {
        isPurchasing = true
        purchaseErrorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
            isPurchasing = false
            return isPremium
        } catch {
            purchaseErrorMessage = error.localizedDescription
            isPurchasing = false
            return false
        }
    }
    
    // MARK: - Проверка прав (Entitlements)
    
    public func updatePurchasedStatus() async {
        var hasActivePremium = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if SubscriptionPlan.allCases.contains(where: { $0.rawValue == transaction.productID }) {
                    if transaction.revocationDate == nil {
                        hasActivePremium = true
                    }
                }
            } catch {
                print("Failed to verify entitlement: \(error)")
            }
        }
        
        self.isPremium = hasActivePremium
        UserDefaults.standard.set(hasActivePremium, forKey: kPremiumOverrideKey)
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - ОГРАНИЧИТЕЛИ (Gating Logic)
    
    /// Проверка доступа к аудио Нарекаци (Глава 1 бесплатна для всех, остальные 2-95 требуют Premium)
    public func canPlayNarekAudio(prayerId: Int) -> Bool {
        if isPremium { return true }
        return prayerId <= 1
    }
    
    /// Проверка доступности ИИ-ассистента (3 бесплатных вопроса в сутки, далее Premium)
    public func canAskAI() -> Bool {
        if isPremium { return true }
        
        let (todayCount, _) = currentDailyAiUsage()
        return todayCount < maxFreeDailyAiQueries
    }
    
    /// Количество оставшихся бесплатных вопросов к ИИ на сегодня
    public var remainingFreeAiQuestions: Int {
        if isPremium { return 999 }
        let (todayCount, _) = currentDailyAiUsage()
        return max(0, maxFreeDailyAiQueries - todayCount)
    }
    
    /// Фиксация одного использованного бесплатного вопроса к ИИ
    public func recordAiQuestionUsed() {
        if isPremium { return }
        
        let (count, todayString) = currentDailyAiUsage()
        UserDefaults.standard.set(count + 1, forKey: kDailyAiCountKey)
        UserDefaults.standard.set(todayString, forKey: kDailyAiDateKey)
    }
    
    private func currentDailyAiUsage() -> (count: Int, todayString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        
        let savedDate = UserDefaults.standard.string(forKey: kDailyAiDateKey) ?? ""
        if savedDate == todayString {
            let count = UserDefaults.standard.integer(forKey: kDailyAiCountKey)
            return (count, todayString)
        } else {
            // Новый день - сброс
            UserDefaults.standard.set(todayString, forKey: kDailyAiDateKey)
            UserDefaults.standard.set(0, forKey: kDailyAiCountKey)
            return (0, todayString)
        }
    }
    
    /// Для внутреннего тестирования / отладки
    public func setDebugPremium(_ enabled: Bool) {
        self.isPremium = enabled
        UserDefaults.standard.set(enabled, forKey: kPremiumOverrideKey)
    }
}
