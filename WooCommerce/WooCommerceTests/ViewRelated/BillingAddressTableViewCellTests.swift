import XCTest
@testable import WooCommerce

final class BillingAddressTableViewCellTests: XCTestCase {

    private let nameMock = "Lorem ipsum"

    private let addressMock = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

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

private extension BillingAddressTableViewCellTests {
    @MainActor
    func makeSUT() throws -> BillingAddressTableViewCell {
        let nib = Bundle.main.loadNibNamed("BillingAddressTableViewCell", owner: self, options: nil)
        let cell = try XCTUnwrap(nib?.first as? BillingAddressTableViewCell)
        cell.name = nameMock
        cell.address = addressMock
        return cell
    }
}
