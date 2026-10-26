import Foundation

// MARK: - Серверный ИИ для подписчиков
/// Вопрос уходит на Worker Cloudflare (папка cloudflare/ai-proxy), ключ ИИ хранится только там. Подписчику не нужен свой ключ.
/// Пока `baseURL` пуст, приложение работает как раньше: только со своим ключом человека.
enum AIProxy {
    /// Адрес развёрнутого Worker, например "https://luys-ai.<поддомен>.workers.dev" (см. cloudflare/ai-proxy/README.md)
    static let baseURL = ""

    /// Подставляется вместо ключа провайдера: AIModelRegistry видит его и отправляет запрос на сервер
    static let sentinelKey = "luys-premium-server"

    /// Сообщения об ошибке с этим префиксом уже написаны для человека и показываются как есть
    static let messagePrefix = "[luys]"

    static var isConfigured: Bool { !baseURL.isEmpty }

    /// Серверный ИИ работает для подписчика, когда адрес сервера задан
    static var isAvailableForCurrentUser: Bool {
        isConfigured && SubscriptionManager.premiumSnapshot
    }

    private static func failure(_ code: Int, _ text: String) -> NSError {
        NSError(domain: "AIProxy", code: code, userInfo: [NSLocalizedDescriptionKey: messagePrefix + text])
    }

    static func generate(prompt: String, systemPrompt: String?, jsonMode: Bool, maxTokens: Int) async throws -> String {
        let language = BibleManager.shared.appLanguage
        guard let url = URL(string: baseURL)?.appendingPathComponent("v1/generate") else {
            throw failure(500, language.pick(hy: "Սերվերի հասցեն սխալ է", ru: "Неверный адрес сервера ИИ", en: "Invalid AI server address"))
        }
        guard let transaction = await SubscriptionManager.shared.currentEntitlementJWS() else {
            throw failure(401, language.pick(
                hy: "Չհաջողվեց հաստատել բաժանորդագրությունը: Բացեք բաժանորդագրության էկրանը և սեղմեք «Վերականգնել գնումները»",
                ru: "Не удалось подтвердить подписку. Откройте экран подписки и нажмите «Восстановить покупки»",
                en: "Could not confirm your subscription. Open the subscription screen and tap “Restore Purchases”"
            ))
        }

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "prompt": prompt,
            "transaction": transaction,
            "json": jsonMode,
            "maxTokens": maxTokens
        ]
        if let systemPrompt, !systemPrompt.isEmpty {
            body["system"] = systemPrompt
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

        if status == 200, let text = json?["text"] as? String, !text.isEmpty {
            return text
        }

        let reason = (json?["reason"] as? String) ?? (json?["error"] as? String) ?? "\(status)"
        switch status {
        case 401, 403:
            throw failure(status, language.pick(
                hy: "Բաժանորդագրությունը հաստատված չէ (\(reason)): Բացեք բաժանորդագրության էկրանը և սեղմեք «Վերականգնել գնումները»",
                ru: "Подписка не подтверждена (\(reason)). Откройте экран подписки и нажмите «Восстановить покупки»",
                en: "Your subscription could not be confirmed (\(reason)). Open the subscription screen and tap “Restore Purchases”"
            ))
        case 429:
            throw failure(status, language.pick(
                hy: "Այսօրվա հարցերի սահմանաչափը սպառվել է: Այն կթարմացվի վաղը",
                ru: "Лимит вопросов на сегодня исчерпан. Он обновится завтра",
                en: "Today's question limit is reached. It resets tomorrow"
            ))
        case 503:
            throw failure(status, language.pick(
                hy: "ԱԲ ծառայությունը ժամանակավորապես ծանրաբեռնված է, փորձեք ավելի ուշ",
                ru: "Сервис ИИ сейчас перегружен, попробуйте позже",
                en: "The AI service is busy right now, please try again later"
            ))
        default:
            throw failure(status, language.pick(
                hy: "ԱԲ-ն չպատասխանեց, փորձեք կրկին",
                ru: "ИИ не ответил, попробуйте ещё раз",
                en: "The AI did not respond, please try again"
            ))
        }
    }
}
