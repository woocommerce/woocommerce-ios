import XCTest
@testable import WooCommerce

final class TitleAndEditableValueTableViewCellTests: XCTestCase {
    private var cell: TitleAndEditableValueTableViewCell!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let nib = try XCTUnwrap(Bundle.main.loadNibNamed("TitleAndEditableValueTableViewCell", owner: self, options: nil))
        cell = try XCTUnwrap(nib.first as? TitleAndEditableValueTableViewCell)
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testCellIsNonSelectable() {
        XCTAssertEqual(cell.selectionStyle, UITableViewCell.SelectionStyle.none)
    }

    func testTitleHasFootNoteStyleApplied() throws {
        // Given
        let mirror = try self.mirror(of: cell)

        // When
        let title = mirror.title

        // Then
        XCTAssertEqual(title.font, UIFont.footnote)
        XCTAssertEqual(title.textColor, .systemColor(.secondaryLabel))
    }

    func testValueHasBodyStyleApplied() throws {
        // Given
        let mirror = try self.mirror(of: cell)

        // When
        let value = mirror.value

        // Then
        XCTAssertEqual(value.font, UIFont.body)
        XCTAssertEqual(value.textColor, .text)
    }
}

private extension TitleAndEditableValueTableViewCellTests {
    struct TitleAndEditableValueTableViewCellMirror {
        let title: UILabel
        let value: UITextField
    }

    func mirror(of cell: TitleAndEditableValueTableViewCell) throws -> TitleAndEditableValueTableViewCellMirror {
        let mirror = Mirror(reflecting: cell)

        return TitleAndEditableValueTableViewCellMirror(
            title: try XCTUnwrap(mirror.descendant("title") as? UILabel),
            value: try XCTUnwrap(mirror.descendant("value") as? UITextField)
        )
    }

}
