import SwiftUI

// MARK: - Тексты дуэли на трёх языках
enum QuizDuelText {
    static func opponent(_ name: String?, _ language: AppLanguage) -> String {
        name ?? language.pick(hy: "Մրցակից", ru: "Соперник", en: "Opponent")
    }

    static func categoryLine(_ duel: QuizDuel, _ language: AppLanguage) -> String {
        let count = language.pick(hy: "\(duel.n) հարց", ru: "\(duel.n) вопросов", en: "\(duel.n) questions")
        return count + " · " + duel.category.title(for: language)
    }

    /// Итог для того, чей счёт `mine`, против `theirs`
    static func verdict(mine: Int, theirs: Int, _ language: AppLanguage) -> String {
        if mine > theirs {
            return language.pick(hy: "Դուք հաղթեցիք", ru: "Вы победили", en: "You won")
        }
        if mine < theirs {
            let gap = theirs - mine
            return language.pick(hy: "Մրցակիցը առաջ է \(gap) միավորով", ru: "Соперник впереди на \(gap)", en: "Your opponent leads by \(gap)")
        }
        return language.pick(hy: "Ոչ-ոքի", ru: "Ничья", en: "A draw")
    }

    /// Сообщение со ссылкой: вызов (счёт у одного) или ответ (счёт у обоих)
    static func shareMessage(for duel: QuizDuel, url: URL, _ language: AppLanguage) -> String {
        let n = duel.n
        let text: String
        if let q = duel.q, let r = duel.r {
            text = language.pick(
                hy: "Մենամարտը կայացավ: Ինձ՝ \(q)/\(n), քեզ՝ \(r)/\(n): Ռեվանշ՞",
                ru: "Дуэль сыграна! У меня \(q) из \(n), у тебя \(r). Реванш?",
                en: "Duel played! I scored \(q) of \(n), you \(r). Rematch?"
            )
        } else {
            let r = duel.r ?? 0
            text = language.pick(
                hy: "Խաղանք Աստվածաշնչի վիկտորինա: Իմ արդյունքը՝ \(r)/\(n): Կհաղթե՞ս:",
                ru: "Сыграем в библейскую викторину? Мой счёт: \(r) из \(n). Побьёшь?",
                en: "Shall we play a Bible quiz? My score: \(r) of \(n). Can you beat it?"
            )
        }
        return text + "\n" + url.absoluteString
    }
}

// MARK: - Приглашение: друг бросил вызов
struct QuizDuelInviteView: View {
    let duel: QuizDuel
    let language: AppLanguage
    let accentColor: Color
    let primaryTextColor: Color
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 10)
            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 46))
                .foregroundColor(accentColor)
            Text(language.pick(hy: "Մենամարտի հրավեր", ru: "Вызов на дуэль", en: "A duel challenge"))
                .font(PaperFont.font(size: 22, weight: .semibold))
                .foregroundColor(primaryTextColor)
            Text(language.pick(
                hy: "\(QuizDuelText.opponent(duel.a, language))-ը Ձեզ հրավիրում է Աստվածաշնչի վիկտորինայի",
                ru: "\(QuizDuelText.opponent(duel.a, language)) вызывает вас на библейскую викторину",
                en: "\(QuizDuelText.opponent(duel.a, language)) challenges you to a Bible quiz"
            ))
            .font(PaperFont.font(size: 15))
            .foregroundColor(Paper.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)

            VStack(spacing: 6) {
                Text("\(duel.r ?? 0) / \(duel.n)")
                    .font(PaperFont.font(size: 34, weight: .semibold).monospacedDigit())
                    .foregroundColor(Paper.gold)
                Text(language.pick(hy: "Մրցակցի արդյունքը", ru: "Счёт соперника", en: "Opponent's score"))
                    .font(PaperFont.font(size: 12))
                    .foregroundColor(Paper.inkSecondary)
                Text(QuizDuelText.categoryLine(duel, language))
                    .font(PaperFont.font(size: 12, weight: .medium))
                    .foregroundColor(Paper.inkSecondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .paperSheet(cornerRadius: 16)
            .padding(.horizontal, 20)

            Button {
                Haptics.impact(.soft)
                onAccept()
            } label: {
                Text(language.pick(hy: "Ընդունել հրավերը", ru: "Принять вызов", en: "Accept the challenge"))
                    .font(PaperFont.font(size: 16, weight: .semibold))
                    .foregroundColor(Paper.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Paper.accentFill)
                    .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
            Spacer()
        }
    }
}

// MARK: - Итог партии: вызов отправляется, ответ сравнивается
struct QuizDuelFinishView: View {
    /// Дуэль так, как она была задана к началу партии (счёта игрока в ней ещё нет)
    let duel: QuizDuel
    /// Играл тот, кто принял вызов (у автора вызова это false)
    let isResponder: Bool
    let myScore: Int
    let language: AppLanguage
    let accentColor: Color
    let primaryTextColor: Color
    /// Готовая дуэль со счётом игрока: из неё делается ссылка для отправки
    let onShare: (QuizDuel) -> Void
    let onRematch: () -> Void
    let onClose: () -> Void

