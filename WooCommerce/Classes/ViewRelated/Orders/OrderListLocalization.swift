import Foundation

enum OrderListLocalization {
    static let allOrders = NSLocalizedString(
        "orderList.browsingRow.allOrders",
        value: "All Orders",
        comment: "Header bar label on top of order list when no filters are applied"
    )
    static let filteredOrders = NSLocalizedString(
        "orderList.browsingRow.filteredOrders",
        value: "Filtered Orders",
        comment: "Header bar label on top of order list when filters are applied"
    )
    static let filter = NSLocalizedString(
        "orderList.filterButton.title",
        value: "Filter",
        comment: "Title of the toolbar button to filter orders without filters applied."
    )
    static let filterWithCount = NSLocalizedString(
        "orderList.filterButton.titleWithCount",
        value: "Filter (%1$ld)",
        comment: "Title of the toolbar button to filter orders with filters applied."
    )
    static let allOrdersEmptyStateMessage = NSLocalizedString(
        "orderList.emptyState.title",
        value: "Waiting for your first order",
        comment: "The message shown in the Orders → All Orders tab if the list is empty."
    )
    static let allOrdersEmptyStateDetail = NSLocalizedString(
        "orderList.emptyState.description",
        value: "Explore how you can increase your store sales.",
        comment: "The detailed message shown in the Orders → All Orders tab if the list is empty."
    )
    static let learnMore = NSLocalizedString(
        "orderList.emptyState.learnMoreButton.title",
        value: "Learn more",
        comment: "Title of button shown in the Orders → All Orders tab if the list is empty."
    )
    static let filteredOrdersEmptyStateMessage = NSLocalizedString(
        "orderList.filteredEmptyState.title",
        value: "We're sorry, we couldn't find any order that match %1$@",
        comment: "Message for empty Orders filtered results. The %1$@ is a placeholder for the filters entered by the user."
    )
    static let clearFilters = NSLocalizedString(
        "orderList.filteredEmptyState.clearFiltersButton.title",
        value: "Clear Filters",
        comment: "Action to remove filters orders on the placeholder overlay when no orders match the filter on the Order List"
    )
    static let markCompleted = NSLocalizedString(
        "orderList.swipeAction.markCompleted",
        value: "Mark Completed",
        comment: "Title for the swipe order action to mark it as completed"
    )
    static let currencyUnavailableTitle = NSLocalizedString(
        "orderList.currencyUnavailable.banner.title",
        value: "Store currency unavailable",
        comment: "Title of the banner shown on the Orders list when the store's currency couldn't be loaded."
    )
    static let currencyUnavailableInfo = NSLocalizedString(
        "orderList.currencyUnavailable.banner.info",
        value: "We couldn't load your store's currency, so order totals may be shown in the wrong currency.",
        comment: "Message of the banner shown on the Orders list when the store's currency couldn't be loaded."
    )
    static let currencyUnavailableRetry = NSLocalizedString(
        "orderList.currencyUnavailable.banner.retry",
        value: "Retry",
        comment: "Title of the button to retry loading the store's currency on the Orders list warning banner."
    )

    static func filterTitle(count: Int) -> String {
        guard count > 0 else { return filter }
        return String.localizedStringWithFormat(filterWithCount, count)
    }

    static func lastUpdated(time: String) -> String {
        let format = NSLocalizedString(
            "orderList.browsingRow.lastUpdated",
            value: "Last Updated: %1$@",
            comment: "Time for when the orders were last updated"
        )
        return String.localizedStringWithFormat(format, time)
    }

    static func markCompletedNoticeTitle(orderID: Int64) -> String {
        let format = NSLocalizedString(
            "orderList.markCompletedNotice.success.title",
            value: "Order #%1$d marked as completed",
            comment: "Notice title when an order is marked as completed via a swipe action. Parameter: Order Number"
        )
        return String.localizedStringWithFormat(format, orderID)
    }

    static func markCompletedErrorNoticeTitle(orderID: Int64) -> String {
        let format = NSLocalizedString(
            "orderList.markCompletedNotice.error.title",
            value: "Error updating Order #%1$d",
            comment: "Notice title when marking an order as completed via a swipe action fails. Parameter: Order Number"
        )
        return String.localizedStringWithFormat(format, orderID)
    }
}
