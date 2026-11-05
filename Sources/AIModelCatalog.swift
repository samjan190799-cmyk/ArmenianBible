import Foundation

// MARK: - Список моделей ИИ с нашего сервера
// Кнопка «Обновить модели» в настройках и фоновая проверка берут актуальные идентификаторы моделей Google, OpenAI и Anthropic
// с Worker (GET /v1/models, папка cloudflare/ai-proxy), поэтому новые модели появляются без выпуска версии в App Store.
// Список лежит в UserDefaults, и пока сети нет или сервер молчит, приложение работает с последним сохранённым
// (а если его не было, со встроенным в AIModelRegistry). Ни ключей, ни данных человека запрос не содержит.

struct AIModelCatalog: Codable, Equatable {
    var version: Int
    var updated: String
    var gemini: [String]
    var openai: [String]
    var claude: [String]

    func models(for provider: AIProvider) -> [String] {
        switch provider {
        case .gemini: return gemini
        case .chatgpt: return openai
        case .claude: return claude
        }
    }
}

enum AIModelsRefreshStatus {
    /// Сервер отдал список, и в нём есть модели, которых раньше не было
    case updated
    /// Сервер отдал список, нового в нём нет (или проверка не нужна: недавно уже обновляли)
    case upToDate
    /// Нет сети
    case offline
    /// Сервер не отдал список: Worker старой версии, сбой или ответ неверного вида
    case unavailable
}

struct AIModelsRefreshResult {
    let status: AIModelsRefreshStatus
    /// Идентификаторы, которых не было в прежнем списке
    let added: [String]
    /// Провайдеры, у которых список изменился: для них активная модель выбирается заново
    let changedProviders: [AIProvider]
}

enum AIModelCatalogStore {
    private static let storageKey = "ai_model_catalog_v1"
    private static let fetchedAtKey = "ai_model_catalog_fetched_at"
    private static let attemptedAtKey = "ai_model_catalog_attempted_at"

    /// Как часто фоновая проверка ходит на сервер после удачного ответа
    private static let backgroundInterval: TimeInterval = 12 * 3600
    /// Как часто повторяем попытку, если сервер не ответил
    private static let retryInterval: TimeInterval = 3600
    private static let maxPerProvider = 8

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    // MARK: Сохранённый список

    /// Последний удачно полученный список; nil, пока ни разу не получали
    static var cached: AIModelCatalog? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AIModelCatalog.self, from: data)
    }

    /// Когда список последний раз удачно получен с сервера
    static var lastUpdated: Date? {
        let stamp = UserDefaults.standard.double(forKey: fetchedAtKey)
        return stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
    }

    // MARK: Проверка идентификаторов

    /// Идентификатор безопасен для адреса запроса: только латиница, цифры, точка, дефис и подчёркивание
    static func isPlausibleModelId(_ id: String) -> Bool {
        guard id.count >= 3, id.count <= 64 else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
        return id.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// Идентификатор подходит провайдеру по началу имени (чужие и случайные имена в список не попадают)
    static func isValidModelId(_ id: String, for provider: AIProvider) -> Bool {
        guard isPlausibleModelId(id) else { return false }
        switch provider {
        case .gemini:
            return id.hasPrefix("gemini-")
        case .claude:
            return id.hasPrefix("claude-")
        case .chatgpt:
            if id.hasPrefix("gpt-") { return true }
            // o1, o3, o4-mini: «o» и цифра
            let chars = Array(id)
            return chars.count > 1 && chars[0] == "o" && chars[1].isNumber
        }
    }

    /// Оставляет подходящие идентификаторы без повторов, не больше `maxPerProvider`
    static func sanitize(_ ids: [String], for provider: AIProvider) -> [String] {
        var result: [String] = []
        for raw in ids {
            let id = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard isValidModelId(id, for: provider), !result.contains(id) else { continue }
            result.append(id)
            if result.count >= maxPerProvider { break }
        }
        return result
    }

    private struct Payload: Decodable {
        let version: Int?
        let updated: String?
        let gemini: [String]?
        let openai: [String]?
        let claude: [String]?
    }

    /// Разбирает ответ сервера. nil, если это не список моделей (чужая страница, пустой ответ, ни одной подходящей модели)
    static func parse(_ data: Data) -> AIModelCatalog? {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
        let catalog = AIModelCatalog(
            version: payload.version ?? 0,
            updated: String((payload.updated ?? "").prefix(32)),
            gemini: sanitize(payload.gemini ?? [], for: .gemini),
            openai: sanitize(payload.openai ?? [], for: .chatgpt),
            claude: sanitize(payload.claude ?? [], for: .claude)
        )
        if catalog.gemini.isEmpty && catalog.openai.isEmpty && catalog.claude.isEmpty { return nil }
        return catalog
    }

    // MARK: Обновление

    private enum FetchResult {
        case ok(AIModelCatalog)
        case offline
        case unavailable
    }

    private static func fetch() async -> FetchResult {
        guard AIProxy.isConfigured, let url = URL(string: AIProxy.baseURL)?.appendingPathComponent("v1/models") else {
            return .unavailable
        }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  data.count < 20_000, let catalog = parse(data) else {
                return .unavailable
            }
            return .ok(catalog)
        } catch {
            return isOffline(error) ? .offline : .unavailable
        }
    }

    private static func isOffline(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
             .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff:
            return true
        default:
            return false
        }
    }

    /// Все идентификаторы, которые приложение уже знало: сохранённый список и встроенные
    private static func knownModelIds() -> Set<String> {
        var known = Set<String>()
        for provider in AIProvider.allCases {
            known.formUnion(AIModelRegistry.builtinHierarchy(for: provider))
            known.formUnion(cached?.models(for: provider) ?? [])
        }
        return known
    }

    /// Подтягивает список с сервера. Без `force` ходит на сервер не чаще раза в 12 часов (после неудачи не чаще раза в час),
    /// с `force` (кнопка «Обновить модели») идёт всегда.
    static func refresh(force: Bool) async -> AIModelsRefreshResult {
        let defaults = UserDefaults.standard
        let now = Date().timeIntervalSince1970
        if !force {
            let fetchedAt = defaults.double(forKey: fetchedAtKey)
            let attemptedAt = defaults.double(forKey: attemptedAtKey)
            if now - fetchedAt < backgroundInterval || now - attemptedAt < retryInterval {
                return AIModelsRefreshResult(status: .upToDate, added: [], changedProviders: [])
            }
        }
        defaults.set(now, forKey: attemptedAtKey)

        let known = knownModelIds()
        let previous = cached

        switch await fetch() {
        case .ok(let catalog):
            if let data = try? JSONEncoder().encode(catalog) {
                defaults.set(data, forKey: storageKey)
            }
            defaults.set(now, forKey: fetchedAtKey)

            let added = AIProvider.allCases
                .flatMap { catalog.models(for: $0) }
                .filter { !known.contains($0) }
            // Без прежнего списка (первый запуск) считаем изменившимся только то, что отличается от встроенного
            let changed = AIProvider.allCases.filter { provider in
                let before = previous?.models(for: provider) ?? AIModelRegistry.builtinHierarchy(for: provider)
                return before != catalog.models(for: provider)
            }
            return AIModelsRefreshResult(status: added.isEmpty ? .upToDate : .updated, added: added, changedProviders: changed)
        case .offline:
            return AIModelsRefreshResult(status: .offline, added: [], changedProviders: [])
        case .unavailable:
            return AIModelsRefreshResult(status: .unavailable, added: [], changedProviders: [])
        }
    }
}
