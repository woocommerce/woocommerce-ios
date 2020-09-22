import TestKit
import XCTest
@testable import WooCommerce

final class MainTabBarControllerTests: XCTestCase {
    private var stores: StoresManager!
    private var tabBarController: MainTabBarController!

    override func setUp() {
        super.setUp()
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        stores = DefaultStoresManager.testingInstance
        ServiceLocator.setStores(stores)
        tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController
    }

    override func tearDown() {
        SessionManager.testingInstance.reset()
        tabBarController = nil
        stores = nil
        super.tearDown()
    }

    func test_tab_view_controllers_are_not_empty_after_updating_default_site() {
        // Arrange
        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
        assertThat((tabBarController.viewControllers?[WooTab.myStore.visibleIndex()] as? UINavigationController)?.topViewController,
                   isAnInstanceOf: DashboardViewController.self)
        assertThat((tabBarController.viewControllers?[WooTab.orders.visibleIndex()] as? UINavigationController)?.topViewController,
                   isAnInstanceOf: OrdersRootViewController.self)
        assertThat((tabBarController.viewControllers?[WooTab.products.visibleIndex()] as? UINavigationController)?.topViewController,
                   isAnInstanceOf: ProductsViewController.self)
        assertThat((tabBarController.viewControllers?[WooTab.reviews.visibleIndex()] as? UINavigationController)?.topViewController,
                   isAnInstanceOf: ReviewsViewController.self)
    }

    func test_tab_view_controllers_are_empty_after_deauthentication() {
        // Arrange
        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        let siteID: Int64 = 134
        stores.updateDefaultStore(storeID: siteID)
        stores.deauthenticate()

        // Assert
        XCTAssertEqual(tabBarController.viewControllers?.count, 0)
    }

    // TODO-1838: update test case after more tabs are torn down upon site ID changes.
    func test_tab_view_controllers_contain_a_different_reviews_tab_after_updating_to_a_different_site() throws {
        // Arrange
        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        let viewControllersBeforeSiteChange = try XCTUnwrap(tabBarController.viewControllers)
        stores.updateDefaultStore(storeID: 630)
        let viewControllersAfterSiteChange = try XCTUnwrap(tabBarController.viewControllers)

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange.count, viewControllersAfterSiteChange.count)
        XCTAssertEqual(viewControllersBeforeSiteChange[WooTab.myStore.visibleIndex()], viewControllersAfterSiteChange[WooTab.myStore.visibleIndex()])
        XCTAssertEqual(viewControllersBeforeSiteChange[WooTab.orders.visibleIndex()], viewControllersAfterSiteChange[WooTab.orders.visibleIndex()])
        XCTAssertEqual(viewControllersBeforeSiteChange[WooTab.products.visibleIndex()], viewControllersAfterSiteChange[WooTab.products.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.reviews.visibleIndex()], viewControllersAfterSiteChange[WooTab.reviews.visibleIndex()])
    }
}
