import UIKit

extension UINavigationController {

    /// Overrides all navigation controllers to use the white status bar.
    /// If we want other navigation controllers to use the black status bar,
    /// we'll need to subclass UINavigationController and override it there.
    ///
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
