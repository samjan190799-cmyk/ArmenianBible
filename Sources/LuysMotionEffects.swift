import SwiftUI

// MARK: - 1. Божественный «дышащий» ореол (Divine Breathing Glow)
/// Непрерывно плавно пульсирующее свечение в тон акцентной темы приложения.
struct DivineBreathingGlow: View {
    let color: Color
    @State private var isExpanded: Bool = false
    
    init(color: Color) {
        self.color = color
    }
    
    var body: some View {
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
struct GoldenSparkBurstView: View {
    let isTriggered: Bool
    
    @State private var particles: [SparkParticle] = []
    
    private struct SparkParticle: Identifiable {
        let id: Int
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let color: Color
    }
    
    init(isTriggered: Bool) {
        self.isTriggered = isTriggered
    }
    
    var body: some View {
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
/// Реалистичное, благоговейное многослойное пламя церковной свечи:
/// хлопковый фитиль, синее основание, яркое белое ядро, золотой лепесток и мягкая аура света.
struct FlickeringCandleFlame: View {
    let baseColor: Color
    let iconSize: CGFloat
    let randomDelay: Double
    
    @State private var breathePhase: CGFloat = 1.0
    @State private var swayAngle: Double = 0.0
    @State private var microFlicker: CGFloat = 1.0
    
    init(baseColor: Color = Color(hex: "F59E0B"), iconSize: CGFloat = 20, randomDelay: Double = 0.0) {
        self.baseColor = baseColor
        self.iconSize = iconSize
        self.randomDelay = randomDelay
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Мягкая теплая радиальная аура (свет свечи в храме)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            baseColor.opacity(0.48),
                            Color(hex: "F59E0B").opacity(0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: iconSize * 1.5
                    )
                )
                .frame(width: iconSize * 2.8, height: iconSize * 2.8)
                .scaleEffect(breathePhase * microFlicker)
                .blur(radius: iconSize * 0.35)
                .offset(y: -iconSize * 0.3)
            
            // 2. Хлопковый фитилек свечи
            Capsule()
                .fill(Color(hex: "1F2937"))
                .frame(width: max(1.5, iconSize * 0.08), height: iconSize * 0.28)
                .offset(y: iconSize * 0.1)
            
            // 3. Сапфирово-голубая зона основания пламени (горение воска)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "60A5FA").opacity(0.85), Color(hex: "3B82F6").opacity(0.15)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: iconSize * 0.35, height: iconSize * 0.25)
                .blur(radius: 0.5)
                .offset(y: -iconSize * 0.04)
            
            // 4. Внешний золотисто-огненный лепесток пламени
            Image(systemName: "flame.fill")
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFFBEB"),
                            Color(hex: "FEF08A"),
                            baseColor,
                            Color(hex: "EA580C")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(x: 1.0 / microFlicker, y: breathePhase, anchor: .bottom)
                .rotationEffect(.degrees(swayAngle), anchor: .bottom)
                .shadow(color: Color(hex: "F59E0B").opacity(0.6), radius: iconSize * 0.25, y: -2)
            
            // 5. Внутреннее белое сияющее ядро (сверхгорячая сердцевина огня)
            Image(systemName: "flame.fill")
                .font(.system(size: iconSize * 0.55, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(hex: "FEF9C3"), Color(hex: "FDE047").opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(x: microFlicker, y: breathePhase * 0.95, anchor: .bottom)
                .rotationEffect(.degrees(swayAngle * 0.6), anchor: .bottom)
                .offset(y: -iconSize * 0.05)
                .blur(radius: 0.6)
        }
        .frame(width: iconSize * 1.5, height: iconSize * 1.5, alignment: .bottom)
        .onAppear {
            let offset = randomDelay.truncatingRemainder(dividingBy: 0.4)
            // Плавное глубокое дыхание огня
            withAnimation(
                .easeInOut(duration: 1.25 + offset)
                .repeatForever(autoreverses: true)
                .delay(randomDelay)
            ) {
                breathePhase = 1.14
            }
            
            // Живое покачивание пламени на ветру
            withAnimation(
                .easeInOut(duration: 1.6 + offset * 1.5)
                .repeatForever(autoreverses: true)
                .delay(randomDelay * 0.5)
            ) {
                swayAngle = 3.4
            }
            
            // Быстрое мерцание / трепет огня (микро-фликер)
            withAnimation(
                .easeInOut(duration: 0.3 + offset * 0.3)
                .repeatForever(autoreverses: true)
                .delay(randomDelay * 0.2)
            ) {
                microFlicker = 1.06
            }
        }
    }
}

// MARK: - 3.1. Реалистичная армянская храмовая свеча (Realistic Armenian Candle)
/// Детализированная модель церковной восковой свечи:
/// живое пламя с синим основанием, восковой столб с цилиндрическим бликом,
/// чаша оплавленного воска у фитиля, капли воска и латунный храмовый подсвечник.
struct RealisticArmenianCandleView: View {
    let tier: CandleTier
    let candleHeight: CGFloat?
    let candleWidth: CGFloat?
    let flameSize: CGFloat
    let randomSeed: Double
    let burnProgress: Double
    let isLit: Bool
    
    init(
        tier: CandleTier,
        candleHeight: CGFloat? = nil,
        candleWidth: CGFloat? = nil,
        flameSize: CGFloat? = nil,
        burnProgress: Double = 0.0,
        isLit: Bool = true,
        randomSeed: Double = 0.0
    ) {
        self.tier = tier
        self.candleHeight = candleHeight
        self.candleWidth = candleWidth
        self.burnProgress = max(0.0, min(1.0, burnProgress))
        self.isLit = isLit
        self.randomSeed = randomSeed
        
        if let flameSize {
            self.flameSize = flameSize
        } else {
            switch tier {
            case .generous: self.flameSize = 25
            case .temple: self.flameSize = 23
            case .rewarded: self.flameSize = 21
            case .small: self.flameSize = 20
            case .freeDaily: self.flameSize = 18
            }
        }
    }
    
    private var resolvedWidth: CGFloat {
        if let candleWidth { return candleWidth }
        switch tier {
        case .generous: return 20
        case .temple: return 17
        case .rewarded: return 15
        case .small: return 14
        case .freeDaily: return 12
        }
    }
    
    private var baseHeight: CGFloat {
        if let candleHeight { return candleHeight }
        switch tier {
        case .generous: return 52
        case .temple: return 44
        case .rewarded: return 38
        case .small: return 34
        case .freeDaily: return 28
        }
    }
    
    /// Реалистичная высота свечи с учетом таяния (от 100% до 22% огарка)
    private var meltedHeight: CGFloat {
        let minHeight: CGFloat = max(9.0, baseHeight * 0.22)
        return max(minHeight, baseHeight - (CGFloat(burnProgress) * (baseHeight - minHeight)))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Живой огонь с естественным разбросом фазы и уменьшением при догорании
            if isLit && burnProgress < 1.0 {
                let flameScale: CGFloat = burnProgress > 0.88 ? max(0.6, 1.0 - (CGFloat(burnProgress - 0.88) * 2.5)) : 1.0
                FlickeringCandleFlame(
                    baseColor: Color(hex: "F59E0B"),
                    iconSize: flameSize * flameScale,
                    randomDelay: randomSeed.truncatingRemainder(dividingBy: 0.8)
                )
                .offset(y: 4)
                .zIndex(2)
            } else {
                // Остывший обугленный фитилек
                Capsule()
                    .fill(Color(hex: "4B5563"))
                    .frame(width: 1.5, height: 5)
                    .offset(y: 2)
                    .zIndex(2)
            }
            
            // 2. Восковой столбик свечи (тает по мере сгорания)
            ZStack(alignment: .top) {
                // Чаша расплавленного полупрозрачного воска у вершины
                Capsule()
                    .fill(Color(hex: "FEF9C3"))
                    .frame(width: resolvedWidth, height: 3.5)
                    .zIndex(1)
                
                // Основной восковой цилиндр с текстурой медового пчелиного воска
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FEF08A"),
                                Color(hex: "FDE047"),
                                Color(hex: "F59E0B"),
                                Color(hex: "D97706"),
                                Color(hex: "92400E")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: resolvedWidth, height: meltedHeight)
                    .overlay(
                        HStack {
                            LinearGradient(
                                colors: [Color.clear, Color.white.opacity(0.35), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: max(2, resolvedWidth * 0.28))
                            .offset(x: resolvedWidth * 0.15)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 2.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 2.5)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.6)
                    )
                
                // Восковые потеки (увеличиваются по мере таяния)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FEF3C7"), Color(hex: "FDE68A")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2.2, height: max(4.0, meltedHeight * (0.35 + CGFloat(burnProgress) * 0.45)))
                    .offset(x: (resolvedWidth / 2) - 1.2, y: 3)
                    .shadow(color: Color.black.opacity(0.18), radius: 0.8, x: -0.5, y: 0.5)
                
                if burnProgress > 0.15 {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FEF3C7"), Color(hex: "FDE68A")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1.8, height: max(3.0, meltedHeight * (0.2 + CGFloat(burnProgress) * 0.35)))
                        .offset(x: -(resolvedWidth / 2) + 1.0, y: 4)
                        .shadow(color: Color.black.opacity(0.15), radius: 0.6, x: 0.5, y: 0.5)
                }
            }
            .zIndex(1)
            
            // 3. Лужица расплавленного воска и латунный подсвечник
            VStack(spacing: 0) {
                // Растущая лужица оплавленного воска у основания свечи
                let poolWidth = resolvedWidth + 2 + (CGFloat(burnProgress) * 12)
                let poolHeight = 2.5 + (CGFloat(burnProgress) * 2.0)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FEF9C3"), Color(hex: "FDE047"), Color(hex: "D97706")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: poolWidth, height: poolHeight)
                    .shadow(color: Color(hex: "F59E0B").opacity(0.25 * burnProgress), radius: 2)
                    .zIndex(1)
                
                // Кольцо-воскоуловитель (латунь)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FDE68A"), Color(hex: "D97706"), Color(hex: "78350F")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: resolvedWidth + 8, height: 3)
                
                // Нижнее массивное блюдце подсвечника
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "D97706"), Color(hex: "92400E"), Color(hex: "451A03")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(38, resolvedWidth + 18), height: 4)
                    .shadow(color: Color.black.opacity(0.4), radius: 3, y: 2)
            }
        }
    }
}

