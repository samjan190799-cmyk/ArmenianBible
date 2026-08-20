import SwiftUI
import UIKit
import Photos

// MARK: - Темы фонов для обоев
enum WallpaperTheme: String, CaseIterable, Identifiable {
    case ararat = "ararat"
    case tatev = "tatev"
    case khachkar = "khachkar"
    case parchment = "parchment"
    case bethlehem = "bethlehem"
    case sunset = "sunset"
    case graphite = "graphite"
    case royal = "royal"
    
    var id: String { rawValue }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .ararat:
            switch language {
            case .armenian: return "Արարատ"
            case .russian: return "Арарат"
            case .english: return "Ararat"
            }
        case .tatev:
            switch language {
            case .armenian: return "Տաթև"
            case .russian: return "Татев"
            case .english: return "Tatev"
            }
        case .khachkar:
            switch language {
            case .armenian: return "Խաչքար"
            case .russian: return "Хачкар"
            case .english: return "Khachkar"
            }
        case .parchment:
            switch language {
            case .armenian: return "Մագաղաթ"
            case .russian: return "Пергамент"
            case .english: return "Parchment"
            }
        case .bethlehem:
            switch language {
            case .armenian: return "Բեթղեհեմ"
            case .russian: return "Вифлеем"
            case .english: return "Bethlehem"
            }
        case .sunset:
            switch language {
            case .armenian: return "Մայրամուտ"
            case .russian: return "Закат"
            case .english: return "Sunset"
            }
        case .graphite:
            switch language {
            case .armenian: return "Գրաֆիտ"
            case .russian: return "Графит"
            case .english: return "Graphite"
            }
        case .royal:
            switch language {
            case .armenian: return "Ծիրանի"
            case .russian: return "Пурпур"
            case .english: return "Royal"
            }
        }
    }
    
    var colors: [Color] {
        switch self {
        case .ararat:
            return [Color(hex: "0F172A"), Color(hex: "1E293B"), Color(hex: "38BDF8").opacity(0.4), Color(hex: "F43F5E").opacity(0.3)]
        case .tatev:
            return [Color(hex: "020617"), Color(hex: "0F172A"), Color(hex: "1E3A5F"), Color(hex: "0EA5E9").opacity(0.3)]
        case .khachkar:
            return [Color(hex: "18181B"), Color(hex: "27272A"), Color(hex: "D97706").opacity(0.35), Color(hex: "B45309").opacity(0.2)]
        case .parchment:
            return [Color(hex: "292524"), Color(hex: "44403C"), Color(hex: "78716C"), Color(hex: "D97706").opacity(0.25)]
        case .bethlehem:
            return [Color(hex: "030712"), Color(hex: "0B132B"), Color(hex: "1C2541"), Color(hex: "6366F1").opacity(0.4)]
        case .sunset:
            return [Color(hex: "1A0B2E"), Color(hex: "3B185F"), Color(hex: "A12568"), Color(hex: "FEC260").opacity(0.35)]
        case .graphite:
            return [Color(hex: "090A0F"), Color(hex: "12141C"), Color(hex: "1E2230"), Color(hex: "64748B").opacity(0.2)]
        case .royal:
            return [Color(hex: "1E1035"), Color(hex: "311458"), Color(hex: "581C87"), Color(hex: "F59E0B").opacity(0.35)]
        }
    }
    
    var isLight: Bool {
        return false
    }
    
    var accentColor: Color {
        switch self {
        case .ararat: return Color(hex: "38BDF8")
        case .tatev: return Color(hex: "38BDF8")
        case .khachkar: return Color(hex: "F59E0B")
        case .parchment: return Color(hex: "FBBF24")
        case .bethlehem: return Color(hex: "818CF8")
        case .sunset: return Color(hex: "FB7185")
        case .graphite: return Color(hex: "94A3B8")
        case .royal: return Color(hex: "FBBF24")
        }
    }
}

