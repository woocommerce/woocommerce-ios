import XCTest
@testable import WooCommerce
@testable import Yosemite

final class SummaryTableViewCellTests: XCTestCase {
    private var cell: SummaryTableViewCell!

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("SummaryTableViewCell", owner: self, options: nil)
        cell = nib?.first as? SummaryTableViewCell
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testTitleLabelIsSetToTheBilledPersonName() throws {
        let mirror = try self.mirror(of: cell)
        let viewModel = SummaryTableViewCellViewModel(order: sampleOrder(), status: nil)

        cell.configure(viewModel)

        XCTAssertEqual(mirror.titleLabel.text, viewModel.billedPersonName)
    }

    func testCreatedLabelIsSetToTheCreationDateAndOrderNumber() throws {
        let mirror = try self.mirror(of: cell)
        let viewModel = SummaryTableViewCellViewModel(order: sampleOrder(), status: nil)

        cell.configure(viewModel)

        XCTAssertEqual(mirror.subtitleLabel.text, viewModel.subtitle)
    }

    func testDisplayStatusLabelIsSetToThePresentationStatusName() throws {
        // Given
        let mirror = try self.mirror(of: cell)

        let orderStatus = OrderStatus(name: "Automattic", siteID: 123, slug: "automattic", total: 0)
        let viewModel = SummaryTableViewCellViewModel(order: sampleOrder(), status: orderStatus)

        // When
        cell.configure(viewModel)

        // Then
        XCTAssertEqual(mirror.paymentStatusLabel.text, orderStatus.name)
    }

    func testTappingButtonExecutesCallback() throws {
        // Given
        let mirror = try self.mirror(of: cell)

        let expect = expectation(description: "The action assigned gets called")
        cell.onEditTouchUp = {
            expect.fulfill()
        }

        // When
        mirror.updateStatusButton.sendActions(for: .touchUpInside)

        // Then
        waitForExpectations(timeout: 1, handler: nil)
    }
}

private extension SummaryTableViewCellTests {
    func sampleOrder() -> Order {
        return Order(siteID: 123,
                     orderID: 963,
                     parentID: 2,
                     customerID: 11,
                     number: "963",
                     statusKey: "automattic",
                     currency: "USD",
                     customerNote: "",
                     dateCreated: Date(),
                     dateModified: Date(),
                     datePaid: Date(),
                     discountTotal: "30.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "31.20",
                     totalTax: "1.20",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: [],
                     billingAddress: nil,
                     shippingAddress: nil,
                     shippingLines: [],
                     coupons: [],
                     refunds: [])
    }
}

// MARK: - Mirror

private extension SummaryTableViewCellTests {
    /// Represents private properties of `SummaryTableViewCell`
    ///
    struct SummaryTableViewCellMirror {
        let titleLabel: UILabel
        let subtitleLabel: UILabel
        let paymentStatusLabel: PaddedLabel
        let updateStatusButton: UIButton
    }

    /// Create testable struct to test private properties of `SummaryTableViewCell`
    ///
    func mirror(of cell: SummaryTableViewCell) throws -> SummaryTableViewCellMirror {
        let mirror = Mirror(reflecting: cell)

        return SummaryTableViewCellMirror(
            titleLabel: try XCTUnwrap(mirror.descendant("titleLabel") as? UILabel),
            subtitleLabel: try XCTUnwrap(mirror.descendant("subtitleLabel") as? UILabel),
            paymentStatusLabel: try XCTUnwrap(mirror.descendant("paymentStatusLabel") as? PaddedLabel),
            updateStatusButton: try XCTUnwrap(mirror.descendant("updateStatusButton") as? UIButton)
        )
    }
}
