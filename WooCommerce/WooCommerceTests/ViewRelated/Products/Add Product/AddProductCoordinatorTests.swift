import TestKit
import XCTest
import Yosemite

@testable import WooCommerce
import WordPressUI

final class AddProductCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var storageManager: MockStorageManager!
    private let sampleSiteID: Int64 = 100
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()
        storageManager = MockStorageManager()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        navigationController = nil
        storageManager = nil

        analytics = nil
        analyticsProvider = nil

        super.tearDown()
    }

    func test_it_presents_bottom_sheet_on_start() {
        // Arrange
        let coordinator = makeAddProductCoordinator()

        // Action
        coordinator.start()
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Assert
        assertThat(coordinator.navigationController.presentedViewController, isAnInstanceOf: BottomSheetViewController.self)
    }

    func test_it_presents_AddProductWithAIActionSheet_on_start_when_eligible_for_ProductCreationAI() {
        // Given
        let coordinator = makeAddProductCoordinator(
            addProductWithAIEligibilityChecker: MockProductCreationAIEligibilityChecker(isEligible: true)
        )

        // When
        coordinator.start()
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        assertThat(coordinator.navigationController.presentedViewController, isAnInstanceOf: AddProductWithAIActionSheetHostingController.self)
    }

    func test_it_presents_other_bottom_sheet_on_start_when_not_eligible_for_ProductCreationAI() {
        // Given
        storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: sampleSiteID, isSampleItem: false))
        let coordinator = makeAddProductCoordinator(
            addProductWithAIEligibilityChecker: MockProductCreationAIEligibilityChecker(isEligible: false)
        )

        // When
        coordinator.start()
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        assertThat(coordinator.navigationController.presentedViewController, isAnInstanceOf: BottomSheetViewController.self)
    }

    func test_it_presents_product_form_on_start_when_the_source_is_announcement_modal() {
        // Given
        let coordinator = makeAddProductCoordinator(
            source: .productDescriptionAIAnnouncementModal,
            addProductWithAIEligibilityChecker: MockProductCreationAIEligibilityChecker(isEligible: true)
        )

        // When
        coordinator.start()

        // Then
        waitUntil {
            coordinator.navigationController.topViewController is ProductFormViewController<ProductFormViewModel>
        }
    }

    // MARK: Analytics

    func test_it_tracks_ai_entry_point_displayed_event_when_presenting_AddProductWithAIActionSheet() throws {
        // Given
        let coordinator = makeAddProductCoordinator(
            addProductWithAIEligibilityChecker: MockProductCreationAIEligibilityChecker(isEligible: true)
        )

        assertEmpty(analyticsProvider.receivedEvents)

        // When
        coordinator.start()
        waitUntil {
            coordinator.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_entry_point_displayed"))
    }
}

private extension AddProductCoordinatorTests {
    func makeAddProductCoordinator(
        source: AddProductCoordinator.Source = .productsTab,
        addProductWithAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol = MockProductCreationAIEligibilityChecker()
    ) -> AddProductCoordinator {
        let view = UIView()
        return AddProductCoordinator(siteID: sampleSiteID,
                                     source: source,
                                     sourceView: .view(view),
                                     sourceNavigationController: navigationController,
                                     storage: storageManager,
                                     addProductWithAIEligibilityChecker: addProductWithAIEligibilityChecker,
                                     analytics: analytics,
                                     isFirstProduct: false)
    }
}
