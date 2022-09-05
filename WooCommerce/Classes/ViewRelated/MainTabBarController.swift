import Combine
import UIKit
import Yosemite
import WordPressUI
import Experiments


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

    /// Hub Menu Tab
    ///
    case hubMenu
}

extension WooTab {
    /// Initializes a tab with the visible tab index.
    ///
    /// - Parameters:
    ///   - visibleIndex: the index of visible tabs on the tab bar
    init(visibleIndex: Int, isHubMenuFeatureFlagOn: Bool) {
        let tabs = WooTab.visibleTabs(isHubMenuFeatureFlagOn)
        self = tabs[visibleIndex]
    }

    /// Returns the visible tab index.
    func visibleIndex(_ isHubMenuFeatureFlagOn: Bool) -> Int {
        let tabs = WooTab.visibleTabs(isHubMenuFeatureFlagOn)
        guard let tabIndex = tabs.firstIndex(where: { $0 == self }) else {
            assertionFailure("Trying to get the visible tab index for tab \(self) while the visible tabs are: \(tabs)")
            return 0
        }
        return tabIndex
    }

    // Note: currently only the Dashboard tab (My Store) view controller is set up in Main.storyboard.
    private static func visibleTabs(_ isHubMenuFeatureFlagOn: Bool) -> [WooTab] {
        var tabs: [WooTab] = [.myStore, .orders, .products]

        if isHubMenuFeatureFlagOn {
            tabs.append(.hubMenu)
        }
        else {
            tabs.append(.reviews)
        }

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
    private let ordersNavigationController = WooTabNavigationController()
    private let productsNavigationController = WooTabNavigationController()
    private let reviewsNavigationController = WooTabNavigationController()
    private let hubMenuNavigationController = WooTabNavigationController()
    private var reviewsTabCoordinator: ReviewsCoordinator?
    private var hubMenuTabCoordinator: HubMenuCoordinator?

    private var cancellableSiteID: AnyCancellable?
    private let featureFlagService: FeatureFlagService
    private let noticePresenter: NoticePresenter
    private let productImageUploader: ProductImageUploaderProtocol
    private let stores: StoresManager = ServiceLocator.stores
    private let analytics: Analytics

    private var productImageUploadErrorsSubscription: AnyCancellable?

    private lazy var isHubMenuFeatureFlagOn = featureFlagService.isFeatureFlagEnabled(.hubMenu)

    private lazy var isOrdersSplitViewFeatureFlagOn = featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab)

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
        let currentlySelectedTab = WooTab(visibleIndex: selectedIndex, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)
        guard let userSelectedIndex = tabBar.items?.firstIndex(of: item) else {
                return
        }
        let userSelectedTab = WooTab(visibleIndex: userSelectedIndex, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)

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
        if let presentedController = Self.childViewController()?.presentedViewController {
            presentedController.dismiss(animated: true)
        }
        selectedIndex = tab.visibleIndex(isHubMenuFeatureFlagOn)
        if let navController = selectedViewController as? UINavigationController {
            navController.popToRootViewController(animated: animated) {
                completion?()
            }
        }
    }

    /// Removes the view controllers in each tab's navigation controller, and resets any logged in properties.
    /// Called after the app is logged out and authentication UI is presented.
    func removeViewControllers() {
        viewControllers?.compactMap { $0 as? UINavigationController }.forEach { navigationController in
            navigationController.viewControllers = []
        }
        reviewsTabCoordinator = nil
        hubMenuTabCoordinator = nil
    }
}


// MARK: - UIViewControllerTransitioningDelegate
//
extension MainTabBarController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController || presented is CardPresentPaymentsModalViewController else {
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
            ServiceLocator.analytics.track(.ordersReselected)
        case .products:
            ServiceLocator.analytics.track(.productListReselected)
        case .reviews:
            ServiceLocator.analytics.track(.notificationsReselected)
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

    /// Switches to the Reviews tab and pops to the root view controller
    ///
    static func switchToReviewsTab(completion: (() -> Void)? = nil) {
        navigateTo(.reviews, completion: completion)
    }

    /// Switches to the Hub Menu tab and pops to the root view controller
    ///
    static func switchToHubMenuTab(completion: (() -> Void)? = nil) {
        navigateTo(.hubMenu, completion: completion)
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

            switchToStore(with: siteID, onCompletion: {
                presentNotificationDetails(for: note)

            })
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
                if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) {
                    (childViewController() as? OrdersSplitViewWrapperController)?.presentDetails(for: note)
                } else {
                    (childViewController() as? OrdersRootViewController)?.presentDetails(for: note)
                }
            }
        default:
            break
        }

        ServiceLocator.analytics.track(.notificationOpened, withProperties: [ "type": note.kind.rawValue,
                                                                              "already_read": note.read ])
    }

    private static func switchToStore(with siteID: Int64, onCompletion: @escaping () -> Void) {
        SwitchStoreUseCase(stores: ServiceLocator.stores).switchStore(with: siteID) { siteChanged in
            if siteChanged {
                let presenter = SwitchStoreNoticePresenter(siteID: siteID)
                presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .switchingStores)
            }

            onCompletion()
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

    static func navigateToOrderDetails(with orderID: Int64, siteID: Int64) {
        switchToStore(with: siteID, onCompletion: {
            switchToOrdersTab {
                // We give some time to the orders tab transition to finish, otherwise it might prevent the second navigation from happening
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    presentDetails(for: orderID, siteID: siteID)
                }
            }
        })
    }

    private static func presentDetails(for orderID: Int64, siteID: Int64) {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) {
            (childViewController() as? OrdersSplitViewWrapperController)?.presentDetails(for: orderID, siteID: siteID)
        } else {
            (childViewController() as? OrdersRootViewController)?.presentDetails(for: orderID, siteID: siteID)
        }
    }

    static func presentPayments() {
        switchToHubMenuTab()

        guard let hubMenuViewController: HubMenuViewController = childViewController() else {
            return
        }

        hubMenuViewController.showPaymentsMenu()
    }
}