// MARK: - Шрифты обоев
enum WallpaperFont: String, CaseIterable, Identifiable {
    case serif = "serif"
    case modern = "modern"
    case mono = "mono"
    
    var id: String { rawValue }
    
    var design: Font.Design {
        switch self {
        case .serif: return .serif
        case .modern: return .default
        case .mono: return .monospaced
        }
    }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .serif:
            switch language {
            case .armenian: return "Դասական"
            case .russian: return "Классика"
            case .english: return "Serif"
            }
        case .modern:
            switch language {
            case .armenian: return "Ժամանակակից"
            case .russian: return "Модерн"
            case .english: return "Modern"
            }
        case .mono:
            switch language {
            case .armenian: return "Մոնո"
            case .russian: return "Моно"
            case .english: return "Mono"
            }
        }
    }
}

// MARK: - Декоративные элементы обоев
enum WallpaperDecor: String, CaseIterable, Identifiable {
    case cross = "cross"
    case laurel = "laurel"
    case quote = "quote"
    case minimal = "minimal"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .cross: return "cross.fill"
        case .laurel: return "laurel.leading"
        case .quote: return "quote.opening"
        case .minimal: return "circle.slash"
        }
    }
    
    func title(for language: AppLanguage) -> String {
        switch self {
        case .cross:
            switch language {
            case .armenian: return "Խաչ"
            case .russian: return "Крест"
            case .english: return "Cross"
            }
        case .laurel:
            switch language {
            case .armenian: return "Դափնի"
            case .russian: return "Лавр"
            case .english: return "Laurel"
            }
        case .quote:
            switch language {
            case .armenian: return "Չակերտ"
            case .russian: return "Цитата"
            case .english: return "Quote"
            }
        case .minimal:
            switch language {
            case .armenian: return "Մաքուր"
            case .russian: return "Минимал"
            case .english: return "Minimal"
            }
        }
    }
}

