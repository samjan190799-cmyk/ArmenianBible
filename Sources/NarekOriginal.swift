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
