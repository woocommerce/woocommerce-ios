import UIKit
import WordPressShared
import WordPressUI


public class LoginNavigationController: RotationAwareNavigationViewController {
    override public func awakeFromNib() {
        super.awakeFromNib()

        navigationBar.barTintColor = WPStyleGuide.wordPressBlue()
    }
}
