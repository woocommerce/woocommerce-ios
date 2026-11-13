import UIKit

extension UIWindow {
    /// Returns the view controller at the top of the view hierarchy.
    @objc public var topmostPresentedViewController: UIViewController? {
        return rootViewController?.topmostPresentedViewController
    }

    /// Returns the deepest presented view controller that is on screen and not being dismissed.
    @objc public var topmostVisiblePresenter: UIViewController? {
        return rootViewController?.topmostVisiblePresenter
    }
}
