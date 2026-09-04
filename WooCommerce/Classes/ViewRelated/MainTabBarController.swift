import Combine
import EventHorizonSDK
import SwiftUI
import UIKit
import Yosemite
import WordPressUI
import Experiments
import enum WooFoundationCore.BuildConfiguration
import protocol WooFoundation.Analytics
import protocol PointOfSale.POSEntryPointEligibilityCheckerProtocol
import enum PointOfSale.POSLockStateKey
import struct PointOfSale.POSHTTPSConfigurationNotice


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

    /// Bookings Tab
    ///
    case bookings

    /// Point of Sale Tab
    ///
    case pointOfSale

    /// Hub Menu Tab
    ///
    case hubMenu
}

extension WooTab {
    /// Initializes a tab with the visible tab index.
    ///
    /// - Parameters:
    ///   - visibleIndex: the index of visible tabs on the tab bar
    ///   - isPOSTabVisible: indicates if the Point of Sale tab is visible.
    ///   - isBookingsTabVisible: indicates if the Bookings tab is visible.
    init(visibleIndex: Int, isPOSTabVisible: Bool, isBookingsTabVisible: Bool = false) {
        let tabs = WooTab.visibleTabs(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)
        self = tabs[visibleIndex]
    }

    /// Returns the visible tab index.
    /// - Parameters:
    ///   - isPOSTabVisible: indicates if the Point of Sale tab is visible.
    ///   - isBookingsTabVisible: indicates if the Bookings tab is visible.
    func visibleIndex(isPOSTabVisible: Bool, isBookingsTabVisible: Bool = false) -> Int {
        let tabs = WooTab.visibleTabs(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)
        guard let tabIndex = tabs.firstIndex(where: { $0 == self }) else {
            assertionFailure("Trying to get the visible tab index for tab \(self) while the visible tabs are: \(tabs)")
            return 0
        }
        return tabIndex
    }

    /// Note: currently only the Dashboard tab (My Store) view controller is set up in Main.storyboard.
    ///
    /// - Parameters:
    ///   - isPOSTabVisible: indicates if the Point of Sale tab is visible.
    ///   - isBookingsTabVisible: indicates if the Bookings tab is visible.
    /// - Returns: visible tabs in the tab bar.
    static func visibleTabs(isPOSTabVisible: Bool, isBookingsTabVisible: Bool = false) -> [WooTab] {
        var tabs: [WooTab] = [.myStore, .orders, .products]

        if isBookingsTabVisible {
            tabs.append(.bookings)
        }

        if isPOSTabVisible {
            tabs.append(.pointOfSale)
        }

        tabs.append(.hubMenu)
        return tabs
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
    override public var childForStatusBarStyle: UIViewController? {
        return nil
    }

    /// Used for overriding the status bar style for all child view controllers
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }

    /// ViewModel
    ///
    private let viewModel = MainTabViewModel()
    private let httpsConfigurationWarningViewModel: HTTPSConfigurationWarningViewModel
    private lazy var httpsConfigurationWarningPresenter = HTTPSConfigurationWarningPresenter(
        viewModel: httpsConfigurationWarningViewModel,
        presentingViewController: self,
        tabViewController: { [weak self] tab in
            self?.rootTabViewController(tab: tab)
        },
        visibleTabs: { [weak self] in
            guard let self else { return [] }
            return WooTab.visibleTabs(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)
        },
        selectedTab: { [weak self] in
            guard let self else { return nil }
            return WooTab(visibleIndex: selectedIndex,
                          isPOSTabVisible: isPOSTabVisible,
                          isBookingsTabVisible: isBookingsTabVisible)
        },
        onAction: { [weak self] in
            guard let self else { return }
            WebviewHelper.launch(HTTPSConfigurationWarningContent.helpURL, with: self)
        }
    )

    /// Warns the merchant when the selected store can't be reached. Hosted here so it overlays every
    /// tab, and stays put while the merchant navigates.
    ///
    private lazy var storeConnectionErrorViewModel = StoreConnectionErrorViewModel(stores: stores)
    private var storeConnectionErrorSubscription: AnyCancellable?
    /// Held strongly: assigning `viewControllers` makes UIKit drop every child that is not a tab, and a
    /// weak reference would go nil while the warning's view is still on screen.
    private var storeConnectionErrorModal: UIViewController?

    /// Tab view controllers
    ///
    private let dashboardNavigationController = WooTabNavigationController()
    private let ordersContainerController = TabContainerController()

    private let productsContainerController = TabContainerController()

    private let posContainerController = TabContainerController()
    private var posTabCoordinator: POSTabCoordinator?

    /// One-shot signal that the POS tab should auto-reopen at cold launch if the persisted
    /// lock state for the active site is true. Flipped to false after the first attempt so
    /// subsequent site switches don't keep yanking the user back into POS.
    private var needsPOSAutoReopenCheck = true

    private let bookingsContainerController = TabContainerController()

    private let hubMenuContainerController = TabContainerController()
    private var hubMenuTabCoordinator: HubMenuCoordinator?

    private var cancellableSiteID: AnyCancellable?
    private var cancellableSite: AnyCancellable?
    private var cancellableForeground: AnyCancellable?

    /// The site currently driving the conditional tabs, re-checked when the app enters the foreground.
    private var conditionalTabsSite: Site?
    private let featureFlagService: FeatureFlagService
    private let noticePresenter: NoticePresenter
    private let productImageUploader: ProductImageUploaderProtocol
    private let stores: StoresManager
    private let analytics: Analytics
    private let posTabVisibilityCheckerFactory: ((_ site: Site) -> POSTabVisibilityCheckerProtocol)
    private let posEligibilityService: POSEligibilityServiceProtocol
    private let bookingsEligibilityCheckerFactory: ((_ site: Site) -> BookingsTabEligibilityCheckerProtocol)
    private let userDefaults: UserDefaults
    private let isPad: Bool

    private var productImageUploadErrorsSubscription: AnyCancellable?

