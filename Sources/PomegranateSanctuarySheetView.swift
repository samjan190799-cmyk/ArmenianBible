import SwiftUI

// MARK: - Полноэкранный Экран «Гранатовый Сад Веры» (Pomegranate Sanctuary View)
struct PomegranateSanctuarySheetView: View {
    @ObservedObject var treeManager = PomegranateTreeManager.shared
    @ObservedObject var bibleManager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingFruitDetail: SpiritualFruit? = nil
    @State private var showingStageDetail: PomegranateStage? = nil
    @State private var isShowingGrowthGuide: Bool = false
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
                    HStack(spacing: 8) {
                        Button {
                            bibleManager.triggerHapticImpact(.light)
                            isShowingGrowthGuide = true
                        } label: {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "EF4444"))
                        }

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
            }
            .sheet(item: $showingFruitDetail) { fruit in
                SpiritualFruitDetailSheetView(fruit: fruit, language: language)
                    .presentationDetents([.medium, .fraction(0.68)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingGrowthGuide) {
                PomegranateGrowthGuideSheetView(language: language)
                    .presentationDetents([.fraction(0.88), .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $showingStageDetail) { stage in
                PomegranateStageDetailSheetView(stage: stage, currentStage: treeManager.currentStage, currentStreak: treeManager.daysStreak, language: language)
                    .presentationDetents([.medium, .fraction(0.68)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $shareItem) { item in
                ActivityView(activityItems: [item.image])
            }
        }
    }
    
    // MARK: - 1. Верхний заголовок стадии
    private var stageHeaderView: some View {
        VStack(spacing: 8) {
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

            // Кнопка руководства "Как растёт дерево?"
            Button {
                bibleManager.triggerHapticImpact(.light)
                isShowingGrowthGuide = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(language == .armenian ? "Ինչպե՞ս է աճում ծառը" : (language == .russian ? "Как растёт дерево?" : "How does the tree grow?"))
                        .font(.system(size: 12, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(Color(hex: "EF4444"))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "EF4444").opacity(0.10))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "EF4444").opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.94))
            .padding(.top, 2)
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
                    .overlay(
                        Capsule().stroke(Color(hex: "7DD3FC").opacity(0.6), lineWidth: 1.2)
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
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(treeManager.isWateredToday ? Color(hex: "38BDF8").opacity(0.45) : Color(hex: "F59E0B").opacity(0.45), lineWidth: 1.2)
        )
    }
    
    // MARK: - 3. Прогресс роста и Дорожная карта 6 Стадий
    private var growthProgressBarCard: some View {
        VStack(spacing: 14) {
            // Верхняя плашка стрика и дней
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
                     (language == .armenian ? "Եվս \(daysLeft) օր մինչև հաջորդ փուլը" : (language == .russian ? "Еще \(daysLeft) дн. до след. ступени" : "\(daysLeft) days to next stage")) :
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
            
            // Дорожная карта всех 6 стадий (Stage Roadmap)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(language == .armenian ? "ԱՃԻ 6 ՓՈՒԼԵՐԸ (ՍԵՂՄԵՔ ՓՈՒԼԻՆ)" : (language == .russian ? "6 СТАДИЙ РОСТА (НАЖМИТЕ ДЛЯ ДЕТАЛЕЙ)" : "6 GROWTH STAGES (TAP FOR DETAILS)"))
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                        .tracking(0.8)
                    
                    Spacer()
                    
                    Button {
                        bibleManager.triggerHapticImpact(.light)
                        isShowingGrowthGuide = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(language == .armenian ? "Կանոններ" : (language == .russian ? "Правила" : "Rules"))
                                .font(.system(size: 11, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "EF4444"))
                    }
                }
                
                // Горизонтальный скролл со всеми 6 стадиями
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PomegranateStage.allCases, id: \.rawValue) { stage in
                            let isCurrent = (stage == treeManager.currentStage)
                            let isCompleted = (stage < treeManager.currentStage)
                            
                            Button {
                                bibleManager.triggerHapticImpact(.light)
                                showingStageDetail = stage
                            } label: {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                isCurrent ? Color(hex: "EF4444") :
                                                (isCompleted ? Color(hex: "10B981") : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)))
                                            )
                                            .frame(width: 36, height: 36)
                                        
                                        if isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                        } else {
                                            Text(stageIcon(for: stage))
                                                .font(.system(size: 16))
                                        }
                                    }
                                    
                                    Text(stage.title(for: language))
                                        .font(.system(size: 11, weight: isCurrent ? .bold : .medium))
                                        .foregroundColor(isCurrent ? (colorScheme == .dark ? .white : Color(hex: "1E293B")) : .secondary)
                                        .lineLimit(1)
                                    
                                    Text("\(stage.requiredDays)+ " + (language == .armenian ? "օր" : (language == .russian ? "дн" : "d")))
                                        .font(.system(size: 10, weight: isCurrent ? .bold : .regular))
                                        .foregroundColor(isCurrent ? Color(hex: "EF4444") : .secondary.opacity(0.7))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(isCurrent ? Color(hex: "EF4444").opacity(0.12) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isCurrent ? Color(hex: "EF4444") : (isCompleted ? Color(hex: "10B981").opacity(0.4) : Color.clear), lineWidth: 1.2)
                                )
                            }
                            .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.94))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.85))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "EF4444").opacity(0.35), lineWidth: 1.2)
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
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "EF4444").opacity(0.35), lineWidth: 1.2)
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
    
    // MARK: - Иконка стадии для Roadmap
    private func stageIcon(for stage: PomegranateStage) -> String {
        switch stage {
        case .seed: return "🌱"
        case .sprout: return "🌿"
        case .youngTree: return "🌳"
        case .bloomingTree: return "🌺"
        case .fruitfulTree: return "🍎"
        case .treeOfLife: return "✨"
        }
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

// MARK: - Модальное Окно: Руководство по росту Древа (Growth Guide Sheet)
struct PomegranateGrowthGuideSheetView: View {
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. Верхняя карточка-интро
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "EF4444").opacity(0.12))
                                .frame(width: 64, height: 64)
                            Image(systemName: "tree.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color(hex: "EF4444"))
                        }
                        
                        Text(language == .armenian ? "Ինչպե՞ս է աճում ծառը" : (language == .russian ? "Как растёт Древо веры?" : "How does the Tree grow?"))
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                        
                        Text(language == .armenian ?
                             "Հոգևոր աճի նռնենին արտացոլում է ձեր ամենօրյա հոգևոր կյանքը և Աստծո Խոսքի մեջ հաստատուն մնալը:" :
                             (language == .russian ?
                              "Гранатовое Древо духовного роста отражает ваше ежедневное пребывание в Слове Божьем и молитве." :
                              "The Spiritual Pomegranate Tree reflects your daily walk with the Word of God and prayer."))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    
                    // 2. Карточки 5 ключевых правил
                    VStack(spacing: 12) {
                        guideRuleCard(
                            icon: "book.fill",
                            iconColor: Color(hex: "3B82F6"),
                            title: language == .armenian ? "1. Ամենօրյա ընթերցում" : (language == .russian ? "1. Ежедневное чтение Слова" : "1. Daily Word Reading"),
                            text: language == .armenian ?
                            "Ամեն օր կարդացեք Աստվածաշունչը կամ օրվա համարը: Յուրաքանչյուր օր ձեր стрик-ը մեծանում է 1-ով:" :
                            (language == .russian ?
                             "Каждый день открывайте стих дня или читайте главы Писания. Каждый день непрерывного чтения добавляет +1 день к стрику." :
                             "Read today's verse or Scripture chapters daily. Each consecutive day adds +1 to your reading streak.")
                        )
                        
                        guideRuleCard(
                            icon: "drop.fill",
                            iconColor: Color(hex: "0284C7"),
                            title: language == .armenian ? "2. Երկնային առավոտյան ցող" : (language == .russian ? "2. Небесная утренняя роса" : "2. Morning Heavenly Dew"),
                            text: language == .armenian ?
                            "Յուրաքանչյուր նոր օր ծառը ստանում է երկնային ցող: Սեղմեք «Ցողել» կամ կարդացեք համարը՝ ծառը սնելու համար:" :
                            (language == .russian ?
                             "Каждое утро дерево ожидает росы. Нажмите «Омыть» или прочтите стих дня, чтобы напитать корни благодатью." :
                             "Every morning the tree receives dew. Tap 'Water' or read the verse to nourish its holy roots.")
                        )
                        
                        guideRuleCard(
                            icon: "leaf.arrow.triangle.circlepath",
                            iconColor: Color(hex: "10B981"),
                            title: language == .armenian ? "3. 6 Սրբազան Փուլեր" : (language == .russian ? "3. 6 Ступеней роста" : "3. 6 Growth Stages"),
                            text: language == .armenian ?
                            "🌱 Սերմ (1-2 օր) ➔ 🌿 Ծիլ (3-6 օր) ➔ 🌳 Տնկի (7-13 օր) ➔ 🌺 Ծաղկած (14-29 օր) ➔ 🍎 Պտղաբեր (30-59 օր) ➔ ✨ Կենաց Ծառ (60+ օր):" :
                            (language == .russian ?
                             "🌱 Семя (1-2 дн.) ➔ 🌿 Росток (3-6 дн.) ➔ 🌳 Деревце (7-13 дн.) ➔ 🌺 Цветы (14-29 дн.) ➔ 🍎 Плоды (30-59 дн.) ➔ ✨ Древо Жизни (60+ дн.):" :
                             "🌱 Seed (1-2 d) ➔ 🌿 Sprout (3-6 d) ➔ 🌳 Young Tree (7-13 d) ➔ 🌺 Blooming (14-29 d) ➔ 🍎 Fruitful (30-59 d) ➔ ✨ Tree of Life (60+ d):")
                        )
                        
                        guideRuleCard(
                            icon: "heart.fill",
                            iconColor: Color(hex: "EF4444"),
                            title: language == .armenian ? "4. Հոգու 9 Պտուղները (Գաղ. 5:22-23)" : (language == .russian ? "4. 9 Плодов Духа (Гал. 5:22-23)" : "4. 9 Fruits of the Spirit"),
                            text: language == .armenian ?
                            "14-րդ օրվանից ծառի ճյուղերին հասունանում են նռան պտուղները: Սեղմեք նռանը՝ բացելու համար Սիրո, Խնդության, Խաղաղության օրհնությունները:" :
                            (language == .russian ?
                             "С 14 дня на ветвях созревают настоящие плоды граната. Коснитесь плода, чтобы открыть благословение Любви, Радости, Мира, Веры и других плодов Духа." :
                             "From day 14, ripe pomegranates appear on the tree. Tap any fruit to reveal holy blessings of Love, Joy, Peace, and Faith.")
                        )
                        
                        guideRuleCard(
                            icon: "shield.lefthalf.filled",
                            iconColor: Color(hex: "F59E0B"),
                            title: language == .armenian ? "5. Ողորմության Օրենք (Անմահ Ծառ)" : (language == .russian ? "5. Закон Милосердия (Дерево не умирает)" : "5. Law of Grace (Tree Never Dies)"),
                            text: language == .armenian ?
                            "Եթե բաց եք թողել մի օր, ծառը չի մահանում: Այն պարզապես սպասում է ձեր վերադարձին և արթնանում է հենց որ կարդաք Աստծո Խոսքը:" :
                            (language == .russian ?
                             "Если вы пропустили день, дерево не погибает! Оно лишь ждет росы и сразу оживает, как только вы возвращаетесь к чтению Писания." :
                             "If you miss a day, the tree does not perish! It only waits for morning dew and revives the moment you return to God's Word.")
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(language == .armenian ? "Ինչպե՞ս է աճում" : (language == .russian ? "Руководство" : "Guide"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(language == .armenian ? "Փակել" : (language == .russian ? "Понятно" : "Done")) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "EF4444"))
                }
            }
        }
    }
    
    private func guideRuleCard(icon: String, iconColor: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                
                Text(text)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(iconColor.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Модальное Окно: Детали выбранной стадии (Stage Detail View)
struct PomegranateStageDetailSheetView: View {
    let stage: PomegranateStage
    let currentStage: PomegranateStage
    let currentStreak: Int
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var isCompleted: Bool { stage < currentStage }
    private var isCurrent: Bool { stage == currentStage }
    private var isLocked: Bool { stage > currentStage }
    
    var body: some View {
        VStack(spacing: 20) {
            // Иконка стадии
            ZStack {
                Circle()
                    .fill(
                        isCurrent ? Color(hex: "EF4444").opacity(0.15) :
                        (isCompleted ? Color(hex: "10B981").opacity(0.15) : Color.gray.opacity(0.1))
                    )
                    .frame(width: 76, height: 76)
                
                Text(stageEmoji(for: stage))
                    .font(.system(size: 38))
            }
            .padding(.top, 20)
            
            VStack(spacing: 6) {
                Text(stage.title(for: language))
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                
                // Бейдж статуса
                HStack(spacing: 6) {
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10B981"))
                        Text(language == .armenian ? "Անցած փուլ" : (language == .russian ? "Пройденный этап" : "Completed Stage"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                    } else if isCurrent {
                        Image(systemName: "flame.fill")
                            .foregroundColor(Color(hex: "EF4444"))
                        Text(language == .armenian ? "Ընթացիկ փուլ" : (language == .russian ? "Текущий этап" : "Current Stage"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        let daysNeeded = max(0, stage.requiredDays - currentStreak)
                        Text(language == .armenian ? "Կբացվի \(daysNeeded) օրից" : (language == .russian ? "Откроется через \(daysNeeded) дн." : "Unlocks in \(daysNeeded) d"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(.ultraThinMaterial))
            }
            
            // Описание стадии
            VStack(spacing: 12) {
                Text(stage.description(for: language))
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "E2E8F0") : Color(hex: "334155"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                
                Divider()
                    .opacity(0.4)
                
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(language == .armenian ? "Պահանջվող ընթերցում:" : (language == .russian ? "Требуется дней в Слове:" : "Required days in Word:"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(stage.requiredDays) " + (language == .armenian ? "օր անընդմեջ" : (language == .russian ? "дней подряд" : "consecutive days")))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(language == .armenian ? "Հասանելի պտուղներ:" : (language == .russian ? "Доступно плодов:" : "Available fruits:"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(fruitsUnlocked(for: stage))/9 " + (language == .armenian ? "պտուղ" : (language == .russian ? "плодов" : "fruits")))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text(language == .armenian ? "Լավ" : (language == .russian ? "Понятно" : "Close"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "EF4444"), Color(hex: "B91C1C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private func stageEmoji(for stage: PomegranateStage) -> String {
        switch stage {
        case .seed: return "🌱"
        case .sprout: return "🌿"
        case .youngTree: return "🌳"
        case .bloomingTree: return "🌺"
        case .fruitfulTree: return "🍎"
        case .treeOfLife: return "✨"
        }
    }
    
    private func fruitsUnlocked(for stage: PomegranateStage) -> Int {
        switch stage {
        case .seed, .sprout: return 0
        case .youngTree: return 1
        case .bloomingTree: return 3
        case .fruitfulTree: return 6
        case .treeOfLife: return 9
        }
    }
}
