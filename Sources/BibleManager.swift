import SwiftUI
import WidgetKit
import Foundation
import UserNotifications

// MARK: - Менеджер стихов (Bible Manager)
class BibleManager: ObservableObject {
    static let shared = BibleManager()
    
    @Published var currentVerse: BibleVerse
    @Published var isGeneratingAI = false
    @Published var updateInterval: UpdateInterval = .everyHour
    @Published var selectedCategory: TextCategory = .both
    @Published var activeProvider: AIProvider = .gemini
    @Published var appLanguage: AppLanguage = .armenian
    @Published var favoriteVerses: [BibleVerse] = []
    @Published var accentTheme: AccentColorTheme = .indigo
    @Published var dailyNotificationsEnabled: Bool = false
    @Published var dailyNotificationTime: Date = Date()
    
    // Идентификатор App Group для совместного доступа к данным между приложением и виджетом
    private let appGroupSuiteName = "group.com.samvel.ArmenianBible"
    
    private let textKey = "currentVerseText"
    private let referenceKey = "currentVerseReference"
    private let apiKeyStoreKey = "gemini_api_key_secure"
    private let openaiApiKeyStoreKey = "openai_api_key_secure"
    private let anthropicApiKeyStoreKey = "anthropic_api_key_secure"
    private let updateIntervalKey = "widgetUpdateInterval"
    private let categoryKey = "selectedCategory"
    private let activeProviderKey = "active_ai_provider"
    private let appLanguageKey = "app_language"
    private let favoritesKey = "favorite_verses"
    private let accentThemeKey = "accent_theme"
    private let notificationsEnabledKey = "daily_notifications_enabled"
    private let notificationTimeKey = "daily_notification_time"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupSuiteName)
    }
    
    // Свойство для получения и сохранения API-ключа Gemini
    var geminiApiKey: String {
        get {
            UserDefaults.standard.string(forKey: apiKeyStoreKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: apiKeyStoreKey)
            objectWillChange.send()
        }
    }
    
    // Свойство для получения и сохранения API-ключа OpenAI (ChatGPT)
    var openaiApiKey: String {
        get {
            UserDefaults.standard.string(forKey: openaiApiKeyStoreKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: openaiApiKeyStoreKey)
            objectWillChange.send()
        }
    }
    
    // Свойство для получения и сохранения API-ключа Anthropic (Claude)
    var anthropicApiKey: String {
        get {
            UserDefaults.standard.string(forKey: anthropicApiKeyStoreKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: anthropicApiKeyStoreKey)
            objectWillChange.send()
        }
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
        
        // Загрузка интервала обновления
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedIntervalRaw = defaults.string(forKey: updateIntervalKey),
           let savedInterval = UpdateInterval(rawValue: savedIntervalRaw) {
            self.updateInterval = savedInterval
        } else {
            self.updateInterval = .everyHour
        }
        
        // Загрузка категории отображаемого текста
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedCategoryRaw = defaults.string(forKey: categoryKey),
           let savedCategory = TextCategory(rawValue: savedCategoryRaw) {
            self.selectedCategory = savedCategory
        } else {
            self.selectedCategory = .both
        }
        
        // Загрузка активного провайдера ИИ
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedProviderRaw = defaults.string(forKey: activeProviderKey),
           let savedProvider = AIProvider(rawValue: savedProviderRaw) {
            self.activeProvider = savedProvider
        } else {
            self.activeProvider = .gemini
        }
        
        // Загрузка языка приложения
        if let defaults = UserDefaults(suiteName: appGroupSuiteName),
           let savedLanguageRaw = defaults.string(forKey: appLanguageKey),
           let savedLanguage = AppLanguage(rawValue: savedLanguageRaw) {
            self.appLanguage = savedLanguage
        } else {
            self.appLanguage = .armenian
        }
        
        // Загрузка Избранного
        if let defaults = sharedDefaults,
           let savedFavoritesData = defaults.data(forKey: favoritesKey) {
            if let decoded = try? JSONDecoder().decode([BibleVerse].self, from: savedFavoritesData) {
                self.favoriteVerses = decoded
            }
        }
        
        // Загрузка Цветовой темы
        if let defaults = sharedDefaults,
           let savedThemeRaw = defaults.string(forKey: accentThemeKey),
           let savedTheme = AccentColorTheme(rawValue: savedThemeRaw) {
            self.accentTheme = savedTheme
        } else {
            self.accentTheme = .indigo
        }
        
        // Загрузка Уведомлений
        if let defaults = sharedDefaults {
            self.dailyNotificationsEnabled = defaults.bool(forKey: notificationsEnabledKey)
            if let savedTime = defaults.object(forKey: notificationTimeKey) as? Date {
                self.dailyNotificationTime = savedTime
            } else {
                var components = DateComponents()
                components.hour = 9
                components.minute = 0
                self.dailyNotificationTime = Calendar.current.date(from: components) ?? Date()
            }
        } else {
            self.dailyNotificationsEnabled = false
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            self.dailyNotificationTime = Calendar.current.date(from: components) ?? Date()
        }
    }
    
    // MARK: - Сохранение активного провайдера ИИ
    func setActiveProvider(_ provider: AIProvider) {
        self.activeProvider = provider
        if let defaults = sharedDefaults {
            defaults.set(provider.rawValue, forKey: activeProviderKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Сохранение языка приложения
    func setAppLanguage(_ language: AppLanguage) {
        self.appLanguage = language
        if let defaults = sharedDefaults {
            defaults.set(language.rawValue, forKey: appLanguageKey)
            defaults.synchronize()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Принудительное обновление UI после смены языка/темы
    func forceRefreshUI() {
        objectWillChange.send()
    }
    
    // MARK: - Сохранение интервала обновления и перезапуск виджета
    func setUpdateInterval(_ interval: UpdateInterval) {
        self.updateInterval = interval
        if let defaults = sharedDefaults {
            defaults.set(interval.rawValue, forKey: updateIntervalKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Сохранение категории контента и перезапуск виджета
    func setSelectedCategory(_ category: TextCategory) {
        self.selectedCategory = category
        if let defaults = sharedDefaults {
            defaults.set(category.rawValue, forKey: categoryKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Получение отфильтрованной базы данных стихов/молитв
    func getFilteredDatabase(for category: TextCategory) -> [BibleVerse] {
        switch category {
        case .verses:
            return BibleVerse.database.filter { !$0.isPrayer }
        case .prayers:
            return BibleVerse.database.filter { $0.isPrayer }
        case .favorites:
            return favoriteVerses.isEmpty ? BibleVerse.database : favoriteVerses
        case .both:
            return BibleVerse.database
        }
    }
    
    // MARK: - Управление Избранным
    func addToFavorites(_ verse: BibleVerse) {
        if !favoriteVerses.contains(where: { $0.text == verse.text }) {
            favoriteVerses.append(verse)
            saveFavorites()
        }
    }
    
    func removeFromFavorites(_ verse: BibleVerse) {
        favoriteVerses.removeAll(where: { $0.text == verse.text })
        saveFavorites()
    }
    
    func isFavorite(_ verse: BibleVerse) -> Bool {
        favoriteVerses.contains(where: { $0.text == verse.text })
    }
    
    private func saveFavorites() {
        if let defaults = sharedDefaults,
           let encoded = try? JSONEncoder().encode(favoriteVerses) {
            defaults.set(encoded, forKey: favoritesKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Сохранение цветовой темы
    func setAccentTheme(_ theme: AccentColorTheme) {
        self.accentTheme = theme
        if let defaults = sharedDefaults {
            defaults.set(theme.rawValue, forKey: accentThemeKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Сохранение и планирование уведомлений
    func setDailyNotificationsEnabled(_ enabled: Bool) {
        self.dailyNotificationsEnabled = enabled
        if let defaults = sharedDefaults {
            defaults.set(enabled, forKey: notificationsEnabledKey)
        }
        if enabled {
            requestNotificationPermission { granted in
                if granted {
                    self.scheduleDailyNotifications()
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    func setDailyNotificationTime(_ time: Date) {
        self.dailyNotificationTime = time
        if let defaults = sharedDefaults {
            defaults.set(time, forKey: notificationTimeKey)
        }
        if dailyNotificationsEnabled {
            scheduleDailyNotifications()
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleDailyNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard dailyNotificationsEnabled else { return }
        
        let database = getFilteredDatabase(for: selectedCategory)
        guard !database.isEmpty else { return }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: dailyNotificationTime)
        
        // UNUserNotificationCenter принимает до 64 уведомлений, мы планируем 7 штук на неделю вперед
        for dayOffset in 0..<7 {
            let verse = database.randomElement() ?? database[0]
            
            let content = UNMutableNotificationContent()
            content.title = "widget_title".localized(for: appLanguage)
            content.body = "\(verse.text) (\(verse.reference))"
            content.sound = .default
            
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "daily_verse_\(dayOffset)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Сохранение стиха в AppGroup и обновление виджета
    func updateCurrentVerse(_ verse: BibleVerse) {
        self.currentVerse = verse
        // Принудительно уведомляем SwiftUI, т.к. BibleVerse struct с computed свойствами
        // может не считаться "изменённым" при смене языка (stored properties те же)
        objectWillChange.send()
        if let defaults = sharedDefaults {
            defaults.set(verse.text, forKey: textKey)
            defaults.set(verse.reference, forKey: referenceKey)
            defaults.synchronize()
            
            // Заставляем виджеты немедленно обновиться
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Выбор случайного стиха из оффлайн-базы данных
    func selectRandomVerse() {
        let database = getFilteredDatabase(for: selectedCategory)
        guard !database.isEmpty else { return }
        
        let availableVerses = database.filter { $0.text != currentVerse.text }
        let newVerse: BibleVerse
        
        if !availableVerses.isEmpty {
            newVerse = availableVerses.randomElement() ?? database[0]
        } else {
            newVerse = database[0]
        }
        
        updateCurrentVerse(newVerse)
    }
    
    // MARK: - Генерация цитаты через Gemini API / ChatGPT / Claude
    func generateVerseWithAI(completion: @escaping (Result<BibleVerse, Error>) -> Void) {
        let apiKey: String
        switch activeProvider {
        case .gemini:
            apiKey = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .chatgpt:
            apiKey = openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .claude:
            apiKey = anthropicApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "BibleManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is empty"])))
            return
        }
        
        var request: URLRequest
        let prompt: String
        switch appLanguage {
        case .armenian:
            prompt = "Դու Աստվածաշնչի փորձագետ ես: Գեներացրու մեկ պատահական, ոգեշնչող, իմաստալից և գեղեցիկ աստվածաշնչյան մեջբերում (տող) հայերեն լեզվով (Արարատ թարգմանությունից): Գրիր ԱՄԲՈՂՋԱԿԱՆ տեքստը, առանց կրճատումների կամ բազմակետերի (...): Տուր միայն մեջբերման տեքստը և հղումը հետևյալ ֆորմատով՝ [Մեջբերում] | [Հղում] (օրինակ՝ Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։ | Սաղմոսներ 23:1): Ոչ մի ուրիշ բան մի գրիր:"
        case .russian:
            prompt = "Ты эксперт по Библии. Сгенерируй одну случайную, вдохновляющую, глубокую и красивую библейскую цитату на русском языке (из Синодального перевода). Пиши ПОЛНЫЙ текст цитаты без сокращений и многоточий (...). Выдай только текст цитаты и ссылку на нее в следующем формате: [Цитата] | [Ссылка] (например: Господь — Пастырь мой; я ни в чем не буду нуждаться. | Псалом 22:1). Больше ничего не пиши."
        case .english:
            prompt = "You are a Bible expert. Generate one random, inspiring, meaningful, and beautiful Bible quote in English (from KJV or ESV translation). Write the COMPLETE text of the quote without abbreviations or ellipses (...). Return only the quote text and the reference in the following format: [Quote] | [Reference] (example: The Lord is my shepherd; I shall not want. | Psalm 23:1). Do not write anything else."
        }
        
        switch activeProvider {
        case .gemini:
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=\(apiKey)") else {
                completion(.failure(NSError(domain: "BibleManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
                return
            }
            let requestBody: [String: Any] = [
                "contents": [
                    [
                        "parts": [
                            ["text": prompt]
                        ]
                    ]
                ]
            ]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Serialization Error"])))
                return
            }
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
        case .chatgpt:
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                completion(.failure(NSError(domain: "BibleManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
                return
            }
            let requestBody: [String: Any] = [
                "model": "gpt-5.5",
                "messages": [
                    ["role": "user", "content": prompt]
                ]
            ]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Serialization Error"])))
                return
            }
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData
            
        case .claude:
            guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
                completion(.failure(NSError(domain: "BibleManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
                return
            }
            let requestBody: [String: Any] = [
                "model": "claude-sonnet-5",
                "max_tokens": 1024,
                "messages": [
                    ["role": "user", "content": prompt]
                ]
            ]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Serialization Error"])))
                return
            }
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = jsonData
        }
        
        isGeneratingAI = true
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isGeneratingAI = false
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Проверяем HTTP статус на наличие ошибок
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                // Пытаемся извлечь сообщение об ошибке от API
                if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var errorMsg: String? = nil
                    
                    if let errorDict = errJson["error"] as? [String: Any] {
                        errorMsg = errorDict["message"] as? String
                    } else if let errorDict = errJson["error"] as? String {
                        errorMsg = errorDict
                    }
                    
                    if let msg = errorMsg {
                        completion(.failure(NSError(domain: "BibleManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(self?.activeProvider.displayName ?? "AI") API: \(msg)"])))
                        return
                    }
                }
                completion(.failure(NSError(domain: "BibleManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])))
                return
            }
            
            do {
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                    return
                }
                
                var extractedText: String? = nil
                
                switch self?.activeProvider {
                case .gemini:
                    if let candidates = jsonResponse["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first {
                        extractedText = firstPart["text"] as? String
                    }
                case .chatgpt:
                    if let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any] {
                        extractedText = message["content"] as? String
                    }
                case .claude:
                    if let contentList = jsonResponse["content"] as? [[String: Any]],
                       let firstContent = contentList.first {
                        extractedText = firstContent["text"] as? String
                    }
                default:
                    break
                }
                
                guard let textResult = extractedText else {
                    completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mismatched JSON structure"])))
                    return
                }
                
                let cleanResult = textResult.trimmingCharacters(in: .whitespacesAndNewlines)
                let components = cleanResult.components(separatedBy: "|")
                
                if components.count >= 2 {
                    let text = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                    let reference = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"”'«»"))
                    
                    let newVerse = BibleVerse(text: text, reference: reference)
                    
                    DispatchQueue.main.async {
                        self?.updateCurrentVerse(newVerse)
                    }
                    completion(.success(newVerse))
                } else {
                    // Попытка использовать всю полученную строку, если нет разделителя |
                    let cleanText = cleanResult.trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "[]\"“'«»"))
                    if !cleanText.isEmpty {
                        let newVerse = BibleVerse(text: cleanText, reference: NSLocalizedString("widget_title", comment: ""))
                        DispatchQueue.main.async {
                            self?.updateCurrentVerse(newVerse)
                        }
                        completion(.success(newVerse))
                    } else {
                        completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid formatting returned from AI"])))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
