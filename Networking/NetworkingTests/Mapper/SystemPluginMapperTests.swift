import XCTest
@testable import Networking

/// SystemPluginMapper Unit Tests
///
final class SystemPluginMapperTests: XCTestCase {

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
        let expectedNetworkActivated = false
        let expectedActive = true

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
        XCTAssertEqual(systemPlugin.active, expectedActive)
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
        let expectedNetworkActivated = false
        let expectedActive = false

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
        XCTAssertEqual(systemPlugin.active, expectedActive)
    }
}

/// Private Methods.
///
private extension SystemPluginMapperTests {

    /// Returns the SystemStatusMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapPlugins(from filename: String) throws -> [SystemPlugin] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try SystemPluginMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the SystemStatusMapper output upon receiving `systemPlugins`
    ///
    func mapLoadSystemStatusResponse() throws -> [SystemPlugin] {
        return try mapPlugins(from: "systemStatusWithPluginsOnly")
    }
}
