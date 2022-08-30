import Foundation
import Yosemite

/// Shows order details from a given universal link that matches the right path
///
struct OrderDetailsRoute: Route {
    let path = "/orders/details"

    func perform(with parameters: [String: String]) {
        guard let storeIdString = parameters[ParametersKeys.blogId],
              let storeId = Int64(storeIdString),
              let orderIdString = parameters[ParametersKeys.orderId],
              let orderId = Int64(orderIdString) else {
            return
        }

        MainTabBarController.presentOrderDetails(with: orderId, siteID: storeId)
    }
}

private extension OrderDetailsRoute {
    enum ParametersKeys {
        static let blogId = "blog_id"
        static let orderId = "order_id"
    }
}
