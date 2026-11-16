import Foundation

enum OrderListLocalization {
    static let allOrders = NSLocalizedString("All Orders",
                                             comment: "Header bar label on top of order list when no filters are applied")
    static let filteredOrders = NSLocalizedString("Filtered Orders",
                                                  comment: "Header bar label on top of order list when filters are applied")
    static let filter = NSLocalizedString("Filter",
                                          comment: "Title of the toolbar button to filter orders without filters applied.")
    static let filterWithCount = NSLocalizedString("Filter (%ld)",
                                                   comment: "Title of the toolbar button to filter orders with filters applied.")
    static let allOrdersEmptyStateMessage = NSLocalizedString(
        "Waiting for your first order",
        comment: "The message shown in the Orders → All Orders tab if the list is empty."
    )
    static let allOrdersEmptyStateDetail = NSLocalizedString(
        "Explore how you can increase your store sales.",
        comment: "The detailed message shown in the Orders → All Orders tab if the list is empty."
    )
    static let learnMore = NSLocalizedString(
        "Learn more",
        comment: "Title of button shown in the Orders → All Orders tab if the list is empty."
    )
    static let filteredOrdersEmptyStateMessage = NSLocalizedString(
        "We're sorry, we couldn't find any order that match %@",
        comment: "Message for empty Orders filtered results. The %@ is a placeholder for the filters entered by the user."
    )
    static let clearFilters = NSLocalizedString(
        "Clear Filters",
        comment: "Action to remove filters orders on the placeholder overlay when no orders match the filter on the Order List"
    )
    static let markCompleted = NSLocalizedString(
        "Mark Completed",
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
        let format = NSLocalizedString("Last Updated: %@", comment: "Time for when the orders were last updated")
        return String.localizedStringWithFormat(format, time)
    }

    static func markCompletedNoticeTitle(orderID: Int64) -> String {
        let format = NSLocalizedString(
            "Order #%1$d marked as completed",
            comment: "Notice title when an order is marked as completed via a swipe action. Parameter: Order Number"
        )
        return String.localizedStringWithFormat(format, orderID)
    }

    static func markCompletedErrorNoticeTitle(orderID: Int64) -> String {
        let format = NSLocalizedString(
            "Error updating Order #%1$d",
            comment: "Notice title when marking an order as completed via a swipe action fails. Parameter: Order Number"
        )
        return String.localizedStringWithFormat(format, orderID)
    }
}
