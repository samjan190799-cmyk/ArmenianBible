import SwiftUI

// MARK: - Внутреннее вью для отображения конкретной главы

struct BibleSingleChapterView: View {
    let book: BibleBook
    let chapter: Int
    let targetVerse: Int?
    
    @ObservedObject var manager = BibleManager.shared
    @State private var chapterText: BibleChapterText? = nil
    @State private var highlightedVerseId: Int? = nil
    @State private var selectedVerseForSheet: BibleVerseText? = nil
    @State private var toastMessage: String? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        manager.accentTheme.color
    }

    private var backgroundColor: Color {
        Paper.page
    }

    private var rowBgColor: Color {
        Paper.sheet
    }

    private var highlightColor: Color {
        accentColor.opacity(colorScheme == .dark ? 0.18 : 0.12)
    }
    
    private var fontDesign: Font.Design {
        .serif
    }
    
    private var primaryTextColor: Color {
        Paper.ink
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            // Эффект вогнутости страницы (тень у корешка слева и изгиб у внешнего края справа)
            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.22 : 0.05),
                    Color.clear,
                    Color.black.opacity(colorScheme == .dark ? 0.06 : 0.015)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
            
            if let text = chapterText {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Книжный заголовок главы: название книги капителью и крупный номер главы киноварью
                            VStack(spacing: 6) {
                                Text(book.name.uppercased())
                                    .font(PaperFont.font(size: 14, weight: .medium))
                                    .tracking(2.2)
                                    .foregroundColor(Paper.inkSecondary)
                                    .multilineTextAlignment(.center)

                                Text("\(chapter)")
                                    .font(PaperFont.font(size: 54))
                                    .foregroundColor(accentColor)
                                    .accessibilityLabel(Text("\("chapter_title_label".localized(for: manager.appLanguage)) \(chapter)"))

                                PaperOrnament(width: 44)
                                    .padding(.top, 2)
                            }
                            .padding(.top, 32)
                            .padding(.bottom, 26)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity)
                            
                            // MARK: - Непрерывный текст главы со свободным выделением и нативным копированием
                            SelectableBibleTextView(
                                attributedText: buildChapterNSAttributedString(from: text),
                                language: manager.appLanguage,
                                onVerseTapped: { verseNum in
                                    if let v = text.verses.first(where: { $0.verseNumber == verseNum }) {
                                        triggerHaptic(.light)
                                        selectedVerseForSheet = v
                                    }
                                },
                                onRemoveHighlight: { verseNum in
                                    triggerHaptic(.medium)
                                    manager.setHighlight(
                                        bookId: book.id,
                                        chapter: chapter,
                                        verseNumber: verseNum,
                                        colorHex: nil
                                    )
                                }
                            )
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // MARK: - Заметки и теги к стихам этой главы (если есть)
                            let chapterAnnotations = text.verses.compactMap { v -> (BibleVerseText, VerseAnnotation)? in
                                guard let ann = manager.annotation(bookId: book.id, chapter: chapter, verseNumber: v.verseNumber),
                                      (!ann.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !ann.tags.isEmpty) else {
                                    return nil
                                }
                                return (v, ann)
                            }
                            
                            if !chapterAnnotations.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "note.text")
                                            .font(.system(size: 13, weight: .regular))
                                        Text("personal_note_title".localized(for: manager.appLanguage))
                                            .font(PaperFont.font(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(accentColor)
                                    .padding(.top, 16)
                                    
                                    ForEach(chapterAnnotations, id: \.0.verseNumber) { (v, ann) in
                                        Button {
                                            triggerHaptic(.light)
                                            selectedVerseForSheet = v
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    Text("\("verse_label".localized(for: manager.appLanguage)) \(v.verseNumber)")
                                                        .font(PaperFont.font(size: 12, weight: .semibold))
                                                        .foregroundColor(accentColor)
                                                    
                                                    Spacer()
                                                    
                                                    if !ann.tags.isEmpty {
                                                        HStack(spacing: 4) {
                                                            ForEach(ann.tags) { tag in
                                                                Text(tag.icon)
                                                                    .font(.system(size: 10))
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                if !ann.note.isEmpty {
                                                    Text(ann.note)
                                                        .font(PaperFont.font(size: 14))
                                                        .foregroundColor(primaryTextColor)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .paperSheet(cornerRadius: 12)
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                            }
                            
                            // Номер страницы (номер текущей главы)
                            VStack(spacing: 10) {
                                PaperOrnament(width: 28)

                                Text("\(chapter)")
                                    .font(PaperFont.font(size: 13))
                                    .foregroundColor(Paper.inkTertiary)
                            }
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 32)
                    }
                    .onAppear {
                        // Скроллим к целевому стиху, если он передан (для Deep Link и поиска)
                        if let target = targetVerse {
                            highlightedVerseId = target
                            
                            // Убираем подсветку через 3 секунды
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    if highlightedVerseId == target {
                                        highlightedVerseId = nil
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                VStack {
                    ProgressView()
                        .tint(accentColor)
                    Text("loading_label".localized(for: manager.appLanguage))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            loadChapterText()
        }
        .sheet(item: $selectedVerseForSheet) { v in
            VerseActionSheetView(
                book: book,
                chapter: chapter,
                verse: v,
                language: manager.appLanguage,
                accentColor: accentColor,
                cardBackgroundColor: Paper.sheet,
                cardBorderColor: LinearGradient(colors: [Paper.hairline, Paper.hairline], startPoint: .top, endPoint: .bottom),
                primaryTextColor: Paper.ink,
                onPinToWidget: {
                    pinToWidget(verse: v)
                },
                onToggleFavorite: {
                    toggleFavorite(verse: v)
                },
                onCopy: {
                    copyToClipboard(verse: v)
                },
                onShare: {
                    shareVerse(verse: v)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .overlay(
            VStack {
                if let msg = toastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(msg)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(20)
                    .shadow(radius: 6)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.3), value: toastMessage != nil)
        )
    }
    
    private func pinToWidget(verse: BibleVerseText) {
        let nameHy = book.nameHy
        let nameRu = book.nameRu
        let nameEn = book.nameEn
        
        let refHy = "\(nameHy) \(chapter):\(verse.verseNumber)"
        let refRu = "\(nameRu) \(chapter):\(verse.verseNumber)"
        let refEn = "\(nameEn) \(chapter):\(verse.verseNumber)"
        
        manager.pinVerseToWidget(
            textHy: verse.textHy,
            textRu: verse.textRu,
            textEn: verse.textEn,
            refHy: refHy,
            refRu: refRu,
            refEn: refEn
        )
        
        triggerHaptic(.medium)
        showToast(message: "toast_pinned_to_widget".localized(for: manager.appLanguage))
    }
    
    private func showToast(message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
    
    private func loadChapterText() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = BibleDatabase.shared.getChapterText(bookId: book.id, chapter: chapter)
            DispatchQueue.main.async {
                self.chapterText = data
            }
        }
    }
    
    private func copyToClipboard(verse: BibleVerseText) {
        let reference = "\(book.name) \(chapter):\(verse.verseNumber)"
        let textToCopy = "\(verse.text(for: manager.appLanguage)) (\(reference))"
        UIPasteboard.general.string = textToCopy
        triggerHaptic(.light)
    }
    
    private func shareVerse(verse: BibleVerseText) {
        let reference = "\(book.name) \(chapter):\(verse.verseNumber)"
        let textToShare = "\(verse.text(for: manager.appLanguage)) (\(reference))"
        
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
    
    private func toggleFavorite(verse: BibleVerseText) {
        triggerHaptic(.medium)
        if manager.isFavorite(verseText: verse) {
            manager.removeFromFavorites(verseText: verse)
        } else {
            manager.addToFavorites(verseText: verse, bookName: book.name)
        }
    }
    
    private func buildChapterNSAttributedString(from text: BibleChapterText) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let fontSize = manager.bibleFontSize
        let textColor = Paper.uiInk
        let uiAccentColor = manager.accentTheme.uiColor

        // Книжная вёрстка: стих — абзац, умеренный интерлиньяж и небольшой отступ между стихами
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = round(fontSize * 0.4)
        paragraphStyle.paragraphSpacing = round(fontSize * 0.6)

        let font = PaperFont.uiFont(size: fontSize)
        let numFont = PaperFont.uiFont(size: max(11, fontSize * 0.62), weight: .semibold)

        let verseKey = NSAttributedString.Key("verseNumber")
        
        for (index, verse) in text.verses.enumerated() {
            // Номер стиха надстрочным шрифтом с кликабельной ссылкой
            let numAttrs: [NSAttributedString.Key: Any] = [
                .font: numFont,
                .foregroundColor: uiAccentColor,
                .baselineOffset: fontSize * 0.3,
                .link: URL(string: "verse://\(verse.verseNumber)") ?? "",
                verseKey: verse.verseNumber
            ]
            let numStr = NSAttributedString(string: " \(verse.verseNumber) ", attributes: numAttrs)
            
            // Текст стиха
            let verseContent = verse.text(for: manager.appLanguage)
            var verseAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle,
                verseKey: verse.verseNumber
            ]
            
            let ann = manager.annotation(bookId: book.id, chapter: chapter, verseNumber: verse.verseNumber)
            let savedColorHex = ann?.colorHex ?? manager.highlightColor(bookId: book.id, chapter: chapter, verseNumber: verse.verseNumber)
            
            if let hex = savedColorHex, !hex.isEmpty {
                verseAttrs[.backgroundColor] = UIColor(Color(hex: hex)).withAlphaComponent(colorScheme == .dark ? 0.35 : 0.25)
            } else if highlightedVerseId == verse.verseNumber {
                verseAttrs[.backgroundColor] = uiAccentColor.withAlphaComponent(colorScheme == .dark ? 0.25 : 0.18)
            }
            
            let verseStr = NSAttributedString(string: verseContent, attributes: verseAttrs)
            
            result.append(numStr)
            result.append(verseStr)
            
            if index < text.verses.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: [.font: font, .paragraphStyle: paragraphStyle]))
            }
        }
        
        return result
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

