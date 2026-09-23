import SwiftUI

// MARK: - Экран Результатов Викторины
struct QuizResultView: View {
    let score: Int
    let total: Int
    let bestScore: Int
    let newlyUnlockedBadges: [AchievementBadge]
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenAchievements: () -> Void
    let onRestart: () -> Void
    
    private var resultTitle: String {
        let percentage = Double(score) / Double(total)
        if percentage >= 0.9 {
            return "quiz_result_expert".localized(for: language)
        } else if percentage >= 0.6 {
            return "quiz_result_good".localized(for: language)
        } else {
            return "quiz_result_try_again".localized(for: language)
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Если разблокированы новые награды
                if !newlyUnlockedBadges.isEmpty {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("new_badge_unlocked".localized(for: language))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.yellow)
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                        }
                        
                        ForEach(newlyUnlockedBadges) { badge in
                            HStack(spacing: 12) {
                                Image(systemName: badge.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(badge.title(for: language))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(primaryTextColor)
                                    Text(badge.description(for: language))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.yellow.opacity(0.12))
                            .cornerRadius(14)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1.2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: score >= 6 ? "sparkles" : "book.closed")
                            .font(.system(size: 38))
                            .foregroundColor(accentColor)
                    }
                    
                    Text(resultTitle)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(primaryTextColor)
                    
                    Text("\(score) / \(total)")
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(accentColor)
                    
                    Text("quiz_result_subtitle".localized(for: language))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(22)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(cardBackgroundColor)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(cardBorderColor, lineWidth: 1.2)
                )
                .padding(.horizontal, 20)
                
                // Кнопка просмотра всех наград
                Button {
                    triggerHaptic(.light)
                    onOpenAchievements()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "medal.fill")
                            .foregroundColor(.orange)
                        Text("view_all_badges".localized(for: language))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(cardBackgroundColor)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                
                // Кнопка Поделиться Результатом
                let shareText = String(format: "quiz_share_text".localized(for: language), score, total)
                ShareLink(item: shareText) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .foregroundColor(secondaryAccentColor)
                        Text("quiz_share_result".localized(for: language))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(cardBackgroundColor)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                
                Button {
                    triggerHaptic(.medium)
                    onRestart()
                } label: {
                    Text("quiz_button_play_again".localized(for: language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentColor)
                        .cornerRadius(16)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .overlay(
            Group {
                if Double(score) / Double(max(1, total)) >= 0.8 {
                    QuizConfettiView()
                        .allowsHitTesting(false)
                }
            }
        )
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

