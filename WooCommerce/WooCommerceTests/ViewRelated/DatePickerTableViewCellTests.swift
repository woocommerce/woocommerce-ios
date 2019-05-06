import XCTest
@testable import WooCommerce

final class DatePickerTableViewCellTests: XCTestCase {
    private var cell: DatePickerTableViewCell?

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("DatePickerTableViewCell", owner: self, options: nil)
        cell = nib?.first as? DatePickerTableViewCell
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testPickerIsConfiguredAsDateOnly() {
        let pickerMode = cell?.getPicker().datePickerMode

        XCTAssertEqual(pickerMode, UIDatePicker.Mode.date)
    }

    func testPickerIsInitialisedWithToday() {
        let pickerDate = cell?.getPicker().date

        XCTAssertEqual(pickerDate?.normalizedDate(), Date().normalizedDate())
    }
}
