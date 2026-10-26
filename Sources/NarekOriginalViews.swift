import SwiftUI

// MARK: - Строка списка глав подлинного текста
struct NarekOriginalRow: View {
    let chapter: NarekOriginalChapter
    let primaryTextColor: Color
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Paper.fillMuted)
                        .frame(width: 42, height: 42)
                    Text("\(chapter.id)")
                        .font(PaperFont.font(size: 14, weight: .semibold).monospacedDigit())
                        .foregroundColor(Paper.inkSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(chapter.ban)
                        .font(PaperFont.font(size: 15, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    Text(chapter.preview)
                        .font(PaperFont.font(size: 13))
                        .foregroundColor(Paper.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Paper.inkSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .paperField(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Чтение главы: листание вперёд и назад, копирование, отправка, переход к записи
struct NarekChapterReaderView: View {
    @ObservedObject private var manager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var currentId: Int
    @State private var shareText: String? = nil
    @State private var copied = false
    /// Слушать главу в плеере: решает, доступна ли запись, экран Нарекаци
    let onListen: (Int) -> Void

    init(startId: Int, onListen: @escaping (Int) -> Void) {
        _currentId = State(initialValue: startId)
        self.onListen = onListen
    }

    private var chapter: NarekOriginalChapter? {
        NarekOriginal.shared.chapter(id: currentId)
    }

    private var total: Int {
        NarekOriginal.shared.chapters.count
    }

    private func go(_ delta: Int) {
        let next = currentId + delta
        guard next >= 1, next <= total else { return }
        Haptics.impact(.light)
        currentId = next
    }

    private var bodySize: CGFloat {
        CGFloat(manager.bibleFontSize)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                if let chapter {
                    VStack(alignment: .leading, spacing: 22) {
                        titleBlock(chapter)

                        ForEach(Array(chapter.stanzas.enumerated()), id: \.offset) { _, stanza in
                            VStack(alignment: .leading, spacing: 9) {
                                if !stanza.label.isEmpty {
                                    Text(stanza.label)
                                        .font(PaperFont.font(size: 13, weight: .semibold))
                                        .tracking(1.2)
                                        .foregroundColor(manager.accentTheme.color)
                                }
                                ForEach(Array(stanza.lines.enumerated()), id: \.offset) { _, line in
                                    Text(line)
                                        .font(PaperFont.font(size: bodySize))
                                        .foregroundColor(Paper.ink)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        sourceNote
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                }
            }
            .id(currentId)

            footer
        }
        .background(PaperBackground())
        .sheet(isPresented: Binding(
            get: { shareText != nil },
            set: { if !$0 { shareText = nil } }
        )) {
            if let text = shareText {
                ActivityView(activityItems: [text])
            }
        }
    }

    // MARK: - Верх: закрыть и номер главы
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Paper.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Paper.sheet))
                    .overlay(Circle().strokeBorder(Paper.hairline, lineWidth: 1))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(chapter?.ban ?? "")
                    .font(PaperFont.font(size: 17, weight: .semibold))
                    .foregroundColor(Paper.ink)
                Text("\(currentId) / \(total)")
                    .font(PaperFont.font(size: 12).monospacedDigit())
                    .foregroundColor(Paper.inkSecondary)
            }

            Spacer()

            // Современный армянский: ссылки на переводы на Wikisource (текст в приложение не копируется)
            Menu {
                Section(manager.appLanguage.pick(
                    hy: "Աշխարհաբար (hy.wikisource.org)",
                    ru: "На современном армянском (hy.wikisource.org)",
                    en: "In modern Armenian (hy.wikisource.org)"
                )) {
                    ForEach(NarekModernArmenian.translations) { translation in
                        if let url = NarekModernArmenian.url(for: translation, chapter: currentId) {
                            Button {
                                Haptics.impact(.light)
                                openURL(url)
                            } label: {
                                Label(translation.translator, systemImage: "arrow.up.right.square")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "character.book.closed")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Paper.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Paper.sheet))
                    .overlay(Circle().strokeBorder(Paper.hairline, lineWidth: 1))
            }
            .accessibilityLabel(Text(manager.appLanguage.pick(
                hy: "Աշխարհաբար թարգմանություն",
                ru: "Перевод на современный армянский",
                en: "Modern Armenian translation"
            )))
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Заголовок главы: редакторская строка мельче, основная заметнее
    @ViewBuilder
    private func titleBlock(_ chapter: NarekOriginalChapter) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(chapter.titleLines.enumerated()), id: \.offset) { index, line in
                let isMain = index == chapter.titleLines.count - 1
                Text(line)
                    .font(PaperFont.font(size: isMain ? 17 : 13, weight: isMain ? .semibold : .regular))
                    .foregroundColor(isMain ? Paper.ink : Paper.inkSecondary)
                    .italic(!isMain)
            }
        }
    }

    private var sourceNote: some View {
        Text(manager.appLanguage.pick(
            hy: "Բնագիր (գրաբար)՝ hy.wikisource.org",
            ru: "Оригинал (грабар): hy.wikisource.org",
            en: "Original (Grabar): hy.wikisource.org"
        ))
        .font(PaperFont.font(size: 12))
        .foregroundColor(Paper.inkSecondary)
    }

    // MARK: - Низ: назад, слушать, копировать, отправить, вперёд
    private var footer: some View {
        HStack(spacing: 0) {
            footerButton(symbol: "chevron.left", enabled: currentId > 1) { go(-1) }
            footerButton(symbol: "headphones", enabled: true) {
                Haptics.impact(.soft)
                onListen(currentId)
            }
            footerButton(symbol: copied ? "checkmark" : "doc.on.doc", enabled: chapter != nil) {
                guard let chapter else { return }
                UIPasteboard.general.string = chapter.text
                Haptics.impact(.soft)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { copied = false }
            }
            footerButton(symbol: "square.and.arrow.up", enabled: chapter != nil) {
                guard let chapter else { return }
                Haptics.impact(.soft)
                shareText = "\(chapter.ban)\n\n\(chapter.text)\n\nՄատեան Ողբերգութեան · Գրիգոր Նարեկացի"
            }
            footerButton(symbol: "chevron.right", enabled: currentId < total) { go(1) }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(
            Paper.sheet
                .overlay(Rectangle().fill(Paper.hairline).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func footerButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(enabled ? Paper.ink : Paper.inkSecondary.opacity(0.4))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
    }
}
