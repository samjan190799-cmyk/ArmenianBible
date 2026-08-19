import SwiftUI
import UIKit

// MARK: - Экран Церковного календаря (Armenian Church Calendar View)
struct ChurchCalendarView: View {
    @ObservedObject var manager = BibleManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedCategory: FeastType? = nil
    @State private var expandedFeastId: String? = nil
    
    // Экспорт календаря
    @State private var shareURL: ShareURLItem? = nil
    @State private var shareImageItem: ShareItem? = nil
    @State private var showCopiedToast = false
    @State private var toastMessage = ""
    
    private var accentColor: Color {
        Color(hex: manager.accentTheme.colorHex)
    }
    
    private var secondaryAccentColor: Color {
        Color(hex: manager.accentTheme.secondaryColorHex)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.85)
    }
    
    private var cardBorderColor: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    private var feasts: [ArmenianChurchFeast] {
        let all = ChurchCalendarService.shared.feasts(for: selectedYear)
        if let cat = selectedCategory {
            return all.filter { $0.type == cat }
        }
        return all
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                backgroundColor.ignoresSafeArea()
                
                // Мягкое неоновое свечение
                RadialGradient(
                    gradient: Gradient(colors: [Color(hex: "F59E0B").opacity(colorScheme == .dark ? 0.08 : 0.05), Color.clear]),
                    center: .top,
                    startRadius: 40,
                    endRadius: 350
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Шапка: Селектор года + Кнопка экспорта в календарь
                    VStack(spacing: 12) {
                        HStack {
                            // Переключатель года
                            Menu {
                                ForEach(2025...2030, id: \.self) { y in
                                    Button("\(y)") {
                                        triggerHaptic(.light)
                                        selectedYear = y
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("\(selectedYear)")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(primaryTextColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(cardBackgroundColor)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryTextColor.opacity(0.1), lineWidth: 1)
                                )
                            }
                            
                            Spacer()
                            
                            // Главная кнопка: Закачать все праздники в календарь
                            Button {
                                triggerHaptic(.medium)
                                exportFullCalendar()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("export_calendar_btn".localized(for: manager.appLanguage))
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color(hex: "F59E0B").opacity(0.3), radius: 6, y: 3)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        
                        // Категории праздников (Горизонтальные чипсы)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // "Все"
                                Button {
                                    triggerHaptic(.light)
                                    selectedCategory = nil
                                } label: {
                                    Text("all_tags_filter".localized(for: manager.appLanguage))
                                        .font(.system(size: 12, weight: selectedCategory == nil ? .bold : .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == nil ? Color(hex: "F59E0B") : cardBackgroundColor)
                                        .foregroundColor(selectedCategory == nil ? .white : primaryTextColor)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedCategory == nil ? Color(hex: "F59E0B") : Color.primary.opacity(0.1), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                ForEach(FeastType.allCases) { cat in
                                    let isSelected = selectedCategory == cat
                                    Button {
                                        triggerHaptic(.light)
                                        selectedCategory = isSelected ? nil : cat
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(cat.icon)
                                            Text(cat.localizedTitle(for: manager.appLanguage))
                                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color(hex: cat.colorHex).opacity(0.25) : cardBackgroundColor)
                                        .foregroundColor(isSelected ? Color(hex: cat.colorHex) : primaryTextColor)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(isSelected ? Color(hex: cat.colorHex) : Color.primary.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // MARK: - Список карточек праздников
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
                
                // Toast
                if showCopiedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(toastMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.85))
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
        var text = "✨ \(feast.title(for: manager.appLanguage))\n📅 \(feast.formattedDate(for: manager.appLanguage))\n\n\(feast.description(for: manager.appLanguage))"
        if !feast.prayer(for: manager.appLanguage).isEmpty {
            text += "\n\n🙏 \(feast.prayer(for: manager.appLanguage))"
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
    let onExportSingle: () -> Void
    let onShareCard: () -> Void
    let onCopyPrayer: () -> Void
    
    var isToday: Bool {
        Calendar.current.isDateInToday(feast.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Верхняя плашка: Дата + Тип + Сегодня бейдж
            HStack(alignment: .center, spacing: 8) {
                // Иконка и категория
                HStack(spacing: 4) {
                    Text(feast.type.icon)
                        .font(.system(size: 13))
                    Text(feast.type.localizedTitle(for: language))
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color(hex: feast.type.colorHex))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: feast.type.colorHex).opacity(0.15))
                .cornerRadius(8)
                
                if isToday {
                    Text("today_badge".localized(for: language))
                        .font(.system(size: 10.5, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                // Дата праздника
                Text(feast.formattedDate(for: language))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(secondaryAccentColor)
            }
            
            // Название праздника
            Text(feast.title(for: language))
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundColor(primaryTextColor)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
            // Краткое описание
            Text(feast.description(for: language))
                .font(.system(size: 13.5, weight: .regular, design: .serif))
                .foregroundColor(primaryTextColor.opacity(0.85))
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 3)
            
            // Раскрывающиеся детали: Чтения и Молитва
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if !feast.scriptureReading.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "0284C7"))
                            Text("scripture_readings_title".localized(for: language) + ":")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "0284C7"))
                            Text(feast.scriptureReading)
                                .font(.system(size: 12, weight: .semibold, design: .serif))
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "0284C7").opacity(0.08))
                        .cornerRadius(8)
                    }
                    
                    if !feast.prayer(for: language).isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "hands.sparkles.fill")
                                    .font(.system(size: 11))
                                Text("prayer_title".localized(for: language))
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "D97706"))
                            
                            Text(feast.prayer(for: language))
                                .font(.system(size: 13, weight: .regular, design: .serif))
                                .foregroundColor(primaryTextColor.opacity(0.9))
                                .lineSpacing(3)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "D97706").opacity(0.08))
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
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
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
                            .foregroundColor(Color(hex: "D97706"))
                            .padding(7)
                            .background(Color(hex: "D97706").opacity(0.1))
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
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackgroundColor)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isToday ? LinearGradient(colors: [Color(hex: "F59E0B"), Color.red], startPoint: .topLeading, endPoint: .bottomTrailing) : cardBorderColor, lineWidth: isToday ? 1.8 : 1.2)
        )
    }
}

// Wrapper for URL sharing in UIActivityViewController
struct ShareURLItem: Identifiable {
    let id = UUID()
    let url: URL
}
