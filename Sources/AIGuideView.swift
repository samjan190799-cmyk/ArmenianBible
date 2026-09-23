import SwiftUI
import WidgetKit
import LocalAuthentication

// MARK: - ЭКРАН ИИ РУКОВОДСТВА (AI Guide View - Библейский Ответчик)
struct AIGuideView: View {
    @ObservedObject var manager = BibleManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var questionText = ""
    @State private var isAskingAI = false
    @State private var isShowingPaywall = false
    @State private var isShowingRewardedOffer = false
    
    // Ошибки и подтверждения
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    @State private var showingClearChatConfirmation = false
    
    // Экспорт и Toast
    @State private var shareItem: ShareItem? = nil
    @State private var showCopiedToast = false
    @State private var toastMessage = ""
    
    @Environment(\.colorScheme) private var colorScheme
    
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
    
    struct SuggestedQuestion: Identifiable {
        let id = UUID()
        let key: String
        let icon: String
    }
    
    private let suggestedQuestions = [
        SuggestedQuestion(key: "q_fear", icon: "shield.fill"),
        SuggestedQuestion(key: "q_forgive", icon: "heart.fill"),
        SuggestedQuestion(key: "q_peace", icon: "wind"),
        SuggestedQuestion(key: "q_hope", icon: "sun.max.fill"),
        SuggestedQuestion(key: "q_trials", icon: "hands.sparkles.fill")
    ]
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            // Фоновое мягкое свечение
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(colorScheme == .dark ? 0.07 : 0.04), Color.clear]),
                center: .top,
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Верхняя панель чата (Header)
                chatHeaderView
                
                Divider()
                    .opacity(0.2)
                
                // 2. Область сообщений со скроллом к низу
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if manager.aiChatMessages.isEmpty {
                                chatWelcomeView
                            } else {
                                ForEach(manager.aiChatMessages) { msg in
                                    AIChatBubbleRow(
                                        message: msg,
                                        manager: manager,
                                        accentColor: accentColor,
                                        secondaryAccentColor: secondaryAccentColor,
                                        cardBackgroundColor: cardBackgroundColor,
                                        cardBorderColor: cardBorderColor,
                                        primaryTextColor: primaryTextColor,
                                        onShareVerse: { verse in
                                            shareVerse(verse)
                                        },
                                        onCopy: { text in
                                            copyText(text)
                                        }
                                    )
                                    .id(msg.id)
                                }
                                
                                if isAskingAI {
                                    AIChatThinkingRow(
                                        language: manager.appLanguage,
                                        accentColor: accentColor,
                                        cardBackgroundColor: cardBackgroundColor,
                                        cardBorderColor: cardBorderColor,
                                        primaryTextColor: primaryTextColor
                                    )
                                    .id("thinkingAnchor")
                                }
                            }
                            
                            // Якорь прокрутки
                            Color.clear
                                .frame(height: 1)
                                .id("bottomChatAnchor")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: manager.aiChatMessages.count) { _ in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            proxy.scrollTo("bottomChatAnchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: isAskingAI) { asking in
                        if asking {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                proxy.scrollTo("bottomChatAnchor", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 3. Нижняя панель ввода (Bottom Input Bar)
                chatBottomInputBar
            }
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
            
            // Всплывающий Toast о копировании
            if showCopiedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(25)
                    .shadow(radius: 10)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCopiedToast)
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
        }
        .confirmationDialog(
            limitDialogTitle,
            isPresented: $isShowingRewardedOffer,
            titleVisibility: .visible
        ) {
            Button(limitDialogWatchAdTitle) {
                triggerHaptic(.medium)
                AdManager.shared.showRewardedAd {
                    let msg = manager.appLanguage == .armenian ? "+1 հարց ավելացվեց!" : (manager.appLanguage == .russian ? "+1 вопрос добавлен!" : "+1 question added!")
                    showToastMessage(msg)
                    if !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        submitQuestion(questionText)
                    }
                }
            }
            Button(limitDialogPaywallTitle) {
                triggerHaptic(.light)
                isShowingPaywall = true
            }
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(limitDialogMessage)
        }
        .alert("alert_empty_key_title".localized(for: manager.appLanguage), isPresented: $showingNoKeyAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(String(format: "alert_empty_key_message".localized(for: manager.appLanguage), manager.activeProvider.displayName))
        }
        .alert("alert_error_title".localized(for: manager.appLanguage), isPresented: $showingErrorAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .confirmationDialog(
            "ai_clear_chat_confirm_title".localized(for: manager.appLanguage),
            isPresented: $showingClearChatConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "ai_clear_chat_btn".localized(for: manager.appLanguage),
                role: .destructive
            ) {
                triggerHaptic(.medium)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    manager.clearAIChat()
                }
            }
            Button("alert_cancel_button".localized(for: manager.appLanguage), role: .cancel) {}
        }
    }
    
    // MARK: - Верхняя панель (Header)
    private var chatHeaderView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("ai_guide_title".localized(for: manager.appLanguage))
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(primaryTextColor)
                    
                    // Меню переключения активной модели ИИ
                    Menu {
                        ForEach(AIProvider.allCases) { provider in
                            Button {
                                triggerHaptic(.medium)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    manager.activeProvider = provider
                                }
                            } label: {
                                HStack {
                                    Text(provider.displayName)
                                    if manager.activeProvider == provider {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color(hex: manager.activeProvider.accentColorHex))
                                .frame(width: 6, height: 6)
                            Text(manager.activeProvider.displayName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: manager.activeProvider.accentColorHex).opacity(0.12))
                        .cornerRadius(8)
                    }
                }
                
                // Статус подписки и кнопка пополнения копилки вопросов
                HStack(spacing: 6) {
                    Image(systemName: subscriptionManager.isPremium ? "crown.fill" : (subscriptionManager.accumulatedBonusAiQuestions > 0 ? "archivebox.fill" : "sparkles"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    
                    Text(headerQuestionsStatusText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(subscriptionManager.isPremium ? Color(hex: "F59E0B") : .secondary)
                    
                    if !subscriptionManager.isPremium {
                        Button {
                            triggerHaptic(.light)
                            isShowingPaywall = true
                        } label: {
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(accentColor.opacity(0.12))
                                .cornerRadius(4)
                        }
                        
                        // Кнопка пополнения копилки за просмотр видео (+1 несгораемый вопрос)
                        Button {
                            triggerHaptic(.medium)
                            let isShown = AdManager.shared.showRewardedAd {
                                let total = subscriptionManager.remainingFreeAiQuestions
                                let banked = subscriptionManager.accumulatedBonusAiQuestions
                                let msg = manager.appLanguage == .armenian ?
                                    "+1 հարց կուտակվեց: Ընդհանուր՝ \(total) (\(banked) կուտակված)" :
                                    (manager.appLanguage == .russian ? "+1 вопрос накоплен! Всего: \(total) (\(banked) в копилке)" : "+1 question banked! Total: \(total) (\(banked) banked)")
                                showToastMessage(msg)
                            }
                            if !isShown {
                                let waitMsg = manager.appLanguage == .armenian ?
                                    "Գովազդը բեռնվում է, խնդրում ենք սպասել մի քանի վայրկյան..." :
                                    (manager.appLanguage == .russian ? "Реклама загружается, пожалуйста, подождите пару секунд..." : "Ad is loading, please wait a few seconds...")
                                showToastMessage(waitMsg)
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text(manager.appLanguage == .armenian ? "+1 կուտակել" : (manager.appLanguage == .russian ? "+1 копить" : "+1 bank"))
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(4)
                            .shadow(color: Color(hex: "F59E0B").opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Кнопка очистки истории диалога
            if !manager.aiChatMessages.isEmpty {
                Button {
                    triggerHaptic(.light)
                    showingClearChatConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(9)
                        .background(cardBackgroundColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
    
    // MARK: - Приветственный экран, если чат еще пуст
    private var chatWelcomeView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 10)
            
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 68, height: 68)
                Image(systemName: "sparkles")
                    .font(.system(size: 30))
                    .foregroundColor(accentColor)
            }
            
            VStack(spacing: 6) {
                Text("ai_guide_title".localized(for: manager.appLanguage))
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(primaryTextColor)
                
                Text("ai_guide_subtitle".localized(for: manager.appLanguage))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineSpacing(4)
            }
            
            // MARK: - Переключатель моделей ИИ
            HStack(spacing: 8) {
                ForEach(AIProvider.allCases) { provider in
                    Button {
                        triggerHaptic(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            manager.activeProvider = provider
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: provider.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(provider.displayName)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(manager.activeProvider == provider ? .white : primaryTextColor.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            manager.activeProvider == provider ?
                            Color(hex: provider.accentColorHex) :
                            cardBackgroundColor
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(manager.activeProvider == provider ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.vertical, 2)
            
            // MARK: - Баннерная Реклама VK (LuysHybridBannerView)
            LuysHybridBannerView(placement: .home)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            
            // MARK: - Карточка получения вопросов за просмотр рекламы (+1 вопрос)
            if !subscriptionManager.isPremium {
                rewardedBonusCard
            }
            
            // Подсказки быстрых вопросов
            VStack(alignment: .leading, spacing: 10) {
                Text("suggested_questions_title".localized(for: manager.appLanguage))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                ForEach(suggestedQuestions) { sq in
                    Button {
                        triggerHaptic(.medium)
                        let q = sq.key.localized(for: manager.appLanguage)
                        submitQuestion(q)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: sq.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondaryAccentColor)
                                .frame(width: 22)
                            
                            Text(sq.key.localized(for: manager.appLanguage))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(primaryTextColor)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(cardBackgroundColor)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Нижняя панель ввода (Bottom Input Bar)
    private var chatBottomInputBar: some View {
        VStack(spacing: 0) {
            // Предупреждение и быстрая кнопка пополнения копилки при исчерпании лимита вопросов
            if !subscriptionManager.isPremium && subscriptionManager.remainingFreeAiQuestions == 0 {
                HStack(spacing: 8) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    
                    Text(manager.appLanguage == .armenian ? "Հարցերի լիմիտը սպառվել է" : (manager.appLanguage == .russian ? "Лимит вопросов исчерпан" : "Question limit reached"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    Button {
                        triggerHaptic(.medium)
                        AdManager.shared.showRewardedAd {
                            let total = subscriptionManager.remainingFreeAiQuestions
                            let msg = manager.appLanguage == .armenian ? "+1 հարց կուտակվեց: Ընդհանուր՝ \(total)" : (manager.appLanguage == .russian ? "+1 вопрос накоплен! Всего: \(total)" : "+1 question banked! Total: \(total)")
                            showToastMessage(msg)
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text(manager.appLanguage == .armenian ? "+1 կուտակել" : (manager.appLanguage == .russian ? "+1 копить" : "+1 bank"))
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "F59E0B"), Color(hex: "EA580C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(cardBackgroundColor)
            }
            
            Divider()
                .opacity(0.3)
            
            HStack(alignment: .bottom, spacing: 10) {
                TextField("ai_placeholder_prompt".localized(for: manager.appLanguage), text: $questionText, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(size: 15))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(cardBackgroundColor)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(questionText.isEmpty ? Color.primary.opacity(0.08) : accentColor.opacity(0.5), lineWidth: 1.2)
                    )
                    .keyboardDismissToolbar()
                
                Button {
                    triggerHaptic(.medium)
                    let textToSend = questionText
                    questionText = ""
                    hideKeyboard()
                    submitQuestion(textToSend)
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSubmit ? accentColor : Color.gray.opacity(0.3))
                            .frame(width: 42, height: 42)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: -1, y: 1)
                    }
                }
                .disabled(!canSubmit)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
    
    private var canSubmit: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isAskingAI
    }
    
    // MARK: - Логика отправки вопроса
    private func submitQuestion(_ rawQuestion: String) {
        let trimmed = rawQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !subscriptionManager.canAskAI() {
            triggerHaptic(.heavy)
            isShowingRewardedOffer = true
            return
        }
        
        let key: String
        switch manager.activeProvider {
        case .gemini: key = manager.geminiApiKey
        case .chatgpt: key = manager.openaiApiKey
        case .claude: key = manager.anthropicApiKey
        }
        
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            triggerHaptic(.heavy)
            showingNoKeyAlert = true
            return
        }
        
        // Добавляем вопрос пользователя в историю чата
        let userMessage = AIChatMessage(isUser: true, text: trimmed)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            manager.addAIChatMessage(userMessage)
            isAskingAI = true
        }
        
        manager.askBibleAI(question: trimmed) { result in
            DispatchQueue.main.async {
                self.isAskingAI = false
                switch result {
                case .success(let answer):
                    self.subscriptionManager.recordAiQuestionUsed()
                    let aiMessage = AIChatMessage(
                        isUser: false,
                        text: answer.answerText,
                        verse: answer.verse
                    )
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                        self.manager.addAIChatMessage(aiMessage)
                    }
                case .failure(let error):
                    let prefix = "error_generation_prefix".localized(for: manager.appLanguage)
                    self.errorMessage = "\(prefix)\(error.localizedDescription)"
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Карточка вознаграждения за просмотр рекламы (+1 вопрос к ИИ)
    private var rewardedBonusCard: some View {
        Button {
            triggerHaptic(.medium)
            AdManager.shared.showRewardedAd {
                let msg = manager.appLanguage == .armenian ? "+1 հարց ավելացվեց!" : (manager.appLanguage == .russian ? "+1 вопрос добавлен!" : "+1 question added!")
                showToastMessage(msg)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F59E0B").opacity(0.2), Color(hex: "EA580C").opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(manager.appLanguage == .armenian ? "Հարցերի Կուտակիչ (+1)" : (manager.appLanguage == .russian ? "Копилка вопросов (+1)" : "Question Bank (+1)"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        if subscriptionManager.accumulatedBonusAiQuestions > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: 7))
                                Text("\(subscriptionManager.accumulatedBonusAiQuestions)")
                                    .font(.system(size: 9, weight: .black))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color(hex: "10B981"))
                            .cornerRadius(4)
                        } else {
                            Text("REWARD")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1.5)
                                .background(Color(hex: "F59E0B"))
                                .cornerRadius(3)
                        }
                    }
                    
                    Text(manager.appLanguage == .armenian ? "Դիտեք գովազդներ և կուտակեք հարցեր առանց սահմանափակման: Կուտակված հարցերը երբեք չեն սպառվում օրվա ավարտին:" : (manager.appLanguage == .russian ? "Смотрите видео и копите вопросы без ограничений! Накопленные вопросы сохраняются навсегда и не сгорают завтра." : "Watch videos to bank questions with no limit! Banked questions never expire at midnight."))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(manager.appLanguage == .armenian ? "Կուտակել" : (manager.appLanguage == .russian ? "Копить" : "Bank"))
                        .font(.system(size: 11, weight: .bold))
                    Image(systemName: "play.fill")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "F59E0B"), Color(hex: "EA580C")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(10)
                .shadow(color: Color(hex: "F59E0B").opacity(0.35), radius: 3, x: 0, y: 1.5)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(cardBackgroundColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "F59E0B").opacity(0.35), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 4)
    }
    
    // Текст статуса вопросов в шапке с учетом накопленной копилки
    private var headerQuestionsStatusText: String {
        if subscriptionManager.isPremium {
            switch manager.appLanguage {
            case .armenian: return "PRO • Անսահմանափակ"
            case .russian: return "PRO • Безлимитно"
            case .english: return "PRO • Unlimited"
            }
        }
        
        let total = subscriptionManager.remainingFreeAiQuestions
        let banked = subscriptionManager.accumulatedBonusAiQuestions
        
        if banked > 0 {
            switch manager.appLanguage {
            case .armenian: return "Մնացել է \(total) հարց (\(banked) կուտակված)"
            case .russian: return "Осталось \(total) вопр. (\(banked) в копилке)"
            case .english: return "\(total) questions (\(banked) banked)"
            }
        } else {
            switch manager.appLanguage {
            case .armenian: return "Մնացել է \(total) հարց"
            case .russian: return "Осталось \(total) вопр."
            case .english: return "\(total) questions left"
            }
        }
    }
    
    private func showToastMessage(_ text: String) {
        triggerHaptic(.medium)
        toastMessage = text
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showCopiedToast = false
            }
        }
    }
    
    private func copyText(_ text: String) {
        UIPasteboard.general.string = text
        showToastMessage("copied_to_clipboard".localized(for: manager.appLanguage))
    }
    
    @MainActor
    private func shareVerse(_ verse: BibleVerse) {
        let exportView = VerseCardExportView(
            verse: verse,
            theme: manager.accentTheme,
            colorScheme: colorScheme
        )
        let hostingController = UIHostingController(rootView: exportView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let image = renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        self.shareItem = ShareItem(image: image)
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        manager.triggerHapticImpact(style)
    }
    
    // MARK: - Локализация предложений Rewarded рекламы
    private var limitDialogTitle: String {
        switch manager.appLanguage {
        case .armenian: return "Հարցերի սահմանաչափը սպառվել է"
        case .russian: return "Лимит вопросов исчерпан"
        case .english: return "Daily Question Limit Reached"
        }
    }
    
    private var limitDialogMessage: String {
        switch manager.appLanguage {
        case .armenian: return "Դիտեք կարճ տեսահոլովակ՝ հարցերի կուտակիչը լիցքավորելու համար (+1 հարց, չի սպառվում), կամ ակտիվացրեք Premium-ը:"
        case .russian: return "Посмотрите короткий видеоролик, чтобы пополнить копилку вопросов (+1 вопрос, никогда не сгорает), или оформите Premium для безлимита:"
        case .english: return "Watch a short video ad to bank an extra question (never expires), or upgrade to Premium for unlimited access:"
        }
    }
    
    private var limitDialogWatchAdTitle: String {
        switch manager.appLanguage {
        case .armenian: return "Կուտակել +1 հարց (դիտել)"
        case .russian: return "Копить +1 вопрос (видео)"
        case .english: return "Bank +1 Question (Watch)"
        }
    }
    
    private var limitDialogPaywallTitle: String {
        switch manager.appLanguage {
        case .armenian: return "Ակտիվացնել Premium"
        case .russian: return "Оформить Premium"
        case .english: return "Upgrade to Premium"
        }
    }
}

// MARK: - Строка сообщения чата (Bubble Row)

struct AIChatBubbleRow: View {
    let message: AIChatMessage
    @ObservedObject var manager: BibleManager
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onShareVerse: (BibleVerse) -> Void
    let onCopy: (String) -> Void
    
    @State private var isHeartBouncing = false
    
    var body: some View {
        if message.isUser {
            // Сообщение пользователя (справа)
            HStack {
                Spacer(minLength: 44)
                
                Text(message.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: accentColor.opacity(0.25), radius: 6, y: 3)
            }
        } else {
            // Ответ Духовного Помощника (слева)
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    // Заголовок карточки ответа
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentColor)
                        Text("ai_guide_title".localized(for: manager.appLanguage))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentColor)
                        
                        Spacer()
                        
                        // Кнопка копирования ответа
                        Button {
                            onCopy(message.text)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    Text(message.text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(primaryTextColor)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Если есть цитируемый стих
                    if let verse = message.verse {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "laurel.leading")
                                    .font(.system(size: 18))
                                    .foregroundColor(secondaryAccentColor.opacity(0.7))
                                Spacer()
                                Image(systemName: "laurel.trailing")
                                    .font(.system(size: 18))
                                    .foregroundColor(secondaryAccentColor.opacity(0.7))
                            }
                            
                            Text(verse.text)
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundColor(primaryTextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(5)
                            
                            Text(verse.reference)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(secondaryAccentColor)
                            
                            // Кнопки управления стихом
                            HStack(spacing: 18) {
                                // Добавить в Избранное
                                Button {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                                        if manager.isFavorite(verse) {
                                            manager.removeFromFavorites(verse)
                                        } else {
                                            manager.addToFavorites(verse)
                                            isHeartBouncing = true
                                        }
                                    }
                                    if isHeartBouncing {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                                            withAnimation(.easeOut(duration: 0.15)) {
                                                isHeartBouncing = false
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: manager.isFavorite(verse) ? "heart.fill" : "heart")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(manager.isFavorite(verse) ? .red : primaryTextColor.opacity(0.5))
                                        .scaleEffect(isHeartBouncing ? 1.3 : 1.0)
                                        .padding(8)
                                        .background(primaryTextColor.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                // Поделиться открыткой
                                Button {
                                    onShareVerse(verse)
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(primaryTextColor.opacity(0.5))
                                        .padding(8)
                                        .background(primaryTextColor.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                // Скопировать стих
                                Button {
                                    onCopy("\(verse.text)\n— \(verse.reference)")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(primaryTextColor.opacity(0.5))
                                        .padding(8)
                                        .background(primaryTextColor.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(cardBackgroundColor.opacity(0.6))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
                .padding(16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(cardBackgroundColor)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(cardBorderColor, lineWidth: 1.2)
                )
                
                Spacer(minLength: 32)
            }
        }
    }
}

// MARK: - Индикатор размышления ИИ (Thinking Bubble)

struct AIChatThinkingRow: View {
    let language: AppLanguage
    let accentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(accentColor)
                    .scaleEffect(0.9)
                
                Text("ai_searching_answer".localized(for: language))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                    .stroke(cardBorderColor, lineWidth: 1)
            )
            .transition(.scale(scale: 0.92).combined(with: .opacity))
            
            Spacer(minLength: 40)
        }
    }
}

// MARK: - ЭКРАН ТОЛКОВАНИЯ (Explanation View)
struct ExplanationView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var explanationText = ""
    @State private var selectedDepth = 0 // 0 = суть, 1 = контекст, 2 = жизнь
    
    // Ошибки
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    
    @Environment(\.colorScheme) private var colorScheme
    
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
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.75)
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
            
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(colorScheme == .dark ? 0.05 : 0.03), Color.clear]),
                center: .top,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок
                    VStack(spacing: 6) {
                        Text("explain_title".localized(for: manager.appLanguage))
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(primaryTextColor)
                        Text("explain_subtitle".localized(for: manager.appLanguage))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    
                    // Блок текущего стиха
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 14))
                                .foregroundColor(secondaryAccentColor)
                            Text(manager.currentVerse.reference)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(secondaryAccentColor)
                        }
                        
                        Text(manager.currentVerse.text)
                            .font(.system(size: 15, weight: .medium, design: .serif))
                            .foregroundColor(primaryTextColor.opacity(0.85))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .background(cardBackgroundColor)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(cardBorderColor, lineWidth: 1.2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Выбор глубины погружения
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Depth", selection: $selectedDepth) {
                            Text("explain_depth_short".localized(for: manager.appLanguage)).tag(0)
                            Text("explain_depth_history".localized(for: manager.appLanguage)).tag(1)
                            Text("explain_depth_life".localized(for: manager.appLanguage)).tag(2)
                        }
                        .pickerStyle(.segmented)
                        .tint(accentColor)
                    }
                    .padding(.horizontal, 20)
                    
                    // Кнопка запуска
                    Button {
                        triggerHaptic(.medium)
                        runTheologicalExplanation()
                    } label: {
                        HStack(spacing: 10) {
                            if manager.isGeneratingText {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "book.pages.fill")
                                    .font(.system(size: 15))
                                Text("button_generate_explanation".localized(for: manager.appLanguage))
                            }
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentColor)
                        .cornerRadius(14)
                        .shadow(color: accentColor.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 8, y: 4)
                    }
                    .disabled(manager.isGeneratingText)
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 20)
                    
                    // Результат
                    if manager.isGeneratingText {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(accentColor)
                            Text("explain_loading".localized(for: manager.appLanguage))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 60)
                    } else if !explanationText.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "cross.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(secondaryAccentColor)
                                Text("explain_title".localized(for: manager.appLanguage))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(secondaryAccentColor)
                            }
                            .padding(.bottom, 4)
                            
                            Text(explanationText)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(primaryTextColor)
                                .lineSpacing(7)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardBackgroundColor)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(cardBorderColor, lineWidth: 1.2)
                        )
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        // Приветственное состояние
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(secondaryAccentColor.opacity(0.4))
                            Text("explain_welcome".localized(for: manager.appLanguage))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 60)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onChange(of: manager.currentVerse) { _ in
            // Сбрасываем текст при смене текущего стиха
            explanationText = ""
        }
        .alert("alert_empty_key_title".localized(for: manager.appLanguage), isPresented: $showingNoKeyAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(String(format: "explain_no_key".localized(for: manager.appLanguage)))
        }
        .alert("alert_error_title".localized(for: manager.appLanguage), isPresented: $showingErrorAlert) {
            Button("alert_ok_button".localized(for: manager.appLanguage), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func runTheologicalExplanation() {
        let key: String
        switch manager.activeProvider {
        case .gemini:
            key = manager.geminiApiKey
        case .chatgpt:
            key = manager.openaiApiKey
        case .claude:
            key = manager.anthropicApiKey
        }
        
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            triggerHaptic(.heavy)
            showingNoKeyAlert = true
            return
        }
        
        let depthPrompt: String
        switch selectedDepth {
        case 0:
            depthPrompt = "Focus on the brief spiritual summary and key theological message."
        case 1:
            depthPrompt = "Focus deeply on the historical context, the original Greek/Hebrew translation nuances, and background of the writing."
        default:
            depthPrompt = "Focus on how this verse applies directly to contemporary daily life, and how to practice its message."
        }
        
        let prompt: String
        switch manager.appLanguage {
        case .armenian:
            prompt = "Դու Աստվածաշնչի փորձագետ և աստվածաբան ես: Բացատրիր և մեկնաբանիր հետևյալ աստվածաշնչյան մեջբերումը՝ «\(manager.currentVerse.text)» (\(manager.currentVerse.reference)): Տուր խորը, բայց հասկանալի բացատրություն հայերեն լեզվով: \(depthPrompt) Գրիր գեղեցիկ, կառուցվածքային, բաժանված պարագրաֆների:"
        case .russian:
            prompt = "Ты эксперт по Библии и богословию. Объясни и истолкуй следующий библейский стих: «\(manager.currentVerse.text)» (\(manager.currentVerse.reference)). Дай глубокое, богословское, но понятное толкование на русском языке. \(depthPrompt) Пиши структурировано, разделяя текст на логические абзацы."
        case .english:
            prompt = "You are a Bible expert and theologian. Explain and interpret the following Bible verse: \"\(manager.currentVerse.text)\" (\(manager.currentVerse.reference)). Provide a deep theological but easy-to-understand explanation in English. \(depthPrompt) Write in clean, structured paragraphs."
        }
        
        manager.generateTextFromAI(prompt: prompt) { result in
            switch result {
            case .success(let text):
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.explanationText = text
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    let prefix = "error_generation_prefix".localized(for: manager.appLanguage)
                    self.errorMessage = "\(prefix)\(error.localizedDescription)"
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        manager.triggerHapticImpact(style)
    }
}

// MARK: - Экран Настроек (Settings View)
