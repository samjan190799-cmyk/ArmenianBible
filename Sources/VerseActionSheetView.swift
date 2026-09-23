import SwiftUI

// MARK: - Плашка действий над стихом (Маркеры + Заметки + Теги + Закрепить на виджет)
struct VerseActionSheetView: View {
    let book: BibleBook
    let chapter: Int
    let verse: BibleVerseText
    let language: AppLanguage
    let accentColor: Color
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    
    @ObservedObject var manager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedColorHex: String? = nil
    @State private var noteText: String = ""
    @State private var selectedTags: Set<VerseTag> = []
    
    let onPinToWidget: () -> Void
    let onToggleFavorite: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    
    private let colors: [(name: String, hex: String)] = [
        ("Gold", "FACC15"),
        ("Green", "4ADE80"),
        ("Blue", "38BDF8"),
        ("Purple", "C084FC"),
        ("Coral", "FB7185")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Цитата стиха
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verse.text(for: language))
                            .font(.system(size: 15, weight: .medium, design: .serif))
                            .foregroundColor(primaryTextColor)
                            .lineSpacing(5)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackgroundColor)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selectedColorHex != nil ? Color(hex: selectedColorHex!).opacity(0.6) : Color.primary.opacity(0.08), lineWidth: 1.5)
                    )
                    
                    // Выбор цвета маркера
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("highlight_color_title".localized(for: language))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Явная кнопка "Убрать цвет" / "Մաքրել գույնը"
                            if selectedColorHex != nil {
                                Button {
                                    triggerHaptic(.medium)
                                    selectedColorHex = nil
                                    saveChanges()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 12))
                                        Text("remove_highlight_btn".localized(for: language))
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red.opacity(0.12))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        
                        HStack(spacing: 14) {
                            ForEach(colors, id: \.hex) { c in
                                Button {
                                    triggerHaptic(.light)
                                    if selectedColorHex == c.hex {
                                        selectedColorHex = nil
                                    } else {
                                        selectedColorHex = c.hex
                                    }
                                    saveChanges()
                                } label: {
                                    Circle()
                                        .fill(Color(hex: c.hex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColorHex == c.hex ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                        .scaleEffect(selectedColorHex == c.hex ? 1.15 : 1.0)
                                        .shadow(color: Color(hex: c.hex).opacity(selectedColorHex == c.hex ? 0.4 : 0.15), radius: 3, y: 1.5)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            
                            Spacer()
                            
                            // Кнопка сброса цвета
                            Button {
                                triggerHaptic(.medium)
                                selectedColorHex = nil
                                saveChanges()
                            } label: {
                                ZStack {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.15), lineWidth: 1.5)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "slash.circle")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(selectedColorHex == nil ? .secondary : .red)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    
                    // Поле личной заметки
                    VStack(alignment: .leading, spacing: 8) {
                        Text("personal_note_title".localized(for: language))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("add_note_placeholder".localized(for: language), text: $noteText, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.system(size: 14))
                            .padding(12)
                            .background(cardBackgroundColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                            .keyboardDismissToolbar()
                            .onChange(of: noteText) { _ in
                                saveChanges()
                            }
                    }
                    
                    // Тематические теги
                    VStack(alignment: .leading, spacing: 8) {
                        Text("tags_section_title".localized(for: language))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(VerseTag.allCases) { tag in
                                let isSelected = selectedTags.contains(tag)
                                Button {
                                    triggerHaptic(.light)
                                    if isSelected {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                    saveChanges()
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(tag.icon)
                                        Text(tag.localizedTitle(for: language))
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color(hex: tag.colorHex).opacity(0.25) : cardBackgroundColor)
                                    .foregroundColor(isSelected ? Color(hex: tag.colorHex) : primaryTextColor.opacity(0.8))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? Color(hex: tag.colorHex) : Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Кнопки быстрых действий
                    VStack(spacing: 10) {
                        Button {
                            onPinToWidget()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .foregroundColor(accentColor)
                                Text("pin_to_widget".localized(for: language))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(primaryTextColor)
                                Spacer()
                            }
                            .padding(14)
                            .background(accentColor.opacity(0.12))
                            .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        HStack(spacing: 10) {
                            Button {
                                onToggleFavorite()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: manager.isFavorite(verseText: verse) ? "heart.slash.fill" : "heart.fill")
                                        .foregroundColor(.red)
                                    Text(manager.isFavorite(verseText: verse) ? "context_menu_remove_favorite".localized(for: language) : "context_menu_add_favorite".localized(for: language))
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(cardBackgroundColor)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Button {
                                onCopy()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(accentColor)
                                    Text("context_menu_copy".localized(for: language))
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(cardBackgroundColor)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Button {
                                onShare()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(accentColor)
                                    Text("context_menu_share".localized(for: language))
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(cardBackgroundColor)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("\(book.name) \(chapter):\(verse.verseNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                if let ann = manager.annotation(bookId: book.id, chapter: chapter, verseNumber: verse.verseNumber) {
                    selectedColorHex = ann.colorHex
                    noteText = ann.note
                    selectedTags = Set(ann.tags)
                } else if let hex = manager.highlightColor(bookId: book.id, chapter: chapter, verseNumber: verse.verseNumber) {
                    selectedColorHex = hex
                }
            }
        }
    }
    
    private func saveChanges() {
        var ann = manager.annotation(bookId: book.id, chapter: chapter, verseNumber: verse.verseNumber) ?? VerseAnnotation(
            bookId: book.id,
            chapter: chapter,
            verseNumber: verse.verseNumber,
            bookNameHy: book.nameHy,
            bookNameRu: book.nameRu,
            bookNameEn: book.nameEn,
            textHy: verse.textHy,
            textHyArarat: verse.textHyArarat,
            textRu: verse.textRu,
            textEn: verse.textEn
        )
        ann.colorHex = selectedColorHex
        ann.note = noteText
        ann.tags = Array(selectedTags)
        ann.updatedAt = Date()
        manager.saveAnnotation(ann)
        manager.setHighlight(
            bookId: book.id,
            chapter: chapter,
            verseNumber: verse.verseNumber,
            colorHex: selectedColorHex,
            bookNameHy: book.nameHy,
            bookNameRu: book.nameRu,
            bookNameEn: book.nameEn,
            textHy: verse.textHy,
            textHyArarat: verse.textHyArarat,
            textRu: verse.textRu,
            textEn: verse.textEn
        )
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

