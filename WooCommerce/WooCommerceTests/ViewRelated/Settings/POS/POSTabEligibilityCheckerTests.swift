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

    @Test func is_eligible_when_all_conditions_satisfied() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test func is_ineligible_when_account_not_whitelisted_and_feature_flag_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .featureFlagDisabled))
    }

    @Test func is_ineligible_when_device_is_not_iPad() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .phone,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .notTablet))
    }

    @Test(arguments: [(country: Country.us, currency: CurrencyCode.USD), (country: Country.gb, currency: .GBP)])
    fileprivate func is_eligible_when_country_and_currency_are_supported(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: country)
        accountWhitelistedInBackend(true)
        let currencySettings = CurrencySettings(currencyCode: currency,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: currencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [(country: Country.ca, currency: CurrencyCode.CAD), (country: Country.es, currency: CurrencyCode.EUR)])
    fileprivate func is_ineligible_when_country_is_not_supported(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: country)
        accountWhitelistedInBackend(true)
        let currencySettings = CurrencySettings(currencyCode: currency,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: currencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedCountry))
    }

    @Test(arguments: [(country: Country.us, currency: CurrencyCode.GBP),
                      (country: Country.us, currency: CurrencyCode.CAD),
                      (country: Country.gb, currency: CurrencyCode.EUR),
                      (country: Country.gb, currency: CurrencyCode.USD)])
    fileprivate func is_ineligible_when_currency_is_not_supported(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: country)
        accountWhitelistedInBackend(true)
        let currencySettings = CurrencySettings(currencyCode: currency,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: currencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedCurrency))
    }

    @Test func is_ineligible_when_woocommerce_version_is_below_minimum() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.5.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion))
    }

    @Test func is_eligible_when_core_version_is_10_0_0_and_POS_feature_enabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0")
        setupPOSFeatureEnabled(.success(true))
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test func is_ineligible_when_core_version_is_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0")
        setupPOSFeatureEnabled(.success(false))
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    @Test func is_ineligible_when_core_version_is_10_0_0_and_POS_feature_check_fails() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0")
        setupPOSFeatureEnabled(.failure(NSError(domain: "test", code: 0)))
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .featureSwitchSyncFailure))
    }

    @Test func is_eligible_when_core_version_is_below_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.9.9")
        setupPOSFeatureEnabled(.success(false))
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
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

    @Test func checkEligibility_skips_first_cached_settings_and_uses_fresh_settings() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)

        // Initial settings (cached) - makes site eligible (US)
        let cachedSettings = [
            SiteSetting.fake().copy(siteID: siteID, settingID: "woocommerce_default_country", value: "US:CA", settingGroupKey: SiteSettingGroup.general.rawValue)
        ]
        // New settings - makes site ineligible (Canada).
        let newSettings = [
            SiteSetting.fake().copy(siteID: siteID, settingID: "woocommerce_default_country", value: "CA:NS", settingGroupKey: SiteSettingGroup.general.rawValue)
        ]
        siteSettings.mockSettingsStream = AsyncStream { continuation in
            // Emits cached settings first (should be skipped).
            continuation.yield((siteID: siteID, settings: cachedSettings))
            // Emits new settings (should be used for eligibility check).
            continuation.yield((siteID: siteID, settings: newSettings))
            continuation.finish()
        }

        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then - Should be ineligible because fresh settings show CA (not cached US)
        #expect(result == .ineligible(reason: .unsupportedCountry))
    }

    @Test func checkEligibility_filters_by_correct_siteID_when_waiting_for_fresh_settings() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)

        // Settings for a different site.
        let wrongSiteSettings = [
            SiteSetting.fake().copy(siteID: 999, settingID: "woocommerce_default_country", value: "CA:NS", settingGroupKey: SiteSettingGroup.general.rawValue)
        ]
        // Settings for correct site.
        let correctSiteSettings = [
            SiteSetting.fake().copy(siteID: siteID, settingID: "woocommerce_default_country", value: "US:CA", settingGroupKey: SiteSettingGroup.general.rawValue)
        ]

        siteSettings.mockSettingsStream = AsyncStream { continuation in
            // Emits settings for a different site (should be filtered out).
            continuation.yield((siteID: 999, settings: wrongSiteSettings))
            // Emits first settings for correct site (should be skipped).
            continuation.yield((siteID: siteID, settings: [SiteSetting.fake().copy(siteID: siteID, settingID: "temp")]))
            // Emits fresh settings for correct site (should be used).
            continuation.yield((siteID: siteID, settings: correctSiteSettings))
            continuation.finish()
        }

        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               pluginsService: pluginsService,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }
}

private extension POSTabEligibilityCheckerTests {
    func setupCountry(country: Country) {
        let setting = SiteSetting.fake()
            .copy(
                siteID: siteID,
                settingID: "woocommerce_default_country",
                value: country.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        siteSettings.mockSettingsStream = AsyncStream { continuation in
            // Emits cached settings first (should be skipped).
            continuation.yield((siteID: siteID, settings: []))
            // Emits fresh settings (should be used for eligibility check).
            continuation.yield((siteID: siteID, settings: [setting]))
            continuation.finish()
        }
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

    enum Fixtures {
        static let usdCurrencySettings = CurrencySettings(currencyCode: .USD,
                                                          currencyPosition: .leftSpace,
                                                          thousandSeparator: "",
                                                          decimalSeparator: ".",
                                                          numberOfDecimals: 3)
        static let nonUSDCurrencySettings = CurrencySettings(currencyCode: .CAD,
                                                             currencyPosition: .leftSpace,
                                                             thousandSeparator: "",
                                                             decimalSeparator: ".",
                                                             numberOfDecimals: 3)
    }

    enum Country: String {
        case us = "US:CA"
        case ca = "CA:NS"
        case gb = "GB"
        case es = "ES"
    }
}

private final class MockPluginsService: PluginsServiceProtocol {
    var pluginToReturn: SystemPlugin = .fake()

    func waitForPluginInStorage(siteID: Int64, pluginName: String, isActive: Bool) async -> SystemPlugin {
        pluginToReturn
    }
}

private final class MockSelectedSiteSettings: SelectedSiteSettingsProtocol {
    var mockSettingsStream: AsyncStream<(siteID: Int64, settings: [SiteSetting])>?
    var siteSettings: [SiteSetting] = []

    var settingsStream: AsyncStream<(siteID: Int64, settings: [SiteSetting])> {
        return mockSettingsStream ?? AsyncStream { _ in }
    }

    func refresh() {
        // Mock implementation - no action needed.
    }
}
