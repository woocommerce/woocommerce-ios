import XCTest
@testable import WooCommerce
import Yosemite

/// CurrencySettings Tests
///
class CurrencySettingsTests: XCTestCase {
    func testInitDefault() {
        let moneyFormat = CurrencySettings()

        XCTAssertEqual(.USD, moneyFormat.currencyCode)
        XCTAssertEqual(.left, moneyFormat.currencyPosition)
        XCTAssertEqual(".", moneyFormat.decimalSeparator)
        XCTAssertEqual(2, moneyFormat.numberOfDecimals)
        XCTAssertEqual(",", moneyFormat.thousandSeparator)
    }

    func testInitWithIndividualParameters() {
        let moneyFormat = CurrencySettings(currencyCode: Currency.Code.USD, currencyPosition: .right, thousandSeparator: "M", decimalSeparator: "X", numberOfDecimals: 10)

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
        let wooCurrencyCode = SiteSetting(siteID: 1, settingID: "woocommerce_currency", label: "", description: "", value: "SHP")
        let wooCurrencyPosition = SiteSetting(siteID: 1, settingID: "woocommerce_currency_pos", label: "", description: "", value: "right")
        let thousandsSeparator = SiteSetting(siteID: 1, settingID: "woocommerce_price_thousand_sep", label: "", description: "", value: "X")
        let decimalSeparator = SiteSetting(siteID: 1, settingID: "woocommerce_price_decimal_sep", label: "", description: "", value: "Y")
        let numberOfDecimals = SiteSetting(siteID: 1, settingID: "woocommerce_price_num_decimals", label: "", description: "", value: "3")

        let siteSettings = [wooCurrencyCode, wooCurrencyPosition, thousandsSeparator, decimalSeparator, numberOfDecimals]
        let moneyFormat = CurrencySettings(siteSettings: siteSettings)

        XCTAssertEqual(.SHP, moneyFormat.currencyCode)
        XCTAssertEqual(.right, moneyFormat.currencyPosition)
        XCTAssertEqual("Y", moneyFormat.decimalSeparator)
        XCTAssertEqual(3, moneyFormat.numberOfDecimals)
        XCTAssertEqual("X", moneyFormat.thousandSeparator)
    }

    func testInitWithIncompleteSiteSettings() {
        let wooCurrencyCode = SiteSetting(siteID: 1, settingID: "woocommerce_currency", label: "", description: "", value: "SHP")
        let wooCurrencyPosition = SiteSetting(siteID: 1, settingID: "woocommerce_currency_pos", label: "", description: "", value: "right")
        let thousandsSeparator = SiteSetting(siteID: 1, settingID: "woocommerce_price_thousand_sep", label: "", description: "", value: "X")
        let decimalSeparator = SiteSetting(siteID: 1, settingID: "woocommerce_price_decimal_sep", label: "", description: "", value: "Y")
        // Missing number of decimals; should default to MoneyFormatSettings()

        let siteSettings = [wooCurrencyCode, wooCurrencyPosition, thousandsSeparator, decimalSeparator]
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
        let symbol = CurrencySettings().symbol(from: .AED)
        XCTAssertEqual("د.إ", symbol)
    }
}
