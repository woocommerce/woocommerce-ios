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
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadCanadaInPersonPaymentsSwitchState(let completion):
                completion(.success(true))
            default:
                break
            }
        }
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

    func test_configuration_for_US_with_stripe_enabled_and_canada_enabled() {
        // Given
        setupFeatures(stripe: true, canada: true)
        setupCountry(country: .us)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores)
        let configuration = loader.configuration

        // Then
        XCTAssertTrue(configuration.isSupportedCountry)
    }

    func test_configuration_for_Canada_with_stripe_enabled_and_canada_enabled() {
        // Given
        setupFeatures(stripe: true, canada: true)
        setupCountry(country: .ca)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores)
        let configuration = loader.configuration

        // Then
        XCTAssertTrue(configuration.isSupportedCountry)
    }

    func test_configuration_for_Spain_with_stripe_enabled_and_canada_enabled() {
        // Given
        setupFeatures(stripe: true, canada: true)
        setupCountry(country: .es)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores)
        let configuration = loader.configuration

        // Then
        XCTAssertFalse(configuration.isSupportedCountry)
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
    }

    func setupFeatures(stripe: Bool, canada: Bool) {
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadCanadaInPersonPaymentsSwitchState(onCompletion: let completion):
                completion(.success(canada))
            default:
                break
            }
        }
    }
}
