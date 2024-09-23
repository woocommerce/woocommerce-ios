import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite

final class WooShippingItemsViewModelTests: XCTestCase {

    private var currencySettings: CurrencySettings!
    private var shippingSettingsService: MockShippingSettingsService!

    override func setUp() {
        currencySettings = CurrencySettings()
        shippingSettingsService = MockShippingSettingsService()
    }

    func test_inits_with_expected_values() throws {
        // Given
        let product = Product.fake().copy(productID: 1, weight: "4")
        let productVariation = ProductVariation.fake().copy(productVariationID: 2, weight: "3")
        let orderItems = [OrderItem.fake().copy(productID: product.productID, quantity: 1, price: 10),
                          OrderItem.fake().copy(variationID: productVariation.productVariationID, quantity: 1, price: 2.5)]
        let dataSource = MockDataSource(orderItems: orderItems, products: [product], productVariations: [productVariation])

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("2 items", viewModel.itemsCountLabel)
        assertEqual("7 oz • $12.50", viewModel.itemsDetailLabel)
        assertEqual(2, viewModel.itemRows.count)
    }

    func test_total_items_count_handles_items_with_quantity_greater_than_one() {
        // Given
        let products = [Product.fake().copy(productID: 1), Product.fake().copy(productID: 2)]
        let orderItems = [OrderItem.fake().copy(productID: 1, quantity: 2), OrderItem.fake().copy(productID: 2, quantity: 1)]
        let dataSource = MockDataSource(orderItems: orderItems, products: products)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource, currencySettings: currencySettings)

        // Then
        assertEqual("3 items", viewModel.itemsCountLabel)
    }

    func test_total_items_details_handles_items_with_quantity_greater_than_one() {
        // Given
        let dimensions = ProductDimensions(length: "20", width: "35", height: "5")
        let product = Product.fake().copy(productID: 1, weight: "5", dimensions: dimensions)
        let variation = ProductVariation.fake().copy(productID: 2, productVariationID: 12, weight: "3", dimensions: dimensions)
        let orderItems = [OrderItem.fake().copy(productID: product.productID, quantity: 2, price: 10),
                          OrderItem.fake().copy(productID: variation.productID, variationID: variation.productVariationID, quantity: 1, price: 2.5)]
        let dataSource = MockDataSource(orderItems: orderItems, products: [product], productVariations: [variation])

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("13 oz • $22.50", viewModel.itemsDetailLabel)
    }

}

private final class MockDataSource: WooShippingItemsDataSource {
    var items: [ShippingLabelPackageItem]

    var orderItems: [OrderItem]

    var products: [Product]

    var productVariations: [ProductVariation]

    init(orderItems: [OrderItem] = [],
         products: [Product] = [],
         productVariations: [ProductVariation] = []) {
        self.orderItems = orderItems
        self.products = products
        self.productVariations = productVariations
        self.items = orderItems.compactMap { ShippingLabelPackageItem(orderItem: $0, products: products, productVariations: productVariations)}
    }
}
