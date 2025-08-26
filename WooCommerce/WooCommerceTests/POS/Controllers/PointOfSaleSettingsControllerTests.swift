
import Testing
import Foundation
@testable import WooCommerce
@testable import Yosemite
import Storage

// TODO: Expand controller tests in WOOMOB-1176
struct PointOfSaleSettingsControllerTests {
    private let mockSettingsService = MockPointOfSaleSettingsService()
    private let mockStorageManager = MockStorageManager()

    @Test func storeName_when_defaultSiteName_provided_then_returns_defaultSiteName() async throws {
        // Given
        let expectedStoreName = "My Test Store"
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                defaultSiteName: expectedStoreName,
                                                siteSettings: [])

        // When
        let actualStoreName = sut.storeName

        // Then
        #expect(actualStoreName == expectedStoreName)
    }

    @Test func storeName_when_defaultSiteName_nil_then_returns_notSet() async throws {
        // Given
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                defaultSiteName: nil,
                                                siteSettings: [])

        // When
        let actualStoreName = sut.storeName

        // Then
        #expect(actualStoreName == "Not set")
    }

    @Test func storeAddress_uses_injected_siteSettings() async throws {
        // Given
        let siteSettings = makeSampleSiteSettings()
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: siteSettings)

        // When
        let storeAddress = sut.storeAddress

        // Then: address should be constructed from site settings, not empty
        #expect(!storeAddress.isEmpty)
    }

    private func makeSampleSiteSettings() -> [Yosemite.SiteSetting] {
        return [
            SiteSetting(siteID: 123,
                        settingID: "woocommerce_store_address",
                        label: "Address",
                        settingDescription: "",
                        value: "123 Test Street",
                        settingGroupKey: "general"),
            SiteSetting(siteID: 123,
                        settingID: "woocommerce_store_city",
                        label: "City",
                        settingDescription: "",
                        value: "Test City",
                        settingGroupKey: "general"),
            SiteSetting(siteID: 123,
                        settingID: "woocommerce_default_country",
                        label: "Country",
                        settingDescription: "",
                        value: "US:CA",
                        settingGroupKey: "general")
        ]
    }
}

private final class MockPointOfSaleSettingsService: PointOfSaleSettingsServiceProtocol {
    var retrievePointOfSaleSettingsWasCalled = false
    var retrievePointOfSaleSettingsResult: Result<[Yosemite.SiteSetting], Error> = .success([])
    let siteID: Int64 = 123

    func retrievePointOfSaleSettings() async throws -> [Yosemite.SiteSetting] {
        retrievePointOfSaleSettingsWasCalled = true
        switch retrievePointOfSaleSettingsResult {
        case .success(let settings):
            return settings
        case .failure(let error):
            throw error
        }
    }
}
