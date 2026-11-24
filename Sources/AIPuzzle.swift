import Foundation

// MARK: - ИИ-уровни игры «Собери стих» (логика; экран во вкладке «ИИ» в VersePuzzle.swift)
// Вкладка «ИИ» (по подписке): ИИ сам выбирает стихи по всей Библии, а уровни идут от известных стихов к редким и становятся сложнее.
// ИИ присылает только ссылки на стихи. Текст всегда берётся из офлайн-Библии приложения, поэтому выдуманной цитаты не бывает,
// а несуществующие ссылки отбрасываются. Десять уровней одной ступени приходят одним запросом и хранятся на телефоне:
// в загруженное можно играть без сети. Если ИИ недоступен, стихи подбирает само приложение по тем же правилам.

/// Ссылка на стих: номер книги по bible.db (1…66), глава, стих
struct AIPuzzleReference: Codable, Hashable {
    let bookId: Int
    let chapter: Int
    let verse: Int
}

/// Ссылка от ИИ вместе с названием книги, которое назвал ИИ: по названию проверяется, что номер книги не перепутан
struct AIPuzzleCandidate: Hashable {
    let reference: AIPuzzleReference
    let bookName: String?
}

/// Ступень сложности: десять уровней подряд
struct AIPuzzleTier: Equatable {
    /// Насколько известными брать стихи (подсказка для ИИ)
    enum Familiarity: String {
        case wellKnown = "well-known"
        case lessKnown = "less well-known"
        case rare = "rarely quoted"
    }

    let number: Int
    let minWords: Int
    let maxWords: Int
    /// Сколько плиток на экране
    let tiles: Int
    let hints: Int
    let attempts: Int
    let familiarity: Familiarity
}

// MARK: Правила
enum AIPuzzleLogic {
    /// Сколько уровней в ступени; столько же приходит в одной пачке от ИИ
    static let levelsPerTier = 10
    /// Сколько ссылок просить у ИИ: часть не пройдёт проверку по базе или по длине
    static let candidatesPerRequest = 16
    /// Сколько последних уровней назвать ИИ, чтобы он их не повторял
    static let maxExcluded = 40
    /// Когда непройденных загруженных уровней меньше этого числа, пора догружать следующую пачку
    static let refillThreshold = 3

    private static let tiers: [AIPuzzleTier] = [
        AIPuzzleTier(number: 1, minWords: 8, maxWords: 14, tiles: 6, hints: 2, attempts: 6, familiarity: .wellKnown),
        AIPuzzleTier(number: 2, minWords: 12, maxWords: 20, tiles: 8, hints: 2, attempts: 6, familiarity: .wellKnown),
        AIPuzzleTier(number: 3, minWords: 18, maxWords: 28, tiles: 8, hints: 1, attempts: 5, familiarity: .lessKnown),
        AIPuzzleTier(number: 4, minWords: 24, maxWords: 36, tiles: 8, hints: 1, attempts: 5, familiarity: .rare),
        AIPuzzleTier(number: 5, minWords: 30, maxWords: 50, tiles: 8, hints: 0, attempts: 4, familiarity: .rare)
    ]

    /// Номер ступени уровня: уровни 1–10 первая, 11–20 вторая и так далее
    static func tierNumber(forLevel level: Int) -> Int {
        (max(1, level) - 1) / levelsPerTier + 1
    }

    /// Параметры ступени уровня; начиная с пятой ступени сложность дальше не растёт
    static func tier(forLevel level: Int) -> AIPuzzleTier {
        tiers[min(tiers.count, tierNumber(forLevel: level)) - 1]
    }

    // MARK: Запрос к ИИ
    static func systemPrompt() -> String {
        """
        You choose Bible verses for a word-ordering puzzle game. Choose from the whole Bible, both Testaments, \
        using the standard 66-book canon (1 Genesis ... 39 Malachi, 40 Matthew ... 66 Revelation). \
        Each verse must express a complete thought on its own: no genealogies, lists of names, census numbers, \
        or verses that only introduce a speech. Spread the choices over many different books and never repeat a verse. \
        Answer with JSON only.
        """
    }

