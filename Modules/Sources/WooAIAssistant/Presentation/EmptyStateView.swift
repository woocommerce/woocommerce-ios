import SwiftUI

struct EmptyStateView: View {

    let suggestions: [SuggestionItem]
    let onPick: (String) -> Void

    init(suggestions: [SuggestionItem] = EmptyStateView.defaultSuggestions,
         onPick: @escaping (String) -> Void) {
        self.suggestions = suggestions
        self.onPick = onPick
    }

    struct SuggestionItem: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
    }

    private static let symbolWidth: CGFloat = 20
    private static let dividerLeadingInset: CGFloat = AssistantSpacing.large + symbolWidth + AssistantSpacing.medium

    var body: some View {
        VStack(alignment: .leading, spacing: AssistantSpacing.medium) {
            Text(Localization.title)
                .font(.assistantTitle)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, AssistantSpacing.large)
                .padding(.top, AssistantSpacing.large)

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
            .background(Color.assistantSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AssistantRadius.medium)
                    .stroke(Color.assistantSurfaceBorder, lineWidth: 1)
            )
            .padding(.horizontal, AssistantSpacing.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, AssistantSpacing.large)
    }

    static let defaultSuggestions: [SuggestionItem] = [
        SuggestionItem(symbol: "chart.bar.fill", title: Localization.suggestionTodaysSales),
        SuggestionItem(symbol: "shippingbox.fill", title: Localization.suggestionLowStock),
        SuggestionItem(symbol: "bag.fill", title: Localization.suggestionRecentOrders),
        SuggestionItem(symbol: "star.fill", title: Localization.suggestionTopProducts)
    ]

    private enum Localization {
        static let title = NSLocalizedString(
            "assistantChat.empty.title",
            value: "Ask about your store",
            comment: "Empty state title for the AI Assistant chat"
        )
        static let suggestionTodaysSales = NSLocalizedString(
            "assistantChat.empty.suggestion.todaysSales",
            value: "Today's sales",
            comment: "Suggested prompt asking the assistant to summarise today's sales"
        )
        static let suggestionLowStock = NSLocalizedString(
            "assistantChat.empty.suggestion.lowStock",
            value: "Low-stock items",
            comment: "Suggested prompt asking the assistant for low-stock products"
        )
        static let suggestionRecentOrders = NSLocalizedString(
            "assistantChat.empty.suggestion.recentOrders",
            value: "Recent orders",
            comment: "Suggested prompt asking the assistant to list recent orders"
        )
        static let suggestionTopProducts = NSLocalizedString(
            "assistantChat.empty.suggestion.topProducts",
            value: "Top products this week",
            comment: "Suggested prompt asking the assistant for the top-selling products this week"
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
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.assistantTextFaint)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, AssistantSpacing.large)
            .padding(.vertical, AssistantSpacing.small + 2)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Empty (in chat)") {
    AssistantChatView.preview(.empty)
}

#Preview("Standalone") {
    EmptyStateView { _ in }
        .background(Color.assistantSurface)
}
#endif
