import XCTest
@testable import WooCommerce

final class CustomerNoteTableViewCellTests: XCTestCase {

    private var cell: CustomerNoteTableViewCell?

    private let headlineMock = "Lorem ipsum"

    private let bodyMock = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("CustomerNoteTableViewCell", owner: self, options: nil)
        cell = nib?.first as? CustomerNoteTableViewCell
        cell?.headline = headlineMock
        cell?.body = bodyMock
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testHeadlineLabelStyleIsSetToHeadline() {
        let mockLabel = UILabel()
        mockLabel.applyHeadlineStyle()

        XCTAssertEqual(cell?.getHeadlineLabel().font, mockLabel.font)
        XCTAssertEqual(cell?.getHeadlineLabel().textColor, mockLabel.textColor)
    }

    func testBodyLabelStyleIsSetToBody() {
        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        XCTAssertEqual(cell?.getBodyLabel().font, mockLabel.font)
        XCTAssertEqual(cell?.getBodyLabel().textColor, mockLabel.textColor)
    }

    func testHeadlineLabelValues() {
        XCTAssertEqual(cell?.getHeadlineLabel().text, headlineMock)
    }

    func testBodyLabelValues() {
        XCTAssertEqual(cell?.getBodyLabel().text, bodyMock)
    }

}
