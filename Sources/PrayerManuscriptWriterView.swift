import SwiftUI

// MARK: - Часы пера: догоняют набранный текст
/// Перо идёт за текстом, а не за временем: каждая новая буква пишется со скоростью руки,
/// вставленный кусок догоняется быстрее, стёртое исчезает сразу.
final class PrayerPenClock {
    private var last: Date?
    private var written: Double = 0
    private var initial: Double = 0
    private var top: CGFloat?

    struct Snapshot {
        let written: Double
        let initial: Double
        let top: CGFloat
    }

    func advance(now: Date, target: Int, hasText: Bool, scrollTarget: CGFloat) -> Snapshot {
        let dt = last.map { min(0.1, max(0, now.timeIntervalSince($0))) } ?? 0
        last = now

        let goal = Double(target)
        if written > goal {
            written = goal
        } else if written < goal {
            let speed = max(16, (goal - written) / 2)
            written = min(goal, written + speed * dt)
        }

        if hasText {
            initial = min(1, initial + dt / 0.7)
        } else {
            initial = 0
        }

        // Окно листа плавно едет вслед за последней строкой
        let current = top ?? scrollTarget
        let eased = current + (scrollTarget - current) * min(1, CGFloat(dt) * 8)
        top = eased
        return Snapshot(written: written, initial: initial, top: eased)
    }
}

// MARK: - Молитва на пергаменте: человек печатает, перо пишет за ним
struct PrayerManuscriptWriterView: View {
    let language: AppLanguage
    /// Строка над текстом на листе: «О здравии · Аракс»
    let reference: String
    /// Каноническая молитва выбранного намерения: её можно вернуть одной кнопкой
    let canonicalPrayer: String
    /// Подпись кнопки «Зажечь свечу» (учитывает PRO и рекламу)
    let lightTitle: String
    /// Человек нажал «Зажечь свечу»: форма зажжёт свечу, когда лист закроется
    let onLight: () -> Void
    @Binding var text: String

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @AppStorage(ManuscriptPen.storageKey) private var penRaw = ManuscriptPen.defaultValue.rawValue
    @ObservedObject private var subscription = SubscriptionManager.shared
    @State private var style = ManuscriptPage.preferredStyle
    @State private var surface = ManuscriptSurface.effective
    @State private var isShowingPens = false
    @State private var isShowingSurfaces = false
    @State private var clock = PrayerPenClock()
    @State private var pageId = UUID()
    @State private var createdAt = Date()
    @State private var writerName = ManuscriptPage.rememberedName

    private static let maxLength = 500
    /// Зерно пергамента не зависит от текста: иначе волокна перерисовывались бы с каждой буквой
    private static let parchmentSeed: UInt32 = 0x1475_C0DE
    private static let backdrop = ManuscriptPalette.color(0x15100B)
    private static let parchmentInk = ManuscriptPalette.color(0xF2E8CF)

    private var activePen: ManuscriptPen {
        let chosen = ManuscriptPen(rawValue: penRaw) ?? ManuscriptPen.defaultValue
        return chosen.isFree || subscription.isPremium ? chosen : ManuscriptPen.defaultValue
    }

    /// Выбранная основа; если Premium закончился, платная заменяется пергаментом
    private var activeSurface: ManuscriptSurface {
        surface.isFree || subscription.isPremium ? surface : .parchment
    }

    private var page: ManuscriptPage {
        ManuscriptPage(
            id: pageId,
            text: text,
            reference: reference,
            language: language,
            style: style,
            surface: activeSurface,
            name: writerName,
            createdAt: createdAt
        )
    }