    @AppStorage("luys_manuscript_name") private var name = ""

    private func sharedDuel() -> QuizDuel {
        var result = duel
        if isResponder {
            result.b = PairLink.clean(name, limit: 40)
            result.q = myScore
        } else {
            result.a = PairLink.clean(name, limit: 40)
            result.r = myScore
        }
        return result
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 42))
                    .foregroundColor(accentColor)
                    .padding(.top, 8)
                Text("\(myScore) / \(duel.n)")
                    .font(PaperFont.font(size: 44, weight: .semibold).monospacedDigit())
                    .foregroundColor(primaryTextColor)

                if isResponder, let theirs = duel.r {
                    VStack(spacing: 6) {
                        Text(QuizDuelText.verdict(mine: myScore, theirs: theirs, language))
                            .font(PaperFont.font(size: 18, weight: .semibold))
                            .foregroundColor(Paper.gold)
                        Text("\(QuizDuelText.opponent(duel.a, language)): \(theirs) / \(duel.n)")
                            .font(PaperFont.font(size: 14))
                            .foregroundColor(Paper.inkSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .paperSheet(cornerRadius: 16)
                } else {
                    Text(language.pick(
                        hy: "Ուղարկեք մարտահրավերը ընկերոջը. նա կխաղա նույն հարցերը:",
                        ru: "Отправьте вызов другу: он сыграет те же вопросы.",
                        en: "Send the challenge to a friend: they will play the same questions."
                    ))
                    .font(PaperFont.font(size: 14))
                    .foregroundColor(Paper.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                }

                TextField(
                    language.pick(hy: "Ձեր անունը (ստորագրության համար)", ru: "Ваше имя (для подписи)", en: "Your name (as a signature)"),
                    text: $name
                )
                .font(PaperFont.font(size: 15))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .paperField(cornerRadius: 12)

                Button {
                    Haptics.impact(.soft)
                    onShare(sharedDuel())
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                        Text(isResponder
                             ? language.pick(hy: "Ուղարկել արդյունքը", ru: "Отправить результат", en: "Send the result")
                             : language.pick(hy: "Ուղարկել մարտահրավերը", ru: "Отправить вызов", en: "Send the challenge"))
                            .font(PaperFont.font(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Paper.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Paper.accentFill)
                    .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())

                if isResponder {
                    Button {
                        onRematch()
                    } label: {
                        Text(language.pick(hy: "Ռեվանշ", ru: "Реванш", en: "Rematch"))
                            .font(PaperFont.font(size: 15, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                    .padding(.top, 2)
                }

                Button {
                    onClose()
                } label: {
                    Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close"))
                        .font(PaperFont.font(size: 14, weight: .medium))
                        .foregroundColor(Paper.inkSecondary)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Итог дуэли, когда друг прислал ответ
struct QuizDuelResultView: View {
    let duel: QuizDuel
    let language: AppLanguage
    let accentColor: Color
    let primaryTextColor: Color
    let onRematch: () -> Void
    let onClose: () -> Void

    var body: some View {
        let mine = duel.r ?? 0
        let theirs = duel.q ?? 0
        return VStack(spacing: 18) {
            Spacer(minLength: 10)
            Image(systemName: "trophy.fill")
                .font(.system(size: 46))
                .foregroundColor(accentColor)
            Text(language.pick(hy: "Մենամարտի արդյունքը", ru: "Итог дуэли", en: "Duel result"))
                .font(PaperFont.font(size: 22, weight: .semibold))
                .foregroundColor(primaryTextColor)
            Text(QuizDuelText.verdict(mine: mine, theirs: theirs, language))
                .font(PaperFont.font(size: 18, weight: .semibold))
                .foregroundColor(Paper.gold)

            HStack(spacing: 24) {
                scoreColumn(title: language.pick(hy: "Դուք", ru: "Вы", en: "You"), score: mine)
                Text(":")
                    .font(PaperFont.font(size: 30, weight: .semibold))
                    .foregroundColor(Paper.inkSecondary)
                scoreColumn(title: QuizDuelText.opponent(duel.b, language), score: theirs)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .paperSheet(cornerRadius: 16)
            .padding(.horizontal, 20)

            Button {
                onRematch()
            } label: {
                Text(language.pick(hy: "Ռեվանշ", ru: "Реванш", en: "Rematch"))
                    .font(PaperFont.font(size: 16, weight: .semibold))
                    .foregroundColor(Paper.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Paper.accentFill)
                    .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)

            Button {
                onClose()
            } label: {
                Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close"))
                    .font(PaperFont.font(size: 14, weight: .medium))
                    .foregroundColor(Paper.inkSecondary)
            }
            Spacer()
        }
    }

    private func scoreColumn(title: String, score: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(score) / \(duel.n)")
                .font(PaperFont.font(size: 30, weight: .semibold).monospacedDigit())
                .foregroundColor(primaryTextColor)
            Text(title)
                .font(PaperFont.font(size: 12))
                .foregroundColor(Paper.inkSecondary)
                .lineLimit(1)
        }
    }
}
