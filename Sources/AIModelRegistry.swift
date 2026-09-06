import Foundation

// MARK: - Модели ИИ и каскадная система безопасности (Fail-Safe Fallback System)
// Архитектура по стандарту приложения Forma:
// 1. Иерархия моделей от новейших к стабильным.
// 2. Автоматический фолбек на резервные модели при ошибках 404 (Not Found), 400 (Bad Model) или 410 (Deprecated).
// 3. Фоновое обнаружение более новых моделей без задержек для пользователя (Zero User Latency).
// 4. Полная изоляция от сбоев — генерация не прерывается даже при закрытии API устаревших моделей.

public final class AIModelRegistry: @unchecked Sendable {
    public static let shared = AIModelRegistry()
    
    // MARK: - Иерархии моделей в порядке убывания новизны (Актуальность: 2026 год)
    
    public static let geminiHierarchy: [String] = [
        "gemini-2.5-flash",
        "gemini-2.0-flash",
        "gemini-1.5-flash",
        "gemini-1.5-pro"
    ]
    
    public static let openAIHierarchy: [String] = [
        "gpt-5-mini",
        "gpt-4.5-preview",
        "gpt-4o-mini",
        "gpt-4o",
        "gpt-3.5-turbo"
    ]
    
    public static let claudeHierarchy: [String] = [
        "claude-3-7-sonnet-latest",
        "claude-3-5-haiku-latest",
        "claude-3-5-sonnet-latest",
        "claude-3-5-haiku-20241022",
        "claude-3-haiku-20240307"
    ]
    
    // MARK: - Быстрая сессия для проверок и сетевых вызовов
    
    private static let fastSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25.0
        config.timeoutIntervalForResource = 35.0
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()
    
    // MARK: - Активные модели (сохраняются в UserDefaults)
    
    public var activeGeminiModel: String {
        get { UserDefaults.standard.string(forKey: "active_gemini_model") ?? "gemini-2.5-flash" }
        set { UserDefaults.standard.set(newValue, forKey: "active_gemini_model") }
    }
    
    public var activeOpenAIModel: String {
        get { UserDefaults.standard.string(forKey: "active_openai_model") ?? "gpt-4o-mini" }
        set { UserDefaults.standard.set(newValue, forKey: "active_openai_model") }
    }
    
    public var activeClaudeModel: String {
        get { UserDefaults.standard.string(forKey: "active_claude_model") ?? "claude-3-5-haiku-20241022" }
        set { UserDefaults.standard.set(newValue, forKey: "active_claude_model") }
    }
    
    private init() {
        // Фоновая тихая проверка при инициализации реестра
        discoverNewerModelsInBackground()
    }
    
    // MARK: - Получение активной модели и цепочки резерва
    
