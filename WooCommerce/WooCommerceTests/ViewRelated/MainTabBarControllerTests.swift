import XCTest
@testable import WooCommerce

private var isProductListFeatureOn: Bool = false

extension FeatureFlag {
    var enabled: Bool {
        switch self {
        case .productList:
            return isProductListFeatureOn
        default:
            return true
        }
    }
}

class MainTabBarControllerTests: XCTestCase {

    func testTabsWhenProductListFeatureIsOff() {
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService(isProductListFeatureOn: false))

        let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(ofClass: MainTabBarController.self)!
        XCTAssertNotNil(tabBarController.view)

        XCTAssertEqual(tabBarController.viewControllers?.count, 3)
    }

    func testTabsWhenProductListFeatureIsOn() {
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService(isProductListFeatureOn: true))

        let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(ofClass: MainTabBarController.self)!
        XCTAssertNotNil(tabBarController.view)

        XCTAssertEqual(tabBarController.viewControllers?.count, 4)
    }

}

private struct MockFeatureFlagService: FeatureFlagService {
    var isProductListFeatureOn: Bool = false

    init(isProductListFeatureOn: Bool) {
        self.isProductListFeatureOn = isProductListFeatureOn
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .productList:
            return isProductListFeatureOn
        default:
            return false
        }
    }
}