// MARK: - Site ID observation for updating tab view controllers
//
private extension MainTabBarController {
    func configureTabViewControllers() {
        viewControllers = {
            var controllers = [UIViewController]()

            let dashboardTabIndex = WooTab.myStore.visibleIndex(isHubMenuFeatureFlagOn)
            controllers.insert(dashboardNavigationController, at: dashboardTabIndex)

            let ordersTabIndex = WooTab.orders.visibleIndex(isHubMenuFeatureFlagOn)
            controllers.insert(ordersNavigationController, at: ordersTabIndex)

            let productsTabIndex = WooTab.products.visibleIndex(isHubMenuFeatureFlagOn)
            controllers.insert(productsNavigationController, at: productsTabIndex)

            if isHubMenuFeatureFlagOn {
                let hubMenuTabIndex = WooTab.hubMenu.visibleIndex(isHubMenuFeatureFlagOn)
                controllers.insert(hubMenuNavigationController, at: hubMenuTabIndex)
            } else {
                let reviewsTabIndex = WooTab.reviews.visibleIndex(isHubMenuFeatureFlagOn)
                controllers.insert(reviewsNavigationController, at: reviewsTabIndex)
            }

            return controllers
        }()
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

        let ordersViewController = createOrdersViewController(siteID: siteID)
        ordersNavigationController.viewControllers = [ordersViewController]

        let productsViewController = createProductsViewController(siteID: siteID)
        productsNavigationController.viewControllers = [productsViewController]

        // Configure hub menu tab coordinator or reviews tab coordinator once per logged in session potentially with multiple sites.
        if isHubMenuFeatureFlagOn {
            if hubMenuTabCoordinator == nil {
                let hubTabCoordinator = createHubMenuTabCoordinator()
                self.hubMenuTabCoordinator = hubTabCoordinator
                hubTabCoordinator.start()
            }
            hubMenuTabCoordinator?.activate(siteID: siteID)
        }
        else {
            if reviewsTabCoordinator == nil {
                let reviewsTabCoordinator = createReviewsTabCoordinator()
                self.reviewsTabCoordinator = reviewsTabCoordinator
                reviewsTabCoordinator.start()
            }
            reviewsTabCoordinator?.activate(siteID: siteID)
        }

        // Set dashboard to be the default tab.
        selectedIndex = WooTab.myStore.visibleIndex(isHubMenuFeatureFlagOn)
    }

    func createDashboardViewController(siteID: Int64) -> UIViewController {
        DashboardViewController(siteID: siteID)
    }

    func createOrdersViewController(siteID: Int64) -> UIViewController {
        if isOrdersSplitViewFeatureFlagOn {
            return OrdersSplitViewWrapperController(siteID: siteID)
        } else {
            return OrdersRootViewController(siteID: siteID)
        }
    }

    func createProductsViewController(siteID: Int64) -> UIViewController {
        ProductsViewController(siteID: siteID)
    }

    func createReviewsTabCoordinator() -> ReviewsCoordinator {
        ReviewsCoordinator(navigationController: reviewsNavigationController,
                           willPresentReviewDetailsFromPushNotification: { [weak self] in
            self?.navigateTo(.reviews)
        })
    }

    func createHubMenuTabCoordinator() -> HubMenuCoordinator {
        HubMenuCoordinator(navigationController: hubMenuNavigationController,
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
        let tab = self.isHubMenuFeatureFlagOn ? WooTab.hubMenu : WooTab.reviews
        let tabIndex = tab.visibleIndex(self.isHubMenuFeatureFlagOn)
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
            let tabIndex = tab.visibleIndex(self.isHubMenuFeatureFlagOn)

            guard let orderTab: UITabBarItem = self.tabBar.items?[tabIndex] else {
                return
            }

            orderTab.badgeValue = countReadableString
            orderTab.badgeColor = .primary
        }

        viewModel.startObservingOrdersCount()
    }
}

// MARK: - Background Product Image Upload Status Updates

private extension MainTabBarController {
    func observeProductImageUploadStatusUpdates() {
        guard featureFlagService.isFeatureFlagEnabled(.backgroundProductImageUpload) else {
            return
        }
        productImageUploadErrorsSubscription = productImageUploader.errors.sink { [weak self] error in
            guard let self = self else { return }
            switch error.error {
            case .failedSavingProductAfterImageUpload:
                self.handleErrorSavingProductAfterImageUpload(error)
            case .failedUploadingImage:
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
        productsNavigationController.present(productNavController, animated: true)
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
