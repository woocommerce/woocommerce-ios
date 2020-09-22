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
    init(visibleIndex: Int) {
        let tabs = WooTab.visibleTabs()
        self = tabs[visibleIndex]
    }

    /// Returns the visible tab index.
    func visibleIndex() -> Int {
        let tabs = WooTab.visibleTabs()
        guard let tabIndex = tabs.firstIndex(where: { $0 == self }) else {
            assertionFailure("Trying to get the visible tab index for tab \(self) while the visible tabs are: \(tabs)")
            return 0
        }
        return tabIndex
    }

    // Note: currently only the Dashboard tab (My Store) view controller is set up in Main.storyboard.
    private static func visibleTabs() -> [WooTab] {
            return [.myStore, .orders, .products, .reviews]
    }
}


// MARK: - MainTabBarController

/// A view controller that shows the tabs Store, Orders, Products, and Reviews.
///
/// TODO Migrate the `viewControllers` management from `Main.storyboard` to here (as code).
///
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

    /// Notifications badge
    ///
    private let notificationsBadge = NotificationsBadgeController()

    /// ViewModel
    ///
    private let viewModel = MainTabViewModel()

    private lazy var dashboardViewController: UIViewController = {
        let dashboardViewController = DashboardViewController()
        return WooNavigationController(rootViewController: dashboardViewController)
    }()

    private lazy var ordersTabViewController: UIViewController = {
        let rootViewController = OrdersRootViewController()
        return WooNavigationController(rootViewController: rootViewController)
    }()

    private lazy var productsTabViewController: UIViewController = {
        let productsViewController = ProductsViewController(nibName: nil, bundle: nil)
        let navController = WooNavigationController(rootViewController: productsViewController)
        let navigationTitle = NSLocalizedString("Products",
                                                comment: "Title of the Products tab — plural form of Product")
        navController.tabBarItem = UITabBarItem(title: navigationTitle,
                                                image: UIImage.productImage,
                                                tag: 0)
        navController.tabBarItem.accessibilityIdentifier = "tab-bar-products-item"

        return navController
    }()

    private lazy var reviewsCoordinator: Coordinator = ReviewsCoordinator(willPresentReviewDetailsFromPushNotification: { [weak self] in
        self?.navigateTo(.reviews)
    })

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate() // call this to refresh status bar changes happening at runtime

        // Add the Orders, Products and Reviews tab
        viewControllers = {
            var controllers = [UIViewController]()

            let dashboardTabIndex = WooTab.myStore.visibleIndex()
            controllers.insert(dashboardViewController, at: dashboardTabIndex)

            let ordersTabIndex = WooTab.orders.visibleIndex()
            controllers.insert(ordersTabViewController, at: ordersTabIndex)

            let productsTabIndex = WooTab.products.visibleIndex()
            controllers.insert(productsTabViewController, at: productsTabIndex)

            let reviewsTabIndex = WooTab.reviews.visibleIndex()
            controllers.insert(reviewsCoordinator.navigationController, at: reviewsTabIndex)

            return controllers
        }()

        loadReviewsTabNotificationCountAndUpdateBadge()

        reviewsCoordinator.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        /// Note:
        /// We hook up KVO in this spot... because at the point in which `viewDidLoad` fires, we haven't really fully
        /// loaded the childViewControllers, and the tabBar isn't fully initialized.
        ///
        startListeningToReviewsTabBadgeUpdates()
        startListeningToOrdersBadge()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.onViewDidAppear()
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
    static func switchToOrdersTab(completion: (() -> Void)? = nil) {
        navigateTo(.orders, completion: completion)
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

    /// Syncs the notification given the ID, and handles the notification based on its notification kind.
    ///
    static func presentNotificationDetails(for noteID: Int64) {
        let action = NotificationAction.synchronizeNotification(noteID: noteID) { note, error in
            guard let note = note else {
                return
            }
            let siteID = note.meta.identifier(forKey: .site) ?? Int.min
            SwitchStoreUseCase(stores: ServiceLocator.stores).switchStore(with: Int64(siteID)) { siteChanged in
                presentNotificationDetails(for: note)

                if siteChanged {
                    let presenter = SwitchStoreNoticePresenter()
                    presenter.presentStoreSwitchedNotice(configuration: .switchingStores)
                }
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Presents the order details if the `note` is for an order push notification.
    ///
    /// For Product Review notifications, that is now handled by `ReviewsCoordinator`. This method
    /// should also be moved to a similar `Coordinator` in the future too.
    ///
    private static func presentNotificationDetails(for note: Note) {
        switch note.kind {
        case .storeOrder:
            switchToOrdersTab {
                guard let ordersVC: OrdersRootViewController = childViewController() else {
                    return
                }

                ordersVC.presentDetails(for: note)
            }
        default:
            break
        }

        ServiceLocator.analytics.track(.notificationOpened, withProperties: [ "type": note.kind.rawValue,
                                                                              "already_read": note.read ])
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


// MARK: - Reviews Tab Badge Updates
//
private extension MainTabBarController {

    /// Setup: KVO Hooks.
    ///
    func startListeningToReviewsTabBadgeUpdates() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(loadReviewsTabNotificationCountAndUpdateBadge),
                                               name: .reviewsBadgeReloadRequired,
                                               object: nil)
    }

    @objc func loadReviewsTabNotificationCountAndUpdateBadge() {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        let action = NotificationCountAction.load(siteID: siteID, type: .kind(.comment)) { [weak self] count in
            self?.updateReviewsTabBadge(count: count)
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Displays or Hides the Dot on the Reviews tab, depending on the notification count
    ///
    func updateReviewsTabBadge(count: Int) {
        let tab = WooTab.reviews
        let tabIndex = tab.visibleIndex()
        notificationsBadge.badgeCountWasUpdated(newValue: count, tab: tab, in: tabBar, tabIndex: tabIndex)
    }
}

// MARK: - Orders Tab Badge

private extension MainTabBarController {
    func startListeningToOrdersBadge() {
        viewModel.onBadgeReload = { [weak self] countReadableString in
            guard let self = self else {
                return
            }

            let tab = WooTab.orders
            let tabIndex = tab.visibleIndex()

            guard let orderTab: UITabBarItem = self.tabBar.items?[tabIndex] else {
                return
            }

            orderTab.badgeValue = countReadableString
            orderTab.badgeColor = .primary
        }

        viewModel.startObservingOrdersCount()
    }
}
