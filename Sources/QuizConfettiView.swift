import SwiftUI

// MARK: - Праздничный эффект частиц / Конфетти
struct QuizConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(particleColor(for: i))
                    .frame(width: CGFloat((i % 4 + 2) * 3), height: CGFloat((i % 4 + 2) * 3))
                    .offset(
                        x: animate ? CGFloat(((i * 37) % 300) - 150) : 0,
                        y: animate ? CGFloat(((i * 53) % 400) - 250) : 0
                    )
                    .scaleEffect(animate ? 1.0 : 0.2)
                    .opacity(animate ? 0.85 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animate = true
            }
        }
    }
    
    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue, .green, .mint]
        return colors[index % colors.count]
    }
}

