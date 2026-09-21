import SwiftUI

struct EmptyStateView: View {

    let onPick: (String) -> Void
    var onFeedbackTap: (() -> Void)? = nil

    private let suggestions: [SuggestionItem] = EmptyStateView.defaultSuggestions

    init(onPick: @escaping (String) -> Void,
         onFeedbackTap: (() -> Void)? = nil) {
        self.onPick = onPick
        self.onFeedbackTap = onFeedbackTap
    }

    struct SuggestionItem: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let prompt: String
    }

    static let defaultSuggestions: [SuggestionItem] = [
        SuggestionItem(symbol: "chart.bar",
                       title: Localization.suggestionRevenueWeek,
                       prompt: Localization.promptRevenueWeek),
        SuggestionItem(symbol: "tag",
                       title: Localization.suggestionOutOfStock,
                       prompt: Localization.promptOutOfStock),
        SuggestionItem(symbol: "list.bullet.rectangle.portrait",
                       title: Localization.suggestionRecentOrders,
                       prompt: Localization.promptRecentOrders),
        SuggestionItem(symbol: "person.2",
                       title: Localization.suggestionNewCustomers,
                       prompt: Localization.promptNewCustomers)
    ]

    private static let symbolWidth: CGFloat = 20
    private static let dividerLeadingInset: CGFloat = AssistantSpacing.large + symbolWidth + AssistantSpacing.medium

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AssistantSpacing.medium) {
                if let onFeedbackTap {
                    AssistantEarlyAccessNoticeCard(onFeedbackTap: onFeedbackTap)
                        .padding(.horizontal, AssistantSpacing.large)
                        .padding(.top, AssistantSpacing.large)
                }

                Text(Localization.title)
                    .font(.assistantTitle)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, AssistantSpacing.large)
                    .padding(.top, AssistantSpacing.xxLarge)

                AssistantDashboardCardShell(
                    title: nil,
                    padBody: false
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, item in
                            SuggestionRow(item: item,
                                          symbolWidth: Self.symbolWidth,
                                          onPick: onPick)
                            if index < suggestions.count - 1 {
                                Rectangle()
                                    .fill(Color.assistantSeparator.opacity(0.4))
                                    .frame(height: 0.5)
                                    .padding(.leading, Self.dividerLeadingInset)
                            }
                        }
                    }
                }
                .padding(.horizontal, AssistantSpacing.large)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, AssistantSpacing.large)
        }
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistantChat.empty.title.v2",
            value: "What can I help with?",
            comment: "Empty state title for the AI Assistant chat"
        )
        static let suggestionRevenueWeek = NSLocalizedString(
            "assistantChat.empty.suggestion.revenueWeek.v2",
            value: "How's revenue this week?",
            comment: "Suggested prompt chip asking the assistant for this week's revenue"
        )
        static let suggestionOutOfStock = NSLocalizedString(
            "assistantChat.empty.suggestion.outOfStock.v2",
            value: "What's running low?",
            comment: "Suggested prompt chip asking the assistant for products that are out of stock"
        )
        static let suggestionRecentOrders = NSLocalizedString(
            "assistantChat.empty.suggestion.recentOrders.v2",
            value: "Any orders need my attention?",
            comment: "Suggested prompt chip asking the assistant to list recent orders"
        )
        static let suggestionNewCustomers = NSLocalizedString(
            "assistantChat.empty.suggestion.newestCustomers.v1",
            value: "Who are my newest customers?",
            comment: "Suggested prompt chip asking the assistant to list the newest customers"
        )
        static let promptRevenueWeek = NSLocalizedString(
            "assistantChat.empty.prompt.revenueWeek",
            value: "How's my revenue this week? Show me total sales for this week and how it compares to last week.",
            comment: "Full prompt sent to the assistant when the revenue suggestion chip is tapped"
        )
        static let promptOutOfStock = NSLocalizedString(
            "assistantChat.empty.prompt.outOfStock",
            value: "What's running low? List the products that are out of stock or low on inventory so I know what to restock.",
            comment: "Full prompt sent to the assistant when the out-of-stock suggestion chip is tapped"
        )
        static let promptRecentOrders = NSLocalizedString(
            "assistantChat.empty.prompt.recentOrders",
            value: "Any orders that need my attention? Show me recent orders that are pending, on hold, or processing.",
            comment: "Full prompt sent to the assistant when the recent-orders suggestion chip is tapped"
        )
        static let promptNewCustomers = NSLocalizedString(
            "assistantChat.empty.prompt.newestCustomers.v1",
            value: "Show my newest customers. List up to 10 customers sorted by registration date, newest first.",
            comment: "Full prompt sent to the assistant when the newest-customers suggestion chip is tapped"
        )
    }
}

private struct SuggestionRow: View {

    let item: EmptyStateView.SuggestionItem
    let symbolWidth: CGFloat
    let onPick: (String) -> Void

    var body: some View {
        Button(action: { onPick(item.prompt) }) {
            HStack(spacing: AssistantSpacing.medium) {
                Image(systemName: item.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.accent))
                    .frame(width: symbolWidth, height: symbolWidth)
                    .accessibilityHidden(true)
                Text(item.title)
                    .font(.assistantBody)
                    .foregroundStyle(Color.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AssistantSpacing.large)
            .padding(.vertical, AssistantSpacing.medium)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(AssistantPressableButtonStyle())
    }
}

#if DEBUG
#Preview("Empty (in chat)") {
    AssistantChatView.preview(.empty)
}

#Preview("Standalone") {
    EmptyStateView(onPick: { _ in })
        .background(Color.assistantSurface)
}
#endif
