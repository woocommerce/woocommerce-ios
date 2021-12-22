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
        XCTAssertEqual(report.environment?.siteURL, "https://additional-beetle.jurassic.ninja")
        XCTAssertEqual(report.environment?.version, "5.9.0")
        XCTAssertEqual(report.environment?.wpVersion, "5.8.2")
        XCTAssertEqual(report.environment?.phpVersion, "7.4.26")
        XCTAssertEqual(report.environment?.curlVersion, "7.47.0, OpenSSL/1.0.2g")
        XCTAssertEqual(report.environment?.mysqlVersion, "5.7.33-0ubuntu0.16.04.1-log")

        XCTAssertEqual(report.database?.wcDatabaseVersion, "5.9.0")
        XCTAssertEqual(report.database?.databasePrefix, "wp_")
        XCTAssertEqual(report.database?.databaseTables.woocommerce.count, 14)
        XCTAssertEqual(report.database?.databaseTables.other.count, 29)

        XCTAssertEqual(report.activePlugins.count, 4)
        XCTAssertEqual(report.activePlugins[0].siteID, dummySiteID)
        XCTAssertEqual(report.inactivePlugins.count, 2)
        XCTAssertEqual(report.inactivePlugins[1].siteID, dummySiteID)
        XCTAssertEqual(report.dropinPlugins.count, 2)
        XCTAssertEqual(report.dropinPlugins[0].name, "advanced-cache.php")
        XCTAssertEqual(report.mustUsePlugins.count, 1)
        XCTAssertEqual(report.mustUsePlugins[0].name, "WP.com Site Helper")

        XCTAssertEqual(report.theme?.name, "Twenty Twenty-One")
        XCTAssertEqual(report.theme?.version, "1.4")
        XCTAssertEqual(report.theme?.authorURL, "https://wordpress.org/")
        XCTAssertEqual(report.theme?.hasWoocommerceSupport, true)
        XCTAssertEqual(report.theme?.overrides.count, 0)

        XCTAssertEqual(report.settings?.apiEnabled, false)
        XCTAssertEqual(report.settings?.currency, "USD")
        XCTAssertEqual(report.settings?.currencySymbol, "&#36;")
        XCTAssertEqual(report.settings?.currencyPosition, "left")
        XCTAssertEqual(report.settings?.numberOfDecimals, 2)
        XCTAssertEqual(report.settings?.thousandSeparator, ",")
        XCTAssertEqual(report.settings?.decimalSeparator, ".")
        XCTAssertEqual(report.settings?.taxonomies["external"], "external")
        XCTAssertEqual(report.settings?.productVisibilityTerms["exclude-from-catalog"], "exclude-from-catalog")

        XCTAssertEqual(report.security?.secureConnection, true)
        XCTAssertEqual(report.security?.hideErrors, false)

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
