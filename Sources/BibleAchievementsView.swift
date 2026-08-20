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
        Color(hex: manager.accentTheme.colorHex)
    }
    private var secondaryAccentColor: Color {
        Color(hex: manager.accentTheme.secondaryColorHex)
    }
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.85)
    }
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            // Фоновое неоновое свечение
            RadialGradient(
                gradient: Gradient(colors: [Color.yellow.opacity(colorScheme == .dark ? 0.08 : 0.05), Color.clear]),
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
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
                        .font(.system(size: 18, weight: .bold))
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
                                                colors: [Color.orange, Color.yellow],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)
                                        .shadow(color: Color.orange.opacity(0.35), radius: 8, y: 3)
                                    
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("your_rank".localized(for: manager.appLanguage))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text(achievements.userRankTitle(for: manager.appLanguage))
                                        .font(.system(size: 18, weight: .bold, design: .serif))
                                        .foregroundColor(primaryTextColor)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(achievements.unlockedCount) / \(achievements.badges.count)")
                                        .font(.system(size: 18, weight: .black, design: .monospaced))
                                        .foregroundColor(Color.orange)
                                    
                                    Text("unlocked_count".localized(for: manager.appLanguage))
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Прогресс-бар
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.08))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange, Color.yellow],
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
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(cardBackgroundColor)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
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
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(Color.primary.opacity(0.06))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .padding(.top, 6)
                
                VStack(spacing: 4) {
                    Text(badge.title(for: language))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(badge.isUnlocked ? primaryTextColor : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(height: 34)
                    
                    if badge.isUnlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("unlocked_status".localized(for: language))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    } else {
                        // Прогресс
                        VStack(spacing: 3) {
                            Text("\(badge.currentProgress) / \(badge.requiredCount)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: badge.progressRatio)
                                .tint(Color.orange)
                                .scaleEffect(x: 1, y: 0.6, anchor: .center)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(badge.isUnlocked ? Color.orange.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1.2)
            )
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
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 74, height: 74)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 10)
            
            VStack(spacing: 6) {
                Text(badge.title(for: language))
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(primaryTextColor)
                
                Text(badge.description(for: language))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            if badge.isUnlocked {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                    Text("badge_unlocked_message".localized(for: language))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(16)
            } else {
                VStack(spacing: 6) {
                    Text("\(badge.currentProgress) / \(badge.requiredCount)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(primaryTextColor)
                    
                    ProgressView(value: badge.progressRatio)
                        .tint(Color.orange)
                        .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
}
