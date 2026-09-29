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
        manager.accentTheme.color
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
            
            // Список книг — оглавление на одном листе бумаги
            ScrollView {
                let filteredBooks = books.filter { selectedTestament == 0 ? !$0.isNewTestament : $0.isNewTestament }

                LazyVStack(spacing: 0) {
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
                                    .font(PaperFont.font(size: 14, weight: .semibold))
                                    .foregroundColor(accentColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(accentColor.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            Spacer(minLength: 40)
                        }
                    } else {
                        ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
                            let progress = manager.getBookProgress(bookId: book.id, totalChapters: book.chaptersCount)
                            Button {
                                let savedChapter = manager.getBookLastReadChapter(bookId: book.id)
                                navigationPath.append(.reader(book: book, chapter: savedChapter, targetVerse: nil))
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .center, spacing: 10) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(book.name)
                                                .font(PaperFont.font(size: 18))
                                                .foregroundColor(Paper.ink)

                                            HStack(spacing: 6) {
                                                Text("\(book.chaptersCount) \("chapters_count_label".localized(for: manager.appLanguage))")

                                                if progress.readCount > 0 {
                                                    Text("·")
                                                    Text("\(progress.readCount)/\(book.chaptersCount)")
                                                        .foregroundColor(progress.percent >= 1.0 ? Paper.gold : accentColor)
                                                }
                                            }
                                            .font(PaperFont.font(size: 13))
                                            .foregroundColor(Paper.inkSecondary)
                                        }

                                        Spacer()

                                        if progress.percent >= 1.0 {
                                            Image(systemName: "checkmark.seal")
                                                .font(.system(size: 15, weight: .regular))
                                                .foregroundColor(Paper.gold)
                                        }

                                        Text(book.shortName)
                                            .font(PaperFont.font(size: 13))
                                            .foregroundColor(Paper.inkTertiary)

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Paper.inkTertiary)
                                    }

                                    if progress.readCount > 0 && progress.percent < 1.0 {
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Paper.hairline)
                                                    .frame(height: 2)

                                                Capsule()
                                                    .fill(accentColor)
                                                    .frame(width: max(3, geo.size.width * CGFloat(min(progress.percent, 1.0))), height: 2)
                                                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: progress.percent)
                                            }
                                        }
                                        .frame(height: 2)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PaperRowButtonStyle())

                            if index < filteredBooks.count - 1 {
                                Rectangle()
                                    .fill(Paper.hairline)
                                    .frame(height: 1)
                                    .padding(.leading, 18)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .paperSheet(cornerRadius: 16)
                .animation(.spring(response: 0.38, dampingFraction: 0.85), value: selectedTestament)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Paper.page)
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
                            .font(PaperFont.font(size: 14, weight: .semibold))
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

