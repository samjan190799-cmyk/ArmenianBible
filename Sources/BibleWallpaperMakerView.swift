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
            return [Color(hex: "060B19"), Color(hex: "172554"), Color(hex: "BE185D"), Color(hex: "F59E0B")]
        case .tatev:
            return [Color(hex: "020617"), Color(hex: "0F172A"), Color(hex: "0369A1"), Color(hex: "0D9488")]
        case .khachkar:
            return [Color(hex: "18181B"), Color(hex: "27272A"), Color(hex: "78350F"), Color(hex: "D97706")]
        case .parchment:
            return [Color(hex: "1C1917"), Color(hex: "44403C"), Color(hex: "78716C"), Color(hex: "B45309")]
        case .bethlehem:
            return [Color(hex: "020617"), Color(hex: "0B132B"), Color(hex: "1E1B4B"), Color(hex: "4338CA")]
        case .sunset:
            return [Color(hex: "1E1B4B"), Color(hex: "581C87"), Color(hex: "9D174D"), Color(hex: "EA580C")]
        case .graphite:
            return [Color(hex: "090A0F"), Color(hex: "12141C"), Color(hex: "1E2230"), Color(hex: "334155")]
        case .royal:
            return [Color(hex: "180828"), Color(hex: "3B0764"), Color(hex: "581C87"), Color(hex: "D97706")]
        }
    }
    
    var accentColor: Color {
        switch self {
        case .ararat: return Color(hex: "FDE047")
        case .tatev: return Color(hex: "38BDF8")
        case .khachkar: return Color(hex: "FBBF24")
        case .parchment: return Color(hex: "FDE68A")
        case .bethlehem: return Color(hex: "A5B4FC")
        case .sunset: return Color(hex: "FDBA74")
        case .graphite: return Color(hex: "E2E8F0")
        case .royal: return Color(hex: "FCD34D")
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
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTheme: WallpaperTheme = .ararat
    @State private var selectedFont: WallpaperFont = .serif
    @State private var selectedDecor: WallpaperDecor = .cross
    @State private var selectedLanguage: AppLanguage = .armenian
    @State private var showLockScreenOverlay = true
    @State private var showSaveSuccessToast = false
    @State private var isExporting = false
    @State private var isShowingPaywall = false
    @State private var isShowingAutomationSheet = false
    
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
                    
                    // MARK: - Панель Настроек Обоев
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
                                        let isPro = (theme == .royal || theme == .bethlehem || theme == .khachkar)
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
                                                    
                                                    if isPro && !subscriptionManager.isPremium {
                                                        Image(systemName: "crown.fill")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.black)
                                                            .padding(4)
                                                            .background(Color(hex: "FDE68A"))
                                                            .clipShape(Circle())
                                                            .offset(x: 16, y: -16)
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
                        
                        // 2. Селекторы: Шрифт, Декор и Язык
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        triggerHaptic(.light)
                        isShowingAutomationSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("auto_wallpaper_nav_button".localized(for: manager.appLanguage))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "FDE047"))
                    }
                }
                
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
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $isShowingAutomationSheet) {
                WallpaperAutomationSheetView()
            }
        }
    }
    
    // MARK: - Рендеринг и Сохранение в Фотопленку
    @MainActor
    private func saveWallpaperToPhotos() {
        let isProTheme = (selectedTheme == .royal || selectedTheme == .bethlehem || selectedTheme == .khachkar)
        if isProTheme && !subscriptionManager.isPremium {
            triggerHaptic(.medium)
            isShowingPaywall = true
            return
        }
        
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.executeSaveWallpaper()
                    }
                }
            }
        } else if status == .authorized || status == .limited {
            executeSaveWallpaper()
        } else {
            triggerHaptic(.medium)
        }
    }
    
    @MainActor
    private func executeSaveWallpaper() {
        isExporting = true
        
        let fullResView = FullResolutionWallpaperView(
            verse: verse,
            theme: selectedTheme,
            fontDesign: selectedFont,
            decor: selectedDecor,
            language: selectedLanguage
        )
        .frame(width: 1170, height: 2532)
        
        let hostingController = UIHostingController(rootView: fullResView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1170, height: 2532)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1170, height: 2532))
        let uiImage = renderer.image { _ in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
        }) { success, _ in
            DispatchQueue.main.async {
                self.isExporting = false
                if success {
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.success)
                    
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        self.showSaveSuccessToast = true
                    }
                    
                    // Показ межстраничной рекламы Meta при соблюдении кулдауна
                    AdManager.shared.recordActionAndShowInterstitialIfReady()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.showSaveSuccessToast = false
                        }
                    }
                }
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Художественный фон обоев (Арарат, Татев, Хачкар, Манускрипт и т.д.)
struct WallpaperArtBackground: View {
    let theme: WallpaperTheme
    
