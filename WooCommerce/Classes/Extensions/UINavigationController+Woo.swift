import Foundation
import UIKit


// MARK: - UINavigationController: Woo Extensions
//
extension UINavigationController {

    /// Updates the navigation bar visibility only when it differs from the requested state.
    ///
    /// Avoiding redundant visibility updates is important when this navigation controller is wrapped by a split view.
    /// UIKit can otherwise try to lay out the wrapper's navigation bar using an item that still belongs to this bar.
    func setNavigationBarHiddenIfNeeded(_ hidden: Bool, animated: Bool) {
        guard isNavigationBarHidden != hidden else {
            return
        }

        setNavigationBarHidden(hidden, animated: animated)
    }

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

    /// Two-stage tab re-selection: pop to root, or scroll to top when already at root.
    /// Every screen being popped must permit it (`shouldPopOnBackButton`), like tapping Back
    /// through them; the first screen that refuses becomes the new top instead. Screens inside
    /// a nested navigation controller (e.g. a collapsed split view's column) are asked too.
    /// Returns `true` when the stack ends up at its root, `false` when a screen refused.
    @discardableResult
    func popToRootOrScrollToTop(animated: Bool) -> Bool {
        guard viewControllers.count > 1 else {
            scrollContentToTop(animated: animated)
            return true
        }
        for element in viewControllers.dropFirst().reversed() {
            for screen in Self.screens(in: element) {
                guard screen.shouldPopOnBackButton() else {
                    revealRefusingScreen(screen, poppedElement: element, animated: animated)
                    return false
                }
            }
        }
        popToRootViewController(animated: animated)
        return true
    }

    /// The screens a stack element stands for, top-down. A collapsed split view puts its column
    /// into the stack as a navigation controller, so that element stands for everything inside it.
    static func screens(in element: UIViewController) -> [UIViewController] {
        guard let nestedNavigationController = element as? UINavigationController else {
            return [element]
        }
        return nestedNavigationController.viewControllers.reversed()
    }

    /// Pops down to the screen that refused, making it the visible top.
    private func revealRefusingScreen(_ screen: UIViewController, poppedElement element: UIViewController, animated: Bool) {
        if topViewController !== element {
            popToViewController(element, animated: animated)
        }
        guard let nestedNavigationController = element as? UINavigationController,
              nestedNavigationController.topViewController !== screen else {
            return
        }
        nestedNavigationController.popToViewController(screen, animated: animated)
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

    /// Replaces the top view controller of the view controllers stack
    ///
    func replaceTopViewController(with viewController: UIViewController, animated: Bool) {
        var helperViewControllers = viewControllers
        helperViewControllers[helperViewControllers.count - 1] = viewController
        setViewControllers(helperViewControllers, animated: animated)
    }
}

// MARK: - Handle UINavigationBar's 'Back' button action
//
protocol UINavigationBarBackButtonHandler {

    /// Should block the 'Back' button action
    ///
    /// - Returns: true - don't block，false - block
    func shouldPopOnBackButton() -> Bool
}

extension UIViewController: UINavigationBarBackButtonHandler {
    //Do not block the "Back" button action by default, otherwise, override this function in the specified viewcontroller
    @objc func shouldPopOnBackButton() -> Bool {
        return true
    }
}

/// The `@retroactive` attribute is used to apply `UINavigationBarDelegate` conformance to `UINavigationController` from the UIKit module.
/// This is necessary due to Swift 6 [SE-0364 proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0364-retroactive-conformance-warning.md).
extension UINavigationController: @retroactive UINavigationBarDelegate {
    public func checkIfNavigationBarShouldPop(item: UINavigationItem) -> Bool {
        guard let vc = topViewController, vc.navigationItem == item else {
            return true
        }

        return vc.shouldPopOnBackButton()
    }

    // While working on https://github.com/woocommerce/woocommerce-ios/pull/13647:
    // - Noticed that this was not being called
    // - Added extension of WooNavigationController with overriding this method and calling checkIfNavigationBarShouldPop(:)
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        return checkIfNavigationBarShouldPop(item: item)
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

/// The `@retroactive` attribute is used for adding `UIGestureRecognizerDelegate` conformance to `UIViewController` from the UIKit module.
/// This is necessary due to Swift 6 [SE-0364 proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0364-retroactive-conformance-warning.md).
extension UIViewController: @retroactive UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isEqual(navigationController?.interactivePopGestureRecognizer) && navigationController?.topViewController == self {
            return shouldPopOnSwipeBack()
        }

        return true
    }

    func handleSwipeBackGesture() {
        guard let navigationController,
              !(navigationController is WooNavigationController) else {
            return
        }

        navigationController.interactivePopGestureRecognizer?.delegate = self
    }
}
