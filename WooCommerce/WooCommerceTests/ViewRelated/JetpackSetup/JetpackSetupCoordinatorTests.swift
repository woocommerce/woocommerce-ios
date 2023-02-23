import XCTest
@testable import WooCommerce
@testable import Yosemite

final class JetpackSetupCoordinatorTests: XCTestCase {

    private var stores: MockStoresManager!
    private var navigationController: UINavigationController!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
        super.setUp()
    }

    override func tearDown() {
        stores = nil
        navigationController = nil
        super.tearDown()
    }

    func test_benefit_modal_is_presented_correctly() {
        // Given
        let testSite = Site.fake()
        let coordinator = JetpackSetupCoordinator(site: testSite, navigationController: navigationController)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertTrue(navigationController.presentedViewController is JetpackBenefitsHostingController)
    }

}
