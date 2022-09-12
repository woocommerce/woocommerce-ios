@testable import WooCommerce
import WordPressAuthenticator
import WordPressKit

final class MockAuthentication: Authentication {
    private(set) var presentSupportFromScreenInvoked = false

    func presentSupport(from sourceViewController: UIViewController, screen: CustomHelpCenterContent.Screen) {
        presentSupportFromScreenInvoked = true
    }

    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        // no-op
    }

    func handleAuthenticationUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool {
        true
    }

    func authenticationUI() -> UIViewController {
        UIViewController()
    }

    func initialize() {
        // no-op
    }

    func setLoggedOutAppSettings(_ settings: LoggedOutAppSettingsProtocol) {
        // no-op
    }

    func errorViewController(for siteURL: String,
                             with matcher: ULAccountMatcher,
                             credentials: AuthenticatorCredentials?,
                             navigationController: UINavigationController,
                             onStorePickerDismiss: @escaping () -> Void) -> UIViewController? {
        nil
    }
}
