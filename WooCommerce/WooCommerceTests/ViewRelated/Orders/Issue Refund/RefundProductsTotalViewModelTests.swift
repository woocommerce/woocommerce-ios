import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `RefundProductsTotalViewModel`
///
final class RefundProductsTotalViewModelTests: XCTestCase {
    func test_viewModel_is_created_with_correct_initial_values() {
        // Given
        let refundItems: [RefundableOrderItem] = [
            .init(item: MockOrderItem.sampleItem(quantity: 1, price: 10.50, totalTax: "1.20"), quantity: 1),
            .init(item: MockOrderItem.sampleItem(quantity: 2, price: 15.00, totalTax: "4.20"), quantity: 2),
            .init(item: MockOrderItem.sampleItem(quantity: 3, price: 7.99, totalTax: "3.30"), quantity: 2),
        ]

        // When
        let viewModel = RefundProductsTotalViewModel(refundItems: refundItems, currency: "USD", currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.productsSubtotal, "$56.48")
        XCTAssertEqual(viewModel.productsTax, "$7.60")
        XCTAssertEqual(viewModel.productsTotal, "$64.08")
    }
}
