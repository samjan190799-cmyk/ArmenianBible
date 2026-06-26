import SwiftUI
import WidgetKit
import Foundation

// MARK: - Менеджер стихов (Bible Manager)
class BibleManager: ObservableObject {
    static let shared = BibleManager()
    
    @Published var currentVerse: BibleVerse
    
    // Идентификатор App Group для совместного доступа к данным между приложением и виджетом
    private let appGroupSuiteName = "group.com.samvel.ArmenianBible"
    
    private let textKey = "currentVerseText"
    private let referenceKey = "currentVerseReference"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupSuiteName)
    }
    
    private init() {
        // Попытка загрузить сохраненный стих из общей памяти App Group
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedText = defaults.string(forKey: textKey),
           let savedRef = defaults.string(forKey: referenceKey) {
            self.currentVerse = BibleVerse(text: savedText, reference: savedRef)
        } else {
            // Если сохраненного стиха нет, используем первый по умолчанию
            let defaultVerse = BibleVerse.database[0]
            self.currentVerse = defaultVerse
            
            // Записываем в общую память
            if let defaults = UserDefaults(suiteName: appGroupSuiteName) {
                defaults.set(defaultVerse.text, forKey: textKey)
                defaults.set(defaultVerse.reference, forKey: referenceKey)
            }
        }
    }
    
    // MARK: - Выбор случайного стиха
    func selectRandomVerse() {
        let database = BibleVerse.database
        guard !database.isEmpty else { return }
        
        // Фильтруем стихи, чтобы не выбрать тот же самый повторно (если их больше одного)
        let availableVerses = database.filter { $0.text != currentVerse.text }
        let newVerse: BibleVerse
        
        if !availableVerses.isEmpty {
            newVerse = availableVerses.randomElement() ?? database[0]
        } else {
            newVerse = database[0]
        }
        
        // Обновляем состояние в приложении
        self.currentVerse = newVerse
        
        // Сохраняем в UserDefaults группы приложений
        if let defaults = sharedDefaults {
            defaults.set(newVerse.text, forKey: textKey)
            defaults.set(newVerse.reference, forKey: referenceKey)
            
            // Вынуждаем WidgetKit немедленно перезагрузить все виджеты на экране блокировки
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
