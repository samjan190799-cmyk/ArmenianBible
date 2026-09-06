import Foundation

// MARK: - Профиль регулярности визитов пользователя
enum UserVisitCadence: String, Codable {
    /// Заходит часто (почти каждый день / несколько раз в неделю) -> строжайший фильтр повторов
    case frequent = "frequent"
    /// Заходит умеренно (1-2 раза в неделю) -> стандартный интервал
    case moderate = "moderate"
    /// Заходит редко (реже раза в неделю или новичок) -> режим освежения памяти и закрепления
    case infrequent = "infrequent"
}

// MARK: - Запись о встреченном вопросе в скрытом дневнике
struct QuizDiaryEntry: Codable, Identifiable {
    var id: String { questionHash }
    let questionHash: String
    let questionSnippet: String
    let categoryRaw: String
    var seenCount: Int
    var lastSeenDate: Date
    var correctCount: Int
    var wrongCount: Int
    
    var isMastered: Bool {
        correctCount >= 2 && wrongCount == 0
    }
}

// MARK: - Невидимый Адаптивный Дневник Викторины («Magic Under The Hood»)
@MainActor
final class QuizAdaptiveDiary: ObservableObject {
    static let shared = QuizAdaptiveDiary()
    
    private let diaryStorageKey = "quiz_adaptive_diary_entries_v1"
    private let sessionsStorageKey = "quiz_adaptive_sessions_v1"
    
    /// Карта записей: хэш вопроса -> данные записи
    private var entries: [String: QuizDiaryEntry] = [:]
    
    /// Даты последних сессий (хранятся до 30 последних дат)
    private var sessionDates: [Date] = []
    
    private init() {
        loadData()
        recordSession()
    }
    
    // MARK: - Учет сессии и определение каденции пользователя
    
    func recordSession() {
        let now = Date()
        // Не дублируем сессии чаще чем раз в час
        if let last = sessionDates.last, now.timeIntervalSince(last) < 3600 {
            return
        }
        sessionDates.append(now)
        if sessionDates.count > 30 {
            sessionDates.removeFirst(sessionDates.count - 30)
        }
        saveSessions()
    }
    
    /// Вычисление ритма визитов пользователя
    var userCadence: UserVisitCadence {
        guard sessionDates.count >= 2 else {
            return .infrequent
        }
        
        let now = Date()
        // Считаем количество сессий за последние 7 дней
        let recentWeekSessions = sessionDates.filter { now.timeIntervalSince($0) <= 7 * 86400 }.count
        
        if recentWeekSessions >= 3 {
            return .frequent
        } else if recentWeekSessions >= 1 {
            return .moderate
        } else {
            return .infrequent
        }
    }
    
    // MARK: - Фиксация ответа на вопрос
    
    func recordQuestionAnswer(questionText: String, category: QuizCategory, isCorrect: Bool) {
        let hash = generateHash(for: questionText)
        let snippet = String(questionText.prefix(60)).trimmingCharacters(in: .whitespacesAndNewlines)
        
        var entry = entries[hash] ?? QuizDiaryEntry(
            questionHash: hash,
            questionSnippet: snippet,
            categoryRaw: category.rawValue,
            seenCount: 0,
            lastSeenDate: Date(),
            correctCount: 0,
            wrongCount: 0
        )
        
        entry.seenCount += 1
        entry.lastSeenDate = Date()
        if isCorrect {
            entry.correctCount += 1
        } else {
            entry.wrongCount += 1
        }
        
        entries[hash] = entry
        saveEntries()
    }
    
    /// Мгновенная регистрация сгенерированного пула вопросов (чтобы они не повторялись даже при перезапуске)
    func registerGeneratedBatch(questions: [QuizQuestion], language: AppLanguage) {
        let now = Date()
        for q in questions {
            let text = q.question(for: language)
            let hash = generateHash(for: text)
            let snippet = String(text.prefix(60)).trimmingCharacters(in: .whitespacesAndNewlines)
            
            var entry = entries[hash] ?? QuizDiaryEntry(
                questionHash: hash,
                questionSnippet: snippet,
                categoryRaw: q.category.rawValue,
                seenCount: 0,
                lastSeenDate: now,
                correctCount: 0,
                wrongCount: 0
            )
            entry.seenCount += 1
            entry.lastSeenDate = now
            entries[hash] = entry
        }
        saveEntries()
    }
    
    // MARK: - Выборка тем для ИИ-промпта (Исключение повторов / Освежение памяти)
    
