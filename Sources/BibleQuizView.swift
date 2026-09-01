import SwiftUI
import UIKit

// MARK: - Главный Экран Викторины
struct BibleQuizView: View {
    @ObservedObject var manager = BibleManager.shared
    @ObservedObject var achievements = AchievementsManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedCategory: QuizCategory = .all
    @State private var selectedQuestionCount = 10
    @State private var quizStarted = false
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var showAnswerDetails = false
    @State private var quizFinished = false
    @State private var activeQuestions: [QuizQuestion] = []
    @State private var categoryBreakdown: [QuizCategory: Int] = [:]
    @State private var isShowingAchievements = false
    @State private var newlyUnlockedBadges: [AchievementBadge] = []
    
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
                    
                    // Кнопка Наград в правом углу
                    Button {
                        triggerHaptic(.light)
                        isShowingAchievements = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.orange)
                            
                            if achievements.unlockedCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                if !quizStarted {
                    // MARK: - Экран Старта и Выбора Категории
                    QuizStartView(
                        selectedCategory: $selectedCategory,
                        selectedQuestionCount: $selectedQuestionCount,
                        bestScore: manager.quizBestScore,
                        unlockedBadgesCount: achievements.unlockedCount,
                        totalBadgesCount: achievements.badges.count,
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        onOpenAchievements: {
                            triggerHaptic(.light)
                            isShowingAchievements = true
                        },
                        onStart: startQuiz
                    )
                } else if quizFinished {
                    // MARK: - Экран Итоговых Результатов
                    QuizResultView(
                        score: score,
                        total: activeQuestions.count,
                        bestScore: manager.quizBestScore,
                        newlyUnlockedBadges: newlyUnlockedBadges,
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        secondaryAccentColor: secondaryAccentColor,
                        cardBackgroundColor: cardBackgroundColor,
                        cardBorderColor: cardBorderColor,
                        primaryTextColor: primaryTextColor,
                        onOpenAchievements: {
                            triggerHaptic(.light)
                            isShowingAchievements = true
                        },
                        onRestart: {
                            quizStarted = false
                            quizFinished = false
                            newlyUnlockedBadges = []
                            categoryBreakdown = [:]
                        }
                    )
                } else if currentQuestionIndex < activeQuestions.count {
                    // MARK: - Игровой Процесс Тестирования
                    let question = activeQuestions[currentQuestionIndex]
                    
                    ScrollViewReader { proxy in
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
                                        .font(.system(size: 18, weight: .semibold, design: .serif))
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
                                .id("questionTop")
                                
                                // 4 Варианта Ответа
                                VStack(spacing: 12) {
                                    ForEach(0..<question.options(for: manager.appLanguage).count, id: \.self) { idx in
                                        let optionText = question.options(for: manager.appLanguage)[idx]
                                        let isSelected = selectedAnswerIndex == idx
                                        let isCorrect = idx == question.correctAnswerIndex
                                        
                                        Button {
                                            if selectedAnswerIndex == nil {
                                                selectAnswer(idx, question: question, proxy: proxy)
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
                                    VStack(alignment: .leading, spacing: 14) {
                                        // Интерактивная плашка стиха
                                        HStack {
                                            Button {
                                                triggerHaptic(.medium)
                                                dismiss()
                                                manager.openBibleReader()
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "book.pages.fill")
                                                        .font(.system(size: 12))
                                                    Text(question.verseRef(for: manager.appLanguage))
                                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                    Image(systemName: "arrow.up.right")
                                                        .font(.system(size: 10, weight: .bold))
                                                }
                                                .foregroundColor(secondaryAccentColor)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(secondaryAccentColor.opacity(0.12))
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(ScaleButtonStyle())
                                            
                                            Spacer()
                                        }
                                        
                                        Text(question.explanation(for: manager.appLanguage))
                                            .font(.system(size: 14))
                                            .foregroundColor(primaryTextColor.opacity(0.9))
                                            .lineSpacing(5)
                                        
                                        Button {
                                            triggerHaptic(.medium)
                                            nextQuestion(proxy: proxy)
                                        } label: {
                                            Text("quiz_next_question".localized(for: manager.appLanguage))
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(accentColor)
                                                .cornerRadius(14)
                                                .shadow(color: accentColor.opacity(0.3), radius: 6, y: 3)
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                        .padding(.top, 4)
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
                                    .id("answerDetailsAnchor")
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAchievements) {
            BibleAchievementsView()
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
        activeQuestions = BibleQuizGenerator.shared.fetchQuestions(category: selectedCategory, count: selectedQuestionCount)
        currentQuestionIndex = 0
        score = 0
        selectedAnswerIndex = nil
        showAnswerDetails = false
        quizFinished = false
        newlyUnlockedBadges = []
        categoryBreakdown = [:]
        withAnimation {
            quizStarted = true
        }
    }
    
    private func selectAnswer(_ index: Int, question: QuizQuestion, proxy: ScrollViewProxy) {
        selectedAnswerIndex = index
        let isCorrect = (index == question.correctAnswerIndex)
        if isCorrect {
            triggerHapticNotification(.success)
            score += 1
            categoryBreakdown[question.category, default: 0] += 1
        } else {
            triggerHapticNotification(.error)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showAnswerDetails = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo("answerDetailsAnchor", anchor: .bottom)
            }
        }
    }
    
    private func nextQuestion(proxy: ScrollViewProxy) {
        if currentQuestionIndex + 1 < activeQuestions.count {
            selectedAnswerIndex = nil
            showAnswerDetails = false
            currentQuestionIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo("questionTop", anchor: .top)
                }
            }
        } else {
            manager.updateQuizBestScore(score)
            let unlocked = achievements.recordQuizResult(score: score, total: activeQuestions.count, categoryBreakdown: categoryBreakdown)
            newlyUnlockedBadges = unlocked
            if !unlocked.isEmpty {
                triggerHapticNotification(.success)
            }
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
    @Binding var selectedQuestionCount: Int
    let bestScore: Int
    let unlockedBadgesCount: Int
    let totalBadgesCount: Int
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenAchievements: () -> Void
    let onStart: () -> Void
    
    private let counts = [10, 20, 30]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.12))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 38))
                            .foregroundColor(accentColor)
                    }
                    
