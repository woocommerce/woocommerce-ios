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
        let singularFormat = NSLocalizedString("%ld variant", comment: "Label about one product variation shown on Products tab")
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
        let pluralFormat = NSLocalizedString("%ld variants", comment: "Label about number of variations shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(pluralFormat, variations.count)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

}

extension ProductsTabProductViewModelTests {
    func productMock(name: String = "Hogsmeade",
                     stockQuantity: Decimal? = nil,
                     stockStatus: ProductStockStatus = .inStock,
                     variations: [Int64] = [],
                     images: [ProductImage] = []) -> Product {

        let mock = MockProduct()
        return mock.product(name: name, stockQuantity: stockQuantity, stockStatus: stockStatus, variations: variations, images: images)
    }
}
