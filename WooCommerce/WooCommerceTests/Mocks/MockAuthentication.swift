@testable import WooCommerce
import WordPressAuthenticator
import WordPressKit

final class MockAuthentication: Authentication {
    private(set) var presentSupportFromScreenInvoked = false
    private(set) var presentSupportFromScreen: CustomHelpCenterContent.Screen?

    func presentSupport(from sourceViewController: UIViewController, screen: CustomHelpCenterContent.Screen) {
        presentSupportFromScreenInvoked = true
        presentSupportFromScreen = screen
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

    func initialize(loggedOutAppSettings: LoggedOutAppSettingsProtocol) {
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
