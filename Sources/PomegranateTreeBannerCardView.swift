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
                        .fill(Paper.page)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Paper.hairline, lineWidth: 1)
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
                            .font(PaperFont.font(size: 10, weight: .semibold))
                            .foregroundColor(Paper.cinnabar)
                            .tracking(1.2)
                        
                        // Бейдж утренней росы
                        if treeManager.isWateredToday {
                            HStack(spacing: 2) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 8))
                                Text(language == .armenian ? "ՑՈՂ" : (language == .russian ? "РОСА" : "DEW"))
                                    .font(PaperFont.font(size: 8, weight: .semibold))
                            }
                            .foregroundColor(Paper.inkSecondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .overlay(Capsule().strokeBorder(Paper.hairline, lineWidth: 0.8))
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: "drop.triangle.fill")
                                    .font(.system(size: 8))
                                Text(language == .armenian ? "ՍՊԱՍՈՒՄ Է" : (language == .russian ? "ЖДЕТ РОСЫ" : "THIRSTY"))
                                    .font(PaperFont.font(size: 8, weight: .semibold))
                            }
                            .foregroundColor(Paper.gold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .overlay(Capsule().strokeBorder(Paper.gold.opacity(0.5), lineWidth: 0.8))
                        }
                    }
                    
                    Text(treeManager.currentStage.title(for: language))
                        .font(PaperFont.font(size: 17, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text("\(treeManager.daysStreak) " + (language == .armenian ? "օր Խոսքի մեջ" : (language == .russian ? "дн. в Слове" : "days in Word")))
                            .font(PaperFont.font(size: 12))
                            .foregroundColor(Paper.inkSecondary)
                        
                        Text("•")
                            .font(PaperFont.font(size: 10))
                            .foregroundColor(Paper.inkTertiary)
                        
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Paper.cinnabar)
                            Text("\(treeManager.visibleFruitsCount)/9 " + (language == .armenian ? "պտուղ" : (language == .russian ? "плодов" : "fruits")))
                                .font(PaperFont.font(size: 12, weight: .medium))
                                .foregroundColor(Paper.cinnabar)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Paper.inkTertiary)
            }
            .padding(14)
            .paperSheet(cornerRadius: 18)
            .padding(.horizontal, 20)
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.96))
    }
}
