import Foundation
import UIKit


/// UIViewController Helpers
///
extension UIViewController {

    /// Returns the default nibName: Matches the classname (expressed as a String!)
    ///
    class var nibName: String {
        return classNameWithoutNamespaces
    }

    /// Removes the text of the navigation bar back button in the next view controller of the navigation stack.
    ///
    func removeNavigationBackBarButtonText() {
        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .minimal
        } else {
            navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
        }
    }

    /// Show the X close button or a custom close button with title on the left bar button item position
    ///
    func addCloseNavigationBarButton(title: String? = nil, target: Any? = nil, action: Selector? = #selector(dismissVC)) {
        /// We can't make self the default value for the `target` parameter without a warning being added.
        /// The compiler-recommended fix for the warning causes a crash when the button is tapped.
        let targetOrSelf = target ?? self
        if let title = title {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: targetOrSelf, action: action)
        }
        else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: .closeButton, style: .plain, target: targetOrSelf, action: action)
            navigationItem.leftBarButtonItem?.accessibilityLabel = Localization.close
        }
    }

}

/// Private methods
///
private extension UIViewController {

    /// Dismiss method
    ///
    @objc func dismissVC() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Constants
private extension UIViewController {
    enum Localization {
        static let close = NSLocalizedString("Close", comment: "Accessibility label for the close button")
    }
}
