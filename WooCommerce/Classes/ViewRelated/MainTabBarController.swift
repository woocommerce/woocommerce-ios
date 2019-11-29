import UIKit
import Yosemite
import WordPressUI


/// Enum representing the individual tabs
///
enum WooTab {

    /// My Store Tab
    ///
    case myStore

    /// Orders Tab
    ///
    case orders

    /// Products Tab
    ///
    case products

    /// Reviews Tab
    ///
    case reviews
}

extension WooTab {
    /// Initializes a tab with the visible tab index.
    ///
    /// - Parameters:
    ///   - visibleIndex: the index of visible tabs on the tab bar
    ///   - isProductListFeatureOn: whether the product list feature is enabled
    init(visibleIndex: Int,
         isProductListFeatureOn: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productList)) {
        let tabs = WooTab.visibleTabs(isProductListFeatureOn: isProductListFeatureOn)
        self = tabs[visibleIndex]
    }

    /// Returns the visible tab index.
    func visibleIndex(isProductListFeatureOn: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productList)) -> Int {
        let tabs = WooTab.visibleTabs(isProductListFeatureOn: isProductListFeatureOn)
        guard let tabIndex = tabs.firstIndex(where: { $0 == self }) else {
            assertionFailure("Trying to get the visible tab index for tab \(self) while the visible tabs are: \(tabs)")
            return 0
        }
        return tabIndex
    }

    // Note: currently all tab view controllers except for Products tab are set up in Main.storyboard.
    private static func visibleTabs(isProductListFeatureOn: Bool) -> [WooTab] {
        if isProductListFeatureOn {
            return [.myStore, .orders, .products, .reviews]
        } else {
            return [.myStore, .orders, .reviews]
        }
    }
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

    /// Orders badge
    ///
    private let ordersBadge = OrdersBadgeController()

    /// ViewModel
    ///
    private let viewModel = MainTabViewModel()


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate() // call this to refresh status bar changes happening at runtime

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productList) {
            configureProductsTab()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        /// Note:
        /// We hook up KVO in this spot... because at the point in which `viewDidLoad` fires, we haven't really fully
        /// loaded the childViewControllers, and the tabBar isn't fully initialized.
        ///
        startListeningToBadgeUpdatesIfNeeded()
        startListeningToOrdersBadge()
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let currentlySelectedTab = WooTab(visibleIndex: selectedIndex)
        guard let userSelectedIndex = tabBar.items?.firstIndex(of: item) else {
                return
        }
        let userSelectedTab = WooTab(visibleIndex: userSelectedIndex)

        // Did we reselect the already-selected tab?
        if currentlySelectedTab == userSelectedTab {
            trackTabReselected(tab: userSelectedTab)
            scrollContentToTop()
        } else {
            trackTabSelected(newTab: userSelectedTab)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.ordersBadge.updateBadgePosition(.orders, in: self.tabBar)
        }
    }

    // MARK: - Public Methods

    /// Switches the TabBarcController to the specified Tab
    ///
    func navigateTo(_ tab: WooTab, animated: Bool = false, completion: (() -> Void)? = nil) {
        selectedIndex = tab.visibleIndex()
        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: animated) {
                completion?()
            }
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

// MARK: - Products tab
//
private extension MainTabBarController {
    func configureProductsTab() {
        var tabViewControllers = viewControllers

        let productsViewController = ProductsViewController(nibName: nil, bundle: nil)

        let navController = WooNavigationController(rootViewController: productsViewController)
        navController.tabBarItem = UITabBarItem(title: NSLocalizedString("Products",
                                                                         comment: "Title of the Products tab — plural form of Product"),
                                                image: UIImage.productImage,
                                                tag: 0)
        tabViewControllers?.insert(navController, at: WooTab.products.visibleIndex())
        viewControllers = tabViewControllers
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
            ServiceLocator.analytics.track(.dashboardSelected)
        case .orders:
            ServiceLocator.analytics.track(.ordersSelected)
        case .products:
            ServiceLocator.analytics.track(.productListSelected)
        case .reviews:
            ServiceLocator.analytics.track(.notificationsSelected)
        }
    }

    /// Tracks "Tab Re Selected" Events.
    ///
    func trackTabReselected(tab: WooTab) {
        switch tab {
        case .myStore:
            ServiceLocator.analytics.track(.dashboardReselected)
        case .orders:
            ServiceLocator.analytics.track(.ordersReselected)
        case .products:
            ServiceLocator.analytics.track(.productListReselected)
        case .reviews:
            ServiceLocator.analytics.track(.notificationsReselected)
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

    /// Switches to the Reviews tab and pops to the root view controller
    ///
    static func switchToReviewsTab(completion: (() -> Void)? = nil) {
        navigateTo(.reviews, completion: completion)
    }

    /// Switches the TabBarController to the specified Tab
    ///
    private static func navigateTo(_ tab: WooTab, animated: Bool = false, completion: (() -> Void)? = nil) {
        guard let tabBar = AppDelegate.shared.tabBarController else {
            return
        }
        tabBar.navigateTo(tab, animated: animated, completion: completion)
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
        switchToReviewsTab {
            guard let reviewsViewController: ReviewsViewController = childViewController() else {
                return
            }
            reviewsViewController.presentDetails(for: noteID)
        }
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

private extension MainTabBarController {
    func startListeningToOrdersBadge() {
        viewModel.onBadgeReload = { [weak self] countReadableString in
            guard let self = self else {
                return
            }

            guard let badgeText = countReadableString else {
                self.ordersBadge.hideBadgeOn(.orders, in: self.tabBar)
                return
            }

            self.ordersBadge.showBadgeOn(.orders,
                                         in: self.tabBar,
                                         withValue: badgeText)
        }

        viewModel.startObservingOrdersCount()
    }
}
