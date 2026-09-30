import XCTest
@testable import WooCommerce

final class CustomerInfoTableViewCellTests: XCTestCase {

    private let titleMock = "Lorem ipsum"

    private let nameMock = "Dolor Sit"

    private let addressMock = "Lorem ipsum dolor sit amet 5, San Francisco"

    @MainActor
    func testTitleLabelStyleIsSetToHeadline() throws {
        let cell = try makeSUT()
        let mockLabel = UILabel()
        mockLabel.applyHeadlineStyle()

        XCTAssertEqual(cell.getTitleLabel().font, mockLabel.font)
        XCTAssertEqual(cell.getTitleLabel().textColor, mockLabel.textColor)
    }

    @MainActor
    func testNameLabelStyleIsSetToBody() throws {
        let cell = try makeSUT()
        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        XCTAssertEqual(cell.getNameLabel().font, mockLabel.font)
        XCTAssertEqual(cell.getNameLabel().textColor, mockLabel.textColor)
    }

    @MainActor
    func testAddressLabelStyleIsSetToBody() throws {
        let cell = try makeSUT()
        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        XCTAssertEqual(cell.getAddressLabel().font, mockLabel.font)
        XCTAssertEqual(cell.getAddressLabel().textColor, mockLabel.textColor)
    }

    @MainActor
    func testTitleLabelValues() throws {
        let cell = try makeSUT()
        XCTAssertEqual(cell.getTitleLabel().text, titleMock)
    }

    @MainActor
    func testNameLabelValues() throws {
        let cell = try makeSUT()
        XCTAssertEqual(cell.getNameLabel().text, nameMock)
    }

    @MainActor
    func testAddressLabelValues() throws {
        let cell = try makeSUT()
        XCTAssertEqual(cell.getAddressLabel().text, addressMock)
    }
}

private extension CustomerInfoTableViewCellTests {
    @MainActor
    func makeSUT() throws -> CustomerInfoTableViewCell {
        let nib = Bundle.main.loadNibNamed("CustomerInfoTableViewCell", owner: self, options: nil)
        let cell = try XCTUnwrap(nib?.first as? CustomerInfoTableViewCell)
        cell.title = titleMock
        cell.name = nameMock
        cell.address = addressMock
        return cell
    }
}
