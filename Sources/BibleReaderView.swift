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
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        NarekatsiView()
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: manager.selectedReaderSection)
            }
            .onChange(of: manager.selectedReaderSection) { newSection in
                if newSection == 1 {
                    navigationPath = []
                }
            }
            .onAppear {
                // При входе на экран Библии всегда открываем каталог книг
                navigationPath = []
                manager.selectedReaderSection = 0
            }
            .onChange(of: manager.activeTabSelection) { newTab in
                if newTab == 3 {
                    // Пользователь нажал на таб Библии — сразу сбрасываем в корень каталога книг
                    navigationPath = []
                    manager.selectedReaderSection = 0
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