                    Text("quiz_start_title".localized(for: language))
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(primaryTextColor)
                    
                    Text("quiz_start_subtitle".localized(for: language))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 10)
                
                // Бейджи результатов и наград
                HStack(spacing: 10) {
                    if bestScore > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                            Text("quiz_best_score".localized(for: language) + ": \(bestScore)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Button {
                        onOpenAchievements()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "medal.fill")
                                .foregroundColor(.yellow)
                            Text("\(unlockedBadgesCount)/\(totalBadgesCount) " + "achievements_btn".localized(for: language))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.yellow.opacity(0.12))
                        .cornerRadius(20)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Выбор количества вопросов
                VStack(alignment: .leading, spacing: 8) {
                    Text("quiz_questions_count".localized(for: language))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    HStack(spacing: 10) {
                        ForEach(counts, id: \.self) { count in
                            Button {
                                selectedQuestionCount = count
                            } label: {
                                Text("\(count) " + "quiz_count_suffix".localized(for: language))
                                    .font(.system(size: 13, weight: selectedQuestionCount == count ? .bold : .medium))
                                    .foregroundColor(selectedQuestionCount == count ? .white : primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedQuestionCount == count ? accentColor : cardBackgroundColor)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedQuestionCount == count ? accentColor : Color.primary.opacity(0.06), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Выбор категории
                VStack(alignment: .leading, spacing: 8) {
                    Text("quiz_select_category".localized(for: language))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 8) {
                        ForEach(QuizCategory.allCases) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(selectedCategory == cat ? accentColor : .secondary)
                                        .frame(width: 24)
                                    
                                    Text(cat.title(for: language))
                                        .font(.system(size: 14, weight: selectedCategory == cat ? .bold : .medium))
                                        .foregroundColor(primaryTextColor)
                                    
                                    Spacer()
                                    
                                    if selectedCategory == cat {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(accentColor)
                                    }
                                }
                                .padding(12)
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
                
                Button {
                    onStart()
                } label: {
                    Text("quiz_button_start".localized(for: language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(accentColor)
                        .cornerRadius(16)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Экран Результатов Викторины
struct QuizResultView: View {
    let score: Int
    let total: Int
    let bestScore: Int
    let newlyUnlockedBadges: [AchievementBadge]
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenAchievements: () -> Void
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Если разблокированы новые награды
                if !newlyUnlockedBadges.isEmpty {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("new_badge_unlocked".localized(for: language))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.yellow)
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                        }
                        
                        ForEach(newlyUnlockedBadges) { badge in
                            HStack(spacing: 12) {
                                Image(systemName: badge.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(badge.title(for: language))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(primaryTextColor)
                                    Text(badge.description(for: language))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.yellow.opacity(0.12))
                            .cornerRadius(14)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1.2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: score >= 6 ? "sparkles" : "book.closed")
                            .font(.system(size: 38))
                            .foregroundColor(accentColor)
                    }
                    
                    Text(resultTitle)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(primaryTextColor)
                    
                    Text("\(score) / \(total)")
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(accentColor)
                    
                    Text("quiz_result_subtitle".localized(for: language))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(22)
                .frame(maxWidth: .infinity)
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
                
                // Кнопка просмотра всех наград
                Button {
                    triggerHaptic(.light)
                    onOpenAchievements()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "medal.fill")
                            .foregroundColor(.orange)
                        Text("view_all_badges".localized(for: language))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(cardBackgroundColor)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                
                // Кнопка Поделиться Результатом
                let shareText = String(format: "quiz_share_text".localized(for: language), score, total)
                ShareLink(item: shareText) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .foregroundColor(secondaryAccentColor)
                        Text("quiz_share_result".localized(for: language))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(cardBackgroundColor)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                
                Button {
                    triggerHaptic(.medium)
                    onRestart()
                } label: {
                    Text("quiz_button_play_again".localized(for: language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentColor)
                        .cornerRadius(16)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .overlay(
            Group {
                if Double(score) / Double(max(1, total)) >= 0.8 {
                    QuizConfettiView()
                        .allowsHitTesting(false)
                }
            }
        )
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Праздничный эффект частиц / Конфетти
struct QuizConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(particleColor(for: i))
                    .frame(width: CGFloat((i % 4 + 2) * 3), height: CGFloat((i % 4 + 2) * 3))
                    .offset(
                        x: animate ? CGFloat(((i * 37) % 300) - 150) : 0,
                        y: animate ? CGFloat(((i * 53) % 400) - 250) : 0
                    )
                    .scaleEffect(animate ? 1.0 : 0.2)
                    .opacity(animate ? 0.85 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animate = true
            }
        }
    }
    
    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue, .green, .mint]
        return colors[index % colors.count]
    }
}

