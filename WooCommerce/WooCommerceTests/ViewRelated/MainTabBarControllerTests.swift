import Combine
import Photos
import PointOfSale
import SwiftUI
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

    func test_selected_tab_is_dashboard_after_navigating_to_products_tab_then_updating_to_a_different_site() throws {
        // Arrange
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService())
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteIDBefore: Int64 = 134
        stores.updateDefaultStore(storeID: siteIDBefore)
        stores.updateDefaultStore(.fake().copy(siteID: siteIDBefore))
        waitFor { promise in
            tabBarController.navigateTo(.products) {
                promise(())
            }
        }
        let selectedTabIndexBeforeSiteChange = tabBarController.selectedIndex
        let siteIDAfter: Int64 = 630
        stores.updateDefaultStore(storeID: siteIDAfter)
        stores.updateDefaultStore(.fake().copy(siteID: siteIDAfter))
        let selectedTabIndexAfterSiteChange = tabBarController.selectedIndex

        // Assert
        XCTAssertEqual(selectedTabIndexBeforeSiteChange, WooTab.products.visibleIndex(isPOSTabVisible: false))
        XCTAssertEqual(selectedTabIndexAfterSiteChange, WooTab.myStore.visibleIndex(isPOSTabVisible: false))
    }

    func test_when_receiving_a_review_notification_from_a_different_site_navigates_to_hubMenu_tab() throws {
        // Arrange
        let pushNotificationsManager = MockPushNotificationsManager()
        ServiceLocator.setPushNotesManager(pushNotificationsManager)

        // Hides POS tab.
        let mockPOSEligibilityChecker = MockPOSTabVisibilityChecker()
        mockPOSEligibilityChecker.visibility = false

        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        // Reset `receivedActions`
        storesManager.reset()
        ServiceLocator.setStores(storesManager)

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        stores: storesManager,
                                        posTabVisibilityCheckerFactory: { _ in mockPOSEligibilityChecker })
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)
        let siteID: Int64 = 782
        storesManager.updateDefaultStore(storeID: siteID)
        storesManager.updateDefaultStore(.fake().copy(siteID: siteID))

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

        let hubMenuNavigationController = try XCTUnwrap(tabBarController.tabRootViewController(tab: .hubMenu, isPOSTabVisible: false) as? UINavigationController)
        assertThat(hubMenuNavigationController.topViewController, isAnInstanceOf: HubMenuViewController.self)

        // Action
        // Send push notification in inactive state
        let pushNotification = WooCommerce.PushNotification(noteID: 1_234, siteID: 1, kind: .comment, title: "", subtitle: "", message: "", note: nil, meta: nil)
        pushNotificationsManager.sendInactiveNotification(pushNotification)

        // Simulate that the network call returns a parcel
        let receivedAction = try XCTUnwrap(storesManager.receivedActions.first(where: { $0 is ProductReviewAction }) as? ProductReviewAction)
        guard case .retrieveProductReviewFromNote(_, let completion) = receivedAction else {
            return XCTFail("Expected retrieveProductReviewFromNote action.")
        }
        completion(.success(ProductReviewFromNoteParcelFactory().parcel(metaSiteID: 606)))

        // HubMenuViewController should be pushed, and be the MainTabBarController visible index
        waitUntil {
            hubMenuNavigationController.topViewController is HubMenuViewController
        }

        waitUntil {
            tabBarController.selectedIndex == WooTab.hubMenu.visibleIndex(isPOSTabVisible: false)
        }
    }

    func test_when_receiving_product_image_upload_error_a_notice_is_enqueued() throws {
        // Given)
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

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
                                 error: .failedUploadingImage(asset: ProductImageAssetType.phAsset(asset: PHAsset()),
                                                              error: NSError(domain: "", code: 8))))

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

        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

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

        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

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

        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

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
                                 error: .failedUploadingImage(asset: ProductImageAssetType.phAsset(asset: PHAsset()),
                                                              error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController.tabContainerController(tab: .products, isPOSTabVisible: false))
        waitUntil {
            productsNavigationController.presentedViewController != nil
        }

        // Then
        waitUntil {
            let productNavigationController = productsNavigationController.presentedViewController as? UINavigationController
            return productNavigationController?.topViewController is ProductLoaderViewController
        }
    }

    // MARK: - Analytics

    func test_failureUploadingImageNotice_events_are_tracked_when_showing_and_tapping_product_image_upload_error_notice() throws {
        // Given
        let noticePresenter = MockNoticePresenter()
        let statusUpdates = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let productImageUploader = MockProductImageUploader(errors: statusUpdates.eraseToAnyPublisher())

        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

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
                                 error: .failedUploadingImage(asset: ProductImageAssetType.phAsset(asset: PHAsset()),
                                                              error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController.tabContainerController(tab: .products, isPOSTabVisible: false))
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

        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

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
                                 error: .failedSavingProductAfterImageUpload(error: error)))
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        notice.actionHandler?()

        let productsNavigationController = try XCTUnwrap(tabBarController
            .tabContainerController(tab: .products, isPOSTabVisible: false))
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
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

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
        XCTAssertEqual(tabBarController.selectedIndex, WooTab.products.visibleIndex(isPOSTabVisible: false))
        XCTAssertEqual(tabBarController.selectedViewController, navigationController)
    }

    func test_navigateToOrderDetails_for_the_same_store_switches_to_orders_tab_and_opens_order() throws {
        // Given
        let siteID: Int64 = 256
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

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
        XCTAssertEqual(tabBarController.selectedIndex, WooTab.orders.visibleIndex(isPOSTabVisible: false))
        let tabContainerController = try XCTUnwrap(tabBarController.selectedViewController as? TabContainerController)
        let ordersSplitViewWrapper = try XCTUnwrap(tabContainerController.wrappedController as? OrdersSplitViewWrapperController)
        let splitViewController = try XCTUnwrap(ordersSplitViewWrapper.children.first as? UISplitViewController)

        waitUntil {
            let secondaryViewController = (splitViewController.viewController(for: .secondary) as? UINavigationController)?.topViewController
            return secondaryViewController is OrderLoaderViewController
        }

        // Resets the tab bar controller mock at the end of the test.
        TestingAppDelegate.mockTabBarController = nil
    }

    func test_pos_tab_becomes_invisible_after_being_selected_when_initially_visible_then_eligibility_changes() throws {
        // Given
        let mockPOSEligibilityChecker = MockAsyncPOSEligibilityChecker()
        mockPOSEligibilityChecker.initialVisibility = true

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        // For initializing `CardPresentPaymentService` async in `POSTabCoordinator.presentPOSView`.
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .publishCardReaderConnections(completion) = action {
                completion(Just<[CardReader]>([]).eraseToAnyPublisher())
            }
            if case let .observeCardReaderUpdateState(completion) = action {
                completion(Just(.none).eraseToAnyPublisher())
            }
        }

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        stores: stores,
                                        posTabVisibilityCheckerFactory: { _ in mockPOSEligibilityChecker })
        }) else {
            return
        }

        window.rootViewController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When POS tab initial visibility is set to true
        let siteID: Int64 = 1126
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

        // Then POS tab is visible before eligibility check is returned
        waitUntil {
            tabBarController.tabRootViewControllers.count == 5
        }
        assertThat(tabBarController.tabRootViewController(tab: .pointOfSale, isPOSTabVisible: true),
                   isAnInstanceOf: POSTabViewController.self)
        let posTabContainerController = try XCTUnwrap(
            tabBarController.viewControllers?[WooTab.pointOfSale.visibleIndex(isPOSTabVisible: true)] as? TabContainerController
        )

        // When selecting POS tab
        XCTAssertFalse(tabBarController.tabBarController(tabBarController, shouldSelect: posTabContainerController))

        waitUntil {
            posTabContainerController.presentedViewController is UIHostingController<PointOfSaleEntryPointView>
        }

        // When POS tab becomes invisible
        mockPOSEligibilityChecker.setVisibilityResult(false)

        // Then POS tab is hidden
        waitUntil {
            tabBarController.tabRootViewControllers.count == 4
        }

        assertThat(tabBarController.tabRootViewController(tab: .myStore, isPOSTabVisible: false),
                   isAnInstanceOf: DashboardViewHostingController.self)
        assertThat(tabBarController.tabRootViewController(tab: .orders, isPOSTabVisible: false),
                   isAnInstanceOf: OrdersSplitViewWrapperController.self)
        assertThat(tabBarController.tabRootViewController(tab: .products, isPOSTabVisible: false),
                   isAnInstanceOf: ProductsViewController.self)

        let hubMenuNavigationController = try XCTUnwrap(tabBarController.tabRootViewController(tab: .hubMenu, isPOSTabVisible: false) as? UINavigationController)
        assertThat(hubMenuNavigationController.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_pos_tab_visibility_is_cached_after_eligibility_check() throws {
        // Given
        let mockPOSEligibilityChecker = MockAsyncPOSEligibilityChecker()
        mockPOSEligibilityChecker.initialVisibility = false

        let mockPOSEligibilityService = MockPOSEligibilityService()

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        stores: stores,
                                        posTabVisibilityCheckerFactory: { _ in mockPOSEligibilityChecker },
                                        posEligibilityService: mockPOSEligibilityService)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When POS tab initial visibility is set to true
        let siteID: Int64 = 1216
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))
        mockPOSEligibilityChecker.setVisibilityResult(true)

        waitUntil {
            tabBarController.tabRootViewControllers.count == 5
        }

        // Then
        XCTAssertEqual(mockPOSEligibilityService.loadCachedPOSTabVisibility(siteID: siteID), true)
    }

    func test_event_is_tracked_after_eligibility_check() throws {
        // Given
        let mockPOSEligibilityChecker = MockPOSTabVisibilityChecker()
        mockPOSEligibilityChecker.visibility = true

        let storesManager = MockStoresManager(sessionManager: .makeForTesting())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        analytics: self.analytics,
                                        stores: storesManager,
                                        posTabVisibilityCheckerFactory: { _ in mockPOSEligibilityChecker })
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let siteID: Int64 = 322
        storesManager.updateDefaultStore(storeID: siteID)
        storesManager.updateDefaultStore(.fake().copy(siteID: siteID))

        // Then
        waitUntil {
            tabBarController.tabRootViewControllers.count == 5
        }

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.pointOfSaleTabVisibilityChecked.rawValue))
        assertEqual(true, analyticsProvider.receivedProperties[safe: indexOfEvent]?["is_visible"] as? Bool)
    }

    func test_initial_tabs_visibility_is_set_from_cache() throws {
        // Given
        let siteID: Int64 = 1126
        let mockPOSEligibilityService = MockPOSEligibilityService()
        mockPOSEligibilityService.cachedTabVisibility[siteID] = true

        let userDefaults = UserDefaults(suiteName: #function)!
        userDefaults.removePersistentDomain(forName: #function)
        userDefaults.cacheBookingsTabVisibility(siteID: siteID, isVisible: true)

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        stores: stores,
                                        posEligibilityService: mockPOSEligibilityService,
                                        userDefaults: userDefaults)
        }) else {
            XCTFail("Failed to instantiate MainTabBarController")
            return
        }

        // When
        stores.updateDefaultStore(storeID: siteID)
        XCTAssertNotNil(tabBarController.view) // This triggers viewDidLoad

        // Then
        let expectedTabs: [WooTab] = [.myStore, .orders, .products, .bookings, .pointOfSale, .hubMenu]
        let visibleTabs = WooTab.visibleTabs(isPOSTabVisible: true, isBookingsTabVisible: true)
        XCTAssertEqual(tabBarController.viewControllers?.count, expectedTabs.count)
        XCTAssertEqual(visibleTabs, expectedTabs)
    }

    func test_switching_sites_applies_cached_tab_visibility() throws {
        // Arrange
        let siteA_ID: Int64 = 101
        let siteB_ID: Int64 = 202

        // Site A: POS visible, Bookings not visible
        let mockPOSEligibilityService = MockPOSEligibilityService()
        mockPOSEligibilityService.cachedTabVisibility[siteA_ID] = true
        mockPOSEligibilityService.cachedTabVisibility[siteB_ID] = false

        let userDefaults = UserDefaults(suiteName: #function)!
        userDefaults.removePersistentDomain(forName: #function)
        userDefaults.cacheBookingsTabVisibility(siteID: siteA_ID, isVisible: false)
        userDefaults.cacheBookingsTabVisibility(siteID: siteB_ID, isVisible: true)

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        let tabBarController = try XCTUnwrap(UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            MainTabBarController(coder: coder,
                                 stores: stores,
                                 posTabVisibilityCheckerFactory: { site in
                                     POSTabVisibilityChecker(site: site, eligibilityService: mockPOSEligibilityService)
                                 },
                                 posEligibilityService: mockPOSEligibilityService,
                                 bookingsEligibilityCheckerFactory: { site, isPOSTabVisible in
                                     BookingsTabEligibilityChecker(site: site, userDefaults: userDefaults, isPOSTabVisible: isPOSTabVisible)
                                 },
                                 userDefaults: userDefaults)
        }))

        // Trigger viewDidLoad
        XCTAssertNotNil(tabBarController.view)

        // Action 1: Switch to Site A
        stores.updateDefaultStore(storeID: siteA_ID)
        stores.updateDefaultStore(.fake().copy(siteID: siteA_ID))

        // Assert 1: Site A should have POS, but not Bookings.
        XCTAssertEqual(tabBarController.viewControllers?.count, 5, "There should be 5 tabs for Site A")
        XCTAssertFalse(tabBarController.tabRootViewControllers.contains(where: { $0 is BookingsTabViewHostingController }),
                       "Bookings tab should not be visible for Site A")
        XCTAssertTrue(tabBarController.tabRootViewControllers.contains(where: { $0 is POSTabViewController }),
                       "POS tab should be visible for Site A")


        // Action 2: Switch to Site B
        stores.updateDefaultStore(storeID: siteB_ID)
        stores.updateDefaultStore(.fake().copy(siteID: siteB_ID))

        // Assert 2: Site B should have Bookings, but not POS.
        XCTAssertEqual(tabBarController.viewControllers?.count, 5, "There should be 5 tabs for Site B")
        XCTAssertTrue(tabBarController.tabRootViewControllers.contains(where: { $0 is BookingsTabViewHostingController }),
                      "Bookings tab should be visible for Site B")
        XCTAssertFalse(tabBarController.tabRootViewControllers.contains(where: { $0 is POSTabViewController }),
                       "POS tab should not be visible for Site B")
    }

    func test_bookings_tab_becomes_invisible_after_being_selected_when_initially_visible_then_eligibility_changes() throws {
        // Given
        let mockBookingsEligibilityChecker = MockAsyncBookingsEligibilityChecker()
        mockBookingsEligibilityChecker.initialVisibility = true

        let mockFeatureFlagService = MockFeatureFlagService()
        ServiceLocator.setFeatureFlagService(mockFeatureFlagService)

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        stores: stores,
                                        bookingsEligibilityCheckerFactory: { _, _ in mockBookingsEligibilityChecker })
        }) else {
            return
        }

        window.rootViewController = tabBarController

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When bookings tab initial visibility is set to true
        let siteID: Int64 = 1126
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))

        // Then bookings tab is visible before eligibility check is returned
        waitUntil {
            tabBarController.tabRootViewControllers.count == 5
        }
        assertThat(tabBarController.tabRootViewController(
            tab: .bookings,
            isPOSTabVisible: false,
            isBookingsTabVisible: true
        ), isAnInstanceOf: BookingsTabViewHostingController.self)

        // When bookings tab becomes invisible
        mockBookingsEligibilityChecker.setVisibilityResult(false)

        // Then bookings tab is hidden
        waitUntil {
            tabBarController.tabRootViewControllers.count == 4
        }

        assertThat(tabBarController.tabRootViewController(
            tab: .myStore,
            isPOSTabVisible: false,
            isBookingsTabVisible: false
        ), isAnInstanceOf: DashboardViewHostingController.self)
        assertThat(tabBarController.tabRootViewController(
            tab: .orders,
            isPOSTabVisible: false,
            isBookingsTabVisible: false
        ), isAnInstanceOf: OrdersSplitViewWrapperController.self)
        assertThat(tabBarController.tabRootViewController(
            tab: .products,
            isPOSTabVisible: false,
            isBookingsTabVisible: false
        ), isAnInstanceOf: ProductsViewController.self)

        let hubMenuNavigationController = try XCTUnwrap(tabBarController.tabRootViewController(
            tab: .hubMenu,
            isPOSTabVisible: false,
            isBookingsTabVisible: false
        ) as? UINavigationController)
        assertThat(hubMenuNavigationController.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }
}

