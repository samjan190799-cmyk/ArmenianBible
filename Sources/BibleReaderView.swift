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
                
                VStack(spacing: 0) {
                    Picker("", selection: $manager.selectedReaderSection) {
                        Text("tab_bible".localized(for: manager.appLanguage)).tag(0)
                        Text("narekatsi_title".localized(for: manager.appLanguage)).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    if manager.selectedReaderSection == 0 {
                        BibleBookListView(navigationPath: $navigationPath)
                    } else {
                        NarekatsiView()
                    }
                }
            }
            .onChange(of: manager.selectedReaderSection) { newSection in
                if newSection == 1 {
                    navigationPath = []
                }
            }
            .onAppear {
                if manager.selectedReaderSection == 1 {
                    navigationPath = []
                } else if !hasRestoredLocation {
                    hasRestoredLocation = true
                    if let bookId = manager.lastReadBookId,
                       let chapter = manager.lastReadChapter,
                       let book = BibleDatabase.shared.getBook(id: bookId) {
                        navigationPath = [
                            .reader(book: book, chapter: chapter, targetVerse: nil)
                        ]
                    }
                }
            }
            .navigationTitle(manager.selectedReaderSection == 0 ? "tab_bible".localized(for: manager.appLanguage) : "narekatsi_title".localized(for: manager.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if manager.selectedReaderSection == 0 {
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
            }
            .sheet(isPresented: $showingSearch) {
                BibleSearchView(navigationPath: $navigationPath, isPresented: $showingSearch)
            }
            .navigationDestination(for: BibleNavigationState.self) { state in
                switch state {
                case .reader(let book, let chapter, let targetVerse):
                    BibleChapterReaderView(book: book, initialChapter: chapter, targetVerse: targetVerse)
                }
            }
            .onReceive(manager.$deepLinkBookId) { bookId in
                guard let bId = bookId else { return }
                manager.deepLinkBookId = nil
                
                if let book = BibleDatabase.shared.getBook(id: bId) {
                    let chapter = manager.deepLinkChapter ?? 1
                    let verse = manager.deepLinkVerse
                    
                    manager.deepLinkChapter = nil
                    manager.deepLinkVerse = nil
                    
                    navigationPath = [
                        .reader(book: book, chapter: chapter, targetVerse: verse)
                    ]
                }
            }
        }
    }
}

// MARK: - Навигационные состояния

