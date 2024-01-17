import UIKit

/// Container for a Woo tab, shown as the root view controller of one of the tabs.
/// Provided as an alternative to `WooTabNavigationController`, for root controllers which should not be in a nav view
/// For example, a Split View, which will not work correctly on iPhone when wrapped in a navigation view.
/// This wraps a controller which can be replaced when the selected site changes.
final class TabContainerController: UIViewController {
    var wrappedController: UIViewController? {
        willSet {
            wrappedController?.willMove(toParent: nil)
            wrappedController?.view.removeFromSuperview()
            wrappedController?.removeFromParent()
        }

        didSet {
            guard let newWrappedController = wrappedController else {
                return
            }

            addChild(newWrappedController)
            view.addSubview(newWrappedController.view)
            newWrappedController.didMove(toParent: self)

            newWrappedController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                newWrappedController.view.topAnchor.constraint(equalTo: view.topAnchor),
                newWrappedController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                newWrappedController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                newWrappedController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            tabBarItem = newWrappedController.tabBarItem
        }
    }
}
