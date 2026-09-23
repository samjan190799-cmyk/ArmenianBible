import SwiftUI

// MARK: - Экран чтения стихов главы (с поддержкой свайпов и перелистывания)

struct BibleChapterReaderView: View {
    let book: BibleBook
    @State var initialChapter: Int
    let targetVerse: Int?
    
    @ObservedObject var manager = BibleManager.shared
    @State private var currentChapterIndex: Int = 0
    @State private var showNavigationHints = true
    @State private var animateHint = false
    @State private var showingChapterSheet = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    var body: some View {
        ZStack {
            PageCurlReaderView(
                book: book,
                currentChapterIndex: $currentChapterIndex,
                initialChapter: initialChapter,
                targetVerse: targetVerse
            ) { book, chapter, targetV in
                BibleSingleChapterView(book: book, chapter: chapter, targetVerse: targetV)
            }
            
            // Анимированные стрелки-подсказки перелистывания
            if showNavigationHints {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(accentColor.opacity(0.45))
                        .padding(.leading, 12)
                        .offset(x: animateHint ? -6 : 0)
                        .shadow(color: .black.opacity(0.15), radius: 2)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(accentColor.opacity(0.45))
                        .padding(.trailing, 12)
                        .offset(x: animateHint ? 6 : 0)
                        .shadow(color: .black.opacity(0.15), radius: 2)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        animateHint = true
                    }
                    // Плавно скрываем стрелочки через 4.5 секунды
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        withAnimation(.easeOut(duration: 0.8)) {
                            showNavigationHints = false
                        }
                    }
                }
                .allowsHitTesting(false) // Чтобы стрелочки не перехватывали жесты
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentChapterIndex = initialChapter - 1
            manager.saveLastReadLocation(bookId: book.id, chapter: initialChapter)
        }
        .onChange(of: currentChapterIndex) { newValue in
            let newChapter = newValue + 1
            manager.saveLastReadLocation(bookId: book.id, chapter: newChapter)
            // Если пользователь перелистнул сам, скрываем подсказки
            if showNavigationHints {
                withAnimation(.easeOut(duration: 0.4)) {
                    showNavigationHints = false
                }
            }
        }
        .toolbar {
            // Кастомный заголовок с возможностью выбора главы
            ToolbarItem(placement: .principal) {
                Button {
                    triggerHaptic(.light)
                    showingChapterSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("\(book.name) \(currentChapterIndex + 1)")
                            .font(.system(size: 17, weight: .bold, design: .serif))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    // Меню выбора перевода Библии
                    Menu {
                        Section("menu_translation_title".localized(for: manager.appLanguage)) {
                            Button {
                                manager.setAppLanguage(.armenian)
                                manager.setArmenianEdition(.ararat)
                            } label: {
                                HStack {
                                    Text("edition_ararat_title".localized(for: manager.appLanguage))
                                    if manager.appLanguage == .armenian && manager.armenianEdition == .ararat {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Button {
                                manager.setAppLanguage(.armenian)
                                manager.setArmenianEdition(.echmiadzin)
                            } label: {
                                HStack {
                                    Text("edition_echmiadzin_title".localized(for: manager.appLanguage))
                                    if manager.appLanguage == .armenian && manager.armenianEdition == .echmiadzin {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Button {
                                manager.setAppLanguage(.russian)
                            } label: {
                                HStack {
                                    Text("edition_russian".localized(for: manager.appLanguage))
                                    if manager.appLanguage == .russian {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Button {
                                manager.setAppLanguage(.english)
                            } label: {
                                HStack {
                                    Text("edition_english".localized(for: manager.appLanguage))
                                    if manager.appLanguage == .english {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "character.book.closed.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                    
                    // Единое меню настройки размера шрифта
                    Menu {
                        Button {
                            manager.setBibleFontSize(15.0)
                        } label: {
                            HStack {
                                Text("font_size_small".localized(for: manager.appLanguage))
                                if manager.bibleFontSize == 15.0 { Image(systemName: "checkmark") }
                            }
                        }
                        
                        Button {
                            manager.setBibleFontSize(18.0)
                        } label: {
                            HStack {
                                Text("font_size_medium".localized(for: manager.appLanguage))
                                if manager.bibleFontSize == 18.0 { Image(systemName: "checkmark") }
                            }
                        }
                        
                        Button {
                            manager.setBibleFontSize(22.0)
                        } label: {
                            HStack {
                                Text("font_size_large".localized(for: manager.appLanguage))
                                if manager.bibleFontSize == 22.0 { Image(systemName: "checkmark") }
                            }
                        }
                    } label: {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingChapterSheet) {
            VStack(spacing: 0) {
                // Заголовок шторки выбора глав
                HStack {
                    Text("\(book.name)")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                    Spacer()
                    Button {
                        showingChapterSheet = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                Divider()
                    .padding(.horizontal, 24)
                
                ScrollView {
                    let gridItems = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
                    
                    LazyVGrid(columns: gridItems, spacing: 12) {
                        ForEach(1...book.chaptersCount, id: \.self) { ch in
                            let isCurrent = currentChapterIndex == ch - 1
                            let isRead = manager.isChapterRead(bookId: book.id, chapter: ch)
                            ChapterSelectionCell(
                                chapter: ch,
                                isCurrent: isCurrent,
                                isRead: isRead,
                                accentColor: accentColor,
                                colorScheme: colorScheme
                            ) {
                                triggerHaptic(.light)
                                currentChapterIndex = ch - 1
                                showingChapterSheet = false
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Ячейка выбора главы в шторке (быстрая компиляция)

struct ChapterSelectionCell: View {
    let chapter: Int
    let isCurrent: Bool
    let isRead: Bool
    let accentColor: Color
    let colorScheme: ColorScheme
    let onSelect: () -> Void
    
    private var textColor: Color {
        if isCurrent { return .white }
        return colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    private var backgroundColor: Color {
        if isCurrent { return accentColor }
        if isRead { return accentColor.opacity(0.12) }
        return colorScheme == .dark ? Color.white.opacity(0.04) : Color.white
    }
    
    private var borderColor: Color {
        if isCurrent { return accentColor }
        if isRead { return accentColor.opacity(0.35) }
        return colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    
    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                Text("\(chapter)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(textColor)
                    .frame(width: 55, height: 55)
                    .background(backgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1.0)
                    )
                
                if isRead && !isCurrent {
                    Circle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: 6, height: 6)
                        .padding(6)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

