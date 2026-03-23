import Combine
import Foundation
import PointOfSale
import Testing
import WooFoundation
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct POSTabEligibilityCheckerTests {
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var siteSettings: MockSelectedSiteSettings!
    private var eligibilityService: MockPOSEligibilityService!
    private var mockSystemStatusService: MockPOSSystemStatusService!
    private var mockSiteSettingService: MockPOSSiteSettingService!
    private let site = Site.fake().copy(siteID: 2)
    private var siteID: Int64 { site.siteID }

    init() async throws {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        storageManager = MockStorageManager()
        eligibilityService = MockPOSEligibilityService()
        siteSettings = MockSelectedSiteSettings()
        mockSystemStatusService = MockPOSSystemStatusService()
        mockSiteSettingService = MockPOSSiteSettingService()
        setupWooCommerceVersion()
    }

    // MARK: - `checkEligibility` Tests

    @Test func is_eligible_when_site_settings_are_from_correct_siteID() async throws {
        // Given

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

        setupWooCommerceVersion("9.6.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test func checkEligibility_returns_expected_result_after_site_settings_available() async throws {
        // Given - no site settings are immediately available (empty stream that will emit values later)

        // Creates a publisher that will emit values after a delay to simulate site settings loading
        let countrySetting = mockCountrySetting(country: .us)
        let currencySetting = mockCurrencySetting(currency: .USD)
        let settingsSubject = PassthroughSubject<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never>()
        siteSettings.mockSettingsStream = settingsSubject.eraseToAnyPublisher()

        setupWooCommerceVersion("9.6.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When - Call checkEligibility before site settings are available
        async let eligibilityTask = checker.checkEligibility()

        // Simulate site settings becoming available after methods are called
        Task {
            settingsSubject.send((siteID: siteID, settings: [countrySetting, currencySetting], source: .refresh))
            settingsSubject.send(completion: .finished)
        }

        let eligibilityResult = await eligibilityTask

        // Then - both methods should wait for site settings and return expected results.
        #expect(eligibilityResult == .eligible)
    }

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.USD),
        (country: Country.gb, currency: CurrencyCode.GBP)
    ])
    fileprivate func is_eligible_when_all_conditions_satisfied(country: Country, currency: CurrencyCode) async throws {
        // Given
        setupCountry(country: country, currency: currency)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [
        (country: Country.ca, currency: CurrencyCode.CAD),
        (country: Country.es, currency: CurrencyCode.EUR)
    ])
    fileprivate func is_ineligible_when_country_is_not_supported(country: Country, currency: CurrencyCode) async throws {
        // Given
        setupCountry(country: country, currency: currency)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .siteSettingsNotAvailable))
    }

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.GBP, expectedSupportedCurrencies: [CurrencyCode.USD]),
        (country: Country.us, currency: CurrencyCode.CAD, expectedSupportedCurrencies: [CurrencyCode.USD]),
        (country: Country.gb, currency: CurrencyCode.EUR, expectedSupportedCurrencies: [CurrencyCode.GBP]),
        (country: Country.gb, currency: CurrencyCode.USD, expectedSupportedCurrencies: [CurrencyCode.GBP])
    ])
    fileprivate func is_ineligible_when_currency_is_not_supported(country: Country,
                                                                  currency: CurrencyCode,
                                                                  expectedSupportedCurrencies: [CurrencyCode]) async throws {
        // Given
        setupCountry(country: country, currency: currency)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedCurrency(countryCode: country.countryCode, supportedCurrencies: expectedSupportedCurrencies)))
    }

    func is_ineligible_when_woocommerce_version_is_below_minimum() async throws {
        // Given
        setupCountry(country: .us)
        setupWooCommerceVersion("9.5.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta")))
    }

    func is_eligible_when_core_version_is_10_0_0_and_POS_feature_enabled() async throws {
        // Given
        setupCountry(country: .us)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    func is_ineligible_when_core_version_is_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        setupCountry(country: .us)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    func is_eligible_when_core_version_is_below_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        setupCountry(country: .us)
        setupWooCommerceVersion("9.9.9", featureSwitchEnabled: false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    // MARK: - CIAB Plan Eligibility Tests

    @Test func checkEligibility_when_ciab_site_with_pro_monthly_plan_then_eligible() async throws {
        // Given
        let ciabSite = Site.fake().copy(siteID: siteID, plan: "woo_hosted_pro_plan_monthly", isGarden: true, gardenName: "commerce")
        stores.updateDefaultStore(ciabSite)
        setupCountry(country: .us)
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleGatingForCIABSites] = true
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlags,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test func checkEligibility_when_ciab_site_with_pro_yearly_plan_then_eligible() async throws {
        // Given
        let ciabSite = Site.fake().copy(siteID: siteID, plan: "woo_hosted_pro_plan_yearly", isGarden: true, gardenName: "commerce")
        stores.updateDefaultStore(ciabSite)
        setupCountry(country: .us)
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleGatingForCIABSites] = true
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlags,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [
        "woo_hosted_free_plan",
        "woo_hosted_basic_plan_monthly",
        "woo_hosted_basic_plan_yearly",
        "woo_hosted_free_trial_plan_monthly"
    ])
    func checkEligibility_when_ciab_site_with_non_pro_plan_then_ineligible(planSlug: String) async throws {
        // Given
        let ciabSite = Site.fake().copy(siteID: siteID, plan: planSlug, isGarden: true, gardenName: "commerce")
        stores.updateDefaultStore(ciabSite)
        setupCountry(country: .us)
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleGatingForCIABSites] = true
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlags,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .ciabPlanUpgradeRequired))
    }

    @Test func checkEligibility_when_non_ciab_site_then_not_blocked_by_plan_check() async throws {
        // Given
        let nonCIABSite = Site.fake().copy(siteID: siteID, plan: "woo_hosted_free_plan", isGarden: false)
        stores.updateDefaultStore(nonCIABSite)
        setupCountry(country: .us)
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleGatingForCIABSites] = true
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlags,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test func checkEligibility_when_feature_flag_disabled_then_ciab_check_skipped() async throws {
        // Given
        let ciabSite = Site.fake().copy(siteID: siteID, plan: "woo_hosted_free_plan", isGarden: true, gardenName: "commerce")
        stores.updateDefaultStore(ciabSite)
        setupCountry(country: .us)
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleGatingForCIABSites] = false
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlags,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then (CIAB check is skipped, so site is eligible at this point)
        #expect(result == .eligible)
    }

    @Test func refreshEligibility_when_ciabPlanUpgradeRequired_then_rechecks_eligibility() async throws {
        // Given
        let ciabSite = Site.fake().copy(siteID: siteID, plan: "woo_hosted_pro_plan_monthly", isGarden: true, gardenName: "commerce")
        stores.updateDefaultStore(ciabSite)
        setupCountry(country: .us, currency: .USD)
        let featureFlags = MockFeatureFlagService()
        featureFlags.isFeatureFlagEnabledReturnValue[.pointOfSaleGatingForCIABSites] = true
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlags,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: .ciabPlanUpgradeRequired)

        // Then
        #expect(result == .eligible)
    }

    // MARK: - `refreshEligibility` Tests

    @Test(arguments: [
        POSIneligibleReason.siteSettingsNotAvailable,
        POSIneligibleReason.unsupportedCurrency(countryCode: .US, supportedCurrencies: [.USD])
    ])
    fileprivate func refreshEligibility_syncs_site_settings_and_checks_eligibility_for_site_settings_issues(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.6.0", featureSwitchEnabled: true)

        var syncCalled = false
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .synchronizeGeneralSiteSettings(_, let completion):
                syncCalled = true
                completion(nil) // Success
            case .isFeatureEnabled(_, _, let completion):
                completion(.success(true))
            default:
                break
            }
        }

        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(syncCalled == true)
        #expect(result == .eligible)
    }

    @Test(arguments: [
        POSIneligibleReason.siteSettingsNotAvailable,
        POSIneligibleReason.unsupportedCurrency(countryCode: .US, supportedCurrencies: [.USD])
    ])
    fileprivate func refreshEligibility_returns_siteSettingsNotAvailable_when_site_settings_sync_fails(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.6.0")

        var syncCalled = false
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .synchronizeGeneralSiteSettings(_, let completion):
                syncCalled = true
                completion(NSError(domain: "test", code: 500)) // Network error
            default:
                break
            }
        }

        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores)

        // When & Then - Should throw the network error
        #expect(syncCalled == false) // Not called yet
        await #expect(throws: NSError.self) {
            try await checker.refreshEligibility(ineligibleReason: ineligibleReason)
        }
        #expect(syncCalled == true) // Called during the attempt
    }

    @Test func refreshEligibility_checks_eligibility_for_featureSwitchDisabled() async throws {
        // Given
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: true)

        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService,
                                               siteSettingService: mockSiteSettingService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: .featureSwitchDisabled)

        // Then - Should check eligibility again (now eligible)
        #expect(result == .eligible)
    }

    @Test func refreshEligibility_checks_eligibility_for_selfDeallocated() async throws {
        // Given
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.6.0", featureSwitchEnabled: true)

        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: .selfDeallocated)

        // Then - Should check eligibility again (now eligible)
        #expect(result == .eligible)
    }

    // MARK: - `refreshEligibility` with System Status Service Tests

    @Test(arguments: [
        POSIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta"),
        POSIneligibleReason.wooCommercePluginNotFound
    ])
    func refreshEligibility_returns_eligible_when_plugin_refreshed_with_valid_version_below_10(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        let wcPlugin = createWooCommercePlugin(version: "9.9.9") // Valid version below feature switch threshold
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: nil))

        setupCountry(country: .us, currency: .USD)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [
        POSIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta"),
        POSIneligibleReason.wooCommercePluginNotFound
    ])
    fileprivate func refreshEligibility_returns_eligible_when_plugin_with_version_10_and_feature_enabled(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        let wcPlugin = createWooCommercePlugin(version: "10.0.0")
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: true))

        setupCountry(country: .us, currency: .USD)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [
        POSIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta"),
        POSIneligibleReason.wooCommercePluginNotFound
    ])
    fileprivate func refreshEligibility_returns_ineligible_when_plugin_not_found_in_system_status(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: nil, featureValue: nil))

        setupCountry(country: .us, currency: .USD)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(result == .ineligible(reason: .wooCommercePluginNotFound))
    }

    @Test(arguments: [
        POSIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta"),
        POSIneligibleReason.wooCommercePluginNotFound
    ])
    fileprivate func refreshEligibility_returns_ineligible_when_plugin_version_still_below_minimum(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        let wcPlugin = createWooCommercePlugin(version: "9.5.0") // Still below minimum 9.6.0-beta
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: nil))

        setupCountry(country: .us, currency: .USD)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta")))
    }

    @Test(arguments: [
        POSIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta"),
        POSIneligibleReason.wooCommercePluginNotFound
    ])
    fileprivate func refreshEligibility_returns_ineligible_when_feature_switch_still_disabled(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        let wcPlugin = createWooCommercePlugin(version: "10.0.0")
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: nil))

        setupCountry(country: .us, currency: .USD)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    @Test(arguments: [
        POSIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta"),
        POSIneligibleReason.wooCommercePluginNotFound
    ])
    fileprivate func refreshEligibility_returns_ineligible_when_system_status_request_fails(ineligibleReason: POSIneligibleReason) async throws {
        // Given
        mockSystemStatusService.resultToReturn = .failure(NSError(domain: "test", code: 500))

        setupCountry(country: .us, currency: .USD)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(result == .ineligible(reason: .wooCommercePluginNotFound))
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

    func setupWooCommerceVersion(_ version: String = "9.6.0-beta", featureSwitchEnabled: Bool? = nil) {
        let wcPlugin = createWooCommercePlugin(version: version)
        mockSystemStatusService.resultToReturn = .success(POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: featureSwitchEnabled))
    }

    func createWooCommercePlugin(version: String) -> SystemPlugin {
        SystemPlugin.fake().copy(
            siteID: siteID,
            plugin: "woocommerce/woocommerce.php",
            version: version,
            active: true
        )
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

private final class MockPOSSystemStatusService: POSSystemStatusServiceProtocol {
    var resultToReturn: Result<POSPluginAndFeatureInfo, Error> = .success(POSPluginAndFeatureInfo(wcPlugin: nil, featureValue: nil))

    func loadWooCommercePluginAndPOSFeatureSwitch(siteID: Int64) async throws -> POSPluginAndFeatureInfo {
        switch resultToReturn {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        }
    }
}