enum BibleNavigationState: Hashable {
    case reader(book: BibleBook, chapter: Int, targetVerse: Int?)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .reader(let book, let chapter, let verse):
            hasher.combine("reader")
            hasher.combine(book.id)
            hasher.combine(chapter)
            hasher.combine(verse)
        }
    }
    
    static func == (lhs: BibleNavigationState, rhs: BibleNavigationState) -> Bool {
        switch (lhs, rhs) {
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
    @State private var books: [BibleBook] = BibleDatabase.shared.getBooks()
    @State private var selectedTestament = 0 // 0 - Ветхий Завет, 1 - Новый Завет
    @State private var showingLibrarySheet = false
    
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
    
    private var retryButtonText: String {
        switch manager.appLanguage {
        case .armenian: return "Կրկնել բեռնումը"
        case .russian: return "Повторить загрузку"
        case .english: return "Retry Loading"
        }
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
            
            // MARK: - Баннерная Реклама Meta (на самом видном месте над списком книг Библии)
            BannerAdView()
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            
            // Список книг
            ScrollView {
                LazyVStack(spacing: 8) {
                    let filteredBooks = books.filter { selectedTestament == 0 ? !$0.isNewTestament : $0.isNewTestament }
                    
                    if filteredBooks.isEmpty {
                        VStack(spacing: 12) {
                            Spacer(minLength: 40)
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.4))
                            Button {
                                books = BibleDatabase.shared.getBooks()
                            } label: {
                                Text(retryButtonText)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(accentColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(accentColor.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            Spacer(minLength: 40)
                        }
                    } else {
                        ForEach(filteredBooks) { book in
                            Button {
                                let savedChapter = manager.getBookLastReadChapter(bookId: book.id)
                                navigationPath.append(.reader(book: book, chapter: savedChapter, targetVerse: nil))
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("tab_bible".localized(for: manager.appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingLibrarySheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(manager.appLanguage.displayName)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(accentColor)
                }
            }
        }
        .sheet(isPresented: $showingLibrarySheet) {
            BibleLibrarySheetView(isPresented: $showingLibrarySheet)
                .presentationDetents([.height(460)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if books.isEmpty {
                books = BibleDatabase.shared.getBooks()
            }
        }
        .onChange(of: manager.appLanguage) { _ in
            // Мгновенно обновляем список книг при смене языка Библии
            books = BibleDatabase.shared.getBooks()
        }
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
        context.coordinator.parent = self
        
        if context.coordinator.currentBookId != book.id {
            context.coordinator.currentBookId = book.id
            context.coordinator.controllersMap.removeAll()
        }
        
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
        var currentBookId: Int
        var controllersMap: [Int: PageViewControllerContainer<Content>] = [:]
        
        init(_ parent: PageCurlReaderView) {
            self.parent = parent
            self.currentBookId = parent.book.id
        }
        
        func viewController(for index: Int) -> UIViewController {
            // Ограничиваем кэш до 5 страниц вокруг текущей, предотвращая утечку памяти
            if controllersMap.count > 5 {
                let keepRange = max(0, index - 2)...min(parent.book.chaptersCount, index + 2)
                for k in Array(controllersMap.keys) {
                    if !keepRange.contains(k) {
                        controllersMap.removeValue(forKey: k)
                    }
                }
            }
            
            let targetV = (index + 1 == parent.initialChapter) ? parent.targetVerse : nil
            let contentView = parent.contentBuilder(parent.book, index + 1, targetV)
            
            if let cached = controllersMap[index] {
                cached.rootView = contentView
                return cached
            }
            
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
                            Button {
                                triggerHaptic(.light)
                                currentChapterIndex = ch - 1
                                showingChapterSheet = false
                            } label: {
                                Text("\(ch)")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(currentChapterIndex == ch - 1 ? .white : (colorScheme == .dark ? .white : Color(hex: "1E293B")))
                                    .frame(width: 55, height: 55)
                                    .background(currentChapterIndex == ch - 1 ? accentColor : (colorScheme == .dark ? Color.white.opacity(0.04) : Color.white))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(currentChapterIndex == ch - 1 ? accentColor : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)), lineWidth: 1.0)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
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
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            // Текстура бумаги
            Color.black.opacity(colorScheme == .dark ? 0.03 : 0.015)
                .blendMode(.overlay)
                .ignoresSafeArea()
            
            // Эффект вогнутости страницы (тень у корешка слева и изгиб у внешнего края справа)
            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.26 : 0.08),
                    Color.clear,
                    Color.black.opacity(colorScheme == .dark ? 0.07 : 0.02)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
            
            if let text = chapterText {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
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
                            .padding(.bottom, 20)
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
                                            .font(.system(size: 13, weight: .bold))
                                        Text("personal_note_title".localized(for: manager.appLanguage))
                                            .font(.system(size: 13, weight: .bold))
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
                                                        .font(.system(size: 12, weight: .bold, design: .serif))
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
                                                        .font(.system(size: 13, weight: .regular, design: .serif))
                                                        .foregroundColor(primaryTextColor)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(rowBgColor)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
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
                cardBackgroundColor: colorScheme == .dark ? Color.white.opacity(0.06) : Color.white,
                cardBorderColor: LinearGradient(colors: [Color.primary.opacity(0.1), Color.primary.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing),
                primaryTextColor: colorScheme == .dark ? .white : Color(hex: "1E293B"),
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
        let textColor = colorScheme == .dark ? UIColor.white.withAlphaComponent(0.92) : UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1.0)
        let uiAccentColor = UIColor(Color(hex: manager.accentTheme.colorHex))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 7
        paragraphStyle.paragraphSpacing = 16
        
        let fontDescriptor = UIFont.systemFont(ofSize: fontSize, weight: .regular).fontDescriptor.withDesign(.serif) ?? UIFont.systemFont(ofSize: fontSize).fontDescriptor
        let font = UIFont(descriptor: fontDescriptor, size: fontSize)
        
        let numDescriptor = UIFont.boldSystemFont(ofSize: max(11, fontSize * 0.65)).fontDescriptor.withDesign(.serif) ?? UIFont.boldSystemFont(ofSize: max(11, fontSize * 0.65)).fontDescriptor
        let numFont = UIFont(descriptor: numDescriptor, size: max(11, fontSize * 0.65))
        
        let verseKey = NSAttributedString.Key("verseNumber")
        
        for (index, verse) in text.verses.enumerated() {
            // Номер стиха надстрочным шрифтом с кликабельной ссылкой
            let numAttrs: [NSAttributedString.Key: Any] = [
                .font: numFont,
                .foregroundColor: uiAccentColor,
                .baselineOffset: fontSize * 0.25,
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
                result.append(NSAttributedString(string: "\n\n", attributes: [.paragraphStyle: paragraphStyle]))
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

// MARK: - FlowLayout для красивого выравнивания чипсов тегов
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: containerWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
