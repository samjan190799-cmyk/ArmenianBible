import Foundation

// MARK: - Модели ИИ и каскадная система безопасности (Fail-Safe Fallback System)
// 1. Список моделей идёт от быстрой и недорогой к более мощным запасным. Актуальный список приложение берёт с сервера
//    (кнопка «Обновить модели», см. AIModelCatalog.swift), а встроенный ниже работает, пока сети или сервера нет.
// 2. Если модель закрыта или недоступна (404, 410, 400 про модель), запрос уходит к следующей. Если не принят ключ,
//    кончились деньги на счёте или нет сети, перебор моделей остановлен: другая модель не поможет, а ждать пришлось бы долго.
// 3. Если закрыты все модели списка, приложение один раз подтягивает свежий список и, как последнее средство, спрашивает
//    у провайдера, какие модели доступны именно этому ключу.
// 4. Подписчик или человек без своего ключа идёт через сервер (AIProxy), и туда же уходит запрос, если свой ключ не принят.

/// Итог проверки одной модели лёгким запросом
enum AIModelProbeResult {
    case ok
    case modelUnavailable
    case keyRejected
    case offline
    case other
}

/// Итог проверки провайдера по ключу человека при нажатии «Обновить модели»
enum AIProviderCheck: Equatable {
    /// Нашлась рабочая модель; `changed` — она отличается от той, что была активной
    case selected(model: String, changed: Bool)
    case keyRejected
    case offline
    case noneWorked
}

struct AIModelsUpdateReport {
    let catalog: AIModelsRefreshResult
    /// Только провайдеры, для которых у человека есть свой ключ
    let providers: [AIProvider: AIProviderCheck]
}

/// Что именно пошло не так с запросом: от этого зависит, пробовать ли следующую модель
enum AIFailureKind {
    case credentials
    case noConnection
    case noFunds
    case modelUnavailable
    case transient
}

final class AIModelRegistry: @unchecked Sendable {
    static let shared = AIModelRegistry()

    // MARK: - Встроенные списки моделей (запасные: на случай, когда список с сервера не получен)
    // Сверено с официальной документацией 2026-11-05 (Google: ai.google.dev, OpenAI: developers.openai.com,
    // Anthropic: platform.claude.com). Закрыты и сюда не входят: gemini-1.5 и 2.0, gpt-3.5-turbo, o1 и o3-mini, все claude-3.x.
    // gemini-2.5-flash и gemini-2.5-pro Google с 1 декабря 2026 перенаправляет на 3.x. gpt-4o-mini остаётся последним запасным
    // до своего закрытия 14 января 2027, потом его можно убрать. Скрипты update_ai_models.py и auto_discover_ai_models.py
    // переписывают эти три массива, поэтому внутри массивов комментариев нет.

    static let geminiHierarchy: [String] = [
        "gemini-3.5-flash-lite",
        "gemini-3.6-flash",
        "gemini-3.8-flash",
        "gemini-2.5-flash-lite"
    ]

    static let openAIHierarchy: [String] = [
        "gpt-6-luna",
        "gpt-6.1-terra",
        "gpt-6.1-sol",
        "gpt-4o-mini"
    ]

    static let claudeHierarchy: [String] = [
        "claude-haiku-5-5",
        "claude-sonnet-5-5",
        "claude-sonnet-5",
        "claude-haiku-4-5"
    ]

    static func builtinHierarchy(for provider: AIProvider) -> [String] {
        switch provider {
        case .gemini: return geminiHierarchy
        case .chatgpt: return openAIHierarchy
        case .claude: return claudeHierarchy
        }
    }

    // MARK: - Сетевые сессии

    /// Для лёгких проверок и списков моделей
    private static let fastSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25.0
        config.timeoutIntervalForResource = 35.0
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    /// Для самих ответов: длинный ответ (толкование, викторина на 4000 токенов) генерируется дольше 25 секунд
    private static let generationSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 75.0
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    private static let storedSchemaKey = "ai_model_registry_schema"
    private static let currentSchema = 2

    private init() {
        migrateStoredModelsIfNeeded()
        // Только дешёвый запрос списка с сервера: ни ключей, ни токенов провайдеров на него не тратится
        refreshCatalogInBackground()
    }

