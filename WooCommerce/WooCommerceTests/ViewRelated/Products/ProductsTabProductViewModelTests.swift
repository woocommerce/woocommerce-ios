import XCTest
import WooFoundation
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

    func test_details_when_sku_is_hidden_then_omits_sku_line() {
        // Given
        let sku = "pear"
        let product = productWith(price: "6", sku: sku)

        // When
        let viewModel = ProductsTabProductViewModel(product: product,
                                                    isSKUShown: false,
                                                    isPriceShown: true,
                                                    currencySettings: usdCurrencySettings)

        // Then
        XCTAssertEqual(viewModel.detailsAttributedString.string, "\(Localization.inStock) • $6.00")
    }

    func test_details_when_price_and_sku_are_shown_then_formats_complete_layout() {
        // Given
        let sku = "pear"
        let product = productWith(price: "6", sku: sku)

        // When
        let viewModel = ProductsTabProductViewModel(product: product,
                                                    isSKUShown: true,
                                                    isPriceShown: true,
                                                    currencySettings: usdCurrencySettings)

        // Then
        let expectedSKU = String.localizedStringWithFormat(Localization.skuFormat, sku)
        XCTAssertEqual(viewModel.detailsAttributedString.string, "\(Localization.inStock) • $6.00\n\(expectedSKU)")
    }

    func test_details_when_price_is_hidden_then_omits_price() {
        // Given
        let product = productWith(price: "6")

        // When
        let viewModel = ProductsTabProductViewModel(product: product,
                                                    isPriceShown: false,
                                                    currencySettings: usdCurrencySettings)

        // Then
        XCTAssertEqual(viewModel.detailsAttributedString.string, Localization.inStock)
    }

    func test_details_when_price_is_empty_then_omits_price_and_separator() {
        // Given
        let product = productWith(price: "")

        // When
        let viewModel = ProductsTabProductViewModel(product: product,
                                                    isPriceShown: true,
                                                    currencySettings: usdCurrencySettings)

        // Then
        XCTAssertEqual(viewModel.detailsAttributedString.string, Localization.inStock)
    }

    func test_details_when_sku_is_empty_then_omits_sku_line() {
        // Given
        let product = productWith(price: "6", sku: "")

        // When
        let viewModel = ProductsTabProductViewModel(product: product,
                                                    isSKUShown: true,
                                                    isPriceShown: true,
                                                    currencySettings: usdCurrencySettings)

        // Then
        XCTAssertEqual(viewModel.detailsAttributedString.string, "\(Localization.inStock) • $6.00")
    }

    func test_details_for_product_bundle_contain_bundle_stock_status_when_bundle_not_in_stock() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle",
                                          manageStock: false,
                                          stockQuantity: 5,
                                          stockStatusKey: "instock",
                                          bundleStockStatus: .insufficientStock,
                                          bundleStockQuantity: 0).toListItem()

        // When
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Then
        let expectedStockText = ProductStockStatus.insufficientStock.description
        XCTAssertTrue(detailsText.contains(expectedStockText),
                      "Expected details text to include \(expectedStockText) but it was \(detailsText) instead")
    }

    func test_details_for_product_bundle_contain_product_stock_status_when_product_is_backordered() {
        // Given
        let product = Product.fake().copy(productTypeKey: "bundle",
                                          manageStock: false,
                                          stockQuantity: 5,
                                          stockStatusKey: "onbackorder",
                                          bundleStockStatus: .inStock,
                                          bundleStockQuantity: 0).toListItem()

        // When
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Then
        let expectedStockText = ProductStockStatus.onBackOrder.description
        XCTAssertTrue(detailsText.contains(expectedStockText),
                      "Expected details text to include \(expectedStockText) but it was \(detailsText) instead")
    }

    func test_details_for_product_bundle_contain_stock_status_with_bundle_stock_quantity_when_quantity_is_set() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: "bundle",
                                          manageStock: false,
                                          stockQuantity: 5,
                                          stockStatusKey: "instock",
                                          bundleStockStatus: .inStock,
                                          bundleStockQuantity: 1).toListItem()

        // Action
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Assert
        let localizedStockQuantity = NumberFormatter.localizedString(from: 1 as NSNumber, number: .decimal)
        let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(format, localizedStockQuantity)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func test_details_for_product_bundle_contain_stock_status_with_bundle_stock_quantity_when_manageStock_enabled() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: "bundle",
                                          manageStock: true,
                                          stockQuantity: 5,
                                          stockStatusKey: "instock",
                                          bundleStockStatus: .inStock,
                                          bundleStockQuantity: 1).toListItem()

        // Action
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string

        // Assert
        let localizedStockQuantity = NumberFormatter.localizedString(from: 1 as NSNumber, number: .decimal)
        let format = NSLocalizedString("%1$@ in stock", comment: "Label about product's inventory stock status shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(format, localizedStockQuantity)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }
}

extension ProductsTabProductViewModelTests {
    func productMock(name: String = "Hogsmeade",
                     stockQuantity: Decimal? = nil,
                     stockStatus: ProductStockStatus = .inStock,
                     variations: [Int64] = [],
                     images: [ProductImage] = []) -> ProductListItem {

        return Product.fake().copy(name: name,
                                   stockQuantity: stockQuantity,
                                   stockStatusKey: stockStatus.rawValue,
                                   images: images,
                                   variations: variations).toListItem()
    }
}

private extension ProductsTabProductViewModelTests {
    var usdCurrencySettings: CurrencySettings {
        CurrencySettings(currencyCode: .USD,
                         currencyPosition: .left,
                         thousandSeparator: "",
                         decimalSeparator: ".",
                         numberOfDecimals: 2)
    }

    func productWith(price: String, sku: String = "") -> ProductListItem {
        Product.fake().copy(productTypeKey: ProductType.simple.rawValue,
                            statusKey: ProductStatus.published.rawValue,
                            sku: sku,
                            price: price,
                            manageStock: false,
                            stockStatusKey: ProductStockStatus.inStock.rawValue,
                            variations: []).toListItem()
    }

    enum Localization {
        static let inStock = NSLocalizedString(
            "string.createStockText.inStock",
            value: "In stock",
            comment: "Label about product's inventory stock status shown on Products tab"
        )
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "Label about the SKU of a product in the product list. Reads, `SKU: productSku`")
    }
}
