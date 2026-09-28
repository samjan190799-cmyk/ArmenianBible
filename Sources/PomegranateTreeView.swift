import SwiftUI

// MARK: - Режим отображения Древа (Display Style)
enum PomegranateViewStyle {
    case compact(height: CGFloat = 84)
    case majestic(height: CGFloat = 280)
    
    var height: CGFloat {
        switch self {
        case .compact(let h): return h
        case .majestic(let h): return h
        }
    }
    
    var isCompact: Bool {
        if case .compact = self { return true }
        return false
    }
}

// MARK: - Художественное Гранатовое Древо Веры (Pomegranate Tree View)
/// Процедурная живописная векторная модель священного гранатового дерева на SwiftUI,
/// отражающая 6 стадий роста, покачивание кроны на ветру, золотую пыльцу и интерактивные плоды.
struct PomegranateTreeView: View {
    let stage: PomegranateStage
    let style: PomegranateViewStyle
    let isThirsting: Bool
    let onFruitTapped: ((Int) -> Void)?
    
    @State private var swayPhase: CGFloat = 0.0
    @State private var pulseGlow: CGFloat = 1.0
    @State private var shimmerPhase: CGFloat = 0.0
    
    init(
        stage: PomegranateStage,
        style: PomegranateViewStyle = .majestic(),
        isThirsting: Bool = false,
        onFruitTapped: ((Int) -> Void)? = nil
    ) {
        self.stage = stage
        self.style = style
        self.isThirsting = isThirsting
        self.onFruitTapped = onFruitTapped
    }
    
    // Мягкое затемнение/пастельность, если дерево ждет утренней росы
    private var foliageOpacity: Double {
        isThirsting ? 0.72 : 1.0
    }
    
    private var saturationRatio: Double {
        isThirsting ? 0.75 : 1.0
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Небесный божественный ореол света позади кроны
            if !style.isCompact {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (stage == .treeOfLife ? Color(hex: "FDE047") : Color(hex: "F59E0B")).opacity(stage >= .bloomingTree ? 0.35 : 0.18),
                                Color(hex: "D97706").opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: style.height * 0.75
                        )
                    )
                    .frame(width: style.height * 1.3, height: style.height * 1.3)
                    .scaleEffect(pulseGlow)
                    .offset(y: -style.height * 0.28)
                    .blur(radius: 20)
            }
            
            // 2. Плодородная освященная земля (Ground Base)
            PomegranateSoilBaseView(style: style, stage: stage)
            
            // 3. Тело дерева в зависимости от текущей стадии
            Group {
                switch stage {
                case .seed:
                    PomegranateSeedView(style: style)
                case .sprout:
                    PomegranateSproutView(style: style, swayPhase: swayPhase)
                case .youngTree:
                    PomegranateYoungTreeView(style: style, swayPhase: swayPhase)
                case .bloomingTree:
                    PomegranateMatureTreeView(
                        style: style,
                        stage: stage,
                        hasFlowers: true,
                        fruitsCount: 3,
                        swayPhase: swayPhase,
                        onFruitTapped: onFruitTapped
                    )
                case .fruitfulTree:
                    PomegranateMatureTreeView(
                        style: style,
                        stage: stage,
                        hasFlowers: false,
                        fruitsCount: 6,
                        swayPhase: swayPhase,
                        onFruitTapped: onFruitTapped
                    )
                case .treeOfLife:
                    PomegranateMatureTreeView(
                        style: style,
                        stage: stage,
                        hasFlowers: true,
                        fruitsCount: 9,
                        isTreeOfLife: true,
                        swayPhase: swayPhase,
                        onFruitTapped: onFruitTapped
                    )
                }
            }
            .saturation(saturationRatio)
            .opacity(foliageOpacity)
            
            // 4. Летающая золотая пыльца и искорки света для старших стадий
            if !style.isCompact && stage >= .bloomingTree {
                PomegranatePollenParticlesView(height: style.height)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: style.height)
        .onAppear {
            // Плавное колыхание ветвей на легком ветру
            withAnimation(
                .easeInOut(duration: 4.2)
                .repeatForever(autoreverses: true)
            ) {
                swayPhase = 1.0
            }
            
            // Пульсация божественного ореола
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                pulseGlow = 1.12
            }
        }
    }
}

// MARK: - 1. Почва / Основание Древа (Soil Base)
struct PomegranateSoilBaseView: View {
    let style: PomegranateViewStyle
    let stage: PomegranateStage
    
