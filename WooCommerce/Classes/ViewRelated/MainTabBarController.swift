import UIKit
import Gridicons
import Yosemite


/// Enum representing the individual tabs
///
enum WooTab: Int, CustomStringConvertible {

    /// My Store Tab
    ///
    case myStore = 0

    /// Orders Tab
    ///
    case orders = 1

    /// Notifications Tab
    ///
    case notifications = 2

    var description: String {
        switch self {
        case .myStore:
            return NSLocalizedString("My Store", comment: "Dashboard tab title")
        case .orders:
            return NSLocalizedString("Orders", comment: "Orders tab title")
        case .notifications:
            return NSLocalizedString("Notifications", comment: "Notifications tab title")
        }
    }

    var tabIcon: UIImage {
        switch self {
        case .myStore:
            return Gridicon.iconOfType(.statsAlt)
        case .orders:
            return Gridicon.iconOfType(.pages)
        case .notifications:
            return Gridicon.iconOfType(.bell)
        }
    }
}


// MARK: - MainTabBarController
//
class MainTabBarController: UITabBarController {

    /// For picking up the child view controller's status bar styling
    ///
    open override var childForStatusBarStyle: UIViewController? {
        return nil
    }

    /// Used for overriding the status bar style for all child view controllers
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setNeedsStatusBarAppearanceUpdate() // call this to refresh status bar changes happening at runtime
    }

    private func setupTabBar() {
        guard let items = tabBar.items else {
            fatalError()
        }

        for (index, item) in items.enumerated() {
            guard let tab = WooTab(rawValue: index) else {
                fatalError()
            }
            item.title = tab.description
            item.image = tab.tabIcon
        }
    }
}


// MARK: - Static navigation helpers
//
extension MainTabBarController {

    /// Switches to the My Store tab and pops to the root view controller
    ///
    static func switchToMyStoreTab() {
        navigateTo(.myStore)
    }

    /// Switches to the Orders tab and pops to the root view controller
    ///
    static func switchToOrdersTab(filter: OrderStatus? = nil) {
        navigateTo(.orders)

        guard let ordersViewController: OrdersViewController = childViewController() else {
            return
        }

        ordersViewController.statusFilter = filter
    }

    /// Switches to the Notifications tab and pops to the root view controller
    ///
    static func switchToNotificationsTab() {
        navigateTo(.notifications)
    }

    /// Switches the TabBarcController to the specified Tab
    ///
    private static func navigateTo(_ tab: WooTab) {
        guard let tabBar = AppDelegate.shared.tabBarController else {
            return
        }

        tabBar.selectedIndex = tab.rawValue
        if let navController = tabBar.selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: false)
        }
    }

    /// Returns the "Top Visible Child" of the specified type
    ///
    private static func childViewController<T: UIViewController>() -> T? {
        let selectedViewController = AppDelegate.shared.tabBarController?.selectedViewController
        guard let navController = selectedViewController as? UINavigationController else {
            return selectedViewController as? T
        }

        return navController.topViewController as? T
    }
}
