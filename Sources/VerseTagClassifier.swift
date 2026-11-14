import Foundation

// MARK: - Категории избранных стихов по смыслу
// У заметок и выделений теги выбирает человек, а у стихов в «Избранном» их не было: при выборе категории
// такие стихи просто пропадали. Теперь категория стиха определяется по смыслу русского и английского текста
// (армянский текст не анализируется: у каждого избранного стиха есть все три перевода) и по книге.
// Определение не зависит от языка интерфейса, поэтому стих не «прыгает» между категориями при смене языка.
// Не больше двух категорий на стих; если смысл не уловлен, берётся «Вера»: она самая широкая.

extension VerseTag {
    private struct Signals {
        /// Начала слов: «мудр» находит «мудрый», «мудрых», «мудрость»
        let stems: [String]
        /// Слова целиком (чтобы короткие слова не цепляли чужие)
        let words: Set<String>
        /// Фразы целиком
        let phrases: [String]
    }

    private static let signals: [(tag: VerseTag, signal: Signals)] = [
        (.faith, Signals(
            stems: ["верова", "верующ", "уверов", "довер", "спас", "освобод", "свобод", "воскрес", "искуп",
                    "faith", "believ", "salvation", "saviour", "savior", "redeem", "redemption", "resurrect", "freedom", "liberty"],
            words: ["вера", "веры", "вере", "веру", "верой", "верить", "верит", "верю", "верую", "веруй", "верьте",
                    "save", "saved", "saves", "risen", "free", "freed"],
            phrases: ["жизнь вечн", "eternal life", "everlasting life"]
        )),
        (.hope, Signals(
            stems: ["надежд", "надея", "упова", "ожида", "чаян", "будущ", "грядущ",
                    "hope", "expect", "future", "anchor", "endur"],
            words: ["wait", "waited", "waiting", "trust", "trusted"],
            phrases: []
        )),
        (.love, Signals(
            stems: ["любов", "любит", "любящ", "возлюб", "милост", "милосерд", "сострада", "нежн", "ласк", "прощ",
                    "love", "lovingkind", "merc", "compassion", "tender", "beloved", "charity", "forgiv"],
            words: ["люби", "любите", "любим", "прости", "kind", "kindness", "loved", "loves"],
            phrases: []
        )),
        (.grief, Signals(
            stems: ["скорб", "печал", "плач", "слез", "страда", "прослез", "тоск", "уныни", "утеш", "смерт", "болезн", "немощ",
                    "стон", "беда", "бедств", "гоне", "испытан", "искуш",
                    "sorrow", "grief", "grieve", "mourn", "tear", "weep", "suffer", "afflict", "trouble", "pain", "comfort",
                    "death", "sick", "trial", "tribulation", "persecut", "distress", "lament"],
            words: ["горе", "горю", "горем", "died", "cry", "cried", "wept"],
            phrases: ["долина смерт", "valley of the shadow"]
        )),
        (.gratitude, Signals(
            stems: ["благодар", "благодат", "хвал", "воспо", "радост", "радуй", "радова", "ликуй", "славь",
                    "thank", "grateful", "gratitude", "praise", "rejoic", "joy", "glad", "bless", "grace"],
            words: ["sing", "sang"],
            phrases: []
        )),
        (.wisdom, Signals(
            stems: ["мудр", "разум", "знани", "учени", "наставл", "истин", "закон", "заповед", "позна", "уразум", "учит",
                    "притч", "совет", "безум", "глупц",
                    "wisdom", "wise", "understand", "knowledge", "instruct", "truth", "law", "command", "learn", "teach",
                    "counsel", "proverb", "fool"],
            words: ["слово", "слова", "словом", "word", "words"],
            phrases: []
        )),
        (.prayer, Signals(
            stems: ["молит", "молис", "помоли", "моле", "взыва", "призов", "призыв", "услыш", "поклон", "свят", "храм",
                    "алтар", "славосл", "помилуй",
                    "pray", "worship", "holy", "holiness", "temple", "altar", "sanctu", "hallow"],
            words: ["просите", "проси", "прошу", "аминь", "господи", "боже", "amen", "ask", "seek", "hear", "heard"],
            phrases: ["call upon", "call on the"]
        ))
    ]

    /// Результаты определения по номеру избранного стиха: текст стиха не меняется, поэтому считаем один раз
    private final class TagBox {
        let tags: [VerseTag]
        init(_ tags: [VerseTag]) { self.tags = tags }
    }

    private static let cache: NSCache<NSString, TagBox> = {
        let cache = NSCache<NSString, TagBox>()
        cache.countLimit = 1000
        return cache
    }()

    /// Категории стиха из «Избранного»: одна или две, самые подходящие по смыслу
    static func suggested(for item: FavoriteItem) -> [VerseTag] {
        let key = item.id.uuidString as NSString
        if let cached = cache.object(forKey: key) { return cached.tags }
        let tags = classify(textRu: item.textRu, textEn: item.textEn, refRu: item.refRu, refEn: item.refEn)
        cache.setObject(TagBox(tags), forKey: key)
        return tags
    }

    /// Определение категорий по тексту и ссылке (отдельно от кэша: так проще проверять)
    static func classify(textRu: String, textEn: String, refRu: String, refEn: String) -> [VerseTag] {
        let text = (stripNotes(textRu) + " " + stripNotes(textEn)).lowercased()
        let tokens = text.split(whereSeparator: { !$0.isLetter }).map(String.init)

        var scores: [VerseTag: Int] = [:]
        for entry in signals {
            var score = 0
            for stem in entry.signal.stems where tokens.contains(where: { $0.hasPrefix(stem) }) { score += 2 }
            for word in entry.signal.words where tokens.contains(word) { score += 2 }
            for phrase in entry.signal.phrases where text.contains(phrase) { score += 3 }
            if score > 0 { scores[entry.tag] = score }
        }

        // Книга подсказывает категорию так же, как это делают подборки виджетов
        let reference = (refRu + " " + refEn).lowercased()
        if reference.contains("псалом") || reference.contains("псалт") || reference.contains("psalm") {
            scores[.prayer, default: 0] += 1
        }
        if reference.contains("притч") || reference.contains("екклесиаст") || reference.contains("премудрост") ||
            reference.contains("proverbs") || reference.contains("ecclesiastes") || reference.contains("wisdom") {
            scores[.wisdom, default: 0] += 3
        }
        if reference.contains("плач иеремии") || reference.contains("lamentations") {
            scores[.grief, default: 0] += 3
        }

        // По убыванию баллов; при равенстве побеждает категория, стоящая раньше в списке
        let ranked = VerseTag.allCases.enumerated()
            .compactMap { index, tag -> (tag: VerseTag, score: Int, index: Int)? in
                guard let score = scores[tag], score > 0 else { return nil }
                return (tag, score, index)
            }
            .sorted { first, second in
                first.score != second.score ? first.score > second.score : first.index < second.index
            }

        guard let best = ranked.first else { return [.faith] }
        var result: [VerseTag] = [best.tag]
        if ranked.count > 1, ranked[1].score >= 2, Double(ranked[1].score) >= Double(best.score) * 0.6 {
            result.append(ranked[1].tag)
        }
        return result
    }

    /// Убирает пометки в фигурных скобках (в английском тексте они стоят в конце стиха)
    private static func stripNotes(_ text: String) -> String {
        var result = ""
        var depth = 0
        for character in text {
            if character == "{" { depth += 1; continue }
            if character == "}" { depth = max(0, depth - 1); continue }
            if depth == 0 { result.append(character) }
        }
        return result
    }
}
