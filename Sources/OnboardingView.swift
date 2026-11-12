import SwiftUI

// MARK: - Знакомство при первом запуске
/// Решает, показывать ли знакомство. Флаг ставит BibleManager при самом первом запуске (когда язык ещё не записан),
/// поэтому у тех, кто уже пользуется приложением, знакомства не будет.
enum OnboardingState {
    static let pendingKey = "onboarding_pending_v1"

    static var shouldShow: Bool {
        guard UserDefaults.standard.bool(forKey: pendingKey) else { return false }
        #if DEBUG || targetEnvironment(simulator)
        // Снимки экрана в CI запускают приложение на чистом симуляторе: знакомство им не нужно (если не попросить -show_onboarding)
        if !ProcessInfo.processInfo.arguments.contains("-show_onboarding") { return false }
        #endif
        return true
    }

    static func finish() {
        UserDefaults.standard.set(false, forKey: pendingKey)
    }
}

// MARK: - Три коротких экрана: язык, виджет, утренний стих
struct OnboardingView: View {
    @ObservedObject private var manager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var page = 0
    @State private var notificationsRequested = false

    private let lastPage = 2

    private var language: AppLanguage { manager.appLanguage }
    private var accent: Color { manager.accentTheme.color }

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        finish(skipped: true)
                    } label: {
                        Text(language.pick(hy: "Բաց թողնել", ru: "Пропустить", en: "Skip"))
                            .font(PaperFont.font(size: 14, weight: .medium))
                            .foregroundColor(Paper.inkSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .opacity(page < lastPage ? 1 : 0)
                    .disabled(page >= lastPage)
                }

                TabView(selection: $page) {
                    languagePage.tag(0)
                    widgetPage.tag(1)
                    versePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0...lastPage, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Paper.gold : Paper.inkTertiary.opacity(0.4))
                            .frame(width: index == page ? 22 : 8, height: 8)
                    }
                }
                .padding(.bottom, 14)
                .animation(.easeInOut(duration: 0.2), value: page)

                Button {
                    advance()
                } label: {
                    Text(primaryTitle)
                        .font(PaperFont.font(size: 17, weight: .semibold))
                        .foregroundColor(Paper.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accent)
                        .cornerRadius(18)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: 560)
        }
        .onAppear { Funnel.track("feature_used", ["feature": "onboarding_shown"]) }
    }

    // MARK: Страница 1: язык
    private var languagePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 44))
                .foregroundColor(Paper.gold)
            Text(language.pick(hy: "Ընտրեք լեզուն", ru: "Выберите язык", en: "Choose your language"))
                .font(PaperFont.font(size: 26, weight: .semibold))
                .foregroundColor(Paper.ink)
                .multilineTextAlignment(.center)
            Text(language.pick(
                hy: "Աստվածաշունչը, Նարեկացին և օգնականը կխոսեն ձեր լեզվով: Լեզուն կարելի է փոխել Կարգավորումներում:",
                ru: "Библия, Нарекаци и помощник будут на вашем языке. Язык можно сменить в «Настройках».",
                en: "The Bible, Narekatsi and the guide will speak your language. You can change it later in Settings."
            ))
            .font(PaperFont.font(size: 14))
            .foregroundColor(Paper.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)

            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases) { option in
                    Button {
                        Haptics.selection()
                        manager.setAppLanguage(option)
                    } label: {
                        HStack {
                            Text(option.displayName)
                                .font(PaperFont.font(size: 18, weight: .semibold))
                                .foregroundColor(Paper.ink)
                            Spacer()
                            Image(systemName: option == language ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(option == language ? Paper.gold : Paper.inkTertiary)
                                .font(.system(size: 20))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(option == language ? Paper.gold.opacity(0.10) : Paper.sheet)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(option == language ? Paper.gold : Paper.hairline, lineWidth: option == language ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    // MARK: Страница 2: виджет
    private var widgetPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "rectangle.3.group.fill")
                .font(.system(size: 44))
                .foregroundColor(Paper.gold)
            Text(language.pick(hy: "Խոսքը՝ ձեր էկրանին", ru: "Слово на вашем экране", en: "Scripture on your screen"))
                .font(PaperFont.font(size: 26, weight: .semibold))
                .foregroundColor(Paper.ink)
                .multilineTextAlignment(.center)
            Text(language.pick(
                hy: "Վիջեթը ամեն օր նոր համար է ցույց տալիս գլխավոր էկրանին և կողպէկրանին:",
                ru: "Виджет каждый день показывает новый стих на главном экране и на экране блокировки.",
                en: "A widget shows a new verse every day on your Home Screen and Lock Screen."
            ))
            .font(PaperFont.font(size: 14))
            .foregroundColor(Paper.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)

            VStack(alignment: .leading, spacing: 14) {
                stepRow(1, language.pick(
                    hy: "Երկար սեղմեք գլխավոր էկրանի դատարկ տեղին",
                    ru: "Нажмите и удерживайте пустое место на экране «Домой»",
                    en: "Touch and hold an empty spot on the Home Screen"))
                stepRow(2, language.pick(
                    hy: "Սեղմեք «+» վերևի անկյունում",
                    ru: "Нажмите «+» в верхнем углу",
                    en: "Tap “+” in the top corner"))
                stepRow(3, language.pick(
                    hy: "Գտեք Luys-ը և ընտրեք չափը",
                    ru: "Найдите Luys и выберите размер",
                    en: "Find Luys and pick a size"))
            }
            .padding(18)
            .paperSheet(cornerRadius: 18)
            .padding(.horizontal, 24)

            Text(language.pick(
                hy: "Կողպէկրանի համար՝ երկար սեղմեք կողպէկրանին → Հարմարեցնել",
                ru: "Для экрана блокировки: удерживайте его → «Настроить»",
                en: "For the Lock Screen: touch and hold it → Customize"))
                .font(PaperFont.font(size: 12))
                .foregroundColor(Paper.inkTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(PaperFont.font(size: 13, weight: .semibold))
                .foregroundColor(Paper.gold)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Paper.gold.opacity(0.15)))
            Text(text)
                .font(PaperFont.font(size: 14))
                .foregroundColor(Paper.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Страница 3: утренний стих
    private var versePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sunrise.fill")
                .font(.system(size: 44))
                .foregroundColor(Paper.gold)
            Text(language.pick(hy: "Առավոտյան համար", ru: "Утренний стих", en: "A morning verse"))
                .font(PaperFont.font(size: 26, weight: .semibold))
                .foregroundColor(Paper.ink)
                .multilineTextAlignment(.center)
            Text(language.pick(
                hy: "Ամեն առավոտ ժամը 8:00-ին մեկ համար՝ օրը սկսելու համար: Ժամը կարելի է փոխել Կարգավորումներում:",
                ru: "Один стих каждое утро в 8:00, чтобы начать день. Время можно поменять в «Настройках».",
                en: "One verse every morning at 8:00 to start the day. You can change the time in Settings."
            ))
            .font(PaperFont.font(size: 14))
            .foregroundColor(Paper.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)

            if notificationsRequested {
                Label(
                    language.pick(hy: "Պատրաստ է", ru: "Готово", en: "All set"),
                    systemImage: "checkmark.circle.fill"
                )
                .font(PaperFont.font(size: 15, weight: .semibold))
                .foregroundColor(Paper.moss)
            } else {
                Button {
                    enableMorningVerse()
                } label: {
                    Label(
                        language.pick(hy: "Միացնել առավոտյան համարը", ru: "Включить утренний стих", en: "Turn on the morning verse"),
                        systemImage: "bell.badge"
                    )
                    .font(PaperFont.font(size: 15, weight: .semibold))
                    .foregroundColor(Paper.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .paperField(cornerRadius: 14, stroke: Paper.gold)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            Spacer()
        }
    }

    // MARK: Действия
    private var primaryTitle: String {
        if page < lastPage {
            return language.pick(hy: "Շարունակել", ru: "Дальше", en: "Next")
        }
        return language.pick(hy: "Սկսել", ru: "Начать", en: "Get started")
    }

    private func advance() {
        Haptics.impact(.light)
        if page < lastPage {
            withAnimation(.easeInOut(duration: 0.25)) { page += 1 }
        } else {
            finish(skipped: false)
        }
    }

    private func enableMorningVerse() {
        Haptics.impact(.light)
        var parts = DateComponents()
        parts.hour = 8
        parts.minute = 0
        if let eight = Calendar.current.date(from: parts) {
            manager.setMorningNotificationTime(eight)
        }
        manager.setMorningNotificationsEnabled(true)
        notificationsRequested = true
        Funnel.track("feature_used", ["feature": "onboarding_notify"])
    }

    private func finish(skipped: Bool) {
        OnboardingState.finish()
        Funnel.track("feature_used", ["feature": skipped ? "onboarding_skipped" : "onboarding_done"])
        dismiss()
    }
}
