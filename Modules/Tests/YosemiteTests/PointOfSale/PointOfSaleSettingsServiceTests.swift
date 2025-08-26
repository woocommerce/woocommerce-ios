import Foundation
import Testing
@testable import Yosemite

struct PointOfSaleSettingsServiceTests {
    private let sut: PointOfSaleSettingsService
    private let settingStoreMethods: MockSettingStoreMethods
    private let storage: MockStorageManager
    private let sampleSiteID: Int64 = 123

    init() {
        self.settingStoreMethods = MockSettingStoreMethods()
        self.storage = MockStorageManager()
        self.sut = PointOfSaleSettingsService(siteID: sampleSiteID,
                                              settingStoreMethods: settingStoreMethods)
    }

    @Test func retrievePointOfSaleSettings_when_successful_then_returns_expected_settings() async throws {
        // Given
        let expectedSettings = makeSiteSettings()
        settingStoreMethods.retrievePointOfSaleSettingsResult = .success(expectedSettings)

        // When
        let settings = try await sut.retrievePointOfSaleSettings()

        // Then
        #expect(settingStoreMethods.retrievePointOfSaleSettingsCalled)
        #expect(settingStoreMethods.retrievePointOfSaleSettingsSiteID == sampleSiteID)
        #expect(settings == expectedSettings)
    }

    @Test func retrievePointOfSaleSettings_when_empty_settings_then_returns_empty_array() async throws {
        // Given
        settingStoreMethods.retrievePointOfSaleSettingsResult = .success([])

        // When
        let settings = try await sut.retrievePointOfSaleSettings()

        // Then
        #expect(settingStoreMethods.retrievePointOfSaleSettingsCalled)
        #expect(settingStoreMethods.retrievePointOfSaleSettingsSiteID == sampleSiteID)
        #expect(settings.isEmpty)
    }

    @Test func retrievePointOfSaleSettings_when_network_error_then_throws_error() async throws {
        // Given
        let expectedError = NSError(domain: "NetworkError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network request failed"])
        settingStoreMethods.retrievePointOfSaleSettingsResult = .failure(expectedError)

        // When
        do {
            _ = try await sut.retrievePointOfSaleSettings()
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            // Then
            #expect(settingStoreMethods.retrievePointOfSaleSettingsCalled)
            #expect(settingStoreMethods.retrievePointOfSaleSettingsSiteID == sampleSiteID)
            let nsError = error as NSError
            #expect(nsError.domain == expectedError.domain)
            #expect(nsError.code == expectedError.code)
        }
    }

    @Test func retrievePointOfSaleSettings_when_settingStoreMethods_throws_then_propagates_error() async throws {
        // Given
        let expectedError = TestError.customError
        settingStoreMethods.retrievePointOfSaleSettingsResult = .failure(expectedError)

        // When
        do {
            _ = try await sut.retrievePointOfSaleSettings()
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            // Then
            #expect(settingStoreMethods.retrievePointOfSaleSettingsCalled)
            #expect(settingStoreMethods.retrievePointOfSaleSettingsSiteID == sampleSiteID)
            #expect(error as? TestError == expectedError)
        }
    }

    @Test func retrievePointOfSaleSettings_passes_correct_siteID_to_settingStoreMethods() async throws {
        // Given
        let differentSiteID: Int64 = 456
        let customSUT = PointOfSaleSettingsService(siteID: differentSiteID,
                                                   settingStoreMethods: settingStoreMethods)
        settingStoreMethods.retrievePointOfSaleSettingsResult = .success([])

        // When
        _ = try await customSUT.retrievePointOfSaleSettings()

        // Then
        #expect(settingStoreMethods.retrievePointOfSaleSettingsCalled)
        #expect(settingStoreMethods.retrievePointOfSaleSettingsSiteID == differentSiteID)
    }

    @Test func retrievePointOfSaleSettings_with_complete_pos_settings_then_returns_all_settings() async throws {
        // Given
        let completeSettings = makeSiteSettings()
        settingStoreMethods.retrievePointOfSaleSettingsResult = .success(completeSettings)

        // When
        let settings = try await sut.retrievePointOfSaleSettings()

        // Then
        #expect(settingStoreMethods.retrievePointOfSaleSettingsCalled)
        #expect(settings.count == 5)
        #expect(settings == completeSettings)

        // Verify specific settings
        let storeNameSetting = settings.first { $0.settingID == "woocommerce_pos_store_name" }
        #expect(storeNameSetting?.value == "WooCommerce Store")

        let addressSetting = settings.first { $0.settingID == "woocommerce_pos_store_address" }
        #expect(addressSetting?.value == "123 Commerce Street\nBusiness District")

        let phoneSetting = settings.first { $0.settingID == "woocommerce_pos_store_phone" }
        #expect(phoneSetting?.value == "+1 (555) 123-4567")

        let emailSetting = settings.first { $0.settingID == "woocommerce_pos_store_email" }
        #expect(emailSetting?.value == "contact@store.com")

        let policySetting = settings.first { $0.settingID == "woocommerce_pos_refund_returns_policy" }
        #expect(policySetting?.value == "30-day return policy with receipt")
    }

    private func makeSiteSettings() -> [SiteSetting] {
        return [
            SiteSetting(siteID: sampleSiteID,
                        settingID: "woocommerce_pos_store_name",
                        label: "Store Name",
                        settingDescription: "Name of the store for POS receipts",
                        value: "WooCommerce Store",
                        settingGroupKey: "pos"),
            SiteSetting(siteID: sampleSiteID,
                        settingID: "woocommerce_pos_store_address",
                        label: "Store Address",
                        settingDescription: "Physical address for receipts",
                        value: "123 Commerce Street\nBusiness District",
                        settingGroupKey: "pos"),
            SiteSetting(siteID: sampleSiteID,
                        settingID: "woocommerce_pos_store_phone",
                        label: "Store Phone",
                        settingDescription: "Contact phone number",
                        value: "+1 (555) 123-4567",
                        settingGroupKey: "pos"),
            SiteSetting(siteID: sampleSiteID,
                        settingID: "woocommerce_pos_store_email",
                        label: "Store Email",
                        settingDescription: "Contact email address",
                        value: "contact@store.com",
                        settingGroupKey: "pos"),
            SiteSetting(siteID: sampleSiteID,
                        settingID: "woocommerce_pos_refund_returns_policy",
                        label: "Refund & Returns Policy",
                        settingDescription: "Store policy for refunds and returns",
                        value: "30-day return policy with receipt",
                        settingGroupKey: "pos")
        ]
    }
}

private enum TestError: Error, Equatable {
    case customError
}
