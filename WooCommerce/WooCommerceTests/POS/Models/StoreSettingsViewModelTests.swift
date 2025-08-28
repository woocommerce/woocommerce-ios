import Testing
import Foundation
@testable import WooCommerce
@testable import Yosemite
import Storage

struct StoreSettingsViewModelTests {
    private let mockSettingsService = MockPointOfSaleSettingsService()
    private let mockPluginService = MockPluginsService()
    private let sampleSiteID: Int64 = 123

    @Test func retrievePOSReceiptSettings_when_supported_plugin_version_then_shouldShowReceiptInformation() async throws {
        // Given
        mockPluginService.setMockPlugin(.wooCommerce,
                                        systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                               version: "10.0.0",
                                                                               active: true))
        let sut = StoreSettingsViewModel(siteID: sampleSiteID,
                                         settingsService: mockSettingsService,
                                         pluginsService: mockPluginService)

        // When
        await sut.retrievePOSReceiptSettings()

        // Then
        #expect(sut.shouldShowReceiptInformation == true)
    }

    @Test func retrievePOSReceiptSettings_when_unsupported_plugin_version_then_shouldShowReceiptInformation_returns_false() async throws {
        // Given
        mockPluginService.setMockPlugin(.wooCommerce,
                                        systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                               version: "9.9.0",
                                                                               active: true))
        let sut = StoreSettingsViewModel(siteID: sampleSiteID,
                                         settingsService: mockSettingsService,
                                         pluginsService: mockPluginService)

        // When
        await sut.retrievePOSReceiptSettings()

        // Then
        #expect(sut.shouldShowReceiptInformation == false)
    }

    @Test func retrievePOSReceiptSettings_when_inactive_plugin_then_shouldShowReceiptInformation_returns_false() async throws {
        // Given
        mockPluginService.setMockPlugin(.wooCommerce,
                                        systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                               version: "10.0.0",
                                                                               active: false))
        let sut = StoreSettingsViewModel(siteID: sampleSiteID,
                                         settingsService: mockSettingsService,
                                         pluginsService: mockPluginService)

        // When
        await sut.retrievePOSReceiptSettings()

        // Then
        #expect(sut.shouldShowReceiptInformation == false)
    }

    @Test func retrievePOSReceiptSettings_when_no_plugin_then_shouldShowReceiptInformation_returns_false() async throws {
        // Given
        mockPluginService.setMockPlugin(.wooCommerce, systemPlugin: nil)
        let sut = StoreSettingsViewModel(siteID: sampleSiteID,
                                         settingsService: mockSettingsService,
                                         pluginsService: mockPluginService)

        // When
        await sut.retrievePOSReceiptSettings()

        // Then
        #expect(sut.shouldShowReceiptInformation == false)
    }

    @Test func retrievePOSReceiptSettings_when_successful_then_updates_receiptInformation() async throws {
        // Given
        mockPluginService.setMockPlugin(.wooCommerce,
                                        systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                               version: "10.0.0",
                                                                               active: true))
        let expectedSettings = [
            SiteSetting(siteID: sampleSiteID,
                       settingID: "woocommerce_pos_store_name",
                       label: "Store Name",
                       settingDescription: "",
                       value: "Test Store",
                       settingGroupKey: "pos"),
            SiteSetting(siteID: sampleSiteID,
                       settingID: "woocommerce_pos_store_phone",
                       label: "Phone",
                       settingDescription: "",
                       value: "+1234567890",
                       settingGroupKey: "pos")
        ]
        mockSettingsService.retrievePointOfSaleSettingsResult = .success(expectedSettings)

        let sut = StoreSettingsViewModel(siteID: sampleSiteID,
                                         settingsService: mockSettingsService,
                                         pluginsService: mockPluginService)

        // When
        await sut.retrievePOSReceiptSettings()

        // Then
        #expect(sut.shouldShowReceiptInformation == true)
        #expect(sut.receiptInformation.storeName == "Test Store")
        #expect(sut.receiptInformation.phone == "+1234567890")
        #expect(sut.receiptInformation.storeAddress == nil) // Not provided in mock data
    }
}

private final class MockPointOfSaleSettingsService: PointOfSaleSettingsServiceProtocol {
    let siteID: Int64 = 123
    var retrievePointOfSaleSettingsWasCalled = false
    var retrievePointOfSaleSettingsResult: Result<[Yosemite.SiteSetting], Error> = .success([])

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
