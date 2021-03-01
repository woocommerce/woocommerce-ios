import UIKit

/// Navigation controller for a Woo tab, shown as the root view controller of one of the tab bar.
/// The first view controller always has large title, while the following view controllers in the navigation stack do not have large title by default.
/// The following view controllers can override `preferredLargeTitleDisplayMode` function to change the large title display mode.
final class WooTabNavigationController: UINavigationController {
    init() {
        super.init(nibName: nil, bundle: nil)
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
            navigationBar.prefersLargeTitles = true
            delegate = self
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) ? .default : StyleManager.statusBarLight
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
