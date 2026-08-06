import SwiftUI
import UIKit

// MARK: - Категория Викторины
enum QuizCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case oldTestament = "old_testament"
    case newTestament = "new_testament"
    case gospels = "gospels"
    
    var id: String { rawValue }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .all:
            return "quiz_cat_all".localized(for: language)
        case .oldTestament:
            return "quiz_cat_old".localized(for: language)
        case .newTestament:
            return "quiz_cat_new".localized(for: language)
        case .gospels:
            return "quiz_cat_gospels".localized(for: language)
        }
    }
}

// MARK: - Модель вопроса Викторины
struct QuizQuestion: Identifiable {
    let id = UUID()
    let category: QuizCategory
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

// MARK: - Главный Экран Викторины
struct BibleQuizView: View {
    @ObservedObject var manager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedCategory: QuizCategory = .all
    @State private var quizStarted = false
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var showAnswerDetails = false
    @State private var quizFinished = false
    @State private var activeQuestions: [QuizQuestion] = []
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    private var secondaryAccentColor: Color {
        Color(hex: manager.accentTheme.secondaryColorHex)
    }
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.85)
    }
    private var cardBorderColor: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            // Фоновое неоновое свечение
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(colorScheme == .dark ? 0.08 : 0.05), Color.clear]),
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Верхний Бар Навигации
                HStack {
                    Button {
                        triggerHaptic(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                    
                    Text("quiz_title".localized(for: manager.appLanguage))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    // Заглушка для выравнивания
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                if !quizStarted {
                    // MARK: - Экран Старта и Выбора Категории
                    QuizStartView(
                        selectedCategory: $selectedCategory,
                        bestScore: manager.quizBestScore,
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        onStart: startQuiz
                    )
                } else if quizFinished {
                    // MARK: - Экран Итоговых Результатов
                    QuizResultView(
                        score: score,
                        total: activeQuestions.count,
                        bestScore: manager.quizBestScore,
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        onRestart: {
                            quizStarted = false
                            quizFinished = false
                        }
                    )
                } else if currentQuestionIndex < activeQuestions.count {
                    // MARK: - Игровой Процесс Тестирования
                    let question = activeQuestions[currentQuestionIndex]
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Прогресс
                            HStack {
                                Text("\(currentQuestionIndex + 1) / \(activeQuestions.count)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(secondaryAccentColor)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                    Text("\(score)")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(primaryTextColor)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(activeQuestions.count))
                                .tint(accentColor)
                                .padding(.horizontal, 20)
                            
                            // Вопрос
                            VStack(spacing: 12) {
                                Image(systemName: "questionmark.bubble.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(accentColor)
                                
                                Text(question.question(for: manager.appLanguage))
                                    .font(.system(size: 19, weight: .semibold, design: .serif))
                                    .foregroundColor(primaryTextColor)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(cardBackgroundColor)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(cardBorderColor, lineWidth: 1.2)
                            )
                            .padding(.horizontal, 20)
                            
                            // 4 Варианта Ответа
                            VStack(spacing: 12) {
                                ForEach(0..<question.options(for: manager.appLanguage).count, id: \.self) { idx in
                                    let optionText = question.options(for: manager.appLanguage)[idx]
                                    let isSelected = selectedAnswerIndex == idx
                                    let isCorrect = idx == question.correctAnswerIndex
                                    
                                    Button {
                                        if selectedAnswerIndex == nil {
                                            selectAnswer(idx, question: question)
                                        }
                                    } label: {
                                        HStack {
                                            Text("\(letterPrefix(for: idx)).")
                                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                                .foregroundColor(optionTextColor(isSelected: isSelected, isCorrect: isCorrect))
                                            
                                            Text(optionText)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(primaryTextColor)
                                                .multilineTextAlignment(.leading)
                                            
                                            Spacer()
                                            
                                            if selectedAnswerIndex != nil {
                                                if isCorrect {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                } else if isSelected {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .fill(optionBgColor(isSelected: isSelected, isCorrect: isCorrect))
                                            }
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(optionBorderColor(isSelected: isSelected, isCorrect: isCorrect), lineWidth: 1.2)
                                        )
                                    }
                                    .disabled(selectedAnswerIndex != nil)
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Пояснение и Кнопка "Дальше"
                            if showAnswerDetails {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .foregroundColor(secondaryAccentColor)
                                        Text(question.verseRef(for: manager.appLanguage))
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(secondaryAccentColor)
                                    }
                                    
                                    Text(question.explanation(for: manager.appLanguage))
                                        .font(.system(size: 14))
                                        .foregroundColor(primaryTextColor.opacity(0.85))
                                        .lineSpacing(4)
                                    
                                    Button {
                                        triggerHaptic(.medium)
                                        nextQuestion()
                                    } label: {
                                        Text("quiz_next_question".localized(for: manager.appLanguage))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(accentColor)
                                            .cornerRadius(14)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .padding(.top, 6)
                                }
                                .padding(18)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(cardBackgroundColor)
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(cardBorderColor, lineWidth: 1.2)
                                )
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }
    
    private func letterPrefix(for index: Int) -> String {
        switch index {
        case 0: return "A"
        case 1: return "B"
        case 2: return "C"
        default: return "D"
        }
    }
    
    private func optionBgColor(isSelected: Bool, isCorrect: Bool) -> Color {
        if selectedAnswerIndex == nil {
            return cardBackgroundColor
        }
        if isCorrect {
            return Color.green.opacity(0.12)
        }
        if isSelected && !isCorrect {
            return Color.red.opacity(0.12)
        }
        return cardBackgroundColor
    }
    
    private func optionBorderColor(isSelected: Bool, isCorrect: Bool) -> Color {
        if selectedAnswerIndex == nil {
            return primaryTextColor.opacity(0.08)
        }
        if isCorrect {
            return Color.green
        }
        if isSelected && !isCorrect {
            return Color.red
        }
        return primaryTextColor.opacity(0.08)
    }
    
    private func optionTextColor(isSelected: Bool, isCorrect: Bool) -> Color {
        if selectedAnswerIndex == nil {
            return secondaryAccentColor
        }
        if isCorrect {
            return .green
        }
        if isSelected && !isCorrect {
            return .red
        }
        return secondaryAccentColor
    }
    
    private func startQuiz() {
        triggerHaptic(.medium)
        let filtered: [QuizQuestion]
        if selectedCategory == .all {
            filtered = QuizDatabase.allQuestions
        } else {
            filtered = QuizDatabase.allQuestions.filter { $0.category == selectedCategory }
        }
        activeQuestions = Array(filtered.shuffled().prefix(10))
        currentQuestionIndex = 0
        score = 0
        selectedAnswerIndex = nil
        showAnswerDetails = false
        quizFinished = false
        withAnimation {
            quizStarted = true
        }
    }
    
    private func selectAnswer(_ index: Int, question: QuizQuestion) {
        selectedAnswerIndex = index
        let isCorrect = (index == question.correctAnswerIndex)
        if isCorrect {
            triggerHapticNotification(.success)
            score += 1
        } else {
            triggerHapticNotification(.error)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showAnswerDetails = true
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex + 1 < activeQuestions.count {
            selectedAnswerIndex = nil
            showAnswerDetails = false
            currentQuestionIndex += 1
        } else {
            manager.updateQuizBestScore(score)
            withAnimation {
                quizFinished = true
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func triggerHapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// MARK: - Экран Старта Викторины
struct QuizStartView: View {
    @Binding var selectedCategory: QuizCategory
    let bestScore: Int
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 42))
                        .foregroundColor(accentColor)
                }
                
                Text("quiz_start_title".localized(for: language))
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(primaryTextColor)
                
                Text("quiz_start_subtitle".localized(for: language))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            if bestScore > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                    Text("quiz_best_score".localized(for: language) + ": \(bestScore) / 10")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(primaryTextColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(20)
            }
            
            // Выбор категории
            VStack(alignment: .leading, spacing: 10) {
                Text("quiz_select_category".localized(for: language))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 10) {
                    ForEach(QuizCategory.allCases) { cat in
                        Button {
                            selectedCategory = cat
                        } label: {
                            HStack {
                                Text(cat.title(for: language))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(primaryTextColor)
                                
                                Spacer()
                                
                                if selectedCategory == cat {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(accentColor)
                                }
                            }
                            .padding(14)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(selectedCategory == cat ? accentColor.opacity(0.1) : cardBackgroundColor)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(selectedCategory == cat ? accentColor : Color.primary.opacity(0.06), lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                onStart()
            } label: {
                Text("quiz_button_start".localized(for: language))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accentColor)
                    .cornerRadius(16)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Экран Результатов Викторины
struct QuizResultView: View {
    let score: Int
    let total: Int
    let bestScore: Int
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onRestart: () -> Void
    
    private var resultTitle: String {
        let percentage = Double(score) / Double(total)
        if percentage >= 0.9 {
            return "quiz_result_expert".localized(for: language)
        } else if percentage >= 0.6 {
            return "quiz_result_good".localized(for: language)
        } else {
            return "quiz_result_try_again".localized(for: language)
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: score >= 6 ? "sparkles" : "book.closed")
                        .font(.system(size: 46))
                        .foregroundColor(accentColor)
                }
                
                Text(resultTitle)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(primaryTextColor)
                
                Text("\(score) / \(total)")
                    .font(.system(size: 38, weight: .black, design: .monospaced))
                    .foregroundColor(accentColor)
                
                Text("quiz_result_subtitle".localized(for: language))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            .padding(26)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1.2)
            )
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                onRestart()
            } label: {
                Text("quiz_button_play_again".localized(for: language))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accentColor)
                    .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - База Данных Вопросов Викторины
struct QuizDatabase {
    static let allQuestions: [QuizQuestion] = [
        QuizQuestion(
            category: .oldTestament,
            questionHy: "Քանի՞ օրում Աստված արարեց աշխարհը և հանգստացավ յոթերորդ օրը։",
            questionRu: "За сколько дней Бог сотворил мир, после чего почил в день седьмой?",
            questionEn: "In how many days did God create the world before resting on the seventh day?",
            optionsHy: ["5 օրում", "6 օրում", "7 օրում", "40 օրում"],
            optionsRu: ["За 5 дней", "За 6 дней", "За 7 дней", "За 40 дней"],
            optionsEn: ["In 5 days", "In 6 days", "In 7 days", "In 40 days"],
            correctAnswerIndex: 1,
            explanationHy: "Աստված արարեց երկինքն ու երկիրը 6 օրում, իսկ յոթերորդ օրը հանգստացավ Իր բոլոր գործերից։",
            explanationRu: "Бог сотворил небо и землю за 6 дней, а в седьмой день почил от всех дел Своих.",
            explanationEn: "God created the heavens and the earth in 6 days, and rested on the seventh day from all His work.",
            verseRefHy: "Ծննդոց 2:2",
            verseRefRu: "Бытие 2:2",
            verseRefEn: "Genesis 2:2"
        ),
        QuizQuestion(
            category: .oldTestament,
            questionHy: "Ո՞վ տապան կառուցեց ջրհեղեղից փրկվելու համար։",
            questionRu: "Кто построил ковчег для спасения от Великого потопа?",
            questionEn: "Who built the ark to survive the Great Flood?",
            optionsHy: ["Աբրահամը", "Մովսեսը", "Նոյը", "Դավիթը"],
            optionsRu: ["Авраам", "Моисей", "Ной", "Давид"],
            optionsEn: ["Abraham", "Moses", "Noah", "David"],
            correctAnswerIndex: 2,
            explanationHy: "Աստված պատվիրեց Նոյին տապան շինել, որպեսզի նա և իր ընտանիքը փրկվեն ջրհեղեղից։",
            explanationRu: "Бог повелел Ною построить ковчег, чтобы спасти свою семью и животных от потопа.",
            explanationEn: "God commanded Noah to build an ark to save his family and animals from the flood.",
            verseRefHy: "Ծննդոց 6:14",
            verseRefRu: "Бытие 6:14",
            verseRefEn: "Genesis 6:14"
        ),
        QuizQuestion(
            category: .oldTestament,
            questionHy: "Ո՞վ սպանեց Գողիաթին պարսատիկով և քարով։",
            questionRu: "Кто победил великана Голиафа с помощью пращи и камня?",
            questionEn: "Who defeated the giant Goliath using a sling and a stone?",
            optionsHy: ["Սավուղը", "Սողոմոնը", "Դավիթը", "Սամսոնը"],
            optionsRu: ["Саул", "Соломон", "Давид", "Самсон"],
            optionsEn: ["Saul", "Solomon", "David", "Samson"],
            correctAnswerIndex: 2,
            explanationHy: "Երիտասարդ Դավիթը հավատով ելավ փղշտացի Գողիաթի դեմ և հաղթեց նրան Տիրոջ անունով։",
            explanationRu: "Молодой Давид выступил с верою против филистимлянина Голиафа и победил во имя Господа.",
            explanationEn: "Young David confronted Goliath in faith and defeated him in the name of the Lord.",
            verseRefHy: "Ա Թագավորաց 17:50",
            verseRefRu: "1 Царств 17:50",
            verseRefEn: "1 Samuel 17:50"
        ),
        QuizQuestion(
            category: .gospels,
            questionHy: "Ո՞ր քաղաքում ծնվեց Հիսուս Քրիստոս։",
            questionRu: "В каком городе родился Иисус Христос?",
            questionEn: "In which city was Jesus Christ born?",
            optionsHy: ["Նազարեթ", "Երուսաղեմ", "Բեթղեհեմ", "Կափառնաում"],
            optionsRu: ["Назарет", "Иерусалим", "Вифлеем", "Капернаум"],
            optionsEn: ["Nazareth", "Jerusalem", "Bethlehem", "Capernaum"],
            correctAnswerIndex: 2,
            explanationHy: "Հիսուս ծնվեց Հուդայի Բեթղեհեմ քաղաքում, ինչպես մարգարեացվել էր։",
            explanationRu: "Иисус родился в Вифлееме Иудейском, как и предрекали пророки.",
            explanationEn: "Jesus was born in Bethlehem of Judea, as foretold by the prophets.",
            verseRefHy: "Մատթեոս 2:1",
            verseRefRu: "Матфея 2:1",
            verseRefEn: "Matthew 2:1"
        ),
        QuizQuestion(
            category: .gospels,
            questionHy: "Քանի՞ առաքյալ ընտրեց Հիսուսը։",
            questionRu: "Сколько апостолов избрал Иисус?",
            questionEn: "How many apostles did Jesus choose?",
            optionsHy: ["7", "10", "12", "70"],
            optionsRu: ["7", "10", "12", "70"],
            optionsEn: ["7", "10", "12", "70"],
            correctAnswerIndex: 2,
            explanationHy: "Հիսուս ընտրեց տասներկու աշակերտների, որպեսզի նրանք լինեն Իր ականատեսները։",
            explanationRu: "Иисус призвал двенадцать учеников, чтобы они проповедовали Евангелие.",
            explanationEn: "Jesus called twelve disciples to follow Him and preach the Gospel.",
            verseRefHy: "Մատթեոս 10:1",
            verseRefRu: "Матфея 10:1",
            verseRefEn: "Matthew 10:1"
        ),
        QuizQuestion(
            category: .newTestament,
            questionHy: "Ո՞վ էր Պողոս առաքյալը նախքան Քրիստոնեություն ընդունելը։",
            questionRu: "Кем был апостол Павел до своего обращения в христианство?",
            questionEn: "Who was the Apostle Paul before converting to Christianity?",
            optionsHy: ["Ձկնորս", "Սավուղ (հալածող)", "Մաքսավոր", "Քահանայապետ"],
            optionsRu: ["Рыбак", "Савл (гонитель)", "Миттарь", "Первосвященник"],
            optionsEn: ["Fisherman", "Saul (persecutor)", "Tax collector", "High Priest"],
            correctAnswerIndex: 1,
            explanationHy: "Սավուղը հալածում էր եկեղեցին, մինչև Դամասկոսի ճանապարհին հանդիպեց Տեր Հիսուսին։",
            explanationRu: "Савл яростно гнал христиан, пока на пути в Дамаск не встретил воскресшего Господа.",
            explanationEn: "Saul persecuted Christians until he encountered the risen Lord on the road to Damascus.",
            verseRefHy: "Գործք 9:3-5",
            verseRefRu: "Деяния 9:3-5",
            verseRefEn: "Acts 9:3-5"
        )
    ]
}