    private var posTabVisibilityChecker: POSTabVisibilityCheckerProtocol?
    private var posEligibilityCheckTask: Task<Void, Never>?

    /// periphery: ignore - keeping strong ref of the checker to keep its async task alive
    private var bookingsEligibilityChecker: BookingsTabEligibilityCheckerProtocol?
    private var bookingsEligibilityCheckTask: Task<Void, Never>?

    private var isPOSTabVisible: Bool = false
    private var isBookingsTabVisible: Bool = false
    private var isBookingsFeatureAvailable: Bool = false

    /// periphery: ignore - used in tests
    init?(coder: NSCoder,
          featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
          noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
          productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
          analytics: Analytics = ServiceLocator.analytics,
          stores: StoresManager = ServiceLocator.stores,
          posTabVisibilityCheckerFactory: ((Site) -> POSTabVisibilityCheckerProtocol)? = nil,
          posEligibilityService: POSEligibilityServiceProtocol = POSEligibilityService(),
          bookingsEligibilityCheckerFactory: ((Site) -> BookingsTabEligibilityCheckerProtocol)? = nil,
          userDefaults: UserDefaults = .standard,
          // Injected for mocking in tests.
          isPad: Bool? = nil) {
        self.featureFlagService = featureFlagService
        self.noticePresenter = noticePresenter
        self.productImageUploader = productImageUploader
        self.analytics = analytics
        self.stores = stores
        self.httpsConfigurationWarningViewModel = HTTPSConfigurationWarningViewModel(stores: stores)
        self.posTabVisibilityCheckerFactory = posTabVisibilityCheckerFactory ?? { site in
            POSTabVisibilityChecker(site: site)
        }
        self.posEligibilityService = posEligibilityService
        self.bookingsEligibilityCheckerFactory = bookingsEligibilityCheckerFactory ?? { site in
            BookingsTabEligibilityChecker(site: site)
        }
        self.userDefaults = userDefaults
        self.isPad = isPad ?? UIDevice.isPad()
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        let featureFlagService = ServiceLocator.featureFlagService
        self.featureFlagService = featureFlagService
        self.noticePresenter = ServiceLocator.noticePresenter
        self.productImageUploader = ServiceLocator.productImageUploader
        self.analytics = ServiceLocator.analytics
        self.stores = ServiceLocator.stores
        self.httpsConfigurationWarningViewModel = HTTPSConfigurationWarningViewModel(stores: ServiceLocator.stores)
        self.posTabVisibilityCheckerFactory = { site in
            POSTabVisibilityChecker(site: site)
        }
        self.posEligibilityService = POSEligibilityService()
        self.bookingsEligibilityCheckerFactory = { site in
            BookingsTabEligibilityChecker(site: site)
        }
        self.userDefaults = .standard
        self.isPad = UIDevice.isPad()
        super.init(coder: coder)
    }

    deinit {
        cancellableSiteID?.cancel()
        posEligibilityCheckTask?.cancel()
        bookingsEligibilityCheckTask?.cancel()
    }

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate() // call this to refresh status bar changes happening at runtime

        delegate = self

        // Setup initial visibility for conditional tabs (POS, Bookings)
        setupConditionalTabsInitialVisibility()

        observeSiteIDForViewControllers()
        observeSiteForConditionalTabs()
        httpsConfigurationWarningPresenter.start()
        observeStoreConnectionError()
        observeProductImageUploadStatusUpdates()

        startListeningToHubMenuTabBadgeUpdates()

