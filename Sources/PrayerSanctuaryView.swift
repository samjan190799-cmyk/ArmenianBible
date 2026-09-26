import SwiftUI

// MARK: - Главный экран Виртуального Притвора Храма (PrayerSanctuaryView)
/// Место благоговейной тишины, где верующий может зажечь свечу за близких,
/// помолиться о здравии, мире или упокоении, и поддержать развитие армянской Библии.
struct PrayerSanctuaryView: View {
    @ObservedObject private var candleManager = CandleManager.shared
    @ObservedObject private var manager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isShowingLightSheet: Bool = false
    @State private var selectedCandleForPrayer: PrayerCandle? = nil
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    init() {}
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Глубокий благоговейный фон храма
                Color(hex: "090A0F")
                    .ignoresSafeArea()
                
                // Теплое фоновое свечение лампады
                DivineBreathingGlow(color: Color(hex: "F59E0B"))
                    .offset(y: -120)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: - Хачкар и вступление
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "F59E0B").opacity(0.12))
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: "cross.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "FDE68A"), Color(hex: "F59E0B"), Color(hex: "D97706")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .padding(.top, 10)
                            
                            Text(titleText)
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(subtitleText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "D1D5DB"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 24)
                        }
                        
                        // MARK: - Большая кнопка «Зажечь свечу»
                        Button {
                            triggerHaptic(.medium)
                            isShowingLightSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                FlickeringCandleFlame(baseColor: Color(hex: "F59E0B"), iconSize: 22)
                                
                                Text(lightCandleButtonText)
                                    .font(.system(size: 16, weight: .bold, design: .serif))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FDE68A"), Color(hex: "F59E0B"), Color(hex: "D97706")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(18)
                            .shadow(color: Color(hex: "F59E0B").opacity(0.35), radius: 12, y: 5)
                            .luysShimmer(duration: 2.8)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        
                        // MARK: - Подсвечник (Храмовые свечи)
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text(activeCandlesTitle)
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "F59E0B"))
                                
                                Spacer()
                                
                                Text("\(candleManager.activeCandles.count)")
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 24)
                            
                            if candleManager.activeCandles.isEmpty {
                                emptyCandlesPlaceholder
                            } else {
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
                                    ForEach(candleManager.activeCandles) { candle in
                                        let isSelected = candleManager.selectedWidgetCandleId == candle.id.uuidString
                                        CandleStandCellView(candle: candle, language: manager.appLanguage, isSelectedForWidget: isSelected) {
                                            triggerHaptic(.light)
                                            selectedCandleForPrayer = candle
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 10)
                        
                        // Духовная записка
                        Text(spiritualNoteText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "9CA3AF"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        triggerHaptic(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $isShowingLightSheet) {
                LightCandleFormSheetView(language: manager.appLanguage)
            }
            .sheet(item: $selectedCandleForPrayer) { candle in
                CandleDetailPrayerSheetView(candle: candle, language: manager.appLanguage)
            }
            .onAppear {
                candleManager.cleanExpiredCandles()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                candleManager.cleanExpiredCandles()
            }
        }
    }
    
    // MARK: - Плейсхолдер пустого притвора
    private var emptyCandlesPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "F59E0B").opacity(0.5))
                .padding(.top, 16)
            
            Text(emptyCandlesText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(18)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Локализованные тексты
    private var titleText: String {
        switch manager.appLanguage {
        case .armenian: return "Տաճարային Մոմավառություն"
        case .russian: return "Храмовая Молитва и Свечи"
        case .english: return "Sacred Sanctuary & Vigil"
        }
    }
    
    private var subtitleText: String {
        switch manager.appLanguage {
        case .armenian: return "Վառեք մոմ սրտի լռության մեջ՝ աղոթելով հարազատների առողջության, խաղաղության կամ ննջեցյալների հոգիների համար:"
        case .russian: return "Зажгите свечу в благоговейной тишине сердца — о здравии и защите близких, о мире или об упокоении душ."
        case .english: return "Light a vigil candle in quiet prayer for the health of loved ones, peace, or in loving memory of departed souls."
        }
    }
    
    private var lightCandleButtonText: String {
        switch manager.appLanguage {
        case .armenian: return "Վառել Մոմ Աղոթքով"
        case .russian: return "Зажечь свечу с молитвой"
        case .english: return "Light a Prayer Candle"
        }
    }
    
    private var activeCandlesTitle: String {
        switch manager.appLanguage {
        case .armenian: return "ՎԱՌՎՈՂ ՄՈՄԵՐԸ"
        case .russian: return "ГОРЯЩИЕ СВЕЧИ В ПРИТВОРЕ"
        case .english: return "BURNING CANDLES IN SANCTUARY"
        }
    }
    
    private var emptyCandlesText: String {
        switch manager.appLanguage {
        case .armenian: return "Դեռևս վառված մոմեր չկան: Եղեք առաջինը, ով մոմ կվառի այսօր:"
        case .russian: return "В притворе пока нет горящих свечей. Будьте первыми, кто вознесет молитву сегодня."
        case .english: return "No active candles right now. Be the first to light a candle in prayer today."
        }
    }
    
    private var spiritualNoteText: String {
        switch manager.appLanguage {
        case .armenian: return "Ձեր նվիրատվությունն ուղղվում է Հայերեն Աստվածաշնչի պահպանմանը, աուդիո ձայնագրություններին և սերվերների աշխատանքին:"
        case .russian: return "Каждая зажженная свеча — это ваша добрая поддержка развития армянской Библии, сохранения аудиозаписей и работы серверов."
        case .english: return "Every lit candle supports the preservation of the Armenian Bible, sacred audio recordings, and server maintenance."
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Ячейка отдельной горящей свечи в подсвечнике
struct CandleStandCellView: View {
    let candle: PrayerCandle
    let language: AppLanguage
    var isSelectedForWidget: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack(alignment: .top) {
                // Мягкое свечение пламени на верхнюю часть карточки подсвечника
                RadialGradient(
                    colors: [Color(hex: "F59E0B").opacity(isSelectedForWidget ? 0.28 : 0.18), Color.clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: 85
                )
                
                VStack(spacing: 8) {
                    // Реалистичная армянская восковая свеча с живым пламенем и физическим таянием воска
                    RealisticArmenianCandleView(
                        tier: candle.tier,
                        burnProgress: candle.burnProgress(),
                        isLit: candle.isLit,
                        randomSeed: Double(abs(candle.id.hashValue))
                    )
                    .padding(.top, 8)
                    
                    // Имя близкого или название намерения
                    Text(candle.personName.isEmpty ? candle.intention.title(for: language) : candle.personName)
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                    
                    // Духовное намерение с иконкой
                    HStack(spacing: 4) {
                        Image(systemName: candle.intention.icon)
                            .font(.system(size: 9))
                        Text(candle.intention.title(for: language))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "F59E0B"))
                    .lineLimit(1)
                    
                    // Бейдж «На виджете» (если выбрана)
                    if isSelectedForWidget {
                        HStack(spacing: 3) {
                            Image(systemName: "apps.iphone")
                                .font(.system(size: 8, weight: .bold))
                            Text(language == .armenian ? "ՎԻՋԵԹՈՒՄ" : (language == .russian ? "НА ВИДЖЕТЕ" : "ON WIDGET"))
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(Color(hex: "FDE68A"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color(hex: "F59E0B").opacity(0.35))
                        .clipShape(Capsule())
                    }
                    
                    // Оставшееся время горения и бейдж
                    HStack(spacing: 4) {
                        if candle.tier == .rewarded {
                            Text("🎬")
                                .font(.system(size: 8))
                        }
                        Text(candle.remainingTimeText(for: language))
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(isSelectedForWidget ? 0.07 : 0.04))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelectedForWidget
                            ? Color(hex: "F59E0B")
                            : (candle.tier == .generous ? Color(hex: "F59E0B").opacity(0.35) : Color.white.opacity(0.08)),
                        lineWidth: isSelectedForWidget ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Лист возжжения новой свечи (LightCandleFormSheetView)
struct LightCandleFormSheetView: View {
    let language: AppLanguage
    var initialTier: CandleTier? = nil
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var candleManager = CandleManager.shared
    
    @State private var personName: String = ""
    @State private var selectedIntention: CandleIntention = .health
    @State private var selectedTier: CandleTier = .rewarded
    @State private var customPrayer: String = ""
    @State private var isShowingSuccessAnimation: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "090A0F").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // 1. Выбор духовного намерения
                        VStack(alignment: .leading, spacing: 10) {
                            Text(intentionSectionTitle)
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "F59E0B"))
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(CandleIntention.allCases) { intent in
                                    Button {
                                        triggerHaptic(.light)
                                        selectedIntention = intent
                                        customPrayer = intent.defaultPrayer(for: language)
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: intent.icon)
                                                .font(.system(size: 13, weight: .bold))
                                            Text(intent.title(for: language))
                                                .font(.system(size: 12, weight: .bold, design: .serif))
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                        .background(selectedIntention == intent ? Color(hex: "F59E0B").opacity(0.2) : Color.white.opacity(0.05))
                                        .foregroundColor(selectedIntention == intent ? Color(hex: "FDE68A") : .white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedIntention == intent ? Color(hex: "F59E0B") : Color.white.opacity(0.08), lineWidth: 1.2)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        
                        // 2. Имя близкого человека
                        VStack(alignment: .leading, spacing: 8) {
                            Text(nameSectionTitle)
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "F59E0B"))
                            
                            TextField(namePlaceholder, text: $personName)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // 3. Выбор свечи
                        VStack(alignment: .leading, spacing: 10) {
                            Text(tierSectionTitle)
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(Color(hex: "F59E0B"))
                            
                            VStack(spacing: 10) {
                                // Бесплатная ежедневная свеча
                                if !candleManager.hasUsedDailyFreeCandle {
                                    candleTierRow(tier: .freeDaily, badge: dailyFreeBadgeText)
                                }
                                // Свеча за просмотр видео
                                candleTierRow(tier: .rewarded, badge: rewardedBadgeText)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 4. Текст молитвы (с возможностью ручного написания)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(prayerSectionTitle)
                                    .font(.system(size: 13, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "F59E0B"))
                                
                                Spacer()
                                
                                // Кнопка подстановки канонической молитвы
                                Button {
                                    triggerHaptic(.light)
                                    customPrayer = selectedIntention.defaultPrayer(for: language)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "book.closed")
                                            .font(.system(size: 10))
                                        Text(canonicalPrayerButtonTitle)
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(Color(hex: "FDE68A"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "F59E0B").opacity(0.15))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                if !customPrayer.isEmpty {
                                    Button {
                                        triggerHaptic(.light)
                                        customPrayer = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                }
                            }
                            
                            // Многострочный редактор молитвы с поддержкой ручного ввода
                            ZStack(alignment: .topLeading) {
                                if customPrayer.isEmpty {
                                    Text(prayerPlaceholderText)
                                        .font(.system(size: 14, design: .serif))
                                        .foregroundColor(.white.opacity(0.35))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 14)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $customPrayer)
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .foregroundColor(.white.opacity(0.95))
                                    .lineSpacing(4)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .frame(minHeight: 100, maxHeight: 150)
                                    .padding(8)
                            }
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            
                            HStack {
                                Text(prayerHintText)
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(customPrayer.count)/500")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(customPrayer.count > 500 ? .red : .secondary.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 5. Кнопка совершения молитвы и возжжения
                        VStack(spacing: 8) {
                            Button {
                                triggerHaptic(.medium)
                                Task {
                                    let name = personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? selectedIntention.title(for: language)
                                        : personName
                                    
                                    let prayer = customPrayer.isEmpty ? selectedIntention.defaultPrayer(for: language) : customPrayer
                                    
                                    let success = await candleManager.purchaseAndLightCandle(
                                        tier: selectedTier,
                                        name: name,
                                        intention: selectedIntention,
                                        customPrayer: prayer
                                    )
                                    
                                    if success {
                                        withAnimation(.spring()) {
                                            isShowingSuccessAnimation = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                            dismiss()
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if candleManager.isPurchasing {
                                        ProgressView()
                                            .tint(.black)
                                        Text(loadingText)
                                            .font(.system(size: 15, weight: .bold, design: .serif))
                                            .foregroundColor(.black)
                                    } else {
                                        if selectedTier == .rewarded && !SubscriptionManager.shared.isPremium {
                                            Image(systemName: "play.rectangle.fill")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.black)
                                        } else {
                                            FlickeringCandleFlame(baseColor: Color(hex: "F59E0B"), iconSize: 20)
                                        }
                                        Text(submitButtonText)
                                            .font(.system(size: 16, weight: .bold, design: .serif))
                                            .foregroundColor(.black)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "FDE68A"), Color(hex: "F59E0B"), Color(hex: "D97706")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color(hex: "F59E0B").opacity(0.35), radius: 10, y: 4)
                            }
                            .disabled(candleManager.isPurchasing)
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Сообщение об ошибке или подготовке рекламы
                            if let error = candleManager.errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "F59E0B"))
                                    Text(error)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(hex: "FDE68A"))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 4)
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                
                // Оверлей благословения при успешном зажжении
                if isShowingSuccessAnimation {
                    ZStack {
                        Color.black.opacity(0.75).ignoresSafeArea()
                        VStack(spacing: 18) {
                            FlickeringCandleFlame(baseColor: Color(hex: "F59E0B"), iconSize: 48)
                            GoldenSparkBurstView(isTriggered: true)
                            Text(successTitle)
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            Text(successSubtitle)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "D1D5DB"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        triggerHaptic(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .onAppear {
                if let initialTier {
                    if initialTier == .freeDaily && candleManager.hasUsedDailyFreeCandle {
                        selectedTier = .rewarded
                    } else if initialTier == .small || initialTier == .temple || initialTier == .generous {
                        selectedTier = .rewarded
                    } else {
                        selectedTier = initialTier
                    }
                } else if !candleManager.hasUsedDailyFreeCandle {
                    selectedTier = .freeDaily
                } else {
                    selectedTier = .rewarded
                }
                if customPrayer.isEmpty {
                    customPrayer = selectedIntention.defaultPrayer(for: language)
                }
            }
        }
    }
    
    @ViewBuilder
    private func candleTierRow(tier: CandleTier, badge: String) -> some View {
        Button {
            triggerHaptic(.light)
            selectedTier = tier
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedTier == tier ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedTier == tier ? Color(hex: "F59E0B") : .white.opacity(0.3))
                    .font(.system(size: 18, weight: .bold))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.title(for: language))
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    
                    if tier == .rewarded && SubscriptionManager.shared.isPremium {
                        Text(language == .armenian ? "PRO • ԱՌԱՆՑ ԳՈՎԱԶԴԻ" : (language == .russian ? "PRO • БЕЗ РЕКЛАМЫ" : "PRO • NO ADS"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "34D399"))
                    } else {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
                }
                
                Spacer()
                
                Text(tier.priceDisplay(for: language))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
            }
            .padding(14)
            .background(selectedTier == tier ? Color(hex: "F59E0B").opacity(0.12) : Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedTier == tier ? Color(hex: "F59E0B") : Color.white.opacity(0.06), lineWidth: 1.2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Локализации формы
    private var sheetTitle: String {
        switch language {
        case .armenian: return "Մոմավառություն"
        case .russian: return "Зажжение свечи"
        case .english: return "Light Candle"
        }
    }
    private var intentionSectionTitle: String {
        switch language {
        case .armenian: return "1. ԸՆՏՐԵՔ ԱՂՈԹՔԻ ՆՊԱՏԱԿԸ"
        case .russian: return "1. ВЫБЕРИТЕ НАМЕРЕНИЕ МОЛИТВЫ"
        case .english: return "1. SELECT PRAYER INTENTION"
        }
    }
    private var nameSectionTitle: String {
        switch language {
        case .armenian: return "2. ՀԱՐԱԶԱՏԻ ԱՆՈՒՆԸ (ԿԱՄ ԱՆՈՒՆՆԵՐԸ)"
        case .russian: return "2. ИМЯ БЛИЗКОГО ЧЕЛОВЕКА (ИЛИ СЕМЬИ)"
        case .english: return "2. NAME OF LOVED ONE (OR FAMILY)"
        }
    }
    private var namePlaceholder: String {
        switch language {
        case .armenian: return "Օրինակ՝ Աննա, Արամ, ընտանիք..."
        case .russian: return "Например: Анна, Георгий, семья..."
        case .english: return "E.g. Anna, George, family..."
        }
    }
    private var tierSectionTitle: String {
        switch language {
        case .armenian: return "3. ԸՆՏՐԵՔ ՄՈՄԸ"
        case .russian: return "3. ВЫБЕРИТЕ СВЕЧУ"
        case .english: return "3. SELECT CANDLE"
        }
    }
    private var prayerSectionTitle: String {
        switch language {
        case .armenian: return "4. ԱՂՈԹՔԸ"
        case .russian: return "4. СЛОВА МОЛИТВЫ"
        case .english: return "4. PRAYER WORDS"
        }
    }
    private var dailyFreeBadgeText: String {
        switch language {
        case .armenian: return "ՕՐՎԱ ՊԱՐԳԵՎ • 12 ԺԱՄ"
        case .russian: return "ДАР ДНЯ • 12 ЧАСОВ"
        case .english: return "DAILY GIFT • 12 HOURS"
        }
    }
    private var rewardedBadgeText: String {
        switch language {
        case .armenian: return "🎬 1 ՏԵՍԱՆՅՈՒԹ • 24 ԺԱՄ"
        case .russian: return "🎬 1 ВИДЕО • 24 ЧАСА"
        case .english: return "🎬 1 VIDEO • 24 HOURS"
        }
    }
    private var loadingText: String {
        switch language {
        case .armenian: return "Բեռնում..."
        case .russian: return "Загрузка..."
        case .english: return "Loading..."
        }
    }
    private var submitButtonText: String {
        if selectedTier == .rewarded {
            if SubscriptionManager.shared.isPremium {
                switch language {
                case .armenian: return "Վառել մոմը (PRO • Առանց գովազդի)"
                case .russian: return "Зажечь свечу (PRO • Без рекламы)"
                case .english: return "Light Candle (PRO • No Ads)"
                }
            } else {
                switch language {
                case .armenian: return "🎬 Դիտել գովազդը և վառել մոմը"
                case .russian: return "🎬 Посмотреть видео и зажечь свечу"
                case .english: return "🎬 Watch Video & Light Candle"
                }
            }
        } else {
            switch language {
            case .armenian: return "Վառել օրվա մոմը"
            case .russian: return "Зажечь ежедневную свечу"
            case .english: return "Light Daily Candle"
            }
        }
    }
    private var successTitle: String {
        switch language {
        case .armenian: return "Մոմը Վառվեց"
        case .russian: return "Свеча возжена"
        case .english: return "Candle is Lit"
        }
    }
    private var successSubtitle: String {
        switch language {
        case .armenian: return "Ձեր աղոթքը բարձրացավ Աստծուն: Թող Տերը լսի և օրհնի ձեզ:"
        case .russian: return "Ваша молитва вознесена к Богу. Да благословит Господь вас и ваших близких!"
        case .english: return "Your prayer is lifted to God. May the Lord bless and protect you and your loved ones!"
        }
    }
    private var canonicalPrayerButtonTitle: String {
        switch language {
        case .armenian: return "Կանոնական"
        case .russian: return "Каноническая"
        case .english: return "Canonical"
        }
    }
    
    private var prayerPlaceholderText: String {
        switch language {
        case .armenian: return "Գրեք Ձեր սրտի աղոթքը, խնդրանքը կամ շնորհակալությունը..."
        case .russian: return "Напишите здесь молитву, прошение или благодарность от всего сердца..."
        case .english: return "Write your personal prayer, petition, or gratitude from the heart..."
        }
    }
    
    private var prayerHintText: String {
        switch language {
        case .armenian: return "Կարող եք ազատ խմբագրել կամ գրել սեփական աղոթքը"
        case .russian: return "Вы можете написать свою молитву или отредактировать текст"
        case .english: return "You can freely write or edit your own prayer"
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Карточка деталей молитвы отдельной свечи с симуляцией таяния
struct CandleDetailPrayerSheetView: View {
    let candle: PrayerCandle
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var candleManager = CandleManager.shared
    
    @State private var previewBurnProgress: Double? = nil
    @State private var isSimulatingMelting: Bool = false
    @State private var selectedDuration: Double = 4.0 // 4 секунды по умолчанию
    
    private var currentBurnProgress: Double {
        previewBurnProgress ?? candle.burnProgress()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "090A0F").ignoresSafeArea()
                DivineBreathingGlow(color: Color(hex: "F59E0B")).offset(y: -50)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Интерактивная свеча с живым пламенем и физическим таянием
                        RealisticArmenianCandleView(
                            tier: candle.tier,
                            burnProgress: currentBurnProgress,
                            isLit: currentBurnProgress < 0.99,
                            candleHeight: 68,
                            candleWidth: 22,
                            flameSize: 32,
                            randomSeed: Double(abs(candle.id.hashValue))
                        )
                        .padding(.top, 16)
                        .animation(.easeInOut(duration: isSimulatingMelting ? selectedDuration : 0.25), value: currentBurnProgress)
                        
                        Text(candle.personName.isEmpty ? candle.intention.title(for: language) : candle.personName)
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 6) {
                            Image(systemName: candle.intention.icon)
                            Text(candle.intention.title(for: language))
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                        
                        // Панель таяния свечи
                        VStack(spacing: 10) {
                            HStack {
                                Label(meltingTitleText, systemImage: "flame.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "F59E0B"))
                                
                                Spacer()
                                
                                let remainingPercent = Int(round((1.0 - currentBurnProgress) * 100))
                                Text("\(remainingPercent)% \(waxRemainingText)")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Шкала расхода воска
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(height: 5)
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FDE68A"), Color(hex: "F59E0B"), Color(hex: "EA580C")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(5, geo.size.width * CGFloat(1.0 - currentBurnProgress)), height: 5)
                                }
                            }
                            .frame(height: 5)
                            
                            // Кнопки управления анимацией таяния
                            HStack(spacing: 8) {
                                Button {
                                    startMeltingSimulation()
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: isSimulatingMelting ? "sparkles" : "play.fill")
                                            .font(.system(size: 10, weight: .bold))
                                        Text(watchMeltingText)
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color(hex: "F59E0B").opacity(0.35))
                                    .cornerRadius(10)
                                }
                                .disabled(isSimulatingMelting)
                                
                                if previewBurnProgress != nil {
                                    Button {
                                        triggerHaptic(.light)
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            previewBurnProgress = nil
                                            isSimulatingMelting = false
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(.system(size: 10, weight: .bold))
                                            Text(resetText)
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundColor(Color(hex: "9CA3AF"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                    }
                                }
                                
                                Spacer()
                                
                                // Меню выбора длительности: 3с, 4с, 8с
                                Menu {
                                    Button("3 \(secondsUnitText)") { selectedDuration = 3.0 }
                                    Button("4 \(secondsUnitText)") { selectedDuration = 4.0 }
                                    Button("8 \(secondsUnitText)") { selectedDuration = 8.0 }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 10))
                                        Text("\(Int(selectedDuration))\(secondsUnitText)")
                                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    }
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.top, 2)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                        
                        if let prayer = candle.customPrayer, !prayer.isEmpty {
                            Text(prayer)
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .padding(18)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(16)
                                .padding(.horizontal, 24)
                        }
                        
                        Text(burningTimeRemainingText)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                        
                        // Кнопка: установить эту свечу на виджет Lock Screen и Home Screen
                        let isCurrentWidgetCandle = candleManager.selectedWidgetCandleId == candle.id.uuidString
                        Button {
                            if isCurrentWidgetCandle {
                                candleManager.setSelectedWidgetCandle(id: nil) // Сброс в авторежим (последняя свеча)
                            } else {
                                candleManager.setSelectedWidgetCandle(id: candle.id.uuidString)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCurrentWidgetCandle ? "checkmark.circle.fill" : "apps.iphone")
                                    .font(.system(size: 15, weight: .bold))
                                Text(isCurrentWidgetCandle
                                     ? (language == .armenian ? "✓ Ցուցադրվում է վիջեթում" : (language == .russian ? "✓ Выбрана для виджета" : "✓ Active on Widget"))
                                     : (language == .armenian ? "Տեղադրել վիջեթում" : (language == .russian ? "Поставить на виджет" : "Set for Widget")))
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(isCurrentWidgetCandle ? Color(hex: "FDE68A") : .white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                isCurrentWidgetCandle
                                    ? Color(hex: "F59E0B").opacity(0.25)
                                    : Color.white.opacity(0.08)
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        isCurrentWidgetCandle
                                            ? Color(hex: "F59E0B")
                                            : Color.white.opacity(0.12),
                                        lineWidth: 1.2
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            dismiss()
                        } label: {
                            Text("Ամէն • Аминь")
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "FDE68A"), Color(hex: "F59E0B")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }
    
    private func startMeltingSimulation() {
        triggerHaptic(.medium)
        isSimulatingMelting = true
        previewBurnProgress = 0.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: selectedDuration)) {
                previewBurnProgress = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + selectedDuration + 0.15) {
            triggerHaptic(.success)
            isSimulatingMelting = false
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private var meltingTitleText: String {
        switch language {
        case .armenian: return "Մոմի հալվելը"
        case .russian: return "Таяние свечи"
        case .english: return "Wax Melting"
        }
    }
    
    private var waxRemainingText: String {
        switch language {
        case .armenian: return "մոմ"
        case .russian: return "воска"
        case .english: return "wax"
        }
    }
    
    private var watchMeltingText: String {
        switch language {
        case .armenian: return "Դիտել հալվելը (\(Int(selectedDuration))վ)"
        case .russian: return "Таяние за \(Int(selectedDuration)) сек"
        case .english: return "Melt in \(Int(selectedDuration))s"
        }
    }
    
    private var resetText: String {
        switch language {
        case .armenian: return "Իրական"
        case .russian: return "Реальное"
        case .english: return "Real time"
        }
    }
    
    private var secondsUnitText: String {
        switch language {
        case .armenian: return "վ"
        case .russian: return "с"
        case .english: return "s"
        }
    }
    
    private var burningTimeRemainingText: String {
        switch language {
        case .armenian: return "Կվառվի ևս \(candle.remainingTimeText(for: language))"
        case .russian: return "Горит еще \(candle.remainingTimeText(for: language))"
        case .english: return "Burns for \(candle.remainingTimeText(for: language))"
        }
    }
}
