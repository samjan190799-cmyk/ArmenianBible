import SwiftUI

// MARK: - Полноэкранный Экран «Гранатовый Сад Веры» (Pomegranate Sanctuary View)
struct PomegranateSanctuarySheetView: View {
    @ObservedObject var treeManager = PomegranateTreeManager.shared
    @ObservedObject var bibleManager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingFruitDetail: SpiritualFruit? = nil
    @State private var dewAnimationPulse: Bool = false
    @State private var isSparkBurstActive: Bool = false
    @State private var isSharingTreeCard: Bool = false
    @State private var shareItem: ShareItem? = nil
    
    private var language: AppLanguage {
        bibleManager.appLanguage
    }
    
    private var accentColor: Color {
        Color(hex: bibleManager.accentTheme.colorHex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Фоновый градиент священного храмового сада
                LinearGradient(
                    colors: colorScheme == .dark ? [
                        Color(hex: "090A0F"),
                        Color(hex: "180C0E"),
                        Color(hex: "0F172A")
                    ] : [
                        Color(hex: "FFFBEB"),
                        Color(hex: "FEF2F2"),
                        Color(hex: "F8FAFC")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Тонкое фоновое сияние
                DivineBreathingGlow(color: Color(hex: "EF4444").opacity(colorScheme == .dark ? 0.22 : 0.12))
                    .offset(y: -100)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Верхний заголовок стадии
                        stageHeaderView
                            .padding(.top, 8)
                        
                        // 2. Интерактивное величественное Древо Граната
                        ZStack {
                            PomegranateTreeView(
                                stage: treeManager.currentStage,
                                style: .majestic(height: 290),
                                isThirsting: treeManager.isThirstingForDew,
                                onFruitTapped: { fruitIndex in
                                    handleFruitTap(index: fruitIndex)
                                }
                            )
                            
                            // Салют искр при сборе/тапе на плод
                            RubySparkleBurstView(isTriggered: isSparkBurstActive)
                                .offset(y: -60)
                            
                            // Рябь омовения росой
                            DewRippleView(isTriggered: dewAnimationPulse, color: Color(hex: "38BDF8"))
                                .offset(y: -50)
                            
                            // Подсказка нажать на плод
                            if treeManager.currentStage >= .bloomingTree {
                                VStack {
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Image(systemName: "hand.tap.fill")
                                            .font(.system(size: 11))
                                        Text(language == .armenian ? "Հպվեք նռանը՝ պտուղը բացելու համար" : (language == .russian ? "Коснитесь плода, чтобы открыть благословение" : "Tap any pomegranate to reveal blessing"))
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(colorScheme == .dark ? Color(hex: "FDE047") : Color(hex: "B45309"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4)
                                    )
                                    .padding(.bottom, -12)
                                }
                            }
                        }
                        .frame(height: 310)
                        
                        // 3. Плашка утренней росы (Закон Благодати)
                        morningDewStatusCard
                            .padding(.horizontal, 20)
                        
                        // 4. Карточка прогресса до следующей стадии
                        growthProgressBarCard
                            .padding(.horizontal, 20)
                        
                        // 5. 9 Плодов Духа (Галатам 5:22-23)
                        spiritualFruitsSection
                            .padding(.horizontal, 20)
                        
                        // 6. Библейское слово обетования
                        promiseVerseCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 36)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        bibleManager.triggerHapticImpact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        bibleManager.triggerHapticImpact(.medium)
                        shareGardenAsCard()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .bold))
                            Text(language == .armenian ? "Կիսվել" : (language == .russian ? "Поделиться" : "Share"))
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "EF4444"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "EF4444").opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
            .sheet(item: $showingFruitDetail) { fruit in
                SpiritualFruitDetailSheetView(fruit: fruit, language: language)
                    .presentationDetents([.medium, .fraction(0.68)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(activityItems: [item.image])
            }
        }
    }
    