        configureTabBarLayoutOnIpad()
        observeTraitChanges()
    }

    private func observeTraitChanges() {
        registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) { (self: Self, _) in
            self.configureTabBarLayoutOnIpad()
        }

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.refreshLiquidGlassTabBarAppearanceOnIpad()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        /// Note:
        /// We hook up KVO in this spot... because at the point in which `viewDidLoad` fires, we haven't really fully
        /// loaded the childViewControllers, and the tabBar isn't fully initialized.
        ///

        startListeningToOrdersBadge()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.onViewDidAppear()
        httpsConfigurationWarningPresenter.update()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { [weak self] _ in
            self?.configureTabBarLayoutOnIpad()
        } completion: { [weak self] _ in
            self?.configureTabBarLayoutOnIpad()
            self?.httpsConfigurationWarningPresenter.update()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        configureLiquidGlassTabBarLayoutOnIpad()
        httpsConfigurationWarningPresenter.update()
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let currentlySelectedTab = WooTab(visibleIndex: selectedIndex, isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)
        guard let userSelectedIndex = tabBar.items?.firstIndex(of: item) else {
                return
        }
        let userSelectedTab = WooTab(visibleIndex: userSelectedIndex, isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)

        // Did we reselect the already-selected tab?
        if currentlySelectedTab == userSelectedTab {
            trackTabReselected(tab: userSelectedTab)
            handleTabReselection()
        } else {
            trackTabSelected(newTab: userSelectedTab)
        }
        httpsConfigurationWarningPresenter.selectedTabDidChange(to: userSelectedTab)
    }

    // MARK: - Public Methods

    /// Switches the TabBarController to the specified Tab
    ///
    func navigateTo(_ tab: WooTab, animated: Bool = false, completion: (() -> Void)? = nil) {
        navigateToTabWithViewController(tab, animated: animated) { _ in
            completion?()
        }
    }

    /// Switches the TabBarController to the specified tab and pops to root of the tab if the root is a `UINavigationController`.
    ///
    /// - Parameters:
    ///   - tab: The tab to switch to.
    ///   - animated: Whether the tab switch is animated.
    ///   - completion: Invoked when switching to the tab's root screen is complete with the root view controller.
    func navigateToTabWithViewController(_ tab: WooTab, animated: Bool = false, completion: ((UIViewController) -> Void)? = nil) {
        dismiss(animated: animated) { [weak self] in
            guard let self else { return }
            httpsConfigurationWarningPresenter.update(for: tab)
            selectedIndex = tab.visibleIndex(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)
            guard let selectedViewController else {
                return
            }
            if let navController = selectedViewController as? UINavigationController {
                navController.popToRootViewController(animated: animated) {
                    completion?(navController)
                }
            } else {
                completion?(selectedViewController)
            }
        }
    }

    /// Removes the view controllers in each tab's navigation controller, and resets any logged in properties.
    /// Called after the app is logged out and authentication UI is presented.
    func removeViewControllers() {
        viewControllers?.compactMap { $0 as? UINavigationController }.forEach { navigationController in
            navigationController.viewControllers = []
        }
        hubMenuTabCoordinator = nil
    }

    // MARK: - iPadOS tabs support

    /// Uses the native iPad tab bar layout on iPadOS 26 and keeps the compact trait override as a fallback on iPadOS 18-25.
    ///
    /// The fallback overrides the tab bar controller trait collection to compact to show the same bottom tab layout as on iPhone,
    /// while restoring the real window size class for the tab bar and child view controllers so split-view layouts still work.
    private func configureTabBarLayoutOnIpad() {
        guard #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        if #available(iOS 26.0, *) {
            configureLiquidGlassTabBarLayoutOnIpad()
            return
        }

        traitOverrides.horizontalSizeClass = .compact
        if let rootHorizontalSizeClass = UIApplication.wooKeyWindow?.traitCollection.horizontalSizeClass {
            tabBar.traitOverrides.horizontalSizeClass = rootHorizontalSizeClass
            viewControllers?.forEach { viewController in
                viewController.traitOverrides.horizontalSizeClass = rootHorizontalSizeClass
            }
        }
    }

    private func clearTabBarTraitOverridesOnIpad() {
        traitOverrides.horizontalSizeClass = .unspecified
        tabBar.traitOverrides.horizontalSizeClass = .unspecified
        viewControllers?.forEach { viewController in
            viewController.traitOverrides.horizontalSizeClass = .unspecified
        }
    }

    private func configureLiquidGlassTabBarLayoutOnIpad() {
        guard #available(iOS 26.0, *),
              UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        mode = .tabBar
        tabBar.isTranslucent = true
        refreshLiquidGlassTabBarAppearanceOnIpad()
        clearTabBarTraitOverridesOnIpad()
    }

    private func refreshLiquidGlassTabBarAppearanceOnIpad() {
        guard #available(iOS 26.0, *),
              UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        let appearance = UITabBar.wooAppearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    private func setupConditionalTabsInitialVisibility() {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            return
        }

        setupConditionalTabsInitialVisibility(for: siteID)
    }

    private func setupConditionalTabsInitialVisibility(for siteID: Int64) {
        let isPOSTabVisible = POSTabVisibilityChecker.checkInitialVisibility(
            for: siteID,
            userInterfaceIdiom: isPad ? .pad : .phone,
            eligibilityService: posEligibilityService
        )
        let isBookingsTabVisible = shouldShowBookingsTab(
            isPOSTabVisible: isPOSTabVisible,
            bookingsFeatureAvailable: false
        )

        updateTabViewControllers(
            isPOSTabVisible: isPOSTabVisible,
            isBookingsTabVisible: isBookingsTabVisible
        )
    }
}

// MARK: - UITabBarControllerDelegate
//
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let isSelectingPOSTab = viewController == posContainerController
        if isSelectingPOSTab {
            posTabCoordinator?.openPOS(entryPoint: .posTab)
        }
        return !isSelectingPOSTab
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


// MARK: - Tab re-selection
//
extension MainTabBarController {

    func handleTabReselection() {
        guard let selectedViewController else {
            return
        }
        let content = (selectedViewController as? TabContainerController)?.wrappedController ?? selectedViewController

        guard let navigationController = content as? UINavigationController else {
            (content as? TabReselectionHandling)?.handleTabReselection()
            return
        }

        // A refused pop skips the root's own reset, so its guarded screens are never bypassed.
        guard navigationController.popToRootOrScrollToTop(animated: true) else {
            return
        }
        (navigationController.viewControllers.first as? TabReselectionHandling)?.handleTabReselection()
    }
}

// MARK: - Static navigation helpers
//
private extension MainTabBarController {

    /// Tracks "Tab Selected" Events.
    ///
    func trackTabSelected(newTab: WooTab) {
        switch newTab {
        case .myStore:
            ServiceLocator.analytics.track(.dashboardSelected)
        case .orders:
            ServiceLocator.analytics.track(event: .Orders.ordersSelected())
        case .products:
            ServiceLocator.analytics.track(event: .Products.productListSelected())
        case .bookings:
            ServiceLocator.analytics.track(Event.mainTabBookingsSelect())
        case .hubMenu:
            ServiceLocator.analytics.track(.hubMenuTabSelected)
        case .pointOfSale:
            ServiceLocator.analytics.track(.pointOfSaleTabSelected)
        }
    }

