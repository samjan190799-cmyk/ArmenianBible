import SwiftUI
import WidgetKit
import LocalAuthentication

extension SettingsView {
    // MARK: - Секция «Викторина и Обучение»
    @ViewBuilder
    private var quizSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                
                Text("quiz_settings_section_title".localized(for: selectedLanguage))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            Text("quiz_settings_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // 1. Количество вопросов по умолчанию
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "number.circle.fill")
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                            .font(.system(size: 14))
                        Text("quiz_default_count_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        ForEach([5, 10, 15, 20], id: \.self) { count in
                            let isSelected = quizDefaultCount == count
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    quizDefaultCount = count
                                    manager.setQuizDefaultQuestionCount(count)
                                }
                            } label: {
                                Text("\(count)")
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
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
                
                // 2. Таймер на ответ
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(Color(hex: "F59E0B"))
                            .font(.system(size: 14))
                        Text("quiz_timer_setting_title".localized(for: selectedLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        let timerOptions: [(Int, String)] = [
                            (0, "quiz_timer_none".localized(for: selectedLanguage)),
                            (15, "quiz_timer_15s".localized(for: selectedLanguage)),
                            (30, "quiz_timer_30s".localized(for: selectedLanguage))
                        ]
                        
                        ForEach(timerOptions, id: \.0) { option in
                            let isSelected = quizTimerDuration == option.0
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    quizTimerDuration = option.0
                                    manager.setQuizTimerDuration(option.0)
                                }
                            } label: {
                                Text(option.1)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : primaryTextColor)
                                    .frame(maxWidth: .infinity)
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
                
                // 3. Звуковые эффекты
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "10B981").opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("quiz_sound_title".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Text("quiz_sound_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $quizSoundEnabled)
                        .labelsHidden()
                        .tint(Color(hex: selectedTheme.colorHex))
                        .onChange(of: quizSoundEnabled) { newVal in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                            manager.setQuizSoundEffectsEnabled(newVal)
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
                
                // 4. Сброс статистики викторины
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "EF4444").opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "EF4444"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("quiz_reset_stats_title".localized(for: selectedLanguage))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                            Text("quiz_reset_stats_desc".localized(for: selectedLanguage))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                            isShowingResetQuizAlert = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("quiz_reset_stats_btn".localized(for: selectedLanguage))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "EF4444"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "EF4444").opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    if showQuizResetToast {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "10B981"))
                                .font(.system(size: 12))
                            Text("quiz_stats_reset_toast".localized(for: selectedLanguage))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "10B981"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
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
            }
        }
        .padding(.horizontal, 4)
    }
    
}
