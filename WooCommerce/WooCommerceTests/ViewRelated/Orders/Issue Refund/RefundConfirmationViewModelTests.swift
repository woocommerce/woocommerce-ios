import XCTest

@testable import WooCommerce

import Yosemite

/// Tests for `RefundConfirmationViewModel`.
final class RefundConfirmationViewModelTests: XCTestCase {

    func test_sections_includes_a_previously_refunded_row() throws {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 4)

        let refundItems = [
            OrderRefundCondensed(refundID: 0, reason: nil, total: "-1.6719"),
            OrderRefundCondensed(refundID: 0, reason: nil, total: "-78.56"),
            OrderRefundCondensed(refundID: 0, reason: nil, total: "-67"),
        ]
        let order = MockOrders().empty().copy(refunds: refundItems)

        let details = RefundConfirmationViewModel.Details(order: order, amount: "0.0", refundsShipping: false, items: [])

        let viewModel = RefundConfirmationViewModel(details: details, currencySettings: currencySettings)

        // When
        // We expect the Previously Refunded row to be the first item.
        let previouslyRefundedRow = try XCTUnwrap(viewModel.sections.first?.rows.first as? RefundConfirmationViewModel.TwoColumnRow)

        // Then
        XCTAssertEqual(previouslyRefundedRow.value, "$147.2319")
    }

    func test_refund_amount_is_properly_formatted_with_currency() throws {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)

        let order = MockOrders().empty()
        let details = RefundConfirmationViewModel.Details(order: order, amount: "130.3473", refundsShipping: false, items: [])

        // When
        let viewModel = RefundConfirmationViewModel(details: details, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.refundAmount, "$130.35")
    }
}
