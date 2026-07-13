import SwiftUI

struct BibleReaderView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var navigationPath: [BibleNavigationState] = []
    @State private var showingSearch = false
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var backgroundColor: Color {
        Color(hex: manager.accentTheme.colorHex).opacity(0.03)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                BibleBookListView(navigationPath: $navigationPath)
            }
            .navigationTitle("tab_bible".localized(for: manager.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                BibleSearchView(navigationPath: $navigationPath, isPresented: $showingSearch)
            }
            .navigationDestination(for: BibleNavigationState.self) { state in
                switch state {
                case .chapters(let book):
                    BibleChapterSelectionView(book: book, navigationPath: $navigationPath)
                case .reader(let book, let chapter, let targetVerse):
                    BibleChapterReaderView(book: book, initialChapter: chapter, targetVerse: targetVerse)
                }
            }
            .onReceive(manager.$deepLinkBookId) { bookId in
                guard let bId = bookId else { return }
                // Сбрасываем триггер Deep Link в менеджере
                manager.deepLinkBookId = nil
                
                if let book = BibleDatabase.shared.getBook(id: bId) {
                    let chapter = manager.deepLinkChapter ?? 1
                    let verse = manager.deepLinkVerse
                    
                    manager.deepLinkChapter = nil
                    manager.deepLinkVerse = nil
                    
                    // Переходим напрямую в ридер
                    navigationPath = [.chapters(book: book), .reader(book: book, chapter: chapter, targetVerse: verse)]
                }
            }
        }
    }
}

// MARK: - Навигационные состояния

enum BibleNavigationState: Hashable {
    case chapters(book: BibleBook)
    case reader(book: BibleBook, chapter: Int, targetVerse: Int?)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .chapters(let book):
            hasher.combine("chapters")
            hasher.combine(book.id)
        case .reader(let book, let chapter, let verse):
            hasher.combine("reader")
            hasher.combine(book.id)
            hasher.combine(chapter)
            hasher.combine(verse)
        }
    }
    
    static func == (lhs: BibleNavigationState, rhs: BibleNavigationState) -> Bool {
        switch (lhs, rhs) {
        case (.chapters(let b1), .chapters(let b2)):
            return b1.id == b2.id
        case (.reader(let b1, let c1, let v1), .reader(let b2, let c2, let v2)):
            return b1.id == b2.id && c1 == c2 && v1 == v2
        default:
            return false
        }
    }
}

// MARK: - Список книг Библии

