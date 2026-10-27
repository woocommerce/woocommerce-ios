import XCTest
@testable import WooCommerce

@MainActor
final class DatePickerTableViewCellTests: XCTestCase {

    func testPickerIsConfiguredAsDateOnly() throws {
        let cell = try makeView()

        let pickerMode = cell.getPicker().datePickerMode

        XCTAssertEqual(pickerMode, UIDatePicker.Mode.date)
    }

    func testPickerIsInitialisedWithToday() throws {
        let cell = try makeView()

        let pickerDate = cell.getPicker().date

        XCTAssertEqual(pickerDate.normalizedDate(), Date().normalizedDate())
    }

    private func makeView() throws -> DatePickerTableViewCell {
        let nib = try XCTUnwrap(Bundle.main.loadNibNamed("DatePickerTableViewCell", owner: nil, options: nil))
        return try XCTUnwrap(nib.first as? DatePickerTableViewCell)
    }
}
