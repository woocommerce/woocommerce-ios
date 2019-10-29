import XCTest
@testable import WooCommerce
import Yosemite

/// CurrencySettings Tests
///
class CurrencySettingsTests: XCTestCase {

    override func setUp() {
        ServiceLocator.stores.deauthenticate()

        super.setUp()
    }

    func testInitDefault() {
        let moneyFormat = CurrencySettings()

        XCTAssertEqual(.USD, moneyFormat.currencyCode)
        XCTAssertEqual(.left, moneyFormat.currencyPosition)
        XCTAssertEqual(".", moneyFormat.decimalSeparator)
        XCTAssertEqual(2, moneyFormat.numberOfDecimals)
        XCTAssertEqual(",", moneyFormat.thousandSeparator)
    }

    func testInitWithIndividualParameters() {
        let moneyFormat = CurrencySettings(currencyCode: .USD,
                                           currencyPosition: .right,
                                           thousandSeparator: "M",
                                           decimalSeparator: "X",
                                           numberOfDecimals: 10)

        XCTAssertEqual(.USD, moneyFormat.currencyCode)
        XCTAssertEqual(.right, moneyFormat.currencyPosition)
        XCTAssertEqual("X", moneyFormat.decimalSeparator)
        XCTAssertEqual(10, moneyFormat.numberOfDecimals)
        XCTAssertEqual("M", moneyFormat.thousandSeparator)
    }

    func testInitWithSiteSettingsEmptyArray() {
        let siteSettings: [SiteSetting] = []
        let moneyFormat = CurrencySettings(siteSettings: siteSettings)

        XCTAssertEqual(.USD, moneyFormat.currencyCode)
        XCTAssertEqual(.left, moneyFormat.currencyPosition)
        XCTAssertEqual(".", moneyFormat.decimalSeparator)
        XCTAssertEqual(2, moneyFormat.numberOfDecimals)
        XCTAssertEqual(",", moneyFormat.thousandSeparator)
    }

    func testInitWithSiteSettings() {
        let wooCurrencyCode = SiteSetting(siteID: 1,
                                          settingID: "woocommerce_currency",
                                          label: "",
                                          description: "",
                                          value: "SHP",
                                          settingGroupKey: SiteSettingGroup.general.rawValue)

        let wooCurrencyPosition = SiteSetting(siteID: 1,
                                              settingID: "woocommerce_currency_pos",
                                              label: "",
                                              description: "",
                                              value: "right",
                                              settingGroupKey: SiteSettingGroup.general.rawValue)

        let thousandsSeparator = SiteSetting(siteID: 1,
                                             settingID: "woocommerce_price_thousand_sep",
                                             label: "",
                                             description: "",
                                             value: "X",
                                             settingGroupKey: SiteSettingGroup.general.rawValue)

        let decimalSeparator = SiteSetting(siteID: 1,
                                           settingID: "woocommerce_price_decimal_sep",
                                           label: "",
                                           description: "",
                                           value: "Y",
                                           settingGroupKey: SiteSettingGroup.general.rawValue)

        let numberOfDecimals = SiteSetting(siteID: 1,
                                           settingID: "woocommerce_price_num_decimals",
                                           label: "",
                                           description: "",
                                           value: "3",
                                           settingGroupKey: SiteSettingGroup.general.rawValue)

        let siteSettings = [wooCurrencyCode,
                            wooCurrencyPosition,
                            thousandsSeparator,
                            decimalSeparator,
                            numberOfDecimals]

        let moneyFormat = CurrencySettings(siteSettings: siteSettings)

        XCTAssertEqual(.SHP, moneyFormat.currencyCode)
        XCTAssertEqual(.right, moneyFormat.currencyPosition)
        XCTAssertEqual("Y", moneyFormat.decimalSeparator)
        XCTAssertEqual(3, moneyFormat.numberOfDecimals)
        XCTAssertEqual("X", moneyFormat.thousandSeparator)
    }

    func testInitWithIncompleteSiteSettings() {
        let wooCurrencyCode = SiteSetting(siteID: 1,
                                          settingID: "woocommerce_currency",
                                          label: "",
                                          description: "",
                                          value: "SHP",
                                          settingGroupKey: SiteSettingGroup.general.rawValue)

        let wooCurrencyPosition = SiteSetting(siteID: 1,
                                              settingID: "woocommerce_currency_pos",
                                              label: "",
                                              description: "",
                                              value: "right",
                                              settingGroupKey: SiteSettingGroup.general.rawValue)

        let thousandsSeparator = SiteSetting(siteID: 1,
                                             settingID: "woocommerce_price_thousand_sep",
                                             label: "",
                                             description: "",
                                             value: "X",
                                             settingGroupKey: SiteSettingGroup.general.rawValue)

        let decimalSeparator = SiteSetting(siteID: 1,
                                           settingID: "woocommerce_price_decimal_sep",
                                           label: "",
                                           description: "",
                                           value: "Y",
                                           settingGroupKey: SiteSettingGroup.general.rawValue)

        // Note that the above is missing a declaration for the number of decimals; it should default to 2.

        let siteSettings = [wooCurrencyCode,
                            wooCurrencyPosition,
                            thousandsSeparator,
                            decimalSeparator]

        let moneyFormat = CurrencySettings(siteSettings: siteSettings)

        XCTAssertEqual(.SHP, moneyFormat.currencyCode)
        XCTAssertEqual(.right, moneyFormat.currencyPosition)
        XCTAssertEqual("Y", moneyFormat.decimalSeparator)
        XCTAssertEqual(2, moneyFormat.numberOfDecimals)
        XCTAssertEqual("X", moneyFormat.thousandSeparator)
    }

    /// Test currency symbol lookup returns correctly encoded symbol.
    ///
    func testCurrencySymbol() {
        let symbol = CurrencySettings.shared.symbol(from: CurrencySettings.CurrencyCode.AED)
        XCTAssertEqual("د.إ", symbol)
    }
}
