import Foundation

/// Links an URL with a /payments path to the Payments Hub Menu
/// 
struct PaymentsRoute: Route {
    private let tabBarController: MainTabBarController

    init(tabBarController: MainTabBarController) {
        self.tabBarController = tabBarController
    }

    func canHandle(subPath: String) -> Bool {
        return HubMenuCoordinator.DeepLinkDestination(paymentsDeepLinkSubPath: subPath) != nil
    }

    func perform(for subPath: String, with parameters: [String: String]) -> Bool {
        guard let destination = HubMenuCoordinator.DeepLinkDestination(paymentsDeepLinkSubPath: subPath) else {
            return false
        }

        tabBarController.forwardHubMenuDeeplink(to: destination)

        return true
    }
}

private extension HubMenuCoordinator.DeepLinkDestination {
    init?(paymentsDeepLinkSubPath: String) {
        guard paymentsDeepLinkSubPath.hasPrefix(Constants.paymentsRoot) else {
            return nil
        }

        /// We do this in two steps because we want to handle `/payments` as well as `/payments/`,
        /// and avoid leading `/` for other routes
        let destinationSubPath = paymentsDeepLinkSubPath
            .removingPrefix(Constants.paymentsRoot)
            .removingPrefix("/")

        /// Before Tap to Pay Milestone 2, we only support deeplinks directly to the Payments menu root
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.tapToPayOnIPhoneMilestone2) else {
            if destinationSubPath == "" {
                self = .paymentsMenu
                return
            } else {
                return nil
            }
        }

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
        static let paymentsRoot = "/payments"
    }
}
