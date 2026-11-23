import SwiftUI

// MARK: - Отслеживание места остановки в главе

/// Верх текста главы в системе координат прокрутки (уходит в минус по мере прокрутки)
private struct ChapterTextTopKey: PreferenceKey {
    static var defaultValue: CGFloat = .nan
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if !next.isNaN { value = next }
    }
}

/// Высота видимой области прокрутки
private struct ChapterViewportHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 { value = next }
    }
}

/// Состояние отслеживания живёт в классе, а не в @State: положение прокрутки меняется каждый кадр,
/// а любое изменение @State перестроило бы весь текст главы (и сбросило бы выделение).
private final class ChapterReadingTracker {
    /// Начала стихов от верха текста, по возрастанию
    var verseStarts: [(verse: Int, y: CGFloat)] = []
    var textTop: CGFloat = .nan
    var viewportHeight: CGFloat = 0
    /// Отслеживание включается, когда глава показана и (если открывали по стиху) прокрутка к стиху закончилась
    var isReady = false
    /// Верх текста в момент включения: пока читатель не сдвинул страницу, ничего не сохраняем
    var baselineTop: CGFloat? = nil
    var hasMoved = false
    var saveTask: Task<Void, Never>? = nil

    /// Включает отслеживание: с этого момента положение страницы считается исходным
    /// `restoredVerse` — стих, к которому только что прокрутили при открытии: по тому, где он оказался на экране на самом деле,
    /// уточняем строку чтения (система может считать «верхнюю треть» с учётом полос навигации), чтобы сохранённый стих
    /// не съезжал назад при каждом следующем открытии.
    func markReady(restoredVerse: Int?) {
        guard !isReady else { return }
        isReady = true
        baselineTop = textTop.isNaN ? nil : textTop
        if let verse = restoredVerse, viewportHeight > 0, !textTop.isNaN,
           let start = verseStarts.first(where: { $0.verse == verse }) {
            let measured = textTop + start.y
            let formula = viewportHeight * Self.readLineFraction
            // Если прокрутка упёрлась в конец главы, стих окажется ниже строки чтения: такое измерение не годится
            if abs(measured - formula) <= 120 {
                calibratedLine = measured
            }
        }
    }

    /// Измеренная строка чтения (расстояние от верха области прокрутки) после прокрутки к стиху; nil — считаем по формуле
    var calibratedLine: CGFloat? = nil

    /// Принимает новое положение текста; true — читатель сдвинул страницу и место остановки пора пересчитать
    func registerTextTop(_ top: CGFloat) -> Bool {
        textTop = top
        guard isReady, !top.isNaN else { return false }
        guard let baseline = baselineTop else {
            baselineTop = top
            return false
        }
        if !hasMoved {
            guard abs(top - baseline) > 24 else { return false }
            hasMoved = true
        }
        return true
    }

    /// Доля высоты, на которой лежит строка чтения: туда же прокручиваем при открытии (anchor y = 0.22)
    static let readLineFraction: CGFloat = 0.22

    /// Стих, лежащий на строке чтения; nil — на строке ещё заголовок главы или первый стих
    func verseOnReadLine() -> Int? {
        guard !verseStarts.isEmpty, viewportHeight > 0, !textTop.isNaN else { return nil }
        // Небольшой запас: после прокрутки к стиху его верх может отстоять от строки на пару пунктов
        let line = (calibratedLine ?? viewportHeight * Self.readLineFraction) + 6
        var found: Int? = nil
        for item in verseStarts {
            if textTop + item.y <= line {
                found = item.verse
            } else {
                break
            }
        }
        if let verse = found, verse > 1 { return verse }
        return nil
    }
}

// MARK: - Внутреннее вью для отображения конкретной главы

struct BibleSingleChapterView: View {
    let book: BibleBook
    let chapter: Int
    let targetVerse: Int?
    
    @ObservedObject var manager = BibleManager.shared
    @State private var chapterText: BibleChapterText? = nil
    @State private var highlightedVerseId: Int? = nil
    /// Расстояние от верха текста главы до строки целевого стиха; приходит из раскладки текста, когда известна ширина
    @State private var targetOffset: CGFloat? = nil
    @State private var selectedVerseForSheet: BibleVerseText? = nil
    @State private var toastMessage: String? = nil
    @State private var tracker = ChapterReadingTracker()

    @Environment(\.colorScheme) private var colorScheme

    private static let scrollSpaceName = "chapter-scroll-space"

