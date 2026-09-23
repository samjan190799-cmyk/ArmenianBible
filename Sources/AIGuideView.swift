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
    
}
