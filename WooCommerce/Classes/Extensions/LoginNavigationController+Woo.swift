import UIKit
import WordPressAuthenticator

extension LoginNavigationController {

    /// TODO: Create a property in Authenticator then delete this
    /// https://github.com/wordpress-mobile/WordPressAuthenticator-iOS/issues/26
    ///
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return StyleManager.statusBarLight
    }
}
