import SwiftUI
import UIKit

// MARK: - Режим сортировки праздников
enum CalendarSortMode: String, CaseIterable, Identifiable, Sendable {
    case approaching = "approaching"
    case chronological = "chronological"
    
    var id: String { rawValue }
    
    func localizedTitle(for lang: AppLanguage) -> String {
        switch self {
        case .approaching:
            return "sort_approaching".localized(for: lang)
        case .chronological:
            return "sort_chronological".localized(for: lang)
        }
    }
    
    var icon: String {
        switch self {
        case .approaching: return "clock.arrow.circlepath"
        case .chronological: return "calendar"
        }
    }
}

// MARK: - Экран Церковного календаря (Armenian Church Calendar View)
struct ChurchCalendarView: View {
    @ObservedObject var manager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedCategory: FeastType? = nil
    @State private var sortMode: CalendarSortMode = .approaching
    @State private var expandedFeastId: String? = nil
    @State private var selectedFeastForMeaning: ArmenianChurchFeast? = nil
    
    // Экспорт календаря
    @State private var shareURL: ShareURLItem? = nil
    @State private var shareImageItem: ShareItem? = nil
    @State private var showCopiedToast = false
    @State private var toastMessage = ""
    
    private var accentColor: Color {
        manager.accentTheme.color
    }
    
    private var secondaryAccentColor: Color {
        Paper.inkSecondary
    }
    
    private var backgroundColor: Color {
        Paper.page
    }
    
    private var cardBackgroundColor: Color {
        Paper.sheet
    }
    
    private var cardBorderColor: LinearGradient {
        LinearGradient(colors: [Paper.hairline, Paper.hairline], startPoint: .top, endPoint: .bottom)
    }
    
    private var primaryTextColor: Color {
        Paper.ink
    }
    
