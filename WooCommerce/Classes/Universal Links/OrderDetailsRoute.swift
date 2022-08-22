import Foundation

struct OrderDetailsRoute: Route {
    let path = "/orders/details"
    let action: NavigationAction = OrderDetailsNavigationAction()
}

struct OrderDetailsNavigationAction: NavigationAction {
    func perform(with parameters: [String: String]) {
        DDLogInfo("We received an order details universal link with parameters: \(parameters)")
    }
}
