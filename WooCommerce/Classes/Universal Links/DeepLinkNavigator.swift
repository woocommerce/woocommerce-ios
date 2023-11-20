import Foundation

protocol DeepLinkNavigator {
    func navigate(to destination: any DeepLinkDestinationProtocol)
}

protocol DeepLinkDestinationProtocol: Equatable {}