    /// Получает список недавних сниппетов/тем для текущей категории, которые НЕ нужно повторять
    func getRecentTopicsToAvoid(category: QuizCategory, limit: Int = 25) -> [String] {
        let now = Date()
        let cadence = userCadence
        
        let exclusionDays: Double
        switch cadence {
        case .frequent:
            exclusionDays = 30.0
        case .moderate:
            exclusionDays = 14.0
        case .infrequent:
            exclusionDays = 5.0
        }
        
        let matchingEntries = entries.values.filter { entry in
            let isSameCat = (category == .all || entry.categoryRaw == category.rawValue)
            let withinDays = now.timeIntervalSince(entry.lastSeenDate) < (exclusionDays * 86400)
            return isSameCat && withinDays
        }
        
        let sorted = matchingEntries.sorted { $0.lastSeenDate > $1.lastSeenDate }
        return Array(sorted.prefix(limit).map { $0.questionSnippet })
    }
    
    /// Случайные темы-якоря для предотвращения детерминизма LLM
    private func generateRandomFocusAnchors(category: QuizCategory, language: AppLanguage) -> String {
        switch category {
        case .all:
            let options = [
                "Сотворение мира, исход из Египта, псалмы Давида, Нагорная проповедь",
                "Книга Руфь, пророк Илия, притчи Иисуса, книга Деяний апостолов",
                "Потоп и Ной, мудрость Соломона, исцеление слепорожденного, Послание к Римлянам",
                "Пророк Иона в Ниневии, воскрешение Лазаря, видения книги Откровение"
            ]
            let chosen = options.randomElement() ?? options[0]
            switch language {
            case .armenian: return "Շեշտադրում այս փուլի համար՝ Աստվածաշնչի տարբեր գրքեր և իրադարձություններ:"
            case .russian: return "Случайный акцент раунда: [\(chosen)]."
            case .english: return "Random focus: [Various biblical narratives, avoid repetitive basic questions]."
            }
        case .oldTestament:
            let options = [
                "Патриархи Авраам, Исаак и Иаков",
                "Странствование по пустыне, манна небесная, Медный змей",
                "Цари Саул, Давид и Соломон, постройка Храма",
                "Малые пророки: Амос, Михей, Осия, Аггей",
                "Книга Иова, вера среди испытаний",
                "Псалтирь и книга Притчей Соломоновых"
            ]
            let chosen = options.randomElement() ?? options[0]
            switch language {
            case .armenian: return "Շեշտադրում Հին Կտակարանի մարգարեների և պատմական դրվագների վրա:"
            case .russian: return "Случайный фокус этого раунда: [\(chosen)]. Обязательно составь вопросы по этим книгам."
            case .english: return "Random focus: [Old Testament historical books & prophets]."
            }
        case .gospels:
            let options = [
                "Чудеса в Галилее (претворение воды в вино, утишение бури)",
                "Притчи о блудном сыне, о добром самарянине, о талантах",
                "Беседы Христа с Никодимом и Самарянкой",
                "Тайная вечеря, Гефсиманский сад и первосвященники",
                "Явления воскресшего Спасителя ученикам"
            ]
            let chosen = options.randomElement() ?? options[0]
            switch language {
            case .armenian: return "Հատուկ շեշտադրում Ավետարանի առակների և հրաշքների խորքային մանրամասների վրա:"
            case .russian: return "Случайный фокус этого раунда: [\(chosen)]."
            case .english: return "Random focus: [Gospel parables, miracles, and deep dialogues]."
            }
        case .newTestament:
            let options = [
                "Деяния апостолов: обращение Савла, служение Филиппа и Стефана",
                "Миссионерские путешествия апостола Павла",
                "Послания к Ефесянам, Колоссянам, Филиппийцам",
                "Послания апостолов Иакова, Петра и Иоанна",
                "Книга Откровения: послания семи церквям, Новый Иерусалим"
            ]
            let chosen = options.randomElement() ?? options[0]
            switch language {
            case .armenian: return "Հատուկ շեշտադրում Պողոս առաքյալի ճանապարհորդությունների և Ընդհանրական թղթերի վրա:"
            case .russian: return "Случайный фокус этого раунда: [\(chosen)]."
            case .english: return "Random focus: [Epistles of Paul, General Epistles, and Acts]."
            }
        case .churchHistory:
            let options = [
                "Святой Григорий Просветитель, Хор Вирап и крещение Армении",
                "Святые Месроп Маштоц и Саак Партев, Золотой век армянской письменности",
                "Святой Григор Нарекаци и Книга скорбных песнопений",
                "Святой Нерсес Шнорали, богословие и духовные песнопения",
                "Вселенские соборы и святые отцы Церкви"
            ]
            let chosen = options.randomElement() ?? options[0]
            switch language {
            case .armenian: return "Շեշտադրում Հայ Առաքելական Եկեղեցու սրբերի և ժողովների պատմության վրա:"
            case .russian: return "Случайный фокус этого раунда: [\(chosen)]."
            case .english: return "Random focus: [Armenian Church Fathers, Translators, and Saints]."
            }
        case .verses:
            switch language {
            case .armenian: return "Ընտրիր հազվադեպ, բայց կարևոր խորիմաստ համարներ:"
            case .russian: return "Выбери глубокие, нетривиальные цитаты из разных книг Писания."
            case .english: return "Choose meaningful and distinct verses from various books."
            }
        }
    }
    
