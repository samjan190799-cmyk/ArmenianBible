import SwiftUI
import WidgetKit
import LocalAuthentication

// MARK: - ЭКРАН ИИ РУКОВОДСТВА (AI Guide View - Библейский Ответчик)
struct AIGuideView: View {
    @ObservedObject var manager = BibleManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    /// История бесед: каждая беседа хранится отдельно, открытая показывается на экране
    @ObservedObject private var store = AIChatStore.shared
    @State private var questionText = ""
    @State private var isShowingPaywall = false
    @State private var isHistoryOpen = false

    // Ошибки и подтверждения
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false

    /// Ждём ответ в открытой беседе (в других беседах ответ может ждать независимо)
    private var isAskingAI: Bool {
        store.isPending(store.currentID)
    }

    // Экспорт и Toast
    @State private var shareItem: ShareItem? = nil
    @State private var showCopiedToast = false
    @State private var toastMessage = ""
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        manager.accentTheme.color
    }
    private var secondaryAccentColor: Color {
        Paper.inkSecondary
    }
    private var backgroundColor: Color {
        Paper.page
    }
    private var cardBackgroundColor: Color {
        Paper.sheet
    }
    private var cardBorderColor: LinearGradient {
        LinearGradient(colors: [Paper.hairline, Paper.hairline], startPoint: .top, endPoint: .bottom)
    }
    private var primaryTextColor: Color {
        Paper.ink
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
            PaperBackground()
            
            VStack(spacing: 0) {
                // 1. Верхняя панель чата (Header)
                chatHeaderView
                
                Divider()
                    .opacity(0.2)
                
                // 2. Область сообщений со скроллом к низу
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if store.messages.isEmpty {
                                chatWelcomeView
                            } else {
                                ForEach(store.messages) { msg in
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
                    .onChange(of: store.messages.count) { _ in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            proxy.scrollTo("bottomChatAnchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: store.currentID) { _ in
                        // Другая беседа: сразу к последнему сообщению, без анимации
                        DispatchQueue.main.async {
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
            // Свайп от левого края открывает историю чатов
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        if value.startLocation.x < 28 && value.translation.width > 70 && abs(value.translation.height) < 60 {
                            openHistory()
                        }
                    }
            )

            historyDrawer

            // Всплывающий Toast о копировании
            if showCopiedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Paper.moss)
                        Text(toastMessage)
                            .font(PaperFont.font(size: 14, weight: .medium))
                            .foregroundColor(Paper.page)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Paper.ink.opacity(0.92))
                    .cornerRadius(25)
                    .shadow(radius: 10)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCopiedToast)
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(source: "ai")
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
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
    }

}

