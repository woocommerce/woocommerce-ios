import XCTest
@testable import WooCommerce

final class CustomerNoteTableViewCellTests: XCTestCase {

    private let headlineMock = "Lorem ipsum"

    private let bodyMock = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

    @MainActor
    func testHeadlineLabelStyleIsSetToHeadline() throws {
        let cell = try makeSUT()
        let mockLabel = UILabel()
        mockLabel.applyHeadlineStyle()

        XCTAssertEqual(cell.getHeadlineLabel().font, mockLabel.font)
        XCTAssertEqual(cell.getHeadlineLabel().textColor, mockLabel.textColor)
    }

    @MainActor
    func testBodyLabelStyleIsSetToBody() throws {
        let cell = try makeSUT()
        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        XCTAssertEqual(cell.getBodyTextView().font, mockLabel.font)
        XCTAssertEqual(cell.getBodyTextView().textColor, mockLabel.textColor)
    }

    @MainActor
    func testHeadlineLabelValues() throws {
        let cell = try makeSUT()
        XCTAssertEqual(cell.getHeadlineLabel().text, headlineMock)
    }

    @MainActor
    func testBodyLabelValues() throws {
        let cell = try makeSUT()
        XCTAssertEqual(cell.getBodyTextView().text, bodyMock)
    }
}

private extension CustomerNoteTableViewCellTests {
    @MainActor
    func makeSUT() throws -> CustomerNoteTableViewCell {
        let nib = Bundle.main.loadNibNamed("CustomerNoteTableViewCell", owner: self, options: nil)
        let cell = try XCTUnwrap(nib?.first as? CustomerNoteTableViewCell)
        cell.headline = headlineMock
        cell.body = bodyMock
        return cell
    }
}
