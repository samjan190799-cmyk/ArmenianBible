import SwiftUI

// MARK: - Экран Книги Скорбных Песнопений Григора Нарекаци (Գրիգոր Նարեկացի)
// Содержит 2 вкладки: 📄 Текст и 🎧 Озвучка с полноценным плеером и памятью позиции
struct NarekatsiView: View {
    @ObservedObject var manager = BibleManager.shared
    @StateObject private var audioPlayer = NarekAudioPlayer.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var subTab: Int = 0 // 0: 📄 Текст, 1: 🎧 Озвучка
    @State private var shareText: String? = nil
    @State private var toastMessage: String? = nil
    @State private var searchText: String = ""
    @State private var isShowingPaywall: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var secondaryAccentColor: Color {
        Color(hex: manager.accentTheme.secondaryColorHex)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.white
    }
    
    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "0F172A")
    }
    
    private var filteredPrayers: [NarekPrayer] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return NarekatsiDatabase.shared.prayers
        }
        return NarekatsiDatabase.shared.prayers.filter { prayer in
            prayer.banNumber.lowercased().contains(trimmed) ||
            prayer.title(for: manager.appLanguage).lowercased().contains(trimmed) ||
            prayer.text(for: manager.appLanguage).lowercased().contains(trimmed) ||
            "\(prayer.id)".contains(trimmed)
        }
    }
    
    private var currentOrLastPrayer: NarekPrayer {
        let id = audioPlayer.currentlyPlayingId ?? audioPlayer.savedPrayerId
        return NarekatsiDatabase.shared.prayers.first(where: { $0.id == id }) ?? NarekatsiDatabase.shared.prayers[0]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Переключатель двух вкладок (Текст / Озвучка)
            HStack(spacing: 8) {
                // Вкладка 1: Текст
                Button {
                    triggerHaptic(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        subTab = 0
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("narek_tab_text".localized(for: manager.appLanguage))
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(subTab == 0 ? accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        subTab == 0 ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.white) : Color.clear
                    )
                    .cornerRadius(10)
                    .shadow(color: subTab == 0 ? Color.black.opacity(0.04) : Color.clear, radius: 3, y: 1)
                }
                
                // Вкладка 2: Озвучка
                Button {
                    triggerHaptic(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        subTab = 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "headphones")
                            .font(.system(size: 13, weight: .bold))
                        Text("narek_tab_audio".localized(for: manager.appLanguage))
                            .font(.system(size: 13, weight: .bold))
                        
                        if audioPlayer.isPlaying {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .foregroundColor(subTab == 1 ? accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        subTab == 1 ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.white) : Color.clear
                    )
                    .cornerRadius(10)
                    .shadow(color: subTab == 1 ? Color.black.opacity(0.04) : Color.clear, radius: 3, y: 1)
                }
            }
            .padding(4)
            .background(colorScheme == .dark ? Color.white.opacity(0.06) : Color(hex: "F1F5F9"))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // MARK: - Содержимое выбранной вкладки
            if subTab == 0 {
                // ВКЛАДКА 1: ТЕКСТОВЫЙ ВАРИАНТ
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // Поиск по 95 главам
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Поиск по 95 главам (напр. Բան Ժ или Глава 10)...", text: $searchText)
                                .font(.system(size: 14))
                                .foregroundColor(primaryTextColor)
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(cardBackgroundColor)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(cardBorderColor, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        
                        // Список 95 молитв
                        LazyVStack(spacing: 14) {
                            ForEach(filteredPrayers) { prayer in
                                let isLocked = !subscriptionManager.canPlayNarekAudio(prayerId: prayer.id)
                                NarekCardView(
                                    prayer: prayer,
                                    language: manager.appLanguage,
                                    isPlaying: audioPlayer.isPlaying && audioPlayer.currentlyPlayingId == prayer.id,
                                    isLocked: isLocked,
                                    accentColor: accentColor,
                                    secondaryAccentColor: secondaryAccentColor,
                                    cardBackgroundColor: cardBackgroundColor,
                                    cardBorderColor: cardBorderColor,
                                    primaryTextColor: primaryTextColor,
                                    onToggleAudio: {
                                        if isLocked {
                                            triggerHaptic(.medium)
                                            isShowingPaywall = true
                                        } else {
                                            triggerHaptic(.medium)
                                            audioPlayer.togglePlay(prayer: prayer, language: manager.appLanguage)
                                        }
                                    },
                                    onPinToWidget: {
                                        pinPrayerToWidget(prayer)
                                    },
                                    onCopy: {
                                        copyPrayer(prayer)
                                    },
                                    onShare: {
                                        sharePrayer(prayer)
                                    }
                                )
                            }
                            
                            // MARK: - Баннерная Реклама Meta
                            BannerAdView()
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            } else {
                // ВКЛАДКА 2: ПОЛНОЦЕННЫЙ АУДИОПЛЕЕР С ПАМЯТЬЮ
                ScrollView {
                    VStack(spacing: 18) {
                        
                        // КАРТОЧКА ГЛАВНОГО ПЛЕЕРА
                        NarekHeroPlayerCard(
                            prayer: currentOrLastPrayer,
                            audioPlayer: audioPlayer,
                            isLocked: !subscriptionManager.canPlayNarekAudio(prayerId: currentOrLastPrayer.id),
                            accentColor: accentColor,
                            secondaryAccentColor: secondaryAccentColor,
                            cardBgColor: cardBackgroundColor,
                            cardBorderColor: cardBorderColor,
                            primaryTextColor: primaryTextColor,
                            onShowPaywall: {
                                isShowingPaywall = true
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        
                        // ЗАГОЛОВОК ПЛЕЙЛИСТА
                        HStack {
                            Text("narek_playlist_title".localized(for: manager.appLanguage))
                                .font(.system(size: 16, weight: .bold, design: .serif))
                                .foregroundColor(primaryTextColor)
                            Spacer()
                            Text("narek_prayers_count".localized(for: manager.appLanguage))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        // СПИСОК ГЛАВ В ПЛЕЙЛИСТЕ
                        LazyVStack(spacing: 10) {
                            ForEach(NarekatsiDatabase.shared.prayers) { prayer in
                                let isCurrent = (audioPlayer.currentlyPlayingId == prayer.id) ||
                                                (audioPlayer.currentlyPlayingId == nil && audioPlayer.savedPrayerId == prayer.id)
                                let isThisPlaying = audioPlayer.isPlaying && audioPlayer.currentlyPlayingId == prayer.id
                                let isChapterLocked = !subscriptionManager.canPlayNarekAudio(prayerId: prayer.id)
                                
                                Button {
                                    triggerHaptic(.light)
                                    if isChapterLocked {
                                        isShowingPaywall = true
                                    } else {
                                        audioPlayer.playPrayer(prayer, language: audioPlayer.voiceLanguage)
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        // Индикатор воспроизведения
                                        ZStack {
                                            Circle()
                                                .fill(isCurrent ? accentColor.opacity(0.2) : (colorScheme == .dark ? Color.white.opacity(0.06) : Color(hex: "F1F5F9")))
                                                .frame(width: 42, height: 42)
                                            
                                            if isThisPlaying {
                                                Image(systemName: "waveform")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(accentColor)
                                            } else if isChapterLocked {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(Color(hex: "F59E0B"))
                                            } else {
                                                Text("\(prayer.id)")
                                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                                    .foregroundColor(isCurrent ? accentColor : (colorScheme == .dark ? Color(hex: "94A3B8") : Color(hex: "64748B")))
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                Text(prayer.banNumber)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(isCurrent ? accentColor : primaryTextColor)
                                                
                                                if isChapterLocked {
                                                    Text("PREMIUM")
                                                        .font(.system(size: 9, weight: .black))
                                                        .foregroundColor(.black)
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 2)
                                                        .background(Color(hex: "FDE68A"))
                                                        .cornerRadius(4)
                                                } else {
                                                    Text("• \(prayer.formattedTimestamp(for: audioPlayer.voiceLanguage))")
                                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                        .foregroundColor(isCurrent ? accentColor.opacity(0.9) : .secondary)
                                                }
                                            }
                                            
                                            Text(prayer.title(for: audioPlayer.voiceLanguage))
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(isCurrent ? primaryTextColor : .secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        if isChapterLocked {
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(Color(hex: "F59E0B"))
                                        } else {
                                            Image(systemName: isThisPlaying ? "pause.circle.fill" : (isCurrent ? "play.circle.fill" : "play.circle"))
                                                .font(.system(size: 24))
                                                .foregroundColor(isCurrent ? accentColor : Color.secondary.opacity(0.5))
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(isCurrent ? accentColor.opacity(0.08) : cardBackgroundColor)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isCurrent ? accentColor.opacity(0.8) : cardBorderColor, lineWidth: isCurrent ? 1.5 : 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            
                            // MARK: - Баннерная Реклама Meta
                            BannerAdView()
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .overlay(
            VStack {
                if let msg = toastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(msg)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cardBackgroundColor)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 10)
                }
                Spacer()
            }
            .animation(.spring(), value: toastMessage)
        )
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: Binding(
            get: { shareText != nil },
            set: { if !$0 { shareText = nil } }
        )) {
            if let txt = shareText {
                ActivityView(activityItems: [txt])
            }
        }
    }
    
    // MARK: - Хелперы
    
    private func pinPrayerToWidget(_ prayer: NarekPrayer) {
        triggerHaptic(.medium)
        manager.pinVerseToWidget(
            textHy: prayer.textHy,
            textRu: prayer.textRu,
            textEn: prayer.textEn,
            refHy: prayer.banNumber,
            refRu: prayer.banNumber,
            refEn: prayer.banNumber
        )
        showToast("Աղոթքը տեղադրվեց Վիջեթում 📌")
    }
    
    private func copyPrayer(_ prayer: NarekPrayer) {
        triggerHaptic(.light)
        UIPasteboard.general.string = "\(prayer.title(for: manager.appLanguage))\n\n\(prayer.text(for: manager.appLanguage))"
        showToast("Պատճենված է 📋")
    }
    
    private func sharePrayer(_ prayer: NarekPrayer) {
        triggerHaptic(.light)
        shareText = "«\(prayer.title(for: manager.appLanguage))»\n\n\(prayer.text(for: manager.appLanguage))\n\n(Գրիգոր Նարեկացի — Մատյան Ողբերգության)"
    }
    
    private func showToast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toastMessage == msg {
                toastMessage = nil
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Главная Карточка Аудиоплеера Нарекаци (Hero Player Card)

struct NarekHeroPlayerCard: View {
    let prayer: NarekPrayer
    @ObservedObject var audioPlayer: NarekAudioPlayer
    let isLocked: Bool
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBgColor: Color
    let cardBorderColor: Color
    let primaryTextColor: Color
    let onShowPaywall: () -> Void
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Шапка плеера: Номер главы + Выбор голоса
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(prayer.banNumber)
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundColor(accentColor)
                        
                        if isLocked {
                            Text("👑 PREMIUM")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "FDE68A"))
                                .cornerRadius(5)
                        } else if audioPlayer.isStreaming {
                            Text("narek_loading_audio".localized(for: audioPlayer.voiceLanguage))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(prayer.title(for: audioPlayer.voiceLanguage))
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Переключатель голоса: Сос Саргсян / Олег Моленко
                Menu {
                    Button {
                        audioPlayer.voiceLanguage = .armenian
                        if !isLocked {
                            audioPlayer.play(prayer: prayer, language: .armenian)
                        }
                    } label: {
                        Label("🇦🇲 Սոս Սարգսյան (Հայերեն)", systemImage: audioPlayer.voiceLanguage == .armenian ? "checkmark" : "")
                    }
                    
                    Button {
                        audioPlayer.voiceLanguage = .russian
                        if !isLocked {
                            audioPlayer.play(prayer: prayer, language: .russian)
                        }
                    } label: {
                        Label("🇷🇺 Олег Моленко (Русский)", systemImage: audioPlayer.voiceLanguage == .russian ? "checkmark" : "")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(audioPlayer.voiceLanguage == .armenian ? "🇦🇲 Սոս Ս." : "🇷🇺 О. Моленко")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.12))
                    .foregroundColor(accentColor)
                    .cornerRadius(8)
                }
            }
            
            // Бегунок времени (Seek bar)
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { audioPlayer.currentTime },
                        set: { newVal in
                            if !isLocked {
                                audioPlayer.seek(to: newVal)
                            }
                        }
                    ),
                    in: 0...max(audioPlayer.duration, 1.0)
                )
                .tint(accentColor)
                .disabled(isLocked)
                
                HStack {
                    Text(formatTime(audioPlayer.currentTime))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(audioPlayer.duration > 0 ? formatTime(audioPlayer.duration) : "--:--")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            // Кнопки управления воспроизведением
            HStack(spacing: 24) {
                // Предыдущая глава
                Button {
                    audioPlayer.playPreviousPrayer()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 18))
                        .foregroundColor(primaryTextColor)
                }
                
                // Перемотка назад на 15 сек
                Button {
                    if !isLocked {
                        audioPlayer.skipBackward(seconds: 15)
                    }
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 20))
                        .foregroundColor(primaryTextColor)
                }
                
                // Главная кнопка Play / Pause
                Button {
                    if isLocked {
                        onShowPaywall()
                    } else {
                        audioPlayer.togglePlay(prayer: prayer)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                isLocked ?
                                LinearGradient(
                                    colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [accentColor, secondaryAccentColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                            .shadow(color: (isLocked ? Color(hex: "F59E0B") : accentColor).opacity(0.4), radius: 8, y: 4)
                        
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: audioPlayer.isPlaying ? 0 : 2)
                        }
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Перемотка вперед на 15 сек
                Button {
                    if !isLocked {
                        audioPlayer.skipForward(seconds: 15)
                    }
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 20))
                        .foregroundColor(primaryTextColor)
                }
                
                // Следующая глава
                Button {
                    audioPlayer.playNextPrayer()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 18))
                        .foregroundColor(primaryTextColor)
                }
            }
            .padding(.vertical, 4)
            
            // Индикатор запоминания позиции
            if audioPlayer.savedTimeSeconds > 0 && !audioPlayer.isPlaying {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 11))
                        .foregroundColor(accentColor)
                    Text(String(format: "narek_saved_position_format".localized(for: audioPlayer.voiceLanguage), formatTime(audioPlayer.savedTimeSeconds), audioPlayer.savedPrayerId))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(18)
        .background(cardBgColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}

// MARK: - Карточка текстовой молитвы Нарекаци (NarekCardView)

struct NarekCardView: View {
    let prayer: NarekPrayer
    let language: AppLanguage
    let isPlaying: Bool
    let isLocked: Bool
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: Color
    let primaryTextColor: Color
    
    let onToggleAudio: () -> Void
    let onPinToWidget: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // Верхняя строка карточки: Номер главы + Кнопка прослушивания
            HStack {
                Text(prayer.banNumber)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.12))
                    .cornerRadius(8)
                
                Spacer()
                
                // Кнопка быстрого воспроизведения
                Button {
                    onToggleAudio()
                } label: {
                    HStack(spacing: 5) {
                        if isLocked {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Text("narek_listen_pro".localized(for: language))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(isPlaying ? "narek_stop".localized(for: language) : "narek_listen_prayer".localized(for: language))
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundColor(isLocked ? .white : (isPlaying ? .white : accentColor))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        isLocked ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "D97706")], startPoint: .leading, endPoint: .trailing)) :
                        (isPlaying ? AnyShapeStyle(Color.red) : AnyShapeStyle(accentColor.opacity(0.12)))
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Заголовок главы
            Text(prayer.title(for: language))
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            
            // Текст молитвы
            Text(prayer.text(for: language))
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(primaryTextColor.opacity(0.9))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            
            // Нижняя панель действий (Виджет, Копировать, Поделиться)
            HStack {
                Text("saint_gregory_narekatsi".localized(for: language))
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundColor(accentColor.opacity(0.8))
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        onPinToWidget()
                    } label: {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        onCopy()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        onShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 6)
        }
        .padding(18)
        .background(cardBackgroundColor)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }
}
