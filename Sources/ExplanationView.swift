import SwiftUI
import WidgetKit
import LocalAuthentication

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
