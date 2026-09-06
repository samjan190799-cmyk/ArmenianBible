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
    @AppStorage("quiz_ai_generation_enabled") private var isAIGenerationEnabled = true
    @State private var isGeneratingAI = false
    @State private var showNoKeyAlert = false
    @State private var showAIFailureAlert = false
    @State private var aiErrorMessage = ""
    @State private var aiGenerationStep = 0
    @State private var aiStepTimer: Timer? = nil
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
                        isAIGenerationEnabled: $isAIGenerationEnabled,
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
                                    // Бейдж происхождения вопроса: ИИ или База
                                    HStack(spacing: 6) {
                                        if question.isAIGenerated {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Color(hex: "F59E0B"))
                                            Text("\("quiz_badge_ai_generated".localized(for: manager.appLanguage)) • \(question.aiProviderName ?? QuizAIEngine.shared.currentProviderDisplayName)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color(hex: "F59E0B"), accentColor],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        } else {
                                            Image(systemName: "book.closed.fill")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.secondary)
                                            Text("quiz_badge_offline_database".localized(for: manager.appLanguage))
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(question.isAIGenerated ? Color(hex: "F59E0B").opacity(0.12) : Color.primary.opacity(0.06))
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(question.isAIGenerated ? Color(hex: "F59E0B").opacity(0.35) : Color.clear, lineWidth: 1)
                                    )
                                    .padding(.bottom, 2)
                                    
                                    Image(systemName: "questionmark.bubble.fill")
                                        .font(.system(size: 26))
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
            
            // MARK: - Оверлей ожидания генерации вопросов через ИИ
            if isGeneratingAI {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F59E0B").opacity(0.25), accentColor.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "F59E0B"), accentColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text("quiz_generating_title".localized(for: manager.appLanguage))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Text(currentAIStepText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: 38)
                            .padding(.horizontal, 14)
                            .animation(.easeInOut(duration: 0.3), value: aiGenerationStep)
                    }
                    
                    // Индикатор активного ИИ
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                        Text(QuizAIEngine.shared.currentProviderDisplayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                        .scaleEffect(1.1)
                        .padding(.top, 2)
                }
                .padding(24)
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
                .shadow(color: Color.black.opacity(0.25), radius: 25, y: 10)
                .padding(28)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $isShowingAchievements) {
            BibleAchievementsView()
        }
        .alert(isPresented: $showNoKeyAlert) {
            Alert(
                title: Text("quiz_ai_no_key_title".localized(for: manager.appLanguage)),
                message: Text("quiz_ai_no_key_message".localized(for: manager.appLanguage)),
                primaryButton: .default(Text("quiz_play_classic_button".localized(for: manager.appLanguage)), action: {
                    isAIGenerationEnabled = false
                    startOfflineQuiz()
                }),
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showAIFailureAlert) {
            Alert(
                title: Text("quiz_ai_failed_title".localized(for: manager.appLanguage)),
                message: Text(aiErrorMessage.isEmpty ? "quiz_ai_failed_message".localized(for: manager.appLanguage) : "\("quiz_ai_failed_message".localized(for: manager.appLanguage))\n\n(\(aiErrorMessage))"),
                primaryButton: .default(Text("quiz_play_classic_button".localized(for: manager.appLanguage)), action: {
                    startOfflineQuiz()
                }),
                secondaryButton: .cancel(Text("close_button".localized(for: manager.appLanguage)))
            )
        }
        .onAppear {
            QuizAdaptiveDiary.shared.recordSession()
        }
        .onDisappear {
            stopAITimer()
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
    
    private func startAITimer() {
        aiGenerationStep = 0
        aiStepTimer?.invalidate()
        aiStepTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    aiGenerationStep = (aiGenerationStep + 1) % 4
                }
            }
        }
    }
    
    private func stopAITimer() {
        aiStepTimer?.invalidate()
        aiStepTimer = nil
    }
    
    private var currentAIStepText: String {
        let providerName = QuizAIEngine.shared.currentProviderDisplayName
        switch aiGenerationStep {
        case 0:
            switch manager.appLanguage {
            case .armenian: return "Կապվում ենք \(providerName) նեյրոցանցի հետ..."
            case .russian: return "Подключение к нейросети \(providerName)..."
            case .english: return "Connecting to \(providerName)..."
            }
        case 1:
            switch manager.appLanguage {
            case .armenian: return "Աստվածաշնչի ուսումնասիրություն և յուրահատուկ թեմաների ընտրություն..."
            case .russian: return "Анализ Писания и подбор уникальных тем..."
            case .english: return "Analyzing Scripture and selecting unique themes..."
            }
        case 2:
            switch manager.appLanguage {
            case .armenian: return "Հարցերի, պատասխանների և մեկնաբանությունների կազմում..."
            case .russian: return "Формирование вариантов ответа и богословских пояснений..."
            case .english: return "Generating questions, options and biblical explanations..."
            }
        default:
            switch manager.appLanguage {
            case .armenian: return "Ստուգում օրագրով՝ կրկնությունները բացառելու համար..."
            case .russian: return "Проверка по адаптивному дневнику для исключения повторов..."
            case .english: return "Verifying with adaptive diary to prevent repetition..."
            }
        }
    }
    
    private func startQuiz() {
        triggerHaptic(.medium)
        
        if isAIGenerationEnabled {
            guard QuizAIEngine.shared.isAIAvailable else {
                showNoKeyAlert = true
                return
            }
            
            isGeneratingAI = true
            startAITimer()
            
            Task { @MainActor in
                do {
                    let questions = try await QuizAIEngine.shared.generateQuestions(
                        category: selectedCategory,
                        count: selectedQuestionCount,
                        language: manager.appLanguage
                    )
                    stopAITimer()
                    activeQuestions = questions
                    currentQuestionIndex = 0
                    score = 0
                    selectedAnswerIndex = nil
                    showAnswerDetails = false
                    quizFinished = false
                    newlyUnlockedBadges = []
                    categoryBreakdown = [:]
                    isGeneratingAI = false
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        quizStarted = true
                    }
                } catch {
                    stopAITimer()
                    isGeneratingAI = false
                    aiErrorMessage = error.localizedDescription
                    showAIFailureAlert = true
                }
            }
        } else {
            startOfflineQuiz()
        }
    }
    
    private func startOfflineQuiz() {
        activeQuestions = BibleQuizGenerator.shared.fetchQuestions(category: selectedCategory, count: selectedQuestionCount)
        currentQuestionIndex = 0
        score = 0
        selectedAnswerIndex = nil
        showAnswerDetails = false
        quizFinished = false
        newlyUnlockedBadges = []
        categoryBreakdown = [:]
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            quizStarted = true
        }
    }
    
    private func selectAnswer(_ index: Int, question: QuizQuestion, proxy: ScrollViewProxy) {
        selectedAnswerIndex = index
        let isCorrect = (index == question.correctAnswerIndex)
        
        // Невидимая регистрация ответа в адаптивный дневник («Magic Under The Hood»)
        QuizAdaptiveDiary.shared.recordQuestionAnswer(
            questionText: question.question(for: manager.appLanguage),
            category: question.category,
            isCorrect: isCorrect
        )
        
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
    @Binding var isAIGenerationEnabled: Bool
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
    
    private let counts = [5, 10, 15, 20]
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
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
                
                // Выбор режима викторины (ИИ с адаптацией vs Офлайн база)
                VStack(alignment: .leading, spacing: 8) {
                    Text("quiz_mode_title".localized(for: language))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    HStack(spacing: 10) {
                        Button {
                            triggerHaptic(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                isAIGenerationEnabled = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("quiz_mode_ai".localized(for: language))
                                    .font(.system(size: 13, weight: isAIGenerationEnabled ? .bold : .medium))
                            }
                            .foregroundColor(isAIGenerationEnabled ? .white : primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(isAIGenerationEnabled ? accentColor : cardBackgroundColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isAIGenerationEnabled ? accentColor : Color.primary.opacity(0.06), lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button {
                            triggerHaptic(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                isAIGenerationEnabled = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("quiz_mode_classic".localized(for: language))
                                    .font(.system(size: 13, weight: !isAIGenerationEnabled ? .bold : .medium))
                            }
                            .foregroundColor(!isAIGenerationEnabled ? .white : primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(!isAIGenerationEnabled ? accentColor : cardBackgroundColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(!isAIGenerationEnabled ? accentColor : Color.primary.opacity(0.06), lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Подсказка о выбранном движке
                    HStack(spacing: 6) {
                        Image(systemName: isAIGenerationEnabled ? "sparkles" : "internaldrive.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isAIGenerationEnabled ? Color(hex: "F59E0B") : secondaryAccentColor)
                        Text(isAIGenerationEnabled ?
                             "\("quiz_mode_ai_hint".localized(for: language)) • \(QuizAIEngine.shared.currentProviderDisplayName)" :
                             "quiz_mode_classic_hint".localized(for: language))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                
                // Выбор количества вопросов
                VStack(alignment: .leading, spacing: 8) {
                    Text("quiz_questions_count".localized(for: language))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    HStack(spacing: 10) {
                        ForEach(counts, id: \.self) { count in
                            Button {
                                triggerHaptic(.light)
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

