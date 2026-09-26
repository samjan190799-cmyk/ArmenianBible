import Foundation
import SwiftUI

// MARK: - Духовные намерения для возжжения свечи
enum CandleIntention: String, CaseIterable, Identifiable, Codable, Sendable {
    case health = "health"       // О здравии
    case peace = "peace"         // О мире и защите
    case memory = "memory"       // Об упокоении
    case gratitude = "gratitude" // В благодарность Богу
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .peace: return "dove.fill"
        case .memory: return "cross.fill"
        case .gratitude: return "sun.max.fill"
        }
    }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .health:
            switch language {
            case .armenian: return "Վասն առողջության"
            case .russian: return "О здравии и исцелении"
            case .english: return "For Health & Healing"
            }
        case .peace:
            switch language {
            case .armenian: return "Վասն խաղաղության"
            case .russian: return "О мире и защите"
            case .english: return "For Peace & Protection"
            }
        case .memory:
            switch language {
            case .armenian: return "Վասն հանգստեան"
            case .russian: return "Об упокоении душ"
            case .english: return "In Loving Memory"
            }
        case .gratitude:
            switch language {
            case .armenian: return "Գոհություն Աստծուն"
            case .russian: return "В благодарность Богу"
            case .english: return "In Gratitude to God"
            }
        }
    }
    
    func defaultPrayer(for language: AppLanguage) -> String {
        switch self {
        case .health:
            switch language {
            case .armenian: return "Տե՛ր Աստված, պահպանիր և առողջություն պարգևիր Քո ծառային:"
            case .russian: return "Господи, исцели и укрепи душевные и телесные силы раба Твоего."
            case .english: return "Lord, bless, heal, and protect Your servant with good health."
            }
        case .peace:
            switch language {
            case .armenian: return "Տո՛ւր մեզ Քո երկնային խաղաղությունը և պաշտպանիր ամեն չարից:"
            case .russian: return "Даруй, Господи, мир дому сему и защити от всякого зла."
            case .english: return "Grant us Your heavenly peace and deliver us from all evil."
            }
        case .memory:
            switch language {
            case .armenian: return "Քրիստոս Աստված, հանգո՛ զհոգիս ծառայից Քոց ի լուսեղեն օթևանս:"
            case .russian: return "Упокой, Господи, душу усопшего раба Твоего в селениях праведных."
            case .english: return "Lord, grant eternal rest and peace to the departed soul."
            }
        case .gratitude:
            switch language {
            case .armenian: return "Փա՜ռք Քեզ, Տե՛ր, ամեն բարիքի և ողորմության համար:"
            case .russian: return "Слава Тебе, Господи, за всякое благодеяние и милость Твою."
            case .english: return "Glory to You, Lord, for all Your abundant blessings."
            }
        }
    }
}

// MARK: - Типы свечей (Ежедневный дар и просмотр видеорекламы)
enum CandleTier: String, CaseIterable, Identifiable, Codable, Sendable {
    case freeDaily = "free_daily"
    case rewarded = "rewarded_candle"
    // Архивные идентификаторы (сохранены для совместимости сохраненных в UserDefaults/AppGroup свечей)
    case small = "com.samvel.armenianbible.candle.small"
    case temple = "com.samvel.armenianbible.candle.temple"
    case generous = "com.samvel.armenianbible.candle.generous"
    
    var id: String { rawValue }
    
    var isFree: Bool {
        self == .freeDaily
    }
    
    var isRewarded: Bool {
        self == .rewarded
    }
    
