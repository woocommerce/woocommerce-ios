import XCTest
import Yosemite
@testable import WooCommerce

class ProductRowViewModelTests: XCTestCase {

    func test_viewModel_is_created_with_correct_initial_values() {
        // Given
        let product = Product.fake().copy(productID: 12, name: "Test Product")

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        XCTAssertEqual(viewModel.id, product.productID)
        XCTAssertEqual(viewModel.name, product.name)
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
        XCTAssertTrue(viewModel.stockAndPriceLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.stockAndPriceLabel)\"")
    }

    func test_view_model_creates_expected_label_for_product_with_unmanaged_stock() {
        // Given
        let product = Product.fake().copy(stockStatusKey: "instock")

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let expectedStockLabel = NSLocalizedString("In stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(viewModel.stockAndPriceLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.stockAndPriceLabel)\"")
    }

    func test_view_model_creates_expected_label_for_out_of_stock_product() {
        // Given
        let product = Product.fake().copy(stockStatusKey: "outofstock")

        // When
        let viewModel = ProductRowViewModel(product: product, canChangeQuantity: false)

        // Then
        let expectedStockLabel = NSLocalizedString("Out of stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(viewModel.stockAndPriceLabel.contains(expectedStockLabel),
                      "Expected label to contain \"\(expectedStockLabel)\" but actual label was \"\(viewModel.stockAndPriceLabel)\"")
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
        XCTAssertTrue(viewModel.stockAndPriceLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.stockAndPriceLabel)\"")
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
        XCTAssertTrue(viewModel.stockAndPriceLabel.contains(expectedPriceLabel),
                      "Expected label to contain \"\(expectedPriceLabel)\" but actual label was \"\(viewModel.stockAndPriceLabel)\"")
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
