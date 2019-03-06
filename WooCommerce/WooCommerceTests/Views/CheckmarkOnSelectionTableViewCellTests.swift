import XCTest
@testable import WooCommerce

final class CheckmarkOnSelectionTableViewCellTests: XCTestCase {
    private var cell: CheckmarkOnSelectionTableViewCell?

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("CheckmarkOnSelectionTableViewCell", owner: self, options: nil)
        cell = nib?.first as? CheckmarkOnSelectionTableViewCell
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testTextLabelStyleIsSetToBody() {
        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        XCTAssertEqual(cell?.textLabel?.font, mockLabel.font)
        XCTAssertEqual(cell?.textLabel?.textColor, mockLabel.textColor)
    }

    func testTintColorMatchesExpectation() {
        XCTAssertEqual(cell?.tintColor, StyleManager.wooCommerceBrandColor)
    }

    func testAccessoryTypeForSelectedStateIsCheckMark() {
        cell?.setSelected(true, animated: false)
        XCTAssertEqual(cell?.accessoryType, .checkmark)
    }
}
