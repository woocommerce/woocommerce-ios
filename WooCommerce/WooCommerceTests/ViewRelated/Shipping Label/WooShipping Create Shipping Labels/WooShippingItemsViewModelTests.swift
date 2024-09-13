import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite

final class WooShippingItemsViewModelTests: XCTestCase {

    private var currencySettings: CurrencySettings!

    override func setUp() {
        currencySettings = CurrencySettings()
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
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource, currencySettings: currencySettings)

        // Then
        // Section header labels have expected values
        assertEqual("2 items", viewModel.itemsCountLabel)
        assertEqual("1 kg • $12.50", viewModel.itemsDetailLabel)

        // Section rows have expected values
        assertEqual(2, viewModel.itemRows.count)
        let firstItem = try XCTUnwrap(viewModel.itemRows.first)
        assertEqual("Shirt", firstItem.name)
        assertEqual("1", firstItem.quantityLabel)
        assertEqual("$10.00", firstItem.priceLabel)
        assertEqual("Red", firstItem.detailsLabel)
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
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource, currencySettings: currencySettings)

        // Then
        assertEqual("1 kg • $22.50", viewModel.itemsDetailLabel)
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