    var burnHours: Int {
        switch self {
        case .freeDaily: return 12
        case .rewarded: return 24
        case .small: return 24
        case .temple: return 48
        case .generous: return 168 // 7 дней
        }
    }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .freeDaily:
            switch language {
            case .armenian: return "Օրական մոմ (Անվճար)"
            case .russian: return "Ежедневная свеча (Бесплатно)"
            case .english: return "Daily Candle (Free)"
            }
        case .rewarded:
            switch language {
            case .armenian: return "Աղոթքի մոմ (Գովազդով)"
            case .russian: return "Молитвенная свеча (За видео)"
            case .english: return "Prayer Candle (Watch Video)"
            }
        case .small:
            switch language {
            case .armenian: return "Փոքրիկ մոմ"
            case .russian: return "Малая свеча"
            case .english: return "Small Candle"
            }
        case .temple:
            switch language {
            case .armenian: return "Տաճարային կանթեղ"
            case .russian: return "Храмовая лампада"
            case .english: return "Sanctuary Vigil Lamp"
            }
        case .generous:
            switch language {
            case .armenian: return "Մեծ տաճարային մոմ"
            case .russian: return "Большая храмовая свеча"
            case .english: return "Large Temple Candle"
            }
        }
    }
    
    func priceDisplay(for language: AppLanguage) -> String {
        switch self {
        case .freeDaily:
            return language == .armenian ? "Անվճար" : (language == .russian ? "Бесплатно" : "Free")
        case .rewarded:
            return language == .armenian ? "🎬 Տեսանյութ" : (language == .russian ? "🎬 1 Видео" : "🎬 1 Video")
        case .small:
            return "$0.99"
        case .temple:
            return "$1.99"
        case .generous:
            return "$4.99"
        }
    }
}

// MARK: - Модель зажженной молитвенной свечи
struct PrayerCandle: Identifiable, Codable, Sendable {
    let id: UUID
    let personName: String
    let intention: CandleIntention
    let customPrayer: String?
    let tier: CandleTier
    let litDate: Date
    
    init(
        id: UUID = UUID(),
        personName: String,
        intention: CandleIntention,
        customPrayer: String? = nil,
        tier: CandleTier,
        litDate: Date = Date()
    ) {
        self.id = id
        self.personName = personName
        self.intention = intention
        self.customPrayer = customPrayer
        self.tier = tier
        self.litDate = litDate
    }
    
    var duration: TimeInterval {
        Double(tier.burnHours) * 3600.0
    }
    
    var expirationDate: Date {
        litDate.addingTimeInterval(duration)
    }
    
    var isLit: Bool {
        Date() < expirationDate
    }
    
    var hoursRemaining: Int {
        let remaining = expirationDate.timeIntervalSince(Date())
        return max(0, Int(ceil(remaining / 3600.0)))
    }
    
    /// Процент сгорания свечи на указанную дату (от 0.0 до 1.0)
    func burnProgress(at date: Date = Date()) -> Double {
        guard duration > 0 else { return 1.0 }
        let elapsed = date.timeIntervalSince(litDate)
        return min(1.0, max(0.0, elapsed / duration))
    }
    
    /// Текущий процент сгорания свечи от 0.0 (только зажжена) до 1.0 (полностью сгорела)
    var burnProgress: Double {
        burnProgress(at: Date())
    }
    
    /// Человекочитаемое форматирование оставшегося времени (с минутами, если < 1 часа)
    func remainingTimeText(for language: AppLanguage) -> String {
        let remaining = expirationDate.timeIntervalSince(Date())
        guard remaining > 0 else {
            switch language {
            case .armenian: return "Մարած"
            case .russian: return "Угасла"
            case .english: return "Extinguished"
            }
        }
        
        let totalMinutes = Int(ceil(remaining / 60.0))
        if totalMinutes < 60 {
            let m = max(1, totalMinutes)
            switch language {
            case .armenian: return "\(m) ր."
            case .russian: return "\(m) мин."
            case .english: return "\(m)m"
            }
        }
        
        let hours = Int(ceil(Double(totalMinutes) / 60.0))
        switch language {
        case .armenian: return "\(hours) ժ."
        case .russian: return "\(hours) ч."
        case .english: return "\(hours)h"
        }
    }
}

// MARK: - Константы хранилища свечей
enum CandleConstants {
    public static let candlesStorageKey = "luys_saved_prayer_candles_v1"
    public static let selectedWidgetCandleKey = "luys_selected_widget_candle_id_v1"
}
