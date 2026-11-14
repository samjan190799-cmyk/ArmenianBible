import Foundation

// MARK: - Викторина-дуэль
// Двое играют в один и тот же набор вопросов и сравнивают счёт. Сервера нет: набор получается из «семени» в ссылке
// (одинаковое перемешивание у обоих), а счёт возвращается ответной ссылкой. Вопросы берутся только из кураторской
// базы: она одинакова у всех с одной версией приложения, а вопросы ИИ и по цитатам у каждого получились бы свои.

struct QuizDuel: Codable, Equatable {
    let c: String      // категория
    let s: Int         // «семя» перемешивания
    let n: Int         // сколько вопросов
    let m: Int         // сколько вопросов в пуле категории у автора вызова: так видно, что у друга другая версия базы
    var a: String?     // кто вызвал
    var r: Int?        // его счёт
    var b: String?     // кто принял
    var q: Int?        // его счёт

    var category: QuizCategory { QuizCategory(rawValue: c) ?? .all }

    /// Вызов ждёт ответа: есть счёт автора, нет счёта того, кто принял
    var isChallenge: Bool { r != nil && q == nil }

    /// Дуэль сыграна: счёт есть у обоих
    var isFinished: Bool { r != nil && q != nil }
}

/// Простой воспроизводимый генератор (SplitMix64): у обоих игроков одно «семя» даёт один порядок вопросов
struct QuizSeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum QuizDuelEngine {
    static let questionCount = 10

    /// Категории, у которых есть кураторские вопросы; «стихи» набираются на лету, поэтому в дуэль не годятся
    static func playableCategory(_ category: QuizCategory) -> QuizCategory {
        category == .verses ? .all : category
    }

    /// Пул дуэли: вопросы кураторской базы в том порядке, в каком они записаны в коде
    static func pool(for category: QuizCategory) -> [QuizQuestion] {
        let all = QuizDatabase.allQuestions
        return category == .all ? all : all.filter { $0.category == category }
    }

    /// Новый вызов; nil, если вопросов в категории слишком мало
    static func newDuel(category: QuizCategory, name: String) -> QuizDuel? {
        let chosen = playableCategory(category)
        let count = pool(for: chosen).count
        guard count >= 5 else { return nil }
        return QuizDuel(
            c: chosen.rawValue,
            s: Int.random(in: 1...Int(Int32.max)),
            n: min(questionCount, count),
            m: count,
            a: PairLink.clean(name, limit: 40),
            r: nil,
            b: nil,
            q: nil
        )
    }

    /// Вопросы дуэли; nil, если у игрока другая версия базы (число вопросов не совпало) или категория неизвестна
    static func questions(for duel: QuizDuel) -> [QuizQuestion]? {
        let pool = pool(for: duel.category)
        guard !pool.isEmpty, pool.count == duel.m else { return nil }
        var generator = QuizSeededGenerator(seed: duel.s)
        var indices = Array(pool.indices)
        // Перемешивание Фишера: своё, а не shuffle(using:), порядок которого стандартная библиотека не обещает
        if indices.count > 1 {
            for i in stride(from: indices.count - 1, to: 0, by: -1) {
                let j = Int(generator.next() % UInt64(i + 1))
                indices.swapAt(i, j)
            }
        }
        return indices.prefix(min(duel.n, pool.count)).map { pool[$0] }
    }
}

enum QuizDuelLink {
    static func url(for duel: QuizDuel) -> URL? {
        guard let encoded = PairLink.encode(duel) else { return nil }
        return PairLink.webURL(path: "d", payload: encoded)
    }

    /// Дуэль из ссылки armenianbible://duel?d=…; nil, если ссылка повреждена или значения вне разумных пределов
    static func duel(from url: URL) -> QuizDuel? {
        guard let encoded = PairLink.payload(from: url),
              var duel = PairLink.decode(QuizDuel.self, from: encoded),
              duel.n >= 1, duel.n <= 30, duel.m >= duel.n else { return nil }
        duel.a = PairLink.clean(duel.a, limit: 40)
        duel.b = PairLink.clean(duel.b, limit: 40)
        if let r = duel.r, !(0...duel.n).contains(r) { return nil }
        if let q = duel.q, !(0...duel.n).contains(q) { return nil }
        return duel
    }
}