    var body: some View {
        let width = style.isCompact ? 60.0 : 170.0
        let height = style.isCompact ? 8.0 : 20.0
        
        ZStack {
            // Мягкая тень под деревом
            Ellipse()
                .fill(Color.black.opacity(0.28))
                .frame(width: width * 1.25, height: height * 0.9)
                .blur(radius: style.isCompact ? 2 : 5)
                .offset(y: height * 0.3)
            
            // Теплая земляная насыпь с легким золотистым оттенком
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "451A03"),
                            Color(hex: "291002"),
                            Color(hex: "1F0C02")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)
                .overlay(
                    // Тонкая окантовка света на почве
                    Ellipse()
                        .stroke(Color(hex: "D97706").opacity(0.35), lineWidth: 0.8)
                )
        }
    }
}

// MARK: - 2. Стадия 1: Семя веры (Seed)
struct PomegranateSeedView: View {
    let style: PomegranateViewStyle
    @State private var seedGlow: Bool = false
    
    var body: some View {
        let seedSize: CGFloat = style.isCompact ? 14 : 34
        
        ZStack(alignment: .bottom) {
            // Если экран полноразмерный — показываем духовное видение будущего дерева и лучи света
            if !style.isCompact {
                // 1. Небесный луч света, нисходящий на семя
                LinearGradient(
                    colors: [
                        Color(hex: "FDE047").opacity(0.28),
                        Color(hex: "F59E0B").opacity(0.12),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 90, height: 210)
                .clipShape(Capsule())
                .blur(radius: 6)
                .offset(y: -40)
                
                // 2. Полупрозрачный силуэт будущего цветущего древа (образ плодов)
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "F59E0B").opacity(seedGlow ? 0.6 : 0.3))
                    
                    Image(systemName: "tree.fill")
                        .font(.system(size: 130))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "10B981").opacity(0.16),
                                    Color(hex: "059669").opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blur(radius: 1.0)
                }
                .offset(y: -50)
                
                // 3. Бейдж: Семя укореняется
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9))
                    Text(BibleManager.shared.appLanguage == .armenian ? "Սերմը արմատավորվում է" : (BibleManager.shared.appLanguage == .russian ? "Семя пускает корни" : "Seed taking root"))
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(hex: "EF4444"))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.08), radius: 4)
                )
                .overlay(Capsule().stroke(Color(hex: "EF4444").opacity(0.3), lineWidth: 1))
                .offset(y: -seedSize - 20)
            }
            
            // 4. Тонкие светящиеся корешки веры в почве
            if !style.isCompact {
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 0))
                    path.addQuadCurve(to: CGPoint(x: -18, y: 12), control: CGPoint(x: -8, y: 8))
                    path.move(to: CGPoint(x: 10, y: 0))
                    path.addQuadCurve(to: CGPoint(x: 38, y: 12), control: CGPoint(x: 28, y: 8))
                    path.move(to: CGPoint(x: 10, y: 0))
                    path.addLine(to: CGPoint(x: 10, y: 14))
                }
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "FDE047").opacity(0.7), Color(hex: "D97706").opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )
                .frame(width: 20, height: 14)
                .offset(y: 4)
            }
            
            // 5. Сияющее рубиновое семечко веры
            VStack(spacing: 2) {
                ZStack {
                    // Внешнее свечение
                    Circle()
                        .fill(Color(hex: "EF4444").opacity(seedGlow ? 0.35 : 0.15))
                        .frame(width: seedSize * 1.6, height: seedSize * 1.6)
                        .blur(radius: 6)
                    
                    // Рубиновое семечко граната в форме капли
                    Image(systemName: "drop.fill")
                        .font(.system(size: seedSize, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "F87171"), Color(hex: "DC2626"), Color(hex: "7F1D1D")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(180))
                        .shadow(color: Color(hex: "EF4444").opacity(seedGlow ? 0.8 : 0.35), radius: seedGlow ? 12 : 5)
                    
                    // Золотой внутренний зародыш жизни
                    Circle()
                        .fill(Color(hex: "FDE047"))
                        .frame(width: seedSize * 0.35, height: seedSize * 0.35)
                        .blur(radius: 0.5)
                }
                .offset(y: -seedSize * 0.2)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                seedGlow = true
            }
        }
    }
}

