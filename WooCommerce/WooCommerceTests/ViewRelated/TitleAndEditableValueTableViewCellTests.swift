import XCTest
@testable import WooCommerce

final class TitleAndEditableValueTableViewCellTests: XCTestCase {
    private var cell: TitleAndEditableValueTableViewCell?

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("TitleAndEditableValueTableViewCell", owner: self, options: nil)
        cell = nib?.first as? TitleAndEditableValueTableViewCell
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testCellIsNonSelectable() {
        XCTAssertEqual(cell?.selectionStyle, UITableViewCell.SelectionStyle.none)
    }

    func testTitleHasFootNoteStyleApplied() {
        let title = cell?.title

        XCTAssertEqual(title?.font, UIFont.footnote)
        XCTAssertEqual(title?.textColor, .systemColor(.secondaryLabel))
    }

    func testValueHasBodyStyleApplied() {
        let value = cell?.value

        XCTAssertEqual(value?.font, UIFont.body)
        XCTAssertEqual(value?.textColor, .text)
    }
}
