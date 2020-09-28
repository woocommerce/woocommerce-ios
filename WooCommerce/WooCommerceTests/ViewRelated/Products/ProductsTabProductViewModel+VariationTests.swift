import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductsTabProductViewModel_VariationTests: XCTestCase {
    // MARK: Status / price details

    func test_product_cell_view_model_shows_disabled_details_text_when_variation_is_disabled() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .privateStatus)
        let model = EditableProductVariationModel(productVariation: variation)

        // Action
        let viewModel = ProductsTabProductViewModel(productVariationModel: model)

        // Assert
        XCTAssertTrue(viewModel.detailsAttributedString.string.contains(EditableProductVariationModel.DetailsLocalization.disabledText))
    }

    func test_product_cell_view_model_shows_no_price_details_text_when_variation_is_enabled_but_missing_price() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .publish, regularPrice: nil)
        let model = EditableProductVariationModel(productVariation: variation)

        // Action
        let viewModel = ProductsTabProductViewModel(productVariationModel: model)

        // Assert
        XCTAssertTrue(viewModel.detailsAttributedString.string.contains(EditableProductVariationModel.DetailsLocalization.noPriceText))
    }

    func test_product_cell_view_model_shows_price_details_text_when_variation_is_enabled_and_has_price() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .publish, price: "6", regularPrice: "6")
        let model = EditableProductVariationModel(productVariation: variation)
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)

        // Action
        let viewModel = ProductsTabProductViewModel(productVariationModel: model, currencySettings: currencySettings)

        // Assert
        XCTAssertTrue(viewModel.detailsAttributedString.string.contains("$6.000"))
    }

    // MARK: Inventory details

    func test_product_cell_view_model_shows_stock_status_when_variation_is_not_in_stock() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(stockStatus: .outOfStock)
        let model = EditableProductVariationModel(productVariation: variation)

        // Action
        let viewModel = ProductsTabProductViewModel(productVariationModel: model)

        // Assert
        XCTAssertTrue(viewModel.detailsAttributedString.string.contains(ProductStockStatus.outOfStock.description))
    }

    func test_product_cell_view_model_shows_stock_status_when_variation_is_in_stock_without_stock_quantity() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(stockQuantity: nil, stockStatus: .inStock)
        let model = EditableProductVariationModel(productVariation: variation)

        // Action
        let viewModel = ProductsTabProductViewModel(productVariationModel: model)

        // Assert
        XCTAssertTrue(viewModel.detailsAttributedString.string.contains(ProductStockStatus.inStock.description))
    }

    func test_product_cell_view_model_shows_stock_status_with_quantity_when_variation_is_in_stock_with_stock_quantity() {
        // Arrange
        let stockQuantity: Int64 = 6
        let variation = MockProductVariation().productVariation().copy(stockQuantity: stockQuantity, stockStatus: .inStock)
        let model = EditableProductVariationModel(productVariation: variation)

        // Action
        let viewModel = ProductsTabProductViewModel(productVariationModel: model)

        // Assert
        let format = NSLocalizedString("%ld in stock", comment: "Label about product's inventory stock status shown on Products tab")
        let expectedStockDetails = String.localizedStringWithFormat(format, stockQuantity)
        XCTAssertTrue(viewModel.detailsAttributedString.string.contains(expectedStockDetails))
    }
}
