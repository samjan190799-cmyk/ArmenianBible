import SwiftUI
import UIKit

// MARK: - Нативный компонент для свободного выделения и копирования текста через UITextView
struct SelectableBibleTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let language: AppLanguage
    let onVerseTapped: (Int) -> Void
    let onRemoveHighlight: (Int) -> Void
    /// Стих, к которому надо прокрутить главу (переход по ссылке); вместе с `onVerseOffset`
    var scrollToVerse: Int? = nil
    /// Сообщает, на каком расстоянии от верха текста начинается нужный стих при текущей ширине
    var onVerseOffset: ((CGFloat) -> Void)? = nil

    func makeUIView(context: Context) -> UITextView {
        let textView = VerseTextView()
        textView.onLayout = { [weak coordinator = context.coordinator] view in
            coordinator?.reportVerseOffsetIfNeeded(in: view)
        }
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = context.coordinator
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.linkTextAttributes = [:]
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.delegate = context.coordinator
        textView.addGestureRecognizer(tapGesture)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
        context.coordinator.onVerseTapped = onVerseTapped
        context.coordinator.onRemoveHighlight = onRemoveHighlight
        context.coordinator.language = language
        context.coordinator.scrollToVerse = scrollToVerse
        context.coordinator.onVerseOffset = onVerseOffset
        // Текст мог смениться (другая глава, размер шрифта): положение стиха пересчитается при следующей раскладке
        uiView.setNeedsLayout()
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        // Ширину берём у самого окна, а не у экрана: на iPhone Duo окно бывает уже экрана (две колонки, отступ у строки состояния)
        let candidates: [CGFloat?] = [proposal.width, uiView.superview?.bounds.width, uiView.window?.bounds.width]
        // Без внятной ширины раскладку не навязываем: на нулевой ширине высота текста получилась бы огромной
        guard let width = candidates.compactMap({ $0 }).first(where: { $0 > 0 && $0.isFinite }) else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }

    /// Где в тексте начинается стих (по номеру стиха в атрибутах строки)
    static func verseLocation(in text: NSAttributedString, verse: Int) -> Int? {
        let verseKey = NSAttributedString.Key("verseNumber")
        var location: Int? = nil
        text.enumerateAttribute(verseKey, in: NSRange(location: 0, length: text.length)) { value, range, stop in
            if let number = value as? Int, number == verse {
                location = range.location
                stop.pointee = true
            }
        }
        return location
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(language: language, onVerseTapped: onVerseTapped, onRemoveHighlight: onRemoveHighlight)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var language: AppLanguage
        var onVerseTapped: (Int) -> Void
        var onRemoveHighlight: (Int) -> Void
        /// Для какого стиха, ширины и текста смещение уже сообщено
        var reportedOffsetKey: String? = nil
        var scrollToVerse: Int? = nil
        var onVerseOffset: ((CGFloat) -> Void)? = nil

        /// Положение стиха берётся у самого поля после его раскладки (firstRect работает и в TextKit 2):
        /// раньше его считала отдельная раскладка TextKit 1, а у неё строки чуть другой высоты,
        /// и к середине главы ошибка вырастала до десятков пунктов — стих уезжал под шапку.
        /// Сообщаем после текущего прохода вёрстки: менять состояние SwiftUI во время вёрстки нельзя.
        func reportVerseOffsetIfNeeded(in textView: UITextView) {
            guard let verse = scrollToVerse, let report = onVerseOffset else { return }
            let width = textView.bounds.width
            guard width > 0, textView.bounds.height > 0 else { return }
            let text = textView.attributedText ?? NSAttributedString()
            let key = "\(verse)@\(Int(width))#\(text.length)"
            guard reportedOffsetKey != key else { return }
            guard let start = SelectableBibleTextView.verseLocation(in: text, verse: verse),
                  let startPosition = textView.position(from: textView.beginningOfDocument, offset: start),
                  let endPosition = textView.position(from: startPosition, offset: 1),
                  let range = textView.textRange(from: startPosition, to: endPosition) else { return }
            let rect = textView.firstRect(for: range)
            guard !rect.isNull, !rect.isInfinite, rect.minY.isFinite else { return }
            reportedOffsetKey = key
            let offset = max(0, rect.minY)
            DispatchQueue.main.async { report(offset) }
        }

        init(language: AppLanguage, onVerseTapped: @escaping (Int) -> Void, onRemoveHighlight: @escaping (Int) -> Void) {
            self.language = language
            self.onVerseTapped = onVerseTapped
            self.onRemoveHighlight = onRemoveHighlight
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            
            // Если сейчас текст выделен, не перехватываем тап
            if textView.selectedRange.length > 0 {
                return
            }
            
            let point = gesture.location(in: textView)
            let layoutManager = textView.layoutManager
            let textContainer = textView.textContainer
            
            let characterIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            
            if characterIndex < textView.textStorage.length {
                if let verseNum = textView.textStorage.attribute(NSAttributedString.Key("verseNumber"), at: characterIndex, effectiveRange: nil) as? Int {
                    onVerseTapped(verseNum)
                }
            }
        }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            if URL.scheme == "verse" {
                let raw = (URL.host ?? URL.path).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if let verseNum = Int(raw) {
                    onVerseTapped(verseNum)
                    return false
                }
            }
            return true
        }
        
        @available(iOS 17.0, *)
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            if case .link(let url) = textItem.content, url.scheme == "verse" {
                let raw = (url.host ?? url.path).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if let verseNum = Int(raw) {
                    return UIAction { [weak self] _ in
                        self?.onVerseTapped(verseNum)
                    }
                }
            }
            return defaultAction
        }
        
        @available(iOS 16.0, *)
        func textView(_ textView: UITextView, editMenuFor textRange: UITextRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            let startOffset = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
            var targetVerseNum: Int? = nil
            
            if startOffset < textView.textStorage.length {
                targetVerseNum = textView.textStorage.attribute(NSAttributedString.Key("verseNumber"), at: startOffset, effectiveRange: nil) as? Int
            }
            
            var customActions: [UIMenuElement] = []
            
            if let vNum = targetVerseNum {
                let markerTitle = "edit_menu_marker".localized(for: language)
                let markerAction = UIAction(title: markerTitle, image: UIImage(systemName: "highlighter")) { [weak self] _ in
                    self?.onVerseTapped(vNum)
                }
                customActions.append(markerAction)
                
                let removeTitle = "remove_highlight_btn".localized(for: language)
                let removeAction = UIAction(title: removeTitle, image: UIImage(systemName: "slash.circle"), attributes: .destructive) { [weak self] _ in
                    self?.onRemoveHighlight(vNum)
                }
                customActions.append(removeAction)
            }
            
            var allActions = suggestedActions
            allActions.insert(contentsOf: customActions, at: 0)
            return UIMenu(children: allActions)
        }
    }
}


// MARK: - Поле текста главы, которое сообщает о своей раскладке
/// После каждой раскладки (готова ширина, текст разложен) просит координатора проверить,
/// где лежит целевой стих. Повторно ничего не считается: координатор помнит, что уже сообщил.
final class VerseTextView: UITextView {
    var onLayout: ((UITextView) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(self)
    }
}
