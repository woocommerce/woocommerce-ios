import Foundation
import UIKit


// MARK: - UINavigationController: Woo Extensions
//
extension UINavigationController {

    /// Whenever there's a single viewController onscreen, this method will set the "Top" UIScrollView's
    /// Content Offset to zero.
    ///
    func scrollContentToTop(animated: Bool) {
        guard viewControllers.count == 1,
            let scrollView = visibleViewController?.view?.subviews.first as? UIScrollView
            else {
                return
        }

        scrollView.setContentOffset(.zero, animated: animated)
    }

    /// Completion block for popToRootViewController
    /// UINavigationController API doesn't offer any options for this.
    /// However by using the CoreAnimation framework it's possible to add a completion block to the underlying animation
    ///
    func popToRootViewController(animated: Bool, handler: @escaping ()->()) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(handler)
        popToRootViewController(animated: animated)
        CATransaction.commit()
    }
}

// MARK: - Handle UINavigationBar's 'Back' button action
//
protocol UINavigationBarBackButtonHandler {

    /// Should block the 'Back' button action
    ///
    /// - Returns: true - don't block，false - block
    func  shouldPopOnBackButton() -> Bool
}

extension UIViewController: UINavigationBarBackButtonHandler {
    //Do not block the "Back" button action by default, otherwise, override this function in the specified viewcontroller
    @objc func  shouldPopOnBackButton() -> Bool {
        return true
    }
}

extension UINavigationController: UINavigationBarDelegate {

    // This delegate method is not called on the simulator running iOS 13.4.
    // Test it on a real device.
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        guard let items = navigationBar.items else {
            return false
        }

        if viewControllers.count < items.count {
            return true
        }

        var shouldPop = true

        if let vc = topViewController {
            shouldPop = vc.shouldPopOnBackButton()
        }

        if shouldPop {
            DispatchQueue.main.async {
                self.popViewController(animated: true)
            }
        }
        return false
    }
}
