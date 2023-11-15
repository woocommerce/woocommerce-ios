import Foundation

/// Links supported URLs with a /payments root path to various destinations in the Payments Hub Menu
/// 
struct PaymentsRoute: Route {
    private let deepLinkNavigator: DeepLinkNavigator

    init(deepLinkNavigator: DeepLinkNavigator) {
        self.deepLinkNavigator = deepLinkNavigator
    }

    func canHandle(subPath: String) -> Bool {
        return HubMenuViewController.DeepLinkDestination(paymentsDeepLinkSubPath: subPath) != nil
    }

    func perform(for subPath: String, with parameters: [String: String]) -> Bool {
        guard let destination = HubMenuViewController.DeepLinkDestination(paymentsDeepLinkSubPath: subPath) else {
            return false
        }

        deepLinkNavigator.navigate(to: destination)

        return true
    }
}

private extension HubMenuViewController.DeepLinkDestination {
    init?(paymentsDeepLinkSubPath: String) {
        guard paymentsDeepLinkSubPath.hasPrefix(Constants.paymentsRoot) else {
            return nil
        }

        let destinationSubPath = paymentsDeepLinkSubPath
            .removingPrefix(Constants.paymentsRoot)
            .removingPrefix("/")

        switch destinationSubPath {
        case "":
            self = .paymentsMenu
        case "collect-payment":
            self = .simplePayments
        case "tap-to-pay":
            self = .tapToPayOnIPhone
        default:
            return nil
        }
    }

    enum Constants {
        static let paymentsRoot = "payments"
    }
}