    /// Tracks "Tab Re Selected" Events.
    ///
    func trackTabReselected(tab: WooTab) {
        switch tab {
        case .myStore:
            ServiceLocator.analytics.track(.dashboardReselected)
        case .orders:
            ServiceLocator.analytics.track(event: .Orders.ordersReselected())
        case .products:
            ServiceLocator.analytics.track(event: .Products.productListReselected())
        case .bookings:
            ServiceLocator.analytics.track(Event.mainTabBookingsReselect())
        case .hubMenu:
            ServiceLocator.analytics.track(.hubMenuTabReselected)
            break
        case .pointOfSale:
            assertionFailure("Point of Sale tab should not be reselected as it cannot be selected from `tabBarController(_:shouldSelect:)`.")
            break
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

    /// Switches to the Products tab and pops to the root view controller
    ///
    static func switchToProductsTab(completion: (() -> Void)? = nil) {
        navigateTo(.products, completion: completion)
    }

    /// Switches to the Hub Menu tab and pops to the root view controller
    ///
    static func switchToHubMenuTab(completion: ((HubMenuViewController?) -> Void)? = nil) {
        navigateTo(.hubMenu, completion: {
            let hubMenuViewController: HubMenuViewController? = {
                guard let hubMenuTabController = childViewController() as? TabContainerController,
                      let navigationController = hubMenuTabController.wrappedController as? UINavigationController,
                      let hubMenuViewController = navigationController.topViewController as? HubMenuViewController else {
                    DDLogError("⛔️ Could not switch to the Hub Menu")
                    return nil
                }
                return hubMenuViewController
            }()
            completion?(hubMenuViewController)
        })
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

    /// Presents the details  of a push notification.
    static func switchStoreIfNeededAndPresentNotificationDetails(notification: WooCommerce.PushNotification) {
        let siteID = notification.resolvedSiteID()
        showStore(with: siteID, onCompletion: { _ in
            presentNotificationDetails(for: notification)
        })
    }

    /// Presents the order details if the `note` is for an order push notification.
    ///
    private static func presentNotificationDetails(for notification: PushNotification) {
        switch notification.kind {
        case .storeOrder:
            switchToOrdersTab {
                ordersTabSplitViewWrapper()?.presentDetails(for: notification)
            }
        case .blazeApprovedNote, .blazeRejectedNote, .blazeCancelledNote, .blazePerformedNote:
           navigateToBlazeCampaignDetails(using: notification)
        case .storeStock:
            navigateToProductDetails(using: notification)
        default:
            break
        }

        ServiceLocator.analytics.track(.notificationOpened, withProperties: [ "type": notification.kind.rawValue,
                                                                              "already_read": notification.note?.read ?? false ])
    }

    private static func showStore(with siteID: Int64, onCompletion: @escaping (Bool) -> Void) {
        let stores = ServiceLocator.stores

        // Already showing that store, do nothing
        guard siteID != stores.sessionManager.defaultStoreID else {
            onCompletion(true)
            return
        }

        SwitchStoreUseCase(stores: stores).switchToStoreIfSiteIsStored(with: siteID) { siteChanged in
            guard siteChanged else {
                return onCompletion(false)
            }

            let presenter = SwitchStoreNoticePresenter(siteID: siteID)
            presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .switchingStores)

            onCompletion(true)
        }
    }

    static func presentAddProductFlow() {
        switchToProductsTab {
            let tabBar = AppDelegate.shared.tabBarController
            let productsContainerController = tabBar?.productsContainerController

            guard let productsSplitViewWrapperController = productsContainerController?.wrappedController as? ProductsSplitViewWrapperController else {
                return
            }

            productsSplitViewWrapperController.startProductCreation()
        }
    }

    static func navigateToOrderDetails(with orderID: Int64, siteID: Int64) {
        showStore(with: siteID, onCompletion: { storeIsShown in
            switchToOrdersTab {
                // It failed to show the order's store. We navigate to the orders tab and stop, as we cannot show the order details screen
                guard storeIsShown else {
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.screenTransitionsDelay) {
                    presentDetails(for: orderID, siteID: siteID)
                }
            }
        })
    }

    static func navigateToBlazeCampaignDetails(using notification: PushNotification) {
        guard notification.kind.isBlaze else {
            return
        }

        guard let siteID = notification.meta?.identifier(forKey: .site) else {
            DDLogError("## Notification with [\(String(describing: notification.noteID))] lacks its site ID!")
            return
        }

        guard let campaignID = notification.meta?.identifier(forKey: .campaignID) else {
            DDLogError("## Notification with [\(String(describing: notification.noteID))] lacks its campaign ID!")
            return
        }

        showStore(with: Int64(siteID), onCompletion: { storeIsShown in
            // It failed to show the campaign's store.
            guard storeIsShown else {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.blazeScreenTransitionsDelay) {
                switchToHubMenuTab() { hubMenuViewController in
                    hubMenuViewController?.showBlazeCampaign("\(campaignID)")
                }
            }
        })
    }

    static func navigateToProductDetails(using notification: PushNotification) {
        guard let productID = notification.meta?.identifier(forKey: .product) else {
            DDLogError("## Notification with [\(String(describing: notification.noteID))] lacks its product ID!")
            return
        }

        switchToProductsTab {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.screenTransitionsDelay) {
                presentProductDetails(productID: Int64(productID), siteID: notification.resolvedSiteID())
            }
        }
    }

    private static func presentProductDetails(productID: Int64, siteID: Int64) {
        guard let tabBar = AppDelegate.shared.tabBarController else {
            return
        }

        let model: ProductLoaderViewController.Model = .product(productID: productID)
        let productViewController = ProductLoaderViewController(model: model, siteID: siteID, forceReadOnly: false)
        let productNavController = WooNavigationController(rootViewController: productViewController)
        tabBar.rootTabViewController(tab: .products).present(productNavController, animated: true)
    }

    static func navigateToBlazeCampaignCreation(for siteID: Int64) {
        showStore(with: Int64(siteID), onCompletion: { storeIsShown in
            // It failed to show the campaign's store.
            guard storeIsShown else {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.blazeScreenTransitionsDelay) {
                switchToHubMenuTab() { hubMenuViewController in
                    hubMenuViewController?.showBlazeCampaignCreation()
                }
            }
        })
    }

    static func presentOrderCreationFlow(for customerID: Int64, billing: Address?, shipping: Address?) {
        switchToOrdersTab {
            let tabBar = AppDelegate.shared.tabBarController
            let ordersContainerController = tabBar?.ordersContainerController

            guard let ordersSplitViewWrapperController = ordersContainerController?.wrappedController as? OrdersSplitViewWrapperController else {
                return
            }

            ordersSplitViewWrapperController.presentOrderCreationFlow(for: customerID, billing: billing, shipping: shipping)
        }
    }

    private static func presentDetails(for orderID: Int64, siteID: Int64) {
        ordersTabSplitViewWrapper()?.presentDetails(for: orderID, siteID: siteID)
    }

    private static func ordersTabSplitViewWrapper() -> OrdersSplitViewWrapperController? {
        guard let ordersTabController = childViewController() as? TabContainerController,
              let ordersSplitViewWrapperController = ordersTabController.wrappedController as? OrdersSplitViewWrapperController else {
            return nil
        }
        return ordersSplitViewWrapperController
    }

    static func presentPayments() {
        switchToHubMenuTab() { hubMenuViewController in
            hubMenuViewController?.showPaymentsMenu()
        }
    }

    static func presentCoupons() {
        switchToHubMenuTab() { hubMenuViewController in
            hubMenuViewController?.showCoupons()
        }
    }

    /// Switches to the hub Menu & Navigates to the Privacy Settings Screen.
    ///
    static func navigateToPrivacySettings() {
        switchToHubMenuTab { hubMenuViewController in
            hubMenuViewController?.showPrivacySettings()
        }
    }
}

// MARK: - DeeplinkForwarder
//
extension MainTabBarController: DeepLinkNavigator {
    func navigate(to destination: any DeepLinkDestinationProtocol) {
        switch destination {
        case is HubMenuDestination,
            is PaymentsMenuDestination:
            navigateTo(.hubMenu) { [weak self] in
                self?.hubMenuTabCoordinator?.navigate(to: destination)
            }
        case is OrdersDestination:
            navigateTo(.orders) {
                Self.ordersTabSplitViewWrapper()?.navigate(to: destination)
            }
        case let analyticsDestination as AnalyticsHubDestination:
            navigateTo(.myStore) { [weak self] in
                self?.presentAnalyticsHub(for: analyticsDestination)
            }
        case is POSPromotionDestination:
            presentPOSPromotionModal()
        default:
            return
        }
    }

