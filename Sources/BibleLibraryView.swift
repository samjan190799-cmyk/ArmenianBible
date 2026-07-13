import SwiftUI

// MARK: - Модель для описания книги
struct BookEdition: Identifiable {
    let id: Int
    let language: AppLanguage
    let title: String
    let subtitleKey: String
    let coverColors: [Color]
    let accentColor: Color
    let languageName: String
}

struct BibleLibraryView: View {
    @ObservedObject var manager = BibleManager.shared
    @Binding var navigationPath: [BibleNavigationState]
    @State private var selectedBookIndex = 0
    @State private var dragOffset: CGSize = .zero
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Список трех книг на трех языках
    private let editions = [
        BookEdition(
            id: 0,
            language: .armenian,
            title: "Աստվածաշունչ",
            subtitleKey: "edition_armenian_subtitle",
            coverColors: [Color(hex: "6A0B1A"), Color(hex: "3B040B")],
            accentColor: Color(hex: "D4AF37"), // Золотой
            languageName: "ՀԱՅԵՐԵՆ"
        ),
        BookEdition(
            id: 1,
            language: .russian,
            title: "Библия",
            subtitleKey: "edition_russian_subtitle",
            coverColors: [Color(hex: "0F2347"), Color(hex: "060E1E")],
            accentColor: Color(hex: "E5C158"), // Золотой теплый
            languageName: "РУССКИЙ"
        ),
        BookEdition(
            id: 2,
            language: .english,
            title: "Holy Bible",
            subtitleKey: "edition_english_subtitle",
            coverColors: [Color(hex: "3E2723"), Color(hex: "1F0F0C")],
            accentColor: Color(hex: "CFAC62"), // Латунный золотой
            languageName: "ENGLISH"
        )
    ]
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    var body: some View {
        ZStack {
            // Красивый мягкий градиент на фоне
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "090E17"), Color(hex: "030508")]
                    : [Color(hex: "F8FAFC"), Color(hex: "EEF2F6")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Заголовок библиотеки
                VStack(spacing: 6) {
                    Text("library_title".localized(for: manager.appLanguage))
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                    
                    Text("library_subtitle".localized(for: manager.appLanguage))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 24)
                
                Spacer()
                
                // 3D Карусель книг
                ZStack {
                    // Размытый фоновый круг под книгой для создания глубины и свечения
                    Circle()
                        .fill(editions[selectedBookIndex].coverColors[0].opacity(0.12))
                        .frame(width: 320, height: 320)
                        .blur(radius: 50)
                        .offset(y: -10)
                        .animation(.easeInOut(duration: 0.5), value: selectedBookIndex)
                    
                    TabView(selection: $selectedBookIndex) {
                        ForEach(0..<editions.count, id: \.self) { index in
                            let edition = editions[index]
                            let isSelected = index == selectedBookIndex
                            
                            BookCoverContainer(isSelected: isSelected, dragOffset: isSelected ? dragOffset : .zero) {
                                BookCoverContentView(edition: edition)
                            }
                            .gesture(
                                isSelected ? DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                                            dragOffset = .zero
                                        }
                                    }
                                : nil
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 340)
                }
                
                Spacer()
                
                // Подзаголовок издания и описание
                VStack(spacing: 12) {
                    let currentEdition = editions[selectedBookIndex]
                    
                    Text(currentEdition.subtitleKey.localized(for: manager.appLanguage))
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "334155"))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id("subtitle_\(selectedBookIndex)")
                    
