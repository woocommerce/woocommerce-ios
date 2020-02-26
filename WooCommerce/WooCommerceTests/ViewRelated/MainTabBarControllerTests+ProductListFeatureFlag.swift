import XCTest
@testable import WooCommerce

class MainTabBarControllerTests: XCTestCase {

    private var tabBarController: MainTabBarController!

    override func setUp() {
        super.setUp()
        tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? MainTabBarController
    }

    override func tearDown() {
        tabBarController = nil
        super.tearDown()
    }

    func testTabBarViewControllersWhenProductListFeatureIsOff() {
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService(isProductListFeatureOn: false))

        XCTAssertNotNil(tabBarController.view)

        XCTAssertEqual(tabBarController.viewControllers?.count, 3)
    }

    func testWooTabIndexWhenProductListFeatureIsOff() {
        let isProductListFeatureOn = false

        // Tab --> index
        XCTAssertEqual(WooTab.myStore.visibleIndex(isProductListFeatureOn: isProductListFeatureOn), 0)
        XCTAssertEqual(WooTab.orders.visibleIndex(isProductListFeatureOn: isProductListFeatureOn), 1)
        XCTAssertEqual(WooTab.reviews.visibleIndex(isProductListFeatureOn: isProductListFeatureOn), 2)

        // Index --> tab
        XCTAssertEqual(WooTab(visibleIndex: 0, isProductListFeatureOn: isProductListFeatureOn), .myStore)
        XCTAssertEqual(WooTab(visibleIndex: 1, isProductListFeatureOn: isProductListFeatureOn), .orders)
        XCTAssertEqual(WooTab(visibleIndex: 2, isProductListFeatureOn: isProductListFeatureOn), .reviews)
    }

    func testWooTabIndexWhenProductListFeatureIsOn() {
        let isProductListFeatureOn = true

        // Tab --> index
        XCTAssertEqual(WooTab.myStore.visibleIndex(isProductListFeatureOn: isProductListFeatureOn), 0)
        XCTAssertEqual(WooTab.orders.visibleIndex(isProductListFeatureOn: isProductListFeatureOn), 1)
        XCTAssertEqual(WooTab.products.visibleIndex(isProductListFeatureOn: isProductListFeatureOn), 2)
        XCTAssertEqual(WooTab.reviews.visibleIndex(isProductListFeatureOn: isProductListFeatureOn), 3)

        // Index --> tab
        XCTAssertEqual(WooTab(visibleIndex: 0, isProductListFeatureOn: isProductListFeatureOn), .myStore)
        XCTAssertEqual(WooTab(visibleIndex: 1, isProductListFeatureOn: isProductListFeatureOn), .orders)
        XCTAssertEqual(WooTab(visibleIndex: 2, isProductListFeatureOn: isProductListFeatureOn), .products)
        XCTAssertEqual(WooTab(visibleIndex: 3, isProductListFeatureOn: isProductListFeatureOn), .reviews)
    }

}