extension MainTabBarController {
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

    func tabRootViewController(tab: WooTab, isPOSTabVisible: Bool, isBookingsTabVisible: Bool = false) -> UIViewController? {
        // swiftlint:disable:next empty_enum_arguments
        guard let viewController = tabRootViewControllers[safe: tab.visibleIndex(
            isPOSTabVisible: isPOSTabVisible,
            isBookingsTabVisible: isBookingsTabVisible
        )] else {
            XCTFail("Unexpected access to root controller at tab: \(tab)")
            return nil
        }
        return viewController
    }

    func tabContainerController(tab: WooTab, isPOSTabVisible: Bool, isBookingsTabVisible: Bool = false) -> UIViewController? {
        guard let viewController = viewControllers?[tab.visibleIndex(isPOSTabVisible: isPOSTabVisible, isBookingsTabVisible: isBookingsTabVisible)] else {
            XCTFail("Unexpected access to container controller at tab: \(tab)")
            return nil
        }
        return viewController
    }
}

private final class MockAsyncPOSEligibilityChecker: POSTabVisibilityCheckerProtocol {
    var initialVisibility: Bool = false
    private var visibilityResult: Bool?
    private var visibilityContinuation: CheckedContinuation<Bool, Never>?

    func setVisibilityResult(_ result: Bool) {
        visibilityResult = result
        if let continuation = visibilityContinuation {
            visibilityContinuation = nil
            continuation.resume(returning: result)
        }
    }

