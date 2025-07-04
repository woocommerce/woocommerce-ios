import Combine
import Foundation
import Testing
import WooFoundation
import Yosemite
@testable import WooCommerce

@MainActor
struct LegacyPOSTabEligibilityCheckerTests {
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

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.USD),
        (country: Country.gb, currency: CurrencyCode.GBP)
    ])
    fileprivate func is_visible_when_all_conditions_satisfied(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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

    @Test func is_invisible_when_account_not_whitelisted_and_feature_flag_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(false)
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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

    @Test func is_invisible_when_device_is_not_iPad() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .phone,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test(arguments: [
        (country: Country.ca, currency: CurrencyCode.CAD),
        (country: Country.es, currency: CurrencyCode.EUR)
    ])
    fileprivate func is_invisible_when_country_is_not_supported(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.GBP),
        (country: Country.us, currency: CurrencyCode.CAD),
        (country: Country.gb, currency: CurrencyCode.EUR),
        (country: Country.gb, currency: CurrencyCode.USD)
    ])
    fileprivate func is_invisible_when_currency_is_not_supported(country: Country,
                                                                 currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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

    @Test func is_invisible_when_woocommerce_version_is_below_minimum() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.5.0")
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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

    @Test func is_visible_when_core_version_is_10_0_0_and_POS_feature_enabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0")
        setupPOSFeatureEnabled(.success(true))
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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

    @Test func is_invisible_when_core_version_is_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0")
        setupPOSFeatureEnabled(.success(false))
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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

    @Test func is_invisible_when_core_version_is_10_0_0_and_POS_feature_check_fails() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0")
        setupPOSFeatureEnabled(.failure(NSError(domain: "test", code: 0)))
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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

    @Test func is_visible_when_core_version_is_below_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.9.9")
        setupPOSFeatureEnabled(.success(false))
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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

    @Test func checkInitialVisibility_returns_true_when_cached_tab_visibility_is_enabled() async throws {
        // Given
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID, eligibilityService: eligibilityService, stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: true)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_disabled() async throws {
        // Given
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID, eligibilityService: eligibilityService, stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: false)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_unavailable() async throws {
        // Given
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID, eligibilityService: eligibilityService, stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: nil)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_skips_settings_from_initialLoad() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)

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
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then - Should return false because i2 feature flag is disabled
        #expect(result == false)
    }

    @Test func is_visible_from_filtering_site_settings_by_correct_siteID() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: false)

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
        let checker = LegacyPOSTabEligibilityChecker(siteID: siteID,
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
}

private extension LegacyPOSTabEligibilityCheckerTests {
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
            plugin: "WooCommerce",
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

    func waitForPluginInStorage(siteID: Int64, pluginName: String, isActive: Bool) async -> SystemPlugin {
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
