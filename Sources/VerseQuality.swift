import Foundation

// MARK: - Какие стихи годятся для «стиха дня»
/// «Стих дня» и кнопка «Следующий» берут случайный стих из всей Библии. Раньше годился любой длиннее 15 знаков, и на экране
/// появлялись обрывки: «Տերը խոսեց Մովսեսի հետ և ասաց» (Числа 31:1, «И сказал Господь Моисею, говоря:»), продолжения фраз,
/// родословия и переписи. Здесь стих проверяется по русскому и английскому тексту: армянская пунктуация надёжного признака не даёт,
/// а в синодальном и английском переводах незаконченная мысль кончается двоеточием, запятой или точкой с запятой,
/// а продолжение начинается с маленькой буквы.
///
/// Правила подобраны по всей базе (31 100 стихов): остаётся около трети, то есть десять тысяч стихов.
/// Файл знает только Foundation и не зависит от остального приложения.
enum VerseQuality {
    // MARK: Законченная мысль

    /// Знаки, которыми заканчивается законченное предложение
    private static let terminals: Set<Character> = [".", "!", "?", "…", "»", "\"", "”", ")"]

    /// Слова, на которых кончается зачин речи: после них идёт сама речь, но уже в следующем стихе
    private static let leadRu: Set<String> = ["говоря", "сказал", "сказали", "сказала", "сказав", "скажи", "глаголя", "следующее"]
    private static let leadEn: Set<String> = ["saying", "said", "say", "spake", "answered", "follows"]
    private static let leadHy: Set<String> = ["ասելով", "ասաց", "ասացին", "ասէ", "ասեց", "խօսեց", "խոսեց"]

    // MARK: Не перепись, не возраст, не обмеры

    /// Начала числительных, записанных словами: «восемьсот сорок пять», «сто тридцать лет»
    private static let numberStems: [String] = [
        "двадцат", "тридцат", "сорок", "пятьдесят", "шестьдесят", "семьдесят", "восемьдесят", "девяносто",
        "двести", "триста", "четыреста", "пятьсот", "шестьсот", "семьсот", "восемьсот", "девятьсот", "тысяч",
        "пятнадцат", "шестнадцат", "семнадцат", "восемнадцат", "девятнадцат",
        "двенадцат", "одиннадцат", "тринадцат", "четырнадцат"
    ]

    // MARK: Не чистое повествование

    /// Окончания глагола прошедшего времени, от длинных к коротким
    private static let pastSuffixes = ["лось", "лись", "лась", "лся", "ла", "ли", "ло", "л"]

    /// Слова на «-л», «-ло», «-ла», которые не глаголы: без этого «много» и «число» принимались бы за прошедшее время
    private static let notVerbs: Set<String> = [
        "было", "были", "была", "мало", "зло", "число", "село", "дело", "тело", "много", "гнев", "ил", "стол", "жил",
        "вол", "орел", "осел", "котел", "узел", "престол", "ствол", "камыш", "пол"
    ]

    // MARK: Проверка

