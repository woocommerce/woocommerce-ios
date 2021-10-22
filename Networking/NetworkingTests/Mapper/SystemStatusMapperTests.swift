import XCTest
@testable import Networking

/// SystemStatusMapperTests Unit Tests
///
class SystemStatusMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 999999

    /// Verifies the SystemPlugin fields are parsed correctly.
    ///
    func test_SystemPlugin_fields_are_properly_parsed() throws {
        // Given
        let expectedSiteId: Int64 = 999999
        let expectedPlugin = "woocommerce/woocommerce.php"
        let expectedName = "WooCommerce"
        let expectedUrl = "https://woocommerce.com/"
        let expectedVersion = "5.8.0"
        let expectedVersionLatest = "5.8.0"
        let expectedAuthorName = "Automattic"
        let expectedAuthorUrl = "https://woocommerce.com"
        let expectedNetworkActivated = false

        // When
        let systemPlugins = try mapLoadSystemStatusResponse()

        // Then
        XCTAssertEqual(systemPlugins.count, 4)

        let systemPlugin = systemPlugins[0]
        XCTAssertNotNil(systemPlugin)
        XCTAssertEqual(systemPlugin.siteID, expectedSiteId)
        XCTAssertEqual(systemPlugin.plugin, expectedPlugin)
        XCTAssertEqual(systemPlugin.name, expectedName)
        XCTAssertEqual(systemPlugin.url, expectedUrl)
        XCTAssertEqual(systemPlugin.version, expectedVersion)
        XCTAssertEqual(systemPlugin.versionLatest, expectedVersionLatest)
        XCTAssertEqual(systemPlugin.authorName, expectedAuthorName)
        XCTAssertEqual(systemPlugin.authorUrl, expectedAuthorUrl)
        XCTAssertEqual(systemPlugin.networkActivated, expectedNetworkActivated)
    }
}

/// Private Methods.
///
private extension SystemStatusMapperTests {

    /// Returns the SystemStatusMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapPlugins(from filename: String) throws -> [SystemPlugin] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try SystemStatusMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the SystemStatusMapper output upon receiving `systemPlugins`
    ///
    func mapLoadSystemStatusResponse() throws -> [SystemPlugin] {
        return try mapPlugins(from: "systemStatus")
    }
}
