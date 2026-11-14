import Foundation

// MARK: - Ссылки «для двоих»: подарок листом и вызов на дуэль
// Сервера у этих функций нет: всё нужное лежит в самой ссылке (JSON в base64url). Ссылка ведёт на страницу Worker
// (cloudflare/ai-proxy: /g и /d), которая показывает содержимое и предлагает «Открыть в приложении» или App Store.
// Данные стоят в части ссылки после «#»: браузер не отправляет её на сервер, поэтому текст подарка нигде не хранится
// и не попадает ни в какие журналы. В приложении ссылка открывается схемой armenianbible://gift?d=… и armenianbible://duel?d=…

enum PairLink {
    static let webBase = "https://luys-ai.samjan190799.workers.dev"
    static let scheme = "armenianbible"
    static let appStoreURL = "https://apps.apple.com/app/id6790569890"

    /// JSON в base64url без «=»: только буквы, цифры, «-» и «_», поэтому безопасно и в адресе, и в сообщении
    static func encode<T: Encodable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func decode<T: Decodable>(_ type: T.Type, from string: String) -> T? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// Адрес для сообщения: страница на Worker, данные после «#»
    static func webURL(path: String, payload: String) -> URL? {
        URL(string: "\(webBase)/\(path)#\(payload)")
    }

    /// Данные из ссылки приложения armenianbible://…?d=…
    static func payload(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "d" })?
            .value
    }

    /// Не даём чужой ссылке принести лишнее: имена и подписи обрезаются
    static func clean(_ text: String?, limit: Int) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        return String(text.prefix(limit))
    }
}

/// Текст и ссылка для окна «Поделиться»
struct PairShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}
