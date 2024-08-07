import XCTest
import struct Yosemite.Order
import class WooFoundation.CurrencyFormatter
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentSuccessMessageViewModelTests: XCTestCase {

    private var sut: PointOfSaleCardPresentPaymentSuccessMessageViewModel!

    override func setUp() {
        super.setUp()

        let formatAmount = { (amount: String, currency: String?, locale: Locale) in
            return "\(currency ?? "")\(amount)"
        }
        sut = PointOfSaleCardPresentPaymentSuccessMessageViewModel(formatAmount: formatAmount)
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func testMessage_order_has_total_and_currency() {
        let order = Order.fake().copy(currency: "$", total: "52.30")

        let viewModel = sut.withOrder(order)

        let expectedMessage = "A payment of $52.30 was successfully made"
        XCTAssertEqual(viewModel.message, expectedMessage)
    }

    func testMessage_no_order() {
        XCTAssertNil(sut.message)
    }
}
