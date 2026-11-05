import SwiftUI
import WidgetKit
import LocalAuthentication
import Foundation

extension SettingsView {
    // MARK: - Единая секция «Искусственный Интеллект»
    @ViewBuilder
    var aiAssistantSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            aiHeaderView
            aiProviderPillSelector
            aiCarouselView
            aiPageIndicatorDots
            aiModelsUpdateSection
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
    var aiHeaderView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(providerAccentColor(for: selectedProvider))
            
            Text("ai_provider".localized(for: selectedLanguage))
                .font(PaperFont.font(size: 15, weight: .semibold))
                .foregroundColor(primaryTextColor)
            
            Spacer()
            
            // Бейдж текущей выбранной модели
            HStack(spacing: 4) {
                Circle()
                    .fill(providerAccentColor(for: selectedProvider))
                    .frame(width: 6, height: 6)
                Text(selectedProvider.displayName)
                    .font(PaperFont.font(size: 12, weight: .semibold))
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
    func aiPillBackground(for provider: AIProvider, isSelected: Bool) -> some View {
        let pColor = providerAccentColor(for: provider)
        let sColor = providerSecondaryColor(for: provider)
        let unselectedFill = Paper.fillMuted
        
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
    var aiProviderPillSelector: some View {
        HStack(spacing: 6) {
            ForEach(AIProvider.allCases) { provider in
                let isSelected = selectedProvider == provider
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        selectedProvider = provider
                        manager.setActiveProvider(provider)
                    }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: providerIconName(for: provider))
                            .font(.system(size: 11, weight: .semibold))
                        Text(provider.displayName)
                            .font(PaperFont.font(size: 12, weight: isSelected ? .semibold : .medium))
                    }
                    .foregroundColor(isSelected ? Paper.onAccent : primaryTextColor.opacity(0.7))
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
                .fill(Paper.fillSubtle)
        )
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    var aiCarouselView: some View {
        TabView(selection: $selectedProvider) {
            ForEach(AIProvider.allCases) { provider in
                aiProviderCard(for: provider)
                    .tag(provider)
                    .padding(.horizontal, 4)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 235)
        .onChange(of: selectedProvider) { newProvider in
            manager.setActiveProvider(newProvider)
            Haptics.selection()
        }
    }
    
    @ViewBuilder
    var aiPageIndicatorDots: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                ForEach(AIProvider.allCases) { provider in
                    let isSelected = selectedProvider == provider
                    let pColor = providerAccentColor(for: provider)
                    
                    Capsule()
                        .fill(isSelected ? pColor : Paper.inkSecondary.opacity(0.3))
                        .frame(width: isSelected ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedProvider)
                }
            }
            Spacer()
        }
        .padding(.top, 2)
    }
    
    // MARK: - Обновление списка моделей
    /// Кнопка «Обновить модели»: подтягивает с сервера актуальные модели Google, OpenAI и Anthropic (ключ не нужен),
    /// а у кого есть свой ключ, ещё и проверяет, что выбранная модель с ним отвечает. Без сети ничего не ломается.
    @ViewBuilder
    var aiModelsUpdateSection: some View {
        let tint = providerAccentColor(for: selectedProvider)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ai_models_update_title".localized(for: selectedLanguage))
                        .font(PaperFont.font(size: 13, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    Text(modelsLastUpdatedText)
                        .font(PaperFont.font(size: 11))
                        .foregroundColor(Paper.inkSecondary)
                }

                Spacer()

                Button {
                    startModelsUpdate()
                } label: {
                    HStack(spacing: 4) {
                        if isCheckingModels {
                            ProgressView()
                                .scaleEffect(0.65)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Text(isCheckingModels ? "checking_models".localized(for: selectedLanguage) : "ai_models_update_btn".localized(for: selectedLanguage))
                            .font(PaperFont.font(size: 11, weight: .semibold))
                    }
                    .foregroundColor(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.12))
                    .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isCheckingModels)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Paper.hairline, lineWidth: 1)
            )

            if let toast = activeKeyCheckToast {
                HStack(alignment: .top, spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .padding(.top, 2)
                    Text(toast)
                        .font(PaperFont.font(size: 11, weight: .medium))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(tint)
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.top, 4)
    }

    /// «Обновлено: 5 нояб. 2026 г., 14:30» или «Используется встроенный список», пока с сервера список ещё не получали
    var modelsLastUpdatedText: String {
        guard let date = AIModelCatalogStore.lastUpdated else {
            return "ai_models_never_updated".localized(for: selectedLanguage)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: selectedLanguage.localeCode)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return String(format: "ai_models_last_updated".localized(for: selectedLanguage), formatter.string(from: date))
    }

    func startModelsUpdate() {
        guard !isCheckingModels else { return }
        Haptics.impact(.soft)
        isCheckingModels = true
        Task {
            let report = await AIModelRegistry.shared.updateAllModels()
            await MainActor.run {
                isCheckingModels = false
                let result = modelsUpdateMessage(for: report)
                if result.isGood {
                    Haptics.notify(.success)
                } else {
                    Haptics.notify(.warning)
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    activeKeyCheckToast = result.text
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                    withAnimation { activeKeyCheckToast = nil }
                }
            }
        }
    }

    /// Понятный итог на языке приложения: что с общим списком и что с моделями по ключам человека
    func modelsUpdateMessage(for report: AIModelsUpdateReport) -> (text: String, isGood: Bool) {
        let language = selectedLanguage
        var lines: [String] = []
        var isGood = true

        switch report.catalog.status {
        case .updated:
            lines.append(String(format: "ai_models_updated".localized(for: language), report.catalog.added.count))
        case .upToDate:
            lines.append("ai_models_up_to_date".localized(for: language))
        case .offline:
            lines.append("ai_models_offline".localized(for: language))
            isGood = false
        case .unavailable:
            lines.append("ai_models_unavailable".localized(for: language))
            isGood = false
        }

        for provider in AIProvider.allCases {
            guard let check = report.providers[provider] else { continue }
            switch check {
            case .selected(let model, let changed):
                if changed {
                    let name = AIModelRegistry.prettyName(of: model, provider: provider)
                    lines.append(String(format: "ai_models_switched".localized(for: language), provider.displayName, name))
                }
            case .keyRejected:
                lines.append(String(format: "ai_models_key_rejected".localized(for: language), provider.displayName))
                isGood = false
            case .noneWorked:
                lines.append(String(format: "ai_models_none_worked".localized(for: language), provider.displayName))
                isGood = false
            case .offline:
                // Про отсутствие сети уже сказано выше
                if report.catalog.status != .offline {
                    lines.append("ai_models_offline".localized(for: language))
                    isGood = false
                }
            }
        }
        return (lines.joined(separator: "\n"), isGood)
    }

    @ViewBuilder
    var aiTheologicalToneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "cross.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(selectedTheme.color)
                Text("ai_theological_tone_title".localized(for: selectedLanguage))
                    .font(PaperFont.font(size: 14, weight: .semibold))
                    .foregroundColor(primaryTextColor)
            }
            
            Text("ai_theological_tone_desc".localized(for: selectedLanguage))
                .font(PaperFont.font(size: 12))
                .foregroundColor(Paper.inkSecondary)
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
    func aiTheologicalToneCard(for tone: AITheologicalTone) -> some View {
        let isSelected = selectedTheologicalTone == tone
        let tColor = tone.color
        let strokeColor = isSelected ? tColor : (Paper.fillMuted)
        
        Button {
            Haptics.impact(.light)
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
                            .foregroundColor(isSelected ? Paper.onAccent : tColor)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(tColor)
                    }
                }
                
                Text(tone.localizedTitle(for: selectedLanguage))
                    .font(PaperFont.font(size: 12, weight: isSelected ? .semibold : .semibold))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                
                Text(tone.localizedDesc(for: selectedLanguage))
                    .font(PaperFont.font(size: 10))
                    .foregroundColor(Paper.inkSecondary)
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
    var aiClearChatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("ai_clear_chat_title".localized(for: selectedLanguage))
                            .font(PaperFont.font(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("\(manager.aiChatMessages.count) " + "ai_chat_messages_count".localized(for: selectedLanguage))
                            .font(PaperFont.font(size: 10, weight: .semibold))
                            .foregroundColor(selectedTheme.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(selectedTheme.color.opacity(0.12))
                            .cornerRadius(6)
                    }
                    
                    Text("ai_clear_chat_desc".localized(for: selectedLanguage))
                        .font(PaperFont.font(size: 11))
                        .foregroundColor(Paper.inkSecondary)
                }
                
                Spacer()
                
                Button {
                    Haptics.impact(.soft)
                    isShowingClearAIChatAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                        Text("ai_clear_chat_btn".localized(for: selectedLanguage))
                            .font(PaperFont.font(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Paper.cinnabar)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Paper.cinnabar.opacity(0.1))
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
                    .stroke(Paper.hairline, lineWidth: 1)
            )
            
            if showAIChatClearedToast {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Paper.moss)
                        .font(.system(size: 12))
                    Text("ai_clear_chat_cleared_toast".localized(for: selectedLanguage))
                        .font(PaperFont.font(size: 12, weight: .medium))
                        .foregroundColor(Paper.moss)
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
    func aiProviderCard(for provider: AIProvider) -> some View {
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(pColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(providerTitle(for: provider))
                        .font(PaperFont.font(size: 16, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    Text(providerModelSubtitle(for: provider))
                        .font(PaperFont.font(size: 11, weight: .medium))
                        .foregroundColor(pColor.opacity(0.95))
                }
                
                Spacer()
                
                if isCurrentActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                        Text(activeBadgeText)
                            .font(PaperFont.font(size: 11, weight: .semibold))
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
                .font(PaperFont.font(size: 12))
                .foregroundColor(Paper.inkSecondary)
                .lineLimit(2)
                .lineSpacing(2)
            
            // Поле ввода API ключа
            VisibleApiKeyField(
                placeholder: providerPlaceholder(for: provider),
                text: providerKeyBinding(for: provider),
                accentColor: pColor
            )
            
            // Статус сохранения ключа. Обновление списка моделей — отдельный блок ниже (aiModelsUpdateSection), ключ ему не нужен
            HStack(spacing: 6) {
                if isKeySaved(for: provider) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Paper.moss)
                    Text("api_key_saved".localized(for: selectedLanguage))
                        .font(PaperFont.font(size: 12, weight: .medium))
                        .foregroundColor(Paper.moss)
                } else {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(Paper.inkSecondary.opacity(0.7))
                    Text(apiKeyRequiredText)
                        .font(PaperFont.font(size: 11))
                        .foregroundColor(Paper.inkSecondary.opacity(0.7))
                }

                Spacer()
            }
            .padding(.top, 2)
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
    func providerAccentColor(for provider: AIProvider) -> Color {
        switch provider {
        case .gemini: return Paper.lapis
        case .chatgpt: return Paper.teal
        case .claude: return Paper.ochre
        }
    }
    
    func providerSecondaryColor(for provider: AIProvider) -> Color {
        switch provider {
        case .gemini: return Paper.lapis
        case .chatgpt: return Paper.teal
        case .claude: return Paper.ochre
        }
    }
    
    func providerIconName(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "sparkles"
        case .chatgpt: return "bubble.left.and.text.bubble.right.fill"
        case .claude: return "cpu.fill"
        }
    }
    
    func providerModelSubtitle(for provider: AIProvider) -> String {
        let activeName = AIModelRegistry.shared.displayName(for: provider)
        return "⚡ \(activeName) • " + "auto_upgrade_active".localized(for: selectedLanguage)
    }
    
    func providerTitle(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "gemini_settings_title".localized(for: selectedLanguage)
        case .chatgpt: return "chatgpt_settings_title".localized(for: selectedLanguage)
        case .claude: return "claude_settings_title".localized(for: selectedLanguage)
        }
    }
    
    func providerDescription(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "gemini_settings_description".localized(for: selectedLanguage)
        case .chatgpt: return "chatgpt_settings_description".localized(for: selectedLanguage)
        case .claude: return "claude_settings_description".localized(for: selectedLanguage)
        }
    }
    
    func providerPlaceholder(for provider: AIProvider) -> String {
        switch provider {
        case .gemini: return "placeholder_gemini_key".localized(for: selectedLanguage)
        case .chatgpt: return "placeholder_openai_key".localized(for: selectedLanguage)
        case .claude: return "placeholder_anthropic_key".localized(for: selectedLanguage)
        }
    }
    
    func providerKeyBinding(for provider: AIProvider) -> Binding<String> {
        switch provider {
        case .gemini: return $geminiKeyInput
        case .chatgpt: return $openaiKeyInput
        case .claude: return $anthropicKeyInput
        }
    }
    
    func isKeySaved(for provider: AIProvider) -> Bool {
        switch provider {
        case .gemini: return !manager.geminiApiKey.isEmpty && !geminiKeyInput.isEmpty
        case .chatgpt: return !manager.openaiApiKey.isEmpty && !openaiKeyInput.isEmpty
        case .claude: return !manager.anthropicApiKey.isEmpty && !anthropicKeyInput.isEmpty
        }
    }
    
    var activeBadgeText: String {
        switch selectedLanguage {
        case .armenian: return "Ակտիվ"
        case .russian: return "Активная"
        case .english: return "Active"
        }
    }
    
    var apiKeyRequiredText: String {
        switch selectedLanguage {
        case .armenian: return "Մուտքագրեք անձնական API բանալին"
        case .russian: return "Введите персональный API-ключ"
        case .english: return "Enter personal API key"
        }
    }
    
}
