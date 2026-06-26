import SwiftUI

struct ContentView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var animateVerse = false
    
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
                .offset(y: -50)
            
            VStack(spacing: 24) {
                Spacer()
                
                // MARK: - Контейнер со стихом
                VStack(spacing: 20) {
                    // Символ креста для уважительного традиционного акцента
                    Image(systemName: "laurel.leading")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "A5B4FC").opacity(0.6))
                    
                    Text(manager.currentVerse.text)
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 10)
                        .opacity(animateVerse ? 1 : 0)
                        .offset(y: animateVerse ? 0 : 15)
                    
                    Text(manager.currentVerse.reference)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "818CF8"))
                        .padding(.top, 4)
                        .opacity(animateVerse ? 0.8 : 0)
                        .offset(y: animateVerse ? 0 : 10)
                }
                .padding(28)
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
                
                // MARK: - Кнопка случайного стиха
                Button {
                    // Тактильный отклик
                    triggerHaptic()
                    
                    // Плавная анимация смены текста
                    withAnimation(.easeOut(duration: 0.2)) {
                        animateVerse = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        manager.selectRandomVerse()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            animateVerse = true
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("Պատահական տող") // Случайная строка
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "4F46E5"), Color(hex: "6366F1")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "4F46E5").opacity(0.35), radius: 10, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
                
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
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateVerse = true
            }
        }
    }
    
    // MARK: - Тактильная отдача
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
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
