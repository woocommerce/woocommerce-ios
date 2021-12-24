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
    func test_SitePlugin_fields_are_properly_parsed() {
        let plugin = mapPlugin(from: "plugin")
        XCTAssertNotNil(plugin)
        XCTAssertEqual(plugin?.plugin, "jetpack/jetpack")
        XCTAssertEqual(plugin?.siteID, dummySiteID)
        XCTAssertEqual(plugin?.status, .active)
        XCTAssertEqual(plugin?.name, "Jetpack by WordPress.com")
        XCTAssertEqual(plugin?.pluginUri, "https://jetpack.com")
        XCTAssertEqual(plugin?.author, "Automattic")
        XCTAssertEqual(plugin?.descriptionRaw, "Bring the power of the WordPress.com cloud to your self-hosted WordPress.")
        XCTAssertEqual(plugin?.descriptionRendered, "Bring the power of the WordPress.com cloud to your self-hosted WordPress. " +
                       "<cite>By <a href=\"https://jetpack.com\">Automattic</a>.</cite>")
        XCTAssertEqual(plugin?.version, "9.5")
        XCTAssertEqual(plugin?.textDomain, "jetpack")
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
}
