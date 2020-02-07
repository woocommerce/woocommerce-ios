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
         isProductListFeatureOn: Bool) {
        let tabs = WooTab.visibleTabs(isProductListFeatureOn: isProductListFeatureOn)
        self = tabs[visibleIndex]
    }

    /// Returns the visible tab index.
    func visibleIndex(isProductListFeatureOn: Bool) -> Int {
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

    /// KVO Token
    ///
    private var observationToken: NSKeyValueObservation?

    /// Notifications badge
    ///
    private let notificationsBadge = NotificationsBadgeController()

    /// ViewModel
    ///
    private let viewModel = MainTabViewModel()

    /// Products visibility
    ///
    private var isProductsTabVisible: Bool = false

    private lazy var productsTabViewController: UIViewController = {
        let productsViewController = ProductsViewController(nibName: nil, bundle: nil)
        let navController = WooNavigationController(rootViewController: productsViewController)
        let navigationTitle = NSLocalizedString("Products",
                                                comment: "Title of the Products tab — plural form of Product")
        navController.tabBarItem = UITabBarItem(title: navigationTitle,
                                                image: UIImage.productImage,
                                                tag: 0)
        return navController
    }()

    private lazy var ordersTabViewController: UIViewController = {
        let masterViewController = OrdersMasterViewController()
        return WooNavigationController(rootViewController: masterViewController)
    }()


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate() // call this to refresh status bar changes happening at runtime

        // Add the Orders tab
        viewControllers = {
            let index = WooTab.orders.visibleIndex(isProductListFeatureOn: isProductsTabVisible)
            var controllers = viewControllers ?? []
            controllers.insert(ordersTabViewController, at: index)
            return controllers
        }()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        /// Note:
        /// We hook up KVO in this spot... because at the point in which `viewDidLoad` fires, we haven't really fully
        /// loaded the childViewControllers, and the tabBar isn't fully initialized.
        ///
        startListeningToBadgeUpdatesIfNeeded()
        startListeningToOrdersBadge()
        startListeningToProductsVisibilityChanges()

        reloadProductListVisibility()
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let currentlySelectedTab = WooTab(visibleIndex: selectedIndex, isProductListFeatureOn: isProductsTabVisible)
        guard let userSelectedIndex = tabBar.items?.firstIndex(of: item) else {
                return
        }
        let userSelectedTab = WooTab(visibleIndex: userSelectedIndex, isProductListFeatureOn: isProductsTabVisible)

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
        selectedIndex = tab.visibleIndex(isProductListFeatureOn: isProductsTabVisible)
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
    func updateProductsTabVisibility(isVisible: Bool) {
        guard let existingViewControllers = viewControllers else {
            return
        }

        var tabViewControllers = existingViewControllers

        if isVisible {
            if !tabViewControllers.contains(productsTabViewController) {
                let productsTabIndex = WooTab.products.visibleIndex(isProductListFeatureOn: isVisible)
                tabViewControllers.insert(productsTabViewController, at: productsTabIndex)
            }
        } else {
            if tabViewControllers.contains(productsTabViewController) {
                let productsTabIndex = WooTab.products.visibleIndex(isProductListFeatureOn: isProductsTabVisible)
                tabViewControllers.remove(at: productsTabIndex)
            }
        }

        isProductsTabVisible = isVisible

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
            presentNotificationDetails(for: note)
        }
        ServiceLocator.stores.dispatch(action)
    }

    private static func presentNotificationDetails(for note: Note) {
        switch note.kind {
        case .storeOrder:
            switchToOrdersTab {
                guard let ordersMasterVC: OrdersMasterViewController = childViewController() else {
                    return
                }

                ordersMasterVC.presentDetails(for: note)
            }
        case .comment:
            switchToReviewsTab {
                guard let reviewsViewController: ReviewsViewController = childViewController() else {
                    return
                }
                reviewsViewController.presentDetails(for: note.noteID)
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
        let tab = WooTab.reviews
        let tabIndex = tab.visibleIndex(isProductListFeatureOn: isProductsTabVisible)
        notificationsBadge.badgeCountWasUpdated(newValue: newValue, tab: tab, in: tabBar, tabIndex: tabIndex)
    }
}

// MARK: - Orders Tab Badge

private extension MainTabBarController {
    func startListeningToOrdersBadge() {
        viewModel.onBadgeReload = { [weak self] countReadableString in
            guard let self = self,
            let badgeText = countReadableString else {
                return
            }

            let tab = WooTab.orders
            let tabIndex = tab.visibleIndex(isProductListFeatureOn: self.isProductsTabVisible)

            guard let orderTab: UITabBarItem = self.tabBar.items?[tabIndex] else {
                return
            }

            orderTab.badgeValue = badgeText
            orderTab.badgeColor = .primary
        }

        viewModel.startObservingOrdersCount()
    }
}

// MARK: Products Visibility Observation
//
private extension MainTabBarController {
    func startListeningToProductsVisibilityChanges() {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productList) else {
            return
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadProductListVisibility),
                                               name: .ProductsVisibilityDidChange,
                                               object: nil)
    }

    @objc func reloadProductListVisibility() {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productList) else {
            updateProductsTabVisibility(isVisible: false)
            return
        }

        let action = AppSettingsAction.loadProductsVisibility { [weak self] isVisible in
            self?.updateProductsTabVisibility(isVisible: isVisible)
        }
        ServiceLocator.stores.dispatch(action)
    }
}
