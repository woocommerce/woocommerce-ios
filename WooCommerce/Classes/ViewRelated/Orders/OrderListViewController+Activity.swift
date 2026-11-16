import Foundation
import WooFoundation

private enum OrderListActivity {
    static let type = WooActivityType.orders.rawValue
    static let title = NSLocalizedString("Orders", comment: "Title of the 'Orders' tab - used for spotlight indexing on iOS.")
    static let description = NSLocalizedString("From purchase to fulfillment – manage the entire order process via the app.",
                                               comment: "Description of the 'Orders' screen - used for spotlight indexing on iOS.")
    static let keywords = NSLocalizedString("woocommerce, orders, all orders, new order",
                                            comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Orders' tab.")
        .setOfTags()
}

// MARK: - SearchableActivity Conformance
extension OrderListViewController: @MainActor SearchableActivityConvertible {
    var activityType: String { OrderListActivity.type }
    var activityTitle: String { OrderListActivity.title }
    var activityDescription: String? { OrderListActivity.description }
    var activityKeywords: Set<String>? { OrderListActivity.keywords }
}

extension StoreOrderListHostingController: @MainActor SearchableActivityConvertible {
    var activityType: String { OrderListActivity.type }
    var activityTitle: String { OrderListActivity.title }
    var activityDescription: String? { OrderListActivity.description }
    var activityKeywords: Set<String>? { OrderListActivity.keywords }
}