    private func presentAnalyticsHub(for destination: AnalyticsHubDestination) {
        let analyticsHubVC: AnalyticsHubHostingViewController
        switch destination {
        case .focusedCard(let card, let range):
            analyticsHubVC = AnalyticsHubHostingViewController(
                siteID: stores.sessionManager.defaultStoreID ?? 0,
                timeZone: .siteTimezone,
                selectionType: range,
                focusedCard: card,
                usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter()
            )
        case .defaultHub:
            analyticsHubVC = AnalyticsHubHostingViewController(
                siteID: stores.sessionManager.defaultStoreID ?? 0,
                timeZone: .siteTimezone,
                timeRange: .today,
                usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter()
            )
        }
        dashboardNavigationController.pushViewController(analyticsHubVC, animated: true)
    }

    private func presentPOSPromotionModal() {
        var pendingWebViewModel: WebViewSheetViewModel?

        let modalView = POSPromotionModal_UIKit(
            onDismiss: { [weak self] in
                self?.dismiss(animated: false) {
                    if let webViewModel = pendingWebViewModel {
                        self?.presentWebViewSheet(webViewModel)
                    }
                }
            },
            onShowWebView: { webViewModel in
                pendingWebViewModel = webViewModel
            }
        )
        let hostingController = UIHostingController(rootView: modalView)
        hostingController.view.backgroundColor = .clear
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        present(hostingController, animated: true)
    }

    private func observeStoreConnectionError() {
        storeConnectionErrorSubscription = storeConnectionErrorViewModel.$presentedSiteID
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak self] isPresented in
                isPresented ? self?.presentStoreConnectionErrorModal() : self?.dismissStoreConnectionErrorModal()
            }
    }

    /// Adds the warning as a child on top of the tab bar rather than presenting it.
    ///
    /// A presented view controller owns whatever it presents in turn, so a store that recovered while
    /// the merchant was filling in the support form would have taken that form down with it. As a child
    /// the warning covers every tab just the same, support is presented normally over it, and removing
    /// the warning never disturbs anything the merchant has open.
    ///
    private func presentStoreConnectionErrorModal() {
        guard storeConnectionErrorModal == nil else {
            return
        }

        let modalView = StoreConnectionErrorModal(
            onContactSupport: { [weak self] in
                self?.presentStoreConnectionErrorSupportForm()
            },
            onDismiss: { [weak self] in
                self?.storeConnectionErrorViewModel.dismissTapped()
            }
        )
        let hostingController = UIHostingController(rootView: modalView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        // A presented view controller would hide what is behind it from VoiceOver on its own. A child
        // does not, so the tabs underneath stay reachable unless this says otherwise.
        hostingController.view.accessibilityViewIsModal = true

        addChild(hostingController)
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)

        storeConnectionErrorModal = hostingController
    }

    private func dismissStoreConnectionErrorModal() {
        guard let storeConnectionErrorModal else {
            return
        }
        self.storeConnectionErrorModal = nil
        storeConnectionErrorModal.willMove(toParent: nil)
        storeConnectionErrorModal.view.removeFromSuperview()
        storeConnectionErrorModal.removeFromParent()
    }

    /// Opens support over the warning, which stays behind it so the merchant returns to it afterwards.
    ///
    private func presentStoreConnectionErrorSupportForm() {
        let viewModel = SupportFormViewModel(sourceTag: StoreConnectionErrorSupport.sourceTag,
                                             additionalTags: StoreConnectionErrorSupport.additionalTags)
        SupportFormHostingController(viewModel: viewModel).show(from: self)
    }

    private func presentWebViewSheet(_ webViewModel: WebViewSheetViewModel) {
        let webViewSheet = WebViewSheet(viewModel: webViewModel, done: { [weak self] in
            self?.dismiss(animated: true)
        })
        let hostingController = UIHostingController(rootView: webViewSheet)
        present(hostingController, animated: true)
    }
}

