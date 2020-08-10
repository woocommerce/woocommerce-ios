import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductsTabProductViewModel_VariationTests: XCTestCase {
    func test_product_cell_view_model_shows_disabled_details_text_when_variation_is_disabled() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .privateStatus)
        let model = EditableProductVariationModel(productVariation: variation)

        // Action
        let viewModel = ProductsTabProductViewModel(productVariationModel: model)

        // Assert
        XCTAssertEqual(viewModel.detailsAttributedString.string, EditableProductVariationModel.DetailsLocalization.disabledText)
    }

    func test_product_cell_view_model_shows_no_price_details_text_when_variation_is_enabled_but_missing_price() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .publish, regularPrice: nil)
        let model = EditableProductVariationModel(productVariation: variation)

        // Action
        let viewModel = ProductsTabProductViewModel(productVariationModel: model)

        // Assert
        XCTAssertEqual(viewModel.detailsAttributedString.string, EditableProductVariationModel.DetailsLocalization.noPriceText)
    }

    func test_product_cell_view_model_shows_price_details_text_when_variation_is_enabled_and_has_price() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .publish, regularPrice: "6")
        let model = EditableProductVariationModel(productVariation: variation)
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)

        // Action
        let viewModel = ProductsTabProductViewModel(productVariationModel: model, currencySettings: currencySettings)

        // Assert
        XCTAssertEqual(viewModel.detailsAttributedString.string, "$6.000")
    }
}
