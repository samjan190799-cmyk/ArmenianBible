import SwiftUI

struct BibleReaderView: View {
    @ObservedObject var manager = BibleManager.shared
    @State private var navigationPath: [BibleNavigationState] = []
    @State private var showingSearch = false
    @State private var hasRestoredLocation = false
    
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
                
                BibleLibraryView(navigationPath: $navigationPath)
            }
            .onAppear {
                if !hasRestoredLocation {
                    hasRestoredLocation = true
                    if let bookId = manager.lastReadBookId,
                       let chapter = manager.lastReadChapter,
                       let book = BibleDatabase.shared.getBook(id: bookId) {
                        // Восстанавливаем с шагом bookList для правильного стэка переходов "Назад"
                        navigationPath = [
                            .bookList(language: manager.appLanguage),
                            .chapters(book: book),
                            .reader(book: book, chapter: chapter, targetVerse: nil)
                        ]
                    }
                }
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
                case .bookList(let language):
                    BibleBookListView(language: language, navigationPath: $navigationPath)
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
                    
                    // Переходим напрямую в ридер с правильной вложенностью
                    navigationPath = [
                        .bookList(language: manager.appLanguage),
                        .chapters(book: book),
                        .reader(book: book, chapter: chapter, targetVerse: verse)
                    ]
                }
            }
        }
    }
}

// MARK: - Навигационные состояния

enum BibleNavigationState: Hashable {
    case bookList(language: AppLanguage)
    case chapters(book: BibleBook)
    case reader(book: BibleBook, chapter: Int, targetVerse: Int?)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .bookList(let language):
            hasher.combine("bookList")
            hasher.combine(language.rawValue)
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
        case (.bookList(let l1), .bookList(let l2)):
            return l1 == l2
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
    let language: AppLanguage
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
        .navigationTitle(language.displayName)
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - UIPageViewController обертка для эффекта перелистывания страниц (Page Curl)

struct PageCurlReaderView<Content: View>: UIViewControllerRepresentable {
    let book: BibleBook
    @Binding var currentChapterIndex: Int
    let initialChapter: Int
    let targetVerse: Int?
    let contentBuilder: (BibleBook, Int, Int?) -> Content
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        pageViewController.view.backgroundColor = .clear
        
        let initialVC = context.coordinator.viewController(for: currentChapterIndex)
        pageViewController.setViewControllers([initialVC], direction: .forward, animated: false, completion: nil)
        
        return pageViewController
    }
    
    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        let displayedVC = uiViewController.viewControllers?.first as? PageViewControllerContainer<Content>
        if let currentChapter = displayedVC?.chapter, currentChapter - 1 != currentChapterIndex {
            let direction: UIPageViewController.NavigationDirection = (currentChapter - 1 < currentChapterIndex) ? .forward : .reverse
            let targetVC = context.coordinator.viewController(for: currentChapterIndex)
            uiViewController.setViewControllers([targetVC], direction: direction, animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlReaderView
        var controllersMap: [Int: PageViewControllerContainer<Content>] = [:]
        
        init(_ parent: PageCurlReaderView) {
            self.parent = parent
        }
        
        func viewController(for index: Int) -> UIViewController {
            if let cached = controllersMap[index] {
                return cached
            }
            
            let targetV = (index + 1 == parent.initialChapter) ? parent.targetVerse : nil
            let contentView = parent.contentBuilder(parent.book, index + 1, targetV)
            
            let hostVC = PageViewControllerContainer(rootView: contentView, chapter: index + 1)
            controllersMap[index] = hostVC
            return hostVC
        }
        
        // MARK: - UIPageViewControllerDataSource
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let currentVC = viewController as? PageViewControllerContainer<Content> else { return nil }
            let index = currentVC.chapter - 1
            guard index > 0 else { return nil }
            return self.viewController(for: index - 1)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let currentVC = viewController as? PageViewControllerContainer<Content> else { return nil }
            let index = currentVC.chapter - 1
            guard index < parent.book.chaptersCount - 1 else { return nil }
            return self.viewController(for: index + 1)
        }
        
        // MARK: - UIPageViewControllerDelegate
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
               let visibleVC = pageViewController.viewControllers?.first as? PageViewControllerContainer<Content> {
                let newIndex = visibleVC.chapter - 1
                if parent.currentChapterIndex != newIndex {
                    parent.currentChapterIndex = newIndex
                }
            }
        }
    }
}

class PageViewControllerContainer<Content: View>: UIHostingController<Content> {
    var chapter: Int
    
