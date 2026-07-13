import SwiftUI

struct BibleSearchView: View {
    @Binding var navigationPath: [BibleNavigationState]
    @Binding var isPresented: Bool
    
    @ObservedObject var manager = BibleManager.shared
    @State private var searchQuery = ""
    @State private var searchResults: [BibleSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isSearchFieldFocused: Bool
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var cardBgColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white
    }
    
    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Строка ввода поиска
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("search_placeholder".localized(for: manager.appLanguage), text: $searchQuery)
                                .focused($isSearchFieldFocused)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .submitLabel(.search)
                                .onSubmit {
                                    performSearch()
                                }
                            
                            if !searchQuery.isEmpty {
                                Button {
                                    searchQuery = ""
                                    searchResults = []
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                        .cornerRadius(12)
                        
                        Button {
                            isPresented = false
                        } label: {
                            Text("search_cancel".localized(for: manager.appLanguage))
                                .foregroundColor(accentColor)
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    Divider()
                    
                    // Контент результатов поиска
                    if isSearching {
                        VStack(spacing: 12) {
                            Spacer()
                            ProgressView()
                                .tint(accentColor)
                            Text("search_loading".localized(for: manager.appLanguage))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else if searchResults.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 48))
                                .foregroundColor(accentColor.opacity(0.2))
                            Text(searchQuery.count >= 2 ? "search_no_results".localized(for: manager.appLanguage) : "search_instruction".localized(for: manager.appLanguage))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(searchResults) { result in
                                Button {
                                    navigateToResult(result)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(result.bookName)
                                                .font(.system(size: 14, weight: .bold, design: .serif))
                                                .foregroundColor(accentColor)
                                            Text("\(result.chapter):\(result.verseNumber)")
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        // Текст с подсветкой
                                        highlightedText(text: result.text, query: searchQuery)
                                            .font(.system(size: 14, weight: .regular, design: .serif))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.85) : Color(hex: "27272A"))
                                            .lineLimit(3)
                                            .lineSpacing(4)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .padding(.vertical, 6)
                                }
                                .listRowBackground(cardBgColor)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("search_title".localized(for: manager.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Заглушка, чтобы скрыть стандартную кнопку назад
                    EmptyView()
                }
            }
            .onChange(of: searchQuery) { newValue in
                searchTask?.cancel()
                if newValue.count >= 3 {
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        guard !Task.isCancelled else { return }
                        performSearch()
                    }
                } else if newValue.isEmpty {
                    searchResults = []
                }
            }
            .onAppear {
                isSearchFieldFocused = true
            }
        }
    }

    
    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return }
        
        isSearching = true
        
        DispatchQueue.global(qos: .userInteractive).async {
            let results = BibleDatabase.shared.search(query: query, language: manager.appLanguage)
            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
    
    private func navigateToResult(_ result: BibleSearchResult) {
        isPresented = false
        
        if let book = BibleDatabase.shared.getBook(id: result.bookId) {
            // Переключаем вкладку и осуществляем переход в стек
            manager.activeTabSelection = 3 // Вкладка "Библия"
            
            // Задержка, чтобы дать закрыться sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationPath = [
                    .chapters(book: book),
                    .reader(book: book, chapter: result.chapter, targetVerse: result.verseNumber)
                ]
            }
        }
    }
    
    // Подсветка искомого слова в тексте стиха
    private func highlightedText(text: String, query: String) -> Text {
        guard !query.isEmpty else { return Text(text) }
        
        let words = query.lowercased()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        guard !words.isEmpty else { return Text(text) }
        
        // Будем разбивать текст на фрагменты и подсвечивать те, что совпадают
        var currentText = text
        var resultText = Text("")
        
        // Для простоты подсветим точное совпадение поискового запроса
        let lowerText = text.lowercased()
        let lowerQuery = query.lowercased()
        
        if let range = lowerText.range(of: lowerQuery) {
            let startIdx = text.distance(from: text.startIndex, to: range.lowerBound)
            let endIdx = text.distance(from: text.startIndex, to: range.upperBound)
            
            let before = String(text.prefix(startIdx))
            let match = String(text.prefix(endIdx).suffix(endIdx - startIdx))
            let after = String(text.suffix(text.count - endIdx))
            
            resultText = resultText + Text(before)
            resultText = resultText + Text(match).bold().foregroundColor(accentColor)
            
            // Рекурсивно подсветим остаток строки (если есть еще совпадения)
            if after.lowercased().contains(lowerQuery) {
                resultText = resultText + highlightedText(text: after, query: query)
            } else {
                resultText = resultText + Text(after)
            }
            return resultText
        }
        
        return Text(text)
    }
}
