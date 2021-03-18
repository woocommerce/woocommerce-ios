import XCTest
@testable import Networking

/// SitePluginsMapper Unit Tests
///
class SitePluginsMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 242424

    /// Verifies the SitePlugin fields are parsed correctly.
    ///
    func test_SitePlugin_fields_are_properly_parsed() {
        let plugins = mapLoadSitePluginsResponse()
        XCTAssertEqual(plugins.count, 5)

        let helloDollyPlugin = plugins[0]
        XCTAssertNotNil(helloDollyPlugin)
        XCTAssertEqual(helloDollyPlugin.siteID, dummySiteID)
        XCTAssertEqual(helloDollyPlugin.status, .inactive)
        XCTAssertEqual(helloDollyPlugin.name, "Hello Dolly")
        XCTAssertEqual(helloDollyPlugin.pluginUri, "http://wordpress.org/plugins/hello-dolly/")
        XCTAssertEqual(helloDollyPlugin.authorUri, "http://ma.tt/")
        XCTAssertEqual(helloDollyPlugin.descriptionRaw, "This is not just a plugin, it...")
        XCTAssertEqual(helloDollyPlugin.descriptionRendered, "This is not just a plugin, it symbolizes...")
        XCTAssertEqual(helloDollyPlugin.version, "1.7.2")
        XCTAssertEqual(helloDollyPlugin.textDomain, "")

        let wooCommerceSubscriptionsPlugin = plugins[4]
        XCTAssertNotNil(wooCommerceSubscriptionsPlugin)
        XCTAssertEqual(wooCommerceSubscriptionsPlugin.siteID, dummySiteID)
        XCTAssertEqual(wooCommerceSubscriptionsPlugin.status, .active)
        XCTAssertEqual(wooCommerceSubscriptionsPlugin.name, "WooCommerce Subscriptions")
        XCTAssertEqual(wooCommerceSubscriptionsPlugin.pluginUri, "https://www.woocommerce.com/products/woocommerce-subscriptions/")
        XCTAssertEqual(wooCommerceSubscriptionsPlugin.authorUri, "https://woocommerce.com/")
        XCTAssertEqual(wooCommerceSubscriptionsPlugin.descriptionRaw, "Sell products and services...")
        XCTAssertEqual(wooCommerceSubscriptionsPlugin.descriptionRendered, "Sell products and services with recurring payments...")
        XCTAssertEqual(wooCommerceSubscriptionsPlugin.version, "3.0.13")
        XCTAssertEqual(wooCommerceSubscriptionsPlugin.textDomain, "woocommerce-subscriptions")
    }
}


/// Private Methods.
///
private extension SitePluginsMapperTests {

    /// Returns the SitePluginsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapPlugins(from filename: String) -> [SitePlugin] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! SitePluginsMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the SitePluginsMapper output upon receiving `plugins`
    ///
    func mapLoadSitePluginsResponse() -> [SitePlugin] {
        return mapPlugins(from: "plugins")
    }
}
