import SwiftUI
import UIKit

struct FavoritesView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var searchText = ""
    @State private var showingClearAlert = false
    @State private var selectedSectionTab: Int = 0 // 0: Все, 1: Избранное, 2: Заметки, 3: Выделения
    @State private var selectedTagFilter: VerseTag? = nil
    
    // Редактирование выбранной заметки
    @State private var editingAnnotation: VerseAnnotation? = nil
    
    // Экспорт открытки со стихом и обоев
    @State private var selectedVerseForShare: BibleVerse? = nil
    @State private var selectedWallpaperVerse: BibleVerse? = nil
    @State private var shareItem: ShareItem? = nil
    
    // Toast для уведомления о копировании
    @State private var showCopiedToast = false
    @State private var toastMessage: String = ""
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var secondaryAccentColor: Color {
        Color(hex: manager.accentTheme.secondaryColorHex)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.85)
    }
    
    private var cardBorderColor: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    // MARK: - Фильтрация заметок и аннотаций
    private var filteredAnnotations: [VerseAnnotation] {
        var list = manager.allAnnotations
        
        // Фильтр по разделу
        if selectedSectionTab == 2 {
            // Только заметки
            list = list.filter { !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        } else if selectedSectionTab == 3 {
            // Только маркеры
            list = list.filter { $0.colorHex != nil && !$0.colorHex!.isEmpty }
        }
        
        // Фильтр по тегу
        if let tag = selectedTagFilter {
            list = list.filter { $0.tags.contains(tag) }
        }
        
        // Фильтр по поиску
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.text(for: manager.appLanguage).lowercased().contains(q) ||
                $0.reference(for: manager.appLanguage).lowercased().contains(q) ||
                $0.note.lowercased().contains(q)
            }
        }
        
        return list
    }
    
    // MARK: - Фильтрация избранных стихов
    private var filteredFavorites: [FavoriteItem] {
        if selectedSectionTab == 2 || selectedSectionTab == 3 {
            return []
        }
        if selectedTagFilter != nil {
            return [] // Избранное не имеет тегов напрямую
        }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return manager.favoriteVerses
        } else {
            let query = searchText.lowercased()
            return manager.favoriteVerses.filter { item in
                item.text(for: manager.appLanguage).lowercased().contains(query) ||
                item.reference(for: manager.appLanguage).lowercased().contains(query)
            }
        }
    }
    
    private var totalItemsCount: Int {
        if selectedSectionTab == 1 {
            return manager.favoriteVerses.count
        } else if selectedSectionTab == 2 {
            return manager.allAnnotations.filter { !$0.note.isEmpty }.count
        } else if selectedSectionTab == 3 {
            return manager.allAnnotations.filter { $0.colorHex != nil }.count
        } else {
            return manager.favoriteVerses.count + manager.allAnnotations.count
        }
    }
    
    var body: some View {
        ZStack {
            // MARK: - Фон
            backgroundColor.ignoresSafeArea()
            
            // Мягкое фоновое неоновое свечение
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(colorScheme == .dark ? 0.07 : 0.04), Color.clear]),
                center: .top,
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Заголовок экрана
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("notes_title".localized(for: manager.appLanguage))
                                .font(.system(size: 26, weight: .bold, design: .default))
                                .foregroundColor(primaryTextColor)
                            
                            if totalItemsCount > 0 {
                                Text("\(totalItemsCount) " + "favorites_count_format".localized(for: manager.appLanguage))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(secondaryAccentColor)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Переключатель вкладок: Все / Избранное / Заметки / Выделения
                    Picker("", selection: $selectedSectionTab) {
                        Text("notes_tab_all".localized(for: manager.appLanguage)).tag(0)
                        Text("notes_tab_favorites".localized(for: manager.appLanguage)).tag(1)
                        Text("notes_tab_notes".localized(for: manager.appLanguage)).tag(2)
                        Text("notes_tab_highlights".localized(for: manager.appLanguage)).tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .tint(accentColor)
                    
                    // Горизонтальная лента тегов для быстрой фильтрации
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Кнопка "Все теги"
                            Button {
                                triggerHaptic(.light)
                                selectedTagFilter = nil
                            } label: {
                                Text("all_tags_filter".localized(for: manager.appLanguage))
                                    .font(.system(size: 12, weight: selectedTagFilter == nil ? .bold : .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTagFilter == nil ? accentColor : cardBackgroundColor)
                                    .foregroundColor(selectedTagFilter == nil ? .white : primaryTextColor)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedTagFilter == nil ? accentColor : Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            ForEach(VerseTag.allCases) { tag in
                                let isSelected = selectedTagFilter == tag
                                Button {
                                    triggerHaptic(.light)
                                    if isSelected {
                                        selectedTagFilter = nil
                                    } else {
                                        selectedTagFilter = tag
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(tag.icon)
                                        Text(tag.localizedTitle(for: manager.appLanguage))
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color(hex: tag.colorHex).opacity(0.3) : cardBackgroundColor)
                                    .foregroundColor(isSelected ? Color(hex: tag.colorHex) : primaryTextColor)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(isSelected ? Color(hex: tag.colorHex) : Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 2)
                    }
                    
                    // Поисковая строка
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(primaryTextColor.opacity(0.4))
                        
                        TextField("favorites_search_placeholder".localized(for: manager.appLanguage), text: $searchText)
                            .font(.system(size: 15))
                            .foregroundColor(primaryTextColor)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(primaryTextColor.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(cardBackgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(primaryTextColor.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)
                
                // MARK: - Список карточек или Пустое состояние
                let showFavorites = (selectedSectionTab == 0 || selectedSectionTab == 1) && selectedTagFilter == nil
                let hasAnnotations = !filteredAnnotations.isEmpty
                let hasFavorites = showFavorites && !filteredFavorites.isEmpty
                
                if !hasAnnotations && !hasFavorites {
                    Spacer()
                    EmptyFavoritesView(hasSearchText: !searchText.isEmpty, language: manager.appLanguage)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            // Сначала отображаем заметки и выделения
                            ForEach(filteredAnnotations) { ann in
                                AnnotationCardView(
                                    annotation: ann,
                                    language: manager.appLanguage,
                                    cardBackgroundColor: cardBackgroundColor,
                                    cardBorderColor: cardBorderColor,
                                    primaryTextColor: primaryTextColor,
                                    secondaryAccentColor: secondaryAccentColor,
                                    onOpenBible: {
                                        openAnnotationInBible(ann)
                                    },
                                    onEdit: {
                                        editingAnnotation = ann
                                    },
                                    onDelete: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            manager.deleteAnnotation(bookId: ann.bookId, chapter: ann.chapter, verseNumber: ann.verseNumber)
                                        }
                                        showToast("note_deleted_toast".localized(for: manager.appLanguage))
                                    },
                                    onCopy: {
                                        copyAnnotation(ann)
                                    },
                                    onShare: {
                                        shareAnnotation(ann)
                                    }
                                )
                            }
                            
                            // Затем отображаем стихи из Избранного
                            if showFavorites {
                                ForEach(filteredFavorites) { item in
                                    FavoriteCardView(
                                        item: item,
                                        language: manager.appLanguage,
                                        cardBackgroundColor: cardBackgroundColor,
                                        cardBorderColor: cardBorderColor,
                                        primaryTextColor: primaryTextColor,
                                        secondaryAccentColor: secondaryAccentColor,
                                        onRemove: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                manager.removeFromFavorites(id: item.id)
                                            }
                                        },
                                        onShare: {
                                            shareFavorite(item)
                                        },
                                        onCopy: {
                                            copyFavorite(item)
                                        },
                                        onPinToWidget: {
                                            pinFavoriteToWidget(item)
                                        },
                                        onWallpaper: {
                                            let verse = BibleVerse(
                                                id: item.id,
                                                textHy: item.textHy,
                                                textRu: item.textRu,
                                                textEn: item.textEn,
                                                refHy: item.refHy,
                                                refRu: item.refRu,
                                                refEn: item.refEn
                                            )
                                            selectedWallpaperVerse = verse
                                        },
                                        onOpenBible: {
                                            openInBible(item)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                }
            }
            
            // MARK: - Toast уведомление
            if showCopiedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(25)
                    .shadow(radius: 10)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCopiedToast)
            }
        }
        .sheet(item: $editingAnnotation) { ann in
            if let book = BibleDatabase.shared.getBook(id: ann.bookId) {
                let v = BibleVerseText(
                    id: ann.verseNumber,
                    bookId: ann.bookId,
                    chapter: ann.chapter,
                    verseNumber: ann.verseNumber,
                    textHy: ann.textHy,
                    textRu: ann.textRu,
                    textEn: ann.textEn
                )
                VerseActionSheetView(
                    book: book,
                    chapter: ann.chapter,
                    verse: v,
                    language: manager.appLanguage,
                    accentColor: accentColor,
                    cardBackgroundColor: colorScheme == .dark ? Color.white.opacity(0.06) : Color.white,
                    cardBorderColor: cardBorderColor,
                    primaryTextColor: primaryTextColor,
                    onPinToWidget: {
                        manager.pinVerseToWidget(
                            textHy: ann.textHy,
                            textRu: ann.textRu,
                            textEn: ann.textEn,
                            refHy: ann.reference(for: .armenian),
                            refRu: ann.reference(for: .russian),
                            refEn: ann.reference(for: .english)
                        )
                        showToast("toast_pinned_to_widget".localized(for: manager.appLanguage))
                    },
                    onToggleFavorite: {
                        if manager.isFavorite(verseText: v) {
                            manager.removeFromFavorites(verseText: v)
                        } else {
                            manager.addToFavorites(verseText: v, bookName: book.name)
                        }
                    },
                    onCopy: {
                        copyAnnotation(ann)
                    },
                    onShare: {
                        shareAnnotation(ann)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
        }
        .sheet(item: $selectedWallpaperVerse) { verse in
            BibleWallpaperMakerView(verse: verse)
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
    
    private func copyFavorite(_ item: FavoriteItem) {
        triggerHaptic(.light)
        let textToCopy = "\(item.text(for: manager.appLanguage))\n— \(item.reference(for: manager.appLanguage))"
        UIPasteboard.general.string = textToCopy
        showToast("copied_to_clipboard".localized(for: manager.appLanguage))
    }
    
    private func copyAnnotation(_ ann: VerseAnnotation) {
        triggerHaptic(.light)
        var textToCopy = "\(ann.text(for: manager.appLanguage))\n— \(ann.reference(for: manager.appLanguage))"
        if !ann.note.isEmpty {
            textToCopy += "\n\n📝 \(ann.note)"
        }
        UIPasteboard.general.string = textToCopy
        showToast("copied_to_clipboard".localized(for: manager.appLanguage))
    }
    
    private func openInBible(_ item: FavoriteItem) {
        guard let bookId = item.bookId, let chapter = item.chapter else { return }
        triggerHaptic(.medium)
        manager.deepLinkBookId = bookId
        manager.deepLinkChapter = chapter
        if let verse = item.verseNumber {
            manager.deepLinkVerse = verse
        }
        manager.openBibleReader()
    }
    
    private func openAnnotationInBible(_ ann: VerseAnnotation) {
        triggerHaptic(.medium)
        manager.deepLinkBookId = ann.bookId
        manager.deepLinkChapter = ann.chapter
        manager.deepLinkVerse = ann.verseNumber
        manager.openBibleReader()
    }
    
    private func pinFavoriteToWidget(_ item: FavoriteItem) {
        triggerHaptic(.medium)
        manager.pinVerseToWidget(
            textHy: item.textHy,
            textRu: item.textRu,
            textEn: item.textEn,
            refHy: item.refHy,
            refRu: item.refRu,
            refEn: item.refEn
        )
        showToast("toast_pinned_to_widget".localized(for: manager.appLanguage))
    }
    
    @MainActor
    private func shareFavorite(_ item: FavoriteItem) {
        triggerHaptic(.medium)
        let verse = BibleVerse(
            id: item.id,
            textHy: item.textHy,
            textRu: item.textRu,
            textEn: item.textEn,
            refHy: item.refHy,
            refRu: item.refRu,
            refEn: item.refEn
        )
        
        let exportView = VerseCardExportView(
            verse: verse,
            theme: manager.accentTheme,
            colorScheme: colorScheme
        )
        
        let hostingController = UIHostingController(rootView: exportView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let image = renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        
        self.shareItem = ShareItem(image: image)
    }
    
    @MainActor
    private func shareAnnotation(_ ann: VerseAnnotation) {
        triggerHaptic(.medium)
        let verse = BibleVerse(
            id: ann.id,
            textHy: ann.textHy,
            textRu: ann.textRu,
            textEn: ann.textEn,
            refHy: ann.reference(for: .armenian),
            refRu: ann.reference(for: .russian),
            refEn: ann.reference(for: .english)
        )
        
        let exportView = VerseCardExportView(
            verse: verse,
            theme: manager.accentTheme,
            colorScheme: colorScheme
        )
        
        let hostingController = UIHostingController(rootView: exportView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let image = renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        
        self.shareItem = ShareItem(image: image)
    }
}

// MARK: - Карточка Заметки / Выделения
struct AnnotationCardView: View {
    let annotation: VerseAnnotation
    let language: AppLanguage
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let secondaryAccentColor: Color
    
    let onOpenBible: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Верхняя плашка: цвет маркера + теги + действия
            HStack(alignment: .center, spacing: 8) {
                if let colorHex = annotation.colorHex, !colorHex.isEmpty {
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                }
                
                Text(annotation.reference(for: language))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(secondaryAccentColor)
                
                Spacer()
                
                // Кнопка редактирования
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(secondaryAccentColor)
                        .padding(6)
                        .background(secondaryAccentColor.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Кнопка удаления
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(6)
                        .background(Color.red.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Текст стиха
            Text(annotation.text(for: language))
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(primaryTextColor)
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
            
            // Текст личной заметки (если есть)
            if !annotation.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 11, weight: .semibold))
                        Text("personal_note_title".localized(for: language))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(secondaryAccentColor)
                    
                    Text(annotation.note)
                        .font(.system(size: 13.5, weight: .regular, design: .serif))
                        .foregroundColor(primaryTextColor.opacity(0.9))
                        .lineSpacing(3)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(secondaryAccentColor.opacity(0.06))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(secondaryAccentColor.opacity(0.15), lineWidth: 1)
                )
            }
            
            // Теги
            if !annotation.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(annotation.tags) { tag in
                        HStack(spacing: 3) {
                            Text(tag.icon)
                                .font(.system(size: 10))
                            Text(tag.localizedTitle(for: language))
                                .font(.system(size: 10.5, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: tag.colorHex).opacity(0.16))
                        .foregroundColor(Color(hex: tag.colorHex))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Нижняя панель действий (Открыть в Библии, Копировать, Поделиться)
            HStack {
                Button {
                    onOpenBible()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 12))
                        Text("open_in_bible".localized(for: language))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(secondaryAccentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(secondaryAccentColor.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        onCopy()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                            .padding(8)
                            .background(primaryTextColor.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        onShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                            .padding(8)
                            .background(primaryTextColor.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackgroundColor)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1.2)
        )
    }
}

// MARK: - Карточка стиха из Избранного
struct FavoriteCardView: View {
    let item: FavoriteItem
    let language: AppLanguage
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let secondaryAccentColor: Color
    
    let onRemove: () -> Void
    let onShare: () -> Void
    let onCopy: () -> Void
    let onPinToWidget: () -> Void
    let onWallpaper: () -> Void
    let onOpenBible: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 20))
                    .foregroundColor(secondaryAccentColor.opacity(0.7))
                
                Spacer()
                
                // Кнопка сердечка (Удаление из Избранного)
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onRemove()
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Text(item.text(for: language))
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundColor(primaryTextColor)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text(item.reference(for: language))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(secondaryAccentColor)
                
                Spacer()
                
                // Кнопки управления (Скопировать, Закрепить на виджете, Поделиться, Открыть в Библии)
                HStack(spacing: 10) {
                    if item.bookId != nil && item.chapter != nil {
                        Button {
                            onOpenBible()
                        } label: {
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(secondaryAccentColor)
                                .padding(8)
                                .background(secondaryAccentColor.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    Button {
                        onPinToWidget()
                    } label: {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(secondaryAccentColor)
                            .padding(8)
                            .background(secondaryAccentColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        onWallpaper()
                    } label: {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(secondaryAccentColor)
                            .padding(8)
                            .background(secondaryAccentColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        onCopy()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                            .padding(8)
                            .background(primaryTextColor.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        onShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                            .padding(8)
                            .background(primaryTextColor.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardBackgroundColor)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1.2)
        )
    }
}

// MARK: - Пустое состояние (Empty State)
struct EmptyFavoritesView: View {
    let hasSearchText: Bool
    let language: AppLanguage
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.08))
                    .frame(width: 90, height: 90)
                
                Image(systemName: hasSearchText ? "magnifyingglass" : "note.text.badge.plus")
                    .font(.system(size: 38, weight: .light))
                    .foregroundColor(.red.opacity(0.7))
            }
            
            Text(hasSearchText ? "search_no_results".localized(for: language) : "no_notes_found".localized(for: language))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            if !hasSearchText {
                Text("favorites_empty_subtitle".localized(for: language))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
        }
        .padding(30)
    }
}

