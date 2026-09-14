import Foundation

// MARK: - Модели ИИ и каскадная система безопасности (Fail-Safe Fallback System)
// Архитектура по стандарту приложения Forma:
// 1. Иерархия моделей от новейших к стабильным.
// 2. Автоматический фолбек на резервные модели при ошибках 404 (Not Found), 400 (Bad Model) или 410 (Deprecated).
// 3. Фоновое обнаружение более новых моделей без задержек для пользователя (Zero User Latency).
// 4. Полная изоляция от сбоев — генерация не прерывается даже при закрытии API устаревших моделей.

final class AIModelRegistry: @unchecked Sendable {
    static let shared = AIModelRegistry()
    
    // MARK: - Иерархии моделей в порядке убывания новизны (Актуальность: 2026 год)
    
    static let geminiHierarchy: [String] = [
        "gemini-3.5-flash-lite",
        "gemini-3.5-flash",
        "gemini-2.5-flash",
        "gemini-2.5-pro"
    ]
    
    static let openAIHierarchy: [String] = [
        "gpt-4o-mini",
        "gpt-4o",
        "gpt-3.5-turbo"
    ]
    
    static let claudeHierarchy: [String] = [
        "claude-3-7-sonnet-latest",
        "claude-3-5-sonnet-latest",
        "claude-3-5-haiku-latest",
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
    
    var activeGeminiModel: String {
        get {
            let stored = UserDefaults.standard.string(forKey: "active_gemini_model") ?? "gemini-3.5-flash-lite"
            if stored.contains("1.5") || stored.contains("2.0") || !Self.geminiHierarchy.contains(stored) {
                return "gemini-3.5-flash-lite"
            }
            return stored
        }
        set { UserDefaults.standard.set(newValue, forKey: "active_gemini_model") }
    }
    
    var activeOpenAIModel: String {
        get { UserDefaults.standard.string(forKey: "active_openai_model") ?? "gpt-4o-mini" }
        set { UserDefaults.standard.set(newValue, forKey: "active_openai_model") }
    }
    
    var activeClaudeModel: String {
        get { UserDefaults.standard.string(forKey: "active_claude_model") ?? "claude-3-5-haiku-20241022" }
        set { UserDefaults.standard.set(newValue, forKey: "active_claude_model") }
    }
    
    private init() {
        // Очищаем устаревший или недопустимый кэш моделей
        let defaults = UserDefaults.standard
        if let storedGemini = defaults.string(forKey: "active_gemini_model"),
           storedGemini.contains("1.5") || storedGemini.contains("2.0") || !Self.geminiHierarchy.contains(storedGemini) {
            defaults.set("gemini-3.5-flash-lite", forKey: "active_gemini_model")
        }
        // Фоновая тихая проверка при инициализации реестра
        discoverNewerModelsInBackground()
    }
    
    // MARK: - Получение активной модели и цепочки резерва
    
    func activeModel(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return activeGeminiModel
        case .chatgpt: return activeOpenAIModel
        case .claude: return activeClaudeModel
        }
    }
    
    func hierarchy(for provider: AIProvider) -> [String] {
        switch provider {
        case .gemini: return Self.geminiHierarchy
        case .chatgpt: return Self.openAIHierarchy
        case .claude: return Self.claudeHierarchy
        }
    }
    
    /// Кандидаты для выполнения запроса: сначала активная, затем резервные из иерархии
    func candidateModels(for provider: AIProvider) -> [String] {
        let active = activeModel(for: provider)
        var list = [active]
        for m in hierarchy(for: provider) where !list.contains(m) {
            list.append(m)
        }
        return list
    }
    
    /// Красивое читаемое название текущей модели для UI
    func displayName(for provider: AIProvider) -> String {
        let current = activeModel(for: provider)
        switch provider {
        case .gemini:
            let parts = current.split(separator: "-")
            if parts.count >= 2 {
                let ver = parts[1]
                let suffix = current.contains("flash") ? " Flash" : (current.contains("pro") ? " Pro" : "")
                return "Gemini \(ver)\(suffix)"
            }
            return "Gemini Flash"
            
        case .chatgpt:
            if current.hasPrefix("gpt-") {
                return current.replacingOccurrences(of: "gpt-", with: "GPT-")
            } else if current.hasPrefix("o") {
                return current.uppercased()
            }
            return "ChatGPT"
            
        case .claude:
            if current.contains("3-7") { return "Claude 3.7 Sonnet" }
            if current.contains("sonnet") { return "Claude 3.5 Sonnet" }
            return "Claude 3.5 Haiku"
        }
    }
    
