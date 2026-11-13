import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Разделы главного экрана, которые пользователь может переставлять
/// Устойчивые идентификаторы. В хранилище попадает `rawValue`, а не номер места:
/// новый раздел встанет на своё место по умолчанию, а удалённый не сломает экран.
/// Шапка с датой и карточка стиха дня сюда не входят: они всегда наверху.
enum HomeSection: String, CaseIterable, Identifiable {
    case manuscript
    case narekatsi
    case consolation
    case nativity
    case prayer
    case tree
    case readingPlan
    case quiz
    case feasts
    case sanctuaryMap
    case premium

    var id: String { rawValue }

    /// Порядок по умолчанию (как карточки шли на экране до перестановки)
    static var defaultOrder: [String] { allCases.map { $0.rawValue } }
}

// MARK: - Логика порядка (чистые функции на строках: удобно проверять отдельно)
enum HomeSectionOrder {
    /// Ключ в UserDefaults: идентификаторы через запятую
    static let storageKey = "luys_home_section_order_v1"

    static func decode(_ raw: String) -> [String] {
        raw.split(separator: ",").map { String($0) }
    }

    static func encode(_ ids: [String]) -> String {
        ids.joined(separator: ",")
    }

    /// Сохранённый порядок + набор по умолчанию.
    /// Неизвестные и повторяющиеся идентификаторы отбрасываются; недостающие (новые) разделы
    /// встают сразу после своего предыдущего соседа из порядка по умолчанию (или в начало).
    static func merge(saved: [String], defaults: [String]) -> [String] {
        var result: [String] = []
        for id in saved {
            if defaults.contains(id) && !result.contains(id) {
                result.append(id)
            }
        }
        for (index, id) in defaults.enumerated() {
            if result.contains(id) { continue }
            var insertAt = 0
            var j = index - 1
            while j >= 0 {
                if let position = result.firstIndex(of: defaults[j]) {
                    insertAt = position + 1
                    break
                }
                j -= 1
            }
            result.insert(id, at: insertAt)
        }
        return result
    }

    /// Раздел `id` встаёт на место раздела `target`: идущий вниз оказывается после него, идущий вверх до него
    static func move(_ order: [String], id: String, onto target: String) -> [String] {
        guard id != target,
              let from = order.firstIndex(of: id),
              let to = order.firstIndex(of: target) else { return order }
        var result = order
        let item = result.remove(at: from)
        result.insert(item, at: to)
        return result
    }

    /// Сдвиг на одну позицию выше (-1) или ниже (+1); на краю порядок не меняется
    static func shift(_ order: [String], id: String, by delta: Int) -> [String] {
        guard let from = order.firstIndex(of: id) else { return order }
        let to = from + delta
        guard to >= 0 && to < order.count else { return order }
        var result = order
        result.swapAt(from, to)
        return result
    }

}

// MARK: - Перетаскивание карточки: цель падения у каждой карточки
/// Пока карточку тащат, другие расступаются: как только палец заходит на соседа, раздел встаёт на его место.
struct HomeSectionDropDelegate: DropDelegate {
    let target: HomeSection
    @Binding var dragged: HomeSection?
    let onMove: (HomeSection, HomeSection) -> Void
    let onFinish: () -> Void

    func validateDrop(info: DropInfo) -> Bool {
        dragged != nil
    }

    func dropEntered(info: DropInfo) {
        if let current = dragged, current != target {
            onMove(current, target)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        onFinish()
        return true
    }
}

/// Цель падения на весь экран: отпустили между карточками или у края, перетаскивание всё равно завершается чисто
struct HomeSectionEndDropDelegate: DropDelegate {
    @Binding var dragged: HomeSection?
    let onFinish: () -> Void

    func validateDrop(info: DropInfo) -> Bool {
        dragged != nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        onFinish()
        return true
    }
}

// MARK: - Строка в «Настройках»: вернуть порядок по умолчанию
struct HomeSectionOrderResetRow: View {
    let language: AppLanguage
    let primaryTextColor: Color
    let accent: Color

    @AppStorage(HomeSectionOrder.storageKey) private var savedOrderRaw: String = ""

    private var isCustomized: Bool {
        let current = HomeSectionOrder.merge(saved: HomeSectionOrder.decode(savedOrderRaw), defaults: HomeSection.defaultOrder)
        return current != HomeSection.defaultOrder
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accent.opacity(0.15))
                    .frame(width: 34, height: 34)

                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(language.pick(hy: "Բաժինների դասավորությունը", ru: "Порядок разделов", en: "Order of sections"))
                    .font(PaperFont.font(size: 14, weight: .semibold))
                    .foregroundColor(primaryTextColor)

                Text(language.pick(
                    hy: "Գլխավոր էկրանին երկար սեղմեք քարտի վրա և տեղափոխեք",
                    ru: "На главном экране удерживайте карточку и перетащите её на нужное место",
                    en: "On the home screen, press and hold a card and drag it where you want it"
                ))
                    .font(PaperFont.font(size: 11.5))
                    .foregroundColor(Paper.inkSecondary)
                    .lineLimit(3)
            }

            Spacer()

            Button {
                Haptics.impact(.light)
                withAnimation(PaperMotion.animation(PaperMotion.swap)) {
                    savedOrderRaw = ""
                }
            } label: {
                Text(language.pick(hy: "Վերականգնել", ru: "Сбросить", en: "Reset"))
                    .font(PaperFont.font(size: 13, weight: .semibold))
                    .foregroundColor(isCustomized ? accent : Paper.inkSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill((isCustomized ? accent : Paper.inkSecondary).opacity(0.12)))
            }
            .buttonStyle(.plain)
            .disabled(!isCustomized)
            .accessibilityLabel(Text(language.pick(hy: "Վերականգնել բաժինների դասավորությունը", ru: "Сбросить порядок разделов", en: "Reset the order of sections")))
        }
    }
}
