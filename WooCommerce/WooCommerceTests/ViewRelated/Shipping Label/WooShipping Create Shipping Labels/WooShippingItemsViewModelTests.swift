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

    func test_inits_with_expected_values_from_order_items() throws {
        // Given
        let orderItems = [OrderItem.fake().copy(name: "Shirt",
                                                quantity: 1,
                                                price: 10,
                                                attributes: [OrderItemAttribute.fake().copy(value: "Red")]),
                          OrderItem.fake().copy(quantity: 1, price: 2.5)]
        let dataSource = MockDataSource(orderItems: orderItems)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        // Section header labels have expected values
        assertEqual("2 items", viewModel.itemsCountLabel)
        assertEqual("0 oz • $12.50", viewModel.itemsDetailLabel)

        // Section rows have expected values
        assertEqual(2, viewModel.itemRows.count)
        let firstItem = try XCTUnwrap(viewModel.itemRows.first)
        assertEqual("Shirt", firstItem.name)
        assertEqual("1", firstItem.quantityLabel)
        assertEqual("$10.00", firstItem.priceLabel)
        assertEqual("Red", firstItem.detailsLabel)
    }

    func test_populates_item_data_from_products_and_variations() {
        // Given
        let dimensions = ProductDimensions(length: "20", width: "35", height: "5")
        let product = Product.fake().copy(productID: 1, weight: "5", dimensions: dimensions)
        let variation = ProductVariation.fake().copy(productID: 2, productVariationID: 12, weight: "3", dimensions: dimensions)
        let orderItems = [OrderItem.fake().copy(productID: product.productID, quantity: 2),
                          OrderItem.fake().copy(productID: variation.productID,
                                                variationID: variation.productVariationID,
                                                quantity: 1,
                                                attributes: [OrderItemAttribute.fake().copy(value: "Red")])]
        let dataSource = MockDataSource(orderItems: orderItems, products: [product], productVariations: [variation])

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("23 oz • $0.00", viewModel.itemsDetailLabel)

        let productRow = viewModel.itemRows[0]
        let variationRow = viewModel.itemRows[1]
        assertEqual("10 oz", productRow.weightLabel)
        assertEqual("20 x 35 x 5 in", productRow.detailsLabel)
        assertEqual("3 oz", variationRow.weightLabel)
        assertEqual("20 x 35 x 5 in • Red", variationRow.detailsLabel)
    }

    func test_total_items_count_handles_items_with_quantity_greater_than_one() {
        // Given
        let orderItems = [OrderItem.fake().copy(quantity: 2), OrderItem.fake().copy(quantity: 1)]
        let dataSource = MockDataSource(orderItems: orderItems)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource, currencySettings: currencySettings)

        // Then
        assertEqual("3 items", viewModel.itemsCountLabel)
    }

    func test_total_items_details_handles_total_price_for_items_with_quantity_greater_than_one() {
        // Given
        let orderItems = [OrderItem.fake().copy(quantity: 2, price: 10), OrderItem.fake().copy(quantity: 1, price: 2.5)]
        let dataSource = MockDataSource(orderItems: orderItems)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("0 oz • $22.50", viewModel.itemsDetailLabel)
    }

    func test_item_row_details_label_handles_items_with_multiple_attributes() throws {
        // Given
        let orderItems = [OrderItem.fake().copy(attributes: [OrderItemAttribute.fake().copy(value: "Red"),
                                                             OrderItemAttribute.fake().copy(value: "Small")])]
        let dataSource = MockDataSource(orderItems: orderItems)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource, currencySettings: currencySettings)

        // Then
        let firstItem = try XCTUnwrap(viewModel.itemRows.first)
        assertEqual("Red, Small", firstItem.detailsLabel)
    }

}

private final class MockDataSource: WooShippingItemsDataSource {
    var orderItems: [OrderItem]

    var products: [Product]

    var productVariations: [ProductVariation]

    init(orderItems: [OrderItem] = [],
         products: [Product] = [],
         productVariations: [ProductVariation] = []) {
        self.orderItems = orderItems
        self.products = products
        self.productVariations = productVariations
    }
}
