import TestKit
import XCTest
import Yosemite

@testable import WooCommerce
import WordPressUI

final class AddProductCoordinatorTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var storageManager: MockStorageManager!
    private let sampleSiteID: Int64 = 100

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()
        storageManager = MockStorageManager()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
    }

    override func tearDown() {
        navigationController = nil
        storageManager = nil
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

    func test_it_presents_AddProductWithAIActionSheet_on_start_when_eligible_for_ProductCreationAI_and_store_has_no_products() {
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

    func test_it_presents_AddProductWithAIActionSheet_on_start_when_eligible_for_ProductCreationAI_and_store_has_only_sample_products() {
        // Given
        storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: sampleSiteID, isSampleItem: true))
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

    func test_it_presents_other_bottom_sheet_on_start_when_eligible_for_ProductCreationAI_but_store_has_non_sample_products() {
        // Given
        storageManager.insertSampleProduct(readOnlyProduct: .fake().copy(siteID: sampleSiteID, isSampleItem: false))
        let coordinator = makeAddProductCoordinator(
            addProductWithAIEligibilityChecker: MockProductCreationAIEligibilityChecker(isEligible: true)
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
}

private extension AddProductCoordinatorTests {
    func makeAddProductCoordinator(
        source: AddProductCoordinator.Source = .productsTab,
        addProductWithAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol = MockProductCreationAIEligibilityChecker()
    ) -> AddProductCoordinator {
        let view = UIView()
        return AddProductCoordinator(siteID: sampleSiteID,
                                     source: source,
                                     sourceView: view,
                                     sourceNavigationController: navigationController,
                                     storage: storageManager,
                                     addProductWithAIEligibilityChecker: addProductWithAIEligibilityChecker,
                                     isFirstProduct: false)
    }
}
