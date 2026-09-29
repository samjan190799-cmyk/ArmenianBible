import SwiftUI
import UIKit

// MARK: - Экран Наград и Достижений
struct BibleAchievementsView: View {
    @ObservedObject var manager = BibleManager.shared
    @ObservedObject var achievements = AchievementsManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedBadge: AchievementBadge? = nil
    
    private var accentColor: Color {
        manager.accentTheme.color
    }
    private var secondaryAccentColor: Color {
        Paper.inkSecondary
    }
    private var backgroundColor: Color {
        Paper.page
    }
    private var cardBackgroundColor: Color {
        Paper.sheet
    }
    private var primaryTextColor: Color {
        Paper.ink
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        ZStack {
            PaperBackground()
            
            VStack(spacing: 0) {
                // MARK: - Верхняя панель
                HStack {
                    Button {
                        triggerHaptic(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                    
                    Text("achievements_title".localized(for: manager.appLanguage))
                        .font(PaperFont.font(size: 18, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    // Заглушка для баланса
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // MARK: - Карточка Ранга и Прогресса
                        VStack(spacing: 14) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Paper.gold, Color.yellow],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)
                                        .shadow(color: Paper.shadow, radius: 8, y: 3)
                                    
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("your_rank".localized(for: manager.appLanguage))
                                        .font(PaperFont.font(size: 12, weight: .medium))
                                        .foregroundColor(Paper.inkSecondary)
                                    
                                    Text(achievements.userRankTitle(for: manager.appLanguage))
                                        .font(PaperFont.font(size: 18, weight: .semibold))
                                        .foregroundColor(primaryTextColor)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(achievements.unlockedCount) / \(achievements.badges.count)")
                                        .font(PaperFont.font(size: 18, weight: .semibold).monospacedDigit())
                                        .foregroundColor(Paper.gold)
                                    
                                    Text("unlocked_count".localized(for: manager.appLanguage))
                                        .font(PaperFont.font(size: 11))
                                        .foregroundColor(Paper.inkSecondary)
                                }
                            }
                            
                            // Прогресс-бар
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Paper.ink.opacity(0.08))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Paper.gold, Color.yellow],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: geo.size.width * (Double(achievements.unlockedCount) / Double(max(1, achievements.badges.count))),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(18)
                        .paperSheet(cornerRadius: 20)
                        .padding(.horizontal, 20)
                        
                        // MARK: - Сетка Значков
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(achievements.badges) { badge in
                                BadgeCardView(
                                    badge: badge,
                                    language: manager.appLanguage,
                                    primaryTextColor: primaryTextColor,
                                    cardBackgroundColor: cardBackgroundColor,
                                    onTap: {
                                        triggerHaptic(.light)
                                        selectedBadge = badge
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(
                badge: badge,
                language: manager.appLanguage,
                primaryTextColor: primaryTextColor,
                cardBackgroundColor: cardBackgroundColor
            )
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Карточка Значка в Сетке
struct BadgeCardView: View {
    let badge: AchievementBadge
    let language: AppLanguage
    let primaryTextColor: Color
    let cardBackgroundColor: Color
    let onTap: () -> Void
    
    private var gradient: LinearGradient {
        let colors = badge.gradientColors.compactMap { Color(hex: $0) }
        return LinearGradient(
            colors: colors.isEmpty ? [Color.blue, Color.purple] : colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 12) {
                // Медальон
                ZStack {
                    if badge.isUnlocked {
                        Circle()
                            .fill(gradient)
                            .frame(width: 60, height: 60)
                            .shadow(color: Color(hex: badge.gradientColors.first ?? "#F59E0B").opacity(0.4), radius: 8, y: 4)
                        
                        Image(systemName: badge.icon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(Paper.ink.opacity(0.06))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Paper.inkSecondary.opacity(0.6))
                    }
                }
                .padding(.top, 6)
                
                VStack(spacing: 4) {
                    Text(badge.title(for: language))
                        .font(PaperFont.font(size: 13, weight: .semibold))
                        .foregroundColor(badge.isUnlocked ? primaryTextColor : Paper.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(height: 34)
                    
                    if badge.isUnlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Paper.moss)
                            Text("unlocked_status".localized(for: language))
                                .font(PaperFont.font(size: 11, weight: .semibold))
                                .foregroundColor(Paper.moss)
                        }
                    } else {
                        // Прогресс
                        VStack(spacing: 3) {
                            Text("\(badge.currentProgress) / \(badge.requiredCount)")
                                .font(PaperFont.font(size: 10, weight: .semibold).monospacedDigit())
                                .foregroundColor(Paper.inkSecondary)
                            
                            ProgressView(value: badge.progressRatio)
                                .tint(Paper.gold)
                                .scaleEffect(x: 1, y: 0.6, anchor: .center)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .paperSheet(cornerRadius: 18)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Детальная шторка значка
struct BadgeDetailSheet: View {
    let badge: AchievementBadge
    let language: AppLanguage
    let primaryTextColor: Color
    let cardBackgroundColor: Color
    
    private var gradient: LinearGradient {
        let colors = badge.gradientColors.compactMap { Color(hex: $0) }
        return LinearGradient(
            colors: colors.isEmpty ? [Color.blue, Color.purple] : colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if badge.isUnlocked {
                    Circle()
                        .fill(gradient)
                        .frame(width: 74, height: 74)
                        .shadow(color: Color(hex: badge.gradientColors.first ?? "#F59E0B").opacity(0.4), radius: 10, y: 4)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .fill(Paper.ink.opacity(0.08))
                        .frame(width: 74, height: 74)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Paper.inkSecondary)
                }
            }
            .padding(.top, 10)
            
            VStack(spacing: 6) {
                Text(badge.title(for: language))
                    .font(PaperFont.font(size: 20, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                Text(badge.description(for: language))
                    .font(PaperFont.font(size: 14))
                    .foregroundColor(Paper.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            if badge.isUnlocked {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Paper.gold)
                    Text("badge_unlocked_message".localized(for: language))
                        .font(PaperFont.font(size: 13, weight: .semibold))
                        .foregroundColor(Paper.gold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Paper.gold.opacity(0.12))
                .cornerRadius(16)
            } else {
                VStack(spacing: 6) {
                    Text("\(badge.currentProgress) / \(badge.requiredCount)")
                        .font(PaperFont.font(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundColor(primaryTextColor)
                    
                    ProgressView(value: badge.progressRatio)
                        .tint(Paper.gold)
                        .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
}
