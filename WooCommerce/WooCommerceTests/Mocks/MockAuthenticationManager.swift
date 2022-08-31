@testable import WooCommerce
import WordPressAuthenticator

final class MockAuthenticationManager: Authentication {
    private(set) var authenticationUIInvoked = false
    private(set) var presentSupportInvoked = false

    func authenticationUI() -> UIViewController {
        authenticationUIInvoked = true
        return UIViewController()
    }

    func presentSupport(from sourceViewController: UIViewController, screen: CustomHelpCenterContent.Screen) {
        presentSupportInvoked = true
    }

    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        // no-op
    }

    func handleAuthenticationUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool {
        true
    }

    func initialize() {
        // no-op
    }

    func setLoggedOutAppSettings(_ settings: LoggedOutAppSettingsProtocol) {
        // no-op
    }

    func errorViewController(for siteURL: String,
                             with matcher: ULAccountMatcher,
                             navigationController: UINavigationController,
                             onStorePickerDismiss: @escaping () -> Void) -> UIViewController? {
        nil
    }
}
