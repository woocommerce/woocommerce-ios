import Testing
import Foundation
@testable import WooCommerce
@testable import Yosemite
import Storage

struct PointOfSaleSettingsControllerTests {
    private let mockSettingsService = MockPointOfSaleSettingsService()
    private let mockStorageManager = MockStorageManager()
    private let mockCardPresentPaymentService = MockCardPresentPaymentService()
    private let mockPluginService = MockPluginsService()

    @Test func storeName_when_defaultSiteName_provided_then_returns_defaultSiteName() async throws {
        // Given
        let expectedStoreName = "My Test Store"
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockCardPresentPaymentService,
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
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockCardPresentPaymentService,
                                                pluginsService: mockPluginService,
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
                                                cardPresentPaymentService: mockCardPresentPaymentService,
                                                pluginsService: mockPluginService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: siteSettings)

        // When
        let storeAddress = sut.storeAddress

        // Then: address should be constructed from site settings, not empty
        #expect(!storeAddress.isEmpty)
    }

    @Test func connectedCardReader_initially_nil() async throws {
        // Given
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockCardPresentPaymentService,
                                                pluginsService: mockPluginService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: [])

        // When
        let cardReader = sut.connectedCardReader

        // Then
        #expect(cardReader == nil)
    }

    @Test func cardReader_observation_updates_connectedCardReader() async throws {
        // Given
        let mockService = MockCardPresentPaymentService()
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockService,
                                                pluginsService: mockPluginService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: [])

        // Initially nil
        #expect(sut.connectedCardReader == nil)

        // When
        let cardReader = CardPresentPaymentCardReader(name: "WisePad 3", batteryLevel: 0.75)
        mockService.connectedReader = cardReader

        // Then
        #expect(sut.connectedCardReader?.name == "WisePad 3")
        #expect(sut.connectedCardReader?.batteryLevel == 0.75)
    }

    @Test func retrievePOSReceiptSettings_when_supported_plugin_version_then_shouldShowReceiptInformation() async throws {
        // Given
        mockPluginService.setMockPlugin(.wooCommerce,
                                        systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                               version: "10.0.0",
                                                                               active: true))
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockCardPresentPaymentService,
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
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockCardPresentPaymentService,
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
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockCardPresentPaymentService,
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
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockCardPresentPaymentService,
                                                pluginsService: mockPluginService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: [])

        // When
        await sut.retrievePOSReceiptSettings()

        // Then
        #expect(sut.shouldShowReceiptInformation == false)
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

final class MockPointOfSaleSettingsController: PointOfSaleSettingsControllerProtocol {
    var receiptInformation = POSReceiptInformation(
        storeName: "Sample Store",
        storeAddress: "123 Main Street\nAnytown, ST 12345",
        phone: "+1 (555) 123-4567",
        email: "store@example.com",
        refundReturnsPolicy: "30-day return policy"
    )
    var isLoading: Bool = false
    var shouldShowReceiptInformation: Bool = true
    var storeName: String = "Sample Store"

    var storeAddress: String {
        "123 Main Street\nAnytown, ST 12345"
    }

    var connectedCardReader: CardPresentPaymentCardReader? = nil

    func retrievePOSReceiptSettings() async {
        // no-op
    }
}
