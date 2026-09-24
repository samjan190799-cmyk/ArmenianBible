import SwiftUI

// MARK: - 1. Божественный «дышащий» ореол (Divine Breathing Glow)
/// Непрерывно плавно пульсирующее свечение в тон акцентной темы приложения.
public struct DivineBreathingGlow: View {
    let color: Color
    @State private var isExpanded: Bool = false
    
    public init(color: Color) {
        self.color = color
    }
    
    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: isExpanded ? 380 : 320, height: isExpanded ? 380 : 320)
            .opacity(isExpanded ? 0.65 : 0.38)
            .blur(radius: isExpanded ? 95 : 75)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4.2)
                    .repeatForever(autoreverses: true)
                ) {
                    isExpanded = true
                }
            }
    }
}

// MARK: - 2. Золотой салют искорок (Golden Spark Burst)
/// Микро-частицы благородного золотого света, разлетающиеся при добавлении в избранное.
public struct GoldenSparkBurstView: View {
    let isTriggered: Bool
    
    @State private var particles: [SparkParticle] = []
    
    private struct SparkParticle: Identifiable {
        let id: Int
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let color: Color
    }
    
    public init(isTriggered: Bool) {
        self.isTriggered = isTriggered
    }
    
    public var body: some View {
        ZStack {
            if isTriggered {
                ForEach(0..<12, id: \.self) { index in
                    let angle = Double(index) * (360.0 / 12.0) * (.pi / 180.0)
                    let colors: [Color] = [
                        Color(hex: "F59E0B"), // Золото
                        Color(hex: "FBBF24"), // Янтарный свет
                        Color(hex: "EF4444"), // Рубиновый
                        Color(hex: "FCD34D")  // Светлое золото
                    ]
                    
                    Circle()
                        .fill(colors[index % colors.count])
                        .frame(width: (index % 2 == 0) ? 5 : 3.5, height: (index % 2 == 0) ? 5 : 3.5)
                        .offset(
                            x: cos(angle) * (isTriggered ? 28 : 2),
                            y: sin(angle) * (isTriggered ? 28 : 2)
                        )
                        .scaleEffect(isTriggered ? 0.2 : 1.2)
                        .opacity(isTriggered ? 0.0 : 1.0)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 3. Живой огонь лампады (Flickering Candle Flame)
/// Реалистичное, благоговейное мерцание пламени свечи (микро-покачивание и дыхание света).
public struct FlickeringCandleFlame: View {
    let baseColor: Color
    let iconSize: CGFloat
    
    @State private var flickerScale: CGFloat = 1.0
    @State private var flickerOffset: CGFloat = 0.0
    @State private var flickerOpacity: Double = 0.95
    
    public init(baseColor: Color = Color(hex: "F59E0B"), iconSize: CGFloat = 20) {
        self.baseColor = baseColor
        self.iconSize = iconSize
    }
    
    public var body: some View {
        ZStack {
            // Теплый ореол позади пламени
            Circle()
                .fill(baseColor.opacity(0.35))
                .frame(width: iconSize * 1.8, height: iconSize * 1.8)
                .scaleEffect(flickerScale * 1.1)
                .blur(radius: 6)
            
            // Основной язычок пламени
            Image(systemName: "flame.fill")
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FDE047"), baseColor, Color(hex: "EA580C")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(x: flickerScale, y: 2.0 - flickerScale, anchor: .bottom)
                .rotationEffect(.degrees(Double(flickerOffset) * 2.5), anchor: .bottom)
                .opacity(flickerOpacity)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.9)
                .repeatForever(autoreverses: true)
            ) {
                flickerScale = 1.08
                flickerOffset = 1.0
                flickerOpacity = 1.0
            }
        }
    }
}

// MARK: - 4. Золотой световой блик (Shimmer Effect Modifier)
/// Элегантный луч света, плавно пробегающий под углом через бейджи или карточки.
public struct LuysShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0
    let duration: Double
    let delay: Double
    
    public init(duration: Double = 2.2, delay: Double = 3.5) {
        self.duration = duration
        self.delay = delay
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.32),
                            Color(hex: "FDE68A").opacity(0.4),
                            Color.white.opacity(0.32),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: width * 0.75)
                    .rotationEffect(.degrees(20))
                    .offset(x: phase * (width * 2.2))
                    .clipped()
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.2
                }
            }
    }
}

extension View {
    /// Применяет деликатный золотистый блик света
    public func luysShimmer(duration: Double = 2.4) -> some View {
        modifier(LuysShimmerModifier(duration: duration))
    }
}

// MARK: - 5. Каскадное появление (Staggered Entrance Animation)
/// Позволяет карточкам плавно выплывать волной сверху вниз с каскадной задержкой.
public struct StaggeredEntranceModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var isVisible: Bool = false
    
    public init(index: Int, baseDelay: Double = 0.05) {
        self.index = index
        self.baseDelay = baseDelay
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 22)
            .scaleEffect(isVisible ? 1.0 : 0.97)
            .onAppear {
                withAnimation(
                    .spring(response: 0.48, dampingFraction: 0.76)
                    .delay(Double(index) * baseDelay)
                ) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Каскадный вход элемента списка или набора карточек
    public func staggeredEntrance(index: Int, baseDelay: Double = 0.05) -> some View {
        modifier(StaggeredEntranceModifier(index: index, baseDelay: baseDelay))
    }
}

// MARK: - 6. Живой аудио-эквалайзер (Equalizer Waveform Bars)
/// Индикатор проигрывания аудио с динамически танцующими волнами звука.
public struct AudioWaveformIndicator: View {
    let isPlaying: Bool
    let color: Color
    let barCount: Int
    
    @State private var animPhase: Bool = false
    
    public init(isPlaying: Bool, color: Color = Color(hex: "F59E0B"), barCount: Int = 4) {
        self.isPlaying = isPlaying
        self.color = color
        self.barCount = barCount
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: 3, height: barHeight(for: idx))
            }
        }
        .frame(height: 16)
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startAnimation()
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    animPhase = false
                }
            }
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        guard isPlaying else { return 4 }
        if animPhase {
            let heights: [CGFloat] = [15, 8, 16, 11]
            return heights[index % heights.count]
        } else {
            let heights: [CGFloat] = [7, 14, 9, 15]
            return heights[index % heights.count]
        }
    }
    
    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: 0.38)
            .repeatForever(autoreverses: true)
        ) {
            animPhase = true
        }
    }
}