    // MARK: - 1. Верхний заголовок стадии
    private var stageHeaderView: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "EF4444"))
                
                Text(language == .armenian ? "ՀՈԳԵՎՈՐ ԱՃԻ ՆՌՆԵՆԻ" : (language == .russian ? "ДРЕВО ДУХОВНОГО РОСТА" : "TREE OF SPIRITUAL GROWTH"))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "EF4444"))
                    .tracking(1.2)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "EF4444"))
            }
            
            Text(treeManager.currentStage.title(for: language))
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
            
            Text(treeManager.currentStage.description(for: language))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - 2. Карточка Утренней Росы (Закон Милосердия)
    private var morningDewStatusCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: treeManager.isWateredToday ? [
                                Color(hex: "38BDF8"),
                                Color(hex: "0284C7")
                            ] : [
                                Color(hex: "F59E0B"),
                                Color(hex: "D97706")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: (treeManager.isWateredToday ? Color(hex: "0284C7") : Color(hex: "D97706")).opacity(0.35), radius: 6)
                
                Image(systemName: treeManager.isWateredToday ? "drop.fill" : "drop.triangle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(treeManager.isWateredToday ?
                         (language == .armenian ? "Օրհնված է երկնային ցողով" : (language == .russian ? "Омыто небесной росой" : "Blessed with Heavenly Dew")) :
                         (language == .armenian ? "Սպասում է առավոտյան ցողի" : (language == .russian ? "Жаждет утренней росы" : "Awaiting Morning Dew")))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                    
                    if treeManager.isWateredToday {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                }
                
                Text(treeManager.isWateredToday ?
                     (language == .armenian ? "Ձեր աղոթքն ու Խոսքի ընթերցումը սնում են ծառը:" : (language == .russian ? "Слово Божье и молитва питают корни древа." : "God's Word and prayer nourish your tree today.")) :
                     (language == .armenian ? "Կարդացեք օրվա համարը կամ վառեք մոմ:" : (language == .russian ? "Прочтите стих дня или зажгите свечу в храме." : "Read today's verse or light a prayer candle.")))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if !treeManager.isWateredToday {
                Button {
                    dewAnimationPulse = false
                    withAnimation {
                        dewAnimationPulse = true
                    }
                    treeManager.nourishWithDew(amount: 1)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                        Text(language == .armenian ? "Ցողել" : (language == .russian ? "Омыть" : "Water"))
                            .font(.system(size: 12, weight: .black))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "38BDF8"), Color(hex: "0284C7")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "0284C7").opacity(0.4), radius: 5, y: 2)
                    .livingBorder(
                        colors: [Color(hex: "7DD3FC"), Color(hex: "0284C7"), Color.white, Color(hex: "7DD3FC")],
                        cornerRadius: 16,
                        lineWidth: 1.2,
                        glowRadius: 4,
                        duration: 3.5
                    )
                }
                .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.92))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.85))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .livingBorder(
            colors: treeManager.isWateredToday ? [
                Color(hex: "38BDF8"),
                Color(hex: "0284C7"),
                Color(hex: "7DD3FC"),
                Color(hex: "38BDF8")
            ] : [
                Color(hex: "F59E0B"),
                Color(hex: "D97706"),
                Color(hex: "FDE68A"),
                Color(hex: "F59E0B")
            ],
            cornerRadius: 18,
            lineWidth: 1.2,
            glowRadius: 4,
            duration: 6.0
        )
    }
    
    // MARK: - 3. Прогресс роста
    private var growthProgressBarCard: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "EF4444"))
                    
                    Text("\(treeManager.daysStreak)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                    
                    Text(language == .armenian ? "օր Խոսքի մեջ" : (language == .russian ? "дн. в Слове" : "days in Word"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                let nextTarget = treeManager.currentStage.nextStageTargetDays
                let daysLeft = max(0, nextTarget - treeManager.daysStreak)
                
                Text(daysLeft > 0 ?
                     (language == .armenian ? "\(daysLeft) օր մինչև հաջորդ փուլը" : (language == .russian ? "Еще \(daysLeft) дн. до след. ступени" : "\(daysLeft) days to next stage")) :
                     (language == .armenian ? "Բարձրագույն աստիճան" : (language == .russian ? "Высшая ступень благодати" : "Highest state of grace")))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "EF4444"))
            }
            
            // Полоса прогресса
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "EF4444"), Color(hex: "F59E0B")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * CGFloat(treeManager.progressToNextStage)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.85))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .livingBorder(
            colors: [
                Color(hex: "EF4444"),
                Color(hex: "F59E0B"),
                Color(hex: "B91C1C"),
                Color(hex: "FBBF24"),
                Color(hex: "EF4444")
            ],
            cornerRadius: 18,
            lineWidth: 1.2,
            glowRadius: 5,
            duration: 6.5
        )
    }
    
    // MARK: - 4. 9 Плодов Духа (Галатам 5:22-23)
    private var spiritualFruitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(language == .armenian ? "ՍՈՒՐԲ ՀՈԳՈՒ 9 ՊՏՈՒՂՆԵՐԸ" : (language == .russian ? "9 ПЛОДОВ СВЯТОГО ДУХА" : "9 FRUITS OF THE HOLY SPIRIT"))
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(hex: "EF4444"))
                        .tracking(1.0)
                    
                    Text(language == .armenian ? "Գաղատացիս 5:22-23" : (language == .russian ? "Послание к Галатам 5:22-23" : "Galatians 5:22-23"))
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                }
                
                Spacer()
                
                Text("\(treeManager.visibleFruitsCount)/9")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "EF4444"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "EF4444").opacity(0.12))
                    .clipShape(Capsule())
            }
            
            // Сетка плодов 3x3
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(treeManager.spiritualFruits.enumerated()), id: \.element.id) { index, fruit in
                    let isUnlocked = (index < treeManager.visibleFruitsCount)
                    
                    Button {
                        if isUnlocked {
                            handleFruitTap(index: index + 1)
                        } else {
                            bibleManager.triggerHapticImpact(.light)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(
                                        isUnlocked ?
                                        LinearGradient(
                                            colors: [Color(hex: "EF4444"), Color(hex: "991B1B")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .shadow(color: isUnlocked ? Color(hex: "EF4444").opacity(0.4) : Color.clear, radius: 4)
                                
                                Image(systemName: fruit.icon)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(isUnlocked ? .white : .secondary)
                            }
                            
                            Text(fruit.name(for: language))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isUnlocked ? (colorScheme == .dark ? .white : Color(hex: "1E293B")) : .secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(isUnlocked ? 0.06 : 0.02) : Color.white.opacity(isUnlocked ? 0.9 : 0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(isUnlocked ? Color(hex: "EF4444").opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.92))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.85))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .livingBorder(
            colors: [
                Color(hex: "EF4444"),
                Color(hex: "8B5CF6"),
                Color(hex: "F59E0B"),
                Color(hex: "EF4444")
            ],
            cornerRadius: 20,
            lineWidth: 1.2,
            glowRadius: 5,
            duration: 7.5
        )
    }
    
    // MARK: - 5. Библейское Слово Обетования
    private var promiseVerseCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "EF4444").opacity(0.6))
            
            Text(language == .armenian ?
                 "«Ես եմ որթատունկը, և դուք՝ ճյուղերը: Ով մնում է իմ մեջ, և ես՝ նրա մեջ, նա շատ պտուղ է բերում...»" :
                 (language == .russian ?
                  "«Я есмь Лоза, а вы ветви; кто пребывает во Мне, и Я в нем, тот приносит много плода; ибо без Меня не можете делать ничего.»" :
                  "«I am the vine; you are the branches. If you remain in me and I in you, you will bear much fruit...»"))
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(colorScheme == .dark ? Color(hex: "E2E8F0") : Color(hex: "334155"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Text(language == .armenian ? "Յովհաննու 15:5" : (language == .russian ? "От Иоанна 15:5" : "John 15:5"))
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "EF4444"))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "EF4444").opacity(colorScheme == .dark ? 0.08 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: "EF4444").opacity(0.2), lineWidth: 0.8)
                )
        )
    }
    
    // MARK: - Обработка тапа на плод
    private func handleFruitTap(index: Int) {
        bibleManager.triggerHapticImpact(.heavy)
        isSparkBurstActive = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isSparkBurstActive = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if index - 1 < treeManager.spiritualFruits.count {
                showingFruitDetail = treeManager.spiritualFruits[index - 1]
            }
        }
    }
    
    // MARK: - Экспорт открытки Сада Веры для соцсетей
    @MainActor
    private func shareGardenAsCard() {
        let card = PomegranateGardenExportView(
            treeManager: treeManager,
            language: language,
            colorScheme: colorScheme
        )
        
        let hosting = UIHostingController(rootView: card)
        hosting.view.frame = CGRect(x: 0, y: 0, width: 1080, height: 1350)
        hosting.view.backgroundColor = UIColor.clear
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1350))
        let img = renderer.image { _ in
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }
        
        self.shareItem = ShareItem(image: img)
    }
}