    static func userPrompt(tier: AIPuzzleTier, exclude: [AIPuzzleReference]) -> String {
        var text = """
        Give \(candidatesPerRequest) verses for difficulty step \(tier.number). \
        Length: roughly \(tier.minWords) to \(tier.maxWords) words in English. \
        Familiarity: \(tier.familiarity.rawValue) verses. \
        Answer exactly in this shape: {"verses":[{"b":43,"n":"John","c":3,"v":16}]} \
        where b is the book number, n the English book name, c the chapter and v the verse number.
        """
        if !exclude.isEmpty {
            let list = exclude.map { "\($0.bookId):\($0.chapter):\($0.verse)" }.joined(separator: ", ")
            text += " Do not use these (book:chapter:verse): \(list)."
        }
        return text
    }

    // MARK: Разбор ответа
    /// Ссылки из ответа ИИ: {"verses":[{"b":43,"n":"John","c":3,"v":16}]}, в том числе когда ответ завёрнут в блок кода
    static func parseCandidates(from answer: String) -> [AIPuzzleCandidate] {
        let cleaned = withoutFence(answer)
        guard let data = cleaned.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else { return [] }
        var items: [Any] = []
        if let dictionary = object as? [String: Any], let list = dictionary["verses"] as? [Any] {
            items = list
        } else if let list = object as? [Any] {
            items = list
        }
        var result: [AIPuzzleCandidate] = []
        for item in items {
            guard let entry = item as? [String: Any],
                  let book = intValue(entry["b"]),
                  let chapter = intValue(entry["c"]),
                  let verse = intValue(entry["v"]) else { continue }
            let reference = AIPuzzleReference(bookId: book, chapter: chapter, verse: verse)
            result.append(AIPuzzleCandidate(reference: reference, bookName: entry["n"] as? String))
        }
        return result
    }

    /// Число из JSON: целое, дробное или в кавычках; нелепые значения (бесконечность, миллиарды) отбрасываются
    private static func intValue(_ value: Any?) -> Int? {
        if let number = value as? Int { return number }
        if let number = value as? Double, number.isFinite, abs(number) < 1_000_000 { return Int(number) }
        if let text = value as? String { return Int(text.trimmingCharacters(in: .whitespaces)) }
        return nil
    }

