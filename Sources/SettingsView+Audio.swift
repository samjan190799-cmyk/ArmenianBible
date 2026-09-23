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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                
                Text("narek_audio_settings_title".localized(for: selectedLanguage))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                if narekPlayer.isPlaying {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "10B981"))
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "10B981").opacity(0.12))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
            
            Text("narek_audio_settings_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // 1. Скорость воспроизведения
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                            .font(.system(size: 14))
                        Text("narek_playback_rate_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                    }
                    
                    Text("narek_playback_rate_desc".localized(for: selectedLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
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
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(isSelected ? Color(hex: selectedTheme.colorHex) : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(isSelected ? Color.clear : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)), lineWidth: 1)
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
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
                
                // 2. Таймер сна
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(Color(hex: "F59E0B"))
                            .font(.system(size: 14))
                        Text("narek_sleep_timer_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                        
                        if narekPlayer.sleepTimerRemainingSeconds > 0 {
                            let mins = narekPlayer.sleepTimerRemainingSeconds / 60
                            let secs = narekPlayer.sleepTimerRemainingSeconds % 60
                            Text(String(format: "%02d:%02d", mins, secs))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "F59E0B"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "F59E0B").opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                    
                    Text("narek_sleep_timer_desc".localized(for: selectedLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
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
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .white : primaryTextColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(isSelected ? Color(hex: "F59E0B") : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04)))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(isSelected ? Color.clear : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)), lineWidth: 1)
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
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
                
                // 3. Автопереход к следующей главе
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: selectedTheme.colorHex).opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "repeat")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("narek_autoplay_next_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Text("narek_autoplay_next_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
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
                    .tint(Color(hex: selectedTheme.colorHex))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
}
