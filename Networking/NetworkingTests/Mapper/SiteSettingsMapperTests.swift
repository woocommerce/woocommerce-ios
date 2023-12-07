import XCTest
@testable import Networking


/// SiteSettingsMapper Unit Tests
///
class SiteSettingsMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 242424

    /// Verifies the SiteSetting fields are parsed correctly.
    ///
    func test_SiteSetting_fields_are_properly_parsed() async {
        let settings = await mapLoadGeneralSiteSettingsResponse()
        XCTAssertEqual(settings.count, 20)

        let firstSetting = settings[0]
        XCTAssertNotNil(firstSetting)
        XCTAssertEqual(firstSetting.siteID, dummySiteID)
        XCTAssertEqual(firstSetting.settingID, "woocommerce_store_address")
        XCTAssertEqual(firstSetting.settingDescription, "The street address for your business location.")
        XCTAssertEqual(firstSetting.label, "Address line 1")
        XCTAssertEqual(firstSetting.value, "60 29th Street #343")

        let currencySetting = settings[14]
        XCTAssertNotNil(currencySetting)
        XCTAssertEqual(currencySetting.siteID, dummySiteID)
        XCTAssertEqual(currencySetting.settingID, "woocommerce_currency")
        XCTAssertEqual(currencySetting.settingDescription,
                       "This controls what currency prices are listed at in the catalog and which currency gateways will take payments in.")
        XCTAssertEqual(currencySetting.label, "Currency")
        XCTAssertEqual(currencySetting.value, "USD")

        let decimalSetting = settings[18]
        XCTAssertNotNil(decimalSetting)
        XCTAssertEqual(decimalSetting.siteID, dummySiteID)
        XCTAssertEqual(decimalSetting.settingID, "woocommerce_price_num_decimals")
        XCTAssertEqual(decimalSetting.settingDescription, "This sets the number of decimal points shown in displayed prices.")
        XCTAssertEqual(decimalSetting.label, "Number of decimals")
        XCTAssertEqual(decimalSetting.value, "2")
    }

    /// Verifies the SiteSetting fields are parsed correctly when response has no data envelope.
    ///
    func test_SiteSetting_fields_are_properly_parsed_when_response_has_no_data_envelope() async {
        let settings = await mapLoadGeneralSiteSettingsResponseWithoutDataEnvelope()
        XCTAssertEqual(settings.count, 20)

        let firstSetting = settings[0]
        XCTAssertNotNil(firstSetting)
        XCTAssertEqual(firstSetting.siteID, dummySiteID)
        XCTAssertEqual(firstSetting.settingID, "woocommerce_store_address")
        XCTAssertEqual(firstSetting.settingDescription, "The street address for your business location.")
        XCTAssertEqual(firstSetting.label, "Address line 1")
        XCTAssertEqual(firstSetting.value, "60 29th Street #343")

        let currencySetting = settings[14]
        XCTAssertNotNil(currencySetting)
        XCTAssertEqual(currencySetting.siteID, dummySiteID)
        XCTAssertEqual(currencySetting.settingID, "woocommerce_currency")
        XCTAssertEqual(currencySetting.settingDescription,
                       "This controls what currency prices are listed at in the catalog and which currency gateways will take payments in.")
        XCTAssertEqual(currencySetting.label, "Currency")
        XCTAssertEqual(currencySetting.value, "USD")

        let decimalSetting = settings[18]
        XCTAssertNotNil(decimalSetting)
        XCTAssertEqual(decimalSetting.siteID, dummySiteID)
        XCTAssertEqual(decimalSetting.settingID, "woocommerce_price_num_decimals")
        XCTAssertEqual(decimalSetting.settingDescription, "This sets the number of decimal points shown in displayed prices.")
        XCTAssertEqual(decimalSetting.label, "Number of decimals")
        XCTAssertEqual(decimalSetting.value, "2")
    }

    /// Verifies that a SiteSetting in a broken state gets default values
    ///
    func test_SiteSettings_are_properly_parsed_when_nulls_received() async {
        let settings = await mapLoadBrokenGeneralSiteSettingsResponse()
        XCTAssertEqual(settings.count, 1)

        let firstSetting = settings[0]
        XCTAssertNotNil(firstSetting)
        XCTAssertEqual(firstSetting.siteID, dummySiteID)
        XCTAssertEqual(firstSetting.settingID, "woocommerce_currency")
        XCTAssertEqual(firstSetting.settingDescription, "")
        XCTAssertEqual(firstSetting.label, "")
        XCTAssertEqual(firstSetting.value, "")
    }
}


/// Private Methods.
///
private extension SiteSettingsMapperTests {

    /// Returns the [SiteSetting] output upon receiving `filename` (Data Encoded)
    ///
    func mapGeneralSettings(from filename: String) async -> [SiteSetting] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! await SiteSettingsMapper(siteID: dummySiteID, settingsGroup: SiteSettingGroup.general).map(response: response)
    }

    /// Returns the [SiteSetting] output upon receiving `settings-general`
    ///
    func mapLoadGeneralSiteSettingsResponse() async -> [SiteSetting] {
        return await mapGeneralSettings(from: "settings-general")
    }

    /// Returns the [SiteSetting] output upon receiving `settings-general-without-data`
    ///
    func mapLoadGeneralSiteSettingsResponseWithoutDataEnvelope() async -> [SiteSetting] {
        return await mapGeneralSettings(from: "settings-general-without-data")
    }

    /// Returns the [SiteSetting] output upon receiving `broken-settings-general`
    ///
    func mapLoadBrokenGeneralSiteSettingsResponse() async -> [SiteSetting] {
        return await mapGeneralSettings(from: "broken-settings-general")
    }
}
