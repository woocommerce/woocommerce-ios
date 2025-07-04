import Combine
import Foundation
import Testing
import WooFoundation
import Yosemite
@testable import WooCommerce

@MainActor
struct POSTabEligibilityCheckerTests {
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var siteSettings: MockSelectedSiteSettings!
    private var pluginsService: MockPluginsService!
    private var eligibilityService: MockPOSEligibilityService!
    private let siteID: Int64 = 2

    init() async throws {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        storageManager = MockStorageManager()
        pluginsService = MockPluginsService()
        eligibilityService = MockPOSEligibilityService()
        setupWooCommerceVersion()
        siteSettings = MockSelectedSiteSettings()
    }

    @Test(arguments: [true, false])
    func is_eligible_when_all_conditions_satisfied(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [true, false])
    func is_ineligible_when_account_not_whitelisted_and_feature_flag_disabled(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: .us)
        accountWhitelistedInBackend(false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .featureFlagDisabled))
    }

    @Test(arguments: [true, false])
    func is_ineligible_when_device_is_not_iPad(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .phone,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .notTablet))
    }

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.USD, isPointOfSaleAsATabi2Enabled: true),
        (country: Country.us, currency: CurrencyCode.USD, isPointOfSaleAsATabi2Enabled: false),
        (country: Country.gb, currency: CurrencyCode.GBP, isPointOfSaleAsATabi2Enabled: true),
        (country: Country.gb, currency: CurrencyCode.GBP, isPointOfSaleAsATabi2Enabled: false)
    ])
    fileprivate func is_eligible_when_country_and_currency_supported(country: Country, currency: CurrencyCode, isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [
        (country: Country.ca, currency: CurrencyCode.CAD, isPointOfSaleAsATabi2Enabled: true),
        (country: Country.ca, currency: CurrencyCode.CAD, isPointOfSaleAsATabi2Enabled: false),
        (country: Country.es, currency: CurrencyCode.EUR, isPointOfSaleAsATabi2Enabled: true),
        (country: Country.es, currency: CurrencyCode.EUR, isPointOfSaleAsATabi2Enabled: false)
    ])
    fileprivate func is_ineligible_when_country_is_not_supported(country: Country, currency: CurrencyCode, isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedCountry(supportedCountries: [.US, .GB])))
    }

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.GBP, expectedSupportedCurrencies: [CurrencyCode.USD], isPointOfSaleAsATabi2Enabled: true),
        (country: Country.us, currency: CurrencyCode.GBP, expectedSupportedCurrencies: [CurrencyCode.USD], isPointOfSaleAsATabi2Enabled: false),
        (country: Country.us, currency: CurrencyCode.CAD, expectedSupportedCurrencies: [CurrencyCode.USD], isPointOfSaleAsATabi2Enabled: true),
        (country: Country.us, currency: CurrencyCode.CAD, expectedSupportedCurrencies: [CurrencyCode.USD], isPointOfSaleAsATabi2Enabled: false),
        (country: Country.gb, currency: CurrencyCode.EUR, expectedSupportedCurrencies: [CurrencyCode.GBP], isPointOfSaleAsATabi2Enabled: true),
        (country: Country.gb, currency: CurrencyCode.EUR, expectedSupportedCurrencies: [CurrencyCode.GBP], isPointOfSaleAsATabi2Enabled: false),
        (country: Country.gb, currency: CurrencyCode.USD, expectedSupportedCurrencies: [CurrencyCode.GBP], isPointOfSaleAsATabi2Enabled: true),
        (country: Country.gb, currency: CurrencyCode.USD, expectedSupportedCurrencies: [CurrencyCode.GBP], isPointOfSaleAsATabi2Enabled: false)
    ])
    fileprivate func is_ineligible_when_currency_is_not_supported(country: Country,
                                                                  currency: CurrencyCode,
                                                                  expectedSupportedCurrencies: [CurrencyCode],
                                                                  isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedCurrency(supportedCurrencies: expectedSupportedCurrencies)))
    }

    @Test(arguments: [true, false])
    func is_ineligible_when_woocommerce_version_is_below_minimum(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.5.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta")))
    }

    @Test(arguments: [true, false])
    func is_eligible_when_core_version_is_10_0_0_and_POS_feature_enabled(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0")
        setupPOSFeatureEnabled(.success(true))
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [true, false])
    func is_ineligible_when_core_version_is_10_0_0_and_POS_feature_disabled(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0")
        setupPOSFeatureEnabled(.success(false))
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    @Test(arguments: [true, false])
    func is_ineligible_when_core_version_is_10_0_0_and_POS_feature_check_fails(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0")
        setupPOSFeatureEnabled(.failure(NSError(domain: "test", code: 0)))
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .featureSwitchSyncFailure))
    }

    @Test(arguments: [true, false])
    func is_eligible_when_core_version_is_below_10_0_0_and_POS_feature_disabled(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.9.9")
        setupPOSFeatureEnabled(.success(false))
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test func checkInitialVisibility_returns_true_when_cached_tab_visibility_is_enabled() async throws {
        // Given
        let checker = POSTabEligibilityChecker(siteID: siteID, eligibilityService: eligibilityService, stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: true)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_disabled() async throws {
        // Given
        let checker = POSTabEligibilityChecker(siteID: siteID, eligibilityService: eligibilityService, stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: false)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_unavailable() async throws {
        // Given
        let checker = POSTabEligibilityChecker(siteID: siteID, eligibilityService: eligibilityService, stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: nil)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test(arguments: [true, false])
    func checkEligibility_skips_settings_from_initialLoad(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)

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
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then - Should be ineligible because fresh settings show CA (not cached US)
        #expect(result == .ineligible(reason: .unsupportedCountry(supportedCountries: [.US, .GB])))
    }

    @Test(arguments: [true, false])
    func checkEligibility_filters_by_correct_siteID(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)

        // Settings for a different site.
        let wrongSiteSettings = [
            mockCountrySetting(country: .ca, siteID: 999),
            mockCurrencySetting(currency: .CAD, siteID: 999)
        ]
        // Settings for correct site.
        let correctSiteSettings = [
            mockCountrySetting(country: .us),
            mockCurrencySetting(currency: .USD)
        ]

        siteSettings.mockSettingsStream = [
            // Emits settings for a different site (should be filtered out).
            (siteID: 999, settings: wrongSiteSettings, source: .storageChange),
            // Emits first settings for correct site (should be skipped).
            (siteID: siteID, settings: [SiteSetting.fake().copy(siteID: siteID, settingID: "temp")], source: .initialLoad),
            // Emits fresh settings for correct site (should be used).
            (siteID: siteID, settings: correctSiteSettings, source: .storageChange)
        ].publisher.eraseToAnyPublisher()

        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    // MARK: - checkVisibility Tests

    @Test(arguments: [
        // Eligible countries and currencies.
        (country: Country.us, currency: CurrencyCode.USD),
        (country: Country.gb, currency: CurrencyCode.GBP),
        // Eligible countries but ineligible currencies.
        (country: Country.us, currency: CurrencyCode.EUR),
        (country: Country.gb, currency: CurrencyCode.CAD)
    ])
    fileprivate func checkVisibility_returns_true_when_i2_enabled_and_country_remote_feature_eligible(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test(arguments: [(country: Country.ca, currency: CurrencyCode.CAD), (country: Country.es, currency: CurrencyCode.EUR)])
    fileprivate func checkVisibility_returns_false_when_pointOfSaleAsATabi2_enabled_but_country_ineligible(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test(arguments: [(country: Country.us, currency: CurrencyCode.USD), (country: Country.gb, currency: .GBP)])
    fileprivate func checkVisibility_returns_false_when_i2_enabled_but_remote_feature_flag_disabled(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_returns_true_when_pointOfSaleAsATabi2_disabled_and_checkEligibility_eligible() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test(arguments: [(country: Country.us, currency: CurrencyCode.GBP), (country: Country.gb, currency: .EUR)])
    fileprivate func checkVisibility_returns_false_when_i2_disabled_and_checkEligibility_ineligible(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: country, currency: currency) // Ineligible country/currency combination
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test(arguments: [true, false])
    func checkVisibility_returns_false_when_device_is_not_iPad(isPointOfSaleAsATabi2Enabled: Bool) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: isPointOfSaleAsATabi2Enabled)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .phone, // Not iPad
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkEligibility_uses_cached_values_after_checkVisibility_when_i2_feature_is_enabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When checkVisibility first (which caches siteSettingsEligibility and featureFlagEligibility)
        let visibilityResult = await checker.checkVisibility()

        // And site settings and feature flag eligibility changes
        setupCountry(country: .ca, currency: .AMD)
        accountWhitelistedInBackend(false)

        // Then checkEligibility should use cached values for site settings and feature flags
        let eligibilityResult = await checker.checkEligibility()

        // Then - both should return the expected results, demonstrating caching works
        #expect(visibilityResult == true)
        #expect(eligibilityResult == .eligible)
    }

    @Test func checkVisibility_and_checkEligibility_return_expected_result_after_site_settings_available() async throws {
        // Given - no site settings are immediately available (empty stream that will emit values later)
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        accountWhitelistedInBackend(true)

        // Creates a publisher that will emit values after a delay to simulate site settings loading
        let countrySetting = mockCountrySetting(country: .us)
        let currencySetting = mockCurrencySetting(currency: .USD)
        let settingsSubject = PassthroughSubject<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never>()
        siteSettings.mockSettingsStream = settingsSubject.eraseToAnyPublisher()

        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When - Call checkVisibility and checkEligibility concurrently before site settings are available
        async let visibilityTask = checker.checkVisibility()
        async let eligibilityTask = checker.checkEligibility()

        // Simulate site settings becoming available after methods are called
        Task {
            settingsSubject.send((siteID: siteID, settings: [countrySetting, currencySetting], source: .refresh))
            settingsSubject.send(completion: .finished)
        }

        let visibilityResult = await visibilityTask
        let eligibilityResult = await eligibilityTask

        // Then - both methods should wait for site settings and return expected results.
        #expect(visibilityResult == true)
        #expect(eligibilityResult == .eligible)
    }
}

private extension POSTabEligibilityCheckerTests {
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

    func setupWooCommerceVersion(_ version: String = "9.6.0-beta") {
        pluginsService.pluginToReturn = .fake().copy(
            siteID: siteID,
            plugin: "woocommerce/woocommerce.php",
            version: version,
            active: true
        )
    }

    func accountWhitelistedInBackend(_ isAllowed: Bool = false) {
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case .isRemoteFeatureFlagEnabled(_, _, completion: let completion):
                completion(isAllowed)
            }
        }
    }

    func setupPOSFeatureEnabled(_ result: Result<Bool, Error>) {
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .isFeatureEnabled(_, _, let completion):
                completion(result)
            default:
                break
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

private final class MockPluginsService: PluginsServiceProtocol {
    var pluginToReturn: SystemPlugin = .fake()

    func waitForPluginInStorage(siteID: Int64, plugin: String, isActive: Bool) async -> SystemPlugin {
        pluginToReturn
    }
}

private final class MockSelectedSiteSettings: SelectedSiteSettingsProtocol {
    var mockSettingsStream: AnyPublisher<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never>?
    var siteSettings: [SiteSetting] = []

    var settingsStream: AnyPublisher<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never> {
        return mockSettingsStream ?? Empty().eraseToAnyPublisher()
    }

    func refresh() {
        // Mock implementation - no action needed.
    }
}
