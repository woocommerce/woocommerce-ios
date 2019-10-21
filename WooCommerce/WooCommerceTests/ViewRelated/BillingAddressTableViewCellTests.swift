import XCTest
@testable import WooCommerce

final class BillingAddressTableViewCellTests: XCTestCase {

    private var cell: BillingAddressTableViewCell?

    private let nameMock = "Lorem ipsum"

    private let addressMock = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("BillingAddressTableViewCell", owner: self, options: nil)
        cell = nib?.first as? BillingAddressTableViewCell
        cell?.name = nameMock
        cell?.address = addressMock
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testNameLabelStyleIsSetToBody() {
        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        XCTAssertEqual(cell?.getNameLabel().font, mockLabel.font)
        XCTAssertEqual(cell?.getNameLabel().textColor, mockLabel.textColor)
    }

    func testAddressLabelStyleIsSetToBody() {
        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        XCTAssertEqual(cell?.getAddressLabel().font, mockLabel.font)
        XCTAssertEqual(cell?.getAddressLabel().textColor, mockLabel.textColor)
    }

    func testNameLabelValues() {
        XCTAssertEqual(cell?.getNameLabel().text, nameMock)
    }

    func testAddressLabelValues() {
        XCTAssertEqual(cell?.getAddressLabel().text, addressMock)
    }

}
