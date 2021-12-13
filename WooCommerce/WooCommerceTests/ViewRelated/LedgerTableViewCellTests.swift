import XCTest
@testable import WooCommerce
@testable import Networking

final class LedgerTableViewCellTests: XCTestCase {
    private var cell: LedgerTableViewCell!
    private var viewModel: OrderPaymentDetailsViewModel!
    private var order: Order!

    override func setUp() {
        super.setUp()
        order = MockOrders().orderWithFees()
        viewModel = OrderPaymentDetailsViewModel(order: order)

        let nib = Bundle.main.loadNibNamed("LedgerTableViewCell", owner: self, options: nil)
        cell = nib?.first as? LedgerTableViewCell

        cell?.configure(with: viewModel!)
    }

    override func tearDown() {
        cell = nil
        viewModel = nil
        order = nil
        super.tearDown()
    }

    func test_subtotal_label_contains_expected_text() {
        let label = cell.getSubtotalLabel()
        XCTAssertEqual(label.text, Titles.subtotalLabel)
    }

    func test_subtotal_value_contains_expected_text() {
        let label = cell.getSubtotalValue()
        XCTAssertEqual(label.text, viewModel.subtotalValue)
    }

    func test_discount_label_contains_expected_text() {
        let label = cell.getDiscountLabel()
        XCTAssertEqual(label.text, viewModel.discountText)
    }

    func test_discount_value_contains_expected_text() {
        let label = cell.getDiscountValue()
        XCTAssertEqual(label.text, viewModel.discountValue)
    }

    func test_fees_label_contains_expected_text() {
        let label = cell.getFeesLabel()
        XCTAssertEqual(label.text, Titles.feesLabel)
    }

    func test_shipping_label_contains_expected_text() {
        let label = cell.getShippingLabel()
        XCTAssertEqual(label.text, Titles.shippingLabel)
    }

    func test_shipping_value_contains_expected_text() {
        let label = cell.getShippingValue()
        XCTAssertEqual(label.text, viewModel.shippingValue)
    }

    func test_taxes_label_contains_expected_text() {
        let label = cell.getTaxesLabel()
        XCTAssertEqual(label.text, Titles.taxesLabel)
    }

    func test_taxes_value_contains_expected_text() {
        let label = cell.getTaxesValue()
        XCTAssertEqual(label.text, viewModel.taxesValue)
    }

    func test_total_label_contains_expected_text() {
        let label = cell.getTotalLabel()
        XCTAssertEqual(label.text, Titles.totalLabel)
    }

    func test_total_value_contains_expected_text() {
        let label = cell.getTotalValue()
        XCTAssertEqual(label.text, viewModel.totalValue)
    }
}


private extension LedgerTableViewCellTests {
    enum Titles {
        static let subtotalLabel = NSLocalizedString("Product Total",
                                                     comment: "Product Total label for payment view")
        static let feesLabel = NSLocalizedString("Fees",
                                                     comment: "Fees label for payment view")
        static let shippingLabel = NSLocalizedString("Shipping",
                                                     comment: "Shipping label for payment view")
        static let taxesLabel = NSLocalizedString("Taxes",
                                                  comment: "Taxes label for payment view")
        static let totalLabel = NSLocalizedString("Order Total",
                                                  comment: "Order Total label for payment view")
    }
}
