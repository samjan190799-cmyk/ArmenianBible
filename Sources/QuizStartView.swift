import SwiftUI

// MARK: - Экран Старта Викторины
struct QuizStartView: View {
    @Binding var selectedCategory: QuizCategory
    @Binding var selectedQuestionCount: Int
    @Binding var isAIGenerationEnabled: Bool
    let bestScore: Int
    let unlockedBadgesCount: Int
    let totalBadgesCount: Int
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenAchievements: () -> Void
    let onStart: () -> Void
    
    private let counts = [5, 10, 15, 20]
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.12))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 38))
                            .foregroundColor(accentColor)
                    }
                    
                    Text("quiz_start_title".localized(for: language))
                        .font(PaperFont.font(size: 22, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    
                    Text("quiz_start_subtitle".localized(for: language))
                        .font(PaperFont.font(size: 13))
                        .foregroundColor(Paper.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 10)
                
                // Бейджи результатов и наград
                HStack(spacing: 10) {
                    if bestScore > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Paper.gold)
                            Text("quiz_best_score".localized(for: language) + ": \(bestScore)")
                                .font(PaperFont.font(size: 12, weight: .semibold).monospacedDigit())
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Paper.gold.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Button {
                        onOpenAchievements()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "medal.fill")
                                .foregroundColor(.yellow)
                            Text("\(unlockedBadgesCount)/\(totalBadgesCount) " + "achievements_btn".localized(for: language))
                                .font(PaperFont.font(size: 12, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.yellow.opacity(0.12))
                        .cornerRadius(20)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Выбор режима викторины (ИИ с адаптацией vs Офлайн база)
                VStack(alignment: .leading, spacing: 8) {
                    Text("quiz_mode_title".localized(for: language))
                        .font(PaperFont.font(size: 12, weight: .semibold))
                        .foregroundColor(Paper.inkSecondary)
                        .padding(.horizontal, 4)
                    
                    HStack(spacing: 10) {
                        Button {
                            triggerHaptic(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                isAIGenerationEnabled = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("quiz_mode_ai".localized(for: language))
                                    .font(PaperFont.font(size: 13, weight: isAIGenerationEnabled ? .semibold : .medium))
                            }
                            .foregroundColor(isAIGenerationEnabled ? Paper.onAccent : primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(isAIGenerationEnabled ? accentColor : cardBackgroundColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isAIGenerationEnabled ? accentColor : Paper.ink.opacity(0.06), lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button {
                            triggerHaptic(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                isAIGenerationEnabled = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("quiz_mode_classic".localized(for: language))
                                    .font(PaperFont.font(size: 13, weight: !isAIGenerationEnabled ? .semibold : .medium))
                            }
                            .foregroundColor(!isAIGenerationEnabled ? Paper.onAccent : primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(!isAIGenerationEnabled ? accentColor : cardBackgroundColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(!isAIGenerationEnabled ? accentColor : Paper.ink.opacity(0.06), lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Подсказка о выбранном движке
                    HStack(spacing: 6) {
                        Image(systemName: isAIGenerationEnabled ? "sparkles" : "internaldrive.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isAIGenerationEnabled ? Paper.gold : secondaryAccentColor)
                        Text(isAIGenerationEnabled ?
                             "\("quiz_mode_ai_hint".localized(for: language)) • \(QuizAIEngine.shared.currentProviderDisplayName)" :
                             "quiz_mode_classic_hint".localized(for: language))
                            .font(PaperFont.font(size: 11, weight: .medium))
                            .foregroundColor(Paper.inkSecondary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                
                // Выбор количества вопросов
                VStack(alignment: .leading, spacing: 8) {
                    Text("quiz_questions_count".localized(for: language))
                        .font(PaperFont.font(size: 12, weight: .semibold))
                        .foregroundColor(Paper.inkSecondary)
                        .padding(.horizontal, 4)
                    
                    HStack(spacing: 10) {
                        ForEach(counts, id: \.self) { count in
                            Button {
                                triggerHaptic(.light)
                                selectedQuestionCount = count
                            } label: {
                                Text("\(count) " + "quiz_count_suffix".localized(for: language))
                                    .font(PaperFont.font(size: 13, weight: selectedQuestionCount == count ? .semibold : .medium))
                                    .foregroundColor(selectedQuestionCount == count ? Paper.onAccent : primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedQuestionCount == count ? accentColor : cardBackgroundColor)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedQuestionCount == count ? accentColor : Paper.ink.opacity(0.06), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Выбор категории
                VStack(alignment: .leading, spacing: 8) {
                    Text("quiz_select_category".localized(for: language))
                        .font(PaperFont.font(size: 12, weight: .semibold))
                        .foregroundColor(Paper.inkSecondary)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 8) {
                        ForEach(QuizCategory.allCases) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(selectedCategory == cat ? accentColor : Paper.inkSecondary)
                                        .frame(width: 24)
                                    
                                    Text(cat.title(for: language))
                                        .font(PaperFont.font(size: 14, weight: selectedCategory == cat ? .semibold : .medium))
                                        .foregroundColor(primaryTextColor)
                                    
                                    Spacer()
                                    
                                    if selectedCategory == cat {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(accentColor)
                                    }
                                }
                                .padding(12)
                                .paperSheet(cornerRadius: 14)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Button {
                    onStart()
                } label: {
                    Text("quiz_button_start".localized(for: language))
                        .font(PaperFont.font(size: 16, weight: .semibold))
                        .foregroundColor(Paper.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(accentColor)
                        .cornerRadius(16)
                        .shadow(color: Paper.shadow, radius: 8, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
    }
}

