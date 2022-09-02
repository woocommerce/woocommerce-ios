import XCTest
@testable import Networking

final class SiteSettingMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 242424

    /// Verifies the SiteSetting fields are parsed correctly.
    ///
    func test_SiteSetting_fields_are_properly_parsed() throws {
        let setting = try XCTUnwrap(mapLoadCouponSettingResponse())
        XCTAssertEqual(setting.siteID, dummySiteID)
        XCTAssertEqual(setting.settingID, "woocommerce_enable_coupons")
        XCTAssertEqual(setting.settingDescription, "Enable the use of coupon codes")
        XCTAssertEqual(setting.label, "Enable coupons")
        XCTAssertEqual(setting.value, "yes")
    }
    func test_SiteSetting_value_field_is_properly_parsed_when_value_field_is_not_string() throws {
        let setting = try XCTUnwrap(loadMultiselectValueSettingResponse())
        XCTAssertEqual(setting.settingID, "woocommerce_all_except_countries")
        XCTAssertTrue(setting.value.isEmpty)
    }
}

private extension SiteSettingMapperTests {

    /// Returns the SiteSettingMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSetting(from filename: String) -> SiteSetting? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? SiteSettingMapper(siteID: dummySiteID, settingsGroup: SiteSettingGroup.general).map(response: response)
    }

    /// Returns the SiteSettingMapper output upon receiving `setting-coupon`
    ///
    func mapLoadCouponSettingResponse() -> SiteSetting? {
        return mapSetting(from: "setting-coupon")
    }
    /// Returns the SiteSettingMapper output upon receiving `setting-all-except-countries`
    ///
    func loadMultiselectValueSettingResponse() -> SiteSetting? {
        return mapSetting(from: "setting-all-except-countries")
    }
}
