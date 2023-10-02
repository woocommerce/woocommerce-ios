import XCTest
@testable import WooCommerce

final class AddProductFeaturesViewModelTests: XCTestCase {
    func test_productFeatures_is_updated_with_initial_features() {
        // Given
        let expectedFeatures = "Fancy new smart phone"
        let viewModel = AddProductFeaturesViewModel(siteID: 123,
                                                    productName: "iPhone 15",
                                                    productFeatures: expectedFeatures,
                                                    onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.productFeatures, expectedFeatures)
    }

    func test_proceedToPreview_triggers_onCompletion() {
        // Given
        var triggeredFeatures: String?
        let expectedFeatures = "Fancy new smart phone"
        let viewModel = AddProductFeaturesViewModel(siteID: 123,
                                                    productName: "iPhone 15",
                                                    onCompletion: { triggeredFeatures = $0 })

        // When
        viewModel.productFeatures = expectedFeatures
        viewModel.proceedToPreview()

        // Then
        XCTAssertEqual(triggeredFeatures, expectedFeatures)
    }
}
