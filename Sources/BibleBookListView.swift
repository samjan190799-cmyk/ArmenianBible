import SwiftUI

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
            
            // MARK: - Баннерная Реклама VK (LuysHybridBannerView)
            LuysHybridBannerView(placement: .reader)
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
                            let progress = manager.getBookProgress(bookId: book.id, totalChapters: book.chaptersCount)
                            Button {
                                let savedChapter = manager.getBookLastReadChapter(bookId: book.id)
                                navigationPath.append(.reader(book: book, chapter: savedChapter, targetVerse: nil))
                            } label: {
                                VStack(spacing: 8) {
                                    HStack(alignment: .center) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(book.name)
                                                .font(.system(size: 16, weight: .bold, design: .serif))
                                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                                            
                                            HStack(spacing: 6) {
                                                Text("\(book.chaptersCount) \("chapters_count_label".localized(for: manager.appLanguage))")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.secondary)
                                                
                                                if progress.readCount > 0 {
                                                    Text("•")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.secondary.opacity(0.4))
                                                    
                                                    Text("\(progress.readCount)/\(book.chaptersCount)")
                                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                                        .foregroundColor(progress.percent >= 1.0 ? Color(hex: "34D399") : accentColor)
                                                    
                                                    Text("(\(Int(progress.percent * 100))%)")
                                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                                        .foregroundColor(progress.percent >= 1.0 ? Color(hex: "34D399") : .secondary)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 6) {
                                            if progress.percent >= 1.0 {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(Color(hex: "10B981"))
                                                    .transition(.scale.combined(with: .opacity))
                                            }
                                            
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
                                    }
                                    
                                    if progress.readCount > 0 {
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                                                    .frame(height: 3)
                                                
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: progress.percent >= 1.0
                                                                ? [Color(hex: "10B981"), Color(hex: "34D399")]
                                                                : [accentColor.opacity(0.7), accentColor],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: max(4, geo.size.width * CGFloat(min(progress.percent, 1.0))), height: 3)
                                                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: progress.percent)
                                            }
                                        }
                                        .frame(height: 3)
                                    }
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
                .animation(.spring(response: 0.38, dampingFraction: 0.85), value: selectedTestament)
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

