import Foundation

// MARK: - Алгоритмический генератор вопросов викторины
final class BibleQuizGenerator {
    static let shared = BibleQuizGenerator()
    
    private init() {}
    
    // MARK: - Золотые стихи Библии для генерации вопросов "Из какой книги этот стих?"
    private struct GoldenVerseQuote {
        let textHy: String
        let textRu: String
        let textEn: String
        let bookId: Int
        let chapter: Int
        let verse: Int
        let category: QuizCategory
    }
    
    private let goldenVerses: [GoldenVerseQuote] = [
        GoldenVerseQuote(
            textHy: "«Սկզբումն էր Բանը, և Բանն Աստծո մոտ էր, և Բանն Աստված էր»։",
            textRu: "«В начале было Слово, и Слово было у Бога, и Слово было Бог».",
            textEn: "«In the beginning was the Word, and the Word was with God, and the Word was God».",
            bookId: 43, // Иоанна
            chapter: 1,
            verse: 1,
            category: .gospels
        ),
        GoldenVerseQuote(
            textHy: "«Որովհետև Աստված այնքան սիրեց աշխարհը, որ Իր միածին Որդուն տվեց...»։",
            textRu: "«Ибо так возлюбил Бог мир, что отдал Сына Своего Единородного...».",
            textEn: "«For God so loved the world that He gave His only begotten Son...».",
            bookId: 43, // Иоанна
            chapter: 3,
            verse: 16,
            category: .gospels
        ),
        GoldenVerseQuote(
            textHy: "«Տերն իմ հովիվն է, և ես ոչ մի բանի կարոտ չեմ լինի»։",
            textRu: "«Господь — Пастырь мой; я ни в чем не буду нуждаться».",
            textEn: "«The Lord is my shepherd; I shall not want».",
            bookId: 19, // Псалтирь
            chapter: 23,
            verse: 1,
            category: .oldTestament
        ),
        GoldenVerseQuote(
            textHy: "«Ամեն ինչ կարող եմ ինձ զորացնող Քրիստոսով»։",
            textRu: "«Все могу в укрепляющем меня Иисусе Христе».",
            textEn: "«I can do all things through Christ who strengthens me».",
            bookId: 50, // Филиппийцам
            chapter: 4,
            verse: 13,
            category: .newTestament
        ),
        GoldenVerseQuote(
            textHy: "«Ես եմ ճանապարհը, ճշմարտությունը և կյանքը. ոչ ոք չի գալիս Հոր մոտ, եթե ոչ Ինձանով»։",
            textRu: "«Я есмь путь и истина и жизнь; никто не приходит к Отцу, как только через Меня».",
            textEn: "«I am the way, the truth, and the life. No one comes to the Father except through Me».",
            bookId: 43, // Иоанна
            chapter: 14,
            verse: 6,
            category: .gospels
        ),
        GoldenVerseQuote(
            textHy: "«Սկզբում Աստված ստեղծեց երկինքն ու երկիրը»։",
            textRu: "«В начале сотворил Бог небо и землю».",
            textEn: "«In the beginning God created the heavens and the earth».",
            bookId: 1, // Бытие
            chapter: 1,
            verse: 1,
            category: .oldTestament
        ),
        GoldenVerseQuote(
            textHy: "«Ամենայն զգուշությամբ պահի՛ր քո սիրտը, որովհետև նրանից են բխում կյանքի աղբյուրները»։",
            textRu: "«Больше всего хранимого храни сердце твое, потому что из него источники жизни».",
            textEn: "«Above all else, guard your heart, for everything you do flows from it».",
            bookId: 20, // Притчи
            chapter: 4,
            verse: 23,
            category: .oldTestament
        ),
        GoldenVerseQuote(
            textHy: "«Երանի՜ սրտով մաքուրներին, որովհետև նրանք Աստծուն պիտի տեսնեն»։",
            textRu: "«Блаженны чистые сердцем, ибо они Бога узрят».",
            textEn: "«Blessed are the pure in heart, for they will see God».",
            bookId: 40, // Матфея
            chapter: 5,
            verse: 8,
            category: .gospels
        ),
        GoldenVerseQuote(
            textHy: "«Հավատն էլ, եթե գործեր չունի, ինքնըստինքյան մեռած է»։",
            textRu: "«Так и вера, если не имеет дел, мертва сама по себе».",
            textEn: "«In the same way, faith by itself, if it is not accompanied by action, is dead».",
            bookId: 59, // Иакова
            chapter: 2,
            verse: 17,
            category: .newTestament
        ),
        GoldenVerseQuote(
            textHy: "«Ես եմ Ալֆան և Օմեգան, Սկիզբը և Վերջը, ասում է Տերը...»։",
            textRu: "«Я есмь Альфа и Омега, начало и конец, говорит Господь...».",
            textEn: "«I am the Alpha and the Omega, the First and the Last, says the Lord...».",
            bookId: 66, // Откровение
            chapter: 1,
            verse: 8,
            category: .newTestament
        ),
        GoldenVerseQuote(
            textHy: "«Տիրոջ երկյուղն է իմաստության սկիզբը»։",
            textRu: "«Начало мудрости — страх Господень».",
            textEn: "«The fear of the Lord is the beginning of wisdom».",
            bookId: 20, // Притчи
            chapter: 9,
            verse: 10,
            category: .oldTestament
        ),
        GoldenVerseQuote(
            textHy: "«Եկե՛ք Ինձ մոտ, բոլոր հոգնածներդ ու բեռնավորվածներդ, և Ես ձեզ հանգիստ կտամ»։",
            textRu: "«Придите ко Мне все труждающиеся и обремененные, и Я успокою вас».",
            textEn: "«Come to Me, all you who are weary and burdened, and I will give you rest».",
            bookId: 40, // Матфея
            chapter: 11,
            verse: 28,
            category: .gospels
        )
    ]
    
