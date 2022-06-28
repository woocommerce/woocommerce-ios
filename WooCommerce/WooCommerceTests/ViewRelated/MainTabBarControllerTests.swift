import Combine
import TestKit
import XCTest
@testable import WooCommerce
import Yosemite

final class MainTabBarControllerTests: XCTestCase {
    private var stores: StoresManager!
    // For test cases that assert on a view controller's navigation behavior, a retained window is required
    // with its `rootViewController` set to the view controller.
    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        stores = DefaultStoresManager.testingInstance
        ServiceLocator.setStores(stores)

        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window.resignKey()
        window.rootViewController = nil

        SessionManager.testingInstance.reset()
        stores = nil
        super.tearDown()
    }

    func test_tab_view_controllers_are_not_empty_after_updating_default_site() {

        // Arrange
        // Sets mock `FeatureFlagService` before `MainTabBarController` is initialized so that the feature flags are set correctly.
        let isHubMenuFeatureFlagOn = false
        let featureFlagService = MockFeatureFlagService(isHubMenuOn: isHubMenuFeatureFlagOn)
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder, featureFlagService: featureFlagService)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
        assertThat(tabBarController.tabNavigationController(tab: .myStore, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: DashboardViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .orders, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: OrdersRootViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .products, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: ProductsViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .reviews, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: ReviewsViewController.self)
    }

    func test_tab_view_controllers_returns_expected_values_with_hub_menu_enabled() {
        // Arrange
        // Sets mock `FeatureFlagService` before `MainTabBarController` is initialized so that the feature flags are set correctly.
        let isHubMenuFeatureFlagOn = true
        let featureFlagService = MockFeatureFlagService(isHubMenuOn: isHubMenuFeatureFlagOn)
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder, featureFlagService: featureFlagService)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
        assertThat(tabBarController.tabNavigationController(tab: .myStore, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: DashboardViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .orders, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: OrdersRootViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .products, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: ProductsViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .hubMenu, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_tab_view_controllers_returns_expected_values_with_hub_menu_and_split_view_in_orders_tab_enabled() {
        // Arrange
        // Sets mock `FeatureFlagService` before `MainTabBarController` is initialized so that the feature flags are set correctly.
        let isSplitViewInOrdersTabOn = true
        let isHubMenuFeatureFlagOn = true
        let featureFlagService = MockFeatureFlagService(isHubMenuOn: isHubMenuFeatureFlagOn, isSplitViewInOrdersTabOn: isSplitViewInOrdersTabOn)

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder, featureFlagService: featureFlagService)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
        assertThat(tabBarController.tabNavigationController(tab: .myStore, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: DashboardViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .orders, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: OrdersSplitViewWrapperController.self)
        assertThat(tabBarController.tabNavigationController(tab: .products, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: ProductsViewController.self)
        assertThat(tabBarController.tabNavigationController(tab: .hubMenu, isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_tab_root_viewControllers_are_replaced_after_updating_to_a_different_site() throws {
        // Arrange
        let isHubMenuFeatureFlagOn = false
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService(isHubMenuOn: isHubMenuFeatureFlagOn))
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        let viewControllersBeforeSiteChange = tabBarController.tabRootViewControllers
        stores.updateDefaultStore(storeID: 630)
        let viewControllersAfterSiteChange = tabBarController.tabRootViewControllers

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange.count, viewControllersAfterSiteChange.count)
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.myStore.visibleIndex(isHubMenuFeatureFlagOn)],
                          viewControllersAfterSiteChange[WooTab.myStore.visibleIndex(isHubMenuFeatureFlagOn)])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.orders.visibleIndex(isHubMenuFeatureFlagOn)],
                          viewControllersAfterSiteChange[WooTab.orders.visibleIndex(isHubMenuFeatureFlagOn)])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.products.visibleIndex(isHubMenuFeatureFlagOn)],
                          viewControllersAfterSiteChange[WooTab.products.visibleIndex(isHubMenuFeatureFlagOn)])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.reviews.visibleIndex(isHubMenuFeatureFlagOn)],
                          viewControllersAfterSiteChange[WooTab.reviews.visibleIndex(isHubMenuFeatureFlagOn)])
    }

    func test_tab_view_controllers_stay_the_same_after_updating_to_the_same_site() throws {
        // Arrange
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        let viewControllersBeforeSiteChange = try XCTUnwrap(tabBarController.viewControllers)
        stores.updateDefaultStore(storeID: siteID)
        let viewControllersAfterSiteChange = try XCTUnwrap(tabBarController.viewControllers)

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange, viewControllersAfterSiteChange)
    }

    func test_selected_tab_is_dashboard_after_navigating_to_products_tab_then_updating_to_a_different_site() throws {
        // Arrange
        let isHubMenuFeatureFlagOn = false
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService(isHubMenuOn: isHubMenuFeatureFlagOn))
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        tabBarController.navigateTo(.products)
        let selectedTabIndexBeforeSiteChange = tabBarController.selectedIndex
        stores.updateDefaultStore(storeID: 630)
        let selectedTabIndexAfterSiteChange = tabBarController.selectedIndex

        // Assert
        XCTAssertEqual(selectedTabIndexBeforeSiteChange, WooTab.products.visibleIndex(isHubMenuFeatureFlagOn))
        XCTAssertEqual(selectedTabIndexAfterSiteChange, WooTab.myStore.visibleIndex(isHubMenuFeatureFlagOn))
    }

    func test_when_receiving_a_review_notification_from_a_different_site_navigates_to_reviews_tab_and_presents_review_details() throws {
        // Arrange
        // Sets mock `FeatureFlagService` before `MainTabBarController` is initialized so that the feature flags are set correctly.
        let isHubMenuFeatureFlagOn = false
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService(isHubMenuOn: isHubMenuFeatureFlagOn))

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController else {
            return
        }

        let pushNotificationsManager = MockPushNotificationsManager()
        ServiceLocator.setPushNotesManager(pushNotificationsManager)

        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        // Reset `receivedActions`
        storesManager.reset()
        ServiceLocator.setStores(storesManager)

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        stores.updateDefaultStore(storeID: 134)

        // Simulate successful state resetting after logging out from push notification store switching
        storesManager.whenReceivingAction(ofType: StatsActionV4.self) { action in
            if case let .resetStoredStats(completion) = action {
                completion()
            }
        }
        storesManager.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .resetStoredOrders(completion) = action {
                completion()
            }
        }
        storesManager.whenReceivingAction(ofType: ProductReviewAction.self) { action in
            if case let .resetStoredProductReviews(completion) = action {
                completion()
            }
        }

        assertThat(tabBarController.tabNavigationController(tab: .reviews,

                                                            isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: ReviewsViewController.self)

        // Action
        // Send push notification in inactive state
        let pushNotification = PushNotification(noteID: 1_234, kind: .comment, title: "", subtitle: "", message: "")
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel
        let receivedAction = try XCTUnwrap(storesManager.receivedActions.first as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.success(ProductReviewFromNoteParcelFactory().parcel(metaSiteID: 606)))

        // Assert
        waitUntil {
            tabBarController.tabNavigationController(tab: .reviews,
                                                     isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.viewControllers.count == 2
        }

        XCTAssertEqual(tabBarController.selectedIndex, WooTab.reviews.visibleIndex(isHubMenuFeatureFlagOn))

        // A ReviewDetailsViewController should be pushed
        assertThat(tabBarController.tabNavigationController(tab: .reviews,

                                                            isHubMenuFeatureFlagOn: isHubMenuFeatureFlagOn)?.topViewController,
                   isAnInstanceOf: ReviewDetailsViewController.self)
    }

    func test_when_receiving_product_image_upload_error_a_notice_is_enqueued() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: true)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)

        // When
        statusUpdates.send(.init(siteID: 134,
                                 productID: 606,
                                 productImageStatuses: [],
                                 error: .actionHandler(error: NSError(domain: "", code: 8))))

        // Given
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, MainTabBarController.Localization.imageUploadFailureNoticeTitle)
    }

    func test_when_receiving_product_images_saver_error_a_notice_is_enqueued() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: true)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)

        // When
        statusUpdates.send(.init(siteID: 134,
                                 productID: 606,
                                 productImageStatuses: [],
                                 error: .savingProductImages(error: NSError(domain: "", code: 18))))

        // Given
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, MainTabBarController.Localization.imagesSavingFailureNoticeTitle)
    }

    func test_when_tapping_product_image_upload_error_notice_product_details_is_pushed_to_products_tab() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: true)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader)
        }) else {
            return
        }
        window.rootViewController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let error = NSError(domain: "", code: 8)
        statusUpdates.send(.init(siteID: 134, productID: 606, productImageStatuses: [], error: .actionHandler(error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController
            .tabNavigationController(tab: .products,
                                     isHubMenuFeatureFlagOn: featureFlagService.isFeatureFlagEnabled(.hubMenu)))
        waitUntil {
            productsNavigationController.presentedViewController != nil
        }

        // Then
        let productNavigationController = try XCTUnwrap(productsNavigationController.presentedViewController as? UINavigationController)
        assertThat(productNavigationController.topViewController, isAnInstanceOf: ProductLoaderViewController.self)
    }

    func test_when_receiving_product_image_upload_error_with_feature_flag_off_a_notice_is_not_enqueued() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isBackgroundImageUploadEnabled: false)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: featureFlagService,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)

        // When
        let error = NSError(domain: "", code: 8)
        statusUpdates.send(.init(siteID: 134, productID: 606, productImageStatuses: [], error: .actionHandler(error: error)))

        // Then
        XCTAssertEqual(noticePresenter.queuedNotices.count, 0)
    }
}

private extension MainTabBarController {
    var tabRootViewControllers: [UIViewController] {
        viewControllers?.compactMap { $0 as? UINavigationController }.compactMap { $0.viewControllers.first } ?? []
    }

    func tabNavigationController(tab: WooTab, isHubMenuFeatureFlagOn: Bool) -> UINavigationController? {
        guard let navigationController = viewControllers?.compactMap({ $0 as? UINavigationController })[tab.visibleIndex(isHubMenuFeatureFlagOn)] else {
            XCTFail("Unexpected access to navigation controller at tab: \(tab)")
            return nil
        }
        return navigationController
    }
}
