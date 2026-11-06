import Foundation

// MARK: - Очистка армянского текста от ИИ
// ИИ любит писать по-армянски «по-старому»: вопросительный знак «՞», знак ударения «՛», восклицание «՜»
// и «запятую» «՝» ставят прямо над буквой слова («ո՞ր», «Սէ՛րգիոս», «էլ՝»). Шрифт рисует их завитушками и чёрточками
// над буквами, и человек видит в словах непонятные знаки. Библия в приложении и сам интерфейс этих знаков не используют,
// поэтому в ответах ИИ их заменяем обычной пунктуацией: «?», «!» и «,».

enum ArmenianText {
    /// Армянские знаки пунктуации, которые стоят над буквами: ՛ ՜ ՝ ՞ ՟
    private static func isLetterMark(_ scalar: Unicode.Scalar) -> Bool {
        (0x055B...0x055F).contains(scalar.value)
    }

    /// Текст без знаков над буквами.
    /// - «՞» убирается из слова, а конец этого предложения («։» или «.») становится «?»
    /// - «՜» убирается так же, конец предложения становится «!»
    /// - «՛» и «՟» просто убираются
    /// - «՝» заменяется обычной запятой
    /// Текст без этих знаков возвращается как есть (без копирования).
    static func clean(_ text: String) -> String {
        let scalars = Array(text.unicodeScalars)
        guard scalars.contains(where: isLetterMark) else { return text }

        var output = String.UnicodeScalarView()
        // Каким знаком закончить предложение, в котором встретились «՞» или «՜»
        var pending: Unicode.Scalar? = nil

        for (index, scalar) in scalars.enumerated() {
            switch scalar.value {
            case 0x055E: // ՞
                pending = "?"
            case 0x055C: // ՜
                if pending == nil { pending = "!" }
            case 0x055B, 0x055F: // ՛ ՟
                continue
            case 0x055D: // ՝
                output.append(",")
            case 0x0589, 0x002E: // «։» (армянская точка) и «.»
                // Обычная точка считается концом предложения, только если за ней пробел или конец текста
                // (иначе это число вроде «5.3»)
                let next: Unicode.Scalar? = index + 1 < scalars.count ? scalars[index + 1] : nil
                let endsSentence = scalar.value == 0x0589 || next == nil || next?.properties.isWhitespace == true
                if endsSentence, let mark = pending {
                    output.append(mark)
                    pending = nil
                } else {
                    output.append(scalar)
                }
            case 0x003F, 0x0021: // «?» и «!» уже стоят
                output.append(scalar)
                pending = nil
            case 0x000A, 0x000D: // конец строки закрывает предложение
                if let mark = pending {
                    output.append(mark)
                    pending = nil
                }
                output.append(scalar)
            default:
                output.append(scalar)
            }
        }
        if let mark = pending {
            output.append(mark)
        }
        return String(output)
    }
}