extension AIGuideView {
    // MARK: - Верхняя панель (Header)
    private var chatHeaderView: some View {
        HStack(alignment: .center, spacing: 10) {
            // История чатов слева
            Button {
                triggerHaptic(.light)
                openHistory()
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Paper.inkSecondary)
                    .padding(9)
                    .background(cardBackgroundColor)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Paper.ink.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(Text("ai_history_title".localized(for: manager.appLanguage)))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("ai_guide_title".localized(for: manager.appLanguage))
                        .font(PaperFont.font(size: 20, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                
                // Статус подписки и кнопка пополнения копилки вопросов
                HStack(spacing: 6) {
                    Image(systemName: subscriptionManager.isPremium ? "crown.fill" : (subscriptionManager.accumulatedBonusAiQuestions > 0 ? "archivebox.fill" : "sparkles"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Paper.gold)
                    
                    Text(headerQuestionsStatusText)
                        .font(PaperFont.font(size: 11, weight: .semibold))
                        .foregroundColor(subscriptionManager.isPremium ? Paper.gold : Paper.inkSecondary)
                    
                    if !subscriptionManager.isPremium {
                        Button {
                            triggerHaptic(.light)
                            isShowingPaywall = true
                        } label: {
                            Text("PRO")
                                .font(PaperFont.font(size: 9, weight: .semibold))
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(accentColor.opacity(0.12))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()
            
            // Новый чат: пустая беседа сохраняется только после первого вопроса
            Button {
                triggerHaptic(.light)
                startNewChat()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(store.messages.isEmpty ? Paper.inkSecondary.opacity(0.4) : Paper.inkSecondary)
                    .padding(9)
                    .background(cardBackgroundColor)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Paper.ink.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(store.messages.isEmpty)
            .accessibilityLabel(Text("ai_new_chat".localized(for: manager.appLanguage)))
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
                    .font(PaperFont.font(size: 22, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                Text("ai_guide_subtitle".localized(for: manager.appLanguage))
                    .font(PaperFont.font(size: 13))
                    .foregroundColor(Paper.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineSpacing(4)
            }
            
            // Подсказки быстрых вопросов
            VStack(alignment: .leading, spacing: 10) {
                Text("suggested_questions_title".localized(for: manager.appLanguage))
                    .font(PaperFont.font(size: 13, weight: .semibold))
                    .foregroundColor(Paper.inkSecondary)
                    .padding(.horizontal, 4)
                
                ForEach(suggestedQuestions) { sq in
                    Button {
                        triggerHaptic(.soft)
                        let q = sq.key.localized(for: manager.appLanguage)
                        submitQuestion(q)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: sq.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondaryAccentColor)
                                .frame(width: 22)
                            
                            Text(sq.key.localized(for: manager.appLanguage))
                                .font(PaperFont.font(size: 14, weight: .medium))
                                .foregroundColor(primaryTextColor)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Paper.inkSecondary.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .paperField(cornerRadius: 14)
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Paper.gold)
                    
                    Text(manager.appLanguage == .armenian ? "Հարցերի լիմիտը սպառվել է" : (manager.appLanguage == .russian ? "Лимит вопросов исчерпан" : "Question limit reached"))
                        .font(PaperFont.font(size: 12, weight: .medium))
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    Button {
                        triggerHaptic(.soft)
                        isShowingPaywall = true
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 9, weight: .semibold))
                            Text(manager.appLanguage == .armenian ? "Անսահմանափակ" : (manager.appLanguage == .russian ? "Безлимит" : "Unlimited"))
                                .font(PaperFont.font(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Paper.onAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Paper.gold)
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
                    .font(PaperFont.font(size: 15))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(cardBackgroundColor)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(questionText.isEmpty ? Paper.ink.opacity(0.08) : accentColor.opacity(0.5), lineWidth: 1.2)
                    )
                    .keyboardDismissToolbar()
                
                Button {
                    triggerHaptic(.soft)
                    let textToSend = questionText
                    questionText = ""
                    hideKeyboard()
                    submitQuestion(textToSend)
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSubmit ? Paper.accentFill : Paper.fillMuted)
                            .frame(width: 42, height: 42)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Paper.onAccent)
                            .offset(x: -1, y: 1)
                    }
                }
                .disabled(!canSubmit)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Paper.page)
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
            triggerHaptic(.medium)
            isShowingPaywall = true
            return
        }
        
        let key = manager.effectiveAPIKey(for: manager.activeProvider)

        if key.isEmpty {
            // Ключ пуст только пока не задан адрес сервера ИИ: тогда остаётся ввести свой ключ
            triggerHaptic(.medium)
            showingNoKeyAlert = true
            return
        }
        
        Funnel.track("feature_used", ["feature": "ai_question"])
        
        // Прошлые реплики этой беседы уходят ИИ как контекст, чтобы он понимал уточняющие вопросы
        let history = store.messages

        // Добавляем вопрос в открытую беседу (новый чат создаётся здесь, с названием по вопросу)
        let userMessage = AIChatMessage(isUser: true, text: trimmed)
        var chatID = UUID()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            chatID = store.addMessage(userMessage)
            store.setPending(true, for: chatID)
        }
        let targetChatID = chatID

        manager.askBibleAI(question: trimmed, history: history) { result in
            DispatchQueue.main.async {
                self.store.setPending(false, for: targetChatID)
                switch result {
                case .success(let answer):
                    self.subscriptionManager.recordAiQuestionUsed()
                    let aiMessage = AIChatMessage(
                        isUser: false,
                        text: answer.answerText,
                        verse: answer.verse
                    )
                    // Ответ возвращается в ту беседу, где задан вопрос, даже если человек уже открыл другую
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                        _ = self.store.addMessage(aiMessage, to: targetChatID)
                    }
                case .failure(let error):
                    let prefix = "error_generation_prefix".localized(for: manager.appLanguage)
                    self.errorMessage = "\(prefix)\(error.localizedDescription)"
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - История чатов (боковая панель)
    private var historyDrawer: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.86, 340)
            ZStack(alignment: .leading) {
                if isHistoryOpen {
                    // Затемнение: нажатие или свайп влево закрывают панель
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { closeHistory() }
                        .gesture(
                            DragGesture(minimumDistance: 24)
                                .onEnded { value in
                                    if value.translation.width < -50 && abs(value.translation.height) < 80 {
                                        closeHistory()
                                    }
                                }
                        )
                        .transition(.opacity)

                    AIChatHistoryPanel(
                        store: store,
                        language: manager.appLanguage,
                        accentColor: accentColor,
                        onNewChat: {
                            startNewChat()
                            closeHistory()
                        },
                        onSelect: { id in
                            Funnel.track("feature_used", ["feature": "ai_chat_switch"])
                            store.select(id)
                            closeHistory()
                        },
                        onClose: { closeHistory() }
                    )
                    .frame(width: width)
                    .frame(maxHeight: .infinity)
                    .shadow(color: Color.black.opacity(0.25), radius: 14, x: 4, y: 0)
                    .transition(.move(edge: .leading))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .allowsHitTesting(isHistoryOpen)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isHistoryOpen)
    }

    private func openHistory() {
        guard !isHistoryOpen else { return }
        hideKeyboard()
        Funnel.track("feature_used", ["feature": "ai_history_open"])
        isHistoryOpen = true
    }

    private func closeHistory() {
        isHistoryOpen = false
    }

    private func startNewChat() {
        guard !store.messages.isEmpty else { return }
        Funnel.track("feature_used", ["feature": "ai_new_chat"])
        store.startNewChat()
        questionText = ""
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
        triggerHaptic(.soft)
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
}
