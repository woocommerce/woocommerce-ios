import Foundation
import Experiments /// Remove when `.tapToPayOnIPhoneMilestone2` is removed

/// Links supported URLs with a /payments root path to various destinations in the Payments Hub Menu
/// 
struct PaymentsRoute: Route {
    private let deepLinkForwarder: DeepLinkForwarder
    private let featureFlagService: FeatureFlagService // Temporary for testing with `tapToPayOnIPhoneMilestone2` enabled

    init(deepLinkForwarder: DeepLinkForwarder, featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.deepLinkForwarder = deepLinkForwarder
        self.featureFlagService = featureFlagService
    }

    func canHandle(subPath: String) -> Bool {
        return HubMenuCoordinator.DeepLinkDestination(paymentsDeepLinkSubPath: subPath, featureFlagService: featureFlagService) != nil
    }

    func perform(for subPath: String, with parameters: [String: String]) -> Bool {
        guard let destination = HubMenuCoordinator.DeepLinkDestination(paymentsDeepLinkSubPath: subPath, featureFlagService: featureFlagService) else {
            return false
        }

        deepLinkForwarder.forwardHubMenuDeepLink(to: destination)

        return true
    }
}

private extension HubMenuCoordinator.DeepLinkDestination {
    init?(paymentsDeepLinkSubPath: String, featureFlagService: FeatureFlagService) {
        guard paymentsDeepLinkSubPath.hasPrefix(Constants.paymentsRoot) else {
            return nil
        }

        let destinationSubPath = paymentsDeepLinkSubPath
            .removingPrefix(Constants.paymentsRoot)
            .removingPrefix("/")

        /// Before Tap to Pay Milestone 2, we only support deeplinks directly to the Payments menu root
        guard featureFlagService.isFeatureFlagEnabled(.tapToPayOnIPhoneMilestone2) else {
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
        static let paymentsRoot = "payments"
    }
}
