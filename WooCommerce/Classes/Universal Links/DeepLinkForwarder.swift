import Foundation

protocol DeepLinkNavigator {
    func navigate(to destination: DeepLinkDestinationProtocol)
}

protocol DeepLinkDestinationProtocol {}
