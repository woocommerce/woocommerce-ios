import XCTest
@testable import WooCommerce

final class ProductDescriptionAICoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        navigationController = nil
        super.tearDown()
    }

    func test_ProductDescriptionGenerationHostingController_is_presented_after_start_is_called() throws {
        // Given
        let coordinator = ProductDescriptionAICoordinator(product: EditableProductModel(product: .fake()),
                                                          navigationController: navigationController,
                                                          source: .productForm,
                                                          analytics: analytics) { _ in }

        // When
        coordinator.start()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is ProductDescriptionGenerationHostingController
        }
    }

    func test_productDescriptionAIButtonTapped_is_tracked_when_bottom_sheet_is_presented() throws {
        // Given
        let coordinator = ProductDescriptionAICoordinator(product: EditableProductModel(product: .fake()),
                                                          navigationController: navigationController,
                                                          source: .aztecEditor,
                                                          analytics: analytics) { _ in }

        // When
        coordinator.start()
        waitUntil {
            self.navigationController.presentedViewController is ProductDescriptionGenerationHostingController
        }

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "product_description_ai_button_tapped")
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(eventProperties["source"] as? String, "aztec_editor")
    }
}
