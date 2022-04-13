import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductsTabProductViewModelTests: XCTestCase {

    // MARK: Stock status

    func test_details_contain_stock_status_without_quantity_when_quantity_is_nil_and_manage_stock_is_enabled() {
        // Arrange
        let product = productMock().copy(manageStock: true, stockQuantity: nil, stockStatusKey: ProductStockStatus.inStock.rawValue)

        // Action
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Assert
        let expectedStockDetail = NSLocalizedString("In stock", comment: "Label about product's inventory stock status shown on Products tab")
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func test_details_contain_stock_status_with_quantity_when_manage_stock_is_enabled() {
        // Arrange
        let stockQuantity: Decimal = 6
        let product = productMock().copy(manageStock: true, stockQuantity: stockQuantity, stockStatusKey: ProductStockStatus.inStock.rawValue)

        // Action
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Assert
        let localizedStockQuantity = NumberFormatter.localizedString(from: stockQuantity as NSNumber, number: .decimal)
        let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(format, localizedStockQuantity)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func test_details_contain_stock_status_without_quantity_when_manage_stock_is_disabled() {
        // Arrange
        let stockQuantity: Decimal = 6
        let product = productMock().copy(manageStock: false, stockQuantity: stockQuantity, stockStatusKey: ProductStockStatus.inStock.rawValue)

        // Action
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Assert
        XCTAssertTrue(detailsText.contains(ProductStockStatus.inStock.description))
    }

    func test_details_contain_stock_status_when_product_is_out_of_stock() {
        // Arrange
        let product = productMock(name: "Yay", stockQuantity: 1099, stockStatus: .outOfStock)

        // Action
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Assert
        let expectedStockDetail = NSLocalizedString("Out of stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    // MARK: Variations

    func test_details_contain_singular_variant_format_when_product_has_one_variation() {
        // Arrange
        let variations: [Int64] = [134]
        let product = productMock(name: "Yay", variations: variations)

        // Action
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Assert
        let singularFormat = NSLocalizedString("%ld variation", comment: "Label about one product variation shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(singularFormat, variations.count)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func test_details_contain_plural_variant_format_when_product_has_multiple_variations() {
        // Arrange
        let variations: [Int64] = [201, 134]
        let product = productMock(name: "Yay", variations: variations)

        // Action
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Assert
        let pluralFormat = NSLocalizedString("%ld variations", comment: "Label about number of variations shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(pluralFormat, variations.count)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func test_skuString_is_not_nil_when_product_has_sku() throws {
        // Given
        let product = productMock(sku: "1324")

        // When
        let viewModel = ProductsTabProductViewModel(product: product)

        // Then
        let expectedSKU = String.localizedStringWithFormat(NSLocalizedString("SKU: %1$@", comment: ""), try XCTUnwrap(product.sku))
        XCTAssertEqual(viewModel.skuString, expectedSKU)
    }

    func test_detailsString_contains_product_price_if_price_is_not_empty() {
        // Given
        let product = productMock(price: "10.00")

        // When
        let viewModel = ProductsTabProductViewModel(product: product)

        // Then
        XCTAssertTrue(viewModel.detailsString.contains(product.price))
    }
}

extension ProductsTabProductViewModelTests {
    func productMock(name: String = "Hogsmeade",
                     price: String = "",
                     stockQuantity: Decimal? = nil,
                     stockStatus: ProductStockStatus = .inStock,
                     variations: [Int64] = [],
                     images: [ProductImage] = [],
                     sku: String? = nil) -> Product {

        return Product.fake().copy(name: name,
                                   sku: sku,
                                   price: price,
                                   stockQuantity: stockQuantity,
                                   stockStatusKey: stockStatus.rawValue,
                                   images: images,
                                   variations: variations)
    }
}
