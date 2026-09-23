import SwiftUI
import WidgetKit
import LocalAuthentication

extension AIGuideView {
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
