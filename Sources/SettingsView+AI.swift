import SwiftUI
import WidgetKit
import LocalAuthentication
import Foundation

extension SettingsView {
    // MARK: - Секция «Искусственный Интеллект»
    // ИИ работает только через сервер приложения (cloudflare/ai-proxy): личные ключи и выбор провайдера убраны.
    // Здесь остаются богословский тон ответов и очистка истории бесед.
    @ViewBuilder
    var aiAssistantSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            aiHeaderView
            aiTheologicalToneSection
            aiClearChatSection
        }
    }
    
    @ViewBuilder
    var aiHeaderView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(selectedTheme.color)
            
            Text("ai_guide_title".localized(for: selectedLanguage))
                .font(PaperFont.font(size: 15, weight: .semibold))
                .foregroundColor(primaryTextColor)
            
            Spacer()
        }
        .padding(.horizontal, 4)
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
                        
                        Text("\(AIChatStore.shared.totalMessageCount) " + "ai_chat_messages_count".localized(for: selectedLanguage))
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
                .disabled(AIChatStore.shared.summaries.isEmpty)
                .opacity(AIChatStore.shared.summaries.isEmpty ? 0.5 : 1.0)
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
}
