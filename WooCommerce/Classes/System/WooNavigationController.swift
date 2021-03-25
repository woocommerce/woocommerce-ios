import UIKit

/// Subclass to set Woo styling. Removes back button text on managed view controllers.
/// Use this when presenting modals.
///
class WooNavigationController: UINavigationController {

    weak override var delegate: UINavigationControllerDelegate? {
        get {
            return navigationDelegate.forwardDelegate
        }
        set {
            navigationDelegate.forwardDelegate = newValue
        }
    }

    /// Private object that listens, acts upon, and forwards events from `UINavigationControllerDelegate`
    ///
    private let navigationDelegate = WooNavigationControllerDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = navigationDelegate
    }

    /// Sets the status bar of the pushed view to white.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StyleManager.statusBarLight
    }
}

/// Class that listens and forwards events from `UINavigationControllerDelegate`
/// Needed to configure the managed `ViewController` back button while providing a `delegate` to children classes.
///
private class WooNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {

    /// Children delegate, all events will be forwarded to this object
    ///
    weak var forwardDelegate: UINavigationControllerDelegate?

    /// Configures the back button for the managed `ViewController` and forwards the event to the children delegate.
    ///
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        configureBackButton(for: viewController)
        forwardDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
    }

    /// Forwards the event to the children delegate.
    ///
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        forwardDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
    }

    /// Forwards the event to the children delegate.
    ///
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        forwardDelegate?.navigationControllerSupportedInterfaceOrientations?(navigationController) ?? .allButUpsideDown
    }

    /// Forwards the event to the children delegate.
    ///
    func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        forwardDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(navigationController) ?? .portrait
    }

    /// Forwards the event to the children delegate.
    ///
    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        forwardDelegate?.navigationController?(navigationController, interactionControllerFor: animationController)
    }

    /// Forwards the event to the children delegate.
    ///
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        forwardDelegate?.navigationController?(navigationController,
                                               animationControllerFor: operation,
                                               from: fromVC,
                                               to: toVC)
    }
}

// MARK: Back button configuration
private extension WooNavigationControllerDelegate {
    /// Removes the back button text for the provided `ViewController`
    ///
    func configureBackButton(for viewController: UIViewController) {
        viewController.removeNavigationBackBarButtonText()
    }
}
