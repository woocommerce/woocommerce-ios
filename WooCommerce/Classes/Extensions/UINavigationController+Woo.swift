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
    @objc func shouldPopOnBackButton() -> Bool {
        return true
    }
}

extension UINavigationController: UINavigationBarDelegate {

    // This delegate method is not called on the simulator or device running iOS 13.4 from Xcode.
    // You need to use a release build.
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

// MARK: - Handle the swipe back gesture
protocol NavigationSwipeBackHandler {

    /// Should block the 'SwipeBack' gesture
    ///
    /// - Returns: true - don't block，false - block
    func shouldPopOnSwipeBack() -> Bool
}

extension UIViewController: NavigationSwipeBackHandler {
    //Do not block the "Swipe back" gesture by default, otherwise, override this function in the specified viewcontroller
    @objc func shouldPopOnSwipeBack() -> Bool {
        return true
    }
}

extension UIViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isEqual(navigationController?.interactivePopGestureRecognizer) {
            return shouldPopOnSwipeBack()
        }

        return false
    }
    
    func handleSwipeBackGesture() {
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
}
