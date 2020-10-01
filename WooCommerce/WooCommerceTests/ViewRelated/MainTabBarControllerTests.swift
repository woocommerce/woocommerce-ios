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

    func test_tab_root_viewControllers_are_replaced_after_updating_to_a_different_site() throws {
        // Arrange
        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        let viewControllersBeforeSiteChange = tabBarController.tabRootViewControllers
        stores.updateDefaultStore(storeID: 630)
        let viewControllersAfterSiteChange = tabBarController.tabRootViewControllers

        // Assert
        XCTAssertEqual(viewControllersBeforeSiteChange.count, viewControllersAfterSiteChange.count)
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.myStore.visibleIndex()], viewControllersAfterSiteChange[WooTab.myStore.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.orders.visibleIndex()], viewControllersAfterSiteChange[WooTab.orders.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.products.visibleIndex()], viewControllersAfterSiteChange[WooTab.products.visibleIndex()])
        XCTAssertNotEqual(viewControllersBeforeSiteChange[WooTab.reviews.visibleIndex()], viewControllersAfterSiteChange[WooTab.reviews.visibleIndex()])
    }

    func test_tab_view_controllers_stay_the_same_after_updating_to_the_same_site() throws {
        // Arrange
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
        // Trigger `viewDidLoad`
        XCTAssertNotNil(tabBarController.view)

        // Action
        stores.updateDefaultStore(storeID: 134)
        tabBarController.navigateTo(.products)
        let selectedTabIndexBeforeSiteChange = tabBarController.selectedIndex
        stores.updateDefaultStore(storeID: 630)
        let selectedTabIndexAfterSiteChange = tabBarController.selectedIndex

        // Assert
        XCTAssertEqual(selectedTabIndexBeforeSiteChange, WooTab.products.visibleIndex())
        XCTAssertEqual(selectedTabIndexAfterSiteChange, WooTab.myStore.visibleIndex())
    }
}

private extension MainTabBarController {
    var tabRootViewControllers: [UIViewController] {
        viewControllers?.compactMap { $0 as? UINavigationController }.compactMap { $0.viewControllers.first } ?? []
    }
}
