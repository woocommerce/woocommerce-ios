import Foundation

/// Links supported URLs with a /payments root path to various destinations in the Payments Hub Menu
///
struct PaymentsRoute: Route {
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

private extension PaymentsRoute {
    func deepLinkDestination(for paymentsDeepLinkSubPath: String) -> (any DeepLinkDestinationProtocol)? {
        guard paymentsDeepLinkSubPath.hasPrefix(Constants.paymentsRoot) else {
            return nil
        }

        let destinationSubPath = paymentsDeepLinkSubPath
            .removingPrefix(Constants.paymentsRoot)
            .removingPrefix("/")

        switch destinationSubPath {
        case "":
            return HubMenuDestination.paymentsMenu
        case "collect-payment":
            return PaymentsMenuDestination.collectPayment
        case "tap-to-pay":
            return PaymentsMenuDestination.tapToPay
        default:
            return nil
        }
    }

    enum Constants {
        static let paymentsRoot = "payments"
    }
}
