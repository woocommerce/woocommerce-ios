import UIKit
import WordPressShared
import WordPressUI


public class LoginNavigationController: RotationAwareNavigationViewController {
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.style.statusBarStyle
    }
}
