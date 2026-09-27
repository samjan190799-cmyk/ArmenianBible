import SwiftUI

// MARK: - Баннерная Карточка Гранатового Древа Веры на Главном Экране
struct PomegranateTreeBannerCardView: View {
    let language: AppLanguage
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onOpenSanctuary: () -> Void
    
    @ObservedObject private var treeManager = PomegranateTreeManager.shared
    
    var body: some View {
        Button {
            onOpenSanctuary()
        } label: {
            HStack(spacing: 14) {
                // 1. Живая миниатюра цветущего гранатового дерева
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "EF4444").opacity(0.12),
                                    Color(hex: "78350F").opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                    
                    PomegranateTreeView(
                        stage: treeManager.currentStage,
                        style: .compact(height: 62),
                        isThirsting: treeManager.isThirstingForDew
                    )
                }
                
                // 2. Информация о ступени духовного роста и плодах
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(language == .armenian ? "ՀՈԳԵՎՈՐ ԱՃԻ ՆՌՆԵՆԻ" : (language == .russian ? "ДРЕВО ДУХОВНОГО РОСТА" : "TREE OF SPIRITUAL GROWTH"))
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(hex: "EF4444"))
                            .tracking(0.8)
                        
                        // Бейдж утренней росы
                        if treeManager.isWateredToday {
                            HStack(spacing: 2) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 8))
                                Text(language == .armenian ? "ՑՈՂ" : (language == .russian ? "РОСА" : "DEW"))
                                    .font(.system(size: 8, weight: .heavy))
                            }
                            .foregroundColor(Color(hex: "0284C7"))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(hex: "E0F2FE"))
                            .clipShape(Capsule())
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: "drop.triangle.fill")
                                    .font(.system(size: 8))
                                Text(language == .armenian ? "ՍՊԱՍՈՒՄ Է" : (language == .russian ? "ЖДЕТ РОСЫ" : "THIRSTY"))
                                    .font(.system(size: 8, weight: .heavy))
                            }
                            .foregroundColor(Color(hex: "D97706"))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(hex: "FEF3C7"))
                            .clipShape(Capsule())
                        }
                    }
                    
                    Text(treeManager.currentStage.title(for: language))
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text("\(treeManager.daysStreak) " + (language == .armenian ? "օր Խոսքի մեջ" : (language == .russian ? "дн. в Слове" : "days in Word")))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "EF4444"))
                            Text("\(treeManager.visibleFruitsCount)/9 " + (language == .armenian ? "պտուղ" : (language == .russian ? "плодов" : "fruits")))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "EF4444"))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryTextColor.opacity(0.3))
            }
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .livingBorder(
                colors: [
                    Color(hex: "EF4444"),
                    Color(hex: "F59E0B"),
                    Color(hex: "B91C1C"),
                    Color(hex: "FDE047"),
                    Color(hex: "EF4444")
                ],
                cornerRadius: 18,
                lineWidth: 1.4,
                glowRadius: 7,
                duration: 5.5
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.96))
    }
}
