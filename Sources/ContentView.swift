import SwiftUI

struct ContentView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var animateVerse = false
    @State private var isShowingSettings = false
    
    // Переменные для обработки ошибок ИИ
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingNoKeyAlert = false
    
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
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 15))
                                Text("Պատահական տող") // Случайный стих
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
                        
                        // Кнопка: Генерация через ИИ (Gemini)
                        Button {
                            let key = manager.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                            if key.isEmpty {
                                triggerHaptic(.warning)
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
                                    Text("ԱԻ Գեներացում") // Генерация ИИ
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
                
                // MARK: - Блок инструкций для экрана блокировки
                VStack(alignment: .leading, spacing: 14) {
                    Text("Ինչպե՞ս ավելացնել Կողպման էկրանին.")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 2)
                    
                    InstructionRow(number: "1", text: "Հպեք և պահեք Կողպման էկրանը:")
                    InstructionRow(number: "2", text: "Ընտրեք «Կարգավորել» (Customize), ապա «Կողպման էկրան»:")
                    InstructionRow(number: "3", text: "Հպեք «Ավելացնել վիդջեթներ» բաժնին:")
                    InstructionRow(number: "4", text: "Գտեք «ArmenianBible» հավելվածը և ավելացրեք վիդջեթը:")
                }
                .padding(20)
                .background(Color.white.opacity(0.02))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateVerse = true
            }
        }
        .sheet(isPresented: &isShowingSettings) {
            SettingsView(isPresented: &isShowingSettings)
        }
        .alert("Մուտքագրեք API բանալին", isPresented: &showingNoKeyAlert) {
            Button("Լավ", role: .cancel) {
                isShowingSettings = true
            }
        } message: {
            Text("ԱԻ գեներացման համար անհրաժեշտ է կարգավորումներում ավելացնել Gemini API բանալին (API Key):")
        }
        .alert("Սխալ", isPresented: &showingErrorAlert) {
            Button("Լավ", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
                errorMessage = "Գեներացման սխալ. խնդրում ենք ստուգել ձեր API Key-ը և ինտերնետ կապը:"
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
    @State private var keyInput = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "090A0F")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        // MARK: - Информационный блок
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gemini AI Կարգավորումներ")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Մուտքագրեք ձեր Gemini API Key-ը, որպեսզի հավելվածը կարողանա ինքնուրույն գեներացնել նոր տողեր Աստվածաշնչից:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 10)
                        
                        // MARK: - Поле ввода API Key
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("AI API Key (AIzaSy...)", text: $keyInput)
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
                                Text("✅ API բանալին պահպանված է:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 4)
                            }
                        }
                        
                        // MARK: - Кнопка сохранения
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                            
                            manager.geminiApiKey = keyInput
                            isPresented = false
                        } label: {
                            Text("Պահպանել") // Сохранить
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
                            Text("Հավելվածի մասին")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("Տարբերակ")
                                Spacer()
                                Text("1.0.1")
                                    .foregroundColor(.secondary)
                            }
                            .font(.system(size: 14))
                            
                            HStack {
                                Text("Մշակող")
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
            .navigationTitle("Կարգավորումներ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Փակել") { // Закрыть
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                keyInput = manager.geminiApiKey
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
