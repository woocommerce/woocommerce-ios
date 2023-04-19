import Foundation

protocol DeepLinkForwarder {
    func forwardHubMenuDeepLink(to destination: HubMenuCoordinator.DeepLinkDestination)
}