    /// Невидимая метка в тексте главы на уровне целевого стиха: к ней прокручивает ScrollViewReader
    private static let verseAnchorId = "verse-scroll-anchor"

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
                                    triggerHaptic(.soft)
                                    manager.setHighlight(
                                        bookId: book.id,
                                        chapter: chapter,
                                        verseNumber: verseNum,
                                        colorHex: nil
                                    )
                                },
                                scrollToVerse: resolvedTargetVerse(in: text),
                                onVerseOffset: { offset in
                                    targetOffset = offset
                                },
                                onVerseStarts: { starts in
                                    tracker.verseStarts = starts
                                }
                            )
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: ChapterTextTopKey.self,
                                        value: geo.frame(in: .named(Self.scrollSpaceName)).minY
                                    )
                                }
                            )
                            .overlay(alignment: .topLeading) {
                                // Метка на высоте целевого стиха. Отступ делаем соседним элементом, а не padding вокруг метки:
                                // иначе ScrollViewReader берёт рамку вместе с отступом и прокручивает не туда
                                if let offset = targetOffset {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Color.clear.frame(width: 1, height: offset)
                                        Color.clear.frame(width: 1, height: 1).id(Self.verseAnchorId)
                                    }
                                }
                            }
                            
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
                                                                Image(systemName: tag.symbol)
                                                                    .font(.system(size: 10))
                                                                    .foregroundColor(tag.color)
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
                    .coordinateSpace(name: Self.scrollSpaceName)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: ChapterViewportHeightKey.self, value: geo.size.height)
                        }
                    )
                    .onPreferenceChange(ChapterViewportHeightKey.self) { height in
                        tracker.viewportHeight = height
                    }
                    .onPreferenceChange(ChapterTextTopKey.self) { top in
                        if tracker.registerTextTop(top) {
                            scheduleVerseSave()
                        }
                    }
                    .onChange(of: targetOffset) { offset in
                        // Смещение стиха стало известно: прокручиваем так, чтобы стих лёг в верхнюю треть экрана
                        guard offset != nil else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(Self.verseAnchorId, anchor: UnitPoint(x: 0.5, y: ChapterReadingTracker.readLineFraction))
                            }
                        }
                    }
                    .onAppear {
                        // Подсвечиваем целевой стих, если он передан (ссылка, поиск, избранное); прокрутка к нему — в onChange выше
                        if let target = resolvedTargetVerse(in: text) {
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
                        .font(PaperFont.font(size: 13))
                        .foregroundColor(Paper.inkSecondary)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            loadChapterText()
        }
        .onDisappear {
            // Ушли с главы (назад к каталогу, закрыли экран): сразу записываем, где остановились
            tracker.saveTask?.cancel()
            if tracker.hasMoved {
                saveReadingVerseNow()
            }
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
                            .foregroundColor(Paper.moss)
                        Text(msg)
                            .font(PaperFont.font(size: 13, weight: .semibold))
                            .foregroundColor(Paper.page)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Paper.ink.opacity(0.92))
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
        
        triggerHaptic(.soft)
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
                // Глава проступает на странице плавно, а не появляется рывком
                withAnimation(PaperMotion.animation(PaperMotion.swap)) {
                    self.chapterText = data
                }
                // Место остановки начинаем отслеживать, когда страница устоялась: при открытии на стихе — после прокрутки к нему
                // (она заканчивается примерно через секунду после показа текста), иначе положение «до прокрутки» затёрло бы сохранённый стих
                let resolvedTarget = data.flatMap { resolvedTargetVerse(in: $0) }
                let settleDelay: Double = (resolvedTarget == nil) ? 0.8 : 2.2
                DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay) {
                    tracker.markReady(restoredVerse: resolvedTarget)
                }
            }
        }
    }

    // MARK: - Сохранение стиха, на котором остановился читатель

    /// Записывает стих не на каждый кадр прокрутки, а когда страница остановилась на пару мгновений
    private func scheduleVerseSave() {
        tracker.saveTask?.cancel()
        tracker.saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            saveReadingVerseNow()
        }
    }

    /// Стих из ссылки или сохранённого места, только если он есть в этой главе (в другом переводе стихов бывает меньше): иначе глава с начала
    private func resolvedTargetVerse(in text: BibleChapterText) -> Int? {
        let maxVerse = text.verses.map { $0.verseNumber }.max() ?? 0
        return ReadingProgress.clampedVerse(targetVerse, maxVerse: maxVerse)
    }

    private func saveReadingVerseNow() {
        // Страницы соседних глав прогреваются заранее: менеджер пишет только за ту главу, что сейчас открыта у читателя
        manager.recordReadingScroll(bookId: book.id, chapter: chapter, verse: tracker.verseOnReadLine())
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
        triggerHaptic(.soft)
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
        Haptics.impact(style)
    }
}

