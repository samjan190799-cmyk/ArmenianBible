import SwiftUI

// MARK: - Модель для описания книги в шторке
struct SheetBookEdition: Identifiable {
    let id: Int
    let language: AppLanguage
    let title: String
    let subtitleKey: String
    let coverColors: [Color]
    let accentColor: Color
    let languageName: String
}

struct BibleLibrarySheetView: View {
    @ObservedObject var manager = BibleManager.shared
    @Binding var isPresented: Bool
    
    @State private var selectedBookIndex = 0
    @State private var dragOffset: CGSize = .zero
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Список трех книг на трех языках
    private let editions = [
        SheetBookEdition(
            id: 0,
            language: .armenian,
            title: "Աստվածաշունչ",
            subtitleKey: "edition_armenian_subtitle",
            coverColors: [Color(hex: "6A0B1A"), Color(hex: "3B040B")],
            accentColor: Color(hex: "D4AF37"), // Золотой
            languageName: "ՀԱՅԵՐԵՆ"
        ),
        SheetBookEdition(
            id: 1,
            language: .russian,
            title: "Библия",
            subtitleKey: "edition_russian_subtitle",
            coverColors: [Color(hex: "0F2347"), Color(hex: "060E1E")],
            accentColor: Color(hex: "E5C158"), // Золотой теплый
            languageName: "РУССКИЙ"
        ),
        SheetBookEdition(
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
            // Фон шторки
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "141A24"), Color(hex: "0E1219")]
                    : [Color(hex: "F8FAFC"), Color(hex: "F1F5F9")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Заголовок шторки
                VStack(spacing: 4) {
                    Text("library_title".localized(for: manager.appLanguage))
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1E293B"))
                    
                    Text("library_subtitle".localized(for: manager.appLanguage))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                
                Spacer()
                
                // 3D Карусель книг (чуть уменьшенный масштаб для шторки)
                ZStack {
                    Circle()
                        .fill(editions[selectedBookIndex].coverColors[0].opacity(0.1))
                        .frame(width: 260, height: 260)
                        .blur(radius: 40)
                        .offset(y: -10)
                        .animation(.easeInOut(duration: 0.5), value: selectedBookIndex)
                    
                    TabView(selection: $selectedBookIndex) {
                        ForEach(0..<editions.count, id: \.self) { index in
                            let edition = editions[index]
                            let isSelected = index == selectedBookIndex
                            
                            SheetBookCoverContainer(isSelected: isSelected, dragOffset: isSelected ? dragOffset : .zero) {
                                SheetBookCoverContentView(edition: edition)
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
                    .frame(height: 250)
                }
                
                Spacer()
                
                // Подзаголовок издания и кнопка
                VStack(spacing: 12) {
                    let currentEdition = editions[selectedBookIndex]
                    
                    Text(currentEdition.subtitleKey.localized(for: manager.appLanguage))
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "334155"))
                        .id("subtitle_\(selectedBookIndex)")
                    
                    // Кнопка Читать
                    Button {
                        triggerSelection()
                    } label: {
                        HStack(spacing: 8) {
                            Text("button_read_bible".localized(for: manager.appLanguage))
                                .font(.system(size: 15, weight: .bold))
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor)
                                .shadow(color: accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            // При открытии шторки устанавливаем фокус на текущий язык
            if let currentIndex = editions.firstIndex(where: { $0.language == manager.appLanguage }) {
                selectedBookIndex = currentIndex
            }
        }
        .onChange(of: selectedBookIndex) { _ in
            triggerHaptic(.light)
        }
    }
    
    // Применение выбора и закрытие шторки
    private func triggerSelection() {
        triggerHaptic(.medium)
        let selectedEdition = editions[selectedBookIndex]
        
        withAnimation {
            manager.setAppLanguage(selectedEdition.language)
        }
        
        // Закрываем шторку
        isPresented = false
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - 3D Контейнер Книги в шторке
struct SheetBookCoverContainer<Content: View>: View {
    let content: Content
    let thickness: CGFloat = 14
    let isSelected: Bool
    let dragOffset: CGSize
    
    init(isSelected: Bool, dragOffset: CGSize, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.dragOffset = dragOffset
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Боковой срез страниц
            SheetPagesSideShape()
                .frame(width: thickness, height: 188)
                .clipShape(RoundedRectangle(cornerRadius: 1))
                .shadow(color: .black.opacity(0.15), radius: 2, x: 2, y: 0)
                .rotation3DEffect(.degrees(90), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                .offset(x: -thickness / 2)
            
            // Обложка книги (размер уменьшен со 180x270 до 126x190)
            content
                .frame(width: 126, height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: .black.opacity(isSelected ? 0.35 : 0.15), radius: isSelected ? 12 : 6, x: isSelected ? 8 : 3, y: isSelected ? 10 : 4)
        }
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

// MARK: - Имитация текстуры страниц в шторке
struct SheetPagesSideShape: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(hex: "FCF9F2"), Color(hex: "E8DDC7"), Color(hex: "D7C5A3")],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            
            VStack(spacing: 2) {
                ForEach(0..<45) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 1)
                }
            }
        }
    }
}

// MARK: - Внутреннее оформление обложки в шторке
struct SheetBookCoverContentView: View {
    let edition: SheetBookEdition
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: edition.coverColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Color.black.opacity(0.12)
                .blendMode(.overlay)
            
            RoundedRectangle(cornerRadius: 5)
                .stroke(
                    LinearGradient(
                        colors: [edition.accentColor.opacity(0.85), edition.accentColor.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .padding(7)
            
            VStack(spacing: 10) {
                Spacer()
                
                Image(systemName: "cross.fill")
                    .font(.system(size: 30))
                    .foregroundColor(edition.accentColor)
                    .shadow(color: edition.accentColor.opacity(0.4), radius: 3)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(edition.title)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Text("HOLY SCRIPTURES")
                        .font(.system(size: 6, weight: .semibold, design: .monospaced))
                        .foregroundColor(edition.accentColor.opacity(0.85))
                        .tracking(1.5)
                }
                
                Spacer()
                
                Text(edition.languageName)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(3)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
