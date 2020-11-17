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

        let details = RefundConfirmationViewModel.Details(order: order, amount: "0.0", refundsShipping: false, items: [], paymentGateway: nil)

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
        let details = RefundConfirmationViewModel.Details(order: order, amount: "130.3473", refundsShipping: false, items: [], paymentGateway: nil)

        // When
        let viewModel = RefundConfirmationViewModel(details: details, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.refundAmount, "$130.35")
    }

    func test_viewModel_has_automatic_refundVia_values_when_using_a_gateway_that_support_refunds() throws {
        // Given
        let order = MockOrders().empty().copy(paymentMethodID: "stipe", paymentMethodTitle: "Stripe")
        let gateway = PaymentGateway(siteID: 123, gatewayID: "stripe", title: "Stripe", description: "", enabled: true, features: [.refunds])
        let details = RefundConfirmationViewModel.Details(order: order, amount: "", refundsShipping: false, items: [], paymentGateway: gateway)

        // When
        let viewModel = RefundConfirmationViewModel(details: details)

        // We expect the Refund Via row to be the last item in the last row.
        let row = try XCTUnwrap(viewModel.sections.last?.rows.last as? RefundConfirmationViewModel.SimpleTextRow)

        // Then
        XCTAssertEqual(row.text, order.paymentMethodTitle)
    }

    func test_viewModel_has_manual_refundVia_values_when_using_a_gateway_that_does_not_support_refunds() throws {
        // Given
        let order = MockOrders().empty().copy(paymentMethodID: "stipe", paymentMethodTitle: "Stripe")
        let gateway = PaymentGateway(siteID: 123, gatewayID: "stripe", title: "Stripe", description: "", enabled: true, features: [])
        let details = RefundConfirmationViewModel.Details(order: order, amount: "", refundsShipping: false, items: [], paymentGateway: gateway)

        // When
        let viewModel = RefundConfirmationViewModel(details: details)

        // We expect the Refund Via row to be the last item in the last row.
        let row = try XCTUnwrap(viewModel.sections.last?.rows.last as? RefundConfirmationViewModel.TitleAndBodyRow)

        // Then
        let title = NSLocalizedString("Manual Refund via Stripe", comment: "")
        let body = NSLocalizedString("A refund will not be issued to the customer. You will need to manually issue the refund through Stripe.", comment: "")
        XCTAssertEqual(row.title, title)
        XCTAssertEqual(row.body, body)
    }
}
