import XCTest
@testable import WooCommerce

final class AddProductWithAIContainerViewModelTests: XCTestCase {
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
