import SwiftUI

/// Специальное нативное представление экрана блокировки iPad (iPadOS 17/18) со стихами и виджетами Armenian Bible
struct iPadLockScreenShowcaseView: View {
    @ObservedObject var manager = BibleManager.shared
    
    var body: some View {
        ZStack {
            // 1. Художественный фон экрана блокировки
            WallpaperArtBackground(theme: .ararat)
            
            // Полупрозрачный градиент глубины
            LinearGradient(
                colors: [Color.black.opacity(0.2), Color.clear, Color.black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Отступ сверху под статус-бар симулятора
                Spacer().frame(height: 75)
                
                // Иконка замка Lock Screen
                Image(systemName: "lock.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
                    .padding(.bottom, 18)
                
                // Дата на армянском языке
                Text("Շաբաթ, 12 Սեպտեմբերի")
                    .font(.system(size: 28, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 3)
                    .padding(.bottom, 4)
                
                // Крупные часы iPadOS
                Text("09:41")
                    .font(.system(size: 154, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: 8)
                    .padding(.bottom, 26)
                
                // Ряд нативных виджетов экрана блокировки iPadOS
                HStack(spacing: 18) {
                    // Виджет 1: Цитата из Библии (accessoryRectangular)
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Տերն իմ լույսն է և իմ փրկությունը, ումի՞ց ես վախենամ:")
                                .font(.system(size: 17, weight: .semibold, design: .default))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .lineSpacing(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer(minLength: 0)
                            
                            HStack(spacing: 4) {
                                Text("✝")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "FDE047"))
                                Text("Սաղմոսներ 27:1")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .frame(width: 270, height: 100)
                    .background(.ultraThinMaterial)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 6)
                    
                    // Виджет 2: Круглый виджет ежедневной молитвы (accessoryCircular)
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1.2))
                        
                        VStack(spacing: 4) {
                            Image(systemName: "cross.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(Color(hex: "FDE047"))
                            Text("Օրվա խոսք")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.95))
                        }
                    }
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 6)
                    
                    // Виджет 3: Церковный календарь (accessoryRectangular)
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("📅")
                                    .font(.system(size: 12))
                                Text("13 Սեպտեմբերի")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "FDE047"))
                            }
                            
                            Text("Խաչվերացի Տոն")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer(minLength: 0)
                            
                            Text("Հայ Եկեղեցական Տոնացույց")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .frame(width: 270, height: 100)
                    .background(.ultraThinMaterial)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1.2)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 6)
                }
                
                Spacer()
                
                // Уведомление на экране блокировки со стихом дня
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cross.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "FDE047"))
                        Text("Armenian Bible • Օրվա Համար")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Text("հենց նոր")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Text("«Ամեն ինչ կարող եմ ինձ զորացնող Քրիստոսի միջոցով:»")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Փիլիպեցիս 4:13")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "FDE047"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: 580)
                .background(.ultraThinMaterial)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
                .padding(.bottom, 60)
                
                // Нижняя полоса Home Bar
                Capsule()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: 320, height: 5.5)
                    .padding(.bottom, 16)
            }
        }
        .ignoresSafeArea()
    }
}
