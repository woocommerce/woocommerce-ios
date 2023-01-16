import XCTest
@testable import Networking


/// SiteAPIMapperTests Unit Tests
///
class SiteAPIMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 242424

    /// Dummy Site Namespaces.
    ///
    private let dummyNamespaces = ["oembed/1.0", "akismet/v1", "jetpack/v4", "wpcom/v2", "wc/v1", "wc/v2", "wc/v3", "wc-pb/v3", "wp/v2"]

    /// Dummy Broken Site Namespaces.
    ///
    private let dummyBrokenNamespaces = ["oembed/1.0", "akismet/v1", "jetpack/v4", "wpcom/v2", "wc-pb/v3", "wp/v2"]

    /// Verifies the SiteSetting fields are parsed correctly.
    ///
    func test_SiteSetting_fields_are_properly_parsed() {
        let apiSettings = mapLoadSiteAPIResponse()

        XCTAssertNotNil(apiSettings)
        XCTAssertEqual(apiSettings?.siteID, dummySiteID)
        XCTAssertNotNil(apiSettings?.namespaces)
        XCTAssertEqual(apiSettings?.namespaces, dummyNamespaces)
        XCTAssertEqual(apiSettings?.highestWooVersion, WooAPIVersion.mark3)
    }

    /// Verifies the SiteSetting fields are parsed correctly.
    ///
    func test_SiteSetting_fields_are_properly_parsed_when_response_has_no_data_envelope() {
        let apiSettings = mapLoadSiteAPIResponseWithoutDataEnvelope()

        XCTAssertNotNil(apiSettings)
        XCTAssertEqual(apiSettings?.siteID, dummySiteID)
        XCTAssertNotNil(apiSettings?.namespaces)
        XCTAssertEqual(apiSettings?.namespaces, dummyNamespaces)
        XCTAssertEqual(apiSettings?.highestWooVersion, WooAPIVersion.mark3)
    }

    /// Verifies the SiteSetting fields are parsed correctly.
    ///
    func test_broken_SiteSetting_fields_are_properly_parsed() {
        let apiSettings = mapLoadBrokenSiteAPIResponse()

        XCTAssertNotNil(apiSettings)
        XCTAssertEqual(apiSettings?.siteID, dummySiteID)
        XCTAssertNotNil(apiSettings?.namespaces)
        XCTAssertEqual(apiSettings?.namespaces, dummyBrokenNamespaces)
        XCTAssertEqual(apiSettings?.highestWooVersion, WooAPIVersion.none)
    }
}


/// Private Methods.
///
private extension SiteAPIMapperTests {

    /// Returns the SiteAPIMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSiteAPIData(from filename: String) -> SiteAPI? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! SiteAPIMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the SiteAPIMapper output upon receiving `site-api`
    ///
    func mapLoadSiteAPIResponse() -> SiteAPI? {
        return mapSiteAPIData(from: "site-api")
    }

    /// Returns the SiteAPIMapper output upon receiving `site-api-without-data`
    ///
    func mapLoadSiteAPIResponseWithoutDataEnvelope() -> SiteAPI? {
        return mapSiteAPIData(from: "site-api-without-data")
    }

    /// Returns the SiteAPIMapper output upon receiving `site-api`
    ///
    func mapLoadBrokenSiteAPIResponse() -> SiteAPI? {
        return mapSiteAPIData(from: "site-api-no-woo")
    }
}
