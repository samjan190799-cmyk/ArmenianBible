import Foundation

// MARK: - Ошибки генерации викторины через ИИ
enum QuizAIError: LocalizedError {
    case missingApiKey
    case invalidURL
    case serializationError
    case serverError(Int, String)
    case emptyResponse
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "API Key is missing or empty"
        case .invalidURL:
            return "Invalid API URL"
        case .serializationError:
            return "Failed to serialize request payload"
        case .serverError(let code, let msg):
            return "AI Server Error (\(code)): \(msg)"
        case .emptyResponse:
            return "AI returned an empty response"
        case .parsingFailed:
            return "Failed to parse questions from AI response"
        }
    }
}

// MARK: - Промежуточная структура для декодинга JSON ответа ИИ
private struct RawAIQuestion: Codable {
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String?
    let verseRef: String?
}

// MARK: - Интеллектуальный Движок Генерации Викторины
@MainActor
final class QuizAIEngine {
    static let shared = QuizAIEngine()
    
    private init() {}
    
    /// Проверка: доступна ли генерация через ИИ (есть ли ключ или подписка)
    var isAIAvailable: Bool {
        let manager = BibleManager.shared
        let sub = SubscriptionManager.shared
        if sub.isPremium {
            return true
        }
        switch manager.activeProvider {
        case .gemini:
            return !manager.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .chatgpt:
            return !manager.openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .claude:
            return !manager.anthropicApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    /// Отображаемое название активного ИИ-провайдера с актуальной моделью
    var currentProviderDisplayName: String {
        let provider = BibleManager.shared.activeProvider
        return AIModelRegistry.shared.displayName(for: provider)
    }
    
    /// Генерация пула вопросов через активный ИИ-провайдер с учетом адаптивного дневника и каскадной защиты моделей
    func generateQuestions(
        category: QuizCategory,
        count: Int,
        language: AppLanguage
    ) async throws -> [QuizQuestion] {
        let manager = BibleManager.shared
        let provider = manager.activeProvider
        
        let apiKey: String
        switch provider {
        case .gemini:
            apiKey = manager.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .chatgpt:
            apiKey = manager.openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .claude:
            apiKey = manager.anthropicApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !apiKey.isEmpty || SubscriptionManager.shared.isPremium else {
            throw QuizAIError.missingApiKey
        }
        
        // Получаем адаптивную директиву из невидимого дневника со случайными якорями и запретами
        let adaptiveDirective = QuizAdaptiveDiary.shared.makeAdaptivePromptDirective(category: category, language: language)
        let prompt = buildPrompt(category: category, count: count, language: language, adaptiveDirective: adaptiveDirective)
        
        // Выполняем генерацию через реестр моделей с авто-фолбеком на проверенные модели
        let registry = AIModelRegistry.shared
        let systemPrompt = provider == .chatgpt ? "You are a helpful Bible quiz generator. You always return valid JSON array only." : nil
        let (rawContent, _) = try await registry.executeRequest(
            provider: provider,
            apiKey: apiKey,
            prompt: prompt,
            systemPrompt: systemPrompt,
            jsonMode: true,
            maxTokens: 4096
        )
        let providerName = registry.displayName(for: provider)
        
        let questions = try parseQuestions(from: rawContent, category: category, language: language, providerName: providerName)
        guard !questions.isEmpty else {
            throw QuizAIError.parsingFailed
        }
        
        // Мгновенная регистрация сгенерированного пула в адаптивном дневнике
        QuizAdaptiveDiary.shared.registerGeneratedBatch(questions: questions, language: language)
        
        return questions
    }
    
    // MARK: - Промпты для ИИ
    
    private func buildPrompt(category: QuizCategory, count: Int, language: AppLanguage, adaptiveDirective: String) -> String {
        let dynamicSeed = UUID().uuidString.prefix(8)
        let timestamp = Int(Date().timeIntervalSince1970)
        let categoryName: String
        let langName: String
        
        switch language {
        case .armenian:
            langName = "հայերեն (արևելահայերեն)"
            switch category {
            case .all: categoryName = "Ամբողջ Աստվածաշունչը (Հին և Նոր Կտակարաններ)"
            case .oldTestament: categoryName = "Հին Կտակարան"
            case .gospels: categoryName = "Չորս Ավետարանները (Մատթեոս, Մարկոս, Ղուկաս, Հովհաննես)"
            case .newTestament: categoryName = "Նոր Կտակարան (Գործք, Թղթեր, Հայտնություն)"
            case .churchHistory: categoryName = "Եկեղեցու պատմություն և Հայ Առաքելական Եկեղեցու սրբեր"
            case .verses: categoryName = "Հայտնի աստվածաշնչյան մեջբերումներ և համարներ"
            }
            
            return """
            Դու Աստվածաշնչի փորձագետ և աստվածաբան ես։
            Գեներացրու ճիշտ \(count) հատ բարձրորակ վիկտորինայի հարց «\(categoryName)» թեմայով \(langName) լեզվով։
            ՍԵՍԻԱՅԻ ԵԶԱԿԻ ԿՈԴ (Seed)՝ #\(dynamicSeed)-\(timestamp)։ Կազմիր բոլորովին նոր, չկրկնվող հարցեր։
            
            ԱԴԱՊՏԻՎ ՀՐԱՀԱՆԳ (անհատականություն օգտատիրոջ համար)՝
            \(adaptiveDirective)
            
            Յուրաքանչյուր հարց պետք է ունենա՝
            - question: հարցի հստակ և գրագետ տեքստը
            - options: ճիշտ 4 տարբերակ (զանգված), որոնցից միայն մեկն է ճիշտ
            - correctAnswerIndex: ճիշտ տարբերակի ինդեքսը (0, 1, 2 կամ 3)
            - explanation: 1-2 նախադասությամբ հոգևոր բացատրություն, թե ինչու է այդ պատասխանը ճիշտ
            - verseRef: աստվածաշնչյան հղում (օրինակ՝ «Մատթեոս 5:3» կամ «Սաղմոսներ 23:1»)
            
            ՊԱՏԱՍԽԱՆԸ ՏՈՒՐ ԽՍՏԻՎ ՄԻԱՅՆ JSON ՖՈՐՄԱՏՈՎ (առանց markdown ```json նշանների, առանց ավելորդ նախաբանի կամ վերջաբանի)՝
            [
              {
                "question": "...",
                "options": ["...", "...", "...", "..."],
                "correctAnswerIndex": 0,
                "explanation": "...",
                "verseRef": "..."
              }
            ]
            """
            
        case .russian:
            langName = "русский язык (Синодальный перевод)"
            switch category {
            case .all: categoryName = "Вся Библия (Ветхий и Новый Завет)"
            case .oldTestament: categoryName = "Ветхий Завет"
            case .gospels: categoryName = "Четыре Евангелия (Матфея, Марка, Луки, Иоанна)"
            case .newTestament: categoryName = "Новый Завет (Деяния, Послания, Откровение)"
            case .churchHistory: categoryName = "История Церкви, святые и апостолы"
            case .verses: categoryName = "Стихи и золотые цитаты из Священного Писания"
            }
            
            return """
            Ты признанный эксперт по Библии и богословию.
            Сгенерируй ровно \(count) качественных, интересных вопросов для библейской викторины по теме: «\(categoryName)» на \(langName).
            УНИКАЛЬНЫЙ СЕССИОННЫЙ КЛЮЧ (Seed): #\(dynamicSeed)-\(timestamp). Вопросы должны быть глубокими, оригинальными и не повторяться!
            
            АДАПТИВНАЯ ДИРЕКТИВА (персонализация под пользователя):
            \(adaptiveDirective)
            
            Требования к каждому вопросу:
            - question: ясный, глубокий и богословски точный вопрос
            - options: ровно 4 варианта ответа (массив строк), где только один вариант верен
            - correctAnswerIndex: целочисленный индекс правильного варианта (0, 1, 2 или 3)
            - explanation: емкое библейское объяснение на 1-2 предложения
            - verseRef: точная ссылка на книгу, главу и стих (например: «Матфея 5:3» или «Псалом 22:1»)
            
            ОТВЕТ ДОЛЖЕН БЫТЬ СТРОГО В ФОРМАТЕ JSON (без обертки ```json, без лишних приветствий):
            [
              {
                "question": "...",
                "options": ["...", "...", "...", "..."],
                "correctAnswerIndex": 0,
                "explanation": "...",
                "verseRef": "..."
              }
            ]
            """
            
        case .english:
            langName = "English (ESV/KJV)"
            switch category {
            case .all: categoryName = "Entire Bible (Old and New Testaments)"
            case .oldTestament: categoryName = "Old Testament"
            case .gospels: categoryName = "The Four Gospels (Matthew, Mark, Luke, John)"
            case .newTestament: categoryName = "New Testament (Acts, Epistles, Revelation)"
            case .churchHistory: categoryName = "Church History and Apostles"
            case .verses: categoryName = "Bible verses and quotes"
            }
            
            return """
            You are a renowned Bible scholar and theologian.
            Generate exactly \(count) high-quality Bible quiz questions on the topic of "\(categoryName)" in \(langName).
            UNIQUE SESSION SEED: #\(dynamicSeed)-\(timestamp). Ensure questions are 100% fresh, diverse and non-repetitive!
            
            ADAPTIVE DIRECTIVE:
            \(adaptiveDirective)
            
            Requirements for each question:
            - question: clear, accurate and meaningful question
            - options: exactly 4 answer options (array of strings), with only one correct answer
            - correctAnswerIndex: integer index of the correct answer (0, 1, 2, or 3)
            - explanation: 1-2 sentence biblical explanation
            - verseRef: scripture reference (e.g. "Matthew 5:3" or "Psalm 23:1")
            
            OUTPUT STRICTLY RAW JSON ONLY (no markdown ```json fences, no preamble):
            [
              {
                "question": "...",
                "options": ["...", "...", "...", "..."],
                "correctAnswerIndex": 0,
                "explanation": "...",
                "verseRef": "..."
              }
            ]
            """
        }
    }
    
    // MARK: - Сетевые вызовы к API (делегируются в AIModelRegistry с каскадной защитой)
    
    private func requestGemini(apiKey: String, prompt: String) async throws -> String {
        let (text, _) = try await AIModelRegistry.shared.executeRequest(provider: .gemini, apiKey: apiKey, prompt: prompt, jsonMode: true, maxTokens: 4096)
        return text
    }
    
    private func requestChatGPT(apiKey: String, prompt: String) async throws -> String {
        let (text, _) = try await AIModelRegistry.shared.executeRequest(provider: .chatgpt, apiKey: apiKey, prompt: prompt, systemPrompt: "You are a helpful Bible quiz generator. You always return valid JSON array only.", jsonMode: true, maxTokens: 4096)
        return text
    }
    
    private func requestClaude(apiKey: String, prompt: String) async throws -> String {
        let (text, _) = try await AIModelRegistry.shared.executeRequest(provider: .claude, apiKey: apiKey, prompt: prompt, jsonMode: false, maxTokens: 4096)
        return text
    }
    
    // MARK: - Парсинг и санитизация JSON
    
    private func parseQuestions(from rawText: String, category: QuizCategory, language: AppLanguage, providerName: String) throws -> [QuizQuestion] {
        var cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Убираем маркдаун обертки ```json и ```
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Если обернуто в объект {"questions": [...]}
        if cleaned.hasPrefix("{") {
            if let objData = cleaned.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: objData) as? [String: Any] {
                for key in ["questions", "items", "data", "quiz"] {
                    if let innerArray = dict[key] as? [[String: Any]],
                       let innerData = try? JSONSerialization.data(withJSONObject: innerArray) {
                        return try decodeRawQuestions(from: innerData, category: category, language: language, providerName: providerName)
                    }
                }
            }
        }
        
        // Находим границы JSON массива [...]
        guard let startIndex = cleaned.firstIndex(of: "["),
              let endIndex = cleaned.lastIndex(of: "]") else {
            throw QuizAIError.parsingFailed
        }
        
        let jsonArrayString = String(cleaned[startIndex...endIndex])
        guard let arrayData = jsonArrayString.data(using: .utf8) else {
            throw QuizAIError.parsingFailed
        }
        
        return try decodeRawQuestions(from: arrayData, category: category, language: language, providerName: providerName)
    }
    
    private func decodeRawQuestions(from data: Data, category: QuizCategory, language: AppLanguage, providerName: String) throws -> [QuizQuestion] {
        let rawQuestions = try JSONDecoder().decode([RawAIQuestion].self, from: data)
        guard !rawQuestions.isEmpty else {
            throw QuizAIError.emptyResponse
        }
        
        return rawQuestions.compactMap { raw in
            guard raw.options.count >= 4 else { return nil }
            let safeOptions = Array(raw.options.prefix(4))
            let safeIndex = (0..<4).contains(raw.correctAnswerIndex) ? raw.correctAnswerIndex : 0
            let explanation = raw.explanation ?? ""
            let verseRef = raw.verseRef ?? ""
            
            return QuizQuestion(
                category: category,
                difficulty: .medium,
                questionHy: raw.question,
                questionRu: raw.question,
                questionEn: raw.question,
                optionsHy: safeOptions,
                optionsRu: safeOptions,
                optionsEn: safeOptions,
                correctAnswerIndex: safeIndex,
                explanationHy: explanation,
                explanationRu: explanation,
                explanationEn: explanation,
                verseRefHy: verseRef,
                verseRefRu: verseRef,
                verseRefEn: verseRef,
                isAIGenerated: true,
                aiProviderName: providerName
            )
        }
    }
}
