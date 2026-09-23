import SwiftUI
import UIKit

// MARK: - Нативный компонент для свободного выделения и копирования текста через UITextView
struct SelectableBibleTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let language: AppLanguage
    let onVerseTapped: (Int) -> Void
    let onRemoveHighlight: (Int) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
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
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(language: language, onVerseTapped: onVerseTapped, onRemoveHighlight: onRemoveHighlight)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var language: AppLanguage
        var onVerseTapped: (Int) -> Void
        var onRemoveHighlight: (Int) -> Void
        
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

