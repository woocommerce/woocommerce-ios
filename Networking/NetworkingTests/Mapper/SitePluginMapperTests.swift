import XCTest
@testable import Networking

/// SitePluginMapper Unit Tests
///
final class SitePluginMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 1112

    /// Verifies the SitePlugin fields are parsed correctly.
    ///
    func test_SitePlugin_fields_are_properly_parsed() throws {
        let plugin = try XCTUnwrap(mapPlugin(from: "plugin"))
        XCTAssertEqual(plugin.plugin, "jetpack/jetpack")
        XCTAssertEqual(plugin.siteID, dummySiteID)
        XCTAssertEqual(plugin.status, .active)
        XCTAssertEqual(plugin.name, "Jetpack by WordPress.com")
        XCTAssertEqual(plugin.pluginUri, "https://jetpack.com")
        XCTAssertEqual(plugin.author, "Automattic")
        XCTAssertEqual(plugin.descriptionRaw, "Bring the power of the WordPress.com cloud to your self-hosted WordPress.")
        XCTAssertEqual(plugin.descriptionRendered, "Bring the power of the WordPress.com cloud to your self-hosted WordPress. " +
                       "<cite>By <a href=\"https://jetpack.com\">Automattic</a>.</cite>")
        XCTAssertEqual(plugin.version, "9.5")
        XCTAssertEqual(plugin.textDomain, "jetpack")
    }

    /// Verifies the SitePlugin fields are parsed correctly when there's no data envelope wrapping the response.
    ///
    func test_SitePlugin_fields_are_properly_parsed_for_response_without_data_envelope() throws {
        let plugin = try XCTUnwrap(mapPluginWithoutEnvelope(from: "site-plugin-without-envelope"))
        XCTAssertEqual(plugin.plugin, "jetpack/jetpack")
        XCTAssertEqual(plugin.siteID, -1)
        XCTAssertEqual(plugin.status, .active)
        XCTAssertEqual(plugin.name, "Jetpack")
        XCTAssertEqual(plugin.pluginUri, "https://jetpack.com")
        XCTAssertEqual(plugin.author, "Automattic")
        XCTAssertEqual(plugin.descriptionRaw, "Security, performance, and marketing tools made by WordPress experts. " +
                       "Jetpack keeps your site protected so you can focus on more important things.")
        XCTAssertEqual(plugin.descriptionRendered, "Security, performance, and marketing tools made by WordPress experts. " +
                       "Jetpack keeps your site protected so you can focus on more important things. " +
                       "<cite>By <a href=\"https://jetpack.com\">Automattic</a>.</cite>")
        XCTAssertEqual(plugin.version, "11.5.1")
        XCTAssertEqual(plugin.textDomain, "jetpack")
    }
}


/// Private Methods.
///
private extension SitePluginMapperTests {

    /// Returns the SitePluginMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapPlugin(from filename: String) -> SitePlugin? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? SitePluginMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the SitePluginMapper output upon receiving `filename` (Data Encoded)
    /// The decoder should not include data envelope.
    ///
    func mapPluginWithoutEnvelope(from filename: String) -> SitePlugin? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? SitePluginMapper().map(response: response)
    }
}
