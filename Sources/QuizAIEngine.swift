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

// MARK: - Промежуточная структура для декодинга JSON ответа ИИ (максимальная толерантность к типам)
private struct RawAIQuestion: Decodable {
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String?
    let verseRef: String?
    
    enum CodingKeys: String, CodingKey {
        case question, options, explanation, verseRef
        case correctAnswerIndex
        case correct_answer_index, answerIndex, answer_index, correct
        case ref, verse_ref
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.question = try container.decode(String.self, forKey: .question)
        
        // Варианты ответов: массив строк или словарь {"A": "...", "B": "..."}
        if let optsArray = try? container.decode([String].self, forKey: .options) {
            self.options = optsArray
        } else if let optsDict = try? container.decode([String: String].self, forKey: .options) {
            let sortedKeys = optsDict.keys.sorted()
            self.options = sortedKeys.compactMap { optsDict[$0] }
        } else {
            self.options = []
        }
        
        // Индекс правильного ответа: число или строка ("0", "1")
        var parsedIndex: Int? = nil
        if let intVal = try? container.decode(Int.self, forKey: .correctAnswerIndex) {
            parsedIndex = intVal
        } else if let intVal = try? container.decode(Int.self, forKey: .correct_answer_index) {
            parsedIndex = intVal
        } else if let intVal = try? container.decode(Int.self, forKey: .answerIndex) {
            parsedIndex = intVal
        } else if let intVal = try? container.decode(Int.self, forKey: .answer_index) {
            parsedIndex = intVal
        } else if let intVal = try? container.decode(Int.self, forKey: .correct) {
            parsedIndex = intVal
        } else if let strVal = try? container.decode(String.self, forKey: .correctAnswerIndex) {
            parsedIndex = Int(strVal.trimmingCharacters(in: .whitespacesAndNewlines))
        } else if let strVal = try? container.decode(String.self, forKey: .correct_answer_index) {
            parsedIndex = Int(strVal.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        self.correctAnswerIndex = parsedIndex ?? 0
        
        self.explanation = try? container.decodeIfPresent(String.self, forKey: .explanation)
        self.verseRef = (try? container.decodeIfPresent(String.self, forKey: .verseRef)) ??
                        (try? container.decodeIfPresent(String.self, forKey: .verse_ref)) ??
                        (try? container.decodeIfPresent(String.self, forKey: .ref))
    }
}

// MARK: - Интеллектуальный Движок Генерации Викторины
@MainActor
final class QuizAIEngine {
    static let shared = QuizAIEngine()
    
    private init() {}
    