                    // Точки навигации (Page Indicator)
                    HStack(spacing: 6) {
                        ForEach(0..<editions.count, id: \.self) { index in
                            Circle()
                                .fill(index == selectedBookIndex ? accentColor : Color.secondary.opacity(0.3))
                                .frame(width: index == selectedBookIndex ? 8 : 6, height: index == selectedBookIndex ? 8 : 6)
                                .scaleEffect(index == selectedBookIndex ? 1.2 : 1.0)
                                .animation(.spring(), value: selectedBookIndex)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Кнопка Читать
                    Button {
                        triggerSelection()
                    } label: {
                        HStack(spacing: 8) {
                            Text("button_read_bible".localized(for: manager.appLanguage))
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "book.fill")
                                .font(.system(size: 15))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(accentColor)
                                .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 10)
                }
                .padding(.bottom, 48)
            }
        }
        .onChange(of: selectedBookIndex) { _ in
            triggerHaptic(.light)
        }
    }
    
    // Переход к выбору книг Библии
    private func triggerSelection() {
        triggerHaptic(.medium)
        let selectedEdition = editions[selectedBookIndex]
        
        // Меняем язык в менеджере (это обновит всё приложение)
        withAnimation {
            manager.setAppLanguage(selectedEdition.language)
        }
        
        // Переходим к списку книг
        navigationPath.append(.bookList(language: selectedEdition.language))
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - 3D Контейнер Книги
struct BookCoverContainer<Content: View>: View {
    let content: Content
    let thickness: CGFloat = 18
    let isSelected: Bool
    let dragOffset: CGSize
    
    init(isSelected: Bool, dragOffset: CGSize, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.dragOffset = dragOffset
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Боковой срез страниц (активен при развороте)
            PagesSideShape()
                .frame(width: thickness, height: 268)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .shadow(color: .black.opacity(0.15), radius: 2, x: 2, y: 0)
                // Поворачиваем боковой срез на 90 градусов в 3D
                .rotation3DEffect(.degrees(90), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                .offset(x: -thickness / 2)
            
            // Обложка книги
            content
                .frame(width: 180, height: 270)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: .black.opacity(isSelected ? 0.4 : 0.2), radius: isSelected ? 16 : 8, x: isSelected ? 10 : 4, y: isSelected ? 12 : 6)
        }
        // 3D вращение книги:
        // Базовый поворот -22 градуса, чтобы видеть объем среза страниц справа
        .rotation3DEffect(
            .degrees(isSelected ? Double(dragOffset.width / 5) - 22 : -10),
            axis: (x: 0, y: 1, z: 0)
        )
        .rotation3DEffect(
            .degrees(isSelected ? Double(-dragOffset.height / 5) + 6 : 2),
            axis: (x: 1, y: 0, z: 0)
        )
        .scaleEffect(isSelected ? 1.05 : 0.82)
        .opacity(isSelected ? 1.0 : 0.65)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: isSelected)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: dragOffset)
    }
}

// MARK: - Имитация текстуры страниц
struct PagesSideShape: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(hex: "FCF9F2"), Color(hex: "E8DDC7"), Color(hex: "D7C5A3")],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            
            // Мелкие горизонтальные полосы для симуляции стопки страниц
            VStack(spacing: 2) {
                ForEach(0..<65) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 1)
                }
            }
        }
    }
}

// MARK: - Внутреннее оформление обложки
struct BookCoverContentView: View {
    let edition: BookEdition
    
    var body: some View {
        ZStack {
            // Цвет обложки
            LinearGradient(
                colors: edition.coverColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Текстура кожи
            Color.black.opacity(0.12)
                .blendMode(.overlay)
            
            // Золотая тисненая рамка
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    LinearGradient(
                        colors: [edition.accentColor.opacity(0.85), edition.accentColor.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(10)
            
            // Тиснение элементов обложки
            VStack(spacing: 16) {
                Spacer()
                
                // Декоративный элемент сверху
                Image(systemName: "crown")
                    .font(.system(size: 16))
                    .foregroundColor(edition.accentColor)
                    .opacity(0.7)
                
                // Золотой крест
                Image(systemName: "cross.fill")
                    .font(.system(size: 44))
                    .foregroundColor(edition.accentColor)
                    .shadow(color: edition.accentColor.opacity(0.4), radius: 5)
                
                Spacer()
                
                // Тексты на обложке
                VStack(spacing: 8) {
                    Text(edition.title)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Text("HOLY SCRIPTURES")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(edition.accentColor.opacity(0.85))
                        .tracking(2)
                }
                
                Spacer()
                
                // Языковой тег снизу
                Text(edition.languageName)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(4)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
