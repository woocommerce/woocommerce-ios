import XCTest
@testable import WooCommerce
@testable import Networking

final class OrderPaymentDetailsViewModelTests: XCTestCase {
    private var order: Order!
    private var viewModel: OrderPaymentDetailsViewModel!

    /// Broken Orders
    ///
    private var brokenOrder: Order!
    private var anotherBrokenOrder: Order!
    private var orderWithFees: Order!
    private var orderWithAPIRefunds: Order!
    private var orderWithTransientRefunds: Order!
    private var brokenOrderViewModel: OrderPaymentDetailsViewModel!
    private var anotherBrokenOrderViewModel: OrderPaymentDetailsViewModel!
    private var orderWithFeesViewModel: OrderPaymentDetailsViewModel!
    private var orderWithAPIRefundsViewModel: OrderPaymentDetailsViewModel!
    private var orderWithTransientRefundsViewModel: OrderPaymentDetailsViewModel!

    override func setUp() {
        super.setUp()
        order = MockOrders().sampleOrder()
        viewModel = OrderPaymentDetailsViewModel(order: order!, currencySettings: CurrencySettings())

        brokenOrder = MockOrders().brokenOrder()
        brokenOrderViewModel = OrderPaymentDetailsViewModel(order: brokenOrder)

        anotherBrokenOrder = MockOrders().unpaidOrder()
        anotherBrokenOrderViewModel = OrderPaymentDetailsViewModel(order: anotherBrokenOrder)

        orderWithFees = MockOrders().orderWithFees()
        orderWithFeesViewModel = OrderPaymentDetailsViewModel(order: orderWithFees, currencySettings: CurrencySettings())

        orderWithAPIRefunds = MockOrders().orderWithAPIRefunds()
        orderWithAPIRefundsViewModel = OrderPaymentDetailsViewModel(order: orderWithAPIRefunds, refund: MockRefunds.sampleRefund())

        orderWithTransientRefunds = MockOrders().orderWithTransientRefunds()
        orderWithTransientRefundsViewModel = OrderPaymentDetailsViewModel(order: orderWithTransientRefunds, refund: MockRefunds.sampleRefund())
    }

    override func tearDown() {
        orderWithAPIRefundsViewModel = nil
        orderWithAPIRefunds = nil
        orderWithTransientRefundsViewModel = nil
        orderWithTransientRefunds = nil
        orderWithFeesViewModel = nil
        orderWithFees = nil
        anotherBrokenOrderViewModel = nil
        anotherBrokenOrder = nil
        brokenOrderViewModel = nil
        brokenOrder = nil
        viewModel = nil
        order = nil
        super.tearDown()
    }

    func test_subtotal_matches_expectation() {
        XCTAssertEqual(viewModel.subtotal, 0)
    }

    func test_subtotal_value_matches_expectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(.zero, with: order.currency) ?? String()
        XCTAssertEqual(viewModel.subtotalValue, expectedValue)
    }

    func test_discount_text_matches_expectation() {
        XCTAssertNil(viewModel.discountText)
    }

    func test_discount_value_matches_expectation() {
        let expectedValue = "-" + CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.discountTotal, with: order.currency)!
        XCTAssertEqual(viewModel.discountValue, expectedValue)
    }

    func test_discount_is_visible_for_orders_with_discount() {
        XCTAssertFalse(viewModel.shouldHideDiscount)
    }

    func test_discount_is_hidden_for_orders_without_discount() {
        XCTAssertTrue(anotherBrokenOrderViewModel.shouldHideDiscount)
    }

    func test_fees_value_matches_expectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount("100.00", with: orderWithFees.currency)

        XCTAssertEqual(orderWithFeesViewModel.feesValue, expectedValue)
    }

    func test_fees_are_hidden_for_order_without_fees() {
        XCTAssertTrue(viewModel.shouldHideFees)
    }

    func test_fees_are_visible_for_order_with_fees() {
        XCTAssertFalse(orderWithFeesViewModel.shouldHideFees)
    }

    func test_shipping_value_matches_expectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.shippingTotal, with: order.currency)
        XCTAssertEqual(viewModel.shippingValue, expectedValue)
    }

    func test_taxes_value_matches_expectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.totalTax, with: order.currency)
        XCTAssertEqual(viewModel.taxesValue, expectedValue)
    }

    func test_total_value_matches_expectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.total,
                                                             with: order.currency)
        XCTAssertEqual(viewModel.totalValue, expectedValue)
    }

    func test_payment_total_matches_expectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.total,
                                                             with: order.currency)
        XCTAssertEqual(viewModel.totalValue, expectedValue)
    }

    /// Test the `paymentSummary` calculated property
    /// returns nil if the payment method title is an empty string
    ///
    func test_order_payment_method_title_returns_nil_if_payment_method_title_is_blank() {
        let expected = ""
        XCTAssertEqual(brokenOrder.paymentMethodTitle, expected)
        XCTAssertNil(brokenOrderViewModel.paymentSummary)
    }

    /// The `paymentMethodTitle` is used in the `paymentSummary`.
    /// Test that the `paymentSummary` calculated property
    /// does not return nil as long as the `paymentMethodTitle` is present
    ///
    func test_order_payment_method_title_does_not_return_nil_when_present_and_not_blank() {
        guard !order.paymentMethodTitle.isEmpty else {
            XCTFail("Expected a payment_method_title, not a blank or nil value")
            return
        }

        XCTAssertNotNil(viewModel.paymentSummary)
    }

    func test_payment_summary_contains_awaiting_payment_message_when_date_paid_is_null() {
        let awaitingPayment = String.localizedStringWithFormat(
            NSLocalizedString(
                "Awaiting payment via %@",
                comment: "A unit test string. It reads: " +
                "Awaiting payment via <payment method title>." +
                "A payment method example is: 'Credit Card (Stripe)'"
            ),
            anotherBrokenOrder.paymentMethodTitle
        )

        XCTAssertEqual(anotherBrokenOrder.paymentMethodTitle, "Cash on Delivery")
        XCTAssertNil(anotherBrokenOrder.datePaid)

        guard let paymentSummary = anotherBrokenOrderViewModel.paymentSummary else {
            XCTFail("The payment summary should not be nil or blank.")
            return
        }

        XCTAssertTrue(paymentSummary.contains(awaitingPayment))
    }

    func test_coupon_lines_matches_expectation() {
        XCTAssertEqual(viewModel.couponLines, order.coupons)
    }

    func test_order_with_API_refunds_presents_refunds_with_minus_sign() throws {
        let refundAmount = try XCTUnwrap(orderWithAPIRefundsViewModel.refundAmount)

        XCTAssertTrue(refundAmount.hasPrefix("-"))
    }

    func test_order_with_transient_refunds_presents_refunds_with_minus_sign() throws {
        let refundAmount = try XCTUnwrap(orderWithTransientRefundsViewModel.refundAmount)

        XCTAssertTrue(refundAmount.hasPrefix("-"))
    }
}