    public func activeModel(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return activeGeminiModel
        case .chatgpt: return activeOpenAIModel
        case .claude: return activeClaudeModel
        }
    }
    
    public func hierarchy(for provider: AIProvider) -> [String] {
        switch provider {
        case .gemini: return Self.geminiHierarchy
        case .chatgpt: return Self.openAIHierarchy
        case .claude: return Self.claudeHierarchy
        }
    }
    
    /// Кандидаты для выполнения запроса: сначала активная, затем резервные из иерархии
    public func candidateModels(for provider: AIProvider) -> [String] {
        let active = activeModel(for: provider)
        var list = [active]
        for m in hierarchy(for: provider) where !list.contains(m) {
            list.append(m)
        }
        return list
    }
    
    /// Красивое читаемое название текущей модели для UI
    public func displayName(for provider: AIProvider) -> String {
        let current = activeModel(for: provider)
        switch provider {
        case .gemini:
            if current.contains("2.5") { return "Gemini 2.5 Flash" }
            if current.contains("2.0") { return "Gemini 2.0 Flash" }
            if current.contains("pro") { return "Gemini 1.5 Pro" }
            return "Gemini 1.5 Flash"
            
        case .chatgpt:
            if current.contains("5-mini") { return "GPT-5 mini" }
            if current.contains("4.5") { return "GPT-4.5" }
            if current.contains("mini") { return "GPT-4o mini" }
            if current.contains("4o") { return "GPT-4o" }
            return "ChatGPT"
            
        case .claude:
            if current.contains("3-7") { return "Claude 3.7 Sonnet" }
            if current.contains("sonnet") { return "Claude 3.5 Sonnet" }
            return "Claude 3.5 Haiku"
        }
    }
    
    // MARK: - Универсальное выполнение запроса с каскадным переключением (Fail-Safe Fallback)
    
    /// Выполняет запрос к ИИ. Если основная модель возвращает ошибку несовместимости/доступности (404/400/410/429),
    /// код автоматически переходит к следующей резервной модели из списка.
    public func executeRequest(
        provider: AIProvider,
        apiKey: String,
        prompt: String,
        systemPrompt: String? = nil,
        jsonMode: Bool = false,
        maxTokens: Int = 1024
    ) async throws -> (text: String, usedModel: String) {
        let modelsToTry = candidateModels(for: provider)
        var lastError: Error?
        
        for modelName in modelsToTry {
            do {
                let text: String
                switch provider {
                case .gemini:
                    text = try await requestGemini(model: modelName, apiKey: apiKey, prompt: prompt, jsonMode: jsonMode)
                case .chatgpt:
                    text = try await requestChatGPT(model: modelName, apiKey: apiKey, prompt: prompt, systemPrompt: systemPrompt, jsonMode: jsonMode, maxTokens: maxTokens)
                case .claude:
                    text = try await requestClaude(model: modelName, apiKey: apiKey, prompt: prompt, systemPrompt: systemPrompt, maxTokens: maxTokens)
                }
                
                // Если успешно ответила другая модель из цепочки — запоминаем её как стабильную активную
                if modelName != activeModel(for: provider) {
                    saveActiveModel(modelName, for: provider)
                    print("[AI Fallback] ⚡ Переключено на стабильную модель: \(modelName)")
                }
                
                return (text, modelName)
            } catch {
                lastError = error
                print("[AI Fallback] ⚠️ Модель \(modelName) вернула ошибку: \(error.localizedDescription). Пробуем резервную...")
                continue
            }
        }
        
        throw lastError ?? NSError(domain: "AIModelRegistry", code: 500, userInfo: [NSLocalizedDescriptionKey: "Все резервные модели недоступны."])
    }
    
    // MARK: - Сетевые методы по провайдерам
    
    private func requestGemini(model: String, apiKey: String, prompt: String, jsonMode: Bool) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw NSError(domain: "AIModelRegistry", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Gemini URL"])
        }
        
        var genConfig: [String: Any] = [
            "temperature": 0.85
        ]
        if jsonMode {
            genConfig["responseMimeType"] = "application/json"
        }
        
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": genConfig
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = jsonData
        req.timeoutInterval = 25.0
        
        let (data, response) = try await Self.fastSession.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "Gemini", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Gemini Error (\(http.statusCode)): \(msg)"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "Gemini", code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty Gemini Response"])
        }
        return text
    }
    
    private func requestChatGPT(model: String, apiKey: String, prompt: String, systemPrompt: String?, jsonMode: Bool, maxTokens: Int) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "AIModelRegistry", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI URL"])
        }
        
        var messages: [[String: String]] = []
        if let sys = systemPrompt, !sys.isEmpty {
            messages.append(["role": "system", "content": sys])
        }
        messages.append(["role": "user", "content": prompt])
        
        var body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTokens,
            "temperature": 0.85
        ]
        if jsonMode {
            body["response_format"] = ["type": "json_object"]
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = jsonData
        req.timeoutInterval = 25.0
        
        let (data, response) = try await Self.fastSession.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "OpenAI Error (\(http.statusCode)): \(msg)"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw NSError(domain: "OpenAI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty OpenAI Response"])
        }
        return text
    }
    
    private func requestClaude(model: String, apiKey: String, prompt: String, systemPrompt: String?, maxTokens: Int) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw NSError(domain: "AIModelRegistry", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Claude URL"])
        }
        
        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": 0.85,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        if let sys = systemPrompt, !sys.isEmpty {
            body["system"] = sys
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = jsonData
        req.timeoutInterval = 25.0
        
        let (data, response) = try await Self.fastSession.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "Claude", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Claude Error (\(http.statusCode)): \(msg)"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArr = json["content"] as? [[String: Any]],
              let firstContent = contentArr.first,
              let text = firstContent["text"] as? String else {
            throw NSError(domain: "Claude", code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty Claude Response"])
        }
        return text
    }
    
    // MARK: - Фоновое обнаружение и тестирование моделей (Zero User Latency)
    
    /// Тихий запуск фоновой проверки новых моделей
    public func discoverNewerModelsInBackground(force: Bool = false) {
        let defaults = UserDefaults.standard
        let lastProbe = defaults.double(forKey: "last_ai_model_probe_time")
        let now = Date().timeIntervalSince1970
        
        // Проверяем раз в 12 часов, если не вызвано принудительно
        if !force && (now - lastProbe) < 43200 {
            return
        }
        defaults.set(now, forKey: "last_ai_model_probe_time")
        
        Task(priority: .utility) {
            _ = await performModelDiscovery()
        }
    }
    
    /// Проверяет наличие доступных более новых моделей и автоматически повышает активную модель
    @discardableResult
    public func performModelDiscovery() async -> [String: String] {
        let defaults = UserDefaults.standard
        let geminiKey = (defaults.string(forKey: "gemini_api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let openAIKey = (defaults.string(forKey: "openai_api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let claudeKey = (defaults.string(forKey: "anthropic_api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        var upgraded: [String: String] = [:]
        
        // 1. Проверяем Gemini модели сверху вниз
        if !geminiKey.isEmpty {
            for modelName in Self.geminiHierarchy {
                if await testGeminiModel(name: modelName, apiKey: geminiKey) {
                    if self.activeGeminiModel != modelName {
                        self.activeGeminiModel = modelName
                        upgraded["Gemini"] = modelName
                        print("[AI Auto-Upgrade] 🎉 Gemini переключен на новую доступную модель: \(modelName)")
                    }
                    break
                }
            }
        }
        
        // 2. Проверяем OpenAI модели сверху вниз
        if !openAIKey.isEmpty {
            for modelName in Self.openAIHierarchy {
                if await testOpenAIModel(name: modelName, apiKey: openAIKey) {
                    if self.activeOpenAIModel != modelName {
                        self.activeOpenAIModel = modelName
                        upgraded["ChatGPT"] = modelName
                        print("[AI Auto-Upgrade] 🎉 OpenAI переключен на новую доступную модель: \(modelName)")
                    }
                    break
                }
            }
        }
        
        // 3. Проверяем Claude модели сверху вниз
        if !claudeKey.isEmpty {
            for modelName in Self.claudeHierarchy {
                if await testClaudeModel(name: modelName, apiKey: claudeKey) {
                    if self.activeClaudeModel != modelName {
                        self.activeClaudeModel = modelName
                        upgraded["Claude"] = modelName
                        print("[AI Auto-Upgrade] 🎉 Claude переключен на новую доступную модель: \(modelName)")
                    }
                    break
                }
            }
        }
        
        return upgraded
    }
    
    // MARK: - Пинг-тесты моделей
    
    public func testGeminiModel(name: String, apiKey: String) async -> Bool {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(name):generateContent?key=\(apiKey)") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 8.0
        let body: [String: Any] = [
            "contents": [["parts": [["text": "ping"]]]]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return false }
        req.httpBody = data
        guard let (_, response) = try? await Self.fastSession.data(for: req),
              let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }
    
    public func testOpenAIModel(name: String, apiKey: String) async -> Bool {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 8.0
        let body: [String: Any] = [
            "model": name,
            "messages": [["role": "user", "content": "ping"]],
            "max_tokens": 5
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return false }
        req.httpBody = data
        guard let (_, response) = try? await Self.fastSession.data(for: req),
              let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }
    
    public func testClaudeModel(name: String, apiKey: String) async -> Bool {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.timeoutInterval = 8.0
        let body: [String: Any] = [
            "model": name,
            "max_tokens": 5,
            "messages": [["role": "user", "content": "ping"]]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return false }
        req.httpBody = data
        guard let (_, response) = try? await Self.fastSession.data(for: req),
              let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }
    
    // MARK: - Сохранение и сброс
    
    public func saveActiveModel(_ model: String, for provider: AIProvider) {
        let cleaned = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        switch provider {
        case .gemini: activeGeminiModel = cleaned
        case .chatgpt: activeOpenAIModel = cleaned
        case .claude: activeClaudeModel = cleaned
        }
    }
    
    public func resetToDefaults() {
        activeGeminiModel = "gemini-2.0-flash"
        activeOpenAIModel = "gpt-4o-mini"
        activeClaudeModel = "claude-3-5-haiku-20241022"
    }
}
