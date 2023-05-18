import XCTest
import Yosemite
import Hardware

@testable import WooCommerce

final class TapToPayReconnectionControllerTests: XCTestCase {

    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var connectionControllerFactory: MockBuiltInCardReaderConnectionControllerFactory!
    private var sut: TapToPayReconnectionController!
    private let sampleSiteID: Int64 = 12891
    private let sampleConfiguration: CardPresentPaymentsConfiguration = CardPresentPaymentsConfiguration(country: "US")

    override func setUp() {
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.setStoreId(sampleSiteID)
        stores = MockStoresManager(sessionManager: sessionManager)
        connectionControllerFactory = MockBuiltInCardReaderConnectionControllerFactory()
        sut = TapToPayReconnectionController(stores: stores,
                                             connectionControllerFactory: connectionControllerFactory)
        storageManager = MockStorageManager()
        setSiteAddressCountry()
    }

    func setSiteAddressCountry() {
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings(stores: stores, storageManager: storageManager))
        let setting = SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                value: "US:NY",
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        ServiceLocator.selectedSiteSettings.refresh()
    }

    override func tearDown() {
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings())
    }

    func test_reconnectIfNeeded_calls_searchAndConnect_if_no_reader_connected_and_site_and_device_meet_requirements() throws {
        // Given
        let supportDeterminer = MockCardReaderSupportDeterminer()
        supportDeterminer.shouldReturnConnectedReader = nil
        supportDeterminer.shouldReturnSiteSupportsLocalMobileReader = true
        supportDeterminer.shouldReturnDeviceSupportsLocalMobileReader = true
        supportDeterminer.shouldReturnHasPreviousTapToPayUsage = true

        waitFor { promise in
            self.connectionControllerFactory.onSearchAndConnectCalled = {
                promise(())
            }
            // When
            self.sut.reconnectIfNeeded(supportDeterminer: supportDeterminer)
        }

        // Then
        let mockConnectionController = try XCTUnwrap(connectionControllerFactory.mockConnectionController)
        XCTAssert(mockConnectionController.didCallSearchAndConnect)
    }

    func test_reconnectIfNeeded_creates_a_new_connection_controller_with_expected_parameters() throws {
        // Given
        let supportDeterminer = MockCardReaderSupportDeterminer()
        supportDeterminer.shouldReturnConnectedReader = nil
        supportDeterminer.shouldReturnSiteSupportsLocalMobileReader = true
        supportDeterminer.shouldReturnDeviceSupportsLocalMobileReader = true
        supportDeterminer.shouldReturnHasPreviousTapToPayUsage = true

        waitFor { promise in
            self.connectionControllerFactory.onSearchAndConnectCalled = {
                promise(())
            }
            // When
            self.sut.reconnectIfNeeded(supportDeterminer: supportDeterminer)
        }

        // Then
        assertEqual(sampleSiteID, connectionControllerFactory.spyCreateConnectionControllerSiteID)
        assertEqual(false, connectionControllerFactory.spyCreateConnectionControllerAllowTermsOfServiceAcceptance)
        assertEqual(sampleConfiguration, connectionControllerFactory.spyCreateConnectionControllerConfiguration)
    }

}
