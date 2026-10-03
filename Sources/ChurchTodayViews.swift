import SwiftUI

// MARK: - Чтения дня: каждая ссылка открывает место в читалке
struct ScriptureReadingsListView: View {
    let readingText: String
    let language: AppLanguage
    let primaryTextColor: Color
    let onOpen: (ScriptureReference) -> Void

    private var references: [ScriptureReference] {
        ScriptureReferenceParser.parse(readingText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(references.enumerated()), id: \.offset) { _, reference in
                if reference.canOpen {
                    Button {
                        onOpen(reference)
                    } label: {
                        referenceRow(reference, opensInReader: true)
                    }
                    .buttonStyle(FluidSpringButtonStyle(scaleDown: 0.98))
                } else {
                    referenceRow(reference, opensInReader: false)
                }
            }
        }
    }

    private func referenceRow(_ reference: ScriptureReference, opensInReader: Bool) -> some View {
        HStack(spacing: 8) {
            Text(reference.displayText(for: language))
                .font(PaperFont.font(size: 14, weight: .medium))
                .foregroundColor(primaryTextColor)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            if opensInReader {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Paper.inkTertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Панель «Сегодня в Церкви»: постный день и чтения праздника
/// Показывается над списком праздников, только если на сегодня есть что сказать:
/// постный день, праздник или и то и другое. Для спорных дней и обычных дней панели нет.
struct ChurchTodayPanelView: View {
    let language: AppLanguage
    let primaryTextColor: Color
    let onOpenReading: (ScriptureReference) -> Void

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeCode)
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: Date())
    }

    var body: some View {
        let fast = ChurchCalendarService.shared.fastDay(on: Date())
        let feast = ChurchCalendarService.shared.todayFeast()
        let readingText = feast?.scriptureReading ?? ""

        if fast != nil || feast != nil {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("church_today_panel_title".localized(for: language))
                        .font(PaperFont.font(size: 12, weight: .semibold))
                        .tracking(0.6)
                        .foregroundColor(Paper.gold)
                    Spacer()
                    Text(dateText)
                        .font(PaperFont.font(size: 12))
                        .foregroundColor(Paper.inkSecondary)
                }

                if let fast = fast {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Paper.plum)
                        Text(fast.kind.title(for: language))
                            .font(PaperFont.font(size: 16, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .multilineTextAlignment(.leading)
                    }
                }

                if let feast = feast {
                    HStack(spacing: 8) {
                        Image(systemName: feast.type.icon)
                            .font(.system(size: 14))
                            .foregroundColor(feast.type.color)
                        Text(feast.title(for: language))
                            .font(PaperFont.font(size: 16, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .multilineTextAlignment(.leading)
                    }
                }

                if !readingText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Paper.moss)
                            Text("scripture_readings_title".localized(for: language))
                                .font(PaperFont.font(size: 12, weight: .semibold))
                                .foregroundColor(Paper.moss)
                        }
                        ScriptureReadingsListView(
                            readingText: readingText,
                            language: language,
                            primaryTextColor: primaryTextColor,
                            onOpen: onOpenReading
                        )
                    }
                }

                if fast != nil {
                    Text("church_fast_disclaimer".localized(for: language))
                        .font(PaperFont.font(size: 11))
                        .foregroundColor(Paper.inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !readingText.isEmpty {
                    Text("church_readings_disclaimer".localized(for: language))
                        .font(PaperFont.font(size: 11))
                        .foregroundColor(Paper.inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperSheet(cornerRadius: 18)
        }
    }
}