    private var feasts: [ArmenianChurchFeast] {
        let all: [ArmenianChurchFeast]
        switch sortMode {
        case .approaching:
            all = ChurchCalendarService.shared.feastsSortedByApproaching(for: selectedYear)
        case .chronological:
            all = ChurchCalendarService.shared.feasts(for: selectedYear)
        }
        
        if let cat = selectedCategory {
            return all.filter { $0.type == cat }
        }
        return all
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                PaperBackground()
                
                VStack(spacing: 0) {
                    // MARK: - Шапка: Селектор года + Сортировка + Кнопка экспорта
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            // Переключатель года
                            Menu {
                                ForEach(2025...2030, id: \.self) { y in
                                    Button("\(y)") {
                                        triggerHaptic(.light)
                                        selectedYear = y
                                    }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Text("\(selectedYear)")
                                        .font(PaperFont.font(size: 16, weight: .semibold).monospacedDigit())
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(primaryTextColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .paperField(cornerRadius: 12)
                            }
                            
                            // Переключатель режима сортировки (Ближайшие / По календарю)
                            Menu {
                                ForEach(CalendarSortMode.allCases) { mode in
                                    Button {
                                        triggerHaptic(.light)
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            sortMode = mode
                                        }
                                    } label: {
                                        HStack {
                                            Text(mode.localizedTitle(for: manager.appLanguage))
                                            if sortMode == mode {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: sortMode.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Paper.gold)
                                    Text(sortMode.localizedTitle(for: manager.appLanguage))
                                        .font(PaperFont.font(size: 12.5, weight: .semibold))
                                        .foregroundColor(primaryTextColor)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(primaryTextColor.opacity(0.5))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .paperField(cornerRadius: 12)
                            }
                            
                            Spacer()
                            
                            // Главная кнопка: Закачать все праздники в календарь
                            Button {
                                triggerHaptic(.medium)
                                exportFullCalendar()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("export_calendar_btn".localized(for: manager.appLanguage))
                                        .font(PaperFont.font(size: 12, weight: .semibold))
                                }
                                .foregroundColor(Paper.onAccent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Paper.gold)
                                .cornerRadius(12)
                                .shadow(color: Paper.shadow, radius: 6, y: 3)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        
                        // Категории праздников (Горизонтальные чипсы)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // "Все"
                                Button {
                                    triggerHaptic(.light)
                                    selectedCategory = nil
                                } label: {
                                    Text("all_tags_filter".localized(for: manager.appLanguage))
                                        .font(PaperFont.font(size: 12, weight: selectedCategory == nil ? .semibold : .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == nil ? Paper.gold : cardBackgroundColor)
                                        .foregroundColor(selectedCategory == nil ? Paper.onAccent : primaryTextColor)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedCategory == nil ? Paper.gold : Paper.ink.opacity(0.1), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                ForEach(FeastType.allCases) { cat in
                                    let isSelected = selectedCategory == cat
                                    Button {
                                        triggerHaptic(.light)
                                        selectedCategory = isSelected ? nil : cat
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 11, weight: .semibold))
                                            Text(cat.localizedTitle(for: manager.appLanguage))
                                                .font(PaperFont.font(size: 12, weight: isSelected ? .semibold : .medium))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? cat.color.opacity(0.25) : cardBackgroundColor)
                                        .foregroundColor(isSelected ? cat.color : primaryTextColor)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(isSelected ? cat.color : Paper.ink.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 6)
                    
                    // MARK: - Список карточек праздников
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(feasts) { feast in
                                ChurchFeastCardView(
                                    feast: feast,
                                    language: manager.appLanguage,
                                    cardBackgroundColor: cardBackgroundColor,
                                    cardBorderColor: cardBorderColor,
                                    primaryTextColor: primaryTextColor,
                                    secondaryAccentColor: secondaryAccentColor,
                                    isExpanded: expandedFeastId == feast.id,
                                    onToggleExpand: {
                                        triggerHaptic(.light)
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            expandedFeastId = (expandedFeastId == feast.id) ? nil : feast.id
                                        }
                                    },
                                    onShowMeaning: {
                                        triggerHaptic(.medium)
                                        selectedFeastForMeaning = feast
                                    },
                                    onExportSingle: {
                                        exportSingleFeast(feast)
                                    },
                                    onShareCard: {
                                        shareFeastCard(feast)
                                    },
                                    onCopyPrayer: {
                                        copyFeastInfo(feast)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .padding(.bottom, 24)
                    }
                }
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
                
                // Toast
                if showCopiedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Paper.moss)
                            Text(toastMessage)
                                .font(PaperFont.font(size: 14, weight: .medium))
                                .foregroundColor(Paper.page)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Paper.ink.opacity(0.92))
                        .cornerRadius(25)
                        .shadow(radius: 10)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCopiedToast)
                }
            }
            .navigationTitle("church_calendar_title".localized(for: manager.appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(primaryTextColor.opacity(0.5))
                    }
                }
            }
            .sheet(item: $selectedFeastForMeaning) { feast in
                FeastMeaningSheetView(
                    feast: feast,
                    language: manager.appLanguage,
                    accentColor: accentColor,
                    primaryTextColor: primaryTextColor,
                    cardBackgroundColor: cardBackgroundColor,
                    onExport: {
                        exportSingleFeast(feast)
                    },
                    onShare: {
                        shareFeastCard(feast)
                    },
                    onCopy: {
                        copyFeastInfo(feast)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $shareURL) { item in
                ActivityView(activityItems: [item.url])
            }
            .sheet(item: $shareImageItem) { item in
                ActivityView(activityItems: [item.image])
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
    
    private func exportFullCalendar() {
        if let url = ChurchCalendarService.shared.generateICSFile(for: selectedYear, language: manager.appLanguage) {
            self.shareURL = ShareURLItem(url: url)
        }
    }
    
    private func exportSingleFeast(_ feast: ArmenianChurchFeast) {
        if let url = ChurchCalendarService.shared.generateICSFile(for: selectedYear, language: manager.appLanguage) {
            self.shareURL = ShareURLItem(url: url)
        }
    }
    
    private func copyFeastInfo(_ feast: ArmenianChurchFeast) {
        triggerHaptic(.light)
        var text = "\(feast.title(for: manager.appLanguage))\n\(feast.formattedDate(for: manager.appLanguage))\n\n\(feast.description(for: manager.appLanguage))"
        if !feast.meaning(for: manager.appLanguage).isEmpty {
            text += "\n\n\("feast_meaning_section_spiritual".localized(for: manager.appLanguage)):\n\(feast.meaning(for: manager.appLanguage))"
        }
        if !feast.traditions(for: manager.appLanguage).isEmpty {
            text += "\n\n\("feast_meaning_section_traditions".localized(for: manager.appLanguage)):\n\(feast.traditions(for: manager.appLanguage))"
        }
        if !feast.prayer(for: manager.appLanguage).isEmpty {
            text += "\n\n\(feast.prayer(for: manager.appLanguage))"
        }
        UIPasteboard.general.string = text
        showToast("copied_to_clipboard".localized(for: manager.appLanguage))
    }
    
    @MainActor
    private func shareFeastCard(_ feast: ArmenianChurchFeast) {
        triggerHaptic(.medium)
        let verse = BibleVerse(
            id: UUID(),
            textHy: feast.titleHy + "\n\n" + feast.descriptionHy,
            textRu: feast.titleRu + "\n\n" + feast.descriptionRu,
            textEn: feast.titleEn + "\n\n" + feast.descriptionEn,
            refHy: feast.formattedDate(for: .armenian),
            refRu: feast.formattedDate(for: .russian),
            refEn: feast.formattedDate(for: .english)
        )
        
        let exportView = VerseCardExportView(
            verse: verse,
            theme: manager.accentTheme,
            colorScheme: colorScheme
        )
        
        let hostingController = UIHostingController(rootView: exportView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 1080, height: 1080)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))
        let image = renderer.image { context in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
        
        self.shareImageItem = ShareItem(image: image)
    }
}

// MARK: - Карточка церковного праздника
struct ChurchFeastCardView: View {
    let feast: ArmenianChurchFeast
    let language: AppLanguage
    let cardBackgroundColor: Color
    let cardBorderColor: LinearGradient
    let primaryTextColor: Color
    let secondaryAccentColor: Color
    let isExpanded: Bool
    
    let onToggleExpand: () -> Void
    let onShowMeaning: () -> Void
    let onExportSingle: () -> Void
    let onShareCard: () -> Void
    let onCopyPrayer: () -> Void
    
    private var countdown: (text: String, isToday: Bool, isUpcoming: Bool) {
        feast.countdownBadge(for: language)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Верхняя плашка: Дата + Тип + Бейдж обратного отсчета
            HStack(alignment: .center, spacing: 6) {
                // Иконка и категория
                HStack(spacing: 4) {
                    Image(systemName: feast.type.icon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(feast.type.localizedTitle(for: language))
                        .font(PaperFont.font(size: 11, weight: .semibold))
                }
                .foregroundColor(feast.type.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(feast.type.color.opacity(0.15))
                .cornerRadius(8)
                
                // Бейдж приближения даты (Сегодня, Завтра, Через N дней)
                if countdown.isToday {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                        Text(countdown.text)
                            .font(PaperFont.font(size: 10.5, weight: .semibold))
                    }
                    .foregroundColor(Paper.onAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Paper.cinnabar)
                    .cornerRadius(6)
                } else if countdown.isUpcoming {
                    HStack(spacing: 3) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 9))
                        Text(countdown.text)
                            .font(PaperFont.font(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Paper.gold)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Paper.gold.opacity(0.18))
                    .cornerRadius(6)
                }
                
                Spacer()
                
                // Дата праздника
                Text(feast.formattedDate(for: language))
                    .font(PaperFont.font(size: 11.5, weight: .semibold).monospacedDigit())
                    .foregroundColor(secondaryAccentColor)
            }
            
            // Название праздника + Кнопка разъяснения смысла (?)
            HStack(alignment: .top, spacing: 8) {
                Text(feast.title(for: language))
                    .font(PaperFont.font(size: 16.5, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Кнопка разъяснения смысла праздника (?)
                Button {
                    onShowMeaning()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(Paper.gold)
                    .padding(4)
                    .background(Paper.gold.opacity(0.12))
                    .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("feast_meaning_btn".localized(for: language))
            }
            
            // Краткое описание
            Text(feast.description(for: language))
                .font(PaperFont.font(size: 13))
                .foregroundColor(primaryTextColor.opacity(0.85))
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 3)
            
            // Раскрывающиеся детали: Чтения и Молитва
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if !feast.meaning(for: language).isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11))
                                Text("feast_meaning_section_spiritual".localized(for: language))
                                    .font(PaperFont.font(size: 11, weight: .semibold))
                            }
                            .foregroundColor(Paper.plum)
                            
                            Text(feast.meaning(for: language))
                                .font(PaperFont.font(size: 12.5))
                                .foregroundColor(primaryTextColor.opacity(0.9))
                                .lineSpacing(3)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Paper.plum.opacity(0.08))
                        .cornerRadius(10)
                    }
                    
