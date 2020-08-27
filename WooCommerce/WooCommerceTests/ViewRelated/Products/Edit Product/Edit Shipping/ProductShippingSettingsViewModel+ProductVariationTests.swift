import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductShippingSettingsViewModel_ProductVariationTests: XCTestCase {
    typealias Section = ProductShippingSettingsViewController.Section

    func test_sections_do_not_contain_shipping_class_for_a_variation() {
        // Arrange
        let dimensions = ProductDimensions(length: "2.9", width: "", height: "1116")
        let productVariation = MockProductVariation().productVariation()
            .copy(weight: "1.6",
                  dimensions: dimensions,
                  shippingClass: "60-day",
                  shippingClassID: 2)
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Act
        let viewModel = ProductShippingSettingsViewModel(product: model)

        // Assert
        let expectedSections: [Section] = [.init(rows: [.weight, .length, .width, .height])]
        XCTAssertEqual(viewModel.sections, expectedSections)
    }
}
