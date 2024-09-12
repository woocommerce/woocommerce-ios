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
        let order = Order.fake().copy(total: "22.5", items: [OrderItem.fake().copy(name: "Shirt", quantity: 2, total: "20"), OrderItem.fake().copy(quantity: 1)])

        // When
        let viewModel = WooShippingItemsViewModel(order: order, currencySettings: currencySettings)

        // Then
        assertEqual("3 items", viewModel.itemsCountLabel)
        assertEqual("1 kg • $22.50", viewModel.itemsDetailLabel)
        assertEqual(2, viewModel.itemRows.count)

        let firstItem = try XCTUnwrap(viewModel.itemRows.first)
        assertEqual("Shirt", firstItem.name)
        assertEqual("2", firstItem.quantityLabel)
        assertEqual("$20.00", firstItem.priceLabel)
    }

}