// MARK: - Главный Экран Генератора Обоев
struct BibleWallpaperMakerView: View {
    let verse: BibleVerse
    @ObservedObject var manager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTheme: WallpaperTheme = .ararat
    @State private var selectedFont: WallpaperFont = .serif
    @State private var selectedDecor: WallpaperDecor = .cross
    @State private var selectedLanguage: AppLanguage = .armenian
    @State private var showLockScreenOverlay = true
    @State private var showSaveSuccessToast = false
    @State private var isExporting = false
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B0D13").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Область Предпросмотра Обоев iPhone
                    ZStack {
                        // Карточка-телефон с соотношением сторон iPhone
                        WallpaperCanvasView(
                            verse: verse,
                            theme: selectedTheme,
                            fontDesign: selectedFont,
                            decor: selectedDecor,
                            language: selectedLanguage,
                            showOverlay: showLockScreenOverlay
                        )
                        .frame(width: 220, height: 440)
                        .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 38, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.5
                                )
                        )
                        .shadow(color: selectedTheme.accentColor.opacity(0.25), radius: 24, x: 0, y: 12)
                        .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: 10)
                        
                        // Тост об успешном сохранении
                        if showSaveSuccessToast {
                            VStack {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.green)
                                    Text("wallpaper_saved_success".localized(for: manager.appLanguage))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .shadow(radius: 10)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                                Spacer()
                            }
                            .padding(.top, 16)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 12)
                    
                    // MARK: - Панель Настроек Обоев (Шторка управления)
                    VStack(spacing: 16) {
                        // 1. Селектор Темы / Фона
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("wallpaper_background_title".localized(for: manager.appLanguage))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Spacer()
                                
                                // Тумблер предпросмотра часов LockScreen
                                Button {
                                    triggerHaptic(.light)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showLockScreenOverlay.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: showLockScreenOverlay ? "clock.fill" : "clock")
                                            .font(.system(size: 11))
                                        Text("lockscreen_preview".localized(for: manager.appLanguage))
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(showLockScreenOverlay ? selectedTheme.accentColor : .white.opacity(0.5))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(WallpaperTheme.allCases) { theme in
                                        Button {
                                            triggerHaptic(.light)
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedTheme = theme
                                            }
                                        } label: {
                                            VStack(spacing: 6) {
                                                ZStack {
                                                    Circle()
                                                        .fill(
                                                            LinearGradient(
                                                                colors: theme.colors,
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .frame(width: 44, height: 44)
                                                    
                                                    if selectedTheme == theme {
                                                        Circle()
                                                            .stroke(Color.white, lineWidth: 2.5)
                                                            .frame(width: 50, height: 50)
                                                    }
                                                }
                                                
                                                Text(theme.title(for: manager.appLanguage))
                                                    .font(.system(size: 10, weight: selectedTheme == theme ? .bold : .medium))
                                                    .foregroundColor(selectedTheme == theme ? .white : .white.opacity(0.6))
                                            }
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // 2. Селекторы Стиля: Шрифт, Декор и Язык
                        HStack(spacing: 12) {
                            // Шрифт
                            Menu {
                                ForEach(WallpaperFont.allCases) { font in
                                    Button {
                                        triggerHaptic(.light)
                                        selectedFont = font
                                    } label: {
                                        Text(font.title(for: manager.appLanguage))
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "textformat")
                                        .font(.system(size: 12))
                                    Text(selectedFont.title(for: manager.appLanguage))
                                        .font(.system(size: 12, weight: .semibold))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                            }
                            
                            // Декор
                            Menu {
                                ForEach(WallpaperDecor.allCases) { decor in
                                    Button {
                                        triggerHaptic(.light)
                                        selectedDecor = decor
                                    } label: {
                                        Label(decor.title(for: manager.appLanguage), systemImage: decor.icon)
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: selectedDecor.icon)
                                        .font(.system(size: 12))
                                    Text(selectedDecor.title(for: manager.appLanguage))
                                        .font(.system(size: 12, weight: .semibold))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                            }
                            
                            // Язык стиха на обоях
                            Menu {
                                ForEach(AppLanguage.allCases) { lang in
                                    Button {
                                        triggerHaptic(.light)
                                        selectedLanguage = lang
                                    } label: {
                                        Text(lang.displayName)
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 12))
                                    Text(selectedLanguage.displayName)
                                        .font(.system(size: 12, weight: .semibold))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 3. Главная кнопка "Сохранить в Фотопленку"
                        Button {
                            triggerHaptic(.medium)
                            saveWallpaperToPhotos()
                        } label: {
                            HStack(spacing: 10) {
                                if isExporting {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "arrow.down.to.line.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("save_wallpaper_button".localized(for: manager.appLanguage))
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: [Color.white, Color(hex: "F1F5F9")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.white.opacity(0.2), radius: 10, y: 4)
                        }
                        .disabled(isExporting)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .padding(.top, 14)
                    .background(
                        ZStack {
                            Color(hex: "12151E")
                            Color.white.opacity(0.02)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    )
                }
            }
            .navigationTitle("wallpaper_maker_title".localized(for: manager.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        triggerHaptic(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .onAppear {
                selectedLanguage = manager.appLanguage
            }
        }
    }
    
    // MARK: - Рендеринг и Сохранение в Фотопленку
    @MainActor
    private func saveWallpaperToPhotos() {
        isExporting = true
        
        let fullResView = FullResolutionWallpaperView(
            verse: verse,
            theme: selectedTheme,
            fontDesign: selectedFont,
            decor: selectedDecor,
            language: selectedLanguage
        )
        .frame(width: 1170, height: 2532)
        
        let renderer = ImageRenderer(content: fullResView)
        renderer.scale = 1.0
        renderer.proposedSize = ProposedViewSize(width: 1170, height: 2532)
        
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showSaveSuccessToast = true
                isExporting = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showSaveSuccessToast = false
                }
            }
        } else {
            isExporting = false
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Холст предпросмотра обоев (с часами iOS Lock Screen)
struct WallpaperCanvasView: View {
    let verse: BibleVerse
    let theme: WallpaperTheme
    let fontDesign: WallpaperFont
    let decor: WallpaperDecor
    let language: AppLanguage
    let showOverlay: Bool
    
    var body: some View {
        ZStack {
            // Фон
            LinearGradient(
                colors: theme.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Художественные световые пятна
            RadialGradient(
                gradient: Gradient(colors: [theme.accentColor.opacity(0.35), Color.clear]),
                center: .center,
                startRadius: 20,
                endRadius: 180
            )
            
            VStack(spacing: 0) {
                // Верхний блок: Системные часы Lock Screen
                if showOverlay {
                    VStack(spacing: 2) {
                        Text(currentDateString(for: language))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.top, 28)
                        
                        Text("09:41")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(height: 100)
                } else {
                    Spacer().frame(height: 60)
                }
                
                Spacer()
                
                // Центральный блок: Стих и Ссылка
                VStack(spacing: 12) {
                    // Декоративный символ
                    if decor != .minimal {
                        Image(systemName: decor.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.accentColor.opacity(0.9))
                    }
                    
                    Text(verse.text(for: language))
                        .font(.system(size: 13, weight: .medium, design: fontDesign.design))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                    
                    Text(verse.reference(for: language))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.accentColor)
                        .padding(.top, 2)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .background(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 14)
                
                Spacer()
                
                // Нижний блок: Кнопки фонарика и камеры Lock Screen
                if showOverlay {
                    HStack {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 28, height: 28)
                            .overlay(Image(systemName: "flashlight.off.fill").font(.system(size: 11)).foregroundColor(.white))
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 28, height: 28)
                            .overlay(Image(systemName: "camera.fill").font(.system(size: 11)).foregroundColor(.white))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 22)
                } else {
                    Spacer().frame(height: 40)
                }
            }
        }
    }
    
    private func currentDateString(for language: AppLanguage) -> String {
        switch language {
        case .armenian: return "Հինգշաբթի, 20 Օգոստոսի"
        case .russian: return "Четверг, 20 Августа"
        case .english: return "Thursday, August 20"
        }
    }
}

// MARK: - Полноразмерный холст для генерации HD-файла (1170x2532)
struct FullResolutionWallpaperView: View {
    let verse: BibleVerse
    let theme: WallpaperTheme
    let fontDesign: WallpaperFont
    let decor: WallpaperDecor
    let language: AppLanguage
    
    var body: some View {
        ZStack {
            // Фон высокого разрешения
            LinearGradient(
                colors: theme.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Большое сияние
            RadialGradient(
                gradient: Gradient(colors: [theme.accentColor.opacity(0.4), Color.clear]),
                center: .center,
                startRadius: 50,
                endRadius: 700
            )
            
            VStack {
                Spacer()
                
                // Карточка со стихом в центре
                VStack(spacing: 36) {
                    if decor != .minimal {
                        Image(systemName: decor.icon)
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(theme.accentColor.opacity(0.9))
                    }
                    
                    Text(verse.text(for: language))
                        .font(.system(size: 46, weight: .medium, design: fontDesign.design))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(16)
                        .padding(.horizontal, 48)
                    
                    Text(verse.reference(for: language))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.accentColor)
                        .padding(.top, 8)
                }
                .padding(.vertical, 72)
                .padding(.horizontal, 54)
                .background(
                    RoundedRectangle(cornerRadius: 56, style: .continuous)
                        .fill(Color.black.opacity(0.42))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 56, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .padding(.horizontal, 70)
                
                Spacer()
                
                // Подпись приложения внизу
                VStack(spacing: 6) {
                    Text("ArmenianBible")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 90)
            }
        }
        .frame(width: 1170, height: 2532)
    }
}
