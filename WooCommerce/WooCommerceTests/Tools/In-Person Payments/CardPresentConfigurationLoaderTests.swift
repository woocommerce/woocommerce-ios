import XCTest
import Yosemite
@testable import WooCommerce

final class CardPresentConfigurationLoaderTests: XCTestCase {
    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Stores
    ///
    private var stores: MockStoresManager!

    /// Dummy Site ID
    ///
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

    func test_configuration_for_US() {
        // Given
        setupCountry(country: .us)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores)
        let configuration = loader.configuration

        // Then
        XCTAssertTrue(configuration.isSupportedCountry)
    }

    func test_configuration_for_Canada() {
        // Given
        setupCountry(country: .ca)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores)
        let configuration = loader.configuration

        // Then
        XCTAssertTrue(configuration.isSupportedCountry)
    }

    func test_configuration_for_Spain() {
        // Given
        setupCountry(country: .es)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores)
        let configuration = loader.configuration

        // Then
        XCTAssertFalse(configuration.isSupportedCountry)
    }

    func test_configuration_for_UK() {
        // Given
        setupCountry(country: .gb)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores)
        let configuration = loader.configuration

        // Then
        XCTAssertTrue(configuration.isSupportedCountry)
    }
}

private extension CardPresentConfigurationLoaderTests {
    func setupCountry(country: Country) {
        let setting = SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                value: country.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        ServiceLocator.selectedSiteSettings.refresh()
    }

    enum Country: String {
        case us = "US:CA"
        case ca = "CA:NS"
        case es = "ES"
        case gb = "GB"
    }
}
