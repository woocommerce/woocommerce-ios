import XCTest
@testable import Networking


/// DateFormatter+Woo Unit Tests
///
class DateFormatterWooTests: XCTestCase {

    /// Sample Date
    ///
    let datetimeAsString = "2018-01-24T16:21:48"


    /// Verifies that a Woo Datetime is properly parsed by `DateFormatter.Defaults.dateTimeFormatter.
    ///
    func testWooFormattedDateIsProperlyParsed() {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: datetimeAsString) else {
            XCTFail()
            return
        }

        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: date), 2018)
        XCTAssertEqual(calendar.component(.month, from: date), 1)
        XCTAssertEqual(calendar.component(.day, from: date), 24)
    }
}
