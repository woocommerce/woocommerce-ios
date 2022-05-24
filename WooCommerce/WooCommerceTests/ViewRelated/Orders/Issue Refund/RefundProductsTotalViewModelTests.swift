import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `RefundProductsTotalViewModel`
///
final class RefundProductsTotalViewModelTests: XCTestCase {
    func test_viewModel_is_created_with_correct_initial_values() {
        // Given
        let item1Price: Decimal = 10.50
        let item1Quantity: Decimal  = 1

        let item2Price: Decimal = 15.00
        let item2Quantity: Decimal  = 2

        let item3Price: Decimal  = 7.99
        let item3Quantity: Decimal  = 3


        let currencySettings = CurrencySettings()
        let formatter = CurrencyFormatter(currencySettings: currencySettings)

        let refundItems: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(quantity: item1Quantity,
                                                 total: formatter.localize(item1Price * item1Quantity) ?? "0",
                                                 totalTax: "1.20"),
                  quantity: 1),
            .init(item: MockOrderItem.sampleItem(quantity: item2Quantity,
                                                 total: formatter.localize(item2Price * item2Quantity) ?? "0",
                                                 totalTax: "4.20"),
                  quantity: 2),
            .init(item: MockOrderItem.sampleItem(quantity: item3Quantity,
                                                 total: formatter.localize(item3Price * item3Quantity) ?? "0",
                                                 totalTax: "3.30"),
                  quantity: 2),
        ]


        // When
        let viewModel = RefundProductsTotalViewModel(refundItems: refundItems, currency: "USD", currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.productsSubtotal, "$56.48")
        XCTAssertEqual(viewModel.productsTax, "$7.60")
        XCTAssertEqual(viewModel.productsTotal, "$64.08")
    }
}
