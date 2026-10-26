import SwiftUI

// MARK: - Подсказка поверх приложения: задание древа выполнено
/// Появляется на пару секунд, когда чтение главы, свеча или другое действие засчитано в задания дня.
/// Без неё человек не поймёт, откуда взялся отклик и почему растёт древо.
struct PomegranateTaskToastView: View {
    @ObservedObject private var tree = PomegranateTreeManager.shared
    @ObservedObject private var bible = BibleManager.shared

    private var language: AppLanguage { bible.appLanguage }

    var body: some View {
        VStack {
            if let toast = tree.taskToast {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Paper.lapis.opacity(0.18))
                            .frame(width: 34, height: 34)
                        Image(systemName: icon(for: toast))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Paper.lapis)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title(for: toast))
                            .font(PaperFont.font(size: 14, weight: .semibold))
                            .foregroundColor(Paper.ink)
                        Text(subtitle(for: toast))
                            .font(PaperFont.font(size: 12))
                            .foregroundColor(Paper.inkSecondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: Paper.shadow, radius: 10, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Paper.lapis.opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
                .id(toast.id)
                .task(id: toast.id) {
                    try? await Task.sleep(nanoseconds: 3_200_000_000)
                    if tree.taskToast?.id == toast.id {
                        withAnimation(.easeInOut(duration: 0.3)) { tree.taskToast = nil }
                    }
                }
            }
            Spacer()
        }
        .padding(.top, 6)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: tree.taskToast?.id)
        .allowsHitTesting(false)
    }

    private func icon(for toast: PomegranateToast) -> String {
        switch toast.kind {
        case .task: return "drop.fill"
        case .perfectDay: return "sparkles"
        }
    }

    private func title(for toast: PomegranateToast) -> String {
        switch toast.kind {
        case .task:
            return language.pick(hy: "Առաջադրանքը կատարված է", ru: "Задание выполнено", en: "Task complete")
        case .perfectDay:
            return language.pick(hy: "Օրվա բոլոր առաջադրանքները կատարված են", ru: "Все задания дня выполнены", en: "All of today's tasks are done")
        }
    }

    private func subtitle(for toast: PomegranateToast) -> String {
        switch toast.kind {
        case .task(let task, let dew):
            return task.title(for: language) + " · +\(dew)"
        case .perfectDay(let bonus):
            return language.pick(
                hy: "Ծառը ստացավ ևս +\(bonus) ցող",
                ru: "Древо получило ещё +\(bonus) росинки",
                en: "The tree received another +\(bonus) dew"
            )
        }
    }
}
