import Combine
import Foundation
import Testing
import WooFoundation
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct POSTabVisibilityCheckerTests {
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var siteSettings: MockSelectedSiteSettings!
    private var eligibilityService: MockPOSEligibilityService!
    private var mockSiteSettingService: MockPOSSiteSettingService!
    private let site = Site.fake().copy(siteID: 2)
    private var siteID: Int64 { site.siteID }

    init() async throws {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        storageManager = MockStorageManager()
        eligibilityService = MockPOSEligibilityService()
        siteSettings = MockSelectedSiteSettings()
        mockSiteSettingService = MockPOSSiteSettingService()
    }

    // MARK: `checkVisibility`

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.USD),
        (country: Country.gb, currency: CurrencyCode.GBP)
    ])
    fileprivate func is_visible_when_all_conditions_satisfied(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test(arguments: [
        (country: Country.ca, currency: CurrencyCode.CAD),
        (country: Country.es, currency: CurrencyCode.EUR)
    ])
    fileprivate func is_invisible_when_country_is_not_supported(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }


    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.GBP),
        (country: Country.us, currency: CurrencyCode.CAD),
        (country: Country.gb, currency: CurrencyCode.EUR),
        (country: Country.gb, currency: CurrencyCode.USD)
    ])
    fileprivate func is_visible_when_currency_is_not_supported(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }


    func is_visible_when_woocommerce_version_is_below_minimum() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func is_invisible_when_remote_feature_flag_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .us)
        accountWhitelistedInBackend(false)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_skips_settings_from_initialLoad() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()

        // Initial settings (cached) - makes site eligible (US)
        let initialSettings = [
            mockCountrySetting(country: .us),
            mockCurrencySetting(currency: .USD)
        ]
        // New settings - makes site ineligible (Canada).
        let newSettings = [
            mockCountrySetting(country: .ca),
            mockCurrencySetting(currency: .USD)
        ]
        siteSettings.mockSettingsStream = [
            // Emits cached settings first (should be skipped).
            (siteID: siteID, settings: initialSettings, source: .initialLoad),
            // Emits new settings (should be used for eligibility check).
            (siteID: siteID, settings: newSettings, source: .storageChange)
        ].publisher.eraseToAnyPublisher()

        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then - Should be invisible because fresh settings show CA (not cached US)
        #expect(result == false)
    }

    @Test func is_invisible_when_device_is_not_iPad() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .phone, // Not iPad
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func is_invisible_when_site_is_CIAB() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .us, currency: .USD)
        accountWhitelistedInBackend(true)
        let ciabEligibilityChecker = MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: true,
                                                                mockedCIABSites: [site],
                                                                mockedCIABDisabledFeatures: [.pointOfSale])
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              siteCIABEligibilityChecker: ciabEligibilityChecker)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_returns_expected_result_after_site_settings_available() async throws {
        // Given - no site settings are immediately available (empty stream that will emit values later)
        let featureFlagService = MockFeatureFlagService()
        accountWhitelistedInBackend(true)

        // Creates a publisher that will emit values after a delay to simulate site settings loading
        let countrySetting = mockCountrySetting(country: .us)
        let currencySetting = mockCurrencySetting(currency: .USD)
        let settingsSubject = PassthroughSubject<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never>()
        siteSettings.mockSettingsStream = settingsSubject.eraseToAnyPublisher()

        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService)

        // When - Call checkVisibility before site settings are available
        async let visibilityTask = checker.checkVisibility()

        // Simulate site settings becoming available after methods are called
        Task {
            settingsSubject.send((siteID: siteID, settings: [countrySetting, currencySetting], source: .refresh))
            settingsSubject.send(completion: .finished)
        }

        let visibilityResult = await visibilityTask

        // Then - both methods should wait for site settings and return expected results.
        #expect(visibilityResult == true)
    }

    // MARK: - `checkInitialVisibility Tests

    @Test func checkInitialVisibility_returns_true_when_cached_tab_visibility_is_enabled() async throws {
        // Given
        let checker = POSTabVisibilityChecker(site: site, eligibilityService: eligibilityService, stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: true)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_disabled() async throws {
        // Given
        let checker = POSTabVisibilityChecker(site: site, eligibilityService: eligibilityService, stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: false)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_unavailable() async throws {
        // Given
        let checker = POSTabVisibilityChecker(site: site, eligibilityService: eligibilityService, stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: nil)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }
}

private extension POSTabVisibilityCheckerTests {
    func setupCountry(country: Country, currency: CurrencyCode = .USD) {
        let countrySetting = mockCountrySetting(country: country)
        let currencySetting = mockCurrencySetting(currency: currency)
        siteSettings.mockSettingsStream = [
            // Emits cached settings first (should be skipped).
            (siteID: siteID, settings: [], source: .storageChange),
            // Emits fresh settings (should be used for eligibility check).
            (siteID: siteID, settings: [countrySetting, currencySetting], source: .refresh)
        ].publisher.eraseToAnyPublisher()
    }

    func accountWhitelistedInBackend(_ isAllowed: Bool = false) {
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case .isRemoteFeatureFlagEnabled(_, _, _, completion: let completion):
                completion(isAllowed)
            }
        }
    }

    func setupPOSTabVisibility(siteID: Int64, isVisible: Bool?) {
        eligibilityService.cachedTabVisibility[siteID] = isVisible
    }

    enum Country: String {
        case us = "US:CA"
        case ca = "CA:NS"
        case gb = "GB"
        case es = "ES"

        var countryCode: CountryCode {
            switch self {
            case .us:
                return .US
            case .ca:
                return .CA
            case .gb:
                return .GB
            case .es:
                return .ES
            }
        }
    }

    func mockCountrySetting(country: Country, siteID: Int64? = nil) -> SiteSetting {
        SiteSetting.fake()
            .copy(
                siteID: siteID ?? siteID,
                settingID: "woocommerce_default_country",
                value: country.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
    }

    func mockCurrencySetting(currency: CurrencyCode, siteID: Int64? = nil) -> SiteSetting {
        SiteSetting.fake()
            .copy(
                siteID: siteID ?? siteID,
                settingID: "woocommerce_currency",
                value: currency.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
    }
}
