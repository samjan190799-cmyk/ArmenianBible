import Foundation

// MARK: - Категория Викторины
enum QuizCategory: String, CaseIterable, Identifiable, Codable {
    case all = "all"
    case oldTestament = "old_testament"
    case gospels = "gospels"
    case newTestament = "new_testament"
    case churchHistory = "church_history"
    case verses = "verses"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "sparkles"
        case .oldTestament: return "scroll.fill"
        case .gospels: return "book.closed.fill"
        case .newTestament: return "cross.fill"
        case .churchHistory: return "building.columns.fill"
        case .verses: return "quote.bubble.fill"
        }
    }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .all:
            return "quiz_cat_all".localized(for: language)
        case .oldTestament:
            return "quiz_cat_old".localized(for: language)
        case .gospels:
            return "quiz_cat_gospels".localized(for: language)
        case .newTestament:
            return "quiz_cat_new".localized(for: language)
        case .churchHistory:
            return "quiz_cat_church_history".localized(for: language)
        case .verses:
            return "quiz_cat_verses".localized(for: language)
        }
    }
}

// MARK: - Уровень сложности
enum QuizDifficulty: String, CaseIterable, Identifiable, Codable {
    case all = "all"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var id: String { rawValue }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .all:
            return "quiz_diff_all".localized(for: language)
        case .easy:
            return "quiz_diff_easy".localized(for: language)
        case .medium:
            return "quiz_diff_medium".localized(for: language)
        case .hard:
            return "quiz_diff_hard".localized(for: language)
        }
    }
}

// MARK: - Модель вопроса Викторины
struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    let category: QuizCategory
    let difficulty: QuizDifficulty
    
    let questionHy: String
    let questionRu: String
    let questionEn: String
    
    let optionsHy: [String]
    let optionsRu: [String]
    let optionsEn: [String]
    
    let correctAnswerIndex: Int
    let explanationHy: String
    let explanationRu: String
    let explanationEn: String
    let verseRefHy: String
    let verseRefRu: String
    let verseRefEn: String
    
    var isAIGenerated: Bool = false
    var aiProviderName: String? = nil
    
    init(
        id: UUID = UUID(),
        category: QuizCategory,
        difficulty: QuizDifficulty = .medium,
        questionHy: String,
        questionRu: String,
        questionEn: String,
        optionsHy: [String],
        optionsRu: [String],
        optionsEn: [String],
        correctAnswerIndex: Int,
        explanationHy: String,
        explanationRu: String,
        explanationEn: String,
        verseRefHy: String,
        verseRefRu: String,
        verseRefEn: String,
        isAIGenerated: Bool = false,
        aiProviderName: String? = nil
    ) {
        self.id = id
        self.category = category
        self.difficulty = difficulty
        self.questionHy = questionHy
        self.questionRu = questionRu
        self.questionEn = questionEn
        self.optionsHy = optionsHy
        self.optionsRu = optionsRu
        self.optionsEn = optionsEn
        self.correctAnswerIndex = correctAnswerIndex
        self.explanationHy = explanationHy
        self.explanationRu = explanationRu
        self.explanationEn = explanationEn
        self.verseRefHy = verseRefHy
        self.verseRefRu = verseRefRu
        self.verseRefEn = verseRefEn
        self.isAIGenerated = isAIGenerated
        self.aiProviderName = aiProviderName
    }
    
    func question(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return questionHy
        case .russian: return questionRu
        case .english: return questionEn
        }
    }
    
    func options(for lang: AppLanguage) -> [String] {
        switch lang {
        case .armenian: return optionsHy
        case .russian: return optionsRu
        case .english: return optionsEn
        }
    }
    
    func explanation(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return explanationHy
        case .russian: return explanationRu
        case .english: return explanationEn
        }
    }
    
    func verseRef(for lang: AppLanguage) -> String {
        switch lang {
        case .armenian: return verseRefHy
        case .russian: return verseRefRu
        case .english: return verseRefEn
        }
    }
}

// MARK: - База Данных Вопросов Викторины
struct QuizDatabase {
    /// Полная база — объединяет все расширения (OT + Gospels + NT + Church + Extra)
    static var allQuestions: [QuizQuestion] {
        questionsOT + questionsGospels + questionsNT + questionsChurch + questionsExtra
    }
}