    // MARK: - Универсальное выполнение запроса с каскадным переключением (Fail-Safe Fallback)
    
    /// Выполняет запрос к ИИ. Если основная модель возвращает ошибку несовместимости/доступности (404/400/410/429),
    /// код автоматически переходит к следующей резервной модели из списка, парсит рекомендации Google из 404
    /// или запрашивает актуальный список доступных моделей с сервера.
    func executeRequest(
        provider: AIProvider,
        apiKey: String,
        prompt: String,
        systemPrompt: String? = nil,
        jsonMode: Bool = false,
        maxTokens: Int = 1024
    ) async throws -> (text: String, usedModel: String) {
        var modelsToTry = candidateModels(for: provider)
        var lastError: Error?
        var attemptErrors: [String] = []
        var triedModels = Set<String>()
        
        var index = 0
        while index < modelsToTry.count {
            let modelName = modelsToTry[index]
            index += 1
            if triedModels.contains(modelName) { continue }
            triedModels.insert(modelName)
            
            do {
                let text: String
                switch provider {
                case .gemini:
                    text = try await requestGemini(model: modelName, apiKey: apiKey, prompt: prompt, systemPrompt: systemPrompt, jsonMode: jsonMode, maxTokens: maxTokens)
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
                attemptErrors.append("\(modelName): \(error.localizedDescription)")
                print("[AI Fallback] ⚠️ Модель \(modelName) вернула ошибку: \(error.localizedDescription). Пробуем резервную...")
                
                // САМОВОССТАНОВЛЕНИЕ: Если Google вернул рекомендацию использовать модель в тексте ошибки 404/410/400
                if provider == .gemini {
                    let errStr = error.localizedDescription
                    if let range = errStr.range(of: "models/gemini-") {
                        let sub = errStr[range.upperBound...]
                        let modelId = "gemini-" + sub.prefix(while: { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." })
                        let trimmedModel = String(modelId).trimmingCharacters(in: CharacterSet(charactersIn: " .,;\"'()"))
                        if !trimmedModel.isEmpty && !triedModels.contains(trimmedModel) && !modelsToTry.contains(trimmedModel) {
                            print("[AI Self-Healing] 🤖 Google порекомендовал использовать модель: \(trimmedModel). Добавляем в очередь!")
                            modelsToTry.insert(trimmedModel, at: index)
                        }
                    }
                }
                continue
            }
        }
        
        // Резервный рубеж: если все жестко заданные модели вернули ошибку, запрашиваем список живых моделей с серверов Google
        if provider == .gemini {
            let remoteModels = await fetchRemoteGeminiModels(apiKey: apiKey)
            for remoteModel in remoteModels {
                if !triedModels.contains(remoteModel) {
                    triedModels.insert(remoteModel)
                    print("[AI Fallback] 🔍 Пробуем удаленно обнаруженную модель: \(remoteModel)")
                    if let text = try? await requestGemini(model: remoteModel, apiKey: apiKey, prompt: prompt, systemPrompt: systemPrompt, jsonMode: jsonMode, maxTokens: maxTokens) {
                        saveActiveModel(remoteModel, for: .gemini)
                        print("[AI Fallback] ⚡ Успех с удаленной моделью: \(remoteModel)")
                        return (text, remoteModel)
                    }
                }
            }
        }
        
        let detailedMsg = attemptErrors.isEmpty ? "Все резервные модели недоступны." : attemptErrors.joined(separator: "\n")
        throw lastError ?? NSError(domain: "AIModelRegistry", code: 500, userInfo: [NSLocalizedDescriptionKey: detailedMsg])
    }
    
    // MARK: - Сетевые методы по провайдерам
    
    private func requestGemini(model: String, apiKey: String, prompt: String, systemPrompt: String? = nil, jsonMode: Bool, maxTokens: Int = 2048) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw NSError(domain: "AIModelRegistry", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Gemini URL"])
        }
        
        var genConfig: [String: Any] = [
            "temperature": 0.85,
            "maxOutputTokens": maxTokens
        ]
        if jsonMode {
            genConfig["responseMimeType"] = "application/json"
        }
        
        var body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": genConfig
        ]
        
        if let sys = systemPrompt, !sys.isEmpty {
            body["system_instruction"] = [
                "parts": [["text": sys]]
            ]
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
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
    func discoverNewerModelsInBackground(force: Bool = false) {
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
    func performModelDiscovery() async -> [String: String] {
        let defaults = UserDefaults.standard
        let geminiKey = (defaults.string(forKey: "gemini_api_key_secure") ?? defaults.string(forKey: "gemini_api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let openAIKey = (defaults.string(forKey: "openai_api_key_secure") ?? defaults.string(forKey: "openai_api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let claudeKey = (defaults.string(forKey: "anthropic_api_key_secure") ?? defaults.string(forKey: "anthropic_api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        var upgraded: [String: String] = [:]
        
        // 1. Проверяем Gemini модели (сначала опрос удаленного API ListModels, затем иерархия)
        if !geminiKey.isEmpty {
            let remoteModels = await fetchRemoteGeminiModels(apiKey: geminiKey)
            var candidates = remoteModels
            for h in Self.geminiHierarchy where !candidates.contains(h) {
                candidates.append(h)
            }
            for modelName in candidates {
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
        
        // 2. Проверяем OpenAI модели (сначала удаленный API ListModels, затем иерархия)
        if !openAIKey.isEmpty {
            let remoteModels = await fetchRemoteOpenAIModels(apiKey: openAIKey)
            var candidates = remoteModels
            for h in Self.openAIHierarchy where !candidates.contains(h) {
                candidates.append(h)
            }
            for modelName in candidates {
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
    
    /// Точечное обнаружение и обновление моделей для конкретного выбранного провайдера
    @discardableResult
    func updateModels(for provider: AIProvider) async -> (success: Bool, modelName: String, message: String) {
        let defaults = UserDefaults.standard
        let apiKey: String
        switch provider {
        case .gemini:
            apiKey = (defaults.string(forKey: "gemini_api_key_secure") ?? defaults.string(forKey: "gemini_api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .chatgpt:
            apiKey = (defaults.string(forKey: "openai_api_key_secure") ?? defaults.string(forKey: "openai_api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .claude:
            apiKey = (defaults.string(forKey: "anthropic_api_key_secure") ?? defaults.string(forKey: "anthropic_api_key") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !apiKey.isEmpty else {
            return (false, activeModel(for: provider), "api_key_required_hint")
        }
        
        switch provider {
        case .gemini:
            let remote = await fetchRemoteGeminiModels(apiKey: apiKey)
            var candidates = remote
            for h in Self.geminiHierarchy where !candidates.contains(h) {
                candidates.append(h)
            }
            for m in candidates {
                if await testGeminiModel(name: m, apiKey: apiKey) {
                    self.activeGeminiModel = m
                    return (true, displayName(for: .gemini), "models_updated_ok")
                }
            }
            self.activeGeminiModel = "gemini-3.5-flash-lite"
            return (false, displayName(for: .gemini), "model_fallback_applied")
            
        case .chatgpt:
            let remote = await fetchRemoteOpenAIModels(apiKey: apiKey)
            var candidates = remote
            for h in Self.openAIHierarchy where !candidates.contains(h) {
                candidates.append(h)
            }
            for m in candidates {
                if await testOpenAIModel(name: m, apiKey: apiKey) {
                    self.activeOpenAIModel = m
                    return (true, displayName(for: .chatgpt), "models_updated_ok")
                }
            }
            return (false, displayName(for: .chatgpt), "model_fallback_applied")
            
        case .claude:
            let remote = await fetchRemoteClaudeModels(apiKey: apiKey)
            var candidates = remote
            for h in Self.claudeHierarchy where !candidates.contains(h) {
                candidates.append(h)
            }
            for m in candidates {
                if await testClaudeModel(name: m, apiKey: apiKey) {
                    self.activeClaudeModel = m
                    return (true, displayName(for: .claude), "models_updated_ok")
                }
            }
            return (false, displayName(for: .claude), "model_fallback_applied")
        }
    }
    
    // MARK: - Удаленное динамическое обнаружение (ListModels)
    
    private func fetchRemoteGeminiModels(apiKey: String) async -> [String] {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)") else { return [] }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        req.timeoutInterval = 8.0
        
        guard let (data, response) = try? await Self.fastSession.data(for: req),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["models"] as? [[String: Any]] else {
            return []
        }
        
        var found: [String] = []
        for item in list {
            guard let rawName = item["name"] as? String else { continue }
            let name = rawName.replacingOccurrences(of: "models/", with: "")
            let methods = item["supportedGenerationMethods"] as? [String] ?? []
            if methods.contains("generateContent") && name.contains("gemini") {
                let excluded = ["embedding", "aqa", "imagen", "bison", "gecko"]
                if !excluded.contains(where: { name.contains($0) }) {
                    found.append(name)
                }
            }
        }
        
        return sortGeminiModels(found)
    }
    
    private func fetchRemoteOpenAIModels(apiKey: String) async -> [String] {
        guard let url = URL(string: "https://api.openai.com/v1/models") else { return [] }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 8.0
        
        guard let (data, response) = try? await Self.fastSession.data(for: req),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["data"] as? [[String: Any]] else {
            return []
        }
        
        var found: [String] = []
        for item in list {
            guard let mid = item["id"] as? String else { continue }
            if mid.hasPrefix("gpt-") || mid.hasPrefix("o1") || mid.hasPrefix("o3") || mid.hasPrefix("o4") {
                let excluded = ["audio", "realtime", "transcribe", "tts", "search", "vision-preview"]
                if !excluded.contains(where: { mid.contains($0) }) {
                    found.append(mid)
                }
            }
        }
        return sortOpenAIModels(found)
    }
    
    private func sortGeminiModels(_ models: [String]) -> [String] {
        return models.sorted { m1, m2 in
            let v1 = parseVersion(m1)
            let v2 = parseVersion(m2)
            if v1.0 != v2.0 { return v1.0 > v2.0 }
            if v1.1 != v2.1 { return v1.1 > v2.1 }
            let s1 = m1.contains("flash") && !m1.contains("lite") ? 3 : (m1.contains("pro") ? 2 : 1)
            let s2 = m2.contains("flash") && !m2.contains("lite") ? 3 : (m2.contains("pro") ? 2 : 1)
            return s1 > s2
        }
    }
    
    private func sortOpenAIModels(_ models: [String]) -> [String] {
        return models.sorted { m1, m2 in
            let v1 = parseVersion(m1)
            let v2 = parseVersion(m2)
            if v1.0 != v2.0 { return v1.0 > v2.0 }
            if v1.1 != v2.1 { return v1.1 > v2.1 }
            let s1 = m1.contains("mini") ? 1 : 2
            let s2 = m2.contains("mini") ? 1 : 2
            return s1 > s2
        }
    }
    
    private func fetchRemoteClaudeModels(apiKey: String) async -> [String] {
        guard let url = URL(string: "https://api.anthropic.com/v1/models") else { return [] }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.timeoutInterval = 8.0
        
        guard let (data, response) = try? await Self.fastSession.data(for: req),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["data"] as? [[String: Any]] else {
            return []
        }
        
        var found: [String] = []
        for item in list {
            guard let mid = item["id"] as? String else { continue }
            if mid.contains("claude") {
                found.append(mid)
            }
        }
        return sortClaudeModels(found)
    }
    
    private func sortClaudeModels(_ models: [String]) -> [String] {
        return models.sorted { m1, m2 in
            let v1 = parseVersion(m1)
            let v2 = parseVersion(m2)
            if v1.0 != v2.0 { return v1.0 > v2.0 }
            if v1.1 != v2.1 { return v1.1 > v2.1 }
            let s1 = m1.contains("sonnet") ? 3 : (m1.contains("haiku") ? 2 : 1)
            let s2 = m2.contains("sonnet") ? 3 : (m2.contains("haiku") ? 2 : 1)
            return s1 > s2
        }
    }
    
    private func parseVersion(_ name: String) -> (Int, Int) {
        let parts = name.split(separator: "-")
        for part in parts {
            let sub = part.split(separator: ".")
            if let first = sub.first, let major = Int(first) {
                let minor = sub.count > 1 ? (Int(sub[1]) ?? 0) : 0
                return (major, minor)
            }
        }
        return (0, 0)
    }
    
    // MARK: - Пинг-тесты моделей
    
    func testGeminiModel(name: String, apiKey: String) async -> Bool {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(name):generateContent?key=\(apiKey)") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
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
    
    func testOpenAIModel(name: String, apiKey: String) async -> Bool {
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
    
    func testClaudeModel(name: String, apiKey: String) async -> Bool {
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
    
    func saveActiveModel(_ model: String, for provider: AIProvider) {
        let cleaned = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        switch provider {
        case .gemini: activeGeminiModel = cleaned
        case .chatgpt: activeOpenAIModel = cleaned
        case .claude: activeClaudeModel = cleaned
        }
    }
    
    func resetToDefaults() {
        activeGeminiModel = "gemini-3.5-flash-lite"
        activeOpenAIModel = "gpt-4o-mini"
        activeClaudeModel = "claude-3-5-haiku-20241022"
    }
}
