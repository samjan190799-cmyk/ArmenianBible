import SwiftUI
import WidgetKit
import LocalAuthentication

extension SettingsView {
    // MARK: - Единая секция Духовных Напоминаний
    @ViewBuilder
    private var spiritualNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                
                Text("notification_section_title".localized(for: selectedLanguage))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
            }
            
            Text("notification_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            VStack(spacing: 12) {
                // 1. Утренний стих дня
                notificationItemRow(
                    icon: "sun.max.fill",
                    iconColor: Color(hex: "F59E0B"),
                    title: "notification_morning_title".localized(for: selectedLanguage),
                    subtitle: "notification_morning_desc".localized(for: selectedLanguage),
                    isOn: $morningNotificationsEnabled,
                    onToggle: { newVal in
                        handleMorningToggle(newVal)
                    }
                ) {
                    DatePicker(
                        "notification_time_title".localized(for: selectedLanguage),
                        selection: $morningNotificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(inputFieldBgColor)
                    .cornerRadius(10)
                    .onChange(of: morningNotificationTime) { newTime in
                        manager.setMorningNotificationTime(newTime)
                    }
                }
                
                Divider().opacity(0.3)
                
                // 2. Вечерняя молитва и покой
                notificationItemRow(
                    icon: "moon.stars.fill",
                    iconColor: Color(hex: "818CF8"),
                    title: "notification_evening_title".localized(for: selectedLanguage),
                    subtitle: "notification_evening_desc".localized(for: selectedLanguage),
                    isOn: $eveningNotificationsEnabled,
                    onToggle: { newVal in
                        handleEveningToggle(newVal)
                    }
                ) {
                    DatePicker(
                        "notification_time_title".localized(for: selectedLanguage),
                        selection: $eveningNotificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(inputFieldBgColor)
                    .cornerRadius(10)
                    .onChange(of: eveningNotificationTime) { newTime in
                        manager.setEveningNotificationTime(newTime)
                    }
                }
                
                Divider().opacity(0.3)
                
                // 3. Церковные праздники и посты ААЦ
                notificationItemRow(
                    icon: "cross.fill",
                    iconColor: Color(hex: "10B981"),
                    title: "notification_church_calendar_title".localized(for: selectedLanguage),
                    subtitle: "notification_church_calendar_desc".localized(for: selectedLanguage),
                    isOn: $churchFeastsNotificationsEnabled,
                    onToggle: { newVal in
                        handleChurchFeastsToggle(newVal)
                    }
                )
                
                Divider().opacity(0.3)
                
                // 4. План чтения и стрик
                notificationItemRow(
                    icon: "flame.fill",
                    iconColor: Color(hex: "EC4899"),
                    title: "notification_reading_plan_title".localized(for: selectedLanguage),
                    subtitle: "notification_reading_plan_desc".localized(for: selectedLanguage),
                    isOn: $readingPlanNotificationsEnabled,
                    onToggle: { newVal in
                        handleReadingPlanToggle(newVal)
                    }
                ) {
                    DatePicker(
                        "notification_time_title".localized(for: selectedLanguage),
                        selection: $readingPlanNotificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(inputFieldBgColor)
                    .cornerRadius(10)
                    .onChange(of: readingPlanNotificationTime) { newTime in
                        manager.setReadingPlanNotificationTime(newTime)
                    }
                }
            }
            .padding(14)
            .background(inputFieldBgColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(inputFieldBorderColor, lineWidth: 1)
            )
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
    private func notificationItemRow<PickerContent: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onToggle: @escaping (Bool) -> Void,
        @ViewBuilder picker: () -> PickerContent
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(Color(hex: selectedTheme.colorHex))
                    .onChange(of: isOn.wrappedValue) { val in
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        onToggle(val)
                    }
            }
            
            if isOn.wrappedValue {
                HStack {
                    Spacer()
                    picker()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isOn.wrappedValue)
    }
    
    @ViewBuilder
    private func notificationItemRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onToggle: @escaping (Bool) -> Void
    ) -> some View {
        notificationItemRow(
            icon: icon,
            iconColor: iconColor,
            title: title,
            subtitle: subtitle,
            isOn: isOn,
            onToggle: onToggle,
            picker: { EmptyView() }
        )
    }
    
    private func handleMorningToggle(_ newVal: Bool) {
        manager.setMorningNotificationsEnabled(newVal)
        if newVal {
            manager.requestNotificationPermission { granted in
                if !granted {
                    self.morningNotificationsEnabled = false
                    manager.setMorningNotificationsEnabled(false)
                }
            }
        }
    }
    
    private func handleEveningToggle(_ newVal: Bool) {
        manager.setEveningNotificationsEnabled(newVal)
        if newVal {
            manager.requestNotificationPermission { granted in
                if !granted {
                    self.eveningNotificationsEnabled = false
                    manager.setEveningNotificationsEnabled(false)
                }
            }
        }
    }
    
    private func handleChurchFeastsToggle(_ newVal: Bool) {
        manager.setChurchFeastsNotificationsEnabled(newVal)
        if newVal {
            manager.requestNotificationPermission { granted in
                if !granted {
                    self.churchFeastsNotificationsEnabled = false
                    manager.setChurchFeastsNotificationsEnabled(false)
                }
            }
        }
    }
    
    private func handleReadingPlanToggle(_ newVal: Bool) {
        manager.setReadingPlanNotificationsEnabled(newVal)
        if newVal {
            manager.requestNotificationPermission { granted in
                if !granted {
                    self.readingPlanNotificationsEnabled = false
                    manager.setReadingPlanNotificationsEnabled(false)
                }
            }
        }
    }
    
    @ViewBuilder
    private var updateIntervalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("update_interval_title".localized(for: selectedLanguage))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    isShowingWidgetInstruction = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                        Text("widget_instruction_title".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Text("update_interval_description".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Picker("update_interval_title", selection: $selectedInterval) {
                ForEach(UpdateInterval.allCases) { interval in
                    Text(interval.localizedTitle(for: selectedLanguage)).tag(interval)
                }
            }
            .pickerStyle(.menu)
            .tint(colorScheme == .dark ? .white : .primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(inputFieldBgColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(inputFieldBorderColor, lineWidth: 1)
            )
            .onChange(of: selectedInterval) { newInt in
                manager.setUpdateInterval(newInt)
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var verseSourceScopeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("verse_source_scope_title".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Text("verse_source_scope_description".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            VStack(spacing: 8) {
                ForEach(VerseSourceScope.allCases) { scope in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        selectedScope = scope
                        manager.updateVerseSourceScope(scope)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: scope.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(selectedScope == scope ? Color(hex: selectedTheme.colorHex) : .secondary)
                                .frame(width: 24)
                            
                            Text(scope.title(for: selectedLanguage))
                                .font(.system(size: 14, weight: selectedScope == scope ? .bold : .medium))
                                .foregroundColor(primaryTextColor)
                            
                            Spacer()
                            
                            if selectedScope == scope {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedScope == scope ? Color(hex: selectedTheme.colorHex).opacity(0.12) : inputFieldBgColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedScope == scope ? Color(hex: selectedTheme.colorHex) : inputFieldBorderColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var contentTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("content_type_title".localized(for: selectedLanguage))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Text("content_type_description".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Picker("content_type_title", selection: $selectedCategory) {
                ForEach(TextCategory.allCases) { category in
                    Text(category.localizedTitle(for: selectedLanguage)).tag(category)
                }
            }
            .pickerStyle(.menu)
            .tint(colorScheme == .dark ? .white : .primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(inputFieldBgColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(inputFieldBorderColor, lineWidth: 1)
            )
            .onChange(of: selectedCategory) { newCat in
                manager.setSelectedCategory(newCat)
            }
        }
        .padding(.horizontal, 4)
    }
    
}
