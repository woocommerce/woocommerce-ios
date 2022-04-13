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
}
