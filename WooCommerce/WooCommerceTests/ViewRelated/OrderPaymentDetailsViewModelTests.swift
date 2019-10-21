import XCTest

@testable import Networking
@testable import WooCommerce

final class OrderPaymentDetailsViewModelTests: XCTestCase {
    private var order: Order!
    private var subject: OrderPaymentDetailsViewModel!

    override func setUp() {
        super.setUp()
        order = MockOrders().sampleOrder()
        subject = OrderPaymentDetailsViewModel(order: order!)
    }

    override func tearDown() {
        subject = nil
        order = nil
        super.tearDown()
    }

    func testSubtotalMatchesExpectation() {
        XCTAssertEqual(subject.subtotal, 0)
    }

    func testSubtotalValueMatchesExpectation() {
        let expectedValue = CurrencyFormatter().formatAmount(0, with: order.currency) ?? String()
        XCTAssertEqual(subject.subtotalValue, expectedValue)
    }

    func testDiscountTextMatchesExpectation() {
        XCTAssertNil(subject.discountText)
    }

    func testDiscountValueMatchesExpectation() {
        let expectedValue = "-" + CurrencyFormatter().formatAmount(order.discountTotal, with: order.currency)!
        XCTAssertEqual(subject.discountValue, expectedValue)
    }

    func testShippingValueMatchesExpectation() {
        let expectedValue = CurrencyFormatter().formatAmount(order.shippingTotal, with: order.currency)
        XCTAssertEqual(subject.shippingValue, expectedValue)
    }

    func testTaxesValueMatchesExpectation() {
        let expectedValue = CurrencyFormatter().formatAmount(order.totalTax, with: order.currency)
        XCTAssertEqual(subject.taxesValue, expectedValue)
    }

    func testTotalValueMatchedExpectation() {
        let expectedValue = CurrencyFormatter().formatAmount(
            order.total,
            with: order.currency)
        XCTAssertEqual(subject.totalValue, expectedValue)
    }

    func testPaymentTotalMatchedExpectation() {
        let expectedValue = CurrencyFormatter().formatAmount(
            order.total,
            with: order.currency)
        XCTAssertEqual(subject.totalValue, expectedValue)
    }

    func testPaymentSummaryMatchesExpectation() {
        let datePaid = order.datePaid!.toString(dateStyle: .medium, timeStyle: .none)
        let expectedValue = NSLocalizedString(
            "\(datePaid) via \(order.paymentMethodTitle)",
            comment: "Payment on <date> received via (payment method title)"
        )
        XCTAssertEqual(subject.paymentSummary, expectedValue)
    }

    func testCouponLinesMatchesExpectation() {
        XCTAssertEqual(subject.couponLines, order.coupons)
    }
}