// MARK: - Site ID observation for updating tab view controllers
//
private extension MainTabBarController {
    func observePOSEligibilityForPOSTabVisibility(site: Site) {
        let siteID = site.siteID

        // Configures POS tab coordinator once per logged in site session.
        let posTabVisibilityChecker = posTabVisibilityCheckerFactory(site)
        self.posTabVisibilityChecker = posTabVisibilityChecker

        // Sets POS tab initial visibility based on cached value if available.
        let initialVisibility = posTabVisibilityChecker.checkInitialVisibility()
        let isBookingsTabVisible = shouldShowBookingsTab(isPOSTabVisible: initialVisibility,
                                                         bookingsFeatureAvailable: isBookingsFeatureAvailable)
        updateTabViewControllers(isPOSTabVisible: initialVisibility, isBookingsTabVisible: isBookingsTabVisible)

        // Cancels any existing task.
        posEligibilityCheckTask?.cancel()

        // Starts observing the POS eligibility state.
        posEligibilityCheckTask = Task { @MainActor [weak self] in
            guard let self, let posTabVisibilityChecker = self.posTabVisibilityChecker else { return }
            let isPOSTabVisible = await posTabVisibilityChecker.checkVisibility()
            // Cancellation ends the checker's site-settings wait early, so a superseded task resumes
            // with an indeterminate verdict — it must not cache it or rebuild the tab bar (WOOMOB-3915).
            guard !Task.isCancelled else { return }
            analytics.track(.pointOfSaleTabVisibilityChecked, withProperties: ["is_visible": isPOSTabVisible])
            cachePOSTabVisibility(siteID: siteID, isPOSTabVisible: isPOSTabVisible)
            let isBookingsTabVisible = shouldShowBookingsTab(isPOSTabVisible: isPOSTabVisible,
                                                             bookingsFeatureAvailable: isBookingsFeatureAvailable)
            updateTabViewControllers(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)
            viewModel.loadHubMenuTabBadge()

            // Update POS eligibility - coordinator will check actual eligibility if tab is visible
            posTabCoordinator?.updatePOSEligibility(isPOSTabVisible: isPOSTabVisible)
        }
    }

    func updateTabViewControllers(isPOSTabVisible: Bool, isBookingsTabVisible: Bool = false) {
        guard isPOSTabVisible != self.isPOSTabVisible || isBookingsTabVisible != self.isBookingsTabVisible || (viewControllers?.count ?? 0) == 0 else {
            return
        }
        var controllers = [UIViewController]()
        let tabs = WooTab.visibleTabs(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)
        tabs.forEach { tab in
            let tabIndex = tab.visibleIndex(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)
            let tabViewController = rootTabViewController(tab: tab)
            controllers.insert(tabViewController, at: tabIndex)
        }
        viewControllers = controllers
        self.isPOSTabVisible = isPOSTabVisible
        self.isBookingsTabVisible = isBookingsTabVisible
        httpsConfigurationWarningPresenter.updateAll()
        reattachStoreConnectionErrorModalIfNeeded()
    }

    /// Assigning `viewControllers` removes the warning from the children while leaving its view in
    /// place. Reclaim it so it keeps receiving trait and lifecycle updates, stays above the rebuilt tabs,
    /// and can still be removed later.
    ///
    private func reattachStoreConnectionErrorModalIfNeeded() {
        guard let storeConnectionErrorModal, storeConnectionErrorModal.parent == nil else {
            return
        }
        addChild(storeConnectionErrorModal)
        view.bringSubviewToFront(storeConnectionErrorModal.view)
        storeConnectionErrorModal.didMove(toParent: self)
    }

    func rootTabViewController(tab: WooTab) -> UIViewController {
        switch tab {
            case .myStore:
                return dashboardNavigationController
            case .orders:
                return ordersContainerController
            case .products:
                return productsContainerController
            case .bookings:
                return bookingsContainerController
            case .hubMenu:
                return hubMenuContainerController
            case .pointOfSale:
                return posContainerController
        }
    }

