import Testing
import Foundation
@testable import PointOfSale
@testable import Yosemite
import Storage

struct POSSettingsStoreViewModelTests {
    private let mockSettingsService = MockPointOfSaleSettingsService()
    private let mockPluginService = MockPluginsService()
    private let sampleSiteID: Int64 = 123

    @Test func retrievePOSReceiptSettings_when_supported_plugin_version_then_shouldShowReceiptInformation() async throws {
        // Given
        mockPluginService.setMockPlugin(.wooCommerce,
                                        systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                               version: "10.0.0",
                                                                               active: true))
        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: "Test Store",
                                            siteSettings: [])

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
        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: "Test Store",
                                            siteSettings: [])

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
        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: "Test Store",
                                            siteSettings: [])

        // When
        await sut.retrievePOSReceiptSettings()

        // Then
        #expect(sut.shouldShowReceiptInformation == false)
    }

    @Test func retrievePOSReceiptSettings_when_no_plugin_then_shouldShowReceiptInformation_returns_false() async throws {
        // Given
        mockPluginService.setMockPlugin(.wooCommerce, systemPlugin: nil)
        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: "Test Store",
                                            siteSettings: [])

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
        let expectedReceiptInfo = POSReceiptInformation(
            storeName: "Test Store",
            storeAddress: nil,
            phone: "+1234567890",
            email: nil,
            refundReturnsPolicy: nil
        )
        mockSettingsService.retrievePointOfSaleSettingsResult = .success(expectedReceiptInfo)

        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: "Test Store",
                                            siteSettings: [])

        // When
        await sut.retrievePOSReceiptSettings()

        // Then
        #expect(sut.shouldShowReceiptInformation == true)
        #expect(sut.receiptInformation.storeName == "Test Store")
        #expect(sut.receiptInformation.phone == "+1234567890")
        #expect(sut.receiptInformation.storeAddress == nil) // Not provided in mock data
    }

    @Test func storeName_when_defaultSiteName_provided_then_returns_defaultSiteName() async throws {
        // Given
        let expectedStoreName = "My Test Store"
        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: expectedStoreName,
                                            siteSettings: [])

        // When
        let actualStoreName = sut.storeName

        // Then
        #expect(actualStoreName == expectedStoreName)
    }

    @Test func storeName_when_defaultSiteName_nil_then_returns_notSet() async throws {
        // Given
        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: nil,
                                            siteSettings: [])

        // When
        let actualStoreName = sut.storeName

        // Then
        #expect(actualStoreName == "Not set")
    }

    @Test func storeAddress_when_single_address_line_then_returns_address() async throws {
        // Given
        let siteSettings = makeSampleSiteSettingsWithSingleAddress()
        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: "Test Store",
                                            siteSettings: siteSettings)

        // When
        let storeAddress = sut.storeAddress

        // Then
        #expect(storeAddress == "123 Test Street")
    }

    @Test func storeAddress_when_two_address_lines_then_returns_combined_address() async throws {
        // Given
        let siteSettings = makeSampleSiteSettingsWithTwoAddressLines()
        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: "Test Store",
                                            siteSettings: siteSettings)

        // When
        let storeAddress = sut.storeAddress

        // Then
        #expect(storeAddress == "123 Test Street\nSuite 100")
    }

    @Test func storeAddress_when_empty_address2_then_returns_only_address1() async throws {
        // Given
        let siteSettings = makeSampleSiteSettingsWithEmptyAddress2()
        let sut = POSSettingsStoreViewModel(siteID: sampleSiteID,
                                            settingsService: mockSettingsService,
                                            pluginsService: mockPluginService,
                                            defaultSiteName: "Test Store",
                                            siteSettings: siteSettings)

        // When
        let storeAddress = sut.storeAddress

        // Then
        #expect(storeAddress == "456 Main Road")
    }

    private func makeSampleSiteSettingsWithSingleAddress() -> [Yosemite.SiteSetting] {
        return [
            SiteSetting(siteID: 123,
                        settingID: "woocommerce_store_address",
                        label: "Address",
                        settingDescription: "",
                        value: "123 Test Street",
                        settingGroupKey: "general"),
            SiteSetting(siteID: 123,
                        settingID: "woocommerce_store_address_2",
                        label: "Address Line 2",
                        settingDescription: "",
                        value: "",
                        settingGroupKey: "general")
        ]
    }

    private func makeSampleSiteSettingsWithTwoAddressLines() -> [Yosemite.SiteSetting] {
        return [
            SiteSetting(siteID: 123,
                        settingID: "woocommerce_store_address",
                        label: "Address",
                        settingDescription: "",
                        value: "123 Test Street",
                        settingGroupKey: "general"),
            SiteSetting(siteID: 123,
                        settingID: "woocommerce_store_address_2",
                        label: "Address Line 2",
                        settingDescription: "",
                        value: "Suite 100",
                        settingGroupKey: "general")
        ]
    }

    private func makeSampleSiteSettingsWithEmptyAddress2() -> [Yosemite.SiteSetting] {
        return [
            SiteSetting(siteID: 123,
                        settingID: "woocommerce_store_address",
                        label: "Address",
                        settingDescription: "",
                        value: "456 Main Road",
                        settingGroupKey: "general"),
            SiteSetting(siteID: 123,
                        settingID: "woocommerce_store_address_2",
                        label: "Address Line 2",
                        settingDescription: "",
                        value: "",
                        settingGroupKey: "general")
        ]
    }
}

private final class MockPointOfSaleSettingsService: PointOfSaleSettingsServiceProtocol {
    let siteID: Int64 = 123
    var retrievePointOfSaleSettingsWasCalled = false
    var retrievePointOfSaleSettingsResult: Result<POSReceiptInformation, Error> = .success(.empty)

    func retrievePointOfSaleSettings() async throws -> POSReceiptInformation {
        retrievePointOfSaleSettingsWasCalled = true
        switch retrievePointOfSaleSettingsResult {
        case .success(let receiptInfo):
            return receiptInfo
        case .failure(let error):
            throw error
        }
    }

    var updatePointOfSaleSettingsWasCalled = false
    var updatePointOfSaleSettingsChanges: [POSReceiptField: String]?
    var updatePointOfSaleSettingsResult: Result<POSReceiptInformation, Error> = .success(.empty)

    func updatePointOfSaleSettings(_ changes: [POSReceiptField: String]) async throws -> POSReceiptInformation {
        updatePointOfSaleSettingsWasCalled = true
        updatePointOfSaleSettingsChanges = changes
        switch updatePointOfSaleSettingsResult {
        case .success(let receiptInfo):
            return receiptInfo
        case .failure(let error):
            throw error
        }
    }
}
