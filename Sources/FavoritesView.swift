import SwiftUI
import UIKit

struct FavoritesView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var searchText = ""
    @State private var showingClearAlert = false
    
    // Экспорт открытки со стихом
    @State private var selectedVerseForShare: BibleVerse? = nil
    @State private var shareItem: ShareItem? = nil
    
    // Toast для уведомления о копировании
    @State private var showCopiedToast = false
    
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
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.75)
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
    
    private var filteredFavorites: [FavoriteItem] {
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
                            Text("favorites_title".localized(for: manager.appLanguage))
                                .font(.system(size: 26, weight: .bold, design: .default))
                                .foregroundColor(primaryTextColor)
                            
                            if !manager.favoriteVerses.isEmpty {
                                Text("\(manager.favoriteVerses.count) " + "favorites_count_format".localized(for: manager.appLanguage))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(secondaryAccentColor)
                            }
                        }
                        
                        Spacer()
                        
                        if !manager.favoriteVerses.isEmpty {
                            Button {
                                triggerHaptic(.medium)
                                showingClearAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(10)
                                    .background(Color.red.opacity(0.08))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Поисковая строка
                    if !manager.favoriteVerses.isEmpty {
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
                }
                .padding(.bottom, 16)
                
                // MARK: - Список карточек или Пустое состояние
                if filteredFavorites.isEmpty {
                    Spacer()
                    EmptyFavoritesView(hasSearchText: !searchText.isEmpty, language: manager.appLanguage)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
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
                                    onOpenBible: {
                                        openInBible(item)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                }
            }
            
            // MARK: - Toast скопированного текста
            if showCopiedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("copied_to_clipboard".localized(for: manager.appLanguage))
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
        .alert("favorites_clear_all".localized(for: manager.appLanguage), isPresented: $showingClearAlert) {
            Button("alert_cancel_button".localized(for: manager.appLanguage), role: .cancel) {}
            Button("favorites_clear_all".localized(for: manager.appLanguage), role: .destructive) {
                triggerHaptic(.heavy)
                withAnimation(.easeInOut(duration: 0.3)) {
                    manager.favoriteVerses.removeAll()
                }
            }
        } message: {
            Text("favorites_clear_confirm".localized(for: manager.appLanguage))
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.image])
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func copyFavorite(_ item: FavoriteItem) {
        triggerHaptic(.light)
        let textToCopy = "\(item.text(for: manager.appLanguage))\n— \(item.reference(for: manager.appLanguage))"
        UIPasteboard.general.string = textToCopy
        
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
    
    private func openInBible(_ item: FavoriteItem) {
        guard let bookId = item.bookId, let chapter = item.chapter else { return }
        triggerHaptic(.medium)
        manager.deepLinkBookId = bookId
        manager.deepLinkChapter = chapter
        if let verse = item.verseNumber {
            manager.deepLinkVerse = verse
        }
        manager.activeTabSelection = 3 // Переход во вкладку "Библия"
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
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
    
    @MainActor
    private func shareFavorite(_ item: FavoriteItem) {
        triggerHaptic(.medium)
        let verse = BibleVerse(
            id: item.id,
            category: .favorites,
            reference: item.reference(for: manager.appLanguage),
            text: item.text(for: manager.appLanguage),
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
        hostingController.view.backgroundColor = .clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let image = renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        
        self.shareItem = ShareItem(image: image)
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
                
                Image(systemName: hasSearchText ? "magnifyingglass" : "heart.slash.fill")
                    .font(.system(size: 38, weight: .light))
                    .foregroundColor(.red.opacity(0.7))
            }
            
            Text(hasSearchText ? "search_no_results".localized(for: language) : "favorites_empty_title".localized(for: language))
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
