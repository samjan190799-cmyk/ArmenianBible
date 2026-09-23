import SwiftUI
import WidgetKit
import LocalAuthentication

extension SettingsView {
    // MARK: - Секция: Система и данные (Haptics, Face ID, Cache, Backup)
    @ViewBuilder
    private var systemAndDataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Шапка секции
            HStack(spacing: 8) {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: selectedTheme.colorHex))
                
                Text("system_storage_section_title".localized(for: selectedLanguage))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryTextColor)
            }
            
            Text("system_storage_section_desc".localized(for: selectedLanguage))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            VStack(spacing: 12) {
                // 1. Тактильный отклик (Haptic Feedback)
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "3B82F6").opacity(0.15))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("haptics_title".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("haptics_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isHapticsEnabled)
                        .labelsHidden()
                        .tint(Color(hex: selectedTheme.colorHex))
                        .onChange(of: isHapticsEnabled) { newVal in
                            manager.setHapticsEnabled(newVal)
                            if newVal {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                            }
                        }
                }
                
                Divider().opacity(0.3)
                
                // 2. Блокировка Face ID / Touch ID
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "10B981").opacity(0.15))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "faceid")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("biometric_lock_title".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("biometric_lock_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isBiometricLockEnabled)
                        .labelsHidden()
                        .tint(Color(hex: selectedTheme.colorHex))
                        .onChange(of: isBiometricLockEnabled) { newVal in
                            manager.setBiometricLockEnabled(newVal) { success in
                                if !success {
                                    self.isBiometricLockEnabled = manager.isBiometricLockEnabled
                                }
                            }
                        }
                }
                
                Divider().opacity(0.3)
                
                // 3. Очистка кэша
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "EF4444").opacity(0.15))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "trash.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("cache_clear_title".localized(for: selectedLanguage))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                            
                            // Бейдж размера кэша
                            Text(cacheSizeDisplay)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(inputFieldBgColor)
                                .cornerRadius(6)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("cache_clear_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button {
                        isClearingCache = true
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        
                        _ = manager.clearAppCache()
                        cacheSizeDisplay = manager.calculateCacheSize()
                        isClearingCache = false
                        withAnimation {
                            showCacheClearedToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showCacheClearedToast = false
                            }
                        }
                    } label: {
                        Text("cache_clear_btn".localized(for: selectedLanguage))
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(Color(hex: "EF4444"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "EF4444").opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                if showCacheClearedToast {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10B981"))
                            .font(.system(size: 12))
                        Text("cache_cleared_toast".localized(for: selectedLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Divider().opacity(0.3)
                
                // 4. Резервное копирование и экспорт
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "8B5CF6").opacity(0.15))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("export_backup_title".localized(for: selectedLanguage))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("export_backup_desc".localized(for: selectedLanguage))
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        
                        if let url = manager.generateBackupArchive() {
                            self.backupShareUrl = url
                            self.isShowingShareSheet = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: selectedTheme.colorHex))
                            .padding(8)
                            .background(Color(hex: selectedTheme.colorHex).opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
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
    private var aboutSection: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                // 🔐 Секретная зона разработчика: 5 быстрых тапов → диалог PIN-кода
                HStack(spacing: 6) {
                    Text("about_app_title".localized(for: selectedLanguage))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    let now = Date()
                    // Сброс счётчика если пауза между тапами > 2.5 секунд
                    if now.timeIntervalSince(secretLastTap) > 2.5 {
                        secretTapCount = 0
                    }
                    secretLastTap = now
                    secretTapCount += 1
                    
                    let g = UIImpactFeedbackGenerator(style: secretTapCount >= 5 ? .heavy : .light)
                    g.prepare()
                    g.impactOccurred()
                    
                    if secretTapCount >= 5 {
                        secretTapCount = 0
                        devPasscodeInput = ""
                        isShowingDevPasscodeAlert = true
                    }
                }
            
            HStack {
                Text("about_app_version".localized(for: selectedLanguage))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.4")
                    .foregroundColor(.secondary)
                
                Button {
                    let g = UIImpactFeedbackGenerator(style: .light)
                    g.prepare(); g.impactOccurred()
                    AppUpdateManager.shared.checkForUpdates(language: selectedLanguage)
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: selectedTheme.colorHex))
                        .padding(4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .font(.system(size: 14))
            
            HStack {
                Text("about_app_developer".localized(for: selectedLanguage))
                Spacer()
                Text("Samvel")
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 14))
            
            Divider().opacity(0.4)
            
            // ─── Кнопка "Armenian Bible Premium" ────────────────────────
            if subscriptionManager.isPremium {
                // Уже Premium — показываем статус
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ARMENIAN BIBLE PREMIUM")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text({
                            switch selectedLanguage {
                            case .armenian: return "Ձեր բաժանորդագրությունն ակտիվ է ✓"
                            case .russian:  return "Ваша подписка активна ✓"
                            case .english:  return "Your subscription is active ✓"
                            }
                        }())
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(Color(hex: "F59E0B").opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "F59E0B").opacity(0.25), lineWidth: 1))
            } else {
                // Не Premium — кнопка открытия Paywall
                Button {
                    let g = UIImpactFeedbackGenerator(style: .medium)
                    g.prepare(); g.impactOccurred()
                    isShowingPaywall = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ARMENIAN BIBLE PREMIUM")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(Color(hex: "F59E0B"))
                            Text({
                                switch selectedLanguage {
                                case .armenian: return "Բացեք բոլոր հնարավորությունները →"
                                case .russian:  return "Открыть все возможности →"
                                case .english:  return "Unlock all features →"
                                }
                            }())
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "F59E0B").opacity(0.7))
                    }
                    .padding(12)
                    .background(Color(hex: "F59E0B").opacity(0.08))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "F59E0B").opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // ─── Кнопка "Восстановить покупки" ──────────────────────────
            Button {
                let g = UINotificationFeedbackGenerator()
                g.prepare(); g.notificationOccurred(.success)
                Task {
                    let restored = await subscriptionManager.restorePurchases()
                    if restored {
                        let s = UINotificationFeedbackGenerator()
                        s.notificationOccurred(.success)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text({
                        switch selectedLanguage {
                        case .armenian: return "Վերականգնել գնումները"
                        case .russian:  return "Восстановить покупки"
                        case .english:  return "Restore Purchases"
                        }
                    }())
                    .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(hex: selectedTheme.colorHex))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: selectedTheme.colorHex).opacity(0.07))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: selectedTheme.colorHex).opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(subscriptionManager.isPurchasing)
            
            // ─── Кнопка "Оценить Luys в App Store" ───────────────────────
            Button {
                let g = UINotificationFeedbackGenerator()
                g.prepare(); g.notificationOccurred(.success)
                ReviewManager.shared.openAppStoreReviewDirectly()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text({
                        switch selectedLanguage {
                        case .armenian: return "Գնահատել Luys-ը App Store-ում ⭐⭐⭐⭐⭐"
                        case .russian:  return "Оценить Luys в App Store ⭐⭐⭐⭐⭐"
                        case .english:  return "Rate Luys on App Store ⭐⭐⭐⭐⭐"
                        }
                    }())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "F59E0B"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color(hex: "F59E0B").opacity(0.12))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "F59E0B").opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(18)
        .background(aboutBlockBgColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(aboutBlockBorderColor, lineWidth: 1)
        )
        
        // ─── Всплывающее уведомление режима разработчика ────────────────────
        if showDevToast {
            HStack(spacing: 12) {
                Image(systemName: devToastIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(devToastMessage)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(devToastSubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: devToastColor,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: (devToastColor.first ?? .clear).opacity(0.45), radius: 12, x: 0, y: 4)
            )
            .padding(.top, 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        } // конец ZStack
    }
    
    // MARK: - Обработка переключения режима разработчика
    private func handleDevToggle(enablePremium: Bool) {
        let code = devPasscodeInput.trimmingCharacters(in: .whitespaces)
        if code == "1907" || code == "7777" || code == "2026" {
            subscriptionManager.toggleDeveloperPremium(to: enablePremium)
            let n = UINotificationFeedbackGenerator()
            n.notificationOccurred(.success)
            
            if enablePremium {
                devToastIcon = "crown.fill"
                devToastMessage = "👑 Premium активирован!"
                devToastSubtitle = "Все возможности открыты, реклама полностью отключена."
                devToastColor = [Color(hex: "F59E0B"), Color(hex: "D97706")]
            } else {
                devToastIcon = "hammer.fill"
                devToastMessage = "🧪 Free-режим включен!"
                devToastSubtitle = "Реклама Meta включена, лимиты активны для теста."
                devToastColor = [Color(hex: "3B82F6"), Color(hex: "1D4ED8")]
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showDevToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { showDevToast = false }
            }
        } else {
            let n = UINotificationFeedbackGenerator()
            n.notificationOccurred(.error)
        }
        devPasscodeInput = ""
    }
    
    // MARK: - Выбор стиха для текущего размера виджета в предпросмотре
    private func pickVerseForCurrentSize(_ size: PreviewWidgetSize) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            switch size {
            case .lockScreen:
                let pool = BibleVerse.lockScreenVerses(for: selectedLockCategory)
                previewVerse = pool.randomElement() ?? BibleVerse.shortPearls[0]
            case .small:
                let pool = BibleVerse.lockScreenVerses(for: selectedLockCategory)
                previewVerse = pool.randomElement() ?? BibleVerse.shortPearls[0]
            case .medium:
                let pool = BibleVerse.verses(for: selectedMediumCategory, isPremium: subscriptionManager.isPremium)
                let filtered = pool.filter { $0.textHy.count >= 35 && $0.textHy.count <= 100 }
                previewVerse = (!filtered.isEmpty ? filtered : pool).randomElement() ?? BibleVerse.database[1]
            case .large:
                let pool = BibleVerse.verses(for: selectedLargeCategory, isPremium: subscriptionManager.isPremium)
                let filtered = pool.filter { $0.textHy.count >= 75 }
                previewVerse = (!filtered.isEmpty ? filtered : pool).randomElement() ?? BibleVerse.database[0]
            }
        }
    }
}
