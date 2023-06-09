import XCTest
@testable import WooCommerce

final class ShareProductCoordinatorTests: XCTestCase {

    private var navigationController: UINavigationController!
    private let productPath = "https://example.com"

    override func setUp() {
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
        super.setUp()
    }

    override func tearDown() {
        navigationController = nil
        super.tearDown()
    }

    func test_default_share_sheet_is_displayed_when_AI_is_not_available() throws {
        // Given
        let checker = MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: false)
        let coordinator = ShareProductCoordinator(siteID: 123,
                                                  productURL: try XCTUnwrap(URL(string: productPath)),
                                                  productName: "Test",
                                                  shareSheetAnchorItem: UIBarButtonItem(systemItem: .done),
                                                  shareProductEligibilityChecker: checker,
                                                  navigationController: navigationController)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is UIActivityViewController
        }
    }

}
