import Foundation
import UIKit

// MARK: - Согласие на отправку вопроса стороннему ИИ
/// Перед первым запросом через сервер человек один раз соглашается, что вопрос уйдёт через наш сервер к Google Gemini.
/// Окно показываем средствами UIKit поверх всего, что открыто (листы, викторина), иначе запрос завис бы за листом.
@MainActor
enum AIServerConsent {
    private static let storageKey = "ai_server_consent_v1"

    static var isGiven: Bool { UserDefaults.standard.bool(forKey: storageKey) }

    static func ensure() async -> Bool {
        if isGiven { return true }
        guard let presenter = topViewController(), !(presenter is UIAlertController) else { return false }
        let language = BibleManager.shared.appLanguage
        return await withCheckedContinuation { continuation in
            let alert = UIAlertController(
                title: language.pick(hy: "ԱԲ մեր սերվերի միջոցով", ru: "ИИ через наш сервер", en: "AI through our server"),
                message: language.pick(
                    hy: "Ձեր հարցը կփոխանցվի հավելվածի սերվերի միջոցով Google Gemini ծառայությանը՝ պատասխան ստանալու համար: Մենք հարցերն ու պատասխանները չենք պահպանում: Հարցում մի գրեք տվյալներ, որոնցով կարելի է ճանաչել ձեզ:",
                    ru: "Ваш вопрос будет передан через сервер приложения сервису Google Gemini, чтобы получить ответ. Мы не сохраняем вопросы и ответы. Не пишите в вопросе данные, по которым вас можно узнать.",
                    en: "Your question will be sent through the app's server to Google Gemini to get an answer. We do not store questions or answers. Please do not include information that could identify you."
                ),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: language.pick(hy: "Համաձայն եմ", ru: "Согласен", en: "I agree"), style: .default) { _ in
                UserDefaults.standard.set(true, forKey: storageKey)
                continuation.resume(returning: true)
            })
            alert.addAction(UIAlertAction(title: language.pick(hy: "Չեղարկել", ru: "Отмена", en: "Cancel"), style: .cancel) { _ in
                continuation.resume(returning: false)
            })
            presenter.present(alert, animated: true)
        }
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        guard var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - Задачи ИИ
/// Для чего запрос. Имена совпадают с белым списком Worker (cloudflare/ai-proxy/src/tasks.js): для каждой задачи
/// там можно задать отдельный ключ Gemini (`GEMINI_API_KEY_<ЗАДАЧА>`), свой список моделей и суточный потолок.
/// Если для задачи ничего не задано, она работает на общем ключе, как раньше.
enum AITask: String {
    /// Всё, что не относится к задачам ниже
    case general
    /// Чат «Духовный Проводник»
    case chat
    /// Генерация вопросов викторины
    case quiz
    /// «Нарек утешает»: слово утешения
    case consolation
    /// Толкование стиха
    case explain
    /// Подбор и генерация стиха
    case verse
}

// MARK: - Серверный ИИ: для подписчиков и для бесплатных вопросов
/// Вопрос уходит на Worker Cloudflare (папка cloudflare/ai-proxy), ключ ИИ хранится только там. Свой ключ человеку не нужен.
/// Подписчик подтверждается подписанной Apple покупкой, бесплатный вопрос идёт под случайным номером установки
/// и с малым суточным лимитом (сколько вопросов осталось, решает `SubscriptionManager.canAskAI`).
/// Пока `baseURL` пуст, приложение работает как раньше: только со своим ключом человека.
enum AIProxy {
    /// Адрес развёрнутого Worker (см. cloudflare/ai-proxy/README.md)
    static let baseURL = "https://luys-ai.samjan190799.workers.dev"

    /// Подставляется вместо ключа провайдера: AIModelRegistry видит его и отправляет запрос на сервер
    static let sentinelKey = "luys-premium-server"

    /// Сообщения об ошибке с этим префиксом уже написаны для человека и показываются как есть
    static let messagePrefix = "[luys]"

    static var isConfigured: Bool { !baseURL.isEmpty }

    /// Серверный ИИ доступен всем, когда адрес сервера задан: подписчику по подписке, остальным в пределах бесплатных вопросов
    static var isAvailableForCurrentUser: Bool {
        isConfigured
    }

    /// Случайный номер этой установки для бесплатных вопросов: по нему сервер считает суточный лимит.
    /// Ни с именем, ни с Apple ID, ни с рекламным идентификатором он не связан и стирается вместе с приложением.
    private static var installId: String {
        let key = "ai_install_id_v1"
        if let saved = UserDefaults.standard.string(forKey: key), UUID(uuidString: saved) != nil {
            return saved.lowercased()
        }
        let created = UUID().uuidString.lowercased()
        UserDefaults.standard.set(created, forKey: key)
        return created
    }

    private static func failure(_ code: Int, _ text: String) -> NSError {
        NSError(domain: "AIProxy", code: code, userInfo: [NSLocalizedDescriptionKey: messagePrefix + text])
    }

    // MARK: Один быстрый повтор
    /// Пауза перед повтором: сервер или Google на секунду споткнулись
    private static let retryDelay: UInt64 = 1_500_000_000
    /// Повторяем только быструю неудачу: после долгого ожидания человек и так ждал достаточно
    private static let retryWindow: TimeInterval = 20

    /// Ответы сервера, после которых один повтор имеет смысл: сбой Google (502), исключение (500), таймаут Google (504)
    /// и перегрузка (503), кроме общего потолка расходов и ненастроенного ключа (там повтор ничего не изменит)
    private static func isRetryable(status: Int, json: [String: Any]?) -> Bool {
        switch status {
        case 500, 502, 504:
            return true
        case 503:
            let reason = json?["error"] as? String
            return reason != "busy" && reason != "not_configured"
        default:
            return false
        }
    }

