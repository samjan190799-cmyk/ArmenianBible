import Foundation

// MARK: - Подлинный текст «Մատեան Ողբերգութեան» (Книга скорбных песнопений) на древнеармянском
// Файл narek_original_hy.json собран из hy.wikisource.org скриптом Tools/NarekOriginal/build_original.py (см. README рядом).
// Это только оригинал (грабар): переводы на русский и английский защищены авторским правом и в приложение не входят.

struct NarekOriginalStanza: Codable, Hashable {
    /// Армянская цифра строфы («Ա», «Բ», «ԺԱ»); у строфы без цифры в источнике пусто
    let label: String
    let lines: [String]
}

struct NarekOriginalChapter: Codable, Identifiable, Hashable {
    /// Порядковый номер главы, 1…95: он же номер записи в аудиоплеере
    let id: Int
    /// Подпись главы в источнике: «Բան Ա»
    let ban: String
    /// Заголовок главы (одна-две строки, в обычном регистре)
    let titleLines: [String]
    let stanzas: [NarekOriginalStanza]

    /// Весь текст главы: строфы через пустую строку
    var text: String {
        stanzas.map { $0.lines.joined(separator: "\n") }.joined(separator: "\n\n")
    }

    /// Первая строка главы: подпись в списке
    var preview: String {
        stanzas.first?.lines.first ?? ""
    }
}

struct NarekOriginalSource: Codable {
    let title: String
    let site: String
    let url: String
    /// Номер правки страницы на Wikisource, с которой собран файл
    let revision: Int
}

private struct NarekOriginalFile: Codable {
    let source: NarekOriginalSource
    let chapters: [NarekOriginalChapter]
}

final class NarekOriginal {
    static let shared = NarekOriginal()

    let source: NarekOriginalSource?
    let chapters: [NarekOriginalChapter]

    private init() {
        if let url = Bundle.main.url(forResource: "narek_original_hy", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(NarekOriginalFile.self, from: data) {
            source = file.source
            chapters = file.chapters
        } else {
            source = nil
            chapters = []
        }
    }

    func chapter(id: Int) -> NarekOriginalChapter? {
        chapters.first { $0.id == id }
    }
}

// MARK: - Современный армянский (աշխարհաբար): ссылки на переводы на hy.wikisource.org
/// Два перевода на восточноармянский лежат на hy.wikisource.org рядом с оригиналом. Это работы XX века (Мкртич Херанян, 1899–1970;
/// Вазген Геворкян), страницы Wikisource не указывают лицензию, а права на них не проверены, поэтому текст в приложение не копируется:
/// в чтении главы есть только ссылка на то место страницы, где он размещён.
enum NarekModernArmenian {
    struct Translation: Identifiable {
        let id: String
        let translator: String
        let pageTitle: String
        /// Последняя глава, которая есть в переводе: у Геворкяна нет 95-й
        let lastChapter: Int
    }

    static let translations: [Translation] = [
        Translation(id: "kheranyan", translator: "Մկրտիչ Խերանյան", pageTitle: "Մատյան ողբերգության (Մկրտիչ Խերանյան)", lastChapter: 95),
        Translation(id: "gevorgyan", translator: "Վազգեն Գևորգյան", pageTitle: "Մատյան ողբերգության (Վազգեն Գևորգյան)", lastChapter: 94)
    ]

    /// Ссылка на главу в переводе: страница одна на всю книгу, у каждой главы свой заголовок («Բան Ա»)
    static func url(for translation: Translation, chapter: Int) -> URL? {
        guard chapter >= 1, chapter <= translation.lastChapter else { return nil }
        // В заголовке 87-й главы на Wikisource везде та же опечатка, что в оригинале: «Բան ԶԷ» вместо «Բան ՁԷ»
        let heading = chapter == 87 ? "Բան ԶԷ" : NarekOriginal.shared.chapter(id: chapter)?.ban
        var components = URLComponents()
        components.scheme = "https"
        components.host = "hy.wikisource.org"
        components.path = "/wiki/" + translation.pageTitle.replacingOccurrences(of: " ", with: "_")
        components.fragment = heading?.replacingOccurrences(of: " ", with: "_")
        return components.url
    }
}
