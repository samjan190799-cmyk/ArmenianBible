import SwiftUI

// MARK: - Боковая панель истории чатов
// Выезжает слева поверх экрана ИИ-чата. Беседы сгруппированы по дням, закреплённые сверху; есть поиск по названиям
// и вопросам, новый чат, переименование, закрепление и удаление (свайпом и через долгое нажатие).
struct AIChatHistoryPanel: View {
    @ObservedObject var store: AIChatStore
    let language: AppLanguage
    let accentColor: Color
    let onNewChat: () -> Void
    let onSelect: (UUID) -> Void
    let onClose: () -> Void

    @State private var query = ""
    @State private var renamingID: UUID? = nil
    @State private var renameText = ""
    @State private var isShowingRename = false
    @State private var deletingID: UUID? = nil
    @State private var isShowingDelete = false

    private struct ChatSection: Identifiable {
        let id: String
        let title: String
        let items: [AIChatSummary]
    }

    private func t(_ key: String) -> String {
        key.localized(for: language)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            newChatButton
            searchField
            contentView
        }
        .background(Paper.page.ignoresSafeArea())
        .alert(t("ai_chat_rename_title"), isPresented: $isShowingRename) {
            TextField(t("ai_chat_rename_title"), text: $renameText)
            Button(t("alert_cancel_button"), role: .cancel) {}
            Button(t("ai_chat_save")) {
                if let id = renamingID {
                    store.rename(id, to: renameText)
                }
            }
        }
        .confirmationDialog(t("ai_chat_delete_confirm_title"), isPresented: $isShowingDelete, titleVisibility: .visible) {
            Button(t("ai_chat_delete"), role: .destructive) {
                if let id = deletingID {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        store.delete(id)
                    }
                }
            }
            Button(t("alert_cancel_button"), role: .cancel) {}
        } message: {
            Text(t("ai_chat_delete_confirm_msg"))
        }
    }

    // MARK: - Шапка, новый чат, поиск

    private var headerView: some View {
        HStack {
            Text(t("ai_history_title"))
                .font(PaperFont.font(size: 20, weight: .semibold))
                .foregroundColor(Paper.ink)
            Spacer()
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Paper.inkSecondary)
                    .padding(9)
                    .background(Paper.sheet)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Paper.ink.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(Text(t("alert_cancel_button")))
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var newChatButton: some View {
        Button {
            onNewChat()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14, weight: .semibold))
                Text(t("ai_new_chat"))
                    .font(PaperFont.font(size: 14, weight: .semibold))
                Spacer()
            }
            .foregroundColor(Paper.onAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Paper.accentFill)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Paper.inkSecondary)
            TextField(t("ai_history_search"), text: $query)
                .font(PaperFont.font(size: 14))
                .foregroundColor(Paper.ink)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Paper.inkSecondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .paperField(cornerRadius: 12)
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    // MARK: - Список бесед

    @ViewBuilder
    private var contentView: some View {
        let items = store.filtered(by: query)
        if store.summaries.isEmpty {
            emptyState(t("ai_history_empty"))
        } else if items.isEmpty {
            emptyState(t("ai_history_no_results"))
        } else {
            List {
                ForEach(sections(from: items)) { section in
                    Section {
                        ForEach(section.items) { chat in
                            row(chat)
                        }
                    } header: {
                        Text(section.title)
                            .font(PaperFont.font(size: 11, weight: .semibold))
                            .foregroundColor(Paper.inkSecondary)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func emptyState(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(PaperFont.font(size: 13))
                .foregroundColor(Paper.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ chat: AIChatSummary) -> some View {
        let isCurrent = chat.id == store.currentID
        return Button {
            onSelect(chat.id)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Paper.gold)
                    }
                    Text(chat.title)
                        .font(PaperFont.font(size: 14, weight: .semibold))
                        .foregroundColor(Paper.ink)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if store.isPending(chat.id) {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                if !chat.preview.isEmpty {
                    Text(chat.preview)
                        .font(PaperFont.font(size: 12))
                        .foregroundColor(Paper.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Text(relativeTime(chat.updatedAt))
                    .font(PaperFont.font(size: 10))
                    .foregroundColor(Paper.inkSecondary.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isCurrent ? accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                askDelete(chat.id)
            } label: {
                Label(t("ai_chat_delete"), systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                store.togglePin(chat.id)
            } label: {
                Label(chat.isPinned ? t("ai_chat_unpin") : t("ai_chat_pin"),
                      systemImage: chat.isPinned ? "pin.slash" : "pin")
            }
            .tint(Paper.gold)
        }
        .contextMenu {
            Button {
                askRename(chat)
            } label: {
                Label(t("ai_chat_rename"), systemImage: "pencil")
            }
            Button {
                store.togglePin(chat.id)
            } label: {
                Label(chat.isPinned ? t("ai_chat_unpin") : t("ai_chat_pin"),
                      systemImage: chat.isPinned ? "pin.slash" : "pin")
            }
            Button(role: .destructive) {
                askDelete(chat.id)
            } label: {
                Label(t("ai_chat_delete"), systemImage: "trash")
            }
        }
    }

    private func askRename(_ chat: AIChatSummary) {
        renamingID = chat.id
        renameText = chat.title
        isShowingRename = true
    }

    private func askDelete(_ id: UUID) {
        deletingID = id
        isShowingDelete = true
    }

    // MARK: - Группировка по дням

    private func sections(from items: [AIChatSummary]) -> [ChatSection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var pinned: [AIChatSummary] = []
        var todayItems: [AIChatSummary] = []
        var yesterdayItems: [AIChatSummary] = []
        var weekItems: [AIChatSummary] = []
        var olderItems: [AIChatSummary] = []

        for chat in items {
            if chat.isPinned {
                pinned.append(chat)
            } else if calendar.isDateInToday(chat.updatedAt) {
                todayItems.append(chat)
            } else if calendar.isDateInYesterday(chat.updatedAt) {
                yesterdayItems.append(chat)
            } else {
                let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: chat.updatedAt), to: today).day ?? 99
                if days <= 7 {
                    weekItems.append(chat)
                } else {
                    olderItems.append(chat)
                }
            }
        }

        var result: [ChatSection] = []
        if !pinned.isEmpty { result.append(ChatSection(id: "pinned", title: t("ai_history_pinned"), items: pinned)) }
        if !todayItems.isEmpty { result.append(ChatSection(id: "today", title: t("ai_history_today"), items: todayItems)) }
        if !yesterdayItems.isEmpty { result.append(ChatSection(id: "yesterday", title: t("ai_history_yesterday"), items: yesterdayItems)) }
        if !weekItems.isEmpty { result.append(ChatSection(id: "week", title: t("ai_history_week"), items: weekItems)) }
        if !olderItems.isEmpty { result.append(ChatSection(id: "older", title: t("ai_history_older"), items: olderItems)) }
        return result
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: language.localeCode)
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
