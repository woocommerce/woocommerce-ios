import XCTest
@testable import WooCommerce

@MainActor
final class StatusListTableViewCellTests: XCTestCase {

    func testTextLabelStyleIsSetToBody() throws {
        let cell = try makeView()

        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        XCTAssertEqual(cell.textLabel?.font, mockLabel.font)
        XCTAssertEqual(cell.textLabel?.textColor, mockLabel.textColor)
    }

    func testTintColorMatchesExpectation() throws {
        let cell = try makeView()

        XCTAssertEqual(cell.tintColor.cgColor, UIColor.primary.cgColor)
    }

    func testAccessoryTypeForSelectedStateIsCheckMark() throws {
        let cell = try makeView()

        cell.setSelected(true, animated: false)
        XCTAssertEqual(cell.accessoryType, .checkmark)
    }

    private func makeView() throws -> StatusListTableViewCell {
        let nib = try XCTUnwrap(Bundle.main.loadNibNamed("StatusListTableViewCell", owner: nil, options: nil))
        return try XCTUnwrap(nib.first as? StatusListTableViewCell)
    }
}
