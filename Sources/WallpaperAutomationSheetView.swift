import SwiftUI
import UIKit

// MARK: - Режимы автоматизации обоев
enum WallpaperAutomationMode: Int, CaseIterable, Identifiable {
    case photoShuffle = 0
    case shortcuts = 1
    
    var id: Int { rawValue }
    
    func title(for lang: AppLanguage) -> String {
        switch self {
        case .photoShuffle:
            switch lang {
            case .armenian: return "Հպումով (Photo Shuffle)"
            case .russian: return "По касанию (Photo Shuffle)"
            case .english: return "On Tap (Photo Shuffle)"
            }
        case .shortcuts:
            switch lang {
            case .armenian: return "Հրամաններով (Shortcuts)"
            case .russian: return "По времени (Команды)"
            case .english: return "Time (Shortcuts)"
            }
        }
    }
}

// MARK: - Модальный экран настройки автоматической смены обоев
struct WallpaperAutomationSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = BibleManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedMode: WallpaperAutomationMode = .photoShuffle
    @State private var selectedBatchCount: Int = 30
    @State private var isGeneratingBatch: Bool = false
    @State private var batchProgressCurrent: Int = 0
    @State private var batchProgressTotal: Int = 30
    @State private var showBatchSuccess: Bool = false
    @State private var batchErrorMessage: String? = nil
    
    @State private var isExportingSample = false
    @State private var showSampleSuccessToast = false
    @State private var isShowingPaywall = false
    
    private var language: AppLanguage {
        manager.appLanguage
    }
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "090A0F")
                    .ignoresSafeArea()
                
                // Фоновые мягкие градиенты
                Circle()
                    .fill(Color(hex: "F59E0B").opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -100, y: -180)
                
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 120, y: 150)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Верхняя плашка с иконкой
                        headerIconView
                        
                        // Сегмент выбора режима: По касанию (Photo Shuffle) / По времени (Shortcuts)
                        Picker("Automation Mode", selection: $selectedMode) {
                            ForEach(WallpaperAutomationMode.allCases) { mode in
                                Text(mode.title(for: language)).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 4)
                        
                        if selectedMode == .photoShuffle {
                            // РЕЖИМ 1: Системный Photo Shuffle (По касанию / Каждый час)
                            photoShuffleSection
                        } else {
                            // РЕЖИМ 2: Автоматизация через Shortcuts (По расписанию)
                            shortcutsSection
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        triggerHaptic(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Верхняя иконка и заголовки
    private var headerIconView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: Color(hex: "F59E0B").opacity(0.4), radius: 16, y: 6)
                
                Image(systemName: selectedMode == .photoShuffle ? "sparkles.rectangle.stack.fill" : "photo.stack.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, 8)
            
            VStack(spacing: 6) {
                Text(selectedMode == .photoShuffle ? photoShuffleTitle : titleText)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(selectedMode == .photoShuffle ? photoShuffleSubtitle : subtitleText)
                    .font(.system(size: 13.5))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
        }
    }
    
    // MARK: - Секция Photo Shuffle (По касанию / Каждый час)
    private var photoShuffleSection: some View {
        VStack(spacing: 16) {
            // Выбор количества обоев
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(batchCountLabel)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(batchCountBadge)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "FDE047"))
                }
                
                HStack(spacing: 10) {
                    ForEach([20, 30, 50], id: \.self) { count in
                        Button {
                            triggerHaptic(.light)
                            selectedBatchCount = count
                        } label: {
                            Text("\(count) \(wallpapersSuffix)")
                                .font(.system(size: 13, weight: selectedBatchCount == count ? .bold : .medium))
                                .foregroundColor(selectedBatchCount == count ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selectedBatchCount == count ?
                                        Color(hex: "FDE047") : Color.white.opacity(0.08)
                                )
                                .cornerRadius(10)
                        }
                        .disabled(isGeneratingBatch)
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                
                Text(batchDescriptionText)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(2)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            
            // Прогресс генерации
            if isGeneratingBatch {
                VStack(spacing: 10) {
                    HStack {
                        ProgressView()
                            .tint(Color(hex: "FDE047"))
                        Text("\(generatingProgressText): \(batchProgressCurrent) / \(batchProgressTotal)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    ProgressView(value: Double(batchProgressCurrent), total: Double(batchProgressTotal))
                        .tint(Color(hex: "FDE047"))
                }
                .padding(16)
                .background(Color.black.opacity(0.5))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "FDE047").opacity(0.3), lineWidth: 1))
            }
            
            // Кнопка генерации альбома
            Button {
                generateAlbumPack()
            } label: {
                HStack(spacing: 8) {
                    if isGeneratingBatch {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "photo.badge.plus.fill")
                            .font(.system(size: 17, weight: .bold))
                    }
                    Text("\(generateBatchButtonText) (\(selectedBatchCount))")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FDE047"), Color(hex: "F59E0B")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(hex: "F59E0B").opacity(0.35), radius: 12, y: 4)
            }
            .disabled(isGeneratingBatch)
            .buttonStyle(ScaleButtonStyle())
            
            // Сообщение об ошибке, если есть
            if let err = batchErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(12)
                .background(Color.red.opacity(0.15))
                .cornerRadius(12)
            }
            
            // Блок успеха и Инструкция по включению Photo Shuffle на экране блокировки
            if showBatchSuccess {
                VStack(spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18, weight: .bold))
                        Text(batchSuccessMessage)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Пошаговая инструкция для экрана блокировки iOS
                    VStack(alignment: .leading, spacing: 10) {
                        Text(howToEnableShuffleHeader)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "FDE047"))
                        
                        shuffleStepRow(num: "1", text: shuffleStep1)
                        shuffleStepRow(num: "2", text: shuffleStep2)
                        shuffleStepRow(num: "3", text: shuffleStep3)
                        shuffleStepRow(num: "4", text: shuffleStep4)
                    }
                    
                    Button {
                        triggerHaptic(.light)
                        openPhotosApp()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(openPhotosAppText)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(16)
                .background(Color(hex: "10B981").opacity(0.12))
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "10B981").opacity(0.4), lineWidth: 1.2))
            }
        }
    }
    
    // MARK: - Секция Shortcuts (По времени суток)
    private var shortcutsSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 14) {
                stepRow(
                    number: "1",
                    title: step1Title,
                    subtitle: step1Desc,
                    icon: "clock.badge.checkmark.fill",
                    color: Color(hex: "F59E0B")
                )
                
                stepRow(
                    number: "2",
                    title: step2Title,
                    subtitle: step2Desc,
                    icon: "wand.and.stars",
                    color: Color(hex: "38BDF8")
                )
                
                stepRow(
                    number: "3",
                    title: step3Title,
                    subtitle: step3Desc,
                    icon: "lock.iphone",
                    color: Color(hex: "10B981")
                )
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Кнопка: Открыть Команды
            Button {
                triggerHaptic(.medium)
                openShortcutsApp()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.forward.app.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(openShortcutsButtonText)
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FDE047"), Color(hex: "F59E0B")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(hex: "F59E0B").opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Кнопка: Проверить и сохранить образец в Фото
            Button {
                triggerHaptic(.light)
                generateAndSaveSample()
            } label: {
                HStack(spacing: 6) {
                    if isExportingSample {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(testSampleButtonText)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.08))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
            .disabled(isExportingSample)
            .buttonStyle(ScaleButtonStyle())
            
            // Тост подтверждения образца
            if showSampleSuccessToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(sampleSavedText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.85))
                .cornerRadius(20)
                .overlay(Capsule().stroke(Color.green.opacity(0.5), lineWidth: 1))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Ряд шага Photo Shuffle
    @ViewBuilder
    private func shuffleStepRow(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.black)
                .frame(width: 20, height: 20)
                .background(Color(hex: "FDE047"))
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(2)
        }
    }
    
    // MARK: - Вспомогательный ряд шага Shortcuts
    @ViewBuilder
    private func stepRow(number: String, title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(stepPrefix(for: number))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
    
    private func stepPrefix(for number: String) -> String {
        switch language {
        case .armenian: return "Քայլ \(number):"
        case .russian: return "Шаг \(number):"
        case .english: return "Step \(number):"
        }
    }
    
    // MARK: - Действия
    private func generateAlbumPack() {
        guard !isGeneratingBatch else { return }
        isGeneratingBatch = true
        showBatchSuccess = false
        batchErrorMessage = nil
        batchProgressCurrent = 0
        batchProgressTotal = selectedBatchCount
        
        triggerHaptic(.medium)
        
        Task { @MainActor in
            do {
                _ = try await BibleWallpaperGenerator.shared.exportBatchToPhotoAlbum(
                    count: selectedBatchCount,
                    language: language
                ) { current, total in
                    batchProgressCurrent = current
                    batchProgressTotal = total
                    if current % 5 == 0 || current == total {
                        triggerHaptic(.light)
                    }
                }
                
                isGeneratingBatch = false
                showBatchSuccess = true
                
                let notification = UINotificationFeedbackGenerator()
                notification.prepare()
                notification.notificationOccurred(.success)
            } catch {
                isGeneratingBatch = false
                batchErrorMessage = error.localizedDescription
                let notification = UINotificationFeedbackGenerator()
                notification.prepare()
                notification.notificationOccurred(.error)
            }
        }
    }
    
    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let appStoreURL = URL(string: "https://apps.apple.com/app/shortcuts/id915254992") {
            UIApplication.shared.open(appStoreURL)
        }
    }
    
    private func openPhotosApp() {
        if let url = URL(string: "photos-redirect://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func generateAndSaveSample() {
        isExportingSample = true
        
        Task { @MainActor in
            let image = BibleWallpaperGenerator.shared.generateWallpaperImage(verse: manager.currentVerse)
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            isExportingSample = false
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showSampleSuccessToast = true
            }
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                showSampleSuccessToast = false
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Локализация текстов (Photo Shuffle)
    private var photoShuffleTitle: String {
        switch language {
        case .armenian: return "Պաստառների Ալբոմ (Photo Shuffle)"
        case .russian: return "Альбом для Экрана Блокировки"
        case .english: return "Lock Screen Album (Photo Shuffle)"
        }
    }
    
    private var photoShuffleSubtitle: String {
        switch language {
        case .armenian: return "Ստեղծեք տողերի ալբոմ Լուսանկարներում և միացրեք փոփոխությունը հպումով կամ ամեն ժամ"
        case .russian: return "Создайте альбом с цитатами в Фото и настройте авто-смену по касанию экрана или каждый час"
        case .english: return "Create verse album in Photos and enable shuffle on tap or hourly on Lock Screen"
        }
    }
    
    private var batchCountLabel: String {
        switch language {
        case .armenian: return "Պաստառների քանակը"
        case .russian: return "Размер коллекции обоев"
        case .english: return "Wallpaper Pack Size"
        }
    }
    
    private var batchCountBadge: String {
        switch language {
        case .armenian: return "Առանց կրկնության"
        case .russian: return "Без повторов"
        case .english: return "No duplicates"
        }
    }
    
    private var wallpapersSuffix: String {
        switch language {
        case .armenian: return "հատ"
        case .russian: return "обоев"
        case .english: return "wallpapers"
        }
    }
    
    private var batchDescriptionText: String {
        switch language {
        case .armenian: return "Հավելվածը կստեղծի տարբեր գեղարվեստական ֆոներով (Արարատ, Տաթև, Խաչքար, Մագաղաթ և այլն) տողերի ալբոմ «Armenian Bible» անունով ձեր Լուսանկարներում:"
        case .russian: return "Приложение создаст альбом «Armenian Bible» в Фото с разными стихами и уникальными фонами (Арарат, Татев, Хачкар, Пергамент, Вифлеем и др.):"
        case .english: return "The app will generate an \"Armenian Bible\" album in your Photos with unique verses and backgrounds (Ararat, Tatev, Khachkar, Parchment, etc.):"
        }
    }
    
    private var generateBatchButtonText: String {
        switch language {
        case .armenian: return "Ստեղծել Ալբոմը Լուսանկարներում"
        case .russian: return "Сгенерировать альбом в Фото"
        case .english: return "Generate Album in Photos"
        }
    }
    
    private var generatingProgressText: String {
        switch language {
        case .armenian: return "Պահպանում ալբոմում"
        case .russian: return "Создание обоев"
        case .english: return "Generating wallpapers"
        }
    }
    
    private var batchSuccessMessage: String {
        switch language {
        case .armenian: return "«Armenian Bible» ալբոմը հաջողությամբ պահպանվեց!"
        case .russian: return "Альбом «Armenian Bible» успешно сохранен в Фото!"
        case .english: return "\"Armenian Bible\" album successfully saved to Photos!"
        }
    }
    
    private var howToEnableShuffleHeader: String {
        switch language {
        case .armenian: return "Ինչպես միացնել հպումով փոփոխությունը."
        case .russian: return "Как включить смену по касанию на iPhone:"
        case .english: return "How to enable On Tap shuffle on iPhone:"
        }
    }
    
    private var shuffleStep1: String {
        switch language {
        case .armenian: return "Պահեք մատը Կողպեքրանի վրա և սեղմեք «+» (Նոր պաստառներ):"
        case .russian: return "Зажмите экран блокировки и нажмите «+» (Новые обои)."
        case .english: return "Touch and hold Lock Screen, then tap \"+\" (Add New)."
        }
    }
    
    private var shuffleStep2: String {
        switch language {
        case .armenian: return "Վերևում ընտրեք «Ֆոտոների խառնում» (Photo Shuffle):"
        case .russian: return "Вверху выберите «Перемешивание фото» (Photo Shuffle)."
        case .english: return "Tap \"Photo Shuffle\" at the top of the wallpaper gallery."
        }
    }
    
    private var shuffleStep3: String {
        switch language {
        case .armenian: return "«Հաճախականություն» բաժնում ընտրեք «Հպումով» (On Tap) կամ «Ամեն ժամ»:"
        case .russian: return "В «Частота перемешивания» выберите «При касании» (On Tap) или «Каждый час»."
        case .english: return "Set Shuffle Frequency to \"On Tap\" or \"Hourly\"."
        }
    }
    
    private var shuffleStep4: String {
        switch language {
        case .armenian: return "Ընտրեք «Ալբոմ» → «Armenian Bible» և սեղմեք «Կատարված է»:"
        case .russian: return "Нажмите «Альбом» → выберите «Armenian Bible» и нажмите «Готово»!"
        case .english: return "Select Album → choose \"Armenian Bible\" and tap Done!"
        }
    }
    
    private var openPhotosAppText: String {
        switch language {
        case .armenian: return "Բացել «Լուսանկարներ» հավելվածը"
        case .russian: return "Открыть приложение «Фото»"
        case .english: return "Open Photos App"
        }
    }
    
    // MARK: - Локализация текстов (Shortcuts)
    private var titleText: String {
        switch language {
        case .armenian: return "Ամենօրյա Ավտո-Պաստառներ"
        case .russian: return "Ежедневная авто-смена обоев"
        case .english: return "Daily Auto-Wallpaper"
        }
    }
    
    private var subtitleText: String {
        switch language {
        case .armenian: return "Ձեր Կողպման էկրանը ամեն առավոտ կթարմացվի նոր ոգեշնչող աստվածաշնչյան տողով"
        case .russian: return "Экран блокировки будет автоматически обновляться новым стихом каждое утро через Команды iOS"
        case .english: return "Your Lock Screen will automatically update with a new Bible verse every morning via iOS Shortcuts"
        }
    }
    
    private var step1Title: String {
        switch language {
        case .armenian: return "Ստեղծեք Ավտոմատացում"
        case .russian: return "Создайте автоматизацию"
        case .english: return "Create Automation"
        }
    }
    
    private var step1Desc: String {
        switch language {
        case .armenian: return "Բացեք «Հրամաններ» հավելվածը → Ավտոմատացում → Ընտրեք «Օրվա ժամ» (օրինակ՝ 08:00)"
        case .russian: return "В приложении «Команды» перейдите в «Автоматизация» → «Время суток» (например, 08:00)"
        case .english: return "In Shortcuts app open \"Automation\" tab → \"Time of Day\" (e.g. 08:00 AM)"
        }
    }
    
    private var step2Title: String {
        switch language {
        case .armenian: return "Ընտրեք Armenian Bible"
        case .russian: return "Выберите действие"
        case .english: return "Choose Armenian Bible action"
        }
    }
    
    private var step2Desc: String {
        switch language {
        case .armenian: return "Ավելացրեք գործողություն՝ «Ստանալ պաստառը տողով» Armenian Bible-ից"
        case .russian: return "Добавьте действие: «Получить обои со стихом» из приложения Armenian Bible"
        case .english: return "Add action: \"Get Bible Verse Wallpaper\" from Armenian Bible"
        }
    }
    
    private var step3Title: String {
        switch language {
        case .armenian: return "Տեղադրել Կողպման էկրանին"
        case .russian: return "Установить обои"
        case .english: return "Set Wallpaper"
        }
    }
    
    private var step3Desc: String {
        switch language {
        case .armenian: return "Ավելացրեք համակարգային գործողություն՝ «Տեղադրել Պաստառ» և անջատեք «Հարցնել գործարկումից առաջ»"
        case .russian: return "Добавьте системное действие «Установить обои» и отключите «Спрашивать до запуска»"
        case .english: return "Add system action \"Set Wallpaper\" and toggle off \"Ask Before Running\""
        }
    }
    
    private var openShortcutsButtonText: String {
        switch language {
        case .armenian: return "Բացել «Հրամաններ» հավելվածը"
        case .russian: return "Открыть приложение «Команды»"
        case .english: return "Open Shortcuts App"
        }
    }
    
    private var testSampleButtonText: String {
        switch language {
        case .armenian: return "Փորձարկել և պահպանել նմուշը Լուսանկարներում"
        case .russian: return "Проверить и сохранить образец в Фото"
        case .english: return "Generate & Save Sample to Photos"
        }
    }
    
    private var sampleSavedText: String {
        switch language {
        case .armenian: return "Օրինակը հաջողությամբ պահպանվեց Լուսանկարներում"
        case .russian: return "Образец обоев сохранен в Фотопленку!"
        case .english: return "Sample wallpaper saved to Photos!"
        }
    }
}
