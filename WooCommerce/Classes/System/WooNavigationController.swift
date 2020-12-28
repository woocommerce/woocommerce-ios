import UIKit

final class WooTabNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    private var viewControllersWithLargeTitle: [UIViewController] = []

    func addViewControllerWithLargeTitle(_ viewController: UIViewController) {
        viewControllersWithLargeTitle.append(viewController)
        viewController.navigationItem.largeTitleDisplayMode = .always
        viewController.navigationController?.navigationBar.prefersLargeTitles = true
    }
}

extension WooTabNavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewControllersWithLargeTitle.contains(viewController) {
            return
        }

        guard let indexOfViewController = navigationController.viewControllers.lastIndex(of: viewController),
              let previousViewController = navigationController.viewControllers[safe: indexOfViewController - 1],
              viewControllersWithLargeTitle.contains(previousViewController) && viewControllersWithLargeTitle.contains(viewController) == false else {
            return
        }
        viewController.navigationItem.largeTitleDisplayMode = .never
    }
}

class WooTabNavigationController: UINavigationController {
    private let navigationControllerDelegate = WooTabNavigationControllerDelegate()

    init() {
        super.init(nibName: nil, bundle: nil)
        self.delegate = navigationControllerDelegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    func addViewController(_ viewController: UIViewController, isLargeTitlesEnabled: Bool) {
        viewControllers.append(viewController)
        if isLargeTitlesEnabled {
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
