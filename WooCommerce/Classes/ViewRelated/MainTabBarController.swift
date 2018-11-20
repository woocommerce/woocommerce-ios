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

    static func showDotOn(_ tab: WooTab) {
        guard let tabBar = AppDelegate.shared.tabBarController?.tabBar else {
            return
        }

        hideDotOn(tab)
        let dot = GreenDotView(frame: CGRect(x: DotConstants.xOffset,
                                             y: DotConstants.yOffset,
                                             width: DotConstants.diameter,
                                             height: DotConstants.diameter), borderWidth: DotConstants.borderWidth)
        dot.tag = dotTag(for: tab)
        dot.isHidden = true
        tabBar.subviews[tab.rawValue].subviews.first?.insertSubview(dot, at: 1)
        dot.fadeIn()
    }

    static func hideDotOn(_ tab: WooTab) {
        guard let tabBar = AppDelegate.shared.tabBarController?.tabBar else {
            return
        }

        let tag = dotTag(for: tab)
        if let subviews = tabBar.subviews[tab.rawValue].subviews.first?.subviews {
            for subview in subviews where subview.tag == tag {
                subview.fadeOut() { _ in
                    subview.removeFromSuperview()
                }
            }
        }
    }

    private static func dotTag(for tab: WooTab) -> Int {
        return tab.rawValue + DotConstants.tagOffset
    }
}


// MARK: - Constants!
//
private extension MainTabBarController {

    enum DotConstants {
        static let diameter    = CGFloat(10)
        static let borderWidth = CGFloat(1)
        static let xOffset     = CGFloat(2)
        static let yOffset     = CGFloat(0)
        static let tagOffset   = 999
    }
}


// MARK: - GreenDot UIView
//
private class GreenDotView: UIView {

    private var borderWidth = CGFloat(1) // Border line width defaults to 1

    /// Designated Initializer
    ///
    init(frame: CGRect, borderWidth: CGFloat) {
        super.init(frame: frame)
        self.borderWidth = borderWidth
        setupSubviews()
    }

    /// Required Initializer
    ///
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: CGRect(x: rect.origin.x + borderWidth,
                                               y: rect.origin.y + borderWidth,
                                               width: rect.size.width - borderWidth*2,
                                               height: rect.size.height - borderWidth*2))
        StyleManager.wooAccent.setFill()
        path.fill()

        path.lineWidth = borderWidth
        StyleManager.wooWhite.setStroke()
        path.stroke()
    }
}
