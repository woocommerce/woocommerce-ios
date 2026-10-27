import XCTest
@testable import WooCommerce
@testable import Networking

@MainActor
final class LedgerTableViewCellTests: XCTestCase {
    func test_subtotal_label_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getSubtotalLabel()
        XCTAssertEqual(label.text, Titles.subtotalLabel)
    }

    func test_subtotal_value_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getSubtotalValue()
        XCTAssertEqual(label.text, fixture.viewModel.subtotalValue)
    }

    func test_discount_label_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getDiscountLabel()
        XCTAssertEqual(label.text, fixture.viewModel.discountText)
    }

    func test_discount_value_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getDiscountValue()
        XCTAssertEqual(label.text, fixture.viewModel.discountValue)
    }

    func test_fees_label_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getFeesLabel()
        XCTAssertEqual(label.text, Titles.customAmountsLabel)
    }

    func test_shipping_label_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getShippingLabel()
        XCTAssertEqual(label.text, Titles.shippingLabel)
    }

    func test_shipping_value_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getShippingValue()
        XCTAssertEqual(label.text, fixture.viewModel.shippingValue)
    }

    func test_taxes_label_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getTaxesLabel()
        XCTAssertEqual(label.text, Titles.taxesLabel)
    }

    func test_taxes_value_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getTaxesValue()
        XCTAssertEqual(label.text, fixture.viewModel.taxesValue)
    }

    func test_total_label_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getTotalLabel()
        XCTAssertEqual(label.text, Titles.totalLabel)
    }

    func test_total_value_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getTotalValue()
        XCTAssertEqual(label.text, fixture.viewModel.totalValue)
    }

    func test_giftCards_label_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getGiftCardsLabel()
        XCTAssertEqual(label.text, fixture.viewModel.giftCardsText)
    }

    func test_giftCards_value_contains_expected_text() throws {
        let fixture = try makeFixture()

        let label = fixture.cell.getGiftCardsValue()
        XCTAssertEqual(label.text, fixture.viewModel.giftCardsValue)
    }

    private func makeFixture() throws -> (cell: LedgerTableViewCell, viewModel: OrderPaymentDetailsViewModel) {
        let order = MockOrders().orderWithFeesAndGiftCards()
        let viewModel = OrderPaymentDetailsViewModel(order: order)
        let nib = try XCTUnwrap(Bundle.main.loadNibNamed("LedgerTableViewCell", owner: nil, options: nil))
        let cell = try XCTUnwrap(nib.first as? LedgerTableViewCell)
        cell.configure(with: viewModel)
        return (cell, viewModel)
    }
}


private extension LedgerTableViewCellTests {
    enum Titles {
        static let subtotalLabel = NSLocalizedString("Products",
                                                     comment: "Product Total label for payment view")
        static let customAmountsLabel = NSLocalizedString("Custom Amounts",
                                                     comment: "Custom amounts label for payment view")
        static let shippingLabel = NSLocalizedString("Shipping",
                                                     comment: "Shipping label for payment view")
        static let taxesLabel = NSLocalizedString("Taxes",
                                                  comment: "Taxes label for payment view")
        static let totalLabel = NSLocalizedString("Order Total",
                                                  comment: "Order Total label for payment view")
    }
}
