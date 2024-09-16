import Foundation

/// Links supported URLs with an /orders root path to various destinations in the Payments Hub Menu
///
struct OrdersRoute: Route {
    private let deepLinkNavigator: DeepLinkNavigator

    init(deepLinkNavigator: DeepLinkNavigator) {
        self.deepLinkNavigator = deepLinkNavigator
    }

    func canHandle(subPath: String) -> Bool {
        return deepLinkDestination(for: subPath) != nil
    }

    func perform(for subPath: String, with parameters: [String: String]) -> Bool {
        guard let destination = deepLinkDestination(for: subPath) else {
            return false
        }

        deepLinkNavigator.navigate(to: destination)

        return true
    }
}

private extension OrdersRoute {
    func deepLinkDestination(for ordersDeepLinkSubPath: String) -> (any DeepLinkDestinationProtocol)? {
        guard ordersDeepLinkSubPath.hasPrefix(Constants.ordersRoot) else {
            return nil
        }

        let destinationSubPath = ordersDeepLinkSubPath
            .removingPrefix(Constants.ordersRoot)
            .removingPrefix("/")

        switch destinationSubPath {
        case "":
            return OrdersDestination.orderList
        case "create":
            return OrdersDestination.createOrder
        default:
            return nil
        }
    }

    enum Constants {
        static let ordersRoot = "orders"
    }
}
