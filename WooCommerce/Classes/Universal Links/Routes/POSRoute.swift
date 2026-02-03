import Foundation

/// Links supported URLs with a /pos root path to POS-related destinations.
///
/// Example URL: `https://woocommerce.com/mobile/pos/learn-more`
///
struct POSRoute: Route {
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

private extension POSRoute {
    func deepLinkDestination(for posDeepLinkSubPath: String) -> (any DeepLinkDestinationProtocol)? {
        guard posDeepLinkSubPath.hasPrefix(Constants.posRoot) else {
            return nil
        }

        let destinationSubPath = posDeepLinkSubPath
            .removingPrefix(Constants.posRoot)
            .removingPrefix("/")

        switch destinationSubPath {
        case "learn-more":
            return POSPromotionDestination.learnMore
        default:
            return nil
        }
    }

    enum Constants {
        static let posRoot = "pos"
    }
}
