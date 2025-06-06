import XCTest
@testable import Networking

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
    func test_loadGeneralSettings_properly_returns_parsed_settings() async throws {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "settings/general", filename: "settings-general")

        // When
        let settings = try await remote.loadGeneralSettings(for: sampleSiteID)

        // Then
        XCTAssertEqual(settings.count, 2)
        XCTAssertEqual(settings[0].settingID, "woocommerce_store_address")
        XCTAssertEqual(settings[0].value, "60 29th Street #343")
    }

    /// Verifies that loadGeneralSettings properly relays Networking Layer errors.
    ///
    func test_loadGeneralSettings_properly_relays_networking_errors() async {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateError(requestUrlSuffix: "settings/general", error: NetworkError.timeout())

        // When
        do {
            _ = try await remote.loadGeneralSettings(for: sampleSiteID)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Load product settings tests

    /// Verifies that `loadProductSettings` properly parses the sample response.
    ///
    func test_loadProductSettings_properly_returns_parsed_settings() async throws {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "settings/products", filename: "settings-products")

        // When
        let settings = try await remote.loadProductSettings(for: sampleSiteID)

        // Then
        XCTAssertEqual(settings.count, 2)
        XCTAssertEqual(settings[0].settingID, "woocommerce_weight_unit")
        XCTAssertEqual(settings[0].value, "kg")
    }

    /// Verifies that `loadProductSettings` properly relays Networking Layer errors.
    ///
    func test_loadProductSettings_properly_relays_networking_errors() async {
        // Given
        let remote = SiteSettingsRemote(network: network)
        network.simulateError(requestUrlSuffix: "settings/products", error: NetworkError.timeout())

        // When
        do {
            _ = try await remote.loadProductSettings(for: sampleSiteID)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertTrue(error is NetworkError)
        }
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
}
