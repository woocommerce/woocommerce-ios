import Foundation

enum OrderListLocalization {
    static let allOrdersHeaderTitle = NSLocalizedString(
        "orderList.header.allOrders.title",
        value: "All Orders",
        comment: "Header title on the Orders list when no filters are applied."
    )

    static let filteredOrdersHeaderTitle = NSLocalizedString(
        "orderList.header.filteredOrders.title",
        value: "Filtered Orders",
        comment: "Header title on the Orders list when one or more filters are applied."
    )

    static let filterButtonTitle = NSLocalizedString(
        "orderList.header.filter.button",
        value: "Filter",
        comment: "Title of the button that opens order filters when no filters are applied."
    )

    private static let filterButtonWithCountFormat = NSLocalizedString(
        "orderList.header.filter.button.withCount",
        value: "Filter (%1$ld)",
        comment: "Title of the button that opens order filters. %1$ld is the number of active filters."
    )

    private static let lastUpdatedFormat = NSLocalizedString(
        "orderList.header.lastUpdated",
        value: "Last Updated: %1$@",
        comment: "Time when the orders were last updated. %1$@ is a localized time or date and time."
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

    static let errorAccessibilityStatus = NSLocalizedString(
        "orderList.error.banner.accessibilityStatus",
        value: "Error",
        comment: "Accessibility status announced for an error banner on the Orders list."
    )

    static let warningAccessibilityStatus = NSLocalizedString(
        "orderList.warning.banner.accessibilityStatus",
        value: "Warning",
        comment: "Accessibility status announced for a warning banner on the Orders list."
    )

    static func filterButtonTitle(activeFilterCount: Int) -> String {
        guard activeFilterCount > 0 else {
            return filterButtonTitle
        }
        return String.localizedStringWithFormat(filterButtonWithCountFormat, activeFilterCount)
    }

    static func lastUpdatedText(time: String) -> String {
        String.localizedStringWithFormat(lastUpdatedFormat, time)
    }
}
