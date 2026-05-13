import SwiftUI

struct EmptyStateView: View {

    let onPick: (String) -> Void
    var onFeedbackTap: (() -> Void)? = nil
    let siteID: Int64

    @AppStorage private var hasDismissedEarlyAccessNotice: Bool

    private let suggestions: [SuggestionItem] = EmptyStateView.defaultSuggestions

    init(onPick: @escaping (String) -> Void,
         onFeedbackTap: (() -> Void)? = nil,
         siteID: Int64) {
        self.onPick = onPick
        self.onFeedbackTap = onFeedbackTap
        self.siteID = siteID
        self._hasDismissedEarlyAccessNotice = AppStorage(
            wrappedValue: false,
            "hasDismissedWooAIAssistantEarlyAccessTooltip-\(siteID)"
        )
    }

    struct SuggestionItem: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
    }

    private static let symbolWidth: CGFloat = 20
    private static let dividerLeadingInset: CGFloat = AssistantSpacing.large + symbolWidth + AssistantSpacing.medium

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AssistantSpacing.medium) {
                if let onFeedbackTap, !hasDismissedEarlyAccessNotice {
                    AssistantEarlyAccessNoticeCard(
                        onFeedbackTap: onFeedbackTap,
                        onDismiss: { hasDismissedEarlyAccessNotice = true }
                    )
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
                                          onTap: { onPick(item.title) })
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

    private static let defaultSuggestions: [SuggestionItem] = [
        SuggestionItem(symbol: "chart.bar", title: Localization.suggestionRevenueWeek),
        SuggestionItem(symbol: "tag", title: Localization.suggestionOutOfStock),
        SuggestionItem(symbol: "list.bullet.rectangle.portrait", title: Localization.suggestionRecentOrders),
        SuggestionItem(symbol: "person.2", title: Localization.suggestionNewCustomers)
    ]

    private enum Localization {
        static let title = NSLocalizedString(
            "assistantChat.empty.title",
            value: "Ask about your store",
            comment: "Empty state title for the AI Assistant chat"
        )
        static let suggestionRevenueWeek = NSLocalizedString(
            "assistantChat.empty.suggestion.revenueWeek",
            value: "Revenue this week",
            comment: "Suggested prompt asking the assistant for this week's revenue"
        )
        static let suggestionOutOfStock = NSLocalizedString(
            "assistantChat.empty.suggestion.outOfStock",
            value: "Out-of-stock items",
            comment: "Suggested prompt asking the assistant for products that are out of stock"
        )
        static let suggestionRecentOrders = NSLocalizedString(
            "assistantChat.empty.suggestion.recentOrders",
            value: "Recent orders",
            comment: "Suggested prompt asking the assistant to list recent orders"
        )
        static let suggestionNewCustomers = NSLocalizedString(
            "assistantChat.empty.suggestion.newCustomers",
            value: "New customers",
            comment: "Suggested prompt asking the assistant to list the most recently registered customers"
        )
    }
}

private struct SuggestionRow: View {

    let item: EmptyStateView.SuggestionItem
    let symbolWidth: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
    EmptyStateView(onPick: { _ in }, siteID: 0)
        .background(Color.assistantSurface)
}
#endif
