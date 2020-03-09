import XCTest
@testable import WooCommerce

final class CustomerInfoTableViewCellTests: XCTestCase {

    private var cell: CustomerInfoTableViewCell?

    private let titleMock = "Lorem ipsum"

    private let nameMock = "Dolor Sit"

    private let addressMock = "Lorem ipsum dolor sit amet 5, San Francisco"

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("CustomerInfoTableViewCell", owner: self, options: nil)
        cell = nib?.first as? CustomerInfoTableViewCell
        cell?.title = titleMock
        cell?.name = nameMock
        cell?.address = addressMock
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testTitleLabelStyleIsSetToHeadline() {
        let mockLabel = UILabel()
        mockLabel.applyHeadlineStyle()

        XCTAssertEqual(cell?.getTitleLabel().font, mockLabel.font)
        XCTAssertEqual(cell?.getTitleLabel().textColor, mockLabel.textColor)
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

    func testTitleLabelValues() {
        XCTAssertEqual(cell?.getTitleLabel().text, titleMock)
    }

    func testNameLabelValues() {
        XCTAssertEqual(cell?.getNameLabel().text, nameMock)
    }

    func testAddressLabelValues() {
        XCTAssertEqual(cell?.getAddressLabel().text, addressMock)
    }

}
