import XCTest
@testable import WooCommerce
@testable import Networking

final class PaymentTableViewCellTests: XCTestCase {
    private var cell: PaymentTableViewCell?
    private var viewModel: OrderPaymentDetailsViewModel?
    private var order: Order?

    override func setUp() {
        super.setUp()
        order = MockOrders().sampleOrder()
        viewModel = OrderPaymentDetailsViewModel(order: order!)

        let nib = Bundle.main.loadNibNamed("PaymentTableViewCell", owner: self, options: nil)
        cell = nib?.first as? PaymentTableViewCell

        cell?.configure(with: viewModel!)
    }

    override func tearDown() {
        cell = nil
        viewModel = nil
        order = nil
        super.tearDown()
    }

    func testSubtotalLabelContainsExpectedText() {
        let label = cell?.getSubtotalLabel()
        XCTAssertEqual(label?.text, Titles.subtotalLabel)
    }

    func testSubtotalValueContainsExpectedText() {
        let label = cell?.getSubtotalValue()
        XCTAssertEqual(label?.text, viewModel?.subtotalValue)
    }

    func testDiscountLabelContainsExpectedText() {
        let label = cell?.getDiscountLabel()
        XCTAssertEqual(label?.text, viewModel?.discountText)
    }

    func testDiscountValueContainsExpectedText() {
        let label = cell?.getDiscountValue()
        XCTAssertEqual(label?.text, viewModel?.discountValue)
    }

    func testShippingLabelContainsExpectedText() {
        let label = cell?.getShippingLabel()
        XCTAssertEqual(label?.text, Titles.shippingLabel)
    }

    func testShippingValueContainsExpectedText() {
        let label = cell?.getShippingValue()
        XCTAssertEqual(label?.text, viewModel?.shippingValue)
    }

    func testTaxesLabelContainsExpectedText() {
        let label = cell?.getTaxesLabel()
        XCTAssertEqual(label?.text, Titles.taxesLabel)
    }

    func testTaxesValueContainsExpectedText() {
        let label = cell?.getTaxesValue()
        XCTAssertEqual(label?.text, viewModel?.taxesValue)
    }

    func testTotalLabelContainsExpectedText() {
        let label = cell?.getTotalLabel()
        XCTAssertEqual(label?.text, Titles.totalLabel)
    }

    func testTotalValueContainsExpectedText() {
        let label = cell?.getTotalValue()
        XCTAssertEqual(label?.text, viewModel?.totalValue)
    }

    func testFooterTextContainsExpectedText() {
        XCTAssertEqual(cell?.getFooterText(), viewModel?.paymentSummary)
    }
}


private extension PaymentTableViewCellTests {
    enum Titles {
        static let subtotalLabel = NSLocalizedString("Subtotal",
                                                     comment: "Subtotal label for payment view")
        static let shippingLabel = NSLocalizedString("Shipping",
                                                     comment: "Shipping label for payment view")
        static let taxesLabel = NSLocalizedString("Taxes",
                                                  comment: "Taxes label for payment view")
        static let totalLabel = NSLocalizedString("Total",
                                                  comment: "Total label for payment view")
    }
}
