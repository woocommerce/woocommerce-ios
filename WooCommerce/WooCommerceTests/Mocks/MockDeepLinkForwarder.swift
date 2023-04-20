import Foundation
@testable import WooCommerce

final class MockDeepLinkForwarder: DeepLinkForwarder {
    var spyDidForwardHubMenuDeepLink = false
    var spyForwardedHubMenuDeepLink: HubMenuCoordinator.DeepLinkDestination? = nil

    func forwardHubMenuDeepLink(to destination: HubMenuCoordinator.DeepLinkDestination) {
        spyDidForwardHubMenuDeepLink = true
        spyForwardedHubMenuDeepLink = destination
    }
}