    func checkInitialVisibility() -> Bool {
        initialVisibility
    }

    func checkVisibility() async -> Bool {
        if let visibilityResult {
            return visibilityResult
        }
        return await withCheckedContinuation { continuation in
            visibilityContinuation = continuation
            // If we already have a result, return it immediately.
            if visibilityContinuation == nil {
                continuation.resume(returning: visibilityResult ?? true)
            }
        }
    }
}

private final class MockAsyncBookingsEligibilityChecker: BookingsTabEligibilityCheckerProtocol {
    var initialVisibility: Bool = false
    private var visibilityResult: Bool?
    private var visibilityContinuation: CheckedContinuation<Bool, Never>?

    func setVisibilityResult(_ result: Bool) {
        visibilityResult = result
        if let continuation = visibilityContinuation {
            visibilityContinuation = nil
            continuation.resume(returning: result)
        }
    }

    func checkInitialVisibility() -> Bool {
        initialVisibility
    }

    func checkVisibility() async -> Bool {
        if let visibilityResult {
            return visibilityResult
        }
        return await withCheckedContinuation { continuation in
            visibilityContinuation = continuation
            // If we already have a result, return it immediately.
            if visibilityContinuation == nil {
                continuation.resume(returning: visibilityResult ?? true)
            }
        }
    }
}