    /// Формирует адаптивную инструкцию для промпта ИИ
    func makeAdaptivePromptDirective(category: QuizCategory, language: AppLanguage) -> String {
        let cadence = userCadence
        let recentAvoid = getRecentTopicsToAvoid(category: category, limit: 18)
        let randomAnchor = generateRandomFocusAnchors(category: category, language: language)
        
        var directive = "\(randomAnchor) "
        
        switch cadence {
        case .frequent:
            switch language {
            case .armenian:
                directive += "Օգտատերը հաճախ է մասնակցում վիկտորինային։ Կազմիր բացառիկ, նոր, խորաթափանց և հետաքրքիր հարցեր, որոնք հազվադեպ են հանդիպում։"
            case .russian:
                directive += "Пользователь регулярно проходит викторину. Составь оригинальные, глубокие и неизбитые вопросы, избегая самых очевидных фактов."
            case .english:
                directive += "The user plays this quiz very frequently. Generate fresh, original, profound, and unique questions avoiding basic or overused facts."
            }
            
        case .moderate:
            switch language {
            case .armenian:
                directive += "Կազմիր հավասարակշռված հարցեր՝ համատեղելով ինչպես հիմնարար, այնպես էլ ավելի խորքային աստվածաշնչյան գիտելիքները։"
            case .russian:
                directive += "Составь сбалансированные вопросы, сочетающие как фундаментальные, так и глубокие библейские детали."
            case .english:
                directive += "Generate balanced questions combining both foundational and insightful biblical knowledge."
            }
            
        case .infrequent:
            switch language {
            case .armenian:
                directive += "Կազմիր հիշարժան, ոգեշնչող և կարևոր հիմնարար հարցեր, որոնք կօգնեն թարմացնել գիտելիքները։"
            case .russian:
                directive += "Составь ключевые, вдохновляющие и фундаментальные вопросы, помогающие легко освежить память и закрепить Слово Божье."
            case .english:
                directive += "Generate key, inspiring, and foundational questions that refresh memory and reinforce core Biblical knowledge."
            }
        }
        
        if !recentAvoid.isEmpty {
            let listStr = recentAvoid.joined(separator: " | ")
            switch language {
            case .armenian:
                directive += " ԽՍՏԻՎ ԽՈՒՍԱՓԻՐ հետևյալ թեմաներից կամ հարցերից (ԱՐԳԵԼՎԱԾ Է ԿՐԿՆԵԼ)՝ [\(listStr)]։"
            case .russian:
                directive += " СТРОЖАЙШЕ ЗАПРЕЩЕНО повторять или перефразировать следующие темы и вопросы, так как пользователь их недавно видел: [\(listStr)]."
            case .english:
                directive += " STRICTLY FORBIDDEN to repeat or rephrase the following topics, as the user recently encountered them: [\(listStr)]."
            }
        }
        
        return directive
    }
    
    /// Проверка: следует ли отфильтровать офлайн-вопрос (для режима классической базы)
    func shouldFilterOfflineQuestion(questionText: String) -> Bool {
        let hash = generateHash(for: questionText)
        guard let entry = entries[hash] else { return false }
        
        let now = Date()
        let daysAgo = now.timeIntervalSince(entry.lastSeenDate) / 86400
        
        switch userCadence {
        case .frequent:
            // Частым пользователям не показываем вопрос, если видели его менее 20 дней назад
            return daysAgo < 20
        case .moderate:
            // Умеренным не показываем, если видели менее 10 дней назад (если только не ошиблись в нем)
            return daysAgo < 10 && entry.wrongCount == 0
        case .infrequent:
            // Редким гостям можно показывать снова через 4 дня, особенно если были ошибки
            return daysAgo < 4 && entry.wrongCount == 0
        }
    }
    
    // MARK: - Хэширование и персистентность
    
    private func generateHash(for text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var hasher = Hasher()
        hasher.combine(cleaned)
        return String(format: "%016llx", UInt64(bitPattern: Int64(hasher.finalize())))
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: diaryStorageKey),
           let decoded = try? JSONDecoder().decode([String: QuizDiaryEntry].self, from: data) {
            self.entries = decoded
        }
        
        if let datesData = UserDefaults.standard.data(forKey: sessionsStorageKey),
           let decodedDates = try? JSONDecoder().decode([Date].self, from: datesData) {
            self.sessionDates = decodedDates
        }
    }
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: diaryStorageKey)
        }
    }
    
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessionDates) {
            UserDefaults.standard.set(data, forKey: sessionsStorageKey)
        }
    }
}
