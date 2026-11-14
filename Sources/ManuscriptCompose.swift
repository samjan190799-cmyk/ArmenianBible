import SwiftUI

// MARK: - Повод для листа: готовое благословение, которое можно изменить
// До сих пор в «Рукописи» писался только стих. Теперь можно написать своё: благословение, молитву, пожелание.
// Готовые поводы (крестины, день рождения, свадьба, Пасха, Рождество, благодарность) подставляют текст,
// который можно переписать как угодно; такие листы дарят близким.
enum ManuscriptOccasion: String, CaseIterable, Identifiable {
    case baptism, birthday, wedding, easter, christmas, gratitude

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .baptism: return "drop.fill"
        case .birthday: return "gift.fill"
        case .wedding: return "heart.fill"
        case .easter: return "sun.max.fill"
        case .christmas: return "star.fill"
        case .gratitude: return "hands.sparkles.fill"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .baptism: return language.pick(hy: "Մկրտություն", ru: "Крестины", en: "Baptism")
        case .birthday: return language.pick(hy: "Ծնունդ", ru: "День рождения", en: "Birthday")
        case .wedding: return language.pick(hy: "Հարսանիք", ru: "Свадьба", en: "Wedding")
        case .easter: return language.pick(hy: "Զատիկ", ru: "Пасха", en: "Easter")
        case .christmas: return language.pick(hy: "Ծնունդ Քրիստոսի", ru: "Рождество", en: "Christmas")
        case .gratitude: return language.pick(hy: "Շնորհակալություն", ru: "Благодарность", en: "Gratitude")
        }
    }

    /// Готовый текст: короткий, чтобы на листе он выглядел как строфа рукописи
    func text(for language: AppLanguage) -> String {
        switch self {
        case .baptism:
            return language.pick(
                hy: "Այսօր դու վերստին ծնվեցիր վերևից: Թող Տերը պահպանի քեզ քո բոլոր ճանապարհներին:",
                ru: "Сегодня ты родился свыше. Да хранит тебя Господь на всех путях твоих.",
                en: "Today you are born from above. May the Lord keep you in all your ways."
            )
        case .birthday:
            return language.pick(
                hy: "Թող Տերը օրհնի քեզ և պահպանի քեզ: Թող Նրա լույսը լուսավորի քո ամեն օրը:",
                ru: "Да благословит тебя Господь и сохранит тебя. Да озарит свет Его каждый твой день.",
                en: "The Lord bless you and keep you. May His light shine on every day of your life."
            )
        case .wedding:
            return language.pick(
                hy: "Թող Տերը օրհնի ձեր միությունը սիրով, խաղաղությամբ և ուրախությամբ ձեր կյանքի բոլոր օրերին:",
                ru: "Да благословит Господь ваш союз любовью, миром и радостью на все дни жизни.",
                en: "May the Lord bless your union with love, peace and joy all the days of your life."
            )
        case .easter:
            return language.pick(
                hy: "Քրիստոս յարեաւ ի մեռելոց: Օրհնեալ է յարութիւնն Քրիստոսի:",
                ru: "Христос воскрес из мёртвых! Радость и свет воскресения да наполнят ваш дом.",
                en: "Christ is risen from the dead! May the joy and light of the Resurrection fill your home."
            )
        case .christmas:
            return language.pick(
                hy: "Քրիստոս ծնաւ եւ յայտնեցաւ: Օրհնեալ է յայտնութիւնն Քրիստոսի:",
                ru: "Христос родился и явился! Благословенно явление Христа.",
                en: "Christ is born and revealed! Blessed is the revelation of Christ."
            )
        case .gratitude:
            return language.pick(
                hy: "Շնորհակալ եմ Տիրոջը ամեն ինչի համար՝ օրվա լույսի, հարազատների և յուրաքանչյուր շնչի համար:",
                ru: "Благодарю Господа за всё, что Он дал: за свет дня, за близких и за каждый вздох.",
                en: "I thank the Lord for all He has given: the light of day, my loved ones and every breath."
            )
        }
    }
}

// MARK: - Окно «Свой текст»
struct ManuscriptComposeSheet: View {
    let language: AppLanguage
    /// Текст и подпись под ним: из них создаётся лист, который открывается в мастерской
    let onCreate: (_ text: String, _ caption: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var occasion: ManuscriptOccasion? = nil

    /// Больше текст на странице не помещается красиво: вёрстка уменьшает кегль, но строфа должна оставаться строфой
    static let characterLimit = 300

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var caption: String {
        occasion?.title(for: language) ?? language.pick(hy: "Սրտանց", ru: "От всего сердца", en: "From the heart")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(language.pick(
                        hy: "Գրեք օրհնություն, աղոթք կամ մաղթանք: Գրիչը կգրի այն մագաղաթի վրա:",
                        ru: "Напишите благословение, молитву или пожелание. Перо выпишет его на пергаменте.",
                        en: "Write a blessing, prayer or wish. The quill will write it on parchment."
                    ))
                    .font(PaperFont.font(size: 14))
                    .foregroundColor(Paper.inkSecondary)

                    occasionChips

                    VStack(alignment: .trailing, spacing: 6) {
                        TextEditor(text: $text)
                            .font(PaperFont.font(size: 16))
                            .foregroundColor(Paper.ink)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 150)
                            .padding(10)
                            .paperField(cornerRadius: 14)
                        Text("\(text.count)/\(Self.characterLimit)")
                            .font(PaperFont.font(size: 11).monospacedDigit())
                            .foregroundColor(Paper.inkSecondary)
                    }

                    Button {
                        guard !trimmed.isEmpty else { return }
                        ManuscriptStats.track(occasion == nil ? "ms_compose_free" : "ms_compose_occasion")
                        onCreate(trimmed, caption)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 15, weight: .semibold))
                            Text(language.pick(hy: "Գրել մագաղաթի վրա", ru: "Написать на пергаменте", en: "Write on parchment"))
                                .font(PaperFont.font(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Paper.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(trimmed.isEmpty ? Paper.fillMuted : Paper.accentFill)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(trimmed.isEmpty)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(PaperBackground())
            .navigationTitle(language.pick(hy: "Իմ տեքստը", ru: "Свой текст", en: "Your text"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(language.pick(hy: "Չեղարկել", ru: "Отмена", en: "Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(Paper.inkSecondary)
                }
            }
            .onChange(of: text) { value in
                if value.count > Self.characterLimit {
                    text = String(value.prefix(Self.characterLimit))
                }
            }
            .onAppear {
                ManuscriptStats.track("ms_compose")
            }
        }
    }

    private var occasionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ManuscriptOccasion.allCases) { item in
                    let isSelected = occasion == item
                    Button {
                        Haptics.selection()
                        occasion = item
                        text = item.text(for: language)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(item.title(for: language))
                                .font(PaperFont.font(size: 13, weight: isSelected ? .semibold : .medium))
                        }
                        .foregroundColor(isSelected ? Paper.onAccent : Paper.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(isSelected ? Paper.accentFill : Paper.fillSubtle))
                        .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Paper.hairline, lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
}
