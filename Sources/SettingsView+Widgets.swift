import SwiftUI
import WidgetKit
import LocalAuthentication
import Foundation

extension SettingsView {
    // MARK: - Объединенная секция: Виджеты, Экран блокировки и StandBy
    @ViewBuilder
    var widgetsUnifiedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Шапка карточки: Заголовок + Бейдж + Кнопка справки
            HStack(spacing: 8) {
                Label {
                    Text("lockscreen_widget_section_title".localized(for: selectedLanguage))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryTextColor)
                } icon: {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                }
                
                // Бейдж STANDBY
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                    Text("STANDBY")
                        .font(.system(size: 9, weight: .black))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Color(hex: "F59E0B").opacity(0.18))
                .foregroundColor(Color(hex: "F59E0B"))
                .cornerRadius(6)
                
                Spacer()
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    isShowingWidgetInstruction = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 14))
                        Text("widget_instruction_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Text("widget_style_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            // 2. Язык виджетов
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    Text("widget_language_title".localized(for: selectedLanguage))
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                }
                
                Picker("widget_language_title", selection: $selectedWidgetLanguage) {
                    ForEach(WidgetLanguage.allCases) { lang in
                        Text(lang.localizedName(for: selectedLanguage)).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .tint(colorScheme == .dark ? .white : .primary)
                .onChange(of: selectedWidgetLanguage) { newLang in
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    manager.setWidgetLanguage(newLang)
                }
            }
            
            // 3. Стиль оформления StandBy / Home виджетов (9 вариантов)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    Text("widget_style_section_title".localized(for: selectedLanguage))
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(WidgetVisualStyle.allCases) { style in
                            WidgetStyleCardButton(
                                style: style,
                                isSelected: selectedWidgetStyle == style,
                                isLocked: false,
                                selectedLanguage: selectedLanguage,
                                themeColorHex: selectedTheme.colorHex,
                                colorScheme: colorScheme
                            ) {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedWidgetStyle = style
                                }
                                manager.setWidgetVisualStyle(style)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Divider().opacity(0.3)
            
            // 4. Интерактивный Live Preview с удобным перелистыванием размеров (в стиле блоков ИИ)
            VStack(alignment: .leading, spacing: 14) {
                // Заголовок секции предпросмотра
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                    Text("standby_preview_title".localized(for: selectedLanguage))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                }
                
                // Горизонтальные табы выбора размера виджета (как в блоках ИИ - можно листать)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PreviewWidgetSize.allCases) { size in
                            let isSelected = previewWidgetSize == size
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    previewWidgetSize = size
                                }
                                pickVerseForCurrentSize(size)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: size.iconName)
                                        .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                                    Text(size.localizedTitle(for: selectedLanguage))
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8.5)
                                .background(
                                    ZStack {
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: selectedTheme.colorHex), Color(hex: selectedTheme.secondaryColorHex)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .shadow(color: Color(hex: selectedTheme.colorHex).opacity(0.35), radius: 6, y: 2)
                                        } else {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(inputFieldBgColor)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(inputFieldBorderColor, lineWidth: 1)
                                                )
                                        }
                                    }
                                )
                                .foregroundColor(isSelected ? .white : primaryTextColor)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
                
                // Подсказка о выбранном типе виджета + кнопка случайного стиха
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: selectedTheme.colorHex))
                            .frame(width: 6, height: 6)
                        Text(previewWidgetSize == .small ? (selectedLanguage == .armenian ? "Գլխավոր էկրան (Փոքր 2×2)" : selectedLanguage == .russian ? "Рабочий стол (Малый 2×2)" : "Home Screen (Small 2×2)") :
                             previewWidgetSize == .medium ? (selectedLanguage == .armenian ? "Գլխավոր էկրան (Միջին 4×2)" : selectedLanguage == .russian ? "Рабочий стол (Средний 4×2)" : "Home Screen (Medium 4×2)") :
                             previewWidgetSize == .large ? (selectedLanguage == .armenian ? "Գլխավոր էկրան (Մեծ 4×4)" : selectedLanguage == .russian ? "Рабочий стол (Большой 4×4)" : "Home Screen (Large 4×4)") :
                             (selectedLanguage == .armenian ? "Կողպեքի էկրան (Մոնոխրոմ)" : selectedLanguage == .russian ? "Экран блокировки (Монохром)" : "Lock Screen (Monochrome)"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        pickVerseForCurrentSize(previewWidgetSize)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 11, weight: .bold))
                            Text("button_random_verse".localized(for: selectedLanguage))
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(Color(hex: selectedTheme.colorHex).opacity(0.12))
                        .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Живое интерактивное превью в выбранном стиле оформления
                Group {
                    switch previewWidgetSize {
                    case .lockScreen:
                        LockScreenPreviewCardView(
                            verse: previewVerse,
                            language: selectedWidgetLanguage.appLanguage ?? selectedLanguage,
                            style: selectedWidgetStyle,
                            colorScheme: colorScheme,
                            accentHex: selectedWidgetStyle == .oledStandby ? "F59E0B" : selectedTheme.colorHex
                        )
                        
                    case .small:
                        // Малый 2x2 (StandBy / Small Widget)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(selectedWidgetStyle.quoteIconColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                
                                Spacer()
                                
                                Text(previewVerse.reference(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                    .font(.system(size: 12, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                    .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                            }
                            
                            Text(previewVerse.text(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                .font(.system(size: 16, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                                .lineSpacing(3)
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .padding(.vertical, 2)
                            
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("widget_pray_done_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 11, weight: .semibold, design: selectedWidgetStyle.fontDesign))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                .cornerRadius(8)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(6)
                                    .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                    .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(14)
                        .background(selectedWidgetStyle.backgroundGradient(for: colorScheme))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(selectedWidgetStyle.borderStroke(for: colorScheme), lineWidth: 1.4)
                        )
                        
                    case .medium:
                        // Средний 4x2 (Medium Widget)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(selectedWidgetStyle.quoteIconColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                
                                Spacer()
                                
                                Text(previewVerse.reference(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                    .font(.system(size: 12.5, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                    .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                            }
                            
                            Text(previewVerse.text(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                .font(.system(size: 16.5, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                .lineLimit(4)
                                .minimumScaleFactor(0.78)
                                .lineSpacing(3.5)
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .padding(.vertical, 1)
                            
                            Spacer(minLength: 4)
                            
                            HStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("widget_next_verse_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 11, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                .cornerRadius(9)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "heart")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("widget_fav_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 11, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .cornerRadius(9)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "hands.sparkles.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("widget_pray_todo_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 11, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(Color(hex: selectedTheme.colorHex))
                                .cornerRadius(9)
                            }
                        }
                        .padding(14)
                        .background(selectedWidgetStyle.backgroundGradient(for: colorScheme))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(selectedWidgetStyle.borderStroke(for: colorScheme), lineWidth: 1.4)
                        )
                        
                    case .large:
                        // Большой 4x4 (Large Widget)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(selectedWidgetStyle.quoteIconColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                
                                Spacer()
                                
                                Text(previewVerse.reference(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                    .font(.system(size: 14, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                    .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                            }
                            
                            Text(previewVerse.text(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                .font(.system(size: 17.5, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                .lineLimit(7)
                                .minimumScaleFactor(0.75)
                                .lineSpacing(4.5)
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .padding(.vertical, 2)
                            
                            Spacer(minLength: 6)
                            
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("widget_next_verse_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 12, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.secondaryTextColor(for: colorScheme, accentHex: selectedTheme.colorHex))
                                .cornerRadius(10)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "heart")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("widget_fav_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 12, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(selectedWidgetStyle.primaryTextColor(for: colorScheme))
                                .cornerRadius(10)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "hands.sparkles.fill")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("widget_pray_todo_btn".localized(for: selectedWidgetLanguage.appLanguage ?? selectedLanguage))
                                        .font(.system(size: 12, weight: .bold, design: selectedWidgetStyle.fontDesign))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedWidgetStyle.buttonBackground(for: colorScheme))
                                .foregroundColor(Color(hex: selectedTheme.colorHex))
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(selectedWidgetStyle.backgroundGradient(for: colorScheme))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selectedWidgetStyle.borderStroke(for: colorScheme), lineWidth: 1.4)
                        )
                    }
                }
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: previewWidgetSize)
                
                // Выбор категории цитат под выбранный размер виджета
                VStack(alignment: .leading, spacing: 6) {
                    switch previewWidgetSize {
                    case .small:
                        Text(selectedLanguage == .armenian ? "Գլխավոր էկրանի համարների ոճը" : selectedLanguage == .russian ? "Стиль стихов для Рабочего стола" : "Home Screen Verse Category")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(LockScreenCategory.allCases) { cat in
                                    let isLocked = cat.isPremiumRequired && !subscriptionManager.isPremium
                                    LockCategoryChipView(
                                        cat: cat,
                                        isSelected: selectedLockCategory == cat,
                                        isLocked: isLocked,
                                        selectedLanguage: selectedLanguage,
                                        themeColorHex: selectedTheme.colorHex,
                                        inputFieldBgColor: inputFieldBgColor,
                                        inputFieldBorderColor: inputFieldBorderColor,
                                        primaryTextColor: primaryTextColor
                                    ) {
                                        if isLocked {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.prepare()
                                            generator.impactOccurred()
                                            isShowingPaywall = true
                                        } else {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.prepare()
                                            generator.impactOccurred()
                                            selectedLockCategory = cat
                                            manager.setLockScreenCategory(cat)
                                            pickVerseForCurrentSize(previewWidgetSize)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        
                    case .lockScreen:
                        Text("lockscreen_category_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(LockScreenCategory.allCases) { cat in
                                    let isLocked = cat.isPremiumRequired && !subscriptionManager.isPremium
                                    LockCategoryChipView(
                                        cat: cat,
                                        isSelected: selectedLockCategory == cat,
                                        isLocked: isLocked,
                                        selectedLanguage: selectedLanguage,
                                        themeColorHex: selectedTheme.colorHex,
                                        inputFieldBgColor: inputFieldBgColor,
                                        inputFieldBorderColor: inputFieldBorderColor,
                                        primaryTextColor: primaryTextColor
                                    ) {
                                        if isLocked {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.prepare()
                                            generator.impactOccurred()
                                            isShowingPaywall = true
                                        } else {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.prepare()
                                            generator.impactOccurred()
                                            selectedLockCategory = cat
                                            manager.setLockScreenCategory(cat)
                                            pickVerseForCurrentSize(previewWidgetSize)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        
                        // Выбор шрифта для виджета Lock Screen
                        Text(selectedLanguage == .armenian ? "Ֆոնտ" : selectedLanguage == .russian ? "Шрифт виджета" : "Widget Font")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(LockScreenFontDesign.allCases) { design in
                                    let isSelected = selectedLockFontDesign == design
                                    Button {
                                        let gen = UIImpactFeedbackGenerator(style: .light)
                                        gen.prepare()
                                        gen.impactOccurred()
                                        selectedLockFontDesign = design
                                        manager.setLockScreenFontDesign(design)
                                    } label: {
                                        VStack(spacing: 3) {
                                            Text(design.previewText)
                                                .font(.system(size: 13, weight: .semibold, design: design.fontDesign))
                                                .foregroundColor(isSelected ? Color(hex: selectedTheme.colorHex) : primaryTextColor)
                                            Text(design.title(for: selectedLanguage))
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(isSelected ? Color(hex: selectedTheme.colorHex) : .secondary)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(isSelected
                                                    ? Color(hex: selectedTheme.colorHex).opacity(0.15)
                                                    : inputFieldBgColor)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(isSelected ? Color(hex: selectedTheme.colorHex) : inputFieldBorderColor, lineWidth: isSelected ? 1.5 : 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        
                    case .medium:
                        Text("widget_medium_category_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(HomeWidgetCategory.allCases) { cat in
                                    let isLocked = cat.isPremiumRequired && !subscriptionManager.isPremium
                                    HomeCategoryChipView(
                                        cat: cat,
                                        isSelected: selectedMediumCategory == cat,
                                        isLocked: isLocked,
                                        selectedLanguage: selectedLanguage,
                                        themeColorHex: selectedTheme.colorHex,
                                        inputFieldBgColor: inputFieldBgColor,
                                        inputFieldBorderColor: inputFieldBorderColor,
                                        primaryTextColor: primaryTextColor
                                    ) {
                                        if isLocked {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.prepare()
                                            generator.impactOccurred()
                                            isShowingPaywall = true
                                        } else {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.prepare()
                                            generator.impactOccurred()
                                            selectedMediumCategory = cat
                                            manager.setMediumWidgetCategory(cat)
                                            pickVerseForCurrentSize(.medium)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        
                    case .large:
                        Text("widget_large_category_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(HomeWidgetCategory.allCases) { cat in
                                    let isLocked = cat.isPremiumRequired && !subscriptionManager.isPremium
                                    HomeCategoryChipView(
                                        cat: cat,
                                        isSelected: selectedLargeCategory == cat,
                                        isLocked: isLocked,
                                        selectedLanguage: selectedLanguage,
                                        themeColorHex: selectedTheme.colorHex,
                                        inputFieldBgColor: inputFieldBgColor,
                                        inputFieldBorderColor: inputFieldBorderColor,
                                        primaryTextColor: primaryTextColor
                                    ) {
                                        if isLocked {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.prepare()
                                            generator.impactOccurred()
                                            isShowingPaywall = true
                                        } else {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.prepare()
                                            generator.impactOccurred()
                                            selectedLargeCategory = cat
                                            manager.setLargeWidgetCategory(cat)
                                            pickVerseForCurrentSize(.large)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // Свеча для виджета «Молитвенная свеча» (если есть зажженные свечи)
                if !candleManager.activeCandles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "F59E0B"))
                            Text(selectedLanguage == .armenian ? "«Աղոթքի մոմ» վիջեթի ընտրություն" : (selectedLanguage == .russian ? "Свеча для виджета «Молитвенная свеча»" : "Candle for 'Prayer Candle' Widget"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                let isAutoSelected = candleManager.selectedWidgetCandleId == nil || candleManager.selectedWidgetCandleId == "latest"
                                Button {
                                    candleManager.setSelectedWidgetCandle(id: nil)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: isAutoSelected ? "checkmark.circle.fill" : "sparkles")
                                            .font(.system(size: 11, weight: .bold))
                                        Text(selectedLanguage == .armenian ? "🔥 Վերջին մոմը (Ավտո)" : (selectedLanguage == .russian ? "🔥 Последняя (Авто)" : "🔥 Latest (Auto)"))
                                            .font(.system(size: 12, weight: isAutoSelected ? .bold : .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(isAutoSelected ? Color(hex: "F59E0B").opacity(0.25) : inputFieldBgColor)
                                    .foregroundColor(isAutoSelected ? Color(hex: "FDE68A") : .secondary)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isAutoSelected ? Color(hex: "F59E0B") : inputFieldBorderColor, lineWidth: 1.2)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                ForEach(candleManager.activeCandles) { candle in
                                    let isSelected = candleManager.selectedWidgetCandleId == candle.id.uuidString
                                    let name = candle.personName.isEmpty ? candle.intention.title(for: selectedLanguage) : candle.personName
                                    Button {
                                        candleManager.setSelectedWidgetCandle(id: candle.id.uuidString)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : candle.intention.icon)
                                                .font(.system(size: 11, weight: .bold))
                                            Text(name)
                                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                                .lineLimit(1)
                                            Text(candle.remainingTimeText(for: selectedLanguage))
                                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                                .opacity(0.7)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color(hex: "F59E0B").opacity(0.25) : inputFieldBgColor)
                                        .foregroundColor(isSelected ? Color(hex: "FDE68A") : primaryTextColor)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(isSelected ? Color(hex: "F59E0B") : inputFieldBorderColor, lineWidth: 1.2)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // Кнопка «Применить и обновить все виджеты» с обратной связью
                Button {
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.success)
                    
                    manager.setWidgetVisualStyle(selectedWidgetStyle)
                    manager.syncLockScreenWidget()
                    WidgetCenter.shared.reloadTimelines(ofKind: "BibleWidget")
                    WidgetCenter.shared.reloadAllTimelines()
                    
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isWidgetsUpdatedSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isWidgetsUpdatedSuccess = false
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isWidgetsUpdatedSuccess ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                            .font(.system(size: 14.5, weight: .bold))
                        Text(isWidgetsUpdatedSuccess ?
                             (selectedLanguage == .armenian ? "✓ Բոլոր վիջեթները թարմացված են" :
                              selectedLanguage == .russian ? "✓ Все виджеты успешно обновлены" :
                              "✓ All Widgets Updated Successfully") :
                             "update_widgets_now_button".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        isWidgetsUpdatedSuccess ?
                            LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "059669")], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color(hex: selectedTheme.colorHex), Color(hex: selectedTheme.secondaryColorHex)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(13)
                    .shadow(color: (isWidgetsUpdatedSuccess ? Color(hex: "10B981") : Color(hex: selectedTheme.colorHex)).opacity(0.35), radius: 8, y: 3)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(cardBackgroundColor)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    var autoWallpaperSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "38BDF8").opacity(0.3), Color(hex: "0284C7").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "38BDF8"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("settings_auto_wallpaper_title".localized(for: selectedLanguage))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("NEW")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: "0284C7"))
                            .cornerRadius(5)
                    }
                    
                    Text("settings_auto_wallpaper_subtitle".localized(for: selectedLanguage))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                isShowingWallpaperAutomation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .bold))
                    Text("auto_wallpaper_nav_button".localized(for: selectedLanguage))
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }
    
}