// MARK: - 4. Золотой световой блик (Shimmer Effect Modifier)
/// Элегантный луч света, плавно пробегающий под углом через бейджи или карточки.
struct LuysShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0
    let duration: Double
    let delay: Double
    
    init(duration: Double = 2.2, delay: Double = 3.5) {
        self.duration = duration
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
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
    func luysShimmer(duration: Double = 2.4) -> some View {
        modifier(LuysShimmerModifier(duration: duration))
    }
}

// MARK: - 5. Каскадное появление (Staggered Entrance Animation)
/// Позволяет карточкам плавно выплывать волной сверху вниз с каскадной задержкой.
struct StaggeredEntranceModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var isVisible: Bool = false
    
    init(index: Int, baseDelay: Double = 0.05) {
        self.index = index
        self.baseDelay = baseDelay
    }
    
    func body(content: Content) -> some View {
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
    func staggeredEntrance(index: Int, baseDelay: Double = 0.05) -> some View {
        modifier(StaggeredEntranceModifier(index: index, baseDelay: baseDelay))
    }
}

// MARK: - 6. Живой аудио-эквалайзер (Equalizer Waveform Bars)
/// Индикатор проигрывания аудио с динамически танцующими волнами звука.
struct AudioWaveformIndicator: View {
    let isPlaying: Bool
    let color: Color
    let barCount: Int
    
    @State private var animPhase: Bool = false
    
    init(isPlaying: Bool, color: Color = Color(hex: "F59E0B"), barCount: Int = 4) {
        self.isPlaying = isPlaying
        self.color = color
        self.barCount = barCount
    }
    
    var body: some View {
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
