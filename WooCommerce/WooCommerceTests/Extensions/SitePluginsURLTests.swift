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

    func test_cardPresentPluginHasPendingTasksURL_when_plugin_is_wcpay_then_returns_correct_URL() {
        let expectedURL = adminURL + "admin.php?page=wc-admin&path=%2Fpayments%2Fconnect"

        // Then
        XCTAssertEqual(site.cardPresentPluginHasPendingTasksURL(plugin: .wcPay), expectedURL)
    }

    func test_cardPresentPluginHasPendingTasksURL_when_plugin_is_stripe_then_returns_correct_URL() {
        let expectedURL = adminURL + "admin.php?page=wc-settings&tab=checkout&section=stripe&panel=settings"

        // Then
        XCTAssertEqual(site.cardPresentPluginHasPendingTasksURL(plugin: .stripe), expectedURL)
    }
}
