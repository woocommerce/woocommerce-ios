import UIKit
import WordPressShared
import WordPressUI


public class LoginNavigationController: RotationAwareNavigationViewController {

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // By default, the back button label uses the previous view's title.
        // To override that, reset the label when pushing a new view controller.
        self.viewControllers.last?.navigationItem.backBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back", comment: "Back button title."), style: .plain, target: nil, action: nil)
        
        super.pushViewController(viewController, animated: animated)
    }

}
