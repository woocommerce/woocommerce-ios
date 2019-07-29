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
final class MainTabBarController: UITabBarController {

    /// For picking up the child view controller's status bar styling
    /// - returns: nil to let the tab bar control styling or `children.first` for VC control.
    ///
    public override var childForStatusBarStyle: UIViewController? {
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

    /// Notifications badge
    ///
    private let notificationsBadge = NotificationsBadgeController()


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
            let userSelectedIndex = tabBar.items?.firstIndex(of: item),
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
        notificationsBadge.badgeCountWasUpdated(newValue: newValue, in: tabBar)
    }
}
