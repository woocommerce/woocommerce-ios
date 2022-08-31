@testable import WooCommerce
import UIKit

final class MockAuthenticationManager: AuthenticationManager {
    private(set) var authenticationUIInvoked: Bool = false

    override func authenticationUI() -> UIViewController {
        authenticationUIInvoked = true
        return UIViewController()
    }
}
