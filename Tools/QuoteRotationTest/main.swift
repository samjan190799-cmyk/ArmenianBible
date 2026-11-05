import Foundation

// Проверка порядка смены цитат в виджете: настоящий код Sources/QuoteRotation.swift.
// Запускается на CI (.github/workflows/quote-rotation-test.yml), в TestFlight ничего не отправляет.
//
//   swiftc -O Sources/QuoteRotation.swift Tools/QuoteRotationTest/main.swift -o quote_rotation_test && ./quote_rotation_test

/// Предсказуемый источник случайности: при одном зерне порядок один и тот же, провал можно повторить
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

var checks = 0
var failures = 0

func check(_ ok: Bool, _ message: @autoclosure () -> String) {
    checks += 1
    if !ok {
        failures += 1
        if failures <= 20 { print("ПРОВАЛ: \(message())") }
    }
}

// MARK: - Порядок показа
// Подборки от одной цитаты до двадцати пяти, по 150 разных зёрен случайности
for n in 1...25 {
    let pool = Array(0..<n)
    for seed in 0..<150 {
        var rng = SplitMix64(seed: UInt64(seed * 7919 + n))

        // Первый круг: каждая цитата ровно один раз
        let cycle = QuoteRotation.plan(pool: pool, history: [], first: nil, count: n, using: &rng)
        check(cycle.order.count == n && Set(cycle.order).count == n, "круг n=\(n) seed=\(seed): \(cycle.order)")

        // Двенадцать графиков подряд по двенадцать записей, память переносится из графика в график, как в виджете
        var history: [Int] = []
        var all: [Int] = []
        for _ in 0..<12 {
            let plan = QuoteRotation.plan(pool: pool, history: history, first: nil, count: 12, using: &rng)
            history = plan.history
            all += plan.order
            check(plan.order.count == 12, "длина графика n=\(n) seed=\(seed): \(plan.order.count)")
            check(history.count <= n, "память больше подборки n=\(n) seed=\(seed): \(history.count)")
        }

        if n >= 2 {
            // Одна и та же цитата никогда не идёт два раза подряд, в том числе на стыке графиков
            for i in 1..<all.count {
                check(all[i] != all[i - 1], "повтор подряд n=\(n) seed=\(seed) i=\(i)")
            }
            // Ни одна цитата не «пропадает»: в любых 2n показах подряд есть все
            for i in 0...(all.count - 2 * n) {
                let window = Set(all[i..<(i + 2 * n)])
                check(window.count == n, "цитата пропала n=\(n) seed=\(seed) i=\(i): в окне \(window.count) из \(n)")
            }
        }
    }
}

// MARK: - Цитата, которая уже стоит первой
do {
    var rng = SplitMix64(seed: 1)
    let plan = QuoteRotation.plan(pool: [1, 2, 3, 4], history: [], first: 3, count: 6, using: &rng)
    check(plan.order.first == 3, "первой должна идти заданная цитата: \(plan.order)")
    check(plan.history.contains(3), "заданная цитата должна попасть в память: \(plan.history)")
    check(plan.order.count == 6, "длина: \(plan.order.count)")

    // Заданная цитата может быть не из подборки (стих от приложения): всё равно идёт первой
    let outside = QuoteRotation.plan(pool: [1, 2, 3, 4], history: [], first: 99, count: 4, using: &rng)
    check(outside.order.first == 99, "заданная цитата вне подборки: \(outside.order)")
}

// MARK: - Память
do {
    var rng = SplitMix64(seed: 2)
    // Чужие ключи (после смены категории или языка) и повторы из памяти уходят
    let plan = QuoteRotation.plan(pool: [1, 2, 3], history: [7, 8, 1, 1, 9], first: nil, count: 2, using: &rng)
    check(plan.history.allSatisfy { [1, 2, 3].contains($0) }, "в памяти остались чужие ключи: \(plan.history)")
    check(Set(plan.history).count == plan.history.count, "в памяти повторы: \(plan.history)")
    // Цитата, показанная недавно, не идёт первой, пока не показаны остальные
    var seenFirst = Set<Int>()
    for seed in 0..<200 {
        var g = SplitMix64(seed: UInt64(seed))
        let p = QuoteRotation.plan(pool: [1, 2, 3, 4], history: [1, 2, 3], first: nil, count: 1, using: &g)
        seenFirst.insert(p.order[0])
    }
    check(seenFirst == [4], "после 1, 2, 3 первой должна идти только 4, а было: \(seenFirst)")
}

// MARK: - Края
do {
    var rng = SplitMix64(seed: 3)
    let one = QuoteRotation.plan(pool: ["a"], history: [], first: nil, count: 5, using: &rng)
    check(one.order == ["a", "a", "a", "a", "a"], "подборка из одной цитаты: \(one.order)")

    let empty = QuoteRotation.plan(pool: [Int](), history: [1], first: nil, count: 5, using: &rng)
    check(empty.order.isEmpty && empty.history.isEmpty, "пустая подборка")

    let zero = QuoteRotation.plan(pool: [1, 2], history: [], first: nil, count: 0, using: &rng)
    check(zero.order.isEmpty, "нулевое число цитат")

    // Повторы в подборке (один стих попал в неё дважды) не должны ломать круг
    let dup = QuoteRotation.plan(pool: [1, 1, 2, 2, 3], history: [], first: nil, count: 3, using: &rng)
    check(Set(dup.order) == [1, 2, 3], "повторы в подборке: \(dup.order)")
}

// MARK: - Ключ цитаты
// Эталонные значения посчитаны независимой реализацией FNV-1a (64 бита): ключ должен пережить перезапуск и обновление приложения,
// иначе вся сохранённая память о показанном станет бесполезной
check(QuoteKey.make("Matthew 6:33") == "cf6207ded3f6596", "эталон 1: \(QuoteKey.make("Matthew 6:33"))")
check(QuoteKey.make("") == "af63d24c8601db8e", "эталон 2: \(QuoteKey.make(""))")
check(QuoteKey.make("ab", "c") == "ab11b2f87ef04a1", "эталон 3: \(QuoteKey.make("ab", "c"))")
check(QuoteKey.make("a", "bc") == "cb31b5381b2a17ab", "эталон 4: \(QuoteKey.make("a", "bc"))")
check(QuoteKey.make("ab", "c") != QuoteKey.make("a", "bc"), "границы частей не должны сливаться")
check(QuoteKey.make("Նախ խնդրեցե՛ք", "Matthew 6:33") == "c56996b5bbcc0f85", "эталон 5 (армянский текст): \(QuoteKey.make("Նախ խնդրեցե՛ք", "Matthew 6:33"))")
check(QuoteKey.make("x") == QuoteKey.make("x"), "ключ должен быть одним и тем же при повторном вызове")

if failures > 0 {
    print("Провалено проверок: \(failures) из \(checks)")
    exit(1)
}
print("Всё в порядке: \(checks) проверок")
