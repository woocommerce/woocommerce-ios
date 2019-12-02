import XCTest
@testable import WooCommerce

final class StatusListTableViewCellTests: XCTestCase {
    private var cell: StatusListTableViewCell?

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("StatusListTableViewCell", owner: self, options: nil)
        cell = nib?.first as? StatusListTableViewCell
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
        XCTAssertEqual(cell?.tintColor.cgColor, UIColor.primary.cgColor)
    }

    func testAccessoryTypeForSelectedStateIsCheckMark() {
        cell?.setSelected(true, animated: false)
        XCTAssertEqual(cell?.accessoryType, .checkmark)
    }
}