// MARK: - 3. Стадия 2: Нежный росток (Sprout)
struct PomegranateSproutView: View {
    let style: PomegranateViewStyle
    let swayPhase: CGFloat
    
    var body: some View {
        let sproutHeight: CGFloat = style.isCompact ? 42 : 110
        let sproutWidth: CGFloat = style.isCompact ? 28 : 70
        
        ZStack(alignment: .bottom) {
            // Изогнутый изумрудный стебель
            Path { path in
                let startX = sproutWidth * 0.5
                let startY = sproutHeight
                path.move(to: CGPoint(x: startX, y: startY))
                path.addCurve(
                    to: CGPoint(x: startX + (swayPhase * 4) - 2, y: sproutHeight * 0.25),
                    control1: CGPoint(x: startX - 4, y: sproutHeight * 0.7),
                    control2: CGPoint(x: startX + 6, y: sproutHeight * 0.45)
                )
            }
            .stroke(
                LinearGradient(
                    colors: [Color(hex: "15803D"), Color(hex: "22C55E"), Color(hex: "4ADE80")],
                    startPoint: .bottom,
                    endPoint: .top
                ),
                style: StrokeStyle(lineWidth: style.isCompact ? 2.5 : 5, lineCap: .round)
            )
            
            // Два нежных листочка наверху
            HStack(spacing: style.isCompact ? 2 : 6) {
                // Левый лист
                PomegranateLeafShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "86EFAC"), Color(hex: "16A34A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: sproutWidth * 0.38, height: sproutHeight * 0.32)
                    .rotationEffect(.degrees(-35 - Double(swayPhase * 6)), anchor: .bottomTrailing)
                
                // Правый лист
                PomegranateLeafShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "BBF7D0"), Color(hex: "22C55E")],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
                    .frame(width: sproutWidth * 0.38, height: sproutHeight * 0.32)
                    .rotationEffect(.degrees(35 + Double(swayPhase * 6)), anchor: .bottomLeading)
            }
            .offset(y: -sproutHeight * 0.68)
            
            // Росинка на вершине
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: style.isCompact ? 3 : 7, height: style.isCompact ? 3 : 7)
                .shadow(color: Color.white.opacity(0.6), radius: 3)
                .offset(y: -sproutHeight * 0.88)
        }
        .frame(width: sproutWidth, height: sproutHeight)
    }
}

// MARK: - 4. Стадия 3: Крепнущее деревце (Young Tree)
struct PomegranateYoungTreeView: View {
    let style: PomegranateViewStyle
    let swayPhase: CGFloat
    
    var body: some View {
        let treeHeight: CGFloat = style.isCompact ? 60 : 160
        let treeWidth: CGFloat = style.isCompact ? 50 : 130
        
        ZStack(alignment: .bottom) {
            // Ствол деревца
            PomegranateTrunkShape(thickness: style.isCompact ? 5 : 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "78350F"), Color(hex: "451A03")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: treeWidth * 0.22, height: treeHeight * 0.65)
            
            // Крона с ветвями и листьями
            ZStack {
                // Листва слева
                PomegranateLeafClusterView(size: treeWidth * 0.42, sway: -swayPhase)
                    .offset(x: -treeWidth * 0.25, y: -treeHeight * 0.45)
                
                // Листва справа
                PomegranateLeafClusterView(size: treeWidth * 0.46, sway: swayPhase)
                    .offset(x: treeWidth * 0.25, y: -treeHeight * 0.5)
                
                // Центральная верхняя листва
                PomegranateLeafClusterView(size: treeWidth * 0.52, sway: swayPhase * 0.5)
                    .offset(y: -treeHeight * 0.65)
                
                // Маленький рубиновый гранатовый бутон
                PomegranateFlowerBudView(size: style.isCompact ? 9 : 18)
                    .offset(x: treeWidth * 0.18, y: -treeHeight * 0.52)
            }
        }
        .frame(width: treeWidth, height: treeHeight)
    }
}

// MARK: - 5. Стадии 4, 5, 6: Зрелое Цветущее и Плодоносящее Древо (Mature Tree)
struct PomegranateMatureTreeView: View {
    let style: PomegranateViewStyle
    let stage: PomegranateStage
    let hasFlowers: Bool
    let fruitsCount: Int
    var isTreeOfLife: Bool = false
    let swayPhase: CGFloat
    let onFruitTapped: ((Int) -> Void)?
    
