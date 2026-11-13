import Foundation

// MARK: - Анонимная воронка
/// Какие экраны открывают и где останавливаются. События уходят на тот же Worker (cloudflare/ai-proxy, POST /v1/events),
/// там считаются и показываются на странице /dashboard. В событиях нет текста вопросов, имён, почты и рекламного
/// идентификатора: только короткие слова из белого списка (см. cloudflare/ai-proxy/src/events.js) и случайный номер установки.
/// Человек может выключить сбор в «Настройках». Пока `AIProxy.baseURL` пуст, ничего не отправляется.
enum Funnel {
    static let enabledKey = "funnel_enabled"
    private static let installKey = "funnel_install_id"
    private static let firstOpenKey = "funnel_first_open"
    private static let pendingKey = "funnel_pending_v1"

    private static let batchSize = 20
    private static let pendingLimit = 200

    // Всё ниже трогаем только на этой очереди
    private static let queue = DispatchQueue(label: "luys.funnel", qos: .utility)
    private static var pending: [[String: Any]] = []
    private static var loaded = false
    private static var isSending = false
    private static var scheduled: DispatchWorkItem?

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) == nil ? true : UserDefaults.standard.bool(forKey: enabledKey)
    }

    /// Симулятор (съёмка скриншотов и роликов в CI) не человек: каждый его запуск выглядел бы новой установкой и портил цифры
    private static let isSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()

    /// Событие с параметрами из белого списка. Вызывается откуда угодно: само уходит на свою очередь
    static func track(_ name: String, _ params: [String: String] = [:]) {
        guard AIProxy.isConfigured, isEnabled, !isSimulator else { return }
        let event: [String: Any] = ["name": name, "params": params, "ts": Int(Date().timeIntervalSince1970)]
        queue.async {
            loadIfNeeded()
            pending.append(event)
            if pending.count > pendingLimit {
                pending.removeFirst(pending.count - pendingLimit)
            }
            save()
            if pending.count >= batchSize {
                sendNext()
            } else {
                schedule(after: 4)
            }
        }
    }

    /// Запуск приложения: сколько дней прошло с первой установки, чтобы отличать новичков от вернувшихся
    static func start() {
        let defaults = UserDefaults.standard
        let first = defaults.object(forKey: firstOpenKey) as? Date ?? Date()
        if defaults.object(forKey: firstOpenKey) == nil {
            defaults.set(first, forKey: firstOpenKey)
        }
        let days = Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 0
        let bucket: String
        switch days {
        case ..<1: bucket = "d0"
        case 1: bucket = "d1"
        case 2...3: bucket = "d2_3"
        case 4...7: bucket = "d4_7"
        default: bucket = "d8p"
        }
        track("app_open", ["day": bucket])
    }

    /// Сколько человек смотрел экран, грубо
    static func secondsBucket(_ seconds: TimeInterval) -> String {
        switch seconds {
        case ..<5: return "lt5"
        case 5..<15: return "s5_15"
        case 15..<60: return "s15_60"
        default: return "s60p"
        }
    }

    /// Отправить накопленное сейчас (например, при сворачивании приложения)
    static func flushNow() {
        queue.async { sendNext() }
    }

    // MARK: - Очередь и отправка

    private static func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if let data = UserDefaults.standard.data(forKey: pendingKey),
           let stored = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] {
            pending = stored
        }
    }

    private static func save() {
        if let data = try? JSONSerialization.data(withJSONObject: pending) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }

    private static func schedule(after seconds: Double) {
        scheduled?.cancel()
        let item = DispatchWorkItem { sendNext() }
        scheduled = item
        queue.asyncAfter(deadline: .now() + seconds, execute: item)
    }

    private static func installId() -> String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: installKey) { return existing }
        let created = UUID().uuidString.lowercased()
        defaults.set(created, forKey: installKey)
        return created
    }

    private static func languageCode() -> String {
        switch BibleManager.shared.appLanguage {
        case .armenian: return "hy"
        case .russian: return "ru"
        case .english: return "en"
        }
    }

    private static func sendNext() {
        loadIfNeeded()
        guard !isSending, !pending.isEmpty, AIProxy.isConfigured, isEnabled, !isSimulator,
              let url = URL(string: AIProxy.baseURL)?.appendingPathComponent("v1/events") else { return }

        let batch = Array(pending.prefix(batchSize))
        let info = Bundle.main.infoDictionary
        let body: [String: Any] = [
            "installId": installId(),
            "app": (info?["CFBundleShortVersionString"] as? String) ?? "0",
            "build": (info?["CFBundleVersion"] as? String) ?? "0",
            "lang": languageCode(),
            "premium": SubscriptionManager.premiumSnapshot,
            "events": batch
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        isSending = true

        URLSession.shared.dataTask(with: request) { _, response, error in
            queue.async {
                isSending = false
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                // 2xx принято; 4xx пачку не примут и в другой раз, её выбрасываем; сеть и 5xx оставляем на потом
                if error == nil, (200..<500).contains(status) {
                    pending.removeFirst(min(batch.count, pending.count))
                    save()
                    if !pending.isEmpty { sendNext() }
                } else {
                    schedule(after: 60)
                }
            }
        }.resume()
    }
}
