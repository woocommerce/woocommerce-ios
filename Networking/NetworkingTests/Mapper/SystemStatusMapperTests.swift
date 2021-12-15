import XCTest
@testable import Networking

/// SystemStatusMapper Unit Tests
///
final class SystemStatusMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 999999

    func test_system_status_fields_are_properly_parsed() throws {
        // When
        let report = try mapLoadSystemStatusResponse()

        // Then
        XCTAssertEqual(report.environment?.homeURL, "https://additional-beetle.jurassic.ninja")
        XCTAssertEqual(report.database?.wcDatabaseVersion, "5.9.0")
        XCTAssertEqual(report.activePlugins.count, 4)
        XCTAssertEqual(report.activePlugins[0].siteID, dummySiteID)
        XCTAssertEqual(report.inactivePlugins.count, 2)
        XCTAssertEqual(report.inactivePlugins[1].siteID, dummySiteID)
        XCTAssertEqual(report.theme?.name, "Twenty Twenty-One")
        XCTAssertEqual(report.settings?.apiEnabled, false)
        XCTAssertEqual(report.security?.secureConnection, true)
        XCTAssertEqual(report.pages.count, 5)
        XCTAssertEqual(report.postTypeCounts.count, 3)
    }
}

private extension SystemStatusMapperTests {

    /// Returns the SystemStatusMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapReport(from filename: String) throws -> SystemStatus {
        guard let response = Loader.contentsOf(filename) else {
            throw NetworkError.notFound
        }

        return try SystemStatusMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the SystemStatusMapper output upon receiving `systemStatus.json`
    ///
    func mapLoadSystemStatusResponse() throws -> SystemStatus {
        return try mapReport(from: "systemStatus")
    }
}
