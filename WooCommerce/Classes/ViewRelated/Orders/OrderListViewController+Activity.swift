import Foundation

// MARK: - SearchableActivity Conformance
extension OrderListViewController: SearchableActivityConvertable {
    var activityType: String {
        return WooActivityType.orders.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("Orders", comment: "Title of the 'Orders' tab - used for spotlight indexing on iOS.")
    }

    var activityDescription: String? {
        return NSLocalizedString("From purchase to fulfillment – manage the entire order process via the app.",
                                 comment: "Description of the 'Orders' screen - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("woocommerce, orders, all orders, new order",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Orders' tab.")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }
}
