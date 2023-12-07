import XCTest
@testable import Networking

final class SiteSettingMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 242424

    /// Verifies the SiteSetting fields are parsed correctly.
    ///
    func test_SiteSetting_fields_are_properly_parsed() async throws {
        let setting = try await mapLoadCouponSettingResponse()
        XCTAssertEqual(setting.siteID, dummySiteID)
        XCTAssertEqual(setting.settingID, "woocommerce_enable_coupons")
        XCTAssertEqual(setting.settingDescription, "Enable the use of coupon codes")
        XCTAssertEqual(setting.label, "Enable coupons")
        XCTAssertEqual(setting.value, "yes")
    }

    /// Verifies the SiteSetting fields are parsed correctly when response has no data envelope.
    ///
    func test_SiteSetting_fields_are_properly_parsed_when_response_has_no_data_envelope() async throws {
        let setting = try await mapLoadCouponSettingResponseWithoutDataEnvelope()
        XCTAssertEqual(setting.siteID, dummySiteID)
        XCTAssertEqual(setting.settingID, "woocommerce_enable_coupons")
        XCTAssertEqual(setting.settingDescription, "Enable the use of coupon codes")
        XCTAssertEqual(setting.label, "Enable coupons")
        XCTAssertEqual(setting.value, "yes")
    }

    func test_SiteSetting_value_field_is_properly_parsed_when_value_field_is_not_string() async throws {
        let setting = try await loadMultiselectValueSettingResponse()
        XCTAssertEqual(setting.settingID, "woocommerce_all_except_countries")
        XCTAssertTrue(setting.value.isEmpty)
    }
}

private extension SiteSettingMapperTests {

    /// Returns the SiteSettingMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSetting(from filename: String) async throws -> SiteSetting {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await SiteSettingMapper(siteID: dummySiteID, settingsGroup: SiteSettingGroup.general).map(response: response)
    }

    /// Returns the SiteSettingMapper output upon receiving `setting-coupon`
    ///
    func mapLoadCouponSettingResponse() async throws -> SiteSetting {
        try await mapSetting(from: "setting-coupon")
    }

    /// Returns the SiteSettingMapper output upon receiving `setting-coupon-without-data`
    ///
    func mapLoadCouponSettingResponseWithoutDataEnvelope() async throws -> SiteSetting {
        try await mapSetting(from: "setting-coupon-without-data")
    }

    /// Returns the SiteSettingMapper output upon receiving `setting-all-except-countries`
    ///
    func loadMultiselectValueSettingResponse() async throws -> SiteSetting {
        try await mapSetting(from: "setting-all-except-countries")
    }

    struct FileNotFoundError: Error {}
}