    var body: some View {
        let treeHeight = style.height * 0.88
        let treeWidth = style.isCompact ? style.height * 0.95 : min(320.0, style.height * 1.1)
        
        ZStack(alignment: .bottom) {
            // 1. Могучий ствол и скелетные ветви в древнеармянском стиле
            PomegranateMatureTrunkView(
                width: treeWidth * 0.26,
                height: treeHeight * 0.6,
                isTreeOfLife: isTreeOfLife,
                isCompact: style.isCompact
            )
            
            // 2. Пышная крона из ланцетовидных гранатовых листьев
            ZStack {
                // Задний темный слой листвы для объема
                PomegranateFoliageBackground(width: treeWidth * 0.88, height: treeHeight * 0.65, isTreeOfLife: isTreeOfLife)
                    .offset(y: -treeHeight * 0.42)
                
                // Передние живописные гроздья листьев
                PomegranateFoliageForeground(
                    width: treeWidth,
                    height: treeHeight * 0.7,
                    swayPhase: swayPhase,
                    isTreeOfLife: isTreeOfLife
                )
                .offset(y: -treeHeight * 0.45)
            }
            
            // 3. Алые цветы граната (*նռան ծաղիկներ*)
            if hasFlowers {
                PomegranateFlowersLayer(
                    width: treeWidth,
                    height: treeHeight,
                    isCompact: style.isCompact
                )
            }
            
            // 4. Спелые царственные плоды граната с коронами (*թագավորական նուռ*)
            PomegranateFruitsLayer(
                width: treeWidth,
                height: treeHeight,
                fruitsCount: fruitsCount,
                isCompact: style.isCompact,
                isTreeOfLife: isTreeOfLife,
                swayPhase: swayPhase,
                onFruitTapped: onFruitTapped
            )
        }
        .frame(width: treeWidth, height: treeHeight)
    }
}

// MARK: - Вспомогательные элементы: Ствол зрелого дерева
struct PomegranateMatureTrunkView: View {
    let width: CGFloat
    let height: CGFloat
    let isTreeOfLife: Bool
    let isCompact: Bool
    
    var body: some View {
        ZStack {
            // Основа ствола
            Path { path in
                path.move(to: CGPoint(x: width * 0.1, y: height))
                // Левая граница ствола с расширением ветвей
                path.addCurve(
                    to: CGPoint(x: 0, y: height * 0.2),
                    control1: CGPoint(x: width * 0.2, y: height * 0.6),
                    control2: CGPoint(x: width * 0.05, y: height * 0.4)
                )
                // Верхнее разветвление
                path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.25))
                path.addCurve(
                    to: CGPoint(x: width * 0.5, y: 0),
                    control1: CGPoint(x: width * 0.4, y: height * 0.15),
                    control2: CGPoint(x: width * 0.45, y: height * 0.05)
                )
                path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.25))
                // Правая ветвь
                path.addLine(to: CGPoint(x: width, y: height * 0.2))
                // Правая граница ствола
                path.addCurve(
                    to: CGPoint(x: width * 0.9, y: height),
                    control1: CGPoint(x: width * 0.95, y: height * 0.4),
                    control2: CGPoint(x: width * 0.8, y: height * 0.6)
                )
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: isTreeOfLife ? [
                        Color(hex: "B45309"),
                        Color(hex: "78350F"),
                        Color(hex: "451A03")
                    ] : [
                        Color(hex: "78350F"),
                        Color(hex: "451A03"),
                        Color(hex: "291002")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                // Текстура коры древнего дерева
                Path { path in
                    path.move(to: CGPoint(x: width * 0.48, y: height * 0.95))
                    path.addCurve(
                        to: CGPoint(x: width * 0.52, y: height * 0.3),
                        control1: CGPoint(x: width * 0.42, y: height * 0.7),
                        control2: CGPoint(x: width * 0.58, y: height * 0.5)
                    )
                }
                .stroke(Color(hex: "D97706").opacity(0.4), lineWidth: isCompact ? 1.0 : 2.0)
            )
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Фоновый и передний слои листвы
struct PomegranateFoliageBackground: View {
    let width: CGFloat
    let height: CGFloat
    let isTreeOfLife: Bool
    
    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            (isTreeOfLife ? Color(hex: "15803D") : Color(hex: "14532D")),
                            Color(hex: "064E3B").opacity(0.85)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: width * 0.45
                    )
                )
                .frame(width: width * 0.78, height: height * 0.72)
        }
    }
}

