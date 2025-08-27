
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

    @Test func connectedCardReader_initially_nil() async throws {
        // Given
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: [])

        // When
        let cardReader = sut.connectedCardReader

        // Then
        #expect(cardReader == nil)
    }

    @Test func updateCardReader_sets_connectedCardReader() async throws {
        // Given
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: [])
        let cardReader = CardPresentPaymentCardReader(name: "WisePad 3", batteryLevel: 0.85)

        // When
        sut.updateCardReader(cardReader)

        // Then
        #expect(sut.connectedCardReader?.name == "WisePad 3")
        #expect(sut.connectedCardReader?.batteryLevel == 0.85)
    }

    @Test func updateCardReader_with_nil_clears_connectedCardReader() async throws {
        // Given
        let sut = PointOfSaleSettingsController(settingsService: mockSettingsService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: [])
        let cardReader = CardPresentPaymentCardReader(name: "WisePad 3", batteryLevel: 0.85)
        sut.updateCardReader(cardReader)

        // When
        sut.updateCardReader(nil)

        // Then
        #expect(sut.connectedCardReader == nil)
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
    var receiptStoreName: String? = "Sample Store"
    var receiptStoreAddress: String? = "123 Main Street\nAnytown, ST 12345"
    var receiptStorePhone: String? = "+1 (555) 123-4567"
    var receiptStoreEmail: String? = "store@example.com"
    var receiptRefundReturnsPolicy: String? = "30-day return policy"
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

    func updateCardReader(_ cardReader: CardPresentPaymentCardReader?) {
        // no-op
    }
}
