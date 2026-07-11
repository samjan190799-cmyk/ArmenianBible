import SwiftUI

struct ContentView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var animateVerse = false
    @State private var isShowingSettings = false
    
    // Переменные для обработки ошибок ИИ
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // MARK: - Премиальный глубокий темный фон
            Color(hex: "090A0F")
                .ignoresSafeArea()
            
            // Тонкая сетка для техно-индустриального стиля
            StaticDotGridView(dotColor: Color.white.opacity(0.025))
                .ignoresSafeArea()
            
            // Легкое фоновое неоновое свечение позади текста
            Circle()
                .fill(Color(hex: "6366F1").opacity(0.08))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(y: -70)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - Top Header & Settings Button
                    HStack {
                        Spacer()
                        
                        Button {
                            triggerHaptic(.light)
                            isShowingSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                        .frame(height: 10)
                    
                    // MARK: - Контейнер со стихом
                    VStack(spacing: 20) {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "A5B4FC").opacity(0.6))
                        
                        Text(manager.currentVerse.text)
                            .font(.system(size: 21, weight: .medium, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 10)
                            .fixedSize(horizontal: false, vertical: true) // Предотвращает обрезку троеточием в приложении
                            .opacity(animateVerse ? 1 : 0)
                            .offset(y: animateVerse ? 0 : 15)
                        
                        Text(manager.currentVerse.reference)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "818CF8"))
                            .padding(.top, 4)
                            .opacity(animateVerse ? 0.8 : 0)
                            .offset(y: animateVerse ? 0 : 10)
                    }
                    .padding(26)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                            .background(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        Color.white.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        triggerHaptic(.medium)
                        
                        withAnimation(.easeOut(duration: 0.18)) {
                            animateVerse = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            manager.selectRandomVerse()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                animateVerse = true
                            }
                        }
                    }
                    
                    
                    // MARK: - Блок кнопок генерации
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            // Кнопка: Случайный оффлайн-стих
                            Button {
                                triggerHaptic(.medium)
                                
                                withAnimation(.easeOut(duration: 0.18)) {
                                    animateVerse = false
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                    manager.selectRandomVerse()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        animateVerse = true
                                    }
                                                      Text("button_random_verse") // Случайный стих (локализуется автоматически)
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Кнопка: Генерация через ИИ
                            Button {
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
                                } else {
                                    triggerHaptic(.medium)
                                    runAIGeneration()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if manager.isGeneratingAI {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 15))
                                        Text("button_ai_generation") // Генерация ИИ
                                    }
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "4F46E5"), Color(hex: "6366F1")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: Color(hex: "4F46E5").opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(manager.isGeneratingAI)
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 10)
                    
                    // MARK: - Блок инструкций для экрана блокировки
                    VStack(alignment: .leading, spacing: 14) {
                        Text("instruction_title")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 2)
                        
                        InstructionRow(number: "1", text: NSLocalizedString("instruction_step_1", comment: ""))
                        InstructionRow(number: "2", text: NSLocalizedString("instruction_step_2", comment: ""))
                        InstructionRow(number: "3", text: NSLocalizedString("instruction_step_3", comment: ""))
                        InstructionRow(number: "4", text: NSLocalizedString("instruction_step_4", comment: ""))
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateVerse = true
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(isPresented: $isShowingSettings)
        }
        .alert(NSLocalizedString("alert_empty_key_title", comment: ""), isPresented: $showingNoKeyAlert) {
            Button(NSLocalizedString("alert_ok_button", comment: ""), role: .cancel) {
                isShowingSettings = true
            }
        } message: {
            Text(String(format: NSLocalizedString("alert_empty_key_message", comment: ""), manager.activeProvider.displayName))
        }
        .alert(NSLocalizedString("alert_error_title", comment: ""), isPresented: $showingErrorAlert) {
            Button(NSLocalizedString("alert_ok_button", comment: ""), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onOpenURL { url in
            if url.scheme == "armenianbible" && url.host == "next-verse" {
                triggerHaptic(.medium)
                withAnimation(.easeOut(duration: 0.18)) {
                    animateVerse = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    manager.selectRandomVerse()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        animateVerse = true
                    }
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && manager.updateInterval == .onScreenActivation {
                triggerHaptic(.light)
                withAnimation(.easeOut(duration: 0.18)) {
                    animateVerse = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    manager.selectRandomVerse()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        animateVerse = true
                    }
                }
            }
        }
    }
    
    // MARK: - Логика отправки запроса к ИИ
    private func runAIGeneration() {
        withAnimation(.easeOut(duration: 0.18)) {
            animateVerse = false
        }
        
        manager.generateVerseWithAI { result in
            switch result {
            case .success(_):
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animateVerse = true
                }
            case .failure(let error):
                errorMessage = "Գեներացման սխալ. \(error.localizedDescription)"
                showingErrorAlert = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animateVerse = true
                }
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Экран Настроек (Settings View)
struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var manager = BibleManager.shared
    
    @State private var selectedProvider: AIProvider = .gemini
    @State private var selectedLanguage: AILanguage = .armenian
    @State private var geminiKeyInput = ""
    @State private var openaiKeyInput = ""
    @State private var anthropicKeyInput = ""
    
    @State private var selectedInterval: UpdateInterval = .everyHour
    @State private var selectedCategory: TextCategory = .both
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "090A0F")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        // MARK: - Выбор ИИ Провайдера
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ai_provider")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("ai_provider_description")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                            
                            Picker("ai_provider", selection: $selectedProvider) {
                                ForEach(AIProvider.allCases) { provider in
                                    Text(provider.displayName).tag(provider)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(.white)
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 10)
                        
                        // MARK: - Выбор языка генерации ИИ
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ai_language")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("ai_language_description")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                            
                            Picker("ai_language", selection: $selectedLanguage) {
                                ForEach(AILanguage.allCases) { language in
                                    Text(language.displayName).tag(language)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(.white)
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Поле ввода API Key в зависимости от провайдера
                        VStack(alignment: .leading, spacing: 8) {
                            switch selectedProvider {
                            case .gemini:
                                Text("gemini_settings_title")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("gemini_settings_description")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                                    .padding(.bottom, 6)
                                
                                SecureField("Gemini API Key (AIzaSy...)", text: $geminiKeyInput)
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                
                                if !manager.geminiApiKey.isEmpty {
                                    Text("api_key_saved")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 4)
                                }
                                
                            case .chatgpt:
                                Text("chatgpt_settings_title")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("chatgpt_settings_description")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                                    .padding(.bottom, 6)
                                
                                SecureField("OpenAI API Key (sk-...)", text: $openaiKeyInput)
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                
                                if !manager.openaiApiKey.isEmpty {
                                    Text("api_key_saved")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 4)
                                }
                                
                            case .claude:
                                Text("claude_settings_title")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("claude_settings_description")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                                    .padding(.bottom, 6)
                                
                                SecureField("Anthropic API Key (sk-ant-...)", text: $anthropicKeyInput)
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                
                                if !manager.anthropicApiKey.isEmpty {
                                    Text("api_key_saved")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Частота смены стихов
                        VStack(alignment: .leading, spacing: 10) {
                            Text("update_interval_title")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("update_interval_description")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                            
                            Picker("update_interval_title", selection: $selectedInterval) {
                                ForEach(UpdateInterval.allCases) { interval in
                                    Text(interval.localizedTitle).tag(interval)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Выбор типа контента (Стихи / Молитвы / Все)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("content_type_title")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("content_type_description")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                            
                            Picker("content_type_title", selection: $selectedCategory) {
                                ForEach(TextCategory.allCases) { category in
                                    Text(category.localizedTitle).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 4)
                        
                        // MARK: - Кнопка сохранения
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                            
                            manager.setActiveProvider(selectedProvider)
                            manager.setAILanguage(selectedLanguage)
                            manager.geminiApiKey = geminiKeyInput
                            manager.openaiApiKey = openaiKeyInput
                            manager.anthropicApiKey = anthropicKeyInput
                            manager.setUpdateInterval(selectedInterval)
                            manager.setSelectedCategory(selectedCategory)
                            isPresented = false
                        } label: {
                            Text("save_button")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "4F46E5"))
                                .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Divider()
                            .opacity(0.1)
                            .padding(.vertical, 8)
                        
                        // MARK: - О приложении
                        VStack(alignment: .leading, spacing: 12) {
                            Text("about_app_title")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("about_app_version")
                                Spacer()
                                Text("1.0.1")
                                    .foregroundColor(.secondary)
                            }
                            .font(.system(size: 14))
                            
                            HStack {
                                Text("about_app_developer")
                                Spacer()
                                Text("Samvel")
                                    .foregroundColor(.secondary)
                            }
                            .font(.system(size: 14))
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("settings_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close_button") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                selectedProvider = manager.activeProvider
                selectedLanguage = manager.aiLanguage
                geminiKeyInput = manager.geminiApiKey
                openaiKeyInput = manager.openaiApiKey
                anthropicKeyInput = manager.anthropicApiKey
                selectedInterval = manager.updateInterval
                selectedCategory = manager.selectedCategory
            }
        }
    }
}

// MARK: - Вспомогательное представление: Строка инструкции
struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "818CF8"))
                .frame(width: 20, height: 20)
                .background(Color(hex: "818CF8").opacity(0.1))
                .clipShape(Circle())
                .padding(.top, 1)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Вспомогательное представление: Сетка точек (Dot Grid)
struct StaticDotGridView: View {
    let dotColor: Color
    
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let dotSize: CGFloat = 1.0
            let spacing: CGFloat = 22.0
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    path.addRect(CGRect(x: x, y: y, width: dotSize, height: dotSize))
                }
            }
            context.fill(path, with: .color(dotColor))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Эластичный стиль кнопки
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Инициализация цвета по Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
