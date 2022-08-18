import XCTest
import Yosemite
@testable import WooCommerce

class CardReaderManualsViewModelTests: XCTestCase {

    private var storageManager: MockStorageManager!
    private var stores: MockStoresManager!
    private let sampleSiteID: Int64 = 1234

    override func setUpWithError() throws {
        try super.setUpWithError()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.sessionManager.setStoreId(sampleSiteID)
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings(stores: stores, storageManager: storageManager))
    }

    override func tearDownWithError() throws {
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings())
        storageManager.reset()
        storageManager = nil
        stores = nil
        try super.tearDownWithError()
    }

    func test_viewModel_not_nil() {
        // Given
        let viewModel = CardReaderManualsViewModel()

        // Then
        XCTAssertNotNil(viewModel)
    }

    func test_viewModel_when_US_store_then_available_card_reader_manuals() {
        // Given
        let setting = SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                value: "US:CA",
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        ServiceLocator.selectedSiteSettings.refresh()
        let viewModel = CardReaderManualsViewModel()

        // When
        let availableReaderTypes = [CardReaderType.chipper, CardReaderType.stripeM2]
        let expectedManuals = availableReaderTypes.map { $0.manual }

        // Then
        XCTAssertEqual(viewModel.manuals, expectedManuals)
    }

    func test_viewModel_when_CA_store_then_available_card_reader_manuals() {
        // Given
        let setting = SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                value: "CA:NS",
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        ServiceLocator.selectedSiteSettings.refresh()
        let viewModel = CardReaderManualsViewModel()

        // When:
        let availableReaderTypes = [CardReaderType.wisepad3]
        let expectedManuals = availableReaderTypes.map { $0.manual }

        // Then
        XCTAssertEqual(viewModel.manuals, expectedManuals)
    }

    func test_viewModel_when_IPP_not_available_country_then_available_card_reader_manuals_is_empty() {
        // Given
        let setting = SiteSetting.fake()
                    .copy(
                        siteID: sampleSiteID,
                        settingID: "woocommerce_default_country",
                        value: "ES",
                        settingGroupKey: SiteSettingGroup.general.rawValue
                    )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        let viewModel = CardReaderManualsViewModel.init()

        // When
        let availableReaderTypes: [CardReaderType] = []
        let expectedManuals = availableReaderTypes.map { $0.manual }

        // Then
        XCTAssertEqual(viewModel.manuals, expectedManuals)
    }
}
