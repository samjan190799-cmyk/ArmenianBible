import SwiftUI
import WidgetKit
import LocalAuthentication
import Foundation

extension SettingsView {
    // MARK: - Секция «Аудиоплеер Нарекаци»
    @ViewBuilder
    var narekAudioSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок
            HStack(spacing: 8) {
                Image(systemName: "headphones")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(selectedTheme.color)
                
                Text("narek_audio_settings_title".localized(for: selectedLanguage))
                    .font(PaperFont.font(size: 15, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                if narekPlayer.isPlaying {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Paper.moss)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(PaperFont.font(size: 11, weight: .semibold))
                            .foregroundColor(Paper.moss)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Paper.moss.opacity(0.12))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
            
            Text("narek_audio_settings_desc".localized(for: selectedLanguage))
                .font(PaperFont.font(size: 13))
                .foregroundColor(Paper.inkSecondary)
                .lineSpacing(3)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // 1. Скорость воспроизведения
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(selectedTheme.color)
                            .font(.system(size: 14))
                        Text("narek_playback_rate_title".localized(for: selectedLanguage))
                            .font(PaperFont.font(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                    }
                    
                    Text("narek_playback_rate_desc".localized(for: selectedLanguage))
                        .font(PaperFont.font(size: 11))
                        .foregroundColor(Paper.inkSecondary)
                    
                    HStack(spacing: 8) {
                        let rateOptions: [(Double, String)] = [
                            (0.8, "narek_playback_rate_08".localized(for: selectedLanguage)),
                            (1.0, "narek_playback_rate_10".localized(for: selectedLanguage)),
                            (1.25, "narek_playback_rate_125".localized(for: selectedLanguage))
                        ]
                        
                        ForEach(rateOptions, id: \.0) { option in
                            let isSelected = narekPlayer.playbackRate == option.0
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    narekPlayer.setPlaybackRate(option.0)
                                }
                            } label: {
                                Text(option.1)
                                    .font(PaperFont.font(size: 12, weight: isSelected ? .semibold : .medium))
                                    .foregroundColor(isSelected ? Paper.onAccent : primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(isSelected ? selectedTheme.color : (Paper.fillMuted))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(isSelected ? Color.clear : (Paper.fillMuted), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Paper.hairline, lineWidth: 1)
                )
                
                // 2. Таймер сна
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(Paper.gold)
                            .font(.system(size: 14))
                        Text("narek_sleep_timer_title".localized(for: selectedLanguage))
                            .font(PaperFont.font(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                        
                        if narekPlayer.sleepTimerRemainingSeconds > 0 {
                            let mins = narekPlayer.sleepTimerRemainingSeconds / 60
                            let secs = narekPlayer.sleepTimerRemainingSeconds % 60
                            Text(String(format: "%02d:%02d", mins, secs))
                                .font(PaperFont.font(size: 11, weight: .semibold).monospacedDigit())
                                .foregroundColor(Paper.gold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Paper.gold.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                    
                    Text("narek_sleep_timer_desc".localized(for: selectedLanguage))
                        .font(PaperFont.font(size: 11))
                        .foregroundColor(Paper.inkSecondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(NarekSleepTimerOption.allCases) { option in
                                let isSelected = narekPlayer.sleepTimerOption == option
                                Button {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        narekPlayer.setSleepTimer(option)
                                    }
                                } label: {
                                    Text(option.title(for: selectedLanguage))
                                        .font(PaperFont.font(size: 12, weight: isSelected ? .semibold : .medium))
                                        .foregroundColor(isSelected ? Paper.onAccent : primaryTextColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(isSelected ? Paper.gold : (Paper.fillMuted))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(isSelected ? Color.clear : (Paper.fillMuted), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Paper.hairline, lineWidth: 1)
                )
                
                // 3. Автопереход к следующей главе
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(selectedTheme.color.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "repeat")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(selectedTheme.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("narek_autoplay_next_title".localized(for: selectedLanguage))
                            .font(PaperFont.font(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Text("narek_autoplay_next_desc".localized(for: selectedLanguage))
                            .font(PaperFont.font(size: 11))
                            .foregroundColor(Paper.inkSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { narekPlayer.autoPlayNextChapter },
                        set: { newVal in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                            narekPlayer.setAutoPlayNextChapter(newVal)
                        }
                    ))
                    .labelsHidden()
                    .tint(selectedTheme.color)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Paper.hairline, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
}
