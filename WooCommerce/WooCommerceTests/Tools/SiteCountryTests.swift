import XCTest
@testable import WooCommerce
@testable import Networking

final class SiteCountryTests: XCTestCase {

    func test_siteCountryName_is_not_nil() {

        // Arrange
        let siteSettings = mapLoadGeneralSiteSettingsResponse()

        // Act
        let siteCountry = SiteCountry(siteSettings: siteSettings)

        // Assert
        XCTAssertNotNil(siteCountry.siteCountryName)
        XCTAssertEqual(siteCountry.siteCountryName, "United States")
    }

}

private extension SiteCountryTests {
    /// Returns the SiteSettings output upon receiving `filename` (Data Encoded)
    ///
    func mapGeneralSettings(from filename: String) -> [SiteSetting] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! SiteSettingsMapper(siteID: 123, settingsGroup: SiteSettingGroup.general).map(response: response)
    }

    /// Returns the SiteSetting  array as output upon receiving `settings-general`
    ///
    func mapLoadGeneralSiteSettingsResponse() -> [SiteSetting] {
        return mapGeneralSettings(from: "settings-general")
    }
}
