import SwiftUI
import WidgetKit
import LocalAuthentication

extension SettingsView {
    // MARK: - Единая секция «Искусственный Интеллект»
    @ViewBuilder
    private var aiAssistantSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            aiHeaderView
            aiProviderPillSelector
            aiCarouselView
            aiPageIndicatorDots
            aiTheologicalToneSection
            aiClearChatSection
        }
        .onChange(of: geminiKeyInput) { val in
            manager.geminiApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .onChange(of: openaiKeyInput) { val in
            manager.openaiApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .onChange(of: anthropicKeyInput) { val in
            manager.anthropicApiKey = val.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    @ViewBuilder
    private var aiHeaderView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(providerAccentColor(for: selectedProvider))
            
            Text("ai_provider".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Spacer()
            
            // Бейдж текущей выбранной модели
            HStack(spacing: 4) {
                Circle()
                    .fill(providerAccentColor(for: selectedProvider))
                    .frame(width: 6, height: 6)
                Text(selectedProvider.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(primaryTextColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(providerAccentColor(for: selectedProvider).opacity(0.12))
            .cornerRadius(10)
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private func aiPillBackground(for provider: AIProvider, isSelected: Bool) -> some View {
        let pColor = providerAccentColor(for: provider)
        let sColor = providerSecondaryColor(for: provider)
        let unselectedFill = colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)
        
        if isSelected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [pColor, sColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: pColor.opacity(0.35), radius: 6, y: 2)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(unselectedFill)
        }
    }
    
    @ViewBuilder
    private var aiProviderPillSelector: some View {
        HStack(spacing: 6) {
            ForEach(AIProvider.allCases) { provider in
                let isSelected = selectedProvider == provider
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        selectedProvider = provider
                        manager.setActiveProvider(provider)
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: providerIconName(for: provider))
                            .font(.system(size: 11, weight: .bold))
                        Text(provider.displayName)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundColor(isSelected ? .white : primaryTextColor.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(aiPillBackground(for: provider, isSelected: isSelected))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.03))
        )
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var aiCarouselView: some View {
        TabView(selection: $selectedProvider) {
            ForEach(AIProvider.allCases) { provider in
                aiProviderCard(for: provider)
                    .tag(provider)
                    .padding(.horizontal, 4)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 255)
        .onChange(of: selectedProvider) { newProvider in
            manager.setActiveProvider(newProvider)
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
    
    @ViewBuilder
    private var aiPageIndicatorDots: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                ForEach(AIProvider.allCases) { provider in
                    let isSelected = selectedProvider == provider
                    let pColor = providerAccentColor(for: provider)
                    
                    Capsule()
                        .fill(isSelected ? pColor : Color.secondary.opacity(0.3))
                        .frame(width: isSelected ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedProvider)
                }
            }
            Spacer()
        }
        .padding(.top, 2)
    }
    
    @ViewBuilder
    private var aiTheologicalToneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "cross.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                Text("ai_theological_tone_title".localized(for: selectedLanguage))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryTextColor)
            }
            
            Text("ai_theological_tone_desc".localized(for: selectedLanguage))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(AITheologicalTone.allCases) { tone in
                    aiTheologicalToneCard(for: tone)
                }
            }
        }
        .padding(.top, 6)
    }
    
    @ViewBuilder
    private func aiTheologicalToneCard(for tone: AITheologicalTone) -> some View {
        let isSelected = selectedTheologicalTone == tone
        let tColor = Color(hex: tone.colorHex)
        let strokeColor = isSelected ? tColor : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
        
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTheologicalTone = tone
                manager.setAITheologicalTone(tone)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? tColor : tColor.opacity(0.12))
                            .frame(width: 26, height: 26)
                        Image(systemName: tone.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isSelected ? .white : tColor)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(tColor)
                    }
                }
                
                Text(tone.localizedTitle(for: selectedLanguage))
                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                
                Text(tone.localizedDesc(for: selectedLanguage))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(strokeColor, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private var aiClearChatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("ai_clear_chat_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("\(manager.aiChatMessages.count) " + "ai_chat_messages_count".localized(for: selectedLanguage))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: selectedTheme.colorHex).opacity(0.12))
                            .cornerRadius(6)
                    }
                    
                    Text("ai_clear_chat_desc".localized(for: selectedLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.prepare()
                    generator.impactOccurred()
                    isShowingClearAIChatAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                        Text("ai_clear_chat_btn".localized(for: selectedLanguage))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "EF4444"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "EF4444").opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(manager.aiChatMessages.isEmpty)
                .opacity(manager.aiChatMessages.isEmpty ? 0.5 : 1.0)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
            )
            
            if showAIChatClearedToast {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "10B981"))
                        .font(.system(size: 12))
                    Text("ai_clear_chat_cleared_toast".localized(for: selectedLanguage))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "10B981"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Карточка отдельного ИИ-провайдера
    @ViewBuilder
    private func aiProviderCard(for provider: AIProvider) -> some View {
        let pColor = providerAccentColor(for: provider)
        let isCurrentActive = manager.activeProvider == provider
        
        VStack(alignment: .leading, spacing: 12) {
            // Верхняя плашка с иконкой, заголовком и статусом
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [pColor.opacity(0.25), providerSecondaryColor(for: provider).opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: providerIconName(for: provider))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(pColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(providerTitle(for: provider))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    Text(providerModelSubtitle(for: provider))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(pColor.opacity(0.95))
                }
                
                Spacer()
                
                if isCurrentActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                        Text(activeBadgeText)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [pColor, providerSecondaryColor(for: provider)], startPoint: .leading, endPoint: .trailing))
                    )
                }
            }
            
            // Описание назначения модели
            Text(providerDescription(for: provider))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .lineSpacing(2)
            
            // Поле ввода API ключа
            VisibleApiKeyField(
                placeholder: providerPlaceholder(for: provider),
                text: providerKeyBinding(for: provider),
                accentColor: pColor
            )
            
            // Статус сохранения ключа и кнопка автопроверки моделей
            HStack(spacing: 6) {
                if isKeySaved(for: provider) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                    Text("api_key_saved".localized(for: selectedLanguage))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                    Text(apiKeyRequiredText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
                
                // Кнопка автообновления моделей (доступна для всех: Gemini, ChatGPT, Claude)
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if !isKeySaved(for: provider) {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            activeKeyCheckToast = "enter_api_key_to_check".localized(for: selectedLanguage)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { activeKeyCheckToast = nil }
                        }
                        return
                    }
                    
                    isCheckingModels = true
                    Task {
                        let res = await AIModelRegistry.shared.updateModels(for: provider)
                        await MainActor.run {
                            isCheckingModels = false
                            if res.success {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    activeKeyCheckToast = res.message.localized(for: selectedLanguage)
                                }
                            } else {
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    activeKeyCheckToast = res.message.localized(for: selectedLanguage)
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation { activeKeyCheckToast = nil }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isCheckingModels {
                            ProgressView()
                                .scaleEffect(0.65)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10, weight: .bold))
                        }
                        Text(isCheckingModels ? "checking_models".localized(for: selectedLanguage) : "check_models".localized(for: selectedLanguage))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(pColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(pColor.opacity(0.12))
                    .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isCheckingModels)
            }
            .padding(.top, 2)
            
            if let toast = activeKeyCheckToast {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text(toast)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(pColor)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [pColor.opacity(0.6), pColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: pColor.opacity(0.08), radius: 10, y: 4)
    }
    
    // MARK: - Вспомогательные методы для ИИ-карусели
    private func providerAccentColor(for provider: AIProvider) -> Color {
        switch provider {
        case .gemini: return Color(hex: "4E80EE")
        case .chatgpt: return Color(hex: "10A37F")
        case .claude: return Color(hex: "E07A5F")
        }
    }
    
    private func providerSecondaryColor(for provider: AIProvider) -> Color {
        switch provider {
        case .gemini: return Color(hex: "8E55EA")
        case .chatgpt: return Color(hex: "059669")
        case .claude: return Color(hex: "D97706")
        }
    }
    
    private func providerIconName(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "sparkles"
        case .chatgpt: return "bubble.left.and.text.bubble.right.fill"
        case .claude: return "cpu.fill"
        }
    }
    
    private func providerModelSubtitle(for provider: AIProvider) -> String {
        let activeName = AIModelRegistry.shared.displayName(for: provider)
        return "⚡ \(activeName) • " + "auto_upgrade_active".localized(for: selectedLanguage)
    }
    
    private func providerTitle(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "gemini_settings_title".localized(for: selectedLanguage)
        case .chatgpt: return "chatgpt_settings_title".localized(for: selectedLanguage)
        case .claude: return "claude_settings_title".localized(for: selectedLanguage)
        }
    }
    
    private func providerDescription(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "gemini_settings_description".localized(for: selectedLanguage)
        case .chatgpt: return "chatgpt_settings_description".localized(for: selectedLanguage)
        case .claude: return "claude_settings_description".localized(for: selectedLanguage)
        }
    }
    
    private func providerPlaceholder(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "placeholder_gemini_key".localized(for: selectedLanguage)
        case .chatgpt: return "placeholder_openai_key".localized(for: selectedLanguage)
        case .claude: return "placeholder_anthropic_key".localized(for: selectedLanguage)
        }
    }
    
    private func providerKeyBinding(for provider: AIProvider) -> Binding<String> {
        switch provider {
        case .gemini: return $geminiKeyInput
        case .chatgpt: return $openaiKeyInput
        case .claude: return $anthropicKeyInput
        }
    }
    
    private func isKeySaved(for provider: AIProvider) -> Bool {
        switch provider {
        case .gemini: return !manager.geminiApiKey.isEmpty && !geminiKeyInput.isEmpty
        case .chatgpt: return !manager.openaiApiKey.isEmpty && !openaiKeyInput.isEmpty
        case .claude: return !manager.anthropicApiKey.isEmpty && !anthropicKeyInput.isEmpty
        }
    }
    
    private var activeBadgeText: String {
        switch selectedLanguage {
        case .armenian: return "Ակտիվ"
        case .russian: return "Активная"
        case .english: return "Active"
        }
    }
    
    private var apiKeyRequiredText: String {
        switch selectedLanguage {
        case .armenian: return "Մուտքագրեք անձնական API բանալին"
        case .russian: return "Введите персональный API-ключ"
        case .english: return "Enter personal API key"
        }
    }
    
}
