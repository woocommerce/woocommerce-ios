import Foundation
import SwiftUI

struct POSOrderListEmptyViewModel: POSListEmptyViewModelProtocol {
    let isSearching: Bool

    var title: String {
        isSearching ? Localization.emptyOrdersSearchTitle : Localization.emptyOrdersTitle
    }

    var subtitle: String {
        isSearching ? Localization.emptyOrdersSearchSubtitle : Localization.emptyOrdersSubtitle
    }

    var hint: String? {
        nil
    }

    var buttonTitle: String? {
        isSearching ? nil : Localization.emptyOrdersButtonTitle
    }

    var icon: Image {
        isSearching ? PointOfSaleAssets.magnifierNotFound.decorativeImage : PointOfSaleAssets.noOrders.decorativeImage
    }
}

private enum Localization {
    static let emptyOrdersTitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersTitle",
        value: "No orders yet",
        comment: "Title appearing when there are no orders to display."
    )

    static let emptyOrdersSubtitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersSubtitle2",
        value: "Explore how you can increase your store sales.",
        comment: "Subtitle appearing when there are no orders to display."
    )

    static let emptyOrdersButtonTitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersButtonTitle2",
        value: "Learn more",
        comment: "Button text for opening an information view when orders when list is empty."
    )

    static let emptyOrdersSearchTitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersSearchTitle",
        value: "No orders found",
        comment: "Title appearing when order search returns no results."
    )

    static let emptyOrdersSearchSubtitle = NSLocalizedString(
        "pos.orderListView.emptyOrdersSearchSubtitle.2",
        value: "We couldn't find any orders with that name. Try adjusting your search term.",
        comment: "Subtitle appearing when order search returns no results."
    )
}
