import UIKit

/// Keeps track of a weak set of view controllers with large title enabled, so that any view controllers shown that are not
/// in the set won't have large title in the navigation bar.
final class WooTabNavigationControllerDelegate: NSObject {
    private var viewControllersWithLargeTitle = NSHashTable<UIViewController>.weakObjects()

    func addViewControllerWithLargeTitle(_ viewController: UIViewController) {
        viewControllersWithLargeTitle.add(viewController)
        viewController.navigationController?.navigationBar.prefersLargeTitles = true
    }
}

extension WooTabNavigationControllerDelegate: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewControllersWithLargeTitle.contains(viewController) {
            viewController.navigationItem.largeTitleDisplayMode = .always
        } else {
            viewController.navigationItem.largeTitleDisplayMode = .never
        }
    }
}

/// Navigation controller for a Woo tab.
/// The difference from `UINavigationController` is that it keeps track of which view controllers with large title enabled.
final class WooTabNavigationController: UINavigationController {
    private let navigationControllerDelegate = WooTabNavigationControllerDelegate()

    init() {
        super.init(nibName: nil, bundle: nil)
        self.delegate = navigationControllerDelegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }

    /// Adds a view controller to the navigation stack with large title enabled or disabled.
    /// - Parameters:
    ///   - viewController: view controller to add to the navigation stack.
    ///   - isLargeTitleEnabled: whether large title is enabled for the given view controller.
    ///   - isLargeTitlesFeatureFlagEnabled: whether large titles feature flag is enabled.
    func addViewController(_ viewController: UIViewController, isLargeTitleEnabled: Bool, isLargeTitlesFeatureFlagEnabled: Bool) {
        viewControllers.append(viewController)
        if isLargeTitleEnabled && isLargeTitlesFeatureFlagEnabled {
            navigationControllerDelegate.addViewControllerWithLargeTitle(viewController)
        }
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
