import Foundation
import SwiftUI

extension BibleVerse {
    // MARK: - Общая база стихов: основные стихи + стихи из «Веры и Мужества»
    /// Стихи из shortFaith2 (кроме молитв), которых ещё нет в основной базе: раньше нигде не показывались
    static let faithScriptures: [BibleVerse] = {
        let known = Set(baseDatabase.map { $0.refEn })
        return shortFaith2.filter { !$0.isPrayer && !known.contains($0.refEn) }
    }()

    /// Плюс цельные отрывки из bible.db (BibleVerseDatabase+Library.swift): они дают среднему и большому виджету разнообразие по длине
    static let database: [BibleVerse] = baseDatabase + faithScriptures + libraryQuotes

    // MARK: - Объединённая категория «Вера и Мужество» (shortFaith + shortFaith2)
    static var allShortFaith: [BibleVerse] { shortFaith + shortFaith2 }

    // MARK: - Выборка стихов по категории домашнего виджета (HomeWidgetCategory)
    static func verses(for category: HomeWidgetCategory, isPremium: Bool = true) -> [BibleVerse] {
        let activeCat = (isPremium || !category.isPremiumRequired) ? category : .all
        switch activeCat {
        case .all:
            return BibleVerse.database
            
        case .gospels:
            let gospels = BibleVerse.database.filter { v in
                let r = (v.refHy + " " + v.refRu + " " + v.refEn).lowercased()
                return r.contains("մատթեոս") || r.contains("մարկոս") || r.contains("ղուկաս") || r.contains("հովհաննես") ||
                       r.contains("матфе") || r.contains("марк") || r.contains("луки") || r.contains("иоанн") ||
                       r.contains("matthew") || r.contains("mark") || r.contains("luke") || r.contains("john")
            }
            return !gospels.isEmpty ? gospels : BibleVerse.database
            
        case .psalms:
            let p = BibleVerse.database.filter { v in
                let r = (v.refHy + " " + v.refRu + " " + v.refEn).lowercased()
                return r.contains("սաղմոս") || r.contains("псалом") || r.contains("psalm")
            }
            let list = p + BibleVerse.shortPsalms
            return !list.isEmpty ? list : BibleVerse.database
            
        case .wisdom:
            let w = BibleVerse.database.filter { v in
                let r = (v.refHy + " " + v.refRu + " " + v.refEn).lowercased()
                return r.contains("առակ") || r.contains("ժողովող") || r.contains("իմաստութ") ||
                       r.contains("притч") || r.contains("екклесиаст") || r.contains("премудрост") ||
                       r.contains("proverbs") || r.contains("ecclesiastes") || r.contains("wisdom")
            }
            let list = w + BibleVerse.shortWisdom
            return !list.isEmpty ? list : BibleVerse.database
            
        case .narekatsi:
            let n = BibleVerse.database.filter { v in
                let r = (v.refHy + " " + v.refRu + " " + v.refEn).lowercased()
                return r.contains("նարեկ") || r.contains("нарекаци") || r.contains("narek")
            }
            // Короткие строки идут в средний виджет, строфы — в средний и большой (по длине)
            let list = n + BibleVerse.shortNarekatsi + BibleVerse.narekStanzas
            return !list.isEmpty ? list : BibleVerse.shortNarekatsi
            
        case .prayers:
            // Молитвы лежат отдельно от стихов (BibleVerseDatabase+Prayers.swift): целые и законченные куски,
            // виджет сам берёт те, что помещаются по длине
            let units = BibleVerse.prayerUnits
            return !units.isEmpty ? units : BibleVerse.database
            
        case .favorites:
            if let savedFavoritesData = AppGroupConstants.sharedDefaults.data(forKey: "favorite_verses"),
               let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: savedFavoritesData),
               !decoded.isEmpty {
                return decoded.map { item in
                    BibleVerse(
                        id: item.id,
                        textHy: item.textHy,
                        textHyArarat: item.textHyArarat,
                        textRu: item.textRu,
                        textEn: item.textEn,
                        refHy: item.refHy,
                        refRu: item.refRu,
                        refEn: item.refEn,
                        isPrayer: false
                    )
                }
            }
            return BibleVerse.database
        }
    }
}

// MARK: - Нормализация строк для сравнения без учета регистра и знаков препинания