    func observeSiteForConditionalTabs() {
        cancellableSite = stores.site
            .compactMap { $0 }
            .sink { [weak self] site in
                guard let self else {
                    return
                }

                conditionalTabsSite = site
                httpsConfigurationWarningViewModel.update(site: site,
                                                          fallbackSiteAddress: stores.sessionManager.defaultCredentials?.siteAddress)
                observePOSEligibilityForPOSTabVisibility(site: site)
                observeBookingsEligibilityForBookingsTabVisibility(site: site)
            }

        // Re-validates POS visibility and eligibility whenever the app returns to the foreground,
        // like Android's onResume re-check. POS entry relies on locally recorded eligibility, so
        // this checkpoint is what detects a store that became ineligible while the app was inactive.
        cancellableForeground = NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self, let site = conditionalTabsSite else {
                    return
                }
                httpsConfigurationWarningViewModel.update(site: site,
                                                          fallbackSiteAddress: stores.sessionManager.defaultCredentials?.siteAddress)
                observePOSEligibilityForPOSTabVisibility(site: site)
            }
    }

    func observeSiteIDForViewControllers() {
        cancellableSiteID = stores.siteID.sink { [weak self] siteID in
            guard let self else {
                return
            }
            self.updateViewControllers(siteID: siteID)
        }
    }

    func updateViewControllers(siteID: Int64?) {
        guard let siteID else {
            return
        }

        // Update conditional tabs initial state for the `siteID`
        setupConditionalTabsInitialVisibility(for: siteID)

        // Update view model with `siteID` to query correct Orders Status
        viewModel.configureOrdersStatusesListener(for: siteID)

        // Initialize each tab's root view controller
        let dashboardViewController = createDashboardViewController(siteID: siteID)
        dashboardNavigationController.viewControllers = [dashboardViewController]

        ordersContainerController.wrappedController = createOrdersViewController(siteID: siteID)

        productsContainerController.wrappedController = ProductsSplitViewWrapperController(siteID: siteID)

        // Configure hub menu tab coordinator once per logged in session potentially with multiple sites.
        if hubMenuTabCoordinator == nil {
            let hubTabCoordinator = createHubMenuTabCoordinator()
            self.hubMenuTabCoordinator = hubTabCoordinator
        }
        hubMenuTabCoordinator?.activate(siteID: siteID)

        // Sets dashboard to be the default tab.
        selectedIndex = WooTab.myStore.visibleIndex(isPOSTabVisible: isPOSTabVisible,
                                                    isBookingsTabVisible: isBookingsTabVisible)

        // Create POS tab coordinator with eligibility service from stores
        let coordinator = POSTabCoordinator(
            siteID: siteID,
            tabContainerController: posContainerController,
            viewControllerToPresent: self,
            storesManager: stores,
            eligibilityChecker: POSTabEligibilityChecker(siteID: siteID),
            localCatalogEligibilityService: stores.posCatalogEligibilityChecker,
            httpsConfigurationNoticeProvider: { [weak self] in
                guard let self, httpsConfigurationWarningViewModel.isVisible else {
                    return nil
                }
                return POSHTTPSConfigurationNotice(
                    title: HTTPSConfigurationWarningContent.title,
                    message: HTTPSConfigurationWarningContent.message,
                    actionTitle: HTTPSConfigurationWarningContent.actionTitle,
                    onAction: { [weak self] in
                        guard let self,
                              let presenter = presentedViewController else { return }
                        WebviewHelper.launch(HTTPSConfigurationWarningContent.helpURL, with: presenter)
                    },
                    onDismiss: { [weak self] in
                        self?.httpsConfigurationWarningViewModel.dismiss()
                    }
                )
            }
        )
        posTabCoordinator = coordinator
        autoReopenPOSIfNeeded(siteID: siteID)

        // Setup bookings wrapped view controller
        let bookingsViewController = createBookingsViewController(siteID: siteID)
        bookingsContainerController.wrappedController = bookingsViewController

        // Updates site ID for the bookings tab to display correct bookings
        (bookingsContainerController.wrappedController as? BookingsTabViewHostingController)?.didSwitchStore(id: siteID)

        httpsConfigurationWarningPresenter.updateAll()
    }

    func createDashboardViewController(siteID: Int64) -> UIViewController {
        DashboardViewHostingController(siteID: siteID)
    }

    func createOrdersViewController(siteID: Int64) -> UIViewController {
        OrdersSplitViewWrapperController(siteID: siteID)
    }

    func createBookingsViewController(siteID: Int64) -> UIViewController {
        BookingsTabViewHostingController(siteID: siteID)
    }

    func createHubMenuTabCoordinator() -> HubMenuCoordinator {
        HubMenuCoordinator(tabContainerController: hubMenuContainerController,
                           storesManager: stores,
                           httpsConfigurationWarningViewModel: httpsConfigurationWarningViewModel,
                           tapToPayBadgePromotionChecker: viewModel.tapToPayBadgePromotionChecker,
                           willPresentReviewDetailsFromPushNotification: { [weak self] in
            await withCheckedContinuation { [weak self] continuation in
                self?.navigateTo(.hubMenu) {
                    continuation.resume(returning: ())
                }
            }
        })
    }

    func observeBookingsEligibilityForBookingsTabVisibility(site: Site) {
        let bookingsEligibilityChecker = bookingsEligibilityCheckerFactory(site)
        self.bookingsEligibilityChecker = bookingsEligibilityChecker

        // Cancels any existing task.
        bookingsEligibilityCheckTask?.cancel()

        // Starts observing the Bookings eligibility state.
        bookingsEligibilityCheckTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let isBookingsFeatureAvailable = await bookingsEligibilityChecker.checkVisibility()
            // TODO: Add analytics tracking for bookings tab visibility
            self.isBookingsFeatureAvailable = isBookingsFeatureAvailable
            let isBookingsTabVisible = shouldShowBookingsTab(isPOSTabVisible: isPOSTabVisible,
                                                             bookingsFeatureAvailable: isBookingsFeatureAvailable)
            updateTabViewControllers(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)
        }
    }
}

private extension MainTabBarController {
    func shouldShowBookingsTab(isPOSTabVisible: Bool, bookingsFeatureAvailable: Bool) -> Bool {
        guard bookingsFeatureAvailable else {
            return false
        }
        return isPad ? !isPOSTabVisible : true
    }
}

// MARK: - Hub Menu Tab Badge Updates
//
private extension MainTabBarController {

    /// Setup: KVO Hooks.
    ///
    func startListeningToHubMenuTabBadgeUpdates() {
        viewModel.onMenuBadgeShouldBeDisplayed = { [weak self] type in
            self?.updateMenuTabBadge(with: .show(type: type))
        }

        viewModel.onMenuBadgeShouldBeHidden = { [weak self] in
            self?.updateMenuTabBadge(with: .hide)
        }
    }

    func updateMenuTabBadge(with action: NotificationBadgeActionType) {
        let tab = WooTab.hubMenu
        let tabIndex = tab.visibleIndex(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)

        switch action {
        case .show:
            tabBar.items?[tabIndex].badgeValue = "•"
        case .hide:
            tabBar.items?[tabIndex].badgeValue = nil
        }
    }
}

// MARK: - Orders Tab Badge

private extension MainTabBarController {
    func startListeningToOrdersBadge() {
        viewModel.onOrdersBadgeReload = { [weak self] countReadableString in
            guard let self else {
                return
            }

            let tab = WooTab.orders
            let tabIndex = tab.visibleIndex(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)

            guard let orderTab: UITabBarItem = self.tabBar.items?[safe: tabIndex] else {
                return
            }

            orderTab.badgeValue = countReadableString
        }

        viewModel.startObservingOrdersCount()
    }
}

// MARK: - Background Product Image Upload Status Updates

private extension MainTabBarController {
    func observeProductImageUploadStatusUpdates() {
        productImageUploadErrorsSubscription = productImageUploader.errors.sink { [weak self] error in
            guard let self else { return }
            switch error.error {
            case .failedSavingProductAfterImageUpload:
                self.handleErrorSavingProductAfterImageUpload(error)
            case .failedUploadingImage, .noActionHandlerFound, .noRemoteProductIDFound:
                self.handleErrorUploadingImage(error)
            }
        }
    }

