import XCTest
@testable import WooCommerce

final class ShareProductCoordinatorTests: XCTestCase {

    private var navigationController: UINavigationController!
    private let productPath = "https://example.com"
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        super.setUp()
    }

    override func tearDown() {
        navigationController = nil
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_default_share_sheet_is_displayed_when_AI_is_not_available() throws {
        // Given
        let checker = MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: false)
        let coordinator = ShareProductCoordinator(siteID: 123,
                                                  productURL: try XCTUnwrap(URL(string: productPath)),
                                                  productName: "Test",
                                                  productDescription: "Test description",
                                                  shareSheetAnchorItem: UIBarButtonItem(systemItem: .done),
                                                  eligibilityChecker: checker,
                                                  navigationController: navigationController)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is UIActivityViewController
        }
    }

    func test_AI_sheet_is_displayed_when_AI_is_available() throws {
        // Given
        let checker = MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: true)
        let coordinator = ShareProductCoordinator(siteID: 123,
                                                  productURL: try XCTUnwrap(URL(string: productPath)),
                                                  productName: "Test",
                                                  productDescription: "Test description",
                                                  shareSheetAnchorItem: UIBarButtonItem(systemItem: .done),
                                                  eligibilityChecker: checker,
                                                  navigationController: navigationController)

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is ProductSharingMessageGenerationHostingController
        }
    }

    func test_analytics_is_tracked_when_AI_sheet_is_displayed() throws {
        // Given
        let checker = MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: true)
        let coordinator = ShareProductCoordinator(siteID: 123,
                                                  productURL: try XCTUnwrap(URL(string: productPath)),
                                                  productName: "Test",
                                                  productDescription: "Test description",
                                                  shareSheetAnchorItem: UIBarButtonItem(systemItem: .done),
                                                  eligibilityChecker: checker,
                                                  navigationController: navigationController,
                                                  analytics: analytics)

        // When
        coordinator.start()
        waitUntil {
            self.navigationController.presentedViewController is ProductSharingMessageGenerationHostingController
        }

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "product_sharing_ai_displayed")
    }
}
