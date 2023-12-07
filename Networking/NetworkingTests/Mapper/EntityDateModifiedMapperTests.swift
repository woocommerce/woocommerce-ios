import XCTest
@testable import Networking

final class EntityDateModifiedMapperTests: XCTestCase {

    func test_date_modified_is_properly_parsed() async throws {
        // Given
        let dates = [await mapLoadDatesResponse(), await mapLoadDatesResponseWithoutData()]
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
    func mapDate(from filename: String) async -> Date? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! await EntityDateModifiedMapper().map(response: response)
    }

    /// Returns the EntityIDMapper output upon receiving `date-modified-gmt`
    ///
    func mapLoadDatesResponse() async -> Date? {
        await mapDate(from: "date-modified-gmt")
    }

    /// Returns the EntityIDMapper output upon receiving `date-modified-gmt-without-data`
    ///
    func mapLoadDatesResponseWithoutData() async -> Date? {
        await mapDate(from: "date-modified-gmt-without-data")
    }
}