    /// Ответ ИИ иногда приходит завёрнутым в блок кода: убираем обёртку
    private static func withoutFence(_ answer: String) -> String {
        var text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasPrefix("```") else { return text }
        if let newline = text.firstIndex(of: "\n") {
            text = String(text[text.index(after: newline)...])
        }
        if let fence = text.range(of: "```", options: .backwards) {
            text = String(text[..<fence.lowerBound])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Проверка по офлайн-Библии
    /// Названия книги от ИИ и из базы совпадают с точностью до регистра и знаков: «Psalm» годится для «Psalms»
    static func namesMatch(_ aiName: String, _ databaseName: String) -> Bool {
        let first = normalized(aiName)
        let second = normalized(databaseName)
        guard !first.isEmpty, !second.isEmpty else { return false }
        return first == second || first.contains(second) || second.contains(first)
    }

    private static func normalized(_ text: String) -> String {
        String(text.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }

    /// Подходит ли стих ступени: законченная мысль и длина в словах на языке игрока
    static func accepts(_ verse: BibleVerseText, tier: AIPuzzleTier, language: AppLanguage) -> Bool {
        guard VerseQuality.isMeaningful(textHy: verse.textHy, textRu: verse.textRu, textEn: verse.textEn) else { return false }
        let count = VersePuzzleLogic.tileWords(of: verse.text(for: language)).count
        return count >= tier.minWords && count <= tier.maxWords
    }

    /// Проверяет ссылку от ИИ по офлайн-Библии: книга и глава существуют, название книги не перепутано, стих есть и подходит ступени
    static func validate(_ candidate: AIPuzzleCandidate, tier: AIPuzzleTier, language: AppLanguage) -> AIPuzzleReference? {
        let reference = candidate.reference
        guard reference.bookId >= 1, reference.chapter >= 1, reference.verse >= 1,
              let book = BibleDatabase.shared.getBook(id: reference.bookId),
              reference.chapter <= book.chaptersCount else { return nil }
        if let name = candidate.bookName, !namesMatch(name, book.nameEn) { return nil }
        guard let verse = BibleDatabase.shared.getVerseText(bookId: reference.bookId, chapter: reference.chapter, verse: reference.verse),
              accepts(verse, tier: tier, language: language) else { return nil }
        return reference
    }

    /// Первые подходящие ссылки из списка ИИ: без повторов и без уже загруженных
    static func validated(_ candidates: [AIPuzzleCandidate], tier: AIPuzzleTier, language: AppLanguage,
                          exclude: Set<AIPuzzleReference>, limit: Int) -> [AIPuzzleReference] {
        var taken = exclude
        var result: [AIPuzzleReference] = []
        for candidate in candidates {
            guard result.count < limit else { break }
            guard !taken.contains(candidate.reference),
                  let reference = validate(candidate, tier: tier, language: language) else { continue }
            taken.insert(reference)
            result.append(reference)
        }
        return result
    }

    // MARK: Стих уровня
    /// Стих для игры по ссылке: настоящий текст из офлайн-Библии на трёх языках и название книги для подписи
    static func verse(for reference: AIPuzzleReference) -> BibleVerse? {
        guard let book = BibleDatabase.shared.getBook(id: reference.bookId),
              let text = BibleDatabase.shared.getVerseText(bookId: reference.bookId, chapter: reference.chapter, verse: reference.verse) else { return nil }
        let place = "\(reference.chapter):\(reference.verse)"
        return BibleVerse(
            textHy: text.textHy,
            textHyArarat: text.textHyArarat,
            textRu: text.textRu,
            textEn: text.textEn,
            refHy: "\(book.nameHy) \(place)",
            refRu: "\(book.nameRu) \(place)",
            refEn: "\(book.nameEn) \(place)",
            isPrayer: false
        )
    }

    // MARK: Запасной выбор без ИИ
    /// Случайные стихи всей Библии с теми же проверками. Нужен, когда ИИ не ответил или прислал мало подходящих.
    /// На подбор уходит до двух тысяч быстрых запросов к базе, поэтому вызывать не с главного потока
    static func localPicks(count: Int, tier: AIPuzzleTier, language: AppLanguage, exclude: Set<AIPuzzleReference>) -> [AIPuzzleReference] {
        guard count > 0 else { return [] }
        let books = BibleDatabase.shared.getBooks()
        guard !books.isEmpty else { return [] }
        var taken = exclude
        var result: [AIPuzzleReference] = []
        var attempts = 0
        while result.count < count && attempts < 2000 {
            attempts += 1
            guard let book = books.randomElement() else { break }
            let reference = AIPuzzleReference(
                bookId: book.id,
                chapter: Int.random(in: 1...max(1, book.chaptersCount)),
                verse: Int.random(in: 1...40)
            )
            guard !taken.contains(reference),
                  let verse = BibleDatabase.shared.getVerseText(bookId: reference.bookId, chapter: reference.chapter, verse: reference.verse),
                  accepts(verse, tier: tier, language: language) else { continue }
            taken.insert(reference)
            result.append(reference)
        }
        return result
    }
}

// MARK: - Хранилище ИИ-уровней
/// Загруженные уровни (ссылки) и звёзды по ним. Всё хранится на телефоне. Партии (попытки, подсказки) пишет общий VersePuzzleStore
final class AIPuzzleStore: ObservableObject {
    static let shared = AIPuzzleStore()

    private let levelsKey = "ai_puzzle_levels_v1"
    private let starsKey = "ai_puzzle_level_stars_v1"
    private let defaults = UserDefaults.standard

    /// Уровень N это levels[N - 1]
    @Published private(set) var levels: [AIPuzzleReference] = []
    /// Лучший результат по уровню: номер уровня → звёзды (1…3)
    @Published private(set) var levelStars: [Int: Int] = [:]

    private init() {
        if let data = defaults.data(forKey: levelsKey),
           let saved = try? JSONDecoder().decode([AIPuzzleReference].self, from: data) {
            levels = saved
        }
        let raw = defaults.dictionary(forKey: starsKey) as? [String: Int] ?? [:]
        for (key, value) in raw {
            if let level = Int(key), level > 0, value > 0 { levelStars[level] = min(3, value) }
        }
    }

    var loadedLevels: Int { levels.count }
    var completedLevels: Int { levelStars.count }
    var totalStars: Int { levelStars.values.reduce(0, +) }

    /// Первый ещё не пройденный уровень
    var nextLevel: Int {
        var level = 1
        while levelStars[level] != nil { level += 1 }
        return level
    }

    /// Сколько загруженных уровней ещё впереди (не пройдено)
    var unplayedAhead: Int { max(0, levels.count - (nextLevel - 1)) }

    /// Пора ли догружать следующую пачку
    var needsRefill: Bool { unplayedAhead < AIPuzzleLogic.refillThreshold }

    func reference(forLevel level: Int) -> AIPuzzleReference? {
        levels.indices.contains(level - 1) ? levels[level - 1] : nil
    }

    func stars(for level: Int) -> Int { levelStars[level] ?? 0 }

    /// Добавляет новые уровни в конец; стихи, которые уже загружены, пропускаются
    func append(_ references: [AIPuzzleReference]) {
        var known = Set(levels)
        let fresh = references.filter { known.insert($0).inserted }
        guard !fresh.isEmpty else { return }
        levels.append(contentsOf: fresh)
        if let data = try? JSONEncoder().encode(levels) {
            defaults.set(data, forKey: levelsKey)
        }
    }

    /// Записывает результат уровня (остаётся лучший). Возвращает true, если уровень пройден впервые
    @discardableResult
    func recordStars(level: Int, stars: Int) -> Bool {
        guard level > 0, stars > 0 else { return false }
        let first = levelStars[level] == nil
        levelStars[level] = max(levelStars[level] ?? 0, min(3, stars))
        var raw: [String: Int] = [:]
        for (key, value) in levelStars { raw[String(key)] = value }
        defaults.set(raw, forKey: starsKey)
        return first
    }
}

// MARK: - Загрузка пачки
struct AIPuzzleBatchResult {
    /// Сколько уровней добавлено
    let added: Int
    /// true, если хотя бы часть стихов выбрал ИИ; false, если пачку собрало само приложение (ИИ недоступен)
    let usedAI: Bool
}

enum AIPuzzleService {
    /// Догружает следующую пачку: десять уровней одной ступени. ИИ присылает ссылки, приложение проверяет их по Библии
    /// и добирает недостающее само. Ошибка ИИ (нет сети, лимит, нет согласия) пачку не отменяет
    @MainActor
    static func loadNextBatch(language: AppLanguage) async -> AIPuzzleBatchResult {
        let store = AIPuzzleStore.shared
        let loaded = store.loadedLevels
        let tier = AIPuzzleLogic.tier(forLevel: loaded + 1)
        let need = AIPuzzleLogic.levelsPerTier - (loaded % AIPuzzleLogic.levelsPerTier)
        let known = Set(store.levels)
        let recent = Array(store.levels.suffix(AIPuzzleLogic.maxExcluded))

        var picked: [AIPuzzleReference] = []
        do {
            let answer = try await AIProxy.generate(
                prompt: AIPuzzleLogic.userPrompt(tier: tier, exclude: recent),
                systemPrompt: AIPuzzleLogic.systemPrompt(),
                jsonMode: true,
                maxTokens: 900,
                task: .puzzle
            )
            let candidates = AIPuzzleLogic.parseCandidates(from: answer)
            picked = await Task.detached(priority: .utility) {
                AIPuzzleLogic.validated(candidates, tier: tier, language: language, exclude: known, limit: need)
            }.value
        } catch {
            // ИИ недоступен: ниже недостающие стихи подбирает само приложение
        }

        let fromAI = picked.count
        if picked.count < need {
            let missing = need - picked.count
            let taken = known.union(picked)
            let more = await Task.detached(priority: .utility) {
                AIPuzzleLogic.localPicks(count: missing, tier: tier, language: language, exclude: taken)
            }.value
            picked.append(contentsOf: more)
        }

        store.append(picked)
        Funnel.track("feature_used", ["feature": fromAI > 0 ? "puzzle_ai_batch" : "puzzle_ai_fallback"])
        return AIPuzzleBatchResult(added: picked.count, usedAI: fromAI > 0)
    }
}
