import Foundation

// MARK: - Порядок смены цитат в виджете
/// Цитаты подборки идут по кругу в случайном порядке: пока не показаны все, ни одна не повторяется.
///
/// Почему не `randomElement()`: каждый новый график виджета начинался с сохранённого стиха, который сам виджет не менял,
/// а остальные записи выбирались случайно с возвращением. К тому же у `BibleVerse` идентификатор новый в каждом запуске
/// процесса, а виджет запускается заново на каждый график, поэтому по `id` стих не узнать. Выходило, что на экране
/// чаще всего одни и те же цитаты. Здесь стихи узнаются по ключу из текста (`QuoteKey`), а память о показанном лежит в общих настройках.
///
/// Файл знает только Foundation: его компилирует и проверяет тест на CI (`Tools/QuoteRotationTest`).
enum QuoteRotation {
    /// Что показывать и что запомнить
    struct Plan<Key: Hashable> {
        /// Порядок показа: первая цитата идёт сейчас, остальные по одной за каждый шаг смены
        var order: [Key]
        /// Память о показанном, от старых к новым: её надо сохранить и передать в следующий раз
        var history: [Key]
    }

    /// - Parameters:
    ///   - pool: подборка (ключи цитат, повторы допустимы: они убираются)
    ///   - history: что показывалось раньше, от старых к новым
    ///   - first: цитата, которая уже стоит первой (её поставил человек кнопкой «Следующий» или приложение)
    ///   - count: сколько цитат нужно
    ///   - generator: источник случайности (в тесте подставляется предсказуемый)
    static func plan<Key: Hashable, G: RandomNumberGenerator>(
        pool: [Key],
        history: [Key],
        first: Key?,
        count: Int,
        using generator: inout G
    ) -> Plan<Key> {
        // Подборка без повторов, в исходном порядке
        var unique: [Key] = []
        var inPool = Set<Key>()
        for key in pool {
            if inPool.insert(key).inserted { unique.append(key) }
        }

        guard count > 0, !unique.isEmpty else { return Plan(order: [], history: []) }

        // Забываем то, чего в подборке уже нет (сменили категорию или язык), и повторы в памяти
        var shown: [Key] = []
        var seen = Set<Key>()
        for key in history {
            if inPool.contains(key), seen.insert(key).inserted { shown.append(key) }
        }

        var order: [Key] = []

        /// Запоминает показанное: самое свежее всегда в конце
        func remember(_ key: Key) {
            if !seen.insert(key).inserted { shown.removeAll { $0 == key } }
            shown.append(key)
        }

        if let first {
            order.append(first)
            remember(first)
        }

        while order.count < count {
            var candidates = unique.filter { !seen.contains($0) }
            if candidates.isEmpty {
                // Круг пройден. Начинаем новый, но то, что показали последним, сразу следом не ставим
                let last = order.last ?? shown.last
                shown = last.map { [$0] } ?? []
                seen = Set(shown)
                candidates = unique.filter { !seen.contains($0) }
                if candidates.isEmpty { candidates = unique }  // подборка из одной цитаты
            }
            guard let next = candidates.randomElement(using: &generator) else { break }
            order.append(next)
            remember(next)
        }

        // Память не больше подборки: старше уже не нужна
        if shown.count > unique.count { shown = Array(shown.suffix(unique.count)) }
        return Plan(order: order, history: shown)
    }
}

// MARK: - Ключ цитаты
/// Постоянный ключ цитаты. `hashValue` и `UUID()` у каждого запуска свои, а ключ должен пережить перезапуск виджета:
/// это хеш FNV-1a (64 бита) от переданных строк, записанный шестнадцатеричным числом.
enum QuoteKey {
    static func make(_ parts: String...) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for part in parts {
            for byte in part.utf8 {
                hash ^= UInt64(byte)
                hash = hash &* 0x100000001b3
            }
            // Разделитель, чтобы ("ab", "c") и ("a", "bc") не совпали
            hash ^= 0x1f
            hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 16)
    }
}