// MARK: - Модальное Окно Одного Плода Святого Духа (Fruit Detail View)
struct SpiritualFruitDetailSheetView: View {
    let fruit: SpiritualFruit
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Иконка плода в короне
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F87171"), Color(hex: "DC2626"), Color(hex: "991B1B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 10, y: 4)
                
                Image(systemName: fruit.icon)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 14)
            
            VStack(spacing: 6) {
                Text(fruit.name(for: language))
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                
                Text(fruit.scriptureRef)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "EF4444"))
            }
            
            // Стихотворное Писание
            VStack(spacing: 10) {
                Text(fruit.scripture(for: language))
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "E2E8F0") : Color(hex: "334155"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 16)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
            .padding(.horizontal, 24)
            
            // Благословение
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(hex: "F59E0B"))
                Text(fruit.blessing(for: language))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Кнопка закрытия
            Button {
                dismiss()
            } label: {
                Text(language == .armenian ? "Փակել" : (language == .russian ? "Принять благословение" : "Accept Blessing"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "EF4444"), Color(hex: "B91C1C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(hex: "EF4444").opacity(0.35), radius: 8, y: 3)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Экспортная Карточка для Соцсетей (Pomegranate Garden Export View)
struct PomegranateGardenExportView: View {
    let treeManager: PomegranateTreeManager
    let language: AppLanguage
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "090A0F"), Color(hex: "1F1215"), Color(hex: "0B0F19")],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 36) {
                // Заголовок
                VStack(spacing: 8) {
                    Text("LUYS • ARMENIAN BIBLE")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "F59E0B"))
                        .tracking(3.0)
                    
                    Text(treeManager.currentStage.title(for: language))
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("\(treeManager.daysStreak) " + (language == .armenian ? "օր Խոսքի մեջ" : (language == .russian ? "дней в Слове" : "days in Word")))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "EF4444"))
                }
                .padding(.top, 60)
                
                // Дерево
                PomegranateTreeView(
                    stage: treeManager.currentStage,
                    style: .majestic(height: 380),
                    isThirsting: false
                )
                
                // Библейский стих
                VStack(spacing: 12) {
                    Text(language == .armenian ?
                         "«Ես եմ որթատունկը, և դուք՝ ճյուղերը: Ով մնում է իմ մեջ, նա շատ պտուղ է բերում:»" :
                         (language == .russian ?
                          "«Я есмь Лоза, а вы ветви; кто пребывает во Мне, тот приносит много плода.»" :
                          "«I am the vine; you are the branches. If you remain in me you will bear much fruit.»"))
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                    
                    Text("Յովհաննու 15:5")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "F59E0B"))
                }
                
                Spacer()
            }
        }
        .frame(width: 1080, height: 1350)
    }
}
