import UIKit
import Gridicons
import Yosemite
import WordPressUI


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

    /// KVO Token
    ///
    private var observationToken: NSKeyValueObservation?


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate() // call this to refresh status bar changes happening at runtime
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        /// Note:
        /// We hook up KVO in this spot... because at the point in which `viewDidLoad` fires, we haven't really fully
        /// loaded the childViewControllers, and the tabBar isn't fully initialized.
        ///
        startListeningToBadgeUpdatesIfNeeded()
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let currentlySelectedTab = WooTab(rawValue: selectedIndex),
            let userSelectedIndex = tabBar.items?.index(of: item),
            let userSelectedTab = WooTab(rawValue: userSelectedIndex) else {
                return
        }

        // Did we reselect the already-selected tab?
        if currentlySelectedTab == userSelectedTab {
            trackTabReselected(tab: userSelectedTab)
            scrollContentToTop()
        } else {
            trackTabSelected(newTab: userSelectedTab)
        }
    }

    // MARK: - Public Methods

    /// Switches the TabBarcController to the specified Tab
    ///
    func navigateTo(_ tab: WooTab, animated: Bool = false) {
        selectedIndex = tab.rawValue
        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: animated)
        }
    }
}


// MARK: - UIViewControllerTransitioningDelegate
//
extension MainTabBarController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}


// MARK: - Static navigation helpers
//
private extension MainTabBarController {

    /// *When applicable* this method will scroll the visible content to top.
    ///
    func scrollContentToTop() {
        guard let navController = selectedViewController as? UINavigationController else {
            return
        }

        navController.scrollContentToTop(animated: true)
    }

    /// Tracks "Tab Selected" Events.
    ///
    func trackTabSelected(newTab: WooTab) {
        switch newTab {
        case .myStore:
            WooAnalytics.shared.track(.dashboardSelected)
        case .orders:
            WooAnalytics.shared.track(.ordersSelected)
        case .notifications:
            WooAnalytics.shared.track(.notificationsSelected)
        }
    }

    /// Tracks "Tab Re Selected" Events.
    ///
    func trackTabReselected(tab: WooTab) {
        switch tab {
        case .myStore:
            WooAnalytics.shared.track(.dashboardReselected)
        case .orders:
            WooAnalytics.shared.track(.ordersReselected)
        case .notifications:
            WooAnalytics.shared.track(.notificationsReselected)
        }
    }
}


// MARK: - Static navigation helpers
//
extension MainTabBarController {

    /// Switches to the My Store tab and pops to the root view controller
    ///
    static func switchToMyStoreTab(animated: Bool = false) {
        navigateTo(.myStore, animated: animated)
    }

    /// Switches to the Orders tab and pops to the root view controller
    ///
    static func switchToOrdersTab() {
        navigateTo(.orders)
    }

    /// Switches to the Notifications tab and pops to the root view controller
    ///
    static func switchToNotificationsTab() {
        navigateTo(.notifications)
    }

    /// Switches the TabBarController to the specified Tab
    ///
    private static func navigateTo(_ tab: WooTab, animated: Bool = false) {
        guard let tabBar = AppDelegate.shared.tabBarController else {
            return
        }

        tabBar.navigateTo(tab, animated: animated)
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


// MARK: - Static Navigation + Details!
//
extension MainTabBarController {

    /// Displays the Orders List with the specified Filter applied.
    ///
    static func presentOrders(statusFilter: OrderStatus) {
        switchToOrdersTab()

        guard let ordersViewController: OrdersViewController = childViewController() else {
            return
        }

        ordersViewController.statusFilter = statusFilter
    }

    /// Switches to the Notifications Tab, and displays the details for the specified Notification ID.
    ///
    static func presentNotificationDetails(for noteID: Int) {
        switchToNotificationsTab()

        guard let notificationsViewController: NotificationsViewController = childViewController() else {
            return
        }

        notificationsViewController.presentDetails(for: noteID)
    }

    /// Switches to the My Store Tab, and presents the Settings .
    ///
    static func presentSettings() {
        switchToMyStoreTab(animated: false)

        guard let dashBoard: DashboardViewController = childViewController() else {
            return
        }

        dashBoard.presentSettings()
    }
}


// MARK: - Tab dot madness!
//
private extension MainTabBarController {

    /// Setup: KVO Hooks.
    ///
    func startListeningToBadgeUpdatesIfNeeded() {
        guard observationToken == nil else {
            return
        }

        observationToken = UIApplication.shared.observe(\.applicationIconBadgeNumber, options: [.initial, .new]) {  (application, _) in
            self.badgeCountWasUpdated(newValue: application.applicationIconBadgeNumber)
        }
    }

    /// Displays or Hides the Dot, depending on the new Badge Value
    ///
    func badgeCountWasUpdated(newValue: Int) {
        guard newValue > 0 else {
            hideDotOn(.notifications)
            return
        }

        showDotOn(.notifications)
    }

    /// Shows the dot in the specified WooTab
    ///
    func showDotOn(_ tab: WooTab) {
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

    /// Hides the Dot in the specified WooTab
    ///
    func hideDotOn(_ tab: WooTab) {
        let tag = dotTag(for: tab)
        if let subviews = tabBar.subviews[tab.rawValue].subviews.first?.subviews {
            for subview in subviews where subview.tag == tag {
                subview.fadeOut() { _ in
                    subview.removeFromSuperview()
                }
            }
        }
    }

    /// Returns the DotView's Tag for the specified WooTab
    ///
    func dotTag(for tab: WooTab) -> Int {
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
