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

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        stores = DefaultStoresManager.testingInstance
        ServiceLocator.setStores(stores)

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window.resignKey()
        window.rootViewController = nil

        analytics = nil
        analyticsProvider = nil

        SessionManager.testingInstance.reset()
        stores = nil
        super.tearDown()
    }

    func test_tab_view_controllers_are_not_empty_after_updating_default_site() throws {

        // Arrange
        // Sets mock `FeatureFlagService` before `MainTabBarController` is initialized so that the feature flags are set correctly.
        let featureFlagService = MockFeatureFlagService()
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
        assertThat(tabBarController.tabRootViewController(tab: .myStore),
                   isAnInstanceOf: DashboardViewHostingController.self)
        assertThat(tabBarController.tabRootViewController(tab: .orders),
                   isAnInstanceOf: OrdersSplitViewWrapperController.self)
        assertThat(tabBarController.tabRootViewController(tab: .products),
                   isAnInstanceOf: ProductsViewController.self)

        let hubMenuNavigationController = try XCTUnwrap(tabBarController.tabRootViewController(tab: .hubMenu) as? UINavigationController)
        assertThat(hubMenuNavigationController.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_tab_view_controllers_returns_expected_values() throws {
        // Arrange
        let featureFlagService = MockFeatureFlagService()

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
        assertThat(tabBarController.tabRootViewController(tab: .myStore),
                   isAnInstanceOf: DashboardViewHostingController.self)
        assertThat(tabBarController.tabRootViewController(tab: .orders),
                   isAnInstanceOf: OrdersSplitViewWrapperController.self)
        assertThat(tabBarController.tabRootViewController(tab: .products),
                   isAnInstanceOf: ProductsViewController.self)

        let hubMenuNavigationController = try XCTUnwrap(tabBarController.tabRootViewController(tab: .hubMenu) as? UINavigationController)
        assertThat(hubMenuNavigationController.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_tab_root_viewControllers_are_replaced_after_updating_to_a_different_site() throws {
        // Arrange
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService())
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
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.myStore.visibleIndex()],
                          viewControllersAfterSiteChange[WooTab.myStore.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.orders.visibleIndex()],
                          viewControllersAfterSiteChange[WooTab.orders.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.products.visibleIndex()],
                          viewControllersAfterSiteChange[WooTab.products.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.hubMenu.visibleIndex()],
                          viewControllersAfterSiteChange[WooTab.hubMenu.visibleIndex()])
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
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService())
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        waitFor { promise in
            tabBarController.navigateTo(.products) {
                promise(())
            }
        }
        let selectedTabIndexBeforeSiteChange = tabBarController.selectedIndex
        stores.updateDefaultStore(storeID: 630)
        let selectedTabIndexAfterSiteChange = tabBarController.selectedIndex

        // Assert
        XCTAssertEqual(selectedTabIndexBeforeSiteChange, WooTab.products.visibleIndex())
        XCTAssertEqual(selectedTabIndexAfterSiteChange, WooTab.myStore.visibleIndex())
    }

    func test_when_receiving_a_review_notification_from_a_different_site_navigates_to_hubMenu_tab() throws {
        // Arrange
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

        let hubMenuNavigationController = try XCTUnwrap(tabBarController.tabRootViewController(tab: .hubMenu) as? UINavigationController)
        assertThat(hubMenuNavigationController.topViewController, isAnInstanceOf: HubMenuViewController.self)

        // Action
        // Send push notification in inactive state
        let pushNotification = PushNotification(noteID: 1_234, siteID: 1, kind: .comment, title: "", subtitle: "", message: "")
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel
        let receivedAction = try XCTUnwrap(storesManager.receivedActions.first(where: { $0 is ProductReviewAction }) as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.success(ProductReviewFromNoteParcelFactory().parcel(metaSiteID: 606)))

        // Assert
        waitUntil {
            hubMenuNavigationController.viewControllers.count != 0
        }
        // HubMenuViewController should be pushed, and be the MainTabBarController visible index
        assertThat(hubMenuNavigationController.topViewController, isAnInstanceOf: HubMenuViewController.self)
        XCTAssertEqual(tabBarController.selectedIndex, WooTab.hubMenu.visibleIndex())
    }

    func test_when_receiving_product_image_upload_error_a_notice_is_enqueued() throws {
        // Given)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
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
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedUploadingImage(error: NSError(domain: "", code: 8))))

        // Given
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, MainTabBarController.Localization.imageUploadFailureNoticeTitle)
    }

    func test_when_receiving_product_images_saving_error_a_notice_is_enqueued() throws {
        // Given
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
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
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedSavingProductAfterImageUpload(error: NSError(domain: "", code: 18))))

        // Given
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, MainTabBarController.Localization.productImagesSavingFailureNoticeTitle)
    }

    func test_when_receiving_variation_image_saving_error_a_notice_is_enqueued() throws {
        // Given
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
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
                                 productOrVariationID: .variation(productID: 0, variationID: 608),
                                 productImageStatuses: [],
                                 error: .failedSavingProductAfterImageUpload(error: NSError(domain: "", code: 18))))

        // Given
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.title, MainTabBarController.Localization.variationImageSavingFailureNoticeTitle)
    }

    func test_when_tapping_product_image_upload_error_notice_product_details_is_pushed_to_products_tab() throws {
        // Given
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
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
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedUploadingImage(error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController.tabContainerController(tab: .products))
        waitUntil {
            productsNavigationController.presentedViewController != nil
        }

        // Then
        let productNavigationController = try XCTUnwrap(productsNavigationController.presentedViewController as? UINavigationController)
        assertThat(productNavigationController.topViewController, isAnInstanceOf: ProductLoaderViewController.self)
    }

    // MARK: - Analytics

    func test_failureUploadingImageNotice_events_are_tracked_when_showing_and_tapping_product_image_upload_error_notice() throws {
        // Given
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader,
                                        analytics: self.analytics)
        }) else {
            return
        }
        window.rootViewController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let error = NSError(domain: "", code: 8)
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedUploadingImage(error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController.tabContainerController(tab: .products))
        waitUntil {
            productsNavigationController.presentedViewController != nil
        }

        // Then
        assertEqual([
            WooAnalyticsStat.failureUploadingImageNoticeShown.rawValue,
            WooAnalyticsStat.failureUploadingImageNoticeTapped.rawValue,
        ], analyticsProvider.receivedEvents)
        assertEqual("product", analyticsProvider.receivedProperties[safe: 0]?["type"] as? String)
        assertEqual("product", analyticsProvider.receivedProperties[safe: 1]?["type"] as? String)
    }

    func test_failureSavingProductAfterImageUploadNotice_events_are_tracked_when_showing_and_tapping_product_saving_error_notice() throws {
        // Given
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        noticePresenter: noticePresenter,
                                        productImageUploader: productImageUploader,
                                        analytics: self.analytics)
        }) else {
            return
        }
        window.rootViewController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let error = NSError(domain: "", code: 8)
        statusUpdates.send(.init(siteID: 134,
                                 productOrVariationID: .product(id: 606),
                                 productImageStatuses: [],
                                 error: .failedSavingProductAfterImageUpload(error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController
                    .tabContainerController(tab: .products))
        waitUntil {
            productsNavigationController.presentedViewController != nil
        }

        // Then
        assertEqual([
            WooAnalyticsStat.failureSavingProductAfterImageUploadNoticeShown.rawValue,
            WooAnalyticsStat.failureSavingProductAfterImageUploadNoticeTapped.rawValue,
        ], analyticsProvider.receivedEvents)
        assertEqual("product", analyticsProvider.receivedProperties[safe: 0]?["type"] as? String)
        assertEqual("product", analyticsProvider.receivedProperties[safe: 1]?["type"] as? String)
    }

    func test_navigateToTabWithNavigationController_returns_UIViewController_of_the_newly_selected_tab() throws {
        // Given
        stores.updateDefaultStore(storeID: 134)

        let tabBarController = try XCTUnwrap(UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController)

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let navigationController = waitFor { promise in
            tabBarController.navigateToTabWithViewController(.products, animated: false) { navigationController in
                promise(navigationController)
            }
        }

        // Then
        XCTAssertEqual(tabBarController.selectedIndex, WooTab.products.visibleIndex())
        XCTAssertEqual(tabBarController.selectedViewController, navigationController)
    }

    func test_navigateToOrderDetails_for_the_same_store_switches_to_orders_tab_and_opens_order() throws {
        // Given
        let siteID: Int64 = 256
        stores.updateDefaultStore(storeID: siteID)

        let mockFeatureFlagService = MockFeatureFlagService()
        ServiceLocator.setFeatureFlagService(mockFeatureFlagService)

        let tabBarController = try XCTUnwrap(UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController)
        TestingAppDelegate.mockTabBarController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        MainTabBarController.navigateToOrderDetails(with: 155, siteID: siteID)
        waitUntil {
            tabBarController.selectedViewController is TabContainerController
        }

        // Then
        XCTAssertEqual(tabBarController.selectedIndex, WooTab.orders.visibleIndex())
        let tabContainerController = try XCTUnwrap(tabBarController.selectedViewController as? TabContainerController)
        let ordersSplitViewWrapper = try XCTUnwrap(tabContainerController.wrappedController as? OrdersSplitViewWrapperController)
        let splitViewController = try XCTUnwrap(ordersSplitViewWrapper.children.first as? UISplitViewController)
        let secondaryViewController = try XCTUnwrap((splitViewController.viewController(for: .secondary) as? UINavigationController)?.topViewController)
        assertThat(secondaryViewController, isAnInstanceOf: OrderLoaderViewController.self)

        // Resets the tab bar controller mock at the end of the test.
        TestingAppDelegate.mockTabBarController = nil
    }

    func test_presentNotificationDetails_for_the_same_store_switches_to_orders_tab_and_opens_order() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        ServiceLocator.setStores(stores)

        let siteID: Int64 = 256
        stores.updateDefaultStore(storeID: siteID)

        stores.whenReceivingAction(ofType: NotificationAction.self) { action in
            guard case let .synchronizeNotification(_, completion) = action else {
                return
            }
            let note = MockNote().makeOrderNote(metaSiteID: siteID, metaOrderID: 612)
            completion(note, nil)
        }

        let mockFeatureFlagService = MockFeatureFlagService()
        ServiceLocator.setFeatureFlagService(mockFeatureFlagService)

        let tabBarController = try XCTUnwrap(UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController)
        TestingAppDelegate.mockTabBarController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        MainTabBarController.presentNotificationDetails(for: 1)
        waitUntil {
            tabBarController.selectedViewController is TabContainerController
        }

        // Then
        XCTAssertEqual(tabBarController.selectedIndex, WooTab.orders.visibleIndex())
        let tabContainerController = try XCTUnwrap(tabBarController.selectedViewController as? TabContainerController)
        let ordersSplitViewWrapper = try XCTUnwrap(tabContainerController.wrappedController as? OrdersSplitViewWrapperController)
        let splitViewController = try XCTUnwrap(ordersSplitViewWrapper.children.first as? UISplitViewController)
        let secondaryViewController = try XCTUnwrap((splitViewController.viewController(for: .secondary) as? UINavigationController)?.topViewController)
        assertThat(secondaryViewController, isAnInstanceOf: OrderLoaderViewController.self)

        // Resets the tab bar controller mock at the end of the test.
        TestingAppDelegate.mockTabBarController = nil
    }
}

private extension MainTabBarController {
    var tabRootViewControllers: [UIViewController] {
        var rootViewControllers = [UIViewController]()

        guard let viewControllers else {
            return rootViewControllers
        }

        for viewController in viewControllers {
            if let navigationController = viewController as? UINavigationController {
                guard let containedViewController = navigationController.viewControllers.first else {
                    continue
                }
                rootViewControllers.append(containedViewController)
            } else if let containerController = viewController as? TabContainerController {
                guard let containedViewController = containerController.wrappedController else {
                    continue
                }
                rootViewControllers.append(containedViewController)
            }
        }

        return rootViewControllers
    }

    func tabRootViewController(tab: WooTab) -> UIViewController? {
        // swiftlint:disable:next empty_enum_arguments
        guard let viewController = tabRootViewControllers[safe: tab.visibleIndex()] else {
            XCTFail("Unexpected access to root controller at tab: \(tab)")
            return nil
        }
        return viewController
    }

    func tabContainerController(tab: WooTab) -> UIViewController? {
        guard let viewController = viewControllers?[tab.visibleIndex()] else {
            XCTFail("Unexpected access to container controller at tab: \(tab)")
            return nil
        }
        return viewController
    }
}