struct BibleBookListView: View {
    @ObservedObject var manager = BibleManager.shared
    @Binding var navigationPath: [BibleNavigationState]
    @State private var books: [BibleBook] = []
    @State private var selectedTestament = 0 // 0 - Ветхий Завет, 1 - Новый Завет
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var segmentedBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)
    }
    
    private var cardBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white
    }
    
    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Переключатель Заветов
            Picker("Testament", selection: $selectedTestament) {
                Text("testament_old".localized(for: manager.appLanguage)).tag(0)
                Text("testament_new".localized(for: manager.appLanguage)).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .tint(accentColor)
            
            // Список книг
            ScrollView {
                LazyVStack(spacing: 8) {
                    let filteredBooks = books.filter { selectedTestament == 0 ? !$0.isNewTestament : $0.isNewTestament }
                    
                    ForEach(filteredBooks) { book in
                        Button {
                            navigationPath.append(.chapters(book: book))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.name)
                                        .font(.system(size: 16, weight: .bold, design: .serif))
                                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                                    Text("\(book.chaptersCount) \("chapters_count_label".localized(for: manager.appLanguage))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(book.shortName)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(accentColor.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(accentColor.opacity(0.08))
                                    .cornerRadius(6)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(cardBgColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(cardBorderColor, lineWidth: 1.0)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            if books.isEmpty {
                books = BibleDatabase.shared.getBooks()
            }
        }
    }
}

// MARK: - Сетка выбора глав

struct BibleChapterSelectionView: View {
    let book: BibleBook
    @Binding var navigationPath: [BibleNavigationState]
    @ObservedObject var manager = BibleManager.shared
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var cardBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.white
    }
    
    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.name)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                        Text(book.isNewTestament ? "testament_new".localized(for: manager.appLanguage) : "testament_old".localized(for: manager.appLanguage))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(book.shortName)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Divider()
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: gridItems, spacing: 10) {
                    ForEach(1...book.chaptersCount, id: \.self) { chapter in
                        Button {
                            navigationPath.append(.reader(book: book, chapter: chapter, targetVerse: nil))
                        } label: {
                            Text("\(chapter)")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                                .frame(width: 55, height: 55)
                                .background(cardBgColor)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(cardBorderColor, lineWidth: 1.0)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Экран чтения стихов главы (с поддержкой свайпов)

struct BibleChapterReaderView: View {
    let book: BibleBook
    @State var initialChapter: Int
    let targetVerse: Int?
    
    @ObservedObject var manager = BibleManager.shared
    @State private var currentChapterIndex: Int = 0
    
    var body: some View {
        // Мы используем TabView с PageTabViewStyle для реализации свайпов по главам
        TabView(selection: $currentChapterIndex) {
            ForEach(1...book.chaptersCount, id: \.self) { chapter in
                BibleSingleChapterView(book: book, chapter: chapter, targetVerse: chapter == initialChapter ? targetVerse : nil)
                    .tag(chapter - 1)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .navigationTitle("\(book.name) \(currentChapterIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentChapterIndex = initialChapter - 1
        }
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
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var rowBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.02) : Color.white
    }
    
    private var highlightColor: Color {
        accentColor.opacity(colorScheme == .dark ? 0.18 : 0.12)
    }
    
    private var fontDesign: Font.Design {
        .serif
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            if let text = chapterText {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(text.verses) { verse in
                                HStack(alignment: .top, spacing: 14) {
                                    // Номер стиха
                                    Text("\(verse.verseNumber)")
                                        .font(.system(size: manager.bibleFontSize - 3, weight: .bold, design: .monospaced))
                                        .foregroundColor(accentColor.opacity(0.8))
                                        .frame(width: 28, alignment: .trailing)
                                        .padding(.top, 2)
                                    
                                    // Текст стиха
                                    Text(verse.text(for: manager.appLanguage))
                                        .font(.system(size: manager.bibleFontSize, weight: .regular, design: fontDesign))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "1E293B"))
                                        .lineSpacing(6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Кнопка избранного
                                    Button {
                                        triggerHaptic(.light)
                                        if manager.isFavorite(verseText: verse) {
                                            manager.removeFromFavorites(verseText: verse)
                                        } else {
                                            manager.addToFavorites(verseText: verse, bookName: book.name)
                                        }
                                    } label: {
                                        Image(systemName: manager.isFavorite(verseText: verse) ? "heart.fill" : "heart")
                                            .font(.system(size: 15))
                                            .foregroundColor(manager.isFavorite(verseText: verse) ? .red : .secondary.opacity(0.4))
                                            .padding(6)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(highlightedVerseId == verse.verseNumber ? highlightColor : Color.clear)
                                .id(verse.verseNumber)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // При тапе можно подсветить стих
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        highlightedVerseId = verse.verseNumber
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        if highlightedVerseId == verse.verseNumber {
                                            withAnimation(.easeInOut(duration: 0.8)) {
                                                highlightedVerseId = nil
                                            }
                                        }
                                    }
                                }
                                
                                Divider()
                                    .padding(.leading, 58)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onAppear {
                        // Скроллим к целевому стиху, если он передан (для Deep Link и поиска)
                        if let target = targetVerse {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                    proxy.scrollTo(target, anchor: .center)
                                }
                                highlightedVerseId = target
                            }
                            
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Кнопка настройки шрифта
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
    
    private func loadChapterText() {
        DispatchQueue.global(qos: .userInitiated).async {
            let data = BibleDatabase.shared.getChapterText(bookId: book.id, chapter: chapter)
            DispatchQueue.main.async {
                self.chapterText = data
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
