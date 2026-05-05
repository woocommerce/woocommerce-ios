import XCTest
@testable import Networking
@testable import NetworkingCore

/// SiteSettingsRemote Unit Tests
///
final class SiteSettingsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load general settings tests

    /// Verifies that loadGeneralSettings properly parses the sample response.
    ///
    func testLoadGeneralSettingsProperlyReturnsParsedSettings() {
        let remote = SiteSettingsRemote(network: network)
        let expectation = self.expectation(description: "Load site settings")

        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "settings-general")
        remote.loadGeneralSettings(for: sampleSiteID) { (siteSettings, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(siteSettings)
            XCTAssertEqual(siteSettings?.count, 20)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadGeneralSettings properly relays Networking Layer errors.
    ///
    func testLoadGeneralSettingsProperlyRelaysNetwokingErrors() {
        let remote = SiteSettingsRemote(network: network)
        let expectation = self.expectation(description: "Load site settings contains errors")

        remote.loadGeneralSettings(for: sampleSiteID) { (siteSettings, error) in
            XCTAssertNil(siteSettings)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - Load product settings tests

    /// Verifies that `loadProductSettings` properly parses the sample response.
    ///
    func testLoadProductSettingsProperlyReturnsParsedSettings() {
        let remote = SiteSettingsRemote(network: network)
        let expectation = self.expectation(description: "Load product settings")

        network.simulateResponse(requestUrlSuffix: "settings/products", filename: "settings-product")
        remote.loadProductSettings(for: sampleSiteID) { (siteSettings, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(siteSettings)
            XCTAssertEqual(siteSettings?.count, 23)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadProductSettings` properly relays Networking Layer errors.
    ///
    func testLoadProductSettingsProperlyRelaysNetwokingErrors() {
        let remote = SiteSettingsRemote(network: network)
        let expectation = self.expectation(description: "Load product settings contains errors")

        remote.loadProductSettings(for: sampleSiteID) { (siteSettings, error) in
            XCTAssertNil(siteSettings)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - Load single setting tests
    func test_loadSetting_properly_returns_parsed_settings() throws {
        // Given
        let couponSettingID = "woocommerce_enable_coupons"
        network.simulateResponse(requestUrlSuffix: "settings/general/\(couponSettingID)", filename: "setting-coupon")
        let remote = SiteSettingsRemote(network: network)

        // When
        let result: Result<Networking.SiteSetting, Error> = waitFor { promise in
            remote.loadSetting(for: self.sampleSiteID, settingGroup: .general, settingID: couponSettingID) { result in
                promise(result)
            }
        }

        // Then
        let setting = try result.get()
        XCTAssertEqual(setting.settingGroupKey, "general")
        XCTAssertEqual(setting.settingID, "woocommerce_enable_coupons")
        XCTAssertEqual(setting.value, "yes")
    }

    func test_loadCouponSetting_properly_relays_netwoking_errors() throws {
        // Given
        let couponSettingID = "woocommerce_enable_coupons"
        let remote = SiteSettingsRemote(network: network)
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "settings/general/\(couponSettingID)", error: error)

        // When
        let result: Result<Networking.SiteSetting, Error> = waitFor { promise in
            remote.loadSetting(for: self.sampleSiteID, settingGroup: .general, settingID: couponSettingID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }

    // MARK: - Update coupon setting tests
    func test_updateCouponSetting_properly_returns_parsed_settings() throws {
        // Given
        let couponSettingID = "woocommerce_enable_coupons"
        network.simulateResponse(requestUrlSuffix: "settings/general/\(couponSettingID)", filename: "setting-coupon")
        let remote = SiteSettingsRemote(network: network)

        // When
        let result: Result<Networking.SiteSetting, Error> = waitFor { promise in
            remote.updateSetting(for: self.sampleSiteID, settingGroup: .general, settingID: couponSettingID, value: "yes") { result in
                promise(result)
            }
        }

        // Then
        let setting = try result.get()
        XCTAssertEqual(setting.settingGroupKey, "general")
        XCTAssertEqual(setting.settingID, "woocommerce_enable_coupons")
        XCTAssertEqual(setting.value, "yes")
    }

    func test_updateCouponSetting_properly_relays_netwoking_errors() throws {
        // Given
        let couponSettingID = "woocommerce_enable_coupons"
        let remote = SiteSettingsRemote(network: network)
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "settings/general/\(couponSettingID)", error: error)

        // When
        let result: Result<Networking.SiteSetting, Error> = waitFor { promise in
            remote.updateSetting(for: self.sampleSiteID, settingGroup: .general, settingID: couponSettingID, value: "yes") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }

    // MARK: - `isFeatureEnabled`

    func test_isFeatureEnabled_returns_true_when_feature_is_enabled() async throws {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "settings/advanced/woocommerce_feature_point_of_sale_enabled",
                                 filename: "settings-advanced-feature-pos-enabled")

        // When
        let isEnabled = try await remote.isFeatureEnabled(for: sampleSiteID, feature: .pointOfSale)

        // Then
        XCTAssertTrue(isEnabled)
    }

    func test_isFeatureEnabled_returns_false_when_feature_is_disabled() async throws {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "settings/advanced/woocommerce_feature_point_of_sale_enabled",
                                 filename: "settings-advanced-feature-pos-disabled")

        // When
        let isEnabled = try await remote.isFeatureEnabled(for: sampleSiteID, feature: .pointOfSale)

        // Then
        XCTAssertFalse(isEnabled)
    }

    func test_isFeatureEnabled_throws_error_when_response_is_invalid() async {
        // Given
        let remote = SiteSettingsRemote(network: network)
                network.simulateResponse(requestUrlSuffix: "settings/advanced/woocommerce_feature_point_of_sale_enabled",
                                         filename: "settings-advanced-feature-pos-invalid")

        // When/Then
        do {
            _ = try await remote.isFeatureEnabled(for: sampleSiteID, feature: .pointOfSale)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? SiteSettingsRemoteError, .invalidResponse)
        }
    }

    func test_isFeatureEnabled_throws_error_when_network_fails() async {
        // Given
        let remote = SiteSettingsRemote(network: network)
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "settings/advanced/woocommerce_feature_point_of_sale_enabled",
                              error: error)

        // When/Then
        do {
            _ = try await remote.isFeatureEnabled(for: sampleSiteID, feature: .pointOfSale)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .unacceptableStatusCode(statusCode: 500))
        }
    }

    // MARK: - `setFeature`

    func test_setFeature_enables_feature_when_enabled_is_true() async throws {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "settings/advanced/woocommerce_feature_point_of_sale_enabled",
                                 filename: "settings-advanced-feature-pos-enabled")

        // When
        let isEnabled = try await remote.setFeature(for: sampleSiteID, feature: .pointOfSale, enabled: true)

        // Then
        XCTAssertTrue(isEnabled)
    }

    func test_setFeature_disables_feature_when_enabled_is_false() async throws {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "settings/advanced/woocommerce_feature_point_of_sale_enabled",
                                 filename: "settings-advanced-feature-pos-disabled")

        // When
        let isEnabled = try await remote.setFeature(for: sampleSiteID, feature: .pointOfSale, enabled: false)

        // Then
        XCTAssertFalse(isEnabled)
    }

    func test_setFeature_throws_error_when_network_fails() async {
        // Given
        let remote = SiteSettingsRemote(network: network)
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "settings/advanced/woocommerce_feature_point_of_sale_enabled",
                              error: error)

        // When/Then
        do {
            _ = try await remote.setFeature(for: sampleSiteID, feature: .pointOfSale, enabled: true)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .unacceptableStatusCode(statusCode: 500))
        }
    }

    // MARK: - `loadAnalyticsOrderDateType`

    func test_loadAnalyticsOrderDateType_returns_parsed_setting() async throws {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "settings/wc_admin/woocommerce_date_type",
                                 filename: "setting-analytics-date-type-paid")

        // When
        let setting = try await remote.loadAnalyticsOrderDateType(for: sampleSiteID)

        // Then
        XCTAssertEqual(setting.settingID, "woocommerce_date_type")
        XCTAssertEqual(setting.value, "date_paid")
        XCTAssertEqual(setting.settingGroupKey, "wc_admin")
    }

    func test_loadAnalyticsOrderDateType_throws_error_when_network_fails() async {
        // Given
        let remote = SiteSettingsRemote(network: network)
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "settings/wc_admin/woocommerce_date_type",
                              error: error)

        // When/Then
        do {
            _ = try await remote.loadAnalyticsOrderDateType(for: sampleSiteID)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .unacceptableStatusCode(statusCode: 500))
        }
    }

    // MARK: - `updateAnalyticsOrderDateType`

    func test_updateAnalyticsOrderDateType_returns_parsed_setting() async throws {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "settings/wc_admin/woocommerce_date_type",
                                 filename: "setting-analytics-date-type-completed")

        // When
        let setting = try await remote.updateAnalyticsOrderDateType(for: sampleSiteID, value: "date_completed")

        // Then
        XCTAssertEqual(setting.settingID, "woocommerce_date_type")
        XCTAssertEqual(setting.value, "date_completed")
        XCTAssertEqual(setting.settingGroupKey, "wc_admin")
    }

    func test_updateAnalyticsOrderDateType_throws_error_when_network_fails() async {
        // Given
        let remote = SiteSettingsRemote(network: network)
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "settings/wc_admin/woocommerce_date_type",
                              error: error)

        // When/Then
        do {
            _ = try await remote.updateAnalyticsOrderDateType(for: sampleSiteID, value: "date_paid")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .unacceptableStatusCode(statusCode: 500))
        }
    }
}
