import XCTest
import Yosemite
import YosemiteTestHelpers
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

    private var ineligibleService: StubCardPresentExpansionEligibilityService!
    private var eligibleService: StubCardPresentExpansionEligibilityService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.sessionManager.setStoreId(sampleSiteID)
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings(stores: stores, storageManager: storageManager))
        ineligibleService = StubCardPresentExpansionEligibilityService(isEligible: false)
        eligibleService = StubCardPresentExpansionEligibilityService(isEligible: true)
    }

    override func tearDownWithError() throws {
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings())
        storageManager.reset()
        storageManager = nil
        stores = nil
        ineligibleService = nil
        eligibleService = nil
        try super.tearDownWithError()
    }

    func test_configuration_for_US_is_supported() {
        // Given
        setupCountry(country: .us)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores, eligibilityService: ineligibleService)

        // Then
        XCTAssertTrue(loader.configuration.isSupportedCountry)
    }

    func test_configuration_for_Canada_is_supported() {
        // Given
        setupCountry(country: .ca)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores, eligibilityService: ineligibleService)

        // Then
        XCTAssertTrue(loader.configuration.isSupportedCountry)
    }

    func test_configuration_for_UK_is_supported() {
        // Given
        setupCountry(country: .gb)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores, eligibilityService: ineligibleService)

        // Then
        XCTAssertTrue(loader.configuration.isSupportedCountry)
    }

    func test_configuration_for_Spain_is_unsupported_when_expansion_ineligible() {
        // Given
        setupCountry(country: .es)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores, eligibilityService: ineligibleService)

        // Then
        XCTAssertFalse(loader.configuration.isSupportedCountry)
    }

    func test_configuration_for_Spain_is_supported_when_expansion_eligible() {
        // Given
        setupCountry(country: .es)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores, eligibilityService: eligibleService)

        // Then
        XCTAssertTrue(loader.configuration.isSupportedCountry)
        XCTAssertEqual(loader.configuration.currencies, [.EUR])
    }

    func test_configuration_for_Singapore_is_supported_when_expansion_eligible() {
        // Given
        setupCountry(country: .sg)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores, eligibilityService: eligibleService)

        // Then
        XCTAssertTrue(loader.configuration.isSupportedCountry)
        XCTAssertEqual(loader.configuration.currencies, [.SGD])
    }

    func test_configuration_for_New_Zealand_is_supported_when_expansion_eligible() {
        // Given
        setupCountry(country: .nz)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores, eligibilityService: eligibleService)

        // Then
        XCTAssertTrue(loader.configuration.isSupportedCountry)
        XCTAssertEqual(loader.configuration.currencies, [.NZD])
    }

    func test_configuration_for_Australia_is_supported() {
        // Given
        setupCountry(country: .au)

        // When
        let loader = CardPresentConfigurationLoader(stores: stores, eligibilityService: eligibleService)

        // Then
        XCTAssertTrue(loader.configuration.isSupportedCountry)
        XCTAssertEqual(loader.configuration.currencies, [.AUD])
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
        case sg = "SG"
        case nz = "NZ"
        case au = "AU"
    }
}

// MARK: - Test Helper

private final class StubCardPresentExpansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol {
    private var isEligibleValue: Bool

    init(isEligible: Bool) {
        self.isEligibleValue = isEligible
    }

    func isEligible(siteID: Int64) -> Bool {
        isEligibleValue
    }

    func cacheEligibility(siteID: Int64, isEligible: Bool) {
        isEligibleValue = isEligible
    }
}
