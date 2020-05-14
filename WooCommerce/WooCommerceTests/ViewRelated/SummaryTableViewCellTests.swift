import XCTest
@testable import WooCommerce
@testable import Yosemite

final class SummaryTableViewCellTests: XCTestCase {
    private var cell: SummaryTableViewCell!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let nib = Bundle.main.loadNibNamed("SummaryTableViewCell", owner: self, options: nil)
        cell = try XCTUnwrap(nib?.first as? SummaryTableViewCell)
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

        XCTAssertEqual(mirror.createdLabel.text, viewModel.dateCreatedAndOrderNumber)
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

    func testTitleLabelIsAppliedHeadStyle() {
        let mockLabel = UILabel()
        mockLabel.applyHeadlineStyle()

        let cellTitleLabel = cell.getTitle()

        XCTAssertEqual(cellTitleLabel.font, mockLabel.font)
        XCTAssertEqual(cellTitleLabel.textColor, mockLabel.textColor)
    }

    func testCreatedLabelIsAppliedHeadStyle() {
        let mockLabel = UILabel()
        mockLabel.applyFootnoteStyle()

        let cellCreatedLabel = cell.getCreatedLabel()

        XCTAssertEqual(cellCreatedLabel.font, mockLabel.font)
        XCTAssertEqual(cellCreatedLabel.textColor, mockLabel.textColor)
    }

    func testStatusLabelIsAppliedPaddedLabelStyle() {
        let mockLabel = UILabel()
        mockLabel.applyPaddedLabelDefaultStyles()

        let cellStatusLabel = cell.getStatusLabel()

        XCTAssertEqual(cellStatusLabel.font, mockLabel.font)
        XCTAssertEqual(cellStatusLabel.layer.borderWidth, mockLabel.layer.borderWidth)
        XCTAssertEqual(cellStatusLabel.layer.cornerRadius, mockLabel.layer.cornerRadius)
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
                     dateCreated: date(with: "2018-04-03T23:05:12"),
                     dateModified: date(with: "2018-04-03T23:05:14"),
                     datePaid: date(with: "2018-04-03T23:05:14"),
                     discountTotal: "30.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "31.20",
                     totalTax: "1.20",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: sampleItems(),
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress(),
                     shippingLines: sampleShippingLines(),
                     coupons: sampleCoupons(),
                     refunds: [])
    }

    func sampleAddress() -> Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: "",
                       address1: "234 70th Street",
                       address2: "",
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "scrambled@scrambled.com")
    }

    func sampleShippingLines() -> [ShippingLine] {
        return [ShippingLine(shippingID: 123,
        methodTitle: "International Priority Mail Express Flat Rate",
        methodID: "usps",
        total: "133.00",
        totalTax: "0.00")]
    }

    func sampleCoupons() -> [OrderCouponLine] {
        let coupon1 = OrderCouponLine(couponID: 894,
                                      code: "30$off",
                                      discount: "30",
                                      discountTax: "1.2")
        return [coupon1]
    }

    func sampleCouponsMutated() -> [OrderCouponLine] {
        let coupon1 = OrderCouponLine(couponID: 894,
                                      code: "30$off",
                                      discount: "20",
                                      discountTax: "12.2")
        let coupon2 = OrderCouponLine(couponID: 12,
                                      code: "hithere!",
                                      discount: "50",
                                      discountTax: "0.66")
        return [coupon1, coupon2]
    }

    func sampleItems() -> [OrderItem] {
        let item1 = OrderItem(itemID: 890,
                              name: "Fruits Basket (Mix & Match Product)",
                              productID: 52,
                              variationID: 0,
                              quantity: 2,
                              price: NSDecimalNumber(integerLiteral: 30),
                              sku: "",
                              subtotal: "50.00",
                              subtotalTax: "2.00",
                              taxClass: "",
                              taxes: [],
                              total: "30.00",
                              totalTax: "1.20")

        let item2 = OrderItem(itemID: 891,
                              name: "Fruits Bundle",
                              productID: 234,
                              variationID: 0,
                              quantity: 1.5,
                              price: NSDecimalNumber(integerLiteral: 0),
                              sku: "5555-A",
                              subtotal: "10.00",
                              subtotalTax: "0.40",
                              taxClass: "",
                              taxes: [],
                              total: "0.00",
                              totalTax: "0.00")

        return [item1, item2]
    }

    func sampleItemsMutated() -> [OrderItem] {
        let item1 = OrderItem(itemID: 890,
                              name: "Fruits Basket (Mix & Match Product) 2",
                              productID: 52,
                              variationID: 0,
                              quantity: 10,
                              price: NSDecimalNumber(integerLiteral: 30),
                              sku: "",
                              subtotal: "60.00",
                              subtotalTax: "4.00",
                              taxClass: "",
                              taxes: [],
                              total: "64.00",
                              totalTax: "4.00")

        let item2 = OrderItem(itemID: 891,
                              name: "Fruits Bundle 2",
                              productID: 234,
                              variationID: 0,
                              quantity: 3,
                              price: NSDecimalNumber(integerLiteral: 0),
                              sku: "5555-A",
                              subtotal: "30.00",
                              subtotalTax: "0.40",
                              taxClass: "",
                              taxes: [],
                              total: "30.40",
                              totalTax: "0.40")

        let item3 = OrderItem(itemID: 23,
                              name: "Some new product",
                              productID: 12,
                              variationID: 0,
                              quantity: 1,
                              price: NSDecimalNumber(integerLiteral: 10),
                              sku: "QWE123",
                              subtotal: "130.00",
                              subtotalTax: "10.40",
                              taxClass: "",
                              taxes: [],
                              total: "140.40",
                              totalTax: "10.40")

        return [item1, item2, item3]
    }

    func sampleItemsMutated2() -> [OrderItem] {
        let item1 = OrderItem(itemID: 890,
                              name: "Fruits Basket (Mix & Match Product) 2",
                              productID: 52,
                              variationID: 0,
                              quantity: 10,
                              price: NSDecimalNumber(integerLiteral: 10),
                              sku: "",
                              subtotal: "60.00",
                              subtotalTax: "4.00",
                              taxClass: "",
                              taxes: [],
                              total: "64.00",
                              totalTax: "4.00")
        return [item1]
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}

// MARK: - Mirror

private extension SummaryTableViewCellTests {
    /// Represents private properties of `SummaryTableViewCell`
    ///
    struct SummaryTableViewCellMirror {
        let titleLabel: UILabel
        let createdLabel: UILabel
        let paymentStatusLabel: PaddedLabel
        let updateStatusButton: UIButton
    }

    /// Create testable struct to test private properties of `SummaryTableViewCell`
    ///
    func mirror(of cell: SummaryTableViewCell) throws -> SummaryTableViewCellMirror {
        let mirror = Mirror(reflecting: cell)

        return SummaryTableViewCellMirror(
            titleLabel: try XCTUnwrap(mirror.descendant("titleLabel") as? UILabel),
            createdLabel: try XCTUnwrap(mirror.descendant("createdLabel") as? UILabel),
            paymentStatusLabel: try XCTUnwrap(mirror.descendant("paymentStatusLabel") as? PaddedLabel),
            updateStatusButton: try XCTUnwrap(mirror.descendant("updateStatusButton") as? UIButton)
        )
    }
}
