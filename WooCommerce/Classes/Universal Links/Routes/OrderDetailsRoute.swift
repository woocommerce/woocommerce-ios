import Foundation

/// Shows order details from a given universal link that matches the right path
///
struct OrderDetailsRoute: Route {
    let path = "/orders/details"

    func perform(with parameters: [String: String]) {
        DDLogInfo("We received an order details universal link with parameters: \(parameters)")
    }
}
