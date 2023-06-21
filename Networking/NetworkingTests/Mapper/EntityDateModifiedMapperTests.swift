import XCTest
@testable import Networking

final class EntityDateModifiedMapperTests: XCTestCase {

    func test_date_modified_is_properly_parsed() throws {
        // Given
        let dates = [mapLoadDatesResponse(), mapLoadDatesResponseWithoutData()]
        let expectedDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2023-03-29T03:23:02")

        for date in dates {
            // Then
            assertEqual(expectedDate, date)
        }
    }

}

/// Private Methods.
///
private extension EntityDateModifiedMapperTests {

    /// Returns the EntityIDMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapDate(from filename: String) -> Date? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! EntityDateModifiedMapper().map(response: response)
    }

    /// Returns the EntityIDMapper output upon receiving `date-modified-gmt`
    ///
    func mapLoadDatesResponse() -> Date? {
        mapDate(from: "date-modified-gmt")
    }

    /// Returns the EntityIDMapper output upon receiving `date-modified-gmt-without-data`
    ///
    func mapLoadDatesResponseWithoutData() -> Date? {
        mapDate(from: "date-modified-gmt-without-data")
    }
}