    init(rootView: Content, chapter: Int) {
        self.chapter = chapter
        super.init(rootView: rootView)
        self.view.backgroundColor = .clear
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Экран чтения стихов главы (с поддержкой свайпов и перелистывания)

struct BibleChapterReaderView: View {
    let book: BibleBook
    @State var initialChapter: Int
    let targetVerse: Int?
    
    @ObservedObject var manager = BibleManager.shared
    @State private var currentChapterIndex: Int = 0
    
    var body: some View {
        PageCurlReaderView(
            book: book,
            currentChapterIndex: $currentChapterIndex,
            initialChapter: initialChapter,
            targetVerse: targetVerse
        ) { book, chapter, targetV in
            BibleSingleChapterView(book: book, chapter: chapter, targetVerse: targetV)
        }
        .navigationTitle("\(book.name) \(currentChapterIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentChapterIndex = initialChapter - 1
            manager.saveLastReadLocation(bookId: book.id, chapter: initialChapter)
        }
        .onChange(of: currentChapterIndex) { newValue in
            let newChapter = newValue + 1
            manager.saveLastReadLocation(bookId: book.id, chapter: newChapter)
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
        colorScheme == .dark ? Color(hex: "121316") : Color(hex: "F4EFEB")
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
            
            // Текстура бумаги
            Color.black.opacity(colorScheme == .dark ? 0.03 : 0.015)
                .blendMode(.overlay)
                .ignoresSafeArea()
            
            // Мягкая тень корешка книги слева
            LinearGradient(
                colors: [Color.black.opacity(colorScheme == .dark ? 0.28 : 0.09), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ignoresSafeArea()
            
            if let text = chapterText {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Книжный заголовок главы
                            VStack(spacing: 8) {
                                Text(book.name)
                                    .font(.system(size: 28, weight: .bold, design: .serif))
                                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                                
                                Text("\("chapter_title_label".localized(for: manager.appLanguage)) \(chapter)")
                                    .font(.system(size: 18, weight: .medium, design: .serif))
                                    .foregroundColor(accentColor)
                                
                                // Изящная классическая виньетка
                                HStack(spacing: 12) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(accentColor.opacity(0.5))
                                        .rotationEffect(.degrees(-45))
                                    
                                    Rectangle()
                                        .fill(accentColor.opacity(0.2))
                                        .frame(width: 35, height: 1)
                                    
                                    Image(systemName: "cross.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(accentColor.opacity(0.7))
                                    
                                    Rectangle()
                                        .fill(accentColor.opacity(0.2))
                                        .frame(width: 35, height: 1)
                                    
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(accentColor.opacity(0.5))
                                        .rotationEffect(.degrees(45))
                                }
                                .padding(.top, 4)
                            }
                            .padding(.top, 36)
                            .padding(.bottom, 28)
                            .frame(maxWidth: .infinity)
                            
                            ForEach(text.verses) { verse in
                                VStack(alignment: .leading, spacing: 0) {
                                    (
                                        Text("\(verse.verseNumber) ")
                                            .font(.system(size: manager.bibleFontSize - 4, weight: .bold, design: fontDesign))
                                            .foregroundColor(accentColor.opacity(0.85))
                                        +
                                        Text(verse.text(for: manager.appLanguage))
                                            .font(.system(size: manager.bibleFontSize, weight: .regular, design: fontDesign))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "1E293B"))
                                    )
                                    .lineSpacing(7)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(highlightedVerseId == verse.verseNumber ? highlightColor : Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        triggerHaptic(.light)
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
                                    .contextMenu {
                                        Button {
                                            copyToClipboard(verse: verse)
                                        } label: {
                                            Label("context_menu_copy".localized(for: manager.appLanguage), systemImage: "doc.on.doc")
                                        }
                                        
                                        Button {
                                            shareVerse(verse: verse)
                                        } label: {
                                            Label("context_menu_share".localized(for: manager.appLanguage), systemImage: "square.and.arrow.up")
                                        }
                                        
                                        Button {
                                            toggleFavorite(verse: verse)
                                        } label: {
                                            if manager.isFavorite(verseText: verse) {
                                                Label("context_menu_remove_favorite".localized(for: manager.appLanguage), systemImage: "heart.slash.fill")
                                            } else {
                                                Label("context_menu_add_favorite".localized(for: manager.appLanguage), systemImage: "heart")
                                            }
                                        }
                                    }
                                }
                                .id(verse.verseNumber)
                            }
                            
                            // Номер страницы (номер текущей главы)
                            VStack(spacing: 8) {
                                Divider()
                                    .background(accentColor.opacity(0.15))
                                    .padding(.horizontal, 48)
                                
                                Text("— \(chapter) —")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(accentColor.opacity(0.6))
                                    .padding(.top, 4)
                            }
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 32)
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
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
