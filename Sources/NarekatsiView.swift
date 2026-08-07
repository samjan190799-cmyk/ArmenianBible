import SwiftUI

// MARK: - Экран Книги Сկորբնիխ Песнопений Григора Нарекаци (Գրիգոր Նարեկացի)
struct NarekatsiView: View {
    @ObservedObject var manager = BibleManager.shared
    @StateObject private var audioPlayer = NarekAudioPlayer.shared
    
    @State private var shareItem: ShareItem? = nil
    @State private var toastMessage: String? = nil
    
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
        colorScheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.85)
    }
    
    private var cardBorderColor: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.14), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                
                // MARK: - Заголовок Нарекаци
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20))
                            .foregroundColor(accentColor)
                        
                        Text("narekatsi_title".localized(for: manager.appLanguage))
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(primaryTextColor)
                    }
                    
                    Text("narekatsi_subtitle".localized(for: manager.appLanguage))
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(secondaryAccentColor)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 40, height: 1)
                        Image(systemName: "cross.fill")
                            .font(.system(size: 10))
                            .foregroundColor(accentColor.opacity(0.7))
                        Rectangle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 40, height: 1)
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                
                // MARK: - Список молитв Нарекаци
                LazyVStack(spacing: 18) {
                    ForEach(NarekatsiDatabase.shared.prayers) { prayer in
                        NarekCardView(
                            prayer: prayer,
                            language: manager.appLanguage,
                            isPlaying: audioPlayer.isPlaying && audioPlayer.currentlyPlayingId == prayer.id,
                            accentColor: accentColor,
                            secondaryAccentColor: secondaryAccentColor,
                            cardBackgroundColor: cardBackgroundColor,
                            cardBorderColor: cardBorderColor,
                            primaryTextColor: primaryTextColor,
                            onToggleAudio: {
                                triggerHaptic(.medium)
                                audioPlayer.speak(prayer: prayer, language: manager.appLanguage)
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
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
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(20)
                    .shadow(radius: 6)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.3), value: toastMessage != nil)
        )
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func pinPrayerToWidget(_ prayer: NarekPrayer) {
        triggerHaptic(.medium)
        let refHy = "Գրիգոր Նարեկացի (\(prayer.banNumber))"
        let refRu = "Св. Григор Нарекаци (\(prayer.banNumber))"
        let refEn = "St. Grigor Narekatsi (\(prayer.banNumber))"
        
        manager.pinVerseToWidget(
            textHy: prayer.textHy,
            textRu: prayer.textRu,
            textEn: prayer.textEn,
            refHy: refHy,
            refRu: refRu,
            refEn: refEn
        )
        showToast(message: "toast_pinned_to_widget".localized(for: manager.appLanguage))
    }
    
    private func copyPrayer(_ prayer: NarekPrayer) {
        triggerHaptic(.light)
        let textToCopy = "\(prayer.title(for: manager.appLanguage))\n\n\(prayer.text(for: manager.appLanguage))\n— Գրիգոր Նարեկացի"
        UIPasteboard.general.string = textToCopy
        showToast(message: "copied_to_clipboard".localized(for: manager.appLanguage))
    }
    
    private func showToast(message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
    
    @MainActor
    private func sharePrayer(_ prayer: NarekPrayer) {
        triggerHaptic(.medium)
        let ref = "Գրիգոր Նարեկացի (\(prayer.banNumber))"
        let cardView = PostcardRenderView(
            text: prayer.text(for: manager.appLanguage),
            reference: ref,
            themeHex: manager.accentTheme.colorHex
        )
        
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            shareItem = ShareItem(image: image)
        }
    }
}

// MARK: - Карточка молитвы Нарекаци
struct NarekCardView: View {
    let prayer: NarekPrayer
    let language: AppLanguage
    let isPlaying: Bool
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    
    let onToggleAudio: () -> Void
    let onPinToWidget: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(prayer.banNumber)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.12))
                    .cornerRadius(8)
                
                Spacer()
                
                // Кнопка Аудио-Озвучки
                Button {
                    onToggleAudio()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPlaying ? "waveform" : "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(isPlaying ? "button_pause_audio".localized(for: language) : "button_listen_audio".localized(for: language))
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(isPlaying ? .white : accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isPlaying ? accentColor : accentColor.opacity(0.12))
                    .cornerRadius(20)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Text(prayer.title(for: language))
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundColor(primaryTextColor)
            
            Text(prayer.text(for: language))
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(primaryTextColor.opacity(0.9))
                .lineSpacing(6)
            
            Divider()
                .opacity(0.15)
            
            HStack {
                Text("Գրիգոր Նարեկացի")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(secondaryAccentColor)
                
                Spacer()
                
                // Денйствия: Закрепить на виджете, Скопировать, Поделиться
                HStack(spacing: 12) {
                    Button {
                        onPinToWidget()
                    } label: {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryAccentColor)
                            .padding(8)
                            .background(secondaryAccentColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        onCopy()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                            .padding(8)
                            .background(primaryTextColor.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        onShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                            .padding(8)
                            .background(primaryTextColor.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackgroundColor)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }
}

// MARK: - Рендер открытки молитв Нарекаци для экспорта
struct PostcardRenderView: View {
    let text: String
    let reference: String
    let themeHex: String
    
    private var accentColor: Color {
        Color(hex: themeHex)
    }
    
    var body: some View {
        ZStack {
            Color(hex: "090A0F")
            
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(0.18), Color.clear]),
                center: .center,
                startRadius: 50,
                endRadius: 450
            )
            
            VStack(spacing: 32) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 52))
                    .foregroundColor(accentColor)
                
                Text(text)
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(12)
                    .padding(.horizontal, 48)
                
                Text(reference)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
                
                Text("Armenian Bible App • Գրիգոր Նարեկացի")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(48)
        }
        .frame(width: 800, height: 800)
    }
}

