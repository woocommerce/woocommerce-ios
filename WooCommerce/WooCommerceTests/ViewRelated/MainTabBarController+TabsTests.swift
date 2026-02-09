import TestKit
import XCTest
@testable import WooCommerce

final class MainTabBarController_TabsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        SessionManager.removeTestingDatabase()
    }

    func test_tab_view_controllers_are_not_empty_after_updating_default_site() throws {
        // Arrange
        let storesManager = MockStoresManager(sessionManager: .makeForTesting())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder, featureFlagService: MockFeatureFlagService(), stores: storesManager)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 980
        storesManager.updateDefaultStore(storeID: siteID)
        storesManager.updateDefaultStore(.fake().copy(siteID: siteID))

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
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

    func test_tab_view_controllers_include_pos_tab_when_pos_tab_is_visible() throws {
        // Given
        let mockPOSEligibilityChecker = MockPOSTabVisibilityChecker()
        mockPOSEligibilityChecker.visibility = true

        let storesManager = MockStoresManager(sessionManager: .makeForTesting())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: MockFeatureFlagService(),
                                        stores: storesManager,
                                        posTabVisibilityCheckerFactory: { _ in mockPOSEligibilityChecker })
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let siteID: Int64 = 314
        storesManager.updateDefaultStore(storeID: siteID)
        storesManager.updateDefaultStore(.fake().copy(siteID: siteID))

        // Then
        waitUntil {
            tabBarController.tabRootViewControllers.count == 5
        }
        assertThat(tabBarController.tabRootViewController(tab: .myStore, isPOSTabVisible: true),
                   isAnInstanceOf: DashboardViewHostingController.self)
        assertThat(tabBarController.tabRootViewController(tab: .orders, isPOSTabVisible: true),
                   isAnInstanceOf: OrdersSplitViewWrapperController.self)
        assertThat(tabBarController.tabRootViewController(tab: .products, isPOSTabVisible: true),
                   isAnInstanceOf: ProductsViewController.self)
        assertThat(tabBarController.tabRootViewController(tab: .pointOfSale, isPOSTabVisible: true),
                   isAnInstanceOf: POSTabViewController.self)

        let hubMenuNavigationController = try XCTUnwrap(tabBarController.tabRootViewController(tab: .hubMenu, isPOSTabVisible: true) as? UINavigationController)
        assertThat(hubMenuNavigationController.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_tab_view_controllers_exclude_pos_tab_when_pos_tab_is_not_visible() throws {
        // Given
        let mockPOSEligibilityChecker = MockPOSTabVisibilityChecker()
        mockPOSEligibilityChecker.visibility = false

        let storesManager = MockStoresManager(sessionManager: .makeForTesting())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: MockFeatureFlagService(),
                                        stores: storesManager,
                                        posTabVisibilityCheckerFactory: { _ in mockPOSEligibilityChecker })
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let siteID: Int64 = 707
        storesManager.updateDefaultStore(storeID: siteID)
        storesManager.updateDefaultStore(.fake().copy(siteID: siteID))

        // Then
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

    func test_tab_view_controllers_do_not_change_when_pos_visibility_changes() throws {
        // Given
        let mockPOSEligibilityChecker = MockPOSTabVisibilityChecker()
        mockPOSEligibilityChecker.visibility = false

        let storesManager = MockStoresManager(sessionManager: .makeForTesting())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: MockFeatureFlagService(),
                                        stores: storesManager,
                                        posTabVisibilityCheckerFactory: { _ in mockPOSEligibilityChecker })
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let siteID: Int64 = 303
        storesManager.updateDefaultStore(storeID: siteID)
        storesManager.updateDefaultStore(.fake().copy(siteID: siteID))

        // Then initial state
        waitUntil {
            tabBarController.tabRootViewControllers.count == 4
        }

        // When - change POS eligibility
        mockPOSEligibilityChecker.visibility = true

        // Then tabs remain the same
        XCTAssertEqual(tabBarController.tabRootViewControllers.count, 4)
    }

    func test_tab_view_controllers_include_bookings_tab_when_bookings_tab_is_visible() throws {
        // Given
        let mockBookingsEligibilityChecker = MockBookingsEligibilityChecker()
        mockBookingsEligibilityChecker.visibility = true

        let storesManager = MockStoresManager(sessionManager: .makeForTesting())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: MockFeatureFlagService(),
                                        stores: storesManager,
                                        bookingsEligibilityCheckerFactory: { _, _ in mockBookingsEligibilityChecker })
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let siteID: Int64 = 314
        storesManager.updateDefaultStore(storeID: siteID)
        storesManager.updateDefaultStore(.fake().copy(siteID: siteID))

        // Then
        waitUntil {
            tabBarController.tabRootViewControllers.count == 5
        }
        assertThat(tabBarController.tabRootViewController(
            tab: .myStore,
            isPOSTabVisible: false,
            isBookingsTabVisible: true
        ), isAnInstanceOf: DashboardViewHostingController.self)
        assertThat(tabBarController.tabRootViewController(
            tab: .orders,
            isPOSTabVisible: false,
            isBookingsTabVisible: true
        ), isAnInstanceOf: OrdersSplitViewWrapperController.self)
        assertThat(tabBarController.tabRootViewController(
            tab: .products,
            isPOSTabVisible: false,
            isBookingsTabVisible: true
        ), isAnInstanceOf: ProductsViewController.self)
        assertThat(tabBarController.tabRootViewController(
            tab: .bookings,
            isPOSTabVisible: false,
            isBookingsTabVisible: true
        ), isAnInstanceOf: BookingsTabViewHostingController.self)

        let hubMenuNavigationController = try XCTUnwrap(tabBarController.tabRootViewController(
            tab: .hubMenu,
            isPOSTabVisible: false,
            isBookingsTabVisible: true
        ) as? UINavigationController)
        assertThat(hubMenuNavigationController.topViewController,
                   isAnInstanceOf: HubMenuViewController.self)
    }

    func test_tab_view_controllers_exclude_bookings_tab_when_bookings_tab_is_not_visible() throws {
        // Given
        let mockBookingsEligibilityChecker = MockBookingsEligibilityChecker()
        mockBookingsEligibilityChecker.visibility = false

        let storesManager = MockStoresManager(sessionManager: .makeForTesting())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: MockFeatureFlagService(),
                                        stores: storesManager,
                                        bookingsEligibilityCheckerFactory: { _, _ in mockBookingsEligibilityChecker })
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let siteID: Int64 = 707
        storesManager.updateDefaultStore(storeID: siteID)
        storesManager.updateDefaultStore(.fake().copy(siteID: siteID))

        // Then
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

    func test_tab_view_controllers_do_not_change_when_bookings_visibility_changes() throws {
        // Given
        let mockBookingsEligibilityChecker = MockBookingsEligibilityChecker()
        mockBookingsEligibilityChecker.visibility = false

        let storesManager = MockStoresManager(sessionManager: .makeForTesting())

        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder,
                                        featureFlagService: MockFeatureFlagService(),
                                        stores: storesManager,
                                        bookingsEligibilityCheckerFactory: { _, _ in mockBookingsEligibilityChecker })
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // When
        let siteID: Int64 = 303
        storesManager.updateDefaultStore(storeID: siteID)
        storesManager.updateDefaultStore(.fake().copy(siteID: siteID))

        // Then initial state
        waitUntil {
            tabBarController.tabRootViewControllers.count == 4
        }

        // When - change bookings eligibility
        mockBookingsEligibilityChecker.visibility = true

        // Then tabs remain the same
        XCTAssertEqual(tabBarController.tabRootViewControllers.count, 4)
    }


    func test_tab_root_viewControllers_are_replaced_after_updating_to_a_different_site() throws {
        // Arrange
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder, featureFlagService: MockFeatureFlagService(), stores: stores)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteIDBefore: Int64 = 134
        stores.updateDefaultStore(storeID: siteIDBefore)
        stores.updateDefaultStore(.fake().copy(siteID: siteIDBefore))
        let viewControllersBeforeSiteChange = tabBarController.tabRootViewControllers

        let siteIDAfter: Int64 = 630
        stores.updateDefaultStore(storeID: siteIDAfter)
        stores.updateDefaultStore(.fake().copy(siteID: siteIDAfter))
        let viewControllersAfterSiteChange = tabBarController.tabRootViewControllers

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange.count, viewControllersAfterSiteChange.count)
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.myStore.visibleIndex(isPOSTabVisible: false)],
                          viewControllersAfterSiteChange[WooTab.myStore.visibleIndex(isPOSTabVisible: false)])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.orders.visibleIndex(isPOSTabVisible: false)],
                          viewControllersAfterSiteChange[WooTab.orders.visibleIndex(isPOSTabVisible: false)])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.products.visibleIndex(isPOSTabVisible: false)],
                          viewControllersAfterSiteChange[WooTab.products.visibleIndex(isPOSTabVisible: false)])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.hubMenu.visibleIndex(isPOSTabVisible: false)],
                          viewControllersAfterSiteChange[WooTab.hubMenu.visibleIndex(isPOSTabVisible: false)])
    }

    func test_tab_view_controllers_stay_the_same_after_updating_to_the_same_site() throws {
        // Arrange
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController(creator: { coder in
            return MainTabBarController(coder: coder, stores: stores)
        }) else {
            return
        }

        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 610
        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))
        let viewControllersBeforeSiteChange = try XCTUnwrap(tabBarController.viewControllers)

        stores.updateDefaultStore(storeID: siteID)
        stores.updateDefaultStore(.fake().copy(siteID: siteID))
        let viewControllersAfterSiteChange = try XCTUnwrap(tabBarController.viewControllers)

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange, viewControllersAfterSiteChange)
    }
}

private final class MockBookingsEligibilityChecker {
    var visibility: Bool = false
}

extension MockBookingsEligibilityChecker: BookingsTabEligibilityCheckerProtocol {
    func checkInitialVisibility() -> Bool {
        visibility
    }

    func checkVisibility() async -> Bool {
        visibility
    }
}