    // MARK: - Генерация вопросов по цитатам "Из какой книги этот стих?"
    func generateVerseGuessQuestions() -> [QuizQuestion] {
        let allBooks = BibleDatabase.shared.books
        guard !allBooks.isEmpty else { return [] }
        
        var generated: [QuizQuestion] = []
        
        for quote in goldenVerses {
            guard let correctBook = allBooks.first(where: { $0.id == quote.bookId }) else { continue }
            
            // Выбираем 3 случайных неправильных книги из того же Завета
            let otherBooks = allBooks.filter { $0.id != quote.bookId && $0.isNewTestament == correctBook.isNewTestament }.shuffled()
            let wrongBooks = Array(otherBooks.prefix(3))
            guard wrongBooks.count == 3 else { continue }
            
            var optionsBooks = [correctBook] + wrongBooks
            optionsBooks.shuffle()
            let correctIndex = optionsBooks.firstIndex(where: { $0.id == correctBook.id }) ?? 0
            
            let q = QuizQuestion(
                category: quote.category,
                difficulty: .medium,
                questionHy: "Ո՞ր գրքից է այս հայտնի համարը.\n\(quote.textHy)",
                questionRu: "Из какой книги Священного Писания эта цитата:\n\(quote.textRu)",
                questionEn: "From which book of the Bible is this quote:\n\(quote.textEn)",
                optionsHy: optionsBooks.map { $0.nameHy },
                optionsRu: optionsBooks.map { $0.nameRu },
                optionsEn: optionsBooks.map { $0.nameEn },
                correctAnswerIndex: correctIndex,
                explanationHy: "Այս համարը գտնվում է \(correctBook.nameHy) գրքի \(quote.chapter)-րդ գլխում։",
                explanationRu: "Этот священный стих написан в книге \(correctBook.nameRu), глава \(quote.chapter):\(quote.verse).",
                explanationEn: "This verse is found in the Book of \(correctBook.nameEn), chapter \(quote.chapter):\(quote.verse).",
                verseRefHy: "\(correctBook.nameHy) \(quote.chapter):\(quote.verse)",
                verseRefRu: "\(correctBook.nameRu) \(quote.chapter):\(quote.verse)",
                verseRefEn: "\(correctBook.nameEn) \(quote.chapter):\(quote.verse)"
            )
            generated.append(q)
        }
        
        return generated
    }
    
    // MARK: - Генерация вопросов по структуре Библии (число глав, порядок книг)
    func generateBibleStructureQuestions() -> [QuizQuestion] {
        let allBooks = BibleDatabase.shared.books
        guard allBooks.count >= 10 else { return [] }
        
        var generated: [QuizQuestion] = []
        
        // 1. Сколько глав в Евангелиях и великих книгах
        let prominentBooks = allBooks.filter { [1, 19, 20, 40, 41, 42, 43, 44, 45, 66].contains($0.id) }
        for book in prominentBooks {
            let correctCount = book.chaptersCount
            var wrongCounts = [correctCount - 4, correctCount + 4, correctCount + 8].filter { $0 > 0 }
            if wrongCounts.count < 3 {
                wrongCounts = [correctCount + 2, correctCount + 6, correctCount + 10]
            }
            var options = ([correctCount] + wrongCounts.prefix(3)).shuffled()
            let correctIndex = options.firstIndex(of: correctCount) ?? 0
            
            let q = QuizQuestion(
                category: book.isNewTestament ? .newTestament : .oldTestament,
                difficulty: .medium,
                questionHy: "Քանի՞ գլուխ ունի «\(book.nameHy)» գիրքը։",
                questionRu: "Сколько глав содержит книга «\(book.nameRu)»?",
                questionEn: "How many chapters are in the Book of «\(book.nameEn)»?",
                optionsHy: options.map { "\($0) գլուխ" },
                optionsRu: options.map { "\($0) глав" },
                optionsEn: options.map { "\($0) chapters" },
                correctAnswerIndex: correctIndex,
                explanationHy: "«\(book.nameHy)» գիրքը բաղկացած է \(correctCount) գլուխներից։",
                explanationRu: "Книга «\(book.nameRu)» состоит из \(correctCount) глав.",
                explanationEn: "The Book of «\(book.nameEn)» consists of \(correctCount) chapters.",
                verseRefHy: "\(book.nameHy) 1-\(correctCount)",
                verseRefRu: "\(book.nameRu) 1-\(correctCount)",
                verseRefEn: "\(book.nameEn) 1-\(correctCount)"
            )
            generated.append(q)
        }
        
        return generated
    }
    
    // MARK: - Сборка пула вопросов для викторины любого размера (до 1000+)
    func fetchQuestions(category: QuizCategory, count: Int = 10) -> [QuizQuestion] {
        var pool: [QuizQuestion] = []
        
        // 1. Кураторские вопросы
        let curated = QuizDatabase.allQuestions
        if category == .all {
            pool.append(contentsOf: curated)
        } else {
            pool.append(contentsOf: curated.filter { $0.category == category })
        }
        
        // 2. Динамические вопросы по цитатам
        let verseQuestions = generateVerseGuessQuestions()
        if category == .all || category == .verses {
            pool.append(contentsOf: verseQuestions)
        } else {
            pool.append(contentsOf: verseQuestions.filter { $0.category == category })
        }
        
        // 3. Вопросы по структуре
        let structureQuestions = generateBibleStructureQuestions()
        if category == .all {
            pool.append(contentsOf: structureQuestions)
        } else {
            pool.append(contentsOf: structureQuestions.filter { $0.category == category })
        }
        
        pool.shuffle()
        return Array(pool.prefix(count))
    }
}
