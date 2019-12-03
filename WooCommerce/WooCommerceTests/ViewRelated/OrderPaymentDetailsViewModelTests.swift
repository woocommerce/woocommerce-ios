import XCTest
@testable import WooCommerce
@testable import Networking

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
        let expectedValue = CurrencyFormatter().formatAmount(order.total,
                                                             with: order.currency)
        XCTAssertEqual(subject.totalValue, expectedValue)
    }

    func testPaymentTotalMatchedExpectation() {
        let expectedValue = CurrencyFormatter().formatAmount(order.total,
                                                             with: order.currency)
        XCTAssertEqual(subject.totalValue, expectedValue)
    }

    // FIXME: - This unit test.
    /// Test the payment summary format and ensure it's localizing properly.
    ///
    func testPaymentSummaryMatchesExpectation() {
        // There isn't a good way to test the composite sentence and
        // ensure the that the translated, formatted sentence is correct.

        // You can get the paymentSummary from the order,
        // BUT you can't create a static expected result string that matches every translated language,
        // WITHOUT using the exact same localization and string manipulation method
        // OR translating a literal string in every language first.
        // I even tried to get the current existing translated strings from the Bundle by trying to  `Localizable.strings` files. No luck. - tc
    }

    func testCouponLinesMatchesExpectation() {
        XCTAssertEqual(subject.couponLines, order.coupons)
    }
}
