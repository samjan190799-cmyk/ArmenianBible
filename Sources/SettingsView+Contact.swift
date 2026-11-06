import SwiftUI
import UIKit

// MARK: - Связь с автором: WhatsApp, Instagram, Telegram
// Ссылки открываются как универсальные: если приложение мессенджера установлено, iOS открывает его,
// иначе страницу в браузере. Логотипов мессенджеров в приложении нет, поэтому значки — символы SF
// в фирменных цветах.

/// Каналы связи с автором приложения
enum AuthorContact: String, CaseIterable, Identifiable {
    case whatsapp
    case telegram
    case instagram

    var id: String { rawValue }

    var title: String {
        switch self {
        case .whatsapp: return "WhatsApp"
        case .telegram: return "Telegram"
        case .instagram: return "Instagram"
        }
    }

    /// Что видит пользователь под названием
    var handle: String {
        switch self {
        case .whatsapp: return "Samvel"
        case .telegram: return "@Samvel190799"
        case .instagram: return "@samvel_hayrapetyan190799"
        }
    }

    var url: URL? {
        switch self {
        case .whatsapp: return URL(string: "https://wa.me/qr/K3FUMUVNKESBM1")
        case .telegram: return URL(string: "https://t.me/Samvel190799")
        case .instagram: return URL(string: "https://www.instagram.com/samvel_hayrapetyan190799/")
        }
    }

    var symbol: String {
        switch self {
        case .whatsapp: return "phone.fill"
        case .telegram: return "paperplane.fill"
        case .instagram: return "camera.fill"
        }
    }

    var tint: Color {
        switch self {
        case .whatsapp: return Color(red: 0.15, green: 0.83, blue: 0.40)
        case .telegram: return Color(red: 0.13, green: 0.62, blue: 0.85)
        case .instagram: return Color(red: 0.88, green: 0.19, blue: 0.42)
        }
    }
}

extension SettingsView {
    var contactAuthorSection: some View {
        let language = selectedLanguage
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.pick(hy: "Կապ հեղինակի հետ", ru: "Связаться с автором", en: "Contact the author"))
                    .font(PaperFont.font(size: 15, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                Text(language.pick(
                    hy: "Գրեք առաջարկների, դիտողությունների կամ խնդիրների մասին. ես կարդում եմ ամեն նամակ։",
                    ru: "Пишите с предложениями, замечаниями или если что-то не работает — я читаю каждое сообщение.",
                    en: "Write with suggestions, complaints or if something doesn't work — I read every message."
                ))
                .font(PaperFont.font(size: 13))
                .foregroundColor(Paper.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                ForEach(AuthorContact.allCases) { contact in
                    contactRow(contact)
                }
            }
        }
        .padding(18)
        .background(aboutBlockBgColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(aboutBlockBorderColor, lineWidth: 1)
        )
    }

    private func contactRow(_ contact: AuthorContact) -> some View {
        Button {
            Haptics.impact(.light)
            if let url = contact.url {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(contact.tint)
                    Image(systemName: contact.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.title)
                        .font(PaperFont.font(size: 15, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    Text(contact.handle)
                        .font(PaperFont.font(size: 12))
                        .foregroundColor(Paper.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Paper.inkTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Paper.fillSubtle)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(Text("\(contact.title), \(contact.handle)"))
    }
}