                    if !feast.scriptureReading.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Paper.lapis)
                            Text("scripture_readings_title".localized(for: language) + ":")
                                .font(PaperFont.font(size: 12, weight: .semibold))
                                .foregroundColor(Paper.lapis)
                            Text(feast.scriptureReading)
                                .font(PaperFont.font(size: 12, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Paper.lapis.opacity(0.08))
                        .cornerRadius(8)
                    }
                    
                    if !feast.prayer(for: language).isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "hands.sparkles.fill")
                                    .font(.system(size: 11))
                                Text("prayer_title".localized(for: language))
                                    .font(PaperFont.font(size: 11, weight: .semibold))
                            }
                            .foregroundColor(Paper.gold)
                            
                            Text(feast.prayer(for: language))
                                .font(PaperFont.font(size: 13))
                                .foregroundColor(primaryTextColor.opacity(0.9))
                                .lineSpacing(3)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Paper.gold.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Нижняя панель действий
            HStack {
                Button {
                    onToggleExpand()
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "collapse_details".localized(for: language) : "expand_details".localized(for: language))
                            .font(PaperFont.font(size: 12, weight: .semibold))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(secondaryAccentColor)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                HStack(spacing: 8) {
                    // В календарь
                    Button {
                        onExportSingle()
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Paper.gold)
                            .padding(7)
                            .background(Paper.gold.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Копировать
                    Button {
                        onCopyPrayer()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                            .padding(7)
                            .background(primaryTextColor.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Поделиться
                    Button {
                        onShareCard()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                            .padding(7)
                            .background(primaryTextColor.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.top, 2)
        }
        .padding(16)
        .paperSheet(cornerRadius: 18)
    }
}

// MARK: - Модальное окно разъяснения смысла праздника (Feast Meaning Sheet View)
struct FeastMeaningSheetView: View {
    let feast: ArmenianChurchFeast
    let language: AppLanguage
    let accentColor: Color
    let primaryTextColor: Color
    let cardBackgroundColor: Color
    
    let onExport: () -> Void
    let onShare: () -> Void
    let onCopy: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var countdown: (text: String, isToday: Bool, isUpcoming: Bool) {
        feast.countdownBadge(for: language)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // MARK: - Шапка праздника
                    VStack(spacing: 8) {
                        Image(systemName: feast.type.icon)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(feast.type.color)
                            .padding(.bottom, 2)
                        
                        Text(feast.title(for: language))
                            .font(PaperFont.font(size: 22, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                        
                        HStack(spacing: 8) {
                            Text(feast.type.localizedTitle(for: language))
                                .font(PaperFont.font(size: 12, weight: .semibold))
                                .foregroundColor(feast.type.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(feast.type.color.opacity(0.15))
                                .cornerRadius(8)
                            
                            Text(feast.formattedDate(for: language))
                                .font(PaperFont.font(size: 13, weight: .semibold).monospacedDigit())
                                .foregroundColor(Paper.inkSecondary)
                            
                            if countdown.isToday {
                                Text(countdown.text)
                                    .font(PaperFont.font(size: 11, weight: .semibold))
                                    .foregroundColor(Paper.onAccent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3.5)
                                    .background(Paper.cinnabar)
                                    .cornerRadius(6)
                            } else if countdown.isUpcoming {
                                Text(countdown.text)
                                    .font(PaperFont.font(size: 11, weight: .semibold))
                                    .foregroundColor(Paper.gold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3.5)
                                    .background(Paper.gold.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                    
                    // MARK: - Раздел 1: Что мы празднуем (Событие)
                    if !feast.description(for: language).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Paper.lapis)
                                Text("feast_meaning_section_event".localized(for: language))
                                    .font(PaperFont.font(size: 14, weight: .semibold))
                                    .foregroundColor(Paper.lapis)
                            }
                            
                            Text(feast.description(for: language))
                                .font(PaperFont.font(size: 14.5))
                                .foregroundColor(primaryTextColor)
                                .lineSpacing(5)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .paperField(cornerRadius: 16)
                    }
                    
                    // MARK: - Раздел 2: Духовный смысл для верующего
                    if !feast.meaning(for: language).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(Paper.plum)
                                Text("feast_meaning_section_spiritual".localized(for: language))
                                    .font(PaperFont.font(size: 14, weight: .semibold))
                                    .foregroundColor(Paper.plum)
                            }
                            
                            Text(feast.meaning(for: language))
                                .font(PaperFont.font(size: 14.5))
                                .foregroundColor(primaryTextColor)
                                .lineSpacing(5)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .paperField(cornerRadius: 16)
                    }
                    
                    // MARK: - Раздел 3: Церковные традиции и обычаи
                    if !feast.traditions(for: language).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Paper.gold)
                                Text("feast_meaning_section_traditions".localized(for: language))
                                    .font(PaperFont.font(size: 14, weight: .semibold))
                                    .foregroundColor(Paper.gold)
                            }
                            
                            Text(feast.traditions(for: language))
                                .font(PaperFont.font(size: 14.5))
                                .foregroundColor(primaryTextColor)
                                .lineSpacing(5)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .paperField(cornerRadius: 16)
                    }
                    
                    // MARK: - Раздел 4: Чтения дня
                    if !feast.scriptureReading.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.pages.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Paper.moss)
                                Text("scripture_readings_title".localized(for: language))
                                    .font(PaperFont.font(size: 13, weight: .semibold))
                                    .foregroundColor(Paper.moss)
                            }
                            
                            Text(feast.scriptureReading)
                                .font(PaperFont.font(size: 14, weight: .medium))
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Paper.moss.opacity(0.08))
                        .cornerRadius(14)
                    }
                    
                    // MARK: - Раздел 5: Праздничная молитва
                    if !feast.prayer(for: language).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "hands.sparkles.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Paper.gold)
                                Text("prayer_title".localized(for: language))
                                    .font(PaperFont.font(size: 13, weight: .semibold))
                                    .foregroundColor(Paper.gold)
                            }
                            
                            Text(feast.prayer(for: language))
                                .font(PaperFont.font(size: 14))
                                .foregroundColor(primaryTextColor)
                                .lineSpacing(4)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Paper.gold.opacity(0.08))
                        .cornerRadius(14)
                    }
                    
                    // MARK: - Действия
                    HStack(spacing: 12) {
                        Button {
                            onCopy()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                Text("context_menu_copy".localized(for: language))
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .paperField(cornerRadius: 12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button {
                            onShare()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("context_menu_share".localized(for: language))
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .paperField(cornerRadius: 12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button {
                            onExport()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.plus")
                                Text("export_calendar_btn".localized(for: language))
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Paper.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Paper.gold)
                            .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("feast_meaning_title".localized(for: language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(primaryTextColor.opacity(0.5))
                    }
                }
            }
        }
    }
}

// Wrapper for URL sharing in UIActivityViewController
struct ShareURLItem: Identifiable {
    let id = UUID()
    let url: URL
}
