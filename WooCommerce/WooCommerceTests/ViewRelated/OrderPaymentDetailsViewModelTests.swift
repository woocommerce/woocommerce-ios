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

    func testPaymentSummaryMatchesExpectation() {
        guard let paymentSummary = subject.paymentSummary else {
            XCTFail()
            return
        }

        // Let's use a language from a region that is NOT the US,
        // to test the localization for this sentence is correct.
        let actualResult = String.getTranslationString(forKey: paymentSummary, languageCode: "zh")
        let expectedResult = "已在 2018年4月3日 收到 Credit Card (Stripe) 付款"

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testCouponLinesMatchesExpectation() {
        XCTAssertEqual(subject.couponLines, order.coupons)
    }
}
