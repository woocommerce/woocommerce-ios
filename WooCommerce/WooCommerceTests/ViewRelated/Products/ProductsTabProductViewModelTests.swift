import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductsTabProductViewModelTests: XCTestCase {

    // MARK: Stock status

    func testDetailsForProductInStockWithoutQuantity() {
        let product = productMock(name: "Yay", stockQuantity: nil, stockStatus: .inStock)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let expectedStockDetail = NSLocalizedString("In stock", comment: "Label about product's inventory stock status shown on Products tab")
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func testDetailsForProductInStockWithQuantity() {
        let stockQuantity: Int64 = 6
        let product = productMock(name: "Yay", stockQuantity: stockQuantity, stockStatus: .inStock)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let format = NSLocalizedString("%ld in stock", comment: "Label about product's inventory stock status shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(format, stockQuantity)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func testDetailsForProductOutOfStock() {
        let product = productMock(name: "Yay", stockQuantity: 1099, stockStatus: .outOfStock)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let expectedStockDetail = NSLocalizedString("Out of stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    // MARK: Variations

    func testDetailsForProductWithOneVariation() {
        let variations: [Int64] = [134]
        let product = productMock(name: "Yay", variations: variations)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let singularFormat = NSLocalizedString("%ld variant", comment: "Label about one product variation shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(singularFormat, variations.count)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func testDetailsForProductWithMultipleVariations() {
        let variations: [Int64] = [201, 134]
        let product = productMock(name: "Yay", variations: variations)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let pluralFormat = NSLocalizedString("%ld variants", comment: "Label about number of variations shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(pluralFormat, variations.count)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

}

extension ProductsTabProductViewModelTests {
    func productMock(name: String = "Hogsmeade",
                     stockQuantity: Int64? = nil,
                     stockStatus: ProductStockStatus = .inStock,
                     variations: [Int64] = [],
                     images: [ProductImage] = []) -> Product {

        let mock = MockProduct()
        return mock.product(name: name, stockQuantity: stockQuantity, stockStatus: stockStatus, variations: variations, images: images)
    }
}
