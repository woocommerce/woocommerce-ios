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
    private let sampleSiteID: Int64 = 123

    @Test func storeName_when_defaultSiteName_provided_then_returns_defaultSiteName() async throws {
        // Given
        let expectedStoreName = "My Test Store"
        let sut = PointOfSaleSettingsController(siteID: sampleSiteID,
                                                settingsService: mockSettingsService,
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
        let sut = PointOfSaleSettingsController(siteID: sampleSiteID,
                                                settingsService: mockSettingsService,
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
        let sut = PointOfSaleSettingsController(siteID: sampleSiteID,
                                                settingsService: mockSettingsService,
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
        let sut = PointOfSaleSettingsController(siteID: sampleSiteID,
                                                settingsService: mockSettingsService,
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
        let sut = PointOfSaleSettingsController(siteID: sampleSiteID,
                                                settingsService: mockSettingsService,
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

final class MockPointOfSaleSettingsController: PointOfSaleSettingsControllerProtocol {
    var storeName: String = "Sample Store"
    var storeAddress: String {
        "123 Main Street\nAnytown, ST 12345"
    }
    var connectedCardReader: CardPresentPaymentCardReader? = nil
    var storeViewModel: POSSettingsStoreViewModel = POSSettingsStoreViewModel(siteID: 123,
                                                                              settingsService: MockPointOfSaleSettingsService(),
                                                                              pluginsService: MockPluginsService(),
                                                                              defaultSiteName: "Sample Store",
                                                                              siteSettings: [])
}
