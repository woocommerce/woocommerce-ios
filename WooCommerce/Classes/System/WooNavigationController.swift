import UIKit

/// Navigation controller for a Woo tab, shown as the root view controller of one of the tab bar.
/// The first view controller always has large title, while the following view controllers in the navigation stack do not have large title by default.
/// The following view controllers can override `preferredLargeTitleDisplayMode` function to change the large title display mode.
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
    // The first view controller always has large title, while the following view controllers in the navigation stack do not have large title by default.
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if navigationController.viewControllers.count == 1 {
            viewController.navigationItem.largeTitleDisplayMode = .always
        } else {
            viewController.navigationItem.largeTitleDisplayMode = viewController.preferredLargeTitleDisplayMode()
        }
    }
}

// MARK: - Large title customizations

extension UIViewController {
    /// A view controller is default not to show large title.
    /// This function allows each view controller to override the default large title display mode.
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
