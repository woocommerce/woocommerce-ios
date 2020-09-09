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
    private var brokenOrderViewModel: OrderPaymentDetailsViewModel!
    private var anotherBrokenOrderViewModel: OrderPaymentDetailsViewModel!

    override func setUp() {
        super.setUp()
        order = MockOrders().sampleOrder()
        viewModel = OrderPaymentDetailsViewModel(order: order!)

        brokenOrder = MockOrders().brokenOrder()
        brokenOrderViewModel = OrderPaymentDetailsViewModel(order: brokenOrder)

        anotherBrokenOrder = MockOrders().unpaidOrder()
        anotherBrokenOrderViewModel = OrderPaymentDetailsViewModel(order: anotherBrokenOrder)
    }

    override func tearDown() {
        anotherBrokenOrderViewModel = nil
        anotherBrokenOrder = nil
        brokenOrderViewModel = nil
        brokenOrder = nil
        viewModel = nil
        order = nil
        super.tearDown()
    }

    func testSubtotalMatchesExpectation() {
        XCTAssertEqual(viewModel.subtotal, 0)
    }

    func testSubtotalValueMatchesExpectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(0, with: order.currency) ?? String()
        XCTAssertEqual(viewModel.subtotalValue, expectedValue)
    }

    func testDiscountTextMatchesExpectation() {
        XCTAssertNil(viewModel.discountText)
    }

    func testDiscountValueMatchesExpectation() {
        let expectedValue = "-" + CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.discountTotal, with: order.currency)!
        XCTAssertEqual(viewModel.discountValue, expectedValue)
    }

    func testShippingValueMatchesExpectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.shippingTotal, with: order.currency)
        XCTAssertEqual(viewModel.shippingValue, expectedValue)
    }

    func testTaxesValueMatchesExpectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.totalTax, with: order.currency)
        XCTAssertEqual(viewModel.taxesValue, expectedValue)
    }

    func testTotalValueMatchedExpectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.total,
                                                             with: order.currency)
        XCTAssertEqual(viewModel.totalValue, expectedValue)
    }

    func testPaymentTotalMatchedExpectation() {
        let expectedValue = CurrencyFormatter(currencySettings: CurrencySettings()).formatAmount(order.total,
                                                             with: order.currency)
        XCTAssertEqual(viewModel.totalValue, expectedValue)
    }

    /// Test the `paymentSummary` calculated property
    /// returns nil if the payment method title is an empty string
    ///
    func testOrderPaymentMethodTitleReturnsNilIfPaymentMethodTitleIsBlank() {
        let expected = ""
        XCTAssertEqual(brokenOrder.paymentMethodTitle, expected)
        XCTAssertNil(brokenOrderViewModel.paymentSummary)
    }

    /// The `paymentMethodTitle` is used in the `paymentSummary`.
    /// Test that the `paymentSummary` calculated property
    /// does not return nil as long as the `paymentMethodTitle` is present
    ///
    func testOrderPaymentMethodTitleDoesNotReturnNilWhenPresentAndNotBlank() {
        guard !order.paymentMethodTitle.isEmpty else {
            XCTFail("Expected a payment_method_title, not a blank or nil value")
            return
        }

        XCTAssertNotNil(viewModel.paymentSummary)
    }

    func testPaymentSummaryContainsAwaitingPaymentMessageWhenDatePaidIsNull() {
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

    func testCouponLinesMatchesExpectation() {
        XCTAssertEqual(viewModel.couponLines, order.coupons)
    }
}

/// Private Methods.
///
private extension OrderPaymentDetailsViewModelTests {

    /// Returns the OrderMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrder(from filename: String) throws -> Order {
        let response = Loader.contentsOf(filename)!
        return try OrderMapper(siteID: 545).map(response: response)
    }
}
