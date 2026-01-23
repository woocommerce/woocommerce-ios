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
        navigationItem.backButtonDisplayMode = .minimal
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

    /// Shows a transparent navigation bar without a bottom border.
    ///
    func configureTransparentNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
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
        static let close = NSLocalizedString("Close", comment: "This text appears as a button label used to dismiss or close modal screens and dialogs throughout the app, including screens like the coupon creation success view and Jetpack installation flow. It provides users with a way to exit or return to the previous screen without performing any additional actions.")
    }
}
