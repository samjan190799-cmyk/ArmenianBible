import SwiftUI

// MARK: - Главный экран Планов Чтения Библии
struct ReadingPlansCatalogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var planManager = ReadingPlanManager.shared
    @ObservedObject private var bibleManager = BibleManager.shared
    
    @State private var selectedCategory: PlanCategory? = nil
    @State private var selectedPlanForDetail: ReadingPlan? = nil
    
    private var language: AppLanguage {
        bibleManager.appLanguage
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.white
    }
    
    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }
    
    var filteredPlans: [ReadingPlan] {
        if let cat = selectedCategory {
            return ReadingPlan.allPlans.filter { $0.category == cat }
        }
        return ReadingPlan.allPlans
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. Плашка со стриком (серией дней)
                        streakHeaderView
                        
                        // 2. Активный план (если выбран)
                        if let activePlan = planManager.activePlan {
                            activePlanCard(activePlan)
                        }
                        
                        // 3. Категории планов
                        categoryFilterView
                        
                        // 4. Список планов
                        VStack(spacing: 14) {
                            ForEach(filteredPlans) { plan in
                                planRowCard(plan)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("reading_plans_title".localized(for: language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close_button".localized(for: language)) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }
                    .foregroundColor(primaryTextColor)
                }
            }
            .sheet(item: $selectedPlanForDetail) { plan in
                ReadingPlanDetailView(plan: plan, onOpenReading: { target in
                    dismiss()
                    planManager.openReadingInBible(target: target)
                })
            }
        }
    }
    
    // MARK: - Плашка Стрика (Дни подряд)
    private var streakHeaderView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "EF4444"), Color(hex: "F59E0B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: Color(hex: "EF4444").opacity(0.3), radius: 8, y: 3)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("\(planManager.currentStreak)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(primaryTextColor)
                    
                    Text("streak_days_suffix".localized(for: language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryTextColor)
                }
                
                Text(planManager.currentStreak > 0 ?
                     "streak_active_message".localized(for: language) :
                     "streak_start_message".localized(for: language))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("streak_record_label".localized(for: language))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text("\(planManager.bestStreak)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(primaryTextColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            .cornerRadius(10)
        }
        .padding(16)
        .background(cardBackgroundColor)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Карточка Активного Плана
    private func activePlanCard(_ plan: ReadingPlan) -> some View {
        let completed = planManager.completedDaysCount(for: plan.id)
        let total = plan.daysCount
        let progress = planManager.progress(for: plan.id)
        let nextDay = planManager.nextIncompleteDay(for: plan.id)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("active_plan_header".localized(for: language))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "10B981"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "10B981").opacity(0.12))
                    .cornerRadius(6)
                
                Spacer()
                
                Text("\(completed)/\(total)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(plan.gradient)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: plan.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title(for: language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    
                    if let day = nextDay {
                        Text("\("day_label".localized(for: language)) \(day.dayNumber): \(day.title(for: language))")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Прогресс-бар
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(plan.gradient)
                        .frame(width: max(8, geo.size.width * CGFloat(progress)), height: 8)
                }
            }
            .frame(height: 8)
            
            // Кнопки управления
            HStack(spacing: 10) {
                if let day = nextDay {
                    Button {
                        dismiss()
                        planManager.openReadingInBible(target: day.target)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("read_today_button".localized(for: language))
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(plan.gradient)
                        .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    selectedPlanForDetail = plan
                } label: {
                    Text("view_plan_button".localized(for: language))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(cardBackgroundColor)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(plan.gradientColors.first.map { Color(hex: $0).opacity(0.3) } ?? cardBorderColor, lineWidth: 1.5)
        )
    }
    
    // MARK: - Фильтр Категорий
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryPill(title: "all_categories".localized(for: language), isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                
                ForEach(PlanCategory.allCases) { cat in
                    categoryPill(title: cat.localizedName(for: language), isSelected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
        }
    }
    
    private func categoryPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? primaryTextColor : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)))
                .foregroundColor(isSelected ? (colorScheme == .dark ? .black : .white) : primaryTextColor)
                .cornerRadius(20)
        }
    }
    
    // MARK: - Карточка Плана в Списке
    private func planRowCard(_ plan: ReadingPlan) -> some View {
        let isCurrent = planManager.activePlanId == plan.id
        let completed = planManager.completedDaysCount(for: plan.id)
        
        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            selectedPlanForDetail = plan
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(plan.gradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: plan.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title(for: language))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Spacer()
                        
                        Text("\(plan.daysCount) \("days_suffix".localized(for: language))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(plan.desc(for: language))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if completed > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "10B981"))
                            Text("\(completed)/\(plan.daysCount) \("completed_label".localized(for: language))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "10B981"))
                        }
                        .padding(.top, 2)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(14)
            .background(cardBackgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isCurrent ? Color(hex: "10B981").opacity(0.4) : cardBorderColor, lineWidth: isCurrent ? 1.5 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Детальный экран плана чтения
struct ReadingPlanDetailView: View {
    let plan: ReadingPlan
    let onOpenReading: (PlanReadingTarget) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var planManager = ReadingPlanManager.shared
    @ObservedObject private var bibleManager = BibleManager.shared
    
    private var language: AppLanguage {
        bibleManager.appLanguage
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1E293B")
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "090A0F") : Color(hex: "F8FAFC")
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.white
    }
    
    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }
    
    var isCurrentPlan: Bool {
        planManager.activePlanId == plan.id
    }
    
    var completedCount: Int {
        planManager.completedDaysCount(for: plan.id)
    }
    
    var isAllCompleted: Bool {
        completedCount >= plan.daysCount
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. Шапка плана
                        headerView
                        
                        // 2. Кнопка «Сделать активным» / «Отказаться»
                        actionButton
                        
                        // 3. Список всех дней
                        daysListView
                    }
                    .padding(20)
                }
            }
            .navigationTitle(plan.title(for: language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close_button".localized(for: language)) {
                        dismiss()
                    }
                    .foregroundColor(primaryTextColor)
                }
            }
        }
    }
    
    // MARK: - Шапка плана
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(plan.gradient)
                        .frame(width: 58, height: 58)
                    
                    Image(systemName: plan.icon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title(for: language))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    
                    Text("\(plan.daysCount) \("days_suffix".localized(for: language)) • \(plan.category.localizedName(for: language))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(plan.desc(for: language))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            // Прогресс
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("progress_label".localized(for: language))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(completedCount) / \(plan.daysCount) (\(Int(planManager.progress(for: plan.id) * 100))%)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(primaryTextColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(plan.gradient)
                            .frame(width: max(8, geo.size.width * CGFloat(planManager.progress(for: plan.id))), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(cardBackgroundColor)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Кнопка выбора активного плана
    private var actionButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            if isCurrentPlan {
                planManager.stopActivePlan()
            } else {
                planManager.startPlan(id: plan.id)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isCurrentPlan ? "xmark.circle" : "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                
                Text(isCurrentPlan ?
                     "abandon_plan_button".localized(for: language) :
                     "start_plan_button".localized(for: language))
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(isCurrentPlan ? .red : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isCurrentPlan ?
                    Color.red.opacity(0.12) :
                    Color(hex: "10B981")
            )
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Список Дней
    private var daysListView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("reading_schedule_header".localized(for: language))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 4)
            
            ForEach(plan.days) { day in
                let isDone = planManager.isDayCompleted(planId: plan.id, dayNumber: day.dayNumber)
                
                HStack(spacing: 12) {
                    // Чекбокс отметки дня
                    Button {
                        planManager.toggleDayCompletion(planId: plan.id, dayNumber: day.dayNumber)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isDone ? Color(hex: "10B981") : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)))
                                .frame(width: 32, height: 32)
                            
                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(day.dayNumber)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Описание дня
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\("day_label".localized(for: language)) \(day.dayNumber): \(day.title(for: language))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isDone ? .secondary : primaryTextColor)
                            .strikethrough(isDone, color: .secondary)
                        
                        Text(day.desc(for: language))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Кнопка Читать
                    Button {
                        dismiss()
                        onOpenReading(day.target)
                    } label: {
                        HStack(spacing: 4) {
                            Text("read_button".localized(for: language))
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "3B82F6"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "3B82F6").opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(12)
                .background(cardBackgroundColor)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isDone ? Color(hex: "10B981").opacity(0.3) : cardBorderColor, lineWidth: 1)
                )
            }
        }
    }
}
