import Foundation

struct PointOfSaleOrderListEmptyViewModel: POSEmptyViewModelProtocol {
    let isSearching: Bool

    var title: String {
        isSearching ? Localization.emptyOrdersSearchTitle : Localization.emptyOrdersTitle
    }

    var subtitle: String {
        isSearching ? Localization.emptyOrdersSearchSubtitle : Localization.emptyOrdersSubtitle
    }

    var hint: String? {
        isSearching ? Localization.emptyOrdersSearchHint : nil
    }

    var buttonTitle: String? {
        isSearching ? nil : Localization.emptyOrdersButtonTitle
    }

    var iconName: String {
        PointOfSaleAssets.magnifierNotFound.imageName
    }
}

private enum Localization {
    static let emptyOrdersTitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersTitle",
        value: "No orders yet",
        comment: "Title appearing when there are no orders to display."
    )

    static let emptyOrdersSubtitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersSubtitle",
        value: "Orders will appear here once you start processing sales.",
        comment: "Subtitle appearing when there are no orders to display."
    )

    static let emptyOrdersButtonTitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersButtonTitle",
        value: "Refresh",
        comment: "Button text for refreshing orders when list is empty."
    )

    static let emptyOrdersSearchTitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersSearchTitle",
        value: "No orders found",
        comment: "Title appearing when order search returns no results."
    )

    static let emptyOrdersSearchSubtitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersSearchSubtitle",
        value: "We couldn't find any orders matching your search.",
        comment: "Subtitle appearing when order search returns no results."
    )

    static let emptyOrdersSearchHint = NSLocalizedString(
        "pos.orderListView.emptyOrdersSearchHint",
        value: "Try adjusting your search term.",
        comment: "Hint text suggesting to modify search terms when no orders are found."
    )
}
