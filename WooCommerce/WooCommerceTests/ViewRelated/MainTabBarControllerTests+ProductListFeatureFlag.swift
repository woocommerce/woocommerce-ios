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

    func testTabBarViewControllers() {

        XCTAssertNotNil(tabBarController.view)
        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
    }

}
