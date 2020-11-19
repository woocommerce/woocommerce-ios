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

    func test_view_model_submits_refund_and_completes_successfully() throws {
        // Given
        let order = MockOrders().empty()
        let details = RefundConfirmationViewModel.Details(order: order, amount: "100.0", refundsShipping: false, items: [], paymentGateway: nil)
        let dispatcher = MockupStoresManager(sessionManager: .testingInstance)
        dispatcher.whenReceivingAction(ofType: RefundAction.self) { action in
            switch action {
            case let .createRefund(_, _, _, onCompletion):
                onCompletion(MockRefunds.sampleRefund(), nil)
            default:
                break
            }
        }

        // When
        let viewModel = RefundConfirmationViewModel(details: details, actionProcessor: dispatcher)
        let result = try waitFor { promise in
            viewModel.submit { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_view_model_submits_refund_with_automatic_refund_enabled() throws {
        // Given
        let order = MockOrders().empty().copy(paymentMethodID: "stipe", paymentMethodTitle: "Stripe")
        let gateway = PaymentGateway(siteID: 123, gatewayID: "stripe", title: "Stripe", description: "", enabled: true, features: [.refunds])
        let details = RefundConfirmationViewModel.Details(order: order, amount: "100.0", refundsShipping: true, items: [], paymentGateway: gateway)
        let dispatcher = MockupStoresManager(sessionManager: .testingInstance)

        // When
        let viewModel = RefundConfirmationViewModel(details: details, actionProcessor: dispatcher)
        let refund: Refund = try waitFor { promise in
            dispatcher.whenReceivingAction(ofType: RefundAction.self) { action in
                if case let .createRefund(_, _, refund, _) = action {
                    promise(refund)
                }
            }
            viewModel.submit(onCompletion: { _ in })
        }


        // Then
        let wasAutomated = try XCTUnwrap(refund.createAutomated)
        XCTAssertTrue(wasAutomated)
    }

    func test_view_model_submits_refund_with_automatic_refund_disabled() throws {
        // Given
        let order = MockOrders().empty().copy(paymentMethodID: "stipe", paymentMethodTitle: "Stripe")
        let gateway = PaymentGateway(siteID: 123, gatewayID: "stripe", title: "Stripe", description: "", enabled: true, features: [.products])
        let details = RefundConfirmationViewModel.Details(order: order, amount: "100.0", refundsShipping: true, items: [], paymentGateway: gateway)
        let dispatcher = MockupStoresManager(sessionManager: .testingInstance)

        // When
        let viewModel = RefundConfirmationViewModel(details: details, actionProcessor: dispatcher)
        let refund: Refund = try waitFor { promise in
            dispatcher.whenReceivingAction(ofType: RefundAction.self) { action in
                if case let .createRefund(_, _, refund, _) = action {
                    promise(refund)
                }
            }
            viewModel.submit(onCompletion: { _ in })
        }

        // Then
        let wasAutomated = try XCTUnwrap(refund.createAutomated)
        XCTAssertFalse(wasAutomated)
    }

    func test_view_model_submits_refund_and_relays_error() throws {
        // Given
        let order = MockOrders().empty()
        let details = RefundConfirmationViewModel.Details(order: order, amount: "100.0", refundsShipping: false, items: [], paymentGateway: nil)
        let expectedError = NSError(domain: "Refund Error", code: 0, userInfo: nil)
        let dispatcher = MockupStoresManager(sessionManager: .testingInstance)
        dispatcher.whenReceivingAction(ofType: RefundAction.self) { action in
            switch action {
            case let .createRefund(_, _, _, onCompletion):
                onCompletion(nil, expectedError)
            default:
                break
            }
        }

        // When
        let viewModel = RefundConfirmationViewModel(details: details, actionProcessor: dispatcher)
        let result = try waitFor { promise in
            viewModel.submit { result in
                promise(result)
            }
        }

        // Then
        let error = try XCTUnwrap(result.failure) as NSError
        XCTAssertEqual(error, expectedError)
    }
}