    /// Проверка: доступна ли генерация через ИИ (требуется введенный API-ключ активного провайдера)
    var isAIAvailable: Bool {
        let manager = BibleManager.shared
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
        
        guard !apiKey.isEmpty else {
            throw QuizAIError.missingApiKey
        }
        
        // Получаем адаптивную директиву из невидимого дневника со случайными якорями и запретами
        let adaptiveDirective = QuizAdaptiveDiary.shared.makeAdaptivePromptDirective(category: category, language: language)
        let prompt = buildPrompt(category: category, count: count, language: language, adaptiveDirective: adaptiveDirective)
        
        // Выполняем генерацию через реестр моделей с авто-фолбеком на проверенные модели
        let registry = AIModelRegistry.shared
        let systemPrompt = "You are an expert Bible quiz generator. Always respond strictly with a valid JSON object containing a 'questions' array."
        
        let questions: [QuizQuestion]
        do {
            let (rawContent, _) = try await registry.executeRequest(
                provider: provider,
                apiKey: apiKey,
                prompt: prompt,
                systemPrompt: systemPrompt,
                jsonMode: true,
                maxTokens: 4096
            )
            let providerName = registry.displayName(for: provider)
            let parsed = parseQuestions(from: rawContent, category: category, language: language, providerName: providerName)
            if !parsed.isEmpty {
                var finalPool = parsed
                if finalPool.count < count {
                    let needed = count - finalPool.count
                    let extras = BibleQuizGenerator.shared.fetchQuestions(category: category, count: needed)
                    finalPool.append(contentsOf: extras)
                }
                questions = Array(finalPool.prefix(count))
            } else {
                questions = BibleQuizGenerator.shared.fetchQuestions(category: category, count: count)
            }
        } catch {
            print("[QuizAIEngine] ⚠️ ИИ вернул ошибку: \(error.localizedDescription). Запуск проверенной оффлайн базы.")
            questions = BibleQuizGenerator.shared.fetchQuestions(category: category, count: count)
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
            
            ՊԱՏԱՍԽԱՆԸ ՏՈՒՐ ԽՍՏԻՎ ՄԻԱՅՆ JSON ՕԲՅԵԿՏԻ ՏԵՍՔՈՎ (առանց markdown ```json նշանների)՝
            {
              "questions": [
                {
                  "question": "...",
                  "options": ["...", "...", "...", "..."],
                  "correctAnswerIndex": 0,
                  "explanation": "...",
                  "verseRef": "..."
                }
              ]
            }
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
            
            ОТВЕТ ДОЛЖЕН БЫТЬ СТРОГО В ВИДЕ JSON ОБЪЕКТА (без обертки ```json, без лишних приветствий):
            {
              "questions": [
                {
                  "question": "...",
                  "options": ["...", "...", "...", "..."],
                  "correctAnswerIndex": 0,
                  "explanation": "...",
                  "verseRef": "..."
                }
              ]
            }
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
            
            OUTPUT STRICTLY A VALID JSON OBJECT ONLY (no markdown ```json fences, no preamble):
            {
              "questions": [
                {
                  "question": "...",
                  "options": ["...", "...", "...", "..."],
                  "correctAnswerIndex": 0,
                  "explanation": "...",
                  "verseRef": "..."
                }
              ]
            }
            """
        }
    }
    
    // MARK: - Парсинг и санитизация JSON
    
    private func parseQuestions(from rawText: String, category: QuizCategory, language: AppLanguage, providerName: String) -> [QuizQuestion] {
        var cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Очистка от Markdown-тегов
        if let jsonBlockStart = cleaned.range(of: "```json") {
            cleaned = String(cleaned[jsonBlockStart.upperBound...])
        } else if let blockStart = cleaned.range(of: "```") {
            cleaned = String(cleaned[blockStart.upperBound...])
        }
        if let blockEnd = cleaned.range(of: "```") {
            cleaned = String(cleaned[..<blockEnd.lowerBound])
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. Стратегия А: Попытка распарсить JSON-объект: {"questions": [...]}
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}"),
           firstBrace < lastBrace {
            let jsonString = String(cleaned[firstBrace...lastBrace])
            if let objData = jsonString.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: objData) as? [String: Any] {
                for key in ["questions", "items", "data", "quiz", "result", "results", "list", "հարցեր", "вопросы"] {
                    if let innerArray = dict[key] as? [[String: Any]] {
                        let decoded = decodeQuestionsFromDictionaries(innerArray, category: category, language: language, providerName: providerName)
                        if !decoded.isEmpty { return decoded }
                    }
                }
                for (_, value) in dict {
                    if let innerArray = value as? [[String: Any]] {
                        let decoded = decodeQuestionsFromDictionaries(innerArray, category: category, language: language, providerName: providerName)
                        if !decoded.isEmpty { return decoded }
                    }
                }
            }
        }
        
        // 3. Стратегия Б: Попытка распарсить как JSON-массив: [...]
        if let firstBracket = cleaned.firstIndex(of: "["),
           let lastBracket = cleaned.lastIndex(of: "]"),
           firstBracket < lastBracket {
            let jsonArrayString = String(cleaned[firstBracket...lastBracket])
            if let arrayData = jsonArrayString.data(using: .utf8),
               let array = try? JSONSerialization.jsonObject(with: arrayData) as? [[String: Any]] {
                let decoded = decodeQuestionsFromDictionaries(array, category: category, language: language, providerName: providerName)
                if !decoded.isEmpty { return decoded }
            }
        }
        
        // 4. Стратегия В: Если JSON оборван на полпути по токенам, пробуем закрыть массив
        if let firstBracket = cleaned.firstIndex(of: "["),
           let lastBrace = cleaned.lastIndex(of: "}") {
            let truncated = String(cleaned[firstBracket...lastBrace]) + "\n]"
            if let arrayData = truncated.data(using: .utf8),
               let array = try? JSONSerialization.jsonObject(with: arrayData) as? [[String: Any]] {
                let decoded = decodeQuestionsFromDictionaries(array, category: category, language: language, providerName: providerName)
                if !decoded.isEmpty { return decoded }
            }
        }
        
        return []
    }
    