    /// Годится ли стих как «стих дня»: законченная мысль, не зачин речи, не перечень и не чистое повествование.
    /// Тексты проверяются по очереди, на первом же несоответствии ответ `false`.
    static func isMeaningful(textHy: String, textRu: String, textEn: String) -> Bool {
        let hy = clean(textHy)
        let ru = clean(textRu)
        let en = clean(textEn)
        if hy.isEmpty && ru.isEmpty && en.isEmpty { return false }

        // 1. Мысль закончена: двоеточие, запятая, «;» и тире в конце означают, что продолжение в следующем стихе
        if !ru.isEmpty, let last = ru.last, !terminals.contains(last) { return false }
        if !en.isEmpty, let last = en.last, !terminals.contains(last) { return false }

        // 2. Это не продолжение предложения: с маленькой буквы начинаются только обрывки
        if let first = ru.first, first.isLowercase { return false }
        if let first = en.first, first.isLowercase { return false }

        // 3. Это не зачин речи: стих кончается на «сказал», «говоря», «saying»
        if !ru.isEmpty, leadRu.contains(lastWord(ru)) { return false }
        if !en.isEmpty, leadEn.contains(lastWord(en)) { return false }
        if !hy.isEmpty, leadHy.contains(lastWord(hy)) { return false }

        if !ru.isEmpty {
            // 4. Это не родословие и не перечень имён
            if occurrences(of: "родил", in: ru.lowercased()) >= 2 { return false }
            let rest = words(ru).dropFirst()
            if rest.count >= 4 {
                let capitalized = rest.filter { $0.first?.isUppercase == true }.count
                if Double(capitalized) / Double(rest.count) >= 0.4 { return false }
            }
        }
        if en.lowercased().contains("begat") { return false }

        if !ru.isEmpty {
            let tokens = letterTokens(ru)

            // 5. Это не перепись, не возраст и не обмеры: два числительных словами и больше
            let numerals = tokens.filter { token in
                token == "сто" || numberStems.contains { token.hasPrefix($0) }
            }.count
            if numerals >= 2 { return false }

            // 6. Это не чистое повествование («И послал…», «Потом родила…»): глагол прошедшего времени в первых словах
            if tokens.prefix(3).contains(where: isPastVerb) { return false }

            // 7. Есть что сказать: хотя бы пять слов
            if words(ru).count < 5 { return false }
        }
        if !hy.isEmpty, hy.count < 25 { return false }
        return true
    }

    // MARK: Насыщенность

    /// Начала слов, по которым видно, что стих о главном: Бог, любовь, вера, надежда, истина, спасение
    private static let richStems: [String] = [
        "бог", "господ", "христ", "иисус", "любов", "любит", "вера", "веры", "веру", "вере", "верит", "верьте", "веруй",
        "надежд", "милост", "милосерд", "благодат", "благослов", "истин", "правд", "свет", "жизн", "спас", "молит", "дух",
        "радост", "радуй", "терпен", "мудр", "смирен", "прощ", "покая", "блажен", "вечн", "царств", "слав", "заповед",
        "уповай", "сердц", "душ"
    ]
    private static let richWords: Set<String> = ["мир", "мира", "мире", "миру"]

    /// Сколько разных признаков смысла в русском тексте стиха. Из случайной выборки берётся самый насыщенный
    /// из подходящих: так реже попадаются перечни и пересказ событий, но выбор остаётся случайным.
    static func richness(textRu: String) -> Int {
        let ru = clean(textRu)
        let tokens = letterTokens(ru)
        var score = richStems.filter { stem in tokens.contains { $0.hasPrefix(stem) } }.count
        if tokens.contains(where: { richWords.contains($0) }) { score += 1 }
        if ru.lowercased().contains("не бойс") { score += 1 }
        return score
    }

    // MARK: Вспомогательное

    /// Убирает пометки в фигурных скобках (в английском тексте они стоят в конце стиха) и лишние пробелы
    private static func clean(_ text: String) -> String {
        var result = ""
        var depth = 0
        for character in text {
            if character == "{" { depth += 1; continue }
            if character == "}" { depth = max(0, depth - 1); continue }
            if depth == 0 { result.append(character) }
        }
        return words(result).joined(separator: " ")
    }

    private static func words(_ text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    /// Слова из одних русских букв, в нижнем регистре
    private static func letterTokens(_ text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { !(("а"..."я").contains($0) || $0 == "ё") })
            .map(String.init)
    }

    /// Последнее слово без знаков препинания, в нижнем регистре
    private static func lastWord(_ text: String) -> String {
        var trimmed = Substring(text)
        let trailing: Set<Character> = [".", ",", ":", ";", "!", "?", "…", "»", "\"", "”", ")", "(", "«", "—", "-"]
        while let last = trimmed.last, last.isWhitespace || trailing.contains(last) { trimmed = trimmed.dropLast() }
        return (trimmed.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? "").lowercased()
    }

    private static func occurrences(of fragment: String, in text: String) -> Int {
        text.components(separatedBy: fragment).count - 1
    }

    private static func isPastVerb(_ word: String) -> Bool {
        guard !notVerbs.contains(word) else { return false }
        return pastSuffixes.contains { suffix in word.hasSuffix(suffix) && word.count - suffix.count >= 3 }
    }
}