    var body: some View {
        ZStack {
            Self.backdrop.ignoresSafeArea()
            RadialGradient(
                colors: [ManuscriptPalette.color(0xC1902F, 0.22), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 10) {
                topBar

                GeometryReader { geo in
                    pageWindow(size: geo.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(placeholder)
                        // Нажатие на лист возвращает клавиатуру: пишем прямо на пергаменте
                        .contentShape(Rectangle())
                        .onTapGesture { isFocused = true }
                }
                .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 8)

                controls
                lightButton
            }
            .padding(.bottom, 8)
        }
        .background(hiddenInput)
        .preferredColorScheme(.dark)
        .onAppear { isFocused = true }
        .onChange(of: text) { newValue in
            if newValue.count > Self.maxLength {
                text = String(newValue.prefix(Self.maxLength))
            }
        }
        .onChange(of: isShowingPens) { showing in
            if !showing { isFocused = true }
        }
        .onChange(of: isShowingSurfaces) { showing in
            if !showing { isFocused = true }
        }
        .onChange(of: surface) { newValue in
            // Выбор запоминается: свеча сохранит лист на этой основе
            UserDefaults.standard.set(newValue.rawValue, forKey: ManuscriptSurface.storageKey)
        }
        .sheet(isPresented: $isShowingPens) {
            ManuscriptPenSheet(language: language, selectedRaw: $penRaw)
        }
        .sheet(isPresented: $isShowingSurfaces) {
            ManuscriptSurfaceSheet(language: language, selection: $surface)
        }
    }

    // MARK: Шапка
    private var topBar: some View {
        HStack {
            Button {
                isFocused = false
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Self.parchmentInk)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .accessibilityLabel(Text(language.pick(hy: "Փակել", ru: "Закрыть", en: "Close")))

            Spacer()

            VStack(spacing: 1) {
                Text(language.pick(hy: "Աղոթք մագաղաթի վրա", ru: "Молитва на пергаменте", en: "Prayer on vellum"))
                    .font(PaperFont.font(size: 17, weight: .semibold))
                    .foregroundColor(Self.parchmentInk)
                Text(reference)
                    .font(PaperFont.font(size: 11))
                    .foregroundColor(Self.parchmentInk.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            // Пустое место справа равно кнопке закрытия слева: заголовок по центру
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: Лист: окно на странице, которое следует за последней строкой
    private func pageWindow(size: CGSize) -> some View {
        let scale = min(size.width / ManuscriptGeometry.size.width, 0.9)
        return TimelineView(.animation) { timeline in
            let current = page
            let layout = ManuscriptTextLayout.cached(for: current, pen: activePen, prayer: true)
            let visibleHeight = size.height / scale
            let minTop: CGFloat = 56
            let followTarget = max(minTop, min(layout.bottomY - visibleHeight + 40, ManuscriptGeometry.size.height - visibleHeight))
            let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let state = clock.advance(now: timeline.date, target: layout.length, hasText: hasText, scrollTarget: followTarget)
            let progress = layout.length > 0 ? CGFloat(min(1, state.written / Double(layout.length))) : 0
            let reveal = ManuscriptReveal(
                parchment: 1, frame: 1, headpiece: 1,
                initial: CGFloat(state.initial), text: progress, margin: 1, colophon: 1
            )
            ManuscriptPageView(
                page: current,
                reveal: reveal,
                sheen: CGPoint(x: 0.15, y: -0.1),
                pen: activePen,
                isLiveWriting: true,
                parchmentSeed: Self.parchmentSeed,
                quillLift: 0
            )
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: ManuscriptGeometry.size.width * scale, height: ManuscriptGeometry.size.height * scale, alignment: .topLeading)
            .offset(y: -state.top * scale)
            .frame(width: ManuscriptGeometry.size.width * scale, height: size.height, alignment: .top)
            .clipped()
        }
        .frame(width: ManuscriptGeometry.size.width * scale, height: size.height)
    }

    // MARK: Стиль и перо
    private var controls: some View {
        HStack(spacing: 8) {
            ForEach(ManuscriptStyle.allCases) { option in
                let isSelected = option == style
                Button {
                    guard option != style else { return }
                    Haptics.selection()
                    style = option
                    UserDefaults.standard.set(option.rawValue, forKey: "luys_manuscript_style")
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ManuscriptPalette.color(option.palette.field))
                            .frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(ManuscriptPalette.color(option.palette.goldLight), lineWidth: 1.2))
                        // Название только у выбранного стиля: ряд кнопок должен помещаться на узком экране
                        if isSelected {
                            Text(option.title(for: language))
                                .font(PaperFont.font(size: 12, weight: .semibold))
                                .foregroundColor(Self.parchmentInk)
                        }
                    }
                    .padding(.horizontal, isSelected ? 10 : 9)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(isSelected ? 0.12 : 0.05)))
                    .overlay(Capsule().strokeBorder(isSelected ? Paper.gold.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.94))
                .accessibilityLabel(Text(option.title(for: language)))
            }

            Button {
                Haptics.impact(.soft)
                isShowingSurfaces = true
            } label: {
                Image(systemName: "paintpalette")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Self.parchmentInk)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .accessibilityLabel(Text(language.pick(hy: "Էջի հիմք", ru: "Основа листа", en: "Page surface")))

            Button {
                Haptics.impact(.soft)
                isShowingPens = true
            } label: {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Self.parchmentInk)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .accessibilityLabel(Text(language.pick(hy: "Գրիչ", ru: "Перо", en: "Pen")))

            if text != canonicalPrayer {
                Button {
                    Haptics.impact(.light)
                    text = canonicalPrayer
                    isFocused = true
                } label: {
                    Image(systemName: "book.closed")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Self.parchmentInk.opacity(0.75))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .accessibilityLabel(Text(language.pick(hy: "Կանոնական աղոթք", ru: "Каноническая молитва", en: "Canonical prayer")))
            }

            if !text.isEmpty {
                Button {
                    Haptics.impact(.light)
                    text = ""
                    isFocused = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Self.parchmentInk.opacity(0.75))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .accessibilityLabel(Text(language.pick(hy: "Մաքրել", ru: "Очистить", en: "Clear")))
            }
        }
    }

    // MARK: Зажечь свечу
    private var lightButton: some View {
        Button {
            Haptics.impact(.soft)
            isFocused = false
            onLight()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(lightTitle)
                    .font(PaperFont.font(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(Self.backdrop)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Paper.gold))
        }
        .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.97))
        .padding(.horizontal, 16)
    }

    // MARK: Ввод прямо на листе
    /// Подсказка на пустом листе
    @ViewBuilder
    private var placeholder: some View {
        if text.isEmpty {
            Text(language.pick(
                hy: "Սկսեք գրել աղոթքը. գրիչը կգրի ձեր հետևից",
                ru: "Начните печатать молитву: перо будет писать следом",
                en: "Start typing your prayer: the pen writes along"
            ))
            .font(PaperFont.font(size: 16))
            .foregroundColor(ManuscriptPalette.color(page.look.palette.ink, 0.55))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 60)
            .allowsHitTesting(false)
        }
    }

    /// Невидимое поле, которое принимает ввод с клавиатуры; всё видимое рисует лист
    private var hiddenInput: some View {
        TextEditor(text: $text)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .frame(width: 44, height: 44)
            .opacity(0.02)
            .allowsHitTesting(false)
    }
}
