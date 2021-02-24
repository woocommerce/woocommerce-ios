import XCTest
@testable import WooCommerce
@testable import Networking

final class SiteAddressTests: XCTestCase {

    func test_the_address_fields_returns_the_expected_values() {
        // Arrange
        let siteSettings = mapLoadGeneralSiteSettingsResponse()

        // Act
        let siteAddress = SiteAddress(siteSettings: siteSettings)

        // Assert
        XCTAssertEqual(siteAddress.address, "60 29th Street #343")
        XCTAssertEqual(siteAddress.address2, "")
        XCTAssertEqual(siteAddress.city, "Auburn")
        XCTAssertEqual(siteAddress.postalCode, "13021")
        XCTAssertEqual(siteAddress.countryCode, "US")
        XCTAssertEqual(siteAddress.countryName, "United States")
        XCTAssertEqual(siteAddress.state, "NY")
    }

}

private extension SiteAddressTests {
    /// Returns the SiteSettings output upon receiving `filename` (Data Encoded)
    ///
    func mapGeneralSettings(from filename: String) -> [SiteSetting] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! SiteSettingsMapper(siteID: 123, settingsGroup: SiteSettingGroup.general).map(response: response)
    }

    /// Returns the SiteSetting array as output upon receiving `settings-general`
    ///
    func mapLoadGeneralSiteSettingsResponse() -> [SiteSetting] {
        return mapGeneralSettings(from: "settings-general")
    }
}
