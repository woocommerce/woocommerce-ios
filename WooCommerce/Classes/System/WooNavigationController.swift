import UIKit

/// Navigation controller for a Woo tab.
/// The difference from `UINavigationController` is that it keeps track of which view controllers with large title enabled.
final class WooTabNavigationController: UINavigationController {

    init() {
        super.init(nibName: nil, bundle: nil)
        navigationBar.prefersLargeTitles = true
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }
}

extension WooTabNavigationController: UINavigationControllerDelegate {
    // Always forces large titles to the root view controller
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if navigationController.viewControllers.count == 1 {
            viewController.navigationItem.largeTitleDisplayMode = .always
        } else {
            viewController.navigationItem.largeTitleDisplayMode = viewController.preferredLargeTitleDisplayMode()
        }
    }
}

// MARK: - Large title customizations
// Allow each vc to override this method and choose their preferred large title display mode
extension UIViewController {
    @objc func preferredLargeTitleDisplayMode() -> UINavigationItem.LargeTitleDisplayMode {
        .never
    }
}



/// Subclass to set Woo styling.
/// Use this when presenting modals.
///
class WooNavigationController: UINavigationController {

    /// Sets the status bar of the pushed view to white.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StyleManager.statusBarLight
    }
}
