import SwiftUI
import WidgetKit
import Foundation

// MARK: - Менеджер стихов (Bible Manager)
class BibleManager: ObservableObject {
    static let shared = BibleManager()
    
    @Published var currentVerse: BibleVerse
    @Published var isGeneratingAI = false
    @Published var updateInterval: UpdateInterval = .everyHour
    @Published var selectedCategory: TextCategory = .both
    
    // Идентификатор App Group для совместного доступа к данным между приложением и виджетом
    private let appGroupSuiteName = "group.com.samvel.ArmenianBible"
    
    private let textKey = "currentVerseText"
    private let referenceKey = "currentVerseReference"
    private let apiKeyStoreKey = "gemini_api_key_secure"
    private let updateIntervalKey = "widgetUpdateInterval"
    private let categoryKey = "selectedCategory"
    
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
        case .both:
            return BibleVerse.database
        }
    }
    
    // MARK: - Сохранение стиха в AppGroup и обновление виджета
    func updateCurrentVerse(_ verse: BibleVerse) {
        self.currentVerse = verse
        if let defaults = sharedDefaults {
            defaults.set(verse.text, forKey: textKey)
            defaults.set(verse.reference, forKey: referenceKey)
            
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
    
    // MARK: - Генерация цитаты через Gemini API
    func generateVerseWithAI(completion: @escaping (Result<BibleVerse, Error>) -> Void) {
        let apiKey = geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "BibleManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is empty"])))
            return
        }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=\(apiKey)") else {
            completion(.failure(NSError(domain: "BibleManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            return
        }
        
        // Промпт, требующий простой текстовый формат с разделителем "|"
        let prompt = "Դու Աստվածաշնչի փորձագետ ես: Գեներացրու մեկ պատահական, ոգեշնչող, իմաստալից և գեղեցիկ աստվածաշնչյան մեջբերում (տող) հայերեն լեզվով (Արարատ թարգմանությունից): Գրիր ԱՄԲՈՂՋԱԿԱՆ տեքստը, առանց կրճատումների կամ բազմակետերի (...): Տուր միայն մեջբերման տեքստը և հղումը հետևյալ ֆորմատով՝ [Մեջբերում] | [Հղում] (օրինակ՝ Տերը իմ հովիվն է, և ես կարիք չեմ ունենա։ | Սաղմոսներ 23:1): Ոչ մի ուրիշ բան մի գրիր:"
        
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
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
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
                // Пытаемся извлечь сообщение об ошибке от самого API Gemini
                if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorDict = errJson["error"] as? [String: Any],
                   let errMsg = errorDict["message"] as? String {
                    completion(.failure(NSError(domain: "BibleManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Gemini API: \(errMsg)"])))
                } else {
                    completion(.failure(NSError(domain: "BibleManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])))
                }
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = jsonResponse["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let textResult = firstPart["text"] as? String {
                    
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
                            let newVerse = BibleVerse(text: cleanText, reference: "Աստվածաշունչ")
                            DispatchQueue.main.async {
                                self?.updateCurrentVerse(newVerse)
                            }
                            completion(.success(newVerse))
                        } else {
                            completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid formatting returned from AI"])))
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "BibleManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mismatched JSON structure"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
