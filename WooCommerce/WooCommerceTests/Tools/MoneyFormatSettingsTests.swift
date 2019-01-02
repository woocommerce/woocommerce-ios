import XCTest
@testable import WooCommerce
import Yosemite

/// MoneyFormatSettings Tests
///
class MoneyFormatSettingsTests: XCTestCase {
    func testInitDefault() {
        let moneyFormat = CurrencyOptions()

        XCTAssertEqual(.left, moneyFormat.currencyPosition)
        XCTAssertEqual(".", moneyFormat.decimalSeparator)
        XCTAssertEqual(2, moneyFormat.numberOfDecimals)
        XCTAssertEqual(",", moneyFormat.thousandSeparator)
    }

    func testInitWithIndividualParameters() {
        let moneyFormat = CurrencyOptions(currencyPosition: .right, thousandSeparator: "M", decimalSeparator: "X", numberOfDecimals: 10)

        XCTAssertEqual(.right, moneyFormat.currencyPosition)
        XCTAssertEqual("X", moneyFormat.decimalSeparator)
        XCTAssertEqual(10, moneyFormat.numberOfDecimals)
        XCTAssertEqual("M", moneyFormat.thousandSeparator)
    }

    func testInitWithSiteSettingsEmptyArray() {
        let siteSettings: [SiteSetting] = []
        let moneyFormat = CurrencyOptions(siteSettings: siteSettings)

        XCTAssertEqual(.left, moneyFormat.currencyPosition)
        XCTAssertEqual(".", moneyFormat.decimalSeparator)
        XCTAssertEqual(2, moneyFormat.numberOfDecimals)
        XCTAssertEqual(",", moneyFormat.thousandSeparator)
    }

    func testInitWithSiteSettings() {
        let wooCurrencyPosition = SiteSetting(siteID: 1, settingID: "woocommerce_currency_pos", label: "", description: "", value: "right")
        let thousandsSeparator = SiteSetting(siteID: 1, settingID: "woocommerce_price_thousand_sep", label: "", description: "", value: "X")
        let decimalSeparator = SiteSetting(siteID: 1, settingID: "woocommerce_price_decimal_sep", label: "", description: "", value: "Y")
        let numberOfDecimals = SiteSetting(siteID: 1, settingID: "woocommerce_price_num_decimals", label: "", description: "", value: "3")

        let siteSettings = [wooCurrencyPosition, thousandsSeparator, decimalSeparator, numberOfDecimals]
        let moneyFormat = CurrencyOptions(siteSettings: siteSettings)

        XCTAssertEqual(.right, moneyFormat.currencyPosition)
        XCTAssertEqual("Y", moneyFormat.decimalSeparator)
        XCTAssertEqual(3, moneyFormat.numberOfDecimals)
        XCTAssertEqual("X", moneyFormat.thousandSeparator)
    }

    func testInitWithIncompleteSiteSettings() {
        let wooCurrencyPosition = SiteSetting(siteID: 1, settingID: "woocommerce_currency_pos", label: "", description: "", value: "right")
        let thousandsSeparator = SiteSetting(siteID: 1, settingID: "woocommerce_price_thousand_sep", label: "", description: "", value: "X")
        let decimalSeparator = SiteSetting(siteID: 1, settingID: "woocommerce_price_decimal_sep", label: "", description: "", value: "Y")
        // Missing number of decimals; should default to MoneyFormatSettings()

        let siteSettings = [wooCurrencyPosition, thousandsSeparator, decimalSeparator]
        let moneyFormat = CurrencyOptions(siteSettings: siteSettings)

        XCTAssertEqual(.right, moneyFormat.currencyPosition)
        XCTAssertEqual("Y", moneyFormat.decimalSeparator)
        XCTAssertEqual(2, moneyFormat.numberOfDecimals)
        XCTAssertEqual("X", moneyFormat.thousandSeparator)
    }

}
