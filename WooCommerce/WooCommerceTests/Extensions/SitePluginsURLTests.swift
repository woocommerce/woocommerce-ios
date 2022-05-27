import Yosemite

@testable import WooCommerce

import Foundation
import XCTest

final class Site_PluginsURLTests: XCTestCase {
    private var adminURL: String!
    private var site: Site!

    override func setUp() {
        super.setUp()

        adminURL = "https://testshop.com/wp-admin/"
        site = Site.fake().copy(adminURL: adminURL)
    }

    override func tearDown() {
        adminURL = nil
        site = nil

        super.tearDown()
    }

    func test_pluginsURL_then_returns_right_URL() {
        let expectedURL = adminURL + "plugins.php"

        // Then
        XCTAssertEqual(site.pluginsURL, expectedURL)
    }

    func test_pluginSettingsSectionURL_when_plugin_is_WCPay_then_returns_right_URL() {
        let expectedURL = adminURL + "admin.php?page=wc-settings&tab=checkout&section=woocommerce_payments"

        // Then
        XCTAssertEqual(site.pluginSettingsSectionURL(from: .wcPay), expectedURL)
    }

    func test_pluginSettingsSectionURL_when_plugin_is_stripe_then_returns_right_URL() {
        let expectedURL = adminURL + "admin.php?page=wc-settings&tab=checkout&section=stripe"

        // Then
        XCTAssertEqual(site.pluginSettingsSectionURL(from: .stripe), expectedURL)
    }
}