    var body: some View {
        ZStack {
            // Базовый градиент
            LinearGradient(
                colors: theme.colors,
                startPoint: .top,
                endPoint: .bottom
            )
            
            switch theme {
            case .ararat:
                // Силуэт горы Арарат на рассвете
                ZStack {
                    // Солнечный диск на горизонте
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "FDE047").opacity(0.8), Color(hex: "F59E0B").opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(y: 60)
                    
                    // Силуэт гор (Masis & Sis)
                    GeometryReader { geo in
                        Path { path in
                            let w = geo.size.width
                            let h = geo.size.height
                            let base = h * 0.78
                            
                            path.move(to: CGPoint(x: 0, y: h))
                            path.addLine(to: CGPoint(x: 0, y: base))
                            // Малый Арарат (Сис)
                            path.addLine(to: CGPoint(x: w * 0.28, y: base - h * 0.15))
                            path.addLine(to: CGPoint(x: w * 0.44, y: base - h * 0.05))
                            // Большой Арарат (Масис)
                            path.addLine(to: CGPoint(x: w * 0.68, y: base - h * 0.26))
                            path.addLine(to: CGPoint(x: w * 0.88, y: base - h * 0.08))
                            path.addLine(to: CGPoint(x: w, y: base))
                            path.addLine(to: CGPoint(x: w, y: h))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1E1B4B").opacity(0.85), Color(hex: "090A0F")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // Снежные шапки Арарата
                        Path { path in
                            let w = geo.size.width
                            let h = geo.size.height
                            let base = h * 0.78
                            
                            // Снег на Масисе
                            path.move(to: CGPoint(x: w * 0.68, y: base - h * 0.26))
                            path.addLine(to: CGPoint(x: w * 0.62, y: base - h * 0.19))
                            path.addLine(to: CGPoint(x: w * 0.74, y: base - h * 0.18))
                            path.closeSubpath()
                        }
                        .fill(Color.white.opacity(0.45))
                    }
                }
                
            case .tatev:
                // Монастырь Татев над ущельем
                ZStack {
                    RadialGradient(
                        colors: [Color(hex: "0284C7").opacity(0.4), Color.clear],
                        center: .top,
                        startRadius: 20,
                        endRadius: 260
                    )
                    
                    // Силуэт купола храма внизу
                    VStack {
                        Spacer()
                        Image(systemName: "cross.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "38BDF8").opacity(0.6))
                            .padding(.bottom, 4)
                        
                        // Арка и купол
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "0F172A").opacity(0.85), Color(hex: "020617")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 70)
                            .overlay(
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.white.opacity(0.15))
                            )
                    }
                }
                
            case .khachkar:
                // Резной орнамент армянского хачкара
                ZStack {
                    RadialGradient(
                        colors: [Color(hex: "D97706").opacity(0.35), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                    
                    // Золотой крест Хачкара на фоне
                    VStack(spacing: 0) {
                        Image(systemName: "cross.fill")
                            .font(.system(size: 80, weight: .ultraLight))
                            .foregroundColor(Color(hex: "F59E0B").opacity(0.18))
                    }
                }
                
            case .parchment:
                // Древний манускрипт Матенадарана
                ZStack {
                    Color(hex: "292524").opacity(0.3)
                    // Тонкая рамка манускрипта
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "D97706").opacity(0.25), lineWidth: 1.5)
                        .padding(14)
                }
                
            case .bethlehem:
                // Вифлеемская Звезда и ночное небо
                ZStack {
                    RadialGradient(
                        colors: [Color(hex: "818CF8").opacity(0.4), Color.clear],
                        center: .top,
                        startRadius: 10,
                        endRadius: 200
                    )
                    
                    VStack {
                        Image(systemName: "sparkle")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(Color(hex: "E0E7FF"))
                            .shadow(color: Color(hex: "818CF8"), radius: 12)
                            .padding(.top, 40)
                        Spacer()
                    }
                }
                
            case .sunset:
                // Закат над Армянским нагорьем
                ZStack {
                    RadialGradient(
                        colors: [Color(hex: "FB7185").opacity(0.45), Color(hex: "EA580C").opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 240
                    )
                }
                
            case .graphite:
                // Чистый премиальный темный оникс
                ZStack {
                    RadialGradient(
                        colors: [Color(hex: "334155").opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 200
                    )
                }
                
            case .royal:
                // Королевский пурпур и сияние
                ZStack {
                    RadialGradient(
                        colors: [Color(hex: "F59E0B").opacity(0.3), Color(hex: "7C3AED").opacity(0.2), Color.clear],
                        center: .top,
                        startRadius: 20,
                        endRadius: 240
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Адаптивный расчет размера шрифта для слабовидящих
func wallpaperFontSize(for text: String, isFullRes: Bool) -> CGFloat {
    let count = text.count
    if count <= 45 {
        return isFullRes ? 80 : 20
    } else if count <= 85 {
        return isFullRes ? 68 : 17
    } else if count <= 135 {
        return isFullRes ? 58 : 14.5
    } else {
        return isFullRes ? 50 : 12.5
    }
}

// MARK: - Холст предпросмотра обоев (адаптированный под весь экран)
struct WallpaperCanvasView: View {
    let verse: BibleVerse
    let theme: WallpaperTheme
    let fontDesign: WallpaperFont
    let decor: WallpaperDecor
    let language: AppLanguage
    let showOverlay: Bool
    
    var body: some View {
        let verseText = verse.text(for: language)
        let fontSize = wallpaperFontSize(for: verseText, isFullRes: false)
        
        ZStack {
            // 1. Художественный фон
            WallpaperArtBackground(theme: theme)
            
            // 2. Мягкая контрастная подложка для слабовидящих
            RadialGradient(
                colors: [Color.black.opacity(0.5), Color.black.opacity(0.15), Color.clear],
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
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.8), radius: 4)
                            .padding(.top, 24)
                        
                        Text("09:41")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 6)
                    }
                    .frame(height: 105)
                } else {
                    Spacer().frame(height: 80)
                }
                
                // Центральный блок: Стих на весь экран для слабовидящих
                VStack(spacing: 8) {
                    if decor != .minimal {
                        Image(systemName: decor.icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.accentColor)
                            .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 2)
                    }
                    
                    Text(verseText)
                        .font(.system(size: fontSize, weight: .bold, design: fontDesign.design))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(fontSize * 0.3)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.98), radius: 6, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 1)
                        .padding(.horizontal, 12)
                    
                    HStack(spacing: 4) {
                        Text(verse.reference(for: language))
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accentColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(theme.accentColor.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 1)
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Нижний блок: Кнопки фонарика и камеры Lock Screen
                if showOverlay {
                    HStack {
                        Circle()
                            .fill(Color.black.opacity(0.45))
                            .frame(width: 28, height: 28)
                            .overlay(Image(systemName: "flashlight.off.fill").font(.system(size: 11)).foregroundColor(.white))
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color.black.opacity(0.45))
                            .frame(width: 28, height: 28)
                            .overlay(Image(systemName: "camera.fill").font(.system(size: 11)).foregroundColor(.white))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                } else {
                    Spacer().frame(height: 50)
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
        let verseText = verse.text(for: language)
        let fontSize = wallpaperFontSize(for: verseText, isFullRes: true)
        
        ZStack {
            // 1. Художественный фон высокого разрешения
            WallpaperArtBackground(theme: theme)
            
            // 2. Мягкая контрастная подложка для слабовидящих (Accessibility Contrast Scrim)
            RadialGradient(
                colors: [Color.black.opacity(0.55), Color.black.opacity(0.2), Color.clear],
                center: .center,
                startRadius: 100,
                endRadius: 850
            )
            .ignoresSafeArea()
            
            // 3. Компоновка контента с учетом защитных зон Lock Screen
            VStack(spacing: 0) {
                // Защитная зона системных часов и виджетов Apple (верхние ~680 px)
                Spacer()
                    .frame(height: 680)
                
                // Главная зона стиха (максимальный размер для слабовидящих)
                VStack(spacing: 28) {
                    if decor != .minimal {
                        Image(systemName: decor.icon)
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(theme.accentColor)
                            .shadow(color: .black.opacity(0.95), radius: 14, x: 0, y: 6)
                    }
                    
                    Text(verseText)
                        .font(.system(size: fontSize, weight: .bold, design: fontDesign.design))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(fontSize * 0.35)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.98), radius: 24, x: 0, y: 8)
                        .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 3)
                        .padding(.horizontal, 48)
                    
                    // Ссылка на стих в контрастном бейдже
                    HStack(spacing: 8) {
                        Text(verse.reference(for: language))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accentColor)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(theme.accentColor.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.9), radius: 12, x: 0, y: 4)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Защитная зона кнопок фонарика, камеры и Home Indicator (нижние ~320 px)
                VStack(spacing: 4) {
                    Text("ArmenianBible")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .shadow(color: .black.opacity(0.8), radius: 4)
                }
                .frame(height: 320, alignment: .bottom)
                .padding(.bottom, 45)
            }
        }
        .frame(width: 1170, height: 2532)
    }
}

