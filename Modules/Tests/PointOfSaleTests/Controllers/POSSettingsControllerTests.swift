import Testing
import Foundation
@testable import PointOfSale
@testable import Yosemite
import Storage

@MainActor
struct POSSettingsControllerTests {
    private let mockSettingsService = MockPointOfSaleSettingsService()
    private let mockCardPresentPaymentService = MockCardPresentPaymentService()
    private let mockPluginService = MockPluginsService()
    private let sampleSiteID: Int64 = 123

    @Test func connectedCardReader_initially_nil() async throws {
        // Given
        let sut = PointOfSaleSettingsController(siteID: sampleSiteID,
                                                settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockCardPresentPaymentService,
                                                pluginsService: mockPluginService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: [],
                                                grdbManager: nil,
                                                catalogSyncCoordinator: nil,
                                                isLocalCatalogEligible: true)

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
                                                siteSettings: [],
                                                grdbManager: nil,
                                                catalogSyncCoordinator: nil,
                                                isLocalCatalogEligible: true)

        // Initially nil
        #expect(sut.connectedCardReader == nil)

        // When
        let cardReader = CardPresentPaymentCardReader(name: "WisePad 3", batteryLevel: 0.75)
        mockService.connectedReader = cardReader

        // Then
        #expect(sut.connectedCardReader?.name == "WisePad 3")
        #expect(sut.connectedCardReader?.batteryLevel == 0.75)
    }

    @Test func cardReader_reconnecting_provides_reader_info() async throws {
        // Given
        let mockService = MockCardPresentPaymentService()
        let sut = PointOfSaleSettingsController(siteID: sampleSiteID,
                                                settingsService: mockSettingsService,
                                                cardPresentPaymentService: mockService,
                                                pluginsService: mockPluginService,
                                                defaultSiteName: "Test Store",
                                                siteSettings: [],
                                                grdbManager: nil,
                                                catalogSyncCoordinator: nil,
                                                isLocalCatalogEligible: true)

        // When
        let cardReader = CardPresentPaymentCardReader(name: "WisePad 3", batteryLevel: 0.75)
        mockService.connectionStatus = .reconnecting(cardReader)

        // Then
        #expect(sut.connectedCardReader?.name == "WisePad 3")
        #expect(sut.connectedCardReader?.batteryLevel == 0.75)
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
}

final class MockPOSSettingsController: POSSettingsControllerProtocol {
    var connectedCardReader: CardPresentPaymentCardReader? = nil
    var storeViewModel: POSSettingsStoreViewModel = POSSettingsStoreViewModel(siteID: 123,
                                                                              settingsService: MockPointOfSaleSettingsService(),
                                                                              pluginsService: MockPluginsService(),
                                                                              defaultSiteName: "Sample Store",
                                                                              siteSettings: [])
    var localCatalogViewModel: POSSettingsLocalCatalogViewModel?
    var isLocalCatalogEligible = true
}
