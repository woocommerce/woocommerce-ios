import XCTest
@testable import WooCommerce

final class AddProductWithAIContainerViewModelTests: XCTestCase {

    // MARK: - `canBeDismissed`

    func test_canBeDismissed_returns_true_if_current_step_is_productName_and_the_name_field_is_empty() {
        // Given
        let viewModel = AddProductWithAIContainerViewModel(siteID: 123, source: .productsTab, onCancel: {}, onCompletion: { _ in })

        // Then
        XCTAssertTrue(viewModel.canBeDismissed)
    }

    func test_canBeDismissed_returns_False_if_current_step_is_productName_and_the_name_field_is_not_empty() {
        // Given
        let viewModel = AddProductWithAIContainerViewModel(siteID: 123, source: .productsTab, onCancel: {}, onCompletion: { _ in })

        // When
        viewModel.addProductNameViewModel.productNameContent = "iPhone 15"

        // Then
        XCTAssertFalse(viewModel.canBeDismissed)
    }

    func test_canBeDismissed_returns_False_if_current_step_is_not_product_name() {
        // Given
        let viewModel = AddProductWithAIContainerViewModel(siteID: 123, source: .productsTab, onCancel: {}, onCompletion: { _ in })

        // When
        viewModel.onContinueWithProductName(name: "iPhone 15")

        // Then
        XCTAssertFalse(viewModel.canBeDismissed)

        // When
        viewModel.onProductFeaturesAdded(features: "No lightning jack")

        // Then
        XCTAssertFalse(viewModel.canBeDismissed)
    }

    // MARK: `didGenerateDataFromPackage`

    func test_didGenerateDataFromPackage_sets_values_from_package_flow() {
        // Given
        let expectedName = "Fancy new smart phone"
        let expectedDescription = "Phone, White color"
        let expectedFeatures = expectedDescription

        let viewModel = AddProductWithAIContainerViewModel(siteID: 123,
                                                           source: .productDescriptionAIAnnouncementModal,
                                                           onCancel: { },
                                                           onCompletion: { _ in })

        // When
        viewModel.didGenerateDataFromPackage(.init(name: expectedName,
                                                   description: expectedDescription,
                                                   image: nil))

        // Then
        XCTAssertEqual(viewModel.productName, expectedName)
        XCTAssertEqual(viewModel.productDescription, expectedDescription)
        XCTAssertEqual(viewModel.productFeatures, expectedFeatures)
    }
}
