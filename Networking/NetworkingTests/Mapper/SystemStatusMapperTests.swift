import XCTest
@testable import Networking

/// SystemStatusMapperTests Unit Tests
///
class SystemStatusMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 999999

    /// Verifies the SystemPlugin fields are parsed correctly for an active plugin
    ///
    func test_active_plugin_fields_are_properly_parsed() throws {
        // Given
        let expectedSiteId: Int64 = 999999
        let expectedPlugin = "woocommerce/woocommerce.php"
        let expectedName = "WooCommerce"
        let expectedUrl = "https://woocommerce.com/"
        let expectedVersion = "5.8.0"
        let expectedVersionLatest = "5.8.0"
        let expectedAuthorName = "Automattic"
        let expectedAuthorUrl = "https://woocommerce.com"
        /// TODO - The mapper is overriding networkActivated to be true for active plugins in general
        /// When we fix #5269 this test will need to be updated to properly test the
        /// new `activated` attribute that will be added to SystemPlugin instead
        let expectedNetworkActivated = true

        // When
        let systemPlugins = try mapLoadSystemStatusResponse()

        // Then
        XCTAssertEqual(systemPlugins.count, 6)

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

    /// Verifies the SystemPlugin fields are parsed correctly for an inactive plugin
    ///
    func test_inactive_plugin_fields_are_properly_parsed() throws {
        // Given
        let expectedSiteId: Int64 = 999999
        let expectedPlugin = "hello.php"
        let expectedName = "Hello Dolly"
        let expectedUrl = "http://wordpress.org/plugins/hello-dolly/"
        let expectedVersion = "1.7.2"
        let expectedVersionLatest = "1.7.2"
        let expectedAuthorName = "Matt Mullenweg"
        let expectedAuthorUrl = "http://ma.tt/"
        /// TODO - The mapper is overriding networkActivated to be true for active plugins in general
        /// When we fix #5269 this test will need to be updated to properly test the
        /// new `activated` attribute that will be added to SystemPlugin instead
        let expectedNetworkActivated = false

        // When
        let systemPlugins = try mapLoadSystemStatusResponse()

        // Then
        XCTAssertEqual(systemPlugins.count, 6)

        let systemPlugin = systemPlugins[5]
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
