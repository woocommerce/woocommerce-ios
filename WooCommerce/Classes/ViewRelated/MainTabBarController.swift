import Combine
import UIKit
import Yosemite
import WordPressUI
import Experiments
import protocol WooFoundation.Analytics


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

    /// Hub Menu Tab
    ///
    case hubMenu
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
        [.myStore, .orders, .products, .hubMenu]
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
        .default
    }

    /// Notifications badge
    ///
    private let notificationsBadge = NotificationsBadgeController()

    /// ViewModel
    ///
    private let viewModel = MainTabViewModel()

    /// Tab view controllers
    ///
    private let dashboardNavigationController = WooTabNavigationController()
    private let ordersContainerController = TabContainerController()

    private let productsContainerController = TabContainerController()

    /// Unfortunately, we can't use the above container to directly hold a WooTabNavigationController, due to
    /// a longstanding bug where a black bar equal to the tab bar height is shown when a nav controller
    /// is shown as an embedded vc in a tab. See link for details, but the solutions don't work here.
    /// https://stackoverflow.com/questions/28608817/uinavigationcontroller-embedded-in-a-container-view-displays-a-table-view-contr
    /// remove when .splitViewInProductsTab is removed.
    private let productsNavigationController = WooTabNavigationController()

    private let reviewsNavigationController = WooTabNavigationController()
    private let hubMenuContainerController = TabContainerController()
    private var hubMenuTabCoordinator: HubMenuCoordinator?

    private var cancellableSiteID: AnyCancellable?
    private let featureFlagService: FeatureFlagService
    private let noticePresenter: NoticePresenter
    private let productImageUploader: ProductImageUploaderProtocol
    private let stores: StoresManager = ServiceLocator.stores
    private let analytics: Analytics

    private var productImageUploadErrorsSubscription: AnyCancellable?

    private lazy var isProductsSplitViewFeatureFlagOn = featureFlagService.isFeatureFlagEnabled(.splitViewInProductsTab)

    init?(coder: NSCoder,
          featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
          noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
          productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
          analytics: Analytics = ServiceLocator.analytics) {
        self.featureFlagService = featureFlagService
        self.noticePresenter = noticePresenter
        self.productImageUploader = productImageUploader
        self.analytics = analytics
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        self.featureFlagService = ServiceLocator.featureFlagService
        self.noticePresenter = ServiceLocator.noticePresenter
        self.productImageUploader = ServiceLocator.productImageUploader
        self.analytics = ServiceLocator.analytics
        super.init(coder: coder)
    }

    deinit {
        cancellableSiteID?.cancel()
    }

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate() // call this to refresh status bar changes happening at runtime

        configureTabViewControllers()
        observeSiteIDForViewControllers()
        observeProductImageUploadStatusUpdates()

        startListeningToHubMenuTabBadgeUpdates()
        viewModel.loadHubMenuTabBadge()
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
            selectedIndex = tab.visibleIndex()
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

    func presentCollectPayment() {
        navigateTo(.hubMenu) { [weak self] in
            self?.hubMenuTabCoordinator?.navigate(to: PaymentsMenuDestination.collectPayment)
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
            ServiceLocator.analytics.track(
                event: .Orders.ordersSelected(horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
        case .products:
            ServiceLocator.analytics.track(
                event: .Products.productListSelected(horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
        case .hubMenu:
            ServiceLocator.analytics.track(.hubMenuTabSelected)
            break
        }
    }

    /// Tracks "Tab Re Selected" Events.
    ///
    func trackTabReselected(tab: WooTab) {
        switch tab {
        case .myStore:
            ServiceLocator.analytics.track(.dashboardReselected)
        case .orders:
            ServiceLocator.analytics.track(
                event: .Orders.ordersReselected(horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
        case .products:
            ServiceLocator.analytics.track(
                event: .Products.productListReselected(horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
        case .hubMenu:
            ServiceLocator.analytics.track(.hubMenuTabReselected)
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

    /// Syncs the notification given the ID, and handles the notification based on its notification kind.
    ///
    static func presentNotificationDetails(for noteID: Int64) {
        let action = NotificationAction.synchronizeNotification(noteID: noteID) { note, error in
            guard let note = note else {
                return
            }
            let siteID = Int64(note.meta.identifier(forKey: .site) ?? Int.min)

            showStore(with: siteID, onCompletion: { _ in
                presentNotificationDetails(for: note)
            })
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Presents the order details if the `note` is for an order push notification.
    ///
    private static func presentNotificationDetails(for note: Note) {
        switch note.kind {
        case .storeOrder:
            switchToOrdersTab {
                ordersTabSplitViewWrapper()?.presentDetails(for: note)
            }
        default:
            break
        }

        ServiceLocator.analytics.track(.notificationOpened, withProperties: [ "type": note.kind.rawValue,
                                                                              "already_read": note.read ])
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

    static func presentCollectPayment() {
        guard let tabBar = AppDelegate.shared.tabBarController else {
            return
        }
        tabBar.presentCollectPayment()
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
        default:
            return
        }
    }
}

// MARK: - Site ID observation for updating tab view controllers
//
private extension MainTabBarController {
    func configureTabViewControllers() {
        viewControllers = {
            var controllers = [UIViewController]()

            let tabs: [WooTab] = [.myStore, .orders, .products, .hubMenu]
            tabs.forEach { tab in
                let tabIndex = tab.visibleIndex()
                let tabViewController = rootTabViewController(tab: tab)
                controllers.insert(tabViewController, at: tabIndex)
            }
            return controllers
        }()
    }

    func rootTabViewController(tab: WooTab) -> UIViewController {
        switch tab {
            case .myStore:
                return dashboardNavigationController
            case .orders:
                return ordersContainerController
            case .products:
                return isProductsSplitViewFeatureFlagOn ? productsContainerController: productsNavigationController
            case .hubMenu:
                return hubMenuContainerController
        }
    }

    func observeSiteIDForViewControllers() {
        cancellableSiteID = stores.siteID.sink { [weak self] siteID in
            guard let self = self else {
                return
            }
            self.updateViewControllers(siteID: siteID)
        }
    }

    func updateViewControllers(siteID: Int64?) {
        guard let siteID = siteID else {
            return
        }

        // Update view model with `siteID` to query correct Orders Status
        viewModel.configureOrdersStatusesListener(for: siteID)

        // Initialize each tab's root view controller
        let dashboardViewController = createDashboardViewController(siteID: siteID)
        dashboardNavigationController.viewControllers = [dashboardViewController]

        ordersContainerController.wrappedController = createOrdersViewController(siteID: siteID)

        if isProductsSplitViewFeatureFlagOn {
            productsContainerController.wrappedController = ProductsSplitViewWrapperController(siteID: siteID)
        } else {
            productsNavigationController.viewControllers = [ProductsViewController(siteID: siteID,
                                                                                   selectedProduct: Empty().eraseToAnyPublisher(),
                                                                                   navigateToContent: { _ in })]
        }

        // Configure hub menu tab coordinator once per logged in session potentially with multiple sites.
        if hubMenuTabCoordinator == nil {
            let hubTabCoordinator = createHubMenuTabCoordinator()
            self.hubMenuTabCoordinator = hubTabCoordinator
        }
        hubMenuTabCoordinator?.activate(siteID: siteID)

        viewModel.loadHubMenuTabBadge()

        // Set dashboard to be the default tab.
        selectedIndex = WooTab.myStore.visibleIndex()
    }

    func createDashboardViewController(siteID: Int64) -> UIViewController {
        DashboardViewHostingController(siteID: siteID)
    }

    func createOrdersViewController(siteID: Int64) -> UIViewController {
        OrdersSplitViewWrapperController(siteID: siteID)
    }

    func createHubMenuTabCoordinator() -> HubMenuCoordinator {
        HubMenuCoordinator(tabContainerController: hubMenuContainerController,
                           tapToPayBadgePromotionChecker: viewModel.tapToPayBadgePromotionChecker,
                           willPresentReviewDetailsFromPushNotification: { [weak self] in
            await withCheckedContinuation { [weak self] continuation in
                self?.navigateTo(.hubMenu) {
                    continuation.resume(returning: ())
                }
            }
        })
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
        let tabIndex = tab.visibleIndex()
        let input = NotificationsBadgeInput(action: action, tab: tab, tabBar: self.tabBar, tabIndex: tabIndex)

        self.notificationsBadge.updateBadge(with: input)
    }
}

// MARK: - Orders Tab Badge

private extension MainTabBarController {
    func startListeningToOrdersBadge() {
        viewModel.onOrdersBadgeReload = { [weak self] countReadableString in
            guard let self = self else {
                return
            }

            let tab = WooTab.orders
            let tabIndex = tab.visibleIndex()

            guard let orderTab: UITabBarItem = self.tabBar.items?[tabIndex] else {
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
            guard let self = self else { return }
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
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
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
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
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
    enum Constants {
        // Used to delay a second navigation after the previous one is called,
        // to ensure that the first transition is finished. Without this delay
        // the second one might not happen.
        static let screenTransitionsDelay = 0.3
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
