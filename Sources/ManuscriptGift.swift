import Foundation

// MARK: - Лист в подарок
// Человек пишет лист (свой текст, поводы, стих) и отправляет ссылку. У получателя лист оживает в приложении: перо пишет
// текст, золото блестит, а в памятной записи внизу стоит имя того, кто подарил. Нет приложения: страница на Worker
// покажет текст и предложит App Store.

struct ManuscriptGiftPayload: Codable {
    let t: String     // текст листа
    let c: String     // подпись под текстом (повод или ссылка на стих)
    let l: String     // язык листа
    let s: String?    // стиль миниатюры
    let f: String?    // основа листа
    let k: String?    // письмо (обычное или месроповское)
    let n: String?    // кто подарил
}

enum ManuscriptGift {
    static let textLimit = 400

    /// Ссылка на лист для сообщения; nil, если лист не удалось упаковать
    static func link(for page: ManuscriptPage, senderName: String) -> URL? {
        let payload = ManuscriptGiftPayload(
            t: String(page.text.prefix(textLimit)),
            c: String(page.reference.prefix(80)),
            l: page.language.rawValue,
            s: page.style.rawValue,
            f: page.surface.rawValue,
            k: page.script.rawValue,
            n: PairLink.clean(senderName, limit: 40)
        )
        guard let encoded = PairLink.encode(payload) else { return nil }
        return PairLink.webURL(path: "g", payload: encoded)
    }

    /// Лист из ссылки armenianbible://gift?d=…; nil, если ссылка повреждена или текста нет
    static func page(from url: URL) -> ManuscriptPage? {
        guard let encoded = PairLink.payload(from: url),
              let payload = PairLink.decode(ManuscriptGiftPayload.self, from: encoded),
              let text = PairLink.clean(payload.t, limit: textLimit) else { return nil }
        let sender = PairLink.clean(payload.n, limit: 40)
        var page = ManuscriptPage(
            text: text,
            reference: PairLink.clean(payload.c, limit: 80) ?? "",
            language: AppLanguage(rawValue: payload.l) ?? .armenian,
            style: ManuscriptStyle(rawValue: payload.s ?? "") ?? .roslin,
            surface: ManuscriptSurface(rawValue: payload.f ?? "") ?? .parchment,
            script: ManuscriptScript(rawValue: payload.k ?? ""),
            name: sender ?? ""
        )
        page.giftFrom = sender
        return page
    }

    /// Текст сообщения со ссылкой, на языке отправителя
    static func message(for language: AppLanguage, url: URL) -> String {
        let intro = language.pick(
            hy: "Էջ քեզ համար ✍️ Բացիր, և գրիչը կգրի այն.",
            ru: "Лист для тебя ✍️ Открой, и перо напишет его:",
            en: "A page for you ✍️ Open it and the quill will write it:"
        )
        return intro + "\n" + url.absoluteString
    }
}
