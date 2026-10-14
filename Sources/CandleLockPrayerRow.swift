import SwiftUI
import WidgetKit

// MARK: - Молитва на экране блокировки: выключатель приватности
/// Остров и виджет на экране блокировки видны без разблокировки, поэтому текст молитвы там показывается
/// только с разрешения человека. Значение лежит в общем хранилище: его читают и остров, и виджет.
/// Большие и средние виджеты дополнительно помечены privacySensitive: заблокированное устройство
/// (в том числе в режиме StandBy) закрывает их текст само.
struct CandleLockPrayerRow: View {
    let language: AppLanguage

    @State private var isOn = AppGroupConstants.sharedBool(forKey: CandleConstants.showPrayerOnLockKey)

    var body: some View {
        Toggle(isOn: Binding(
            get: { isOn },
            set: { newValue in
                isOn = newValue
                AppGroupConstants.syncToAll { $0.set(newValue, forKey: CandleConstants.showPrayerOnLockKey) }
                WidgetCenter.shared.reloadAllTimelines()
            }
        )) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Paper.plum.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Paper.plum)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.pick(
                        hy: "Աղոթքը կողպման էկրանին",
                        ru: "Молитва на экране блокировки",
                        en: "Prayer on the Lock Screen"
                    ))
                    .font(PaperFont.font(size: 14, weight: .semibold))
                    .foregroundColor(Paper.ink)
                    Text(language.pick(
                        hy: "Ցուցադրել աղոթքի սկիզբը Dynamic Island-ում և կողպման էկրանի վիջեթում առանց ապակողպելու",
                        ru: "Показывать начало молитвы в острове и виджете на экране блокировки без разблокировки. Выключено: видны только имя и время горения",
                        en: "Show the start of the prayer in the island and lock-screen widget without unlocking. Off: only the name and burn time are visible"
                    ))
                    .font(PaperFont.font(size: 11.5))
                    .foregroundColor(Paper.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                }
            }
        }
        .tint(Paper.gold)
    }
}