    private func decodeQuestionsFromDictionaries(_ dicts: [[String: Any]], category: QuizCategory, language: AppLanguage, providerName: String) -> [QuizQuestion] {
        var result: [QuizQuestion] = []
        for dict in dicts {
            guard let qText = (dict["question"] as? String ??
                               dict["q"] as? String ??
                               dict["text"] as? String ??
                               dict["title"] as? String ??
                               dict["prompt"] as? String ??
                               dict["հարց"] as? String),
                  !qText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }
            
            var rawOptions: [String] = []
            if let opts = dict["options"] as? [String] {
                rawOptions = opts
            } else if let opts = dict["choices"] as? [String] {
                rawOptions = opts
            } else if let opts = dict["answers"] as? [String] {
                rawOptions = opts
            } else if let opts = dict["variants"] as? [String] {
                rawOptions = opts
            } else if let opts = dict["տարբերակներ"] as? [String] {
                rawOptions = opts
            } else if let optsDict = dict["options"] as? [String: String] {
                let sortedKeys = optsDict.keys.sorted()
                rawOptions = sortedKeys.compactMap { optsDict[$0] }
            }
            
            var finalOptions = rawOptions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            if finalOptions.count < 4 {
                let defaults = ["Այո", "Ոչ", "Հայտնի չէ", "Բոլորը"]
                for d in defaults where !finalOptions.contains(d) && finalOptions.count < 4 {
                    finalOptions.append(d)
                }
            }
            finalOptions = Array(finalOptions.prefix(4))
            guard finalOptions.count == 4 else { continue }
            
            var correctIdx = 0
            if let num = dict["correctAnswerIndex"] as? Int ??
                         dict["correct_answer_index"] as? Int ??
                         dict["answerIndex"] as? Int ??
                         dict["correct"] as? Int ??
                         dict["answer"] as? Int {
                correctIdx = num
            } else if let str = dict["correctAnswerIndex"] as? String ??
                                dict["correct_answer_index"] as? String ??
                                dict["answer"] as? String {
                let cleanStr = str.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                if cleanStr == "A" { correctIdx = 0 }
                else if cleanStr == "B" { correctIdx = 1 }
                else if cleanStr == "C" { correctIdx = 2 }
                else if cleanStr == "D" { correctIdx = 3 }
                else if let parsed = Int(cleanStr) {
                    correctIdx = parsed >= 1 && parsed <= 4 ? parsed - 1 : parsed
                } else if let foundIndex = finalOptions.firstIndex(where: { $0.caseInsensitiveCompare(str) == .orderedSame }) {
                    correctIdx = foundIndex
                }
            }
            if correctIdx < 0 || correctIdx >= 4 { correctIdx = 0 }
            
            let explanation = (dict["explanation"] as? String ?? dict["exp"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let verseRef = (dict["verseRef"] as? String ?? dict["ref"] as? String ?? dict["verse_ref"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            result.append(QuizQuestion(
                category: category,
                difficulty: .medium,
                questionHy: qText,
                questionRu: qText,
                questionEn: qText,
                optionsHy: finalOptions,
                optionsRu: finalOptions,
                optionsEn: finalOptions,
                correctAnswerIndex: correctIdx,
                explanationHy: explanation,
                explanationRu: explanation,
                explanationEn: explanation,
                verseRefHy: verseRef,
                verseRefRu: verseRef,
                verseRefEn: verseRef,
                isAIGenerated: true,
                aiProviderName: providerName
            ))
        }
        return result
    }
}