    /// До схемы 2 в UserDefaults запоминались модели, которые провайдеры уже закрыли (claude-3.x, gpt-3.5, gemini 1.5 и 2.0).
    /// Сбрасываем их, и активной станет первая модель актуального списка
    private func migrateStoredModelsIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: Self.storedSchemaKey) < Self.currentSchema else { return }
        for provider in AIProvider.allCases {
            defaults.removeObject(forKey: Self.activeKey(for: provider))
        }
        defaults.set(Self.currentSchema, forKey: Self.storedSchemaKey)
    }

    // MARK: - Активные модели (сохраняются в UserDefaults)

    private static func activeKey(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "active_gemini_model"
        case .chatgpt: return "active_openai_model"
        case .claude: return "active_claude_model"
        }
    }

    private static func discoveredKey(for provider: AIProvider) -> String {
        "ai_discovered_models_" + provider.rawValue
    }

    /// Запомненная модель, если она всё ещё в списке; иначе первая модель списка
    private func storedActive(for provider: AIProvider) -> String {
        let list = hierarchy(for: provider)
        if let stored = UserDefaults.standard.string(forKey: Self.activeKey(for: provider)), list.contains(stored) {
            return stored
        }
        return list.first ?? Self.builtinHierarchy(for: provider)[0]
    }

    var activeGeminiModel: String {
        get { storedActive(for: .gemini) }
        set { UserDefaults.standard.set(newValue, forKey: Self.activeKey(for: .gemini)) }
    }

    var activeOpenAIModel: String {
        get { storedActive(for: .chatgpt) }
        set { UserDefaults.standard.set(newValue, forKey: Self.activeKey(for: .chatgpt)) }
    }

    var activeClaudeModel: String {
        get { storedActive(for: .claude) }
        set { UserDefaults.standard.set(newValue, forKey: Self.activeKey(for: .claude)) }
    }

    // MARK: - Получение активной модели и цепочки резерва

    func activeModel(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return activeGeminiModel
        case .chatgpt: return activeOpenAIModel
        case .claude: return activeClaudeModel
        }
    }

    /// Итоговый список: сначала с сервера, потом встроенный, в конце найденные по ключу человека
    func hierarchy(for provider: AIProvider) -> [String] {
        let sources: [[String]] = [
            AIModelCatalogStore.cached?.models(for: provider) ?? [],
            Self.builtinHierarchy(for: provider),
            discoveredModels(for: provider)
        ]
        var list: [String] = []
        for source in sources {
            for id in source where !list.contains(id) {
                list.append(id)
            }
        }
        return list
    }

    /// Кандидаты для выполнения запроса: сначала активная, затем резервные из списка
    func candidateModels(for provider: AIProvider) -> [String] {
        let active = activeModel(for: provider)
        var list = [active]
        for m in hierarchy(for: provider) where !list.contains(m) {
            list.append(m)
        }
        return list
    }

    private func discoveredModels(for provider: AIProvider) -> [String] {
        let saved = UserDefaults.standard.stringArray(forKey: Self.discoveredKey(for: provider)) ?? []
        return AIModelCatalogStore.sanitize(saved, for: provider)
    }

    private func rememberDiscovered(_ model: String, for provider: AIProvider) {
        var list = discoveredModels(for: provider)
        guard !list.contains(model) else { return }
        list.insert(model, at: 0)
        UserDefaults.standard.set(Array(list.prefix(3)), forKey: Self.discoveredKey(for: provider))
    }

    /// Красивое читаемое название текущей модели для UI
    func displayName(for provider: AIProvider) -> String {
        Self.prettyName(of: activeModel(for: provider), provider: provider)
    }

    /// «gemini-3.5-flash-lite» → «Gemini 3.5 Flash-Lite», «gpt-6.1-terra» → «GPT-6.1 Terra», «claude-haiku-5-5» → «Claude Haiku 5.5»
    static func prettyName(of model: String, provider: AIProvider) -> String {
        let parts = model.split(separator: "-").map(String.init)
        switch provider {
        case .gemini:
            guard parts.count >= 2 else { return "Gemini" }
            let tail = parts.dropFirst(2).map { $0.capitalized }.joined(separator: "-")
            return tail.isEmpty ? "Gemini \(parts[1])" : "Gemini \(parts[1]) \(tail)"

        case .chatgpt:
            if model.hasPrefix("gpt-"), parts.count >= 2 {
                let tail = parts.dropFirst(2).map { $0.capitalized }.joined(separator: " ")
                return tail.isEmpty ? "GPT-\(parts[1])" : "GPT-\(parts[1]) \(tail)"
            }
            if model.hasPrefix("o"), let digit = model.dropFirst().first, digit.isNumber, let head = parts.first {
                // o4-mini → «O4 Mini»
                let tail = parts.dropFirst().map { $0.capitalized }.joined(separator: " ")
                return tail.isEmpty ? head.uppercased() : "\(head.uppercased()) \(tail)"
            }
            return "ChatGPT"

        case .claude:
            let rest = parts.dropFirst().filter { part in
                part != "latest" && !(part.count == 8 && part.allSatisfy { $0.isNumber })
            }
            let words = rest.filter { part in part.first?.isLetter == true }.map { $0.capitalized }
            let numbers = rest.filter { part in part.first?.isNumber == true }
            guard !words.isEmpty || !numbers.isEmpty else { return "Claude" }
            let version = numbers.joined(separator: ".")
            // Старые имена: claude-3-5-haiku → «Claude 3.5 Haiku»; новые: claude-haiku-5-5 → «Claude Haiku 5.5»
            if let first = rest.first, first.first?.isNumber == true {
                return (["Claude", version] + words).filter { !$0.isEmpty }.joined(separator: " ")
            }
            return (["Claude"] + words + [version]).filter { !$0.isEmpty }.joined(separator: " ")
        }
    }

    // MARK: - Универсальное выполнение запроса с каскадным переключением (Fail-Safe Fallback)

    /// Запрос к ИИ. Подписчик без своего ключа идёт через сервер. Если свой ключ человека не принят (устарел, отозван)
    /// или закрыты все модели, запрос повторяется через сервер. Итог каждого запроса идёт в воронку.
    func executeRequest(
        provider: AIProvider,
        apiKey: String,
        prompt: String,
        systemPrompt: String? = nil,
        jsonMode: Bool = false,
        maxTokens: Int = 1024
    ) async throws -> (text: String, usedModel: String) {
        if apiKey == AIProxy.sentinelKey {
            return try await serverRequest(prompt: prompt, systemPrompt: systemPrompt, jsonMode: jsonMode, maxTokens: maxTokens)
        }
        do {
            let result = try await executeDirectRequest(provider: provider, apiKey: apiKey, prompt: prompt, systemPrompt: systemPrompt, jsonMode: jsonMode, maxTokens: maxTokens)
            Funnel.track("ai_result", ["result": "ok", "via": "own"])
            return result
        } catch {
            guard AIProxy.isAvailableForCurrentUser, Self.isCredentialFailure(error) || Self.isModelsExhausted(error) else {
                Funnel.track("ai_result", ["result": Self.aiOutcome(error), "via": "own"])
                throw error
            }
            return try await serverRequest(prompt: prompt, systemPrompt: systemPrompt, jsonMode: jsonMode, maxTokens: maxTokens)
        }
    }

    private func serverRequest(prompt: String, systemPrompt: String?, jsonMode: Bool, maxTokens: Int) async throws -> (text: String, usedModel: String) {
        do {
            let text = try await AIProxy.generate(prompt: prompt, systemPrompt: systemPrompt, jsonMode: jsonMode, maxTokens: maxTokens)
            Funnel.track("ai_result", ["result": "ok", "via": "server"])
            return (text, "server")
        } catch {
            Funnel.track("ai_result", ["result": Self.aiOutcome(error), "via": "server"])
            throw error
        }
    }

    /// Итог запроса одним словом для воронки
    private static func aiOutcome(_ error: Error) -> String {
        switch (error as NSError).code {
        case 429: return "quota"
        case 451: return "declined"
        case 401, 403: return "auth"
        default: return "error"
        }
    }

    /// Провайдер отказал из-за самого ключа (неверный, просрочен, отозван), а не из-за запроса
    private static func isCredentialFailure(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.code == 401 || nsError.code == 403 { return true }
        let text = error.localizedDescription.lowercased()
        let markers = ["api key not valid", "api_key_invalid", "api key expired", "invalid api key", "invalid_api_key", "incorrect api key", "authentication_error", "unauthorized", "permission_denied"]
        return markers.contains { text.contains($0) }
    }

    /// Закрыты все модели из списка (ошибка собирается в executeDirectRequest)
    private static func isModelsExhausted(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "AIModelRegistry" && nsError.code == 404
    }

    /// Какая это неудача: от этого зависит, пробовать ли следующую модель
    private static func classify(_ error: Error, provider: AIProvider) -> AIFailureKind {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorDataNotAllowed,
                 NSURLErrorInternationalRoamingOff, NSURLErrorCancelled:
                return .noConnection
            default:
                // Таймаут или сбой соединения: пробуем следующую модель, но общий срок ограничен (см. executeDirectRequest)
                return .transient
            }
        }
        let text = error.localizedDescription.lowercased()
        // У Gemini «квота исчерпана» относится к одной модели, у остальных — ко всему счёту
        if provider != .gemini {
            let fundsMarkers = ["credit balance is too low", "insufficient_quota", "exceeded your current quota", "payment required"]
            if fundsMarkers.contains(where: { text.contains($0) }) { return .noFunds }
        }
        if isCredentialFailure(error) {
            // «Нет доступа к модели» — про модель, а не про ключ
            if nsError.code == 403 && text.contains("model") { return .modelUnavailable }
            return .credentials
        }
        switch nsError.code {
        case 404, 410:
            return .modelUnavailable
        case 400:
            let markers = ["model", "not supported", "unsupported", "does not exist", "not found", "deprecated"]
            return markers.contains { text.contains($0) } ? .modelUnavailable : .transient
        default:
            return .transient
        }
    }

    /// Выполняет запрос к ИИ со своим ключом. Если модель закрыта или недоступна, переходит к следующей из списка;
    /// когда закрыты все, один раз обновляет список с сервера и пробует модели, доступные этому ключу.
    private func executeDirectRequest(
        provider: AIProvider,
        apiKey: String,
        prompt: String,
        systemPrompt: String? = nil,
        jsonMode: Bool = false,
        maxTokens: Int = 1024
    ) async throws -> (text: String, usedModel: String) {
        let started = Date()
        var queue = candidateModels(for: provider)
        var triedModels = Set<String>()
        var lastError: Error?
        var attemptErrors: [String] = []
        // До сих пор отказывали только из-за самих моделей (а не из-за сети, сбоя сервера или лимита)
        var onlyModelProblems = true
        var refreshedCatalog = false
        var triedLive = false

        while true {
            guard let modelName = queue.first(where: { !triedModels.contains($0) }) else {
                guard onlyModelProblems, Date().timeIntervalSince(started) < 40 else { break }
                if !refreshedCatalog {
                    refreshedCatalog = true
                    // Свежий список с сервера, если прежний старше 15 минут (чтобы упрямые запросы не долбили сервер)
                    let isStale = AIModelCatalogStore.lastUpdated.map { Date().timeIntervalSince($0) > 900 } ?? true
                    if isStale {
                        _ = await refreshCatalog(force: true)
                    }
                    queue.append(contentsOf: candidateModels(for: provider))
                    continue
                }
                if !triedLive {
                    triedLive = true
                    let live = await liveCandidates(for: provider, apiKey: apiKey)
                    queue.append(contentsOf: live)
                    continue
                }
                break
            }
            triedModels.insert(modelName)
            // Общий срок: не заставляем человека ждать больше полутора минут, перебирая медленные модели
            if !attemptErrors.isEmpty && Date().timeIntervalSince(started) > 80 { break }

            do {
                let text = try await send(provider: provider, model: modelName, apiKey: apiKey, prompt: prompt, systemPrompt: systemPrompt, jsonMode: jsonMode, maxTokens: maxTokens)

                // Запоминаем запасную модель как активную, только если предыдущие закрыты (а не просто моргнули сетью)
                if onlyModelProblems && modelName != activeModel(for: provider) {
                    saveActiveModel(modelName, for: provider)
                    if !hierarchy(for: provider).contains(modelName) { rememberDiscovered(modelName, for: provider) }
                    print("[AI Fallback] Переключено на рабочую модель: \(modelName)")
                }
                return (text, modelName)
            } catch {
                lastError = error
                attemptErrors.append("\(modelName): \(error.localizedDescription)")
                print("[AI Fallback] Модель \(modelName) вернула ошибку: \(error.localizedDescription)")

                switch Self.classify(error, provider: provider) {
                case .credentials, .noConnection, .noFunds:
                    // Другая модель не поможет, а ждать ответа пришлось бы ещё дольше
                    throw error
                case .modelUnavailable:
                    // Google в тексте 404 иногда называет модель-замену: «models/gemini-…». Пробуем её следующей
                    if provider == .gemini, let suggested = Self.suggestedGeminiModel(in: error.localizedDescription),
                       !triedModels.contains(suggested), !queue.contains(suggested) {
                        queue.insert(suggested, at: 0)
                    }
                case .transient:
                    onlyModelProblems = false
                }
            }
        }

        let detailedMsg = attemptErrors.isEmpty ? "All AI models are unavailable." : attemptErrors.joined(separator: "\n")
        if onlyModelProblems && !attemptErrors.isEmpty {
            throw NSError(domain: "AIModelRegistry", code: 404, userInfo: [NSLocalizedDescriptionKey: detailedMsg])
        }
        throw lastError ?? NSError(domain: "AIModelRegistry", code: 500, userInfo: [NSLocalizedDescriptionKey: detailedMsg])
    }

    /// Достаёт из текста ошибки Google имя модели вида «models/gemini-3.6-flash», если оно допустимо
    private static func suggestedGeminiModel(in text: String) -> String? {
        guard let range = text.range(of: "models/gemini-") else { return nil }
        let tail = text[range.upperBound...].prefix(while: { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." })
        let candidate = ("gemini-" + tail).trimmingCharacters(in: CharacterSet(charactersIn: "-."))
        return AIModelCatalogStore.isValidModelId(candidate, for: .gemini) ? candidate : nil
    }

    // MARK: - Сборка запроса и разбор ответа по провайдерам

    /// Совсем новые семейства: ответ начинается с «размышления», оно съедает токены лимита, а параметры вроде temperature не принимаются
    static func isReasoningOpenAI(_ model: String) -> Bool {
        if model.hasPrefix("gpt-") {
            let digits = model.dropFirst(4).prefix(while: { $0.isNumber })
            return (Int(digits) ?? 0) >= 5
        }
        if model.hasPrefix("o"), let digit = model.dropFirst().first, digit.isNumber { return true }
        return false
    }

    /// Claude 5 и новее: размышление включено по умолчанию, sampling-параметры не принимаются
    static func isModernClaude(_ model: String) -> Bool {
        let numbers = model.split(separator: "-").dropFirst().compactMap { Int($0) }
        guard let major = numbers.first else { return false }
        // Для «claude-3-5-haiku» первое число 3, для «claude-haiku-5-5» — 5; дата-суффикс вроде 20251001 идёт позже
        return major >= 5 && major < 100
    }

    /// Запас токенов на размышление новых моделей: оно входит в лимит ответа
    private static let thinkingHeadroom = 1024

    private static func timeout(forMaxTokens maxTokens: Int) -> TimeInterval {
        maxTokens > 2048 ? 60 : 45
    }

    private func makeRequest(
        provider: AIProvider,
        model: String,
        apiKey: String,
        prompt: String,
        systemPrompt: String?,
        jsonMode: Bool,
        maxTokens: Int,
        timeout: TimeInterval
    ) throws -> URLRequest {
        // Идентификатор модели попадает в адрес запроса, поэтому пропускаем только безопасные символы
        guard AIModelCatalogStore.isPlausibleModelId(model) else {
            throw NSError(domain: "AIModelRegistry", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid model id"])
        }
        let urlString: String
        var body: [String: Any]
        var headers: [String: String] = ["Content-Type": "application/json"]

        switch provider {
        case .gemini:
            urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
            headers["x-goog-api-key"] = apiKey
            var genConfig: [String: Any] = [
                "temperature": 0.85,
                // У Gemini 3 размышление входит в лимит ответа
                "maxOutputTokens": model.hasPrefix("gemini-3") ? maxTokens + Self.thinkingHeadroom : maxTokens
            ]
            if jsonMode {
                genConfig["responseMimeType"] = "application/json"
            }
            let userContent: [String: Any] = ["role": "user", "parts": [["text": prompt]]]
            body = [
                "contents": [userContent],
                "generationConfig": genConfig
            ]
            if let sys = systemPrompt, !sys.isEmpty {
                body["systemInstruction"] = ["parts": [["text": sys]]]
            }

        case .chatgpt:
            urlString = "https://api.openai.com/v1/chat/completions"
            headers["Authorization"] = "Bearer \(apiKey)"
            var messages: [[String: String]] = []
            if let sys = systemPrompt, !sys.isEmpty {
                messages.append(["role": "system", "content": sys])
            }
            messages.append(["role": "user", "content": prompt])
            body = ["model": model, "messages": messages]
            if Self.isReasoningOpenAI(model) {
                // max_tokens и температура у этих моделей не принимаются; размышление держим коротким
                body["max_completion_tokens"] = maxTokens + Self.thinkingHeadroom
                body["reasoning_effort"] = "low"
            } else {
                body["max_completion_tokens"] = maxTokens
                body["temperature"] = 0.85
            }
            if jsonMode {
                body["response_format"] = ["type": "json_object"]
            }

        case .claude:
            urlString = "https://api.anthropic.com/v1/messages"
            headers["x-api-key"] = apiKey
            headers["anthropic-version"] = "2023-06-01"
            body = [
                "model": model,
                "max_tokens": maxTokens,
                "messages": [["role": "user", "content": prompt]]
            ]
            if Self.isModernClaude(model) {
                // У Claude 5 нельзя задавать temperature (400), а размышление включено само и входит в max_tokens
                body["max_tokens"] = maxTokens + Self.thinkingHeadroom
                body["output_config"] = ["effort": "low"]
            } else {
                body["temperature"] = 0.85
            }
            if let sys = systemPrompt, !sys.isEmpty {
                body["system"] = sys
            }
        }

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "AIModelRegistry", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid AI URL"])
        }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func providerLabel(_ provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "Gemini"
        case .chatgpt: return "OpenAI"
        case .claude: return "Claude"
        }
    }

    /// Ошибка HTTP с коротким текстом: сообщение провайдера и его код/тип (по ним потом узнаём неверный ключ или нехватку денег)
    private static func httpError(_ provider: AIProvider, _ status: Int, _ data: Data) -> NSError {
        var detail = ""
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any] {
            let message = (error["message"] as? String) ?? ""
            let kind = [error["type"], error["code"], error["status"]].compactMap { $0 as? String }.joined(separator: ", ")
            detail = kind.isEmpty ? message : "\(message) [\(kind)]"
        }
        if detail.isEmpty {
            let raw = String(data: data, encoding: .utf8) ?? ""
            detail = raw.isEmpty ? "HTTP \(status)" : String(raw.prefix(300))
        }
        let label = providerLabel(provider)
        return NSError(domain: label, code: status, userInfo: [NSLocalizedDescriptionKey: "\(label) Error (\(status)): \(detail)"])
    }

    private func parseText(provider: AIProvider, data: Data) throws -> String {
        let label = Self.providerLabel(provider)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        var text = ""
        var reason = ""

        switch provider {
        case .gemini:
            let candidate = (json?["candidates"] as? [[String: Any]])?.first
            let parts = ((candidate?["content"] as? [String: Any])?["parts"] as? [[String: Any]]) ?? []
            // Куски с мыслями модели (thought) в ответ не берём
            text = parts.filter { ($0["thought"] as? Bool) != true }.compactMap { $0["text"] as? String }.joined()
            reason = (candidate?["finishReason"] as? String) ?? ((json?["promptFeedback"] as? [String: Any])?["blockReason"] as? String) ?? ""

        case .chatgpt:
            let choice = (json?["choices"] as? [[String: Any]])?.first
            let message = choice?["message"] as? [String: Any]
            text = (message?["content"] as? String) ?? ""
            reason = (message?["refusal"] as? String) ?? (choice?["finish_reason"] as? String) ?? ""

        case .claude:
            let blocks = (json?["content"] as? [[String: Any]]) ?? []
            // Ответ может начинаться с блока thinking: берём только текстовые блоки
            text = blocks.filter { ($0["type"] as? String) == "text" }.compactMap { $0["text"] as? String }.joined()
            reason = (json?["stop_reason"] as? String) ?? ""
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            let details = reason.isEmpty ? "" : " (" + reason + ")"
            throw NSError(domain: label, code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty " + label + " Response" + details])
        }
        return trimmed
    }

    private func send(
        provider: AIProvider,
        model: String,
        apiKey: String,
        prompt: String,
        systemPrompt: String?,
        jsonMode: Bool,
        maxTokens: Int
    ) async throws -> String {
        let request = try makeRequest(
            provider: provider, model: model, apiKey: apiKey, prompt: prompt, systemPrompt: systemPrompt,
            jsonMode: jsonMode, maxTokens: maxTokens, timeout: Self.timeout(forMaxTokens: maxTokens)
        )
        let (data, response) = try await Self.generationSession.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw Self.httpError(provider, http.statusCode, data)
        }
        return try parseText(provider: provider, data: data)
    }

    // MARK: - Обновление списка моделей (кнопка «Обновить модели»)

    /// Подтягивает список моделей с сервера. Активная модель у тех провайдеров, чей список изменился, выбирается заново
    @discardableResult
    func refreshCatalog(force: Bool) async -> AIModelsRefreshResult {
        let result = await AIModelCatalogStore.refresh(force: force)
        for provider in result.changedProviders {
            UserDefaults.standard.removeObject(forKey: Self.activeKey(for: provider))
        }
        return result
    }

    /// Тихое фоновое обновление списка (не чаще раза в 12 часов)
    func refreshCatalogInBackground() {
        Task(priority: .utility) { [self] in
            _ = await refreshCatalog(force: false)
        }
    }

    /// Кнопка «Обновить модели»: список с сервера (ключ не нужен), затем у тех, кто ввёл свой ключ, проверка,
    /// что выбранная модель отвечает именно с этим ключом
    func updateAllModels() async -> AIModelsUpdateReport {
        let catalog = await refreshCatalog(force: true)
        var checks: [AIProvider: AIProviderCheck] = [:]
        for provider in AIProvider.allCases {
            let key = ownKey(for: provider)
            guard !key.isEmpty else { continue }
            checks[provider] = await selectWorkingModel(for: provider, apiKey: key)
        }
        return AIModelsUpdateReport(catalog: catalog, providers: checks)
    }

    /// Свой ключ человека (пустая строка, если не введён)
    private func ownKey(for provider: AIProvider) -> String {
        let defaults = UserDefaults.standard
        let raw: String?
        switch provider {
        case .gemini: raw = defaults.string(forKey: "gemini_api_key_secure") ?? defaults.string(forKey: "gemini_api_key")
        case .chatgpt: raw = defaults.string(forKey: "openai_api_key_secure") ?? defaults.string(forKey: "openai_api_key")
        case .claude: raw = defaults.string(forKey: "anthropic_api_key_secure") ?? defaults.string(forKey: "anthropic_api_key")
        }
        return (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Лёгкий запрос к модели: отвечает ли она с этим ключом
    func probeModel(provider: AIProvider, model: String, apiKey: String) async -> AIModelProbeResult {
        do {
            let request = try makeRequest(
                provider: provider, model: model, apiKey: apiKey, prompt: "ping", systemPrompt: nil,
                jsonMode: false, maxTokens: 16, timeout: 12
            )
            let (data, response) = try await Self.fastSession.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .other }
            if (200...299).contains(http.statusCode) { return .ok }
            switch Self.classify(Self.httpError(provider, http.statusCode, data), provider: provider) {
            case .credentials: return .keyRejected
            case .modelUnavailable: return .modelUnavailable
            case .noConnection: return .offline
            case .noFunds, .transient: return .other
            }
        } catch {
            return Self.classify(error, provider: provider) == .noConnection ? .offline : .other
        }
    }

    /// Первая модель списка, которая отвечает с ключом человека, становится активной
    private func selectWorkingModel(for provider: AIProvider, apiKey: String) async -> AIProviderCheck {
        let previous = activeModel(for: provider)
        var tried = Set<String>()

        for model in hierarchy(for: provider) {
            if tried.count >= 6 { break }
            tried.insert(model)
            switch await probeModel(provider: provider, model: model, apiKey: apiKey) {
            case .ok:
                saveActiveModel(model, for: provider)
                return .selected(model: model, changed: model != previous)
            case .keyRejected:
                return .keyRejected
            case .offline:
                return .offline
            case .modelUnavailable, .other:
                continue
            }
        }

        // Ни одна известная модель не отвечает: смотрим, что провайдер реально открыл этому ключу
        var liveTried = 0
        for model in await liveCandidates(for: provider, apiKey: apiKey) where !tried.contains(model) {
            if liveTried >= 6 { break }
            liveTried += 1
            switch await probeModel(provider: provider, model: model, apiKey: apiKey) {
            case .ok:
                rememberDiscovered(model, for: provider)
                saveActiveModel(model, for: provider)
                return .selected(model: model, changed: model != previous)
            case .keyRejected:
                return .keyRejected
            case .offline:
                return .offline
            case .modelUnavailable, .other:
                continue
            }
        }
        return .noneWorked
    }

    // MARK: - Модели, которые провайдер открыл этому ключу (ListModels)

    /// Подходящие для чата модели из списка провайдера: сначала недорогие, внутри уровня более новые
    private func liveCandidates(for provider: AIProvider, apiKey: String) async -> [String] {
        let found: [String]
        switch provider {
        case .gemini: found = await fetchRemoteGeminiModels(apiKey: apiKey)
        case .chatgpt: found = await fetchRemoteOpenAIModels(apiKey: apiKey)
        case .claude: found = await fetchRemoteClaudeModels(apiKey: apiKey)
        }
        let valid = found.filter { AIModelCatalogStore.isValidModelId($0, for: provider) }
        let ranked = valid.sorted { first, second in
            let tierA = Self.tier(of: first, provider: provider)
            let tierB = Self.tier(of: second, provider: provider)
            if tierA != tierB { return tierA < tierB }
            let versionA = Self.parseVersion(first)
            let versionB = Self.parseVersion(second)
            if versionA.0 != versionB.0 { return versionA.0 > versionB.0 }
            if versionA.1 != versionB.1 { return versionA.1 > versionB.1 }
            return first < second
        }
        return Array(ranked.prefix(12))
    }

    private static func tier(of model: String, provider: AIProvider) -> Int {
        let lower = model.lowercased()
        switch provider {
        case .gemini:
            return lower.contains("lite") ? 0 : (lower.contains("flash") ? 1 : 2)
        case .chatgpt:
            if lower.contains("luna") || lower.contains("mini") || lower.contains("nano") { return 0 }
            return lower.contains("terra") ? 1 : 2
        case .claude:
            return lower.contains("haiku") ? 0 : (lower.contains("sonnet") ? 1 : 2)
        }
    }

    private static func parseVersion(_ name: String) -> (Int, Int) {
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

    /// Запросить список у провайдера. Пустой список, если нет сети или ключ не принят
    private func fetchList(url: String, headers: [String: String]) async -> [[String: Any]] {
        guard let url = URL(string: url) else { return [] }
        var req = URLRequest(url: url, timeoutInterval: 10)
        req.httpMethod = "GET"
        for (field, value) in headers {
            req.setValue(value, forHTTPHeaderField: field)
        }
        guard let (data, response) = try? await Self.fastSession.data(for: req),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        return ((json["models"] ?? json["data"]) as? [[String: Any]]) ?? []
    }

    private func fetchRemoteGeminiModels(apiKey: String) async -> [String] {
        let list = await fetchList(url: "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200", headers: ["x-goog-api-key": apiKey])
        // Не чат-модели и нестабильные: озвучка, картинки, Live, предварительные и экспериментальные версии
        let excluded = ["embedding", "aqa", "imagen", "bison", "gecko", "image", "tts", "live", "audio", "transcribe",
                        "robotics", "computer-use", "veo", "native", "preview", "exp", "thinking", "learnlm"]
        var found: [String] = []
        for item in list {
            guard let rawName = item["name"] as? String else { continue }
            let name = rawName.replacingOccurrences(of: "models/", with: "")
            let methods = item["supportedGenerationMethods"] as? [String] ?? []
            if methods.contains("generateContent") && name.hasPrefix("gemini-") && !excluded.contains(where: { name.contains($0) }) {
                found.append(name)
            }
        }
        return found
    }

    private func fetchRemoteOpenAIModels(apiKey: String) async -> [String] {
        let list = await fetchList(url: "https://api.openai.com/v1/models", headers: ["Authorization": "Bearer \(apiKey)"])
        let excluded = ["audio", "realtime", "transcribe", "tts", "search", "image", "vision", "codex", "instruct", "pro",
                        "deep-research", "moderation", "embedding", "cyber", "preview", "chat-latest", "computer-use"]
        var found: [String] = []
        for item in list {
            guard let mid = item["id"] as? String else { continue }
            guard mid.hasPrefix("gpt-") || mid.hasPrefix("o3") || mid.hasPrefix("o4") else { continue }
            if excluded.contains(where: { mid.contains($0) }) { continue }
            // Датированные снимки (gpt-4o-2024-08-06) отбрасываем: основное имя уже в списке
            let hasDate = mid.range(of: "-\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression) != nil
            if !hasDate { found.append(mid) }
        }
        return found
    }

    private func fetchRemoteClaudeModels(apiKey: String) async -> [String] {
        let list = await fetchList(url: "https://api.anthropic.com/v1/models?limit=100", headers: ["x-api-key": apiKey, "anthropic-version": "2023-06-01"])
        var found: [String] = []
        for item in list {
            guard let mid = item["id"] as? String, mid.hasPrefix("claude-") else { continue }
            // claude-3.x и 2.x закрыты; на всякий случай не берём их, даже если список вернёт
            let parsed = Self.parseVersion(mid)
            if mid.hasPrefix("claude-3") || mid.hasPrefix("claude-2") || mid.contains("instant") || parsed.0 == 0 { continue }
            found.append(mid)
        }
        return found
    }

    // MARK: - Сохранение и сброс

    func saveActiveModel(_ model: String, for provider: AIProvider) {
        let cleaned = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, AIModelCatalogStore.isPlausibleModelId(cleaned) else { return }
        UserDefaults.standard.set(cleaned, forKey: Self.activeKey(for: provider))
    }

    func resetToDefaults() {
        for provider in AIProvider.allCases {
            UserDefaults.standard.removeObject(forKey: Self.activeKey(for: provider))
            UserDefaults.standard.removeObject(forKey: Self.discoveredKey(for: provider))
        }
    }
}
