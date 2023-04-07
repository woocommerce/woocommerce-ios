import Foundation
import Yosemite

/// Shows order details from a given universal link that matches the right path
///
struct OrderDetailsRoute: Route {
    private let subPath: String = "orders/details"

    func canHandle(subPath: String) -> Bool {
        return subPath == self.subPath
    }

    func perform(for subPath: String, with parameters: [String: String]) -> Bool {
        guard let storeIdString = parameters[ParametersKeys.blogId],
              let storeId = Int64(storeIdString),
              let orderIdString = parameters[ParametersKeys.orderId],
              let orderId = Int64(orderIdString) else {
            DDLogError("Error: we receive an universal link for order details but parameters couldn't be parsed.")

            return false
        }

        MainTabBarController.navigateToOrderDetails(with: orderId, siteID: storeId)

        return true
    }
}

private extension OrderDetailsRoute {
    enum ParametersKeys {
        static let blogId = "blog_id"
        static let orderId = "order_id"
    }
}
