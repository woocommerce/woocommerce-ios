import XCTest
import Yosemite
@testable import WooCommerce

class ProductRowViewModelTests: XCTestCase {

    func test_viewModel_is_created_with_correct_initial_values_from_product() {
        // Given
        let rowID = "0"
        let imageURLString = "https://woo.com/woo.jpg"
        let product = Product.fake().copy(productID: 12,
                                          name: "Test Product",
                                          images: [ProductImage.fake().copy(src: imageURLString)])

        // When
        let viewModel = ProductRowViewModel(id: rowID, product: product, canChangeQuantity: false)

        // Then
        XCTAssertEqual(viewModel.id, rowID)
        XCTAssertEqual(viewModel.productOrVariationID, product.productID)
        XCTAssertEqual(viewModel.name, product.name)
        XCTAssertEqual(viewModel.imageURL, URL(string: imageURLString))
        XCTAssertFalse(viewModel.canChangeQuantity)
        XCTAssertEqual(viewModel.quantity, 1)
        XCTAssertEqual(viewModel.numberOfVariations, 0)
    }

    func test_viewModel_is_created_with_correct_initial_values_from_variable_product() {
        // Given
        let product = Product.fake().copy(productTypeKey: "variable", variations: [0, 1, 2])

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        XCTAssertEqual(viewModel.numberOfVariations, 3)
    }

    func test_viewModel_is_created_with_correct_initial_values_from_product_variation() {
        // Given
        let rowID = "0"
        let imageURLString = "https://woo.com/woo.jpg"
        let name = "Blue - Any Size"
        let productVariation = ProductVariation.fake().copy(productVariationID: 12,
                                                            attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")],
                                                            image: ProductImage.fake().copy(src: imageURLString))

        // When
        let viewModel = ProductRowViewModel(id: rowID, productVariation: productVariation, name: name, canChangeQuantity: false)

        // Then
        XCTAssertEqual(viewModel.id, rowID)
        XCTAssertEqual(viewModel.productOrVariationID, productVariation.productVariationID)
        XCTAssertEqual(viewModel.name, name)
        XCTAssertEqual(viewModel.imageURL, URL(string: imageURLString))
        XCTAssertFalse(viewModel.canChangeQuantity)
        XCTAssertEqual(viewModel.quantity, 1)
    }

    func test_view_model_creates_expected_label_for_product_with_managed_stock() {
        // Given
        let stockQuantity: Decimal = 7
        let product = Product.fake().copy(manageStock: true, stockQuantity: stockQuantity, stockStatusKey: "instock")

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
        let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown during order creation")
        let expectedStockLabel = String.localizedStringWithFormat(format, localizedStockQuantity)
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_product_with_unmanaged_stock() {
        // Given
        let product = Product.fake().copy(stockStatusKey: "instock")

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let expectedStockLabel = NSLocalizedString("In stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_out_of_stock_product() {
        // Given
        let product = Product.fake().copy(stockStatusKey: "outofstock")

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let expectedStockLabel = NSLocalizedString("Out of stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_product_with_price() {
        // Given
        let price = "2.50"
        let product = Product.fake().copy(price: price)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false, currencyFormatter: currencyFormatter)

        // Then
        let expectedPriceLabel = "2.50"
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_label_for_product_with_no_price() {
        // Given
        let price = ""
        let product = Product.fake().copy(price: price)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false, currencyFormatter: currencyFormatter)

        // Then
        let expectedPriceLabel = "$0.00"
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_updates_price_label_when_quantity_changes() {
        // Given
        let product = Product.fake().copy(price: "2.50")
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Defaults to US currency & format

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false, currencyFormatter: currencyFormatter)
        viewModel.incrementQuantity()

        // Then
        let expectedPriceLabel = "$5.00"
        XCTAssertTrue(viewModel.productDetailsLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.productDetailsLabel)\"")
    }

    func test_view_model_creates_expected_product_details_label_for_variable_product() {
        // Given
        let product = Product.fake().copy(productTypeKey: "variable", stockStatusKey: "instock", variations: [0, 1])

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let expectedProductDetailsLabel = "In stock • 2 variations"
        XCTAssertEqual(viewModel.productDetailsLabel, expectedProductDetailsLabel)
    }

    func test_sku_label_is_formatted_correctly_for_product_with_sku() {
        // Given
        let sku = "123456"
        let product = Product.fake().copy(sku: sku)

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let format = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
        let expectedSKULabel = String.localizedStringWithFormat(format, sku)
        XCTAssertEqual(viewModel.skuLabel, expectedSKULabel)
    }

    func test_sku_label_is_empty_for_product_without_sku() {
        // Given
        let sku = ""
        let product = Product.fake().copy(sku: sku)

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let expectedSKULabel = ""
        XCTAssertEqual(viewModel.skuLabel, expectedSKULabel)
    }

    func test_increment_and_decrement_quantity_have_step_value_of_one() {
        // Given
        let product = Product.fake()
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: true)

        // When & Then
        viewModel.incrementQuantity()
        XCTAssertEqual(viewModel.quantity, 2)

        // When & Then
        viewModel.decrementQuantity()
        XCTAssertEqual(viewModel.quantity, 1)
    }

    func test_quantity_has_minimum_value_of_one() {
        // Given
        let product = Product.fake()
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: true)

        // Then
        XCTAssertEqual(viewModel.quantity, 1)
        XCTAssertTrue(viewModel.shouldDisableQuantityDecrementer, "Quantity decrementer is not disabled at minimum value")

        // When
        viewModel.decrementQuantity()

        // Then
        XCTAssertEqual(viewModel.quantity, 1)
    }
}
