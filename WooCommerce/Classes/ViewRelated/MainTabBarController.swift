import UIKit
import Gridicons
import Yosemite


/// Enum representing the individual tabs
///
enum WooTab: Int {

    /// My Store Tab
    ///
    case myStore = 0

    /// Orders Tab
    ///
    case orders = 1

    /// Notifications Tab
    ///
    case notifications = 2
}


// MARK: - MainTabBarController
//
class MainTabBarController: UITabBarController {

    /// For picking up the child view controller's status bar styling
    /// - returns: nil to let the tab bar control styling or `children.first` for VC control.
    ///
    open override var childForStatusBarStyle: UIViewController? {
        return nil
    }

    /// Used for overriding the status bar style for all child view controllers
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StyleManager.statusBarLight
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate() // call this to refresh status bar changes happening at runtime
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let currentlySelectedTab = WooTab(rawValue: selectedIndex),
            let userSelectedIndex = tabBar.items?.index(of: item),
            let userSelectedTab = WooTab(rawValue: userSelectedIndex) else {
                return
        }

        // Did we reselect the already-selected tab?
        if currentlySelectedTab == userSelectedTab {
            switch userSelectedTab {
            case .myStore:
                WooAnalytics.shared.track(.dashboardReselected)
            case .orders:
                WooAnalytics.shared.track(.ordersReselected)
            case .notifications:
                WooAnalytics.shared.track(.notificationsReselected)
            }
        } else {
            switch userSelectedTab {
            case .myStore:
                WooAnalytics.shared.track(.dashboardSelected)
            case .orders:
                WooAnalytics.shared.track(.ordersSelected)
            case .notifications:
                WooAnalytics.shared.track(.notificationsSelected)
            }
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


// MARK: - Tab dot madness!
//
extension MainTabBarController {

    func showDotOnTab(index: Int, radius: CGFloat = 5, color: UIColor = StyleManager.wooAccent, xOffset: CGFloat = 0, yOffset: CGFloat = 0) {
        let tag = index + 42

        hideDotOnTab(index: index)
        let dotDiameter = radius * 2
        let xOffsetBase = CGFloat(21)
        let yOffsetBase = CGFloat(3)

        let dot = UIView(frame: CGRect(x: xOffsetBase + xOffset, y: yOffsetBase + yOffset, width: dotDiameter, height: dotDiameter))
        dot.tag = tag
        dot.backgroundColor = color
        dot.layer.cornerRadius = radius
        tabBar.subviews[index + 1].subviews.first?.insertSubview(dot, at: 1)
    }

    func hideDotOnTab(index: Int) {
        let tag = index + 42
        if let subviews = tabBar.subviews[index + 1].subviews.first?.subviews {
            for subview in subviews where subview.tag == tag {
                subview.removeFromSuperview()
            }
        }
    }
}
