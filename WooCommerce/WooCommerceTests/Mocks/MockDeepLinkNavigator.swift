import Foundation
@testable import WooCommerce

final class MockDeepLinkNavigator: DeepLinkNavigator {
    var spyDidNavigate = false
    var spyNavigatedDestination: (any DeepLinkDestinationProtocol)? = nil

    func navigate(to destination: any DeepLinkDestinationProtocol) {
        spyDidNavigate = true
        spyNavigatedDestination = destination
    }
}
