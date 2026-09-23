import SwiftUI
import WidgetKit
import LocalAuthentication

// MARK: - Строка сообщения чата (Bubble Row)

struct AIChatBubbleRow: View {
    let message: AIChatMessage
    @ObservedObject var manager: BibleManager
    let accentColor: Color
    let secondaryAccentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let onShareVerse: (BibleVerse) -> Void
    let onCopy: (String) -> Void
    
    @State private var isHeartBouncing = false
    
    var body: some View {
        if message.isUser {
            // Сообщение пользователя (справа)
            HStack {
                Spacer(minLength: 44)
                
                Text(message.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: accentColor.opacity(0.25), radius: 6, y: 3)
            }
        } else {
            // Ответ Духовного Помощника (слева)
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    // Заголовок карточки ответа
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentColor)
                        Text("ai_guide_title".localized(for: manager.appLanguage))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentColor)
                        
                        Spacer()
                        
                        // Кнопка копирования ответа
                        Button {
                            onCopy(message.text)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    Text(message.text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(primaryTextColor)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Если есть цитируемый стих
                    if let verse = message.verse {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "laurel.leading")
                                    .font(.system(size: 18))
                                    .foregroundColor(secondaryAccentColor.opacity(0.7))
                                Spacer()
                                Image(systemName: "laurel.trailing")
                                    .font(.system(size: 18))
                                    .foregroundColor(secondaryAccentColor.opacity(0.7))
                            }
                            
                            Text(verse.text)
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundColor(primaryTextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(5)
                            
                            Text(verse.reference)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(secondaryAccentColor)
                            
                            // Кнопки управления стихом
                            HStack(spacing: 18) {
                                // Добавить в Избранное
                                Button {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                                        if manager.isFavorite(verse) {
                                            manager.removeFromFavorites(verse)
                                        } else {
                                            manager.addToFavorites(verse)
                                            isHeartBouncing = true
                                        }
                                    }
                                    if isHeartBouncing {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                                            withAnimation(.easeOut(duration: 0.15)) {
                                                isHeartBouncing = false
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: manager.isFavorite(verse) ? "heart.fill" : "heart")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(manager.isFavorite(verse) ? .red : primaryTextColor.opacity(0.5))
                                        .scaleEffect(isHeartBouncing ? 1.3 : 1.0)
                                        .padding(8)
                                        .background(primaryTextColor.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                // Поделиться открыткой
                                Button {
                                    onShareVerse(verse)
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(primaryTextColor.opacity(0.5))
                                        .padding(8)
                                        .background(primaryTextColor.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                // Скопировать стих
                                Button {
                                    onCopy("\(verse.text)\n— \(verse.reference)")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(primaryTextColor.opacity(0.5))
                                        .padding(8)
                                        .background(primaryTextColor.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(cardBackgroundColor.opacity(0.6))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
                .padding(16)
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
                        .stroke(cardBorderColor, lineWidth: 1.2)
                )
                
                Spacer(minLength: 32)
            }
        }
    }
}

// MARK: - Индикатор размышления ИИ (Thinking Bubble)

struct AIChatThinkingRow: View {
    let language: AppLanguage
    let accentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(accentColor)
                    .scaleEffect(0.9)
                
                Text("ai_searching_answer".localized(for: language))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1)
            )
            .transition(.scale(scale: 0.92).combined(with: .opacity))
            
            Spacer(minLength: 40)
        }
    }
}

// MARK: - ЭКРАН ТОЛКОВАНИЯ (Explanation View)