struct PomegranateFoliageForeground: View {
    let width: CGFloat
    let height: CGFloat
    let swayPhase: CGFloat
    let isTreeOfLife: Bool
    
    var body: some View {
        ZStack {
            // Кластеры сочных гранатовых листьев
            ForEach(0..<7, id: \.self) { idx in
                let angle = Double(idx) * 28.0 - 84.0
                let radius = width * 0.32
                let rad = angle * .pi / 180.0
                let x = cos(rad) * radius
                let y = sin(rad) * radius * 0.65
                
                PomegranateLeafClusterView(
                    size: width * 0.28,
                    sway: (idx % 2 == 0 ? swayPhase : -swayPhase) * 0.7
                )
                .offset(x: x, y: y)
            }
        }
    }
}

// MARK: - Слой Цветов Граната (Blossoms)
struct PomegranateFlowersLayer: View {
    let width: CGFloat
    let height: CGFloat
    let isCompact: Bool
    
    var body: some View {
        let flowerSize: CGFloat = isCompact ? 11 : 22
        
        ZStack {
            // 3 алых гранатовых цветка с золотыми венчиками
            PomegranateBlossomView(size: flowerSize)
                .offset(x: -width * 0.32, y: -height * 0.45)
            
            PomegranateBlossomView(size: flowerSize * 1.1)
                .offset(x: width * 0.28, y: -height * 0.52)
            
            PomegranateBlossomView(size: flowerSize * 0.95)
                .offset(x: width * 0.05, y: -height * 0.68)
        }
    }
}

// MARK: - Слой Спелых Плодов Граната (Interactive Ruby Fruits)
struct PomegranateFruitsLayer: View {
    let width: CGFloat
    let height: CGFloat
    let fruitsCount: Int
    let isCompact: Bool
    let isTreeOfLife: Bool
    let swayPhase: CGFloat
    let onFruitTapped: ((Int) -> Void)?
    
    // Координаты расположения плодов на кроне дерева (до 9 штук)
    private var fruitPositions: [(xRatio: CGFloat, yRatio: CGFloat)] {
        [
            (-0.28, -0.42), // 1. Любовь
            (0.24, -0.46),  // 2. Радость
            (-0.10, -0.62), // 3. Мир
            (0.12, -0.66),  // 4. Долготерпение
            (-0.35, -0.28), // 5. Благость
            (0.32, -0.32),  // 6. Милосердие
            (-0.16, -0.36), // 7. Вера
            (0.16, -0.38),  // 8. Кротость
            (0.0, -0.48)    // 9. Воздержание (Центральный в Древе Жизни)
        ]
    }
    
    var body: some View {
        let count = min(fruitsCount, fruitPositions.count)
        let fruitSize: CGFloat = isCompact ? 13 : 28
        
        ZStack {
            ForEach(0..<count, id: \.self) { idx in
                let pos = fruitPositions[idx]
                let x = width * pos.xRatio
                let y = height * pos.yRatio
                let swayOffset = (idx % 2 == 0 ? swayPhase : -swayPhase) * 2.5
                
                Button {
                    onFruitTapped?(idx + 1)
                } label: {
                    RoyalPomegranateFruitView(
                        size: fruitSize * (idx == 8 ? 1.2 : 1.0),
                        isGolden: isTreeOfLife && (idx == 0 || idx == 8)
                    )
                }
                .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.84))
                .offset(x: x + swayOffset, y: y)
                .disabled(onFruitTapped == nil)
            }
        }
    }
}

// MARK: - Одиночный Царственный Плод Граната с Короной (Royal Pomegranate Fruit)
struct RoyalPomegranateFruitView: View {
    let size: CGFloat
    var isGolden: Bool = false
    @State private var isPulsing: Bool = false
    
