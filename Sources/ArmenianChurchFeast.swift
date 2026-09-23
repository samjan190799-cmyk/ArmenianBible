import Foundation
import UIKit

// MARK: - Тип церковного праздника / события
enum FeastType: String, Codable, CaseIterable, Identifiable, Sendable {
    case daghavar = "daghavar"       // 5 Главных праздников (Տաղավար տոներ)
    case dominical = "dominical"     // Господские и Богородичные праздники (Տերունական տոներ)
    case fasting = "fasting"         // Постные периоды (Պահք)
    case saints = "saints"           // Память святых (Սրբոց տոներ)
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .daghavar: return "crown.fill"
        case .dominical: return "sun.max.fill"
        case .fasting: return "flame.fill"
        case .saints: return "cross.fill"
        }
    }
    
    var colorHex: String {
        switch self {
        case .daghavar: return "F59E0B" // Золотой
        case .dominical: return "38BDF8" // Голубой
        case .fasting: return "8B5CF6"   // Фиолетовый
        case .saints: return "10B981"    // Зеленый
        }
    }
    
    func localizedTitle(for lang: AppLanguage) -> String {
        switch self {
        case .daghavar:
            switch lang {
            case .armenian: return "Տաղավար տոներ"
            case .russian: return "Великие праздники"
            case .english: return "Major Feasts"
            }
        case .dominical:
            switch lang {
            case .armenian: return "Տերունական տոներ"
            case .russian: return "Господские праздники"
            case .english: return "Dominical Feasts"
            }
        case .fasting:
            switch lang {
            case .armenian: return "Պահք"
            case .russian: return "Посты"
            case .english: return "Fasting Days"
            }
        case .saints:
            switch lang {
            case .armenian: return "Սրբոց տոներ"
            case .russian: return "Дни святых"
            case .english: return "Saints' Days"
            }
        }
    }
}

// MARK: - Модель церковного праздника
struct ArmenianChurchFeast: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let type: FeastType
    let date: Date
    let titleHy: String
    let titleRu: String
    let titleEn: String
    let descriptionHy: String
    let descriptionRu: String
    let descriptionEn: String
    let meaningHy: String
    let meaningRu: String
    let meaningEn: String
    let traditionsHy: String
    let traditionsRu: String
    let traditionsEn: String
    let scriptureReading: String
    let prayerHy: String
    let prayerRu: String
    let prayerEn: String
    let isFasting: Bool
    
    func title(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return titleHy
        case .russian: return titleRu
        case .english: return titleEn
        }
    }
    
    func description(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return descriptionHy
        case .russian: return descriptionRu
        case .english: return descriptionEn
        }
    }
    
    func meaning(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return meaningHy.isEmpty ? descriptionHy : meaningHy
        case .russian: return meaningRu.isEmpty ? descriptionRu : meaningRu
        case .english: return meaningEn.isEmpty ? descriptionEn : meaningEn
        }
    }
    
    func traditions(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return traditionsHy
        case .russian: return traditionsRu
        case .english: return traditionsEn
        }
    }
    
    func prayer(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return prayerHy
        case .russian: return prayerRu
        case .english: return prayerEn
        }
    }
    
    var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "hy_AM")
        return formatter.string(from: date)
    }
    
    func formattedDate(for lang: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM, EEEE"
        formatter.locale = Locale(identifier: lang.localeCode)
        return formatter.string(from: date)
    }
    
    func daysRemaining(from baseDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: baseDate)
        let startOfFeast = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfFeast).day ?? 0
    }
    
    func countdownBadge(for lang: AppLanguage, from baseDate: Date = Date()) -> (text: String, isToday: Bool, isUpcoming: Bool) {
        let diff = daysRemaining(from: baseDate)
        if diff == 0 {
            return ("days_left_today".localized(for: lang), true, true)
        } else if diff == 1 {
            return ("days_left_tomorrow".localized(for: lang), false, true)
        } else if diff > 1 {
            let format = "days_left_in".localized(for: lang)
            return (String(format: format, diff), false, true)
        } else {
            return ("days_left_passed".localized(for: lang), false, false)
        }
    }
}

