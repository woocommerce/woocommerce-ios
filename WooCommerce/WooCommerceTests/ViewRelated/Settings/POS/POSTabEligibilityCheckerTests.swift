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
    private var eligibilityService: MockPOSEligibilityService!
    private var mockSystemStatusService: MockPOSSystemStatusService!
    private let siteID: Int64 = 2

    init() async throws {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        storageManager = MockStorageManager()
        eligibilityService = MockPOSEligibilityService()
        siteSettings = MockSelectedSiteSettings()
        mockSystemStatusService = MockPOSSystemStatusService()
        setupWooCommerceVersion()
    }

    // MARK: `checkVisibility`

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.USD),
        (country: Country.gb, currency: CurrencyCode.GBP)
    ])
    fileprivate func is_visible_when_all_conditions_satisfied(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
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
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
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
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
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
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.5.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func is_visible_when_core_version_is_10_0_0_and_POS_feature_enabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }


    func is_visible_when_core_version_is_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }


    func is_visible_when_core_version_is_10_0_0_and_POS_feature_check_fails() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: nil)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func is_visible_when_core_version_is_below_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.9.9", featureSwitchEnabled: false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func is_visible_when_site_settings_are_from_correct_siteID() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)

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
        setupWooCommerceVersion("9.6.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test func is_invisible_when_remote_feature_flag_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
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
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)

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
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then - Should be invisible because fresh settings show CA (not cached US)
        #expect(result == false)
    }

    @Test func is_invisible_when_device_is_not_iPad() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .phone, // Not iPad
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
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

        setupWooCommerceVersion("9.6.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService,
                                               systemStatusService: mockSystemStatusService)

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

    // MARK: - `checkInitialVisibility Tests

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

    // MARK: - `checkEligibility` Tests

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.USD),
        (country: Country.gb, currency: CurrencyCode.GBP)
    ])
    fileprivate func is_eligible_when_all_conditions_satisfied(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService,
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
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

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
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedCurrency(supportedCurrencies: expectedSupportedCurrencies)))
    }

    func is_ineligible_when_woocommerce_version_is_below_minimum() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.5.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta")))
    }

    func is_eligible_when_core_version_is_10_0_0_and_POS_feature_enabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    func is_ineligible_when_core_version_is_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    func is_eligible_when_core_version_is_below_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleAsATabi2Enabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.9.9", featureSwitchEnabled: false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService,
                                               systemStatusService: mockSystemStatusService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    // MARK: - `refreshEligibility` Tests

    @Test func refreshEligibility_returns_ineligible_for_unsupportedIOSVersion() async throws {
        // Given
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               siteSettings: siteSettings,
                                               stores: stores)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: .unsupportedIOSVersion)

        // Then
        #expect(result == .ineligible(reason: .unsupportedIOSVersion))
    }

    @Test(arguments: [
        POSIneligibleReason.siteSettingsNotAvailable,
        POSIneligibleReason.unsupportedCurrency(supportedCurrencies: [.USD])
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
        POSIneligibleReason.unsupportedCurrency(supportedCurrencies: [.USD])
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
                                               systemStatusService: mockSystemStatusService)

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

    func accountWhitelistedInBackend(_ isAllowed: Bool = false) {
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case .isRemoteFeatureFlagEnabled(_, _, completion: let completion):
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