    /// Обрыв соединения, после которого повтор может сработать. Таймаут и «нет интернета» не повторяем
    private static func isRetryable(networkError error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        let codes = [NSURLErrorNetworkConnectionLost, NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed, NSURLErrorSecureConnectionFailed]
        return codes.contains(nsError.code)
    }

    static func generate(prompt: String, systemPrompt: String?, jsonMode: Bool, maxTokens: Int, task: AITask = .general) async throws -> String {
        let language = BibleManager.shared.appLanguage
        guard let url = URL(string: baseURL)?.appendingPathComponent("v1/generate") else {
            throw failure(500, language.pick(hy: "Սերվերի հասցեն սխալ է", ru: "Неверный адрес сервера ИИ", en: "Invalid AI server address"))
        }
        guard await AIServerConsent.ensure() else {
            throw failure(451, language.pick(
                hy: "Առանց համաձայնության հարցը չի կարող ուղարկվել սերվերին",
                ru: "Без согласия вопрос нельзя отправить на сервер",
                en: "The question cannot be sent to the server without your consent"
            ))
        }
        // Подписчик идёт по подписанной Apple покупке. Без подписки (и у тех, чью покупку StoreKit не показывает,
        // например ранних покупателей) вопрос идёт как бесплатный, под номером установки
        var transaction: String?
        if SubscriptionManager.premiumSnapshot {
            transaction = await SubscriptionManager.shared.currentEntitlementJWS()
        }
        let isFree = transaction == nil

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "prompt": prompt,
            "json": jsonMode,
            "maxTokens": maxTokens,
            // Для какой задачи запрос: сервер берёт для неё свой ключ, свои модели и свой суточный потолок
            "task": task.rawValue
        ]
        if let transaction {
            body["transaction"] = transaction
        } else {
            body["installId"] = installId
        }
        if let systemPrompt, !systemPrompt.isEmpty {
            body["system"] = systemPrompt
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Один быстрый повтор при сбое сервера или обрыве соединения. Сервер при сбое ИИ вопрос человеку не засчитывает,
        // поэтому повтор не тратит лимит. Таймаут не повторяем: человек уже прождал минуту
        var status = 0
        var json: [String: Any]?
        var retried = false
        while true {
            let started = Date()
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                status = (response as? HTTPURLResponse)?.statusCode ?? 0
                json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            } catch {
                guard !retried, isRetryable(networkError: error), Date().timeIntervalSince(started) < retryWindow else { throw error }
                retried = true
                Funnel.track("feature_used", ["feature": "ai_retry"])
                try await Task.sleep(nanoseconds: retryDelay)
                continue
            }
            if !retried, status != 200, isRetryable(status: status, json: json), Date().timeIntervalSince(started) < retryWindow {
                retried = true
                Funnel.track("feature_used", ["feature": "ai_retry"])
                try await Task.sleep(nanoseconds: retryDelay)
                continue
            }
            break
        }
        if retried, status == 200 {
            Funnel.track("feature_used", ["feature": "ai_retry_ok"])
        }

        if status == 200, let text = json?["text"] as? String, !text.isEmpty {
            return text
        }

        let reason = (json?["reason"] as? String) ?? (json?["error"] as? String) ?? "\(status)"
        switch status {
        case 401, 403:
            // ИИ-викторина только по подписке: сервер отказывает по задаче quiz без подтверждённой подписки (403 quiz_premium).
            // Подписчику, чью покупку не удалось подтвердить, подсказываем восстановить покупки.
            if isFree && task == .quiz {
                throw failure(status, language.pick(
                    hy: "AI վիկտորինան հասանելի է Premium բաժանորդագրությամբ: Եթե այն ունեք, բացեք բաժանորդագրության էկրանը և սեղմեք «Վերականգնել գնումները»",
                    ru: "ИИ-викторина доступна по подписке Premium. Если подписка у вас есть, откройте экран подписки и нажмите «Восстановить покупки»",
                    en: "The AI quiz comes with Premium. If you already subscribed, open the subscription screen and tap “Restore Purchases”"
                ))
            }
            if isFree {
                throw failure(status, language.pick(
                    hy: "Անվճար հարցերն այժմ հասանելի չեն: Փորձեք ավելի ուշ կամ ձեռք բերեք բաժանորդագրություն",
                    ru: "Бесплатные вопросы сейчас недоступны. Попробуйте позже или оформите подписку",
                    en: "Free questions are unavailable right now. Try again later or subscribe"
                ))
            }
            throw failure(status, language.pick(
                hy: "Բաժանորդագրությունը հաստատված չէ (\(reason)): Բացեք բաժանորդագրության էկրանը և սեղմեք «Վերականգնել գնումները»",
                ru: "Подписка не подтверждена (\(reason)). Откройте экран подписки и нажмите «Восстановить покупки»",
                en: "Your subscription could not be confirmed (\(reason)). Open the subscription screen and tap “Restore Purchases”"
            ))
        case 429:
            if isFree {
                throw failure(status, language.pick(
                    hy: "Այսօրվա անվճար հարցերը սպառվել են: Վաղը կթարմացվեն, իսկ բաժանորդագրությամբ հարցերը շատ ավելի շատ են",
                    ru: "Бесплатные вопросы на сегодня закончились. Они обновятся завтра, а с подпиской их гораздо больше",
                    en: "Today's free questions are used up. They reset tomorrow, and a subscription gives many more"
                ))
            }
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