    func handleErrorSavingProductAfterImageUpload(_ error: ProductImageUploadErrorInfo) {
        let noticeTitle: String = {
            switch error.productOrVariationID {
            case .product:
                return Localization.productImagesSavingFailureNoticeTitle
            case .variation:
                return Localization.variationImageSavingFailureNoticeTitle
            }
        }()
        let notice = Notice(title: noticeTitle,
                            subtitle: nil,
                            message: nil,
                            feedbackType: .error,
                            notificationInfo: nil,
                            actionTitle: Localization.imageUploadFailureNoticeActionTitle,
                            actionHandler: { [weak self] in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.showProductDetails(for: error)
                self.analytics.track(event: .ImageUpload
                    .failureSavingProductAfterImageUploadNoticeTapped(productOrVariation: error.productOrVariationEventProperty))
            }
        })
        let canNoticeBeDisplayed = noticePresenter.enqueue(notice: notice)
        if canNoticeBeDisplayed {
            analytics.track(event: .ImageUpload
                .failureSavingProductAfterImageUploadNoticeShown(productOrVariation: error.productOrVariationEventProperty))
        }
    }

    func handleErrorUploadingImage(_ error: ProductImageUploadErrorInfo) {
        let notice = Notice(title: Localization.imageUploadFailureNoticeTitle,
                            subtitle: nil,
                            message: nil,
                            feedbackType: .error,
                            notificationInfo: nil,
                            actionTitle: Localization.imageUploadFailureNoticeActionTitle,
                            actionHandler: { [weak self] in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.showProductDetails(for: error)
                self.analytics.track(event: .ImageUpload
                    .failureUploadingImageNoticeTapped(productOrVariation: error.productOrVariationEventProperty))
            }
        })
        let canNoticeBeDisplayed = noticePresenter.enqueue(notice: notice)
        if canNoticeBeDisplayed {
            analytics.track(event: .ImageUpload
                .failureUploadingImageNoticeShown(productOrVariation: error.productOrVariationEventProperty))
        }
    }

    func showProductDetails(for error: ProductImageUploadErrorInfo) async {
        // Switches to the correct store first if needed.
        let switchStoreUseCase = SwitchStoreUseCase(stores: stores)
        let siteChanged = await switchStoreUseCase.switchStore(with: error.siteID)
        if siteChanged {
            let presenter = SwitchStoreNoticePresenter(siteID: error.siteID,
                                                       noticePresenter: self.noticePresenter)
            presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .switchingStores)
        }

        if let productsSplitViewWrapperController = productsContainerController.wrappedController as? ProductsSplitViewWrapperController,
           let productForm = productsSplitViewWrapperController.currentProductForm(for: error.productOrVariationID.id) {
            // Ask the product form to display an alert about the error
            return productForm.handleProductUploadError(error)
        }

        let model: ProductLoaderViewController.Model = {
            switch error.productOrVariationID {
            case .product(let id):
                return .product(productID: id)
            case .variation(let productID, let variationID):
                return .productVariation(productID: productID, variationID: variationID)
            }
        }()
        let productViewController = ProductLoaderViewController(model: model,
                                                                siteID: error.siteID,
                                                                forceReadOnly: false)
        let productNavController = WooNavigationController(rootViewController: productViewController)
        rootTabViewController(tab: .products).present(productNavController, animated: true)
    }
}

private extension MainTabBarController {
    func cachePOSTabVisibility(siteID: Int64, isPOSTabVisible: Bool) {
        posEligibilityService.cachePOSTabVisibility(siteID: siteID, isVisible: isPOSTabVisible)
    }
}

private extension MainTabBarController {
    /// Reopen POS on cold launch if the active site's persisted key says it was locked.
    func autoReopenPOSIfNeeded(siteID: Int64) {
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleRoles) else { return }
        guard needsPOSAutoReopenCheck else { return }
        // Consume the one-shot only when the active site is the locked one.
        guard userDefaults.bool(forKey: POSLockStateKey.key(for: siteID)) else { return }
        needsPOSAutoReopenCheck = false

        // Capture the just-created coordinator weakly so a site change between
        // scheduling and execution can't redirect this auto-reopen at a different
        // coordinator. If the active site changes mid-flight the old coordinator
        // is released and the closure no-ops.
        DispatchQueue.main.async { [weak coordinator = posTabCoordinator] in
            coordinator?.openPOS(entryPoint: .autoReopen)
        }
    }
}

private extension MainTabBarController {
    enum Constants {
        // Used to delay a second navigation after the previous one is called,
        // to ensure that the first transition is finished. Without this delay
        // the second one might not happen.
        static let screenTransitionsDelay = 0.3
        static let blazeScreenTransitionsDelay = 1.0
    }
}

extension MainTabBarController {
    enum Localization {
        static let imageUploadFailureNoticeTitle =
        NSLocalizedString("An image failed to upload",
                          comment: "Title of the notice about an image upload failure in the background.")
        static let productImagesSavingFailureNoticeTitle =
        NSLocalizedString("Error saving product images",
                          comment: "Title of the notice about an error saving images uploaded in the background to a product.")
        static let variationImageSavingFailureNoticeTitle =
        NSLocalizedString("Error saving variation image",
                          comment: "Title of the notice about an error saving an image uploaded in the background to a product variation.")
        static let imageUploadFailureNoticeActionTitle =
        NSLocalizedString("View",
                          comment: "Title of the action to view product details from a notice about an image upload failure in the background.")
    }
}

private extension ProductImageUploadErrorInfo {
    var productOrVariationEventProperty: WooAnalyticsEvent.ImageUpload.ProductOrVariation {
        switch productOrVariationID {
        case .product:
            return .product
        case .variation:
            return .variation
        }
    }
}