    var body: some View {
        VStack(spacing: -size * 0.18) {
            // Зубчатая корона граната (Calyx Crown)
            HStack(spacing: size * 0.06) {
                ForEach(0..<3, id: \.self) { _ in
                    TriangleShape()
                        .fill(
                            LinearGradient(
                                colors: isGolden ? [Color(hex: "FDE047"), Color(hex: "D97706")] : [Color(hex: "EF4444"), Color(hex: "991B1B")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.22, height: size * 0.28)
                }
            }
            
            // Налитое рубиновое тело граната с бликом
            ZStack {
                // Внешний мягкий ореол света
                Circle()
                    .fill((isGolden ? Color(hex: "F59E0B") : Color(hex: "EF4444")).opacity(isPulsing ? 0.35 : 0.12))
                    .frame(width: size * 1.35, height: size * 1.35)
                    .blur(radius: 4)
                
                // Основной шар плода
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isGolden ? [
                                Color(hex: "FEF08A"),
                                Color(hex: "F59E0B"),
                                Color(hex: "B45309")
                            ] : [
                                Color(hex: "F87171"),
                                Color(hex: "DC2626"),
                                Color(hex: "991B1B"),
                                Color(hex: "450A0A")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: (isGolden ? Color(hex: "F59E0B") : Color(hex: "EF4444")).opacity(0.45), radius: size * 0.25, y: 1)
                
                // Внутренний рубиновый глянцевый блик света
                Circle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: size * 0.28, height: size * 0.2)
                    .offset(x: -size * 0.22, y: -size * 0.22)
            }
        }
        .scaleEffect(isPulsing ? 1.05 : 0.98)
        .onAppear {
            withAnimation(
                .easeInOut(duration: Double.random(in: 2.2...3.5))
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Алый Цветок Граната (Pomegranate Blossom)
struct PomegranateBlossomView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Алые лепестки в форме звезды
            ForEach(0..<5, id: \.self) { idx in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F87171"), Color(hex: "DC2626"), Color(hex: "991B1B")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.35, height: size * 0.8)
                    .rotationEffect(.degrees(Double(idx) * 72.0))
            }
            
            // Золотые тычинки в центре
            Circle()
                .fill(Color(hex: "FDE047"))
                .frame(width: size * 0.35, height: size * 0.35)
                .shadow(color: Color(hex: "F59E0B").opacity(0.8), radius: 2)
        }
    }
}

// MARK: - Бутон цветка граната (Flower Bud)
struct PomegranateFlowerBudView: View {
    let size: CGFloat
    
    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "F87171"), Color(hex: "B91C1C")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.5, height: size)
            .rotationEffect(.degrees(25))
    }
}

// MARK: - Кластер гранатовых листьев
struct PomegranateLeafClusterView: View {
    let size: CGFloat
    let sway: CGFloat
    
    var body: some View {
        ZStack {
            PomegranateLeafShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "4ADE80"), Color(hex: "15803D"), Color(hex: "14532D")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.65, height: size)
                .rotationEffect(.degrees(-22 + Double(sway * 5)), anchor: .bottom)
            
            PomegranateLeafShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "86EFAC"), Color(hex: "16A34A"), Color(hex: "14532D")],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .frame(width: size * 0.65, height: size)
                .rotationEffect(.degrees(22 + Double(sway * 5)), anchor: .bottom)
        }
    }
}

// MARK: - Форма листа граната (Ланцетовидная)
struct PomegranateLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.midY)
        )
        return path
    }
}

// MARK: - Форма ствола деревца
struct PomegranateTrunkShape: Shape {
    let thickness: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - thickness * 0.5, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - thickness * 0.3, y: rect.minY),
            control: CGPoint(x: rect.midX - thickness * 0.8, y: rect.midY)
        )
        path.addLine(to: CGPoint(x: rect.midX + thickness * 0.3, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX + thickness * 0.5, y: rect.maxY),
            control: CGPoint(x: rect.midX + thickness * 0.8, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Форма зубца короны (Треугольник)
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Золотистая пыльца света и благодати (Pollen Particles)
struct PomegranatePollenParticlesView: View {
    let height: CGFloat
    
    @State private var animPhase: Bool = false
    
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { idx in
                let angle = Double(idx) * 30.0 * .pi / 180.0
                let dist = CGFloat(60 + (idx * 9))
                let x = cos(angle) * dist
                let y = sin(angle) * (dist * 0.7) - (height * 0.4)
                
                Circle()
                    .fill(idx % 2 == 0 ? Color(hex: "FDE047") : Color(hex: "F59E0B"))
                    .frame(width: (idx % 3 == 0) ? 3.5 : 2.0, height: (idx % 3 == 0) ? 3.5 : 2.0)
                    .offset(x: animPhase ? x + 6 : x - 6, y: animPhase ? y - 8 : y + 8)
                    .opacity(animPhase ? 0.85 : 0.25)
                    .blur(radius: 0.4)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.8)
                .repeatForever(autoreverses: true)
            ) {
                animPhase = true
            }
        }
    }
}
