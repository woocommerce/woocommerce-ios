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
    private var connectivityObserver: MockConnectivityObserver!
    private let site = Site.fake().copy(siteID: 2)
    private var siteID: Int64 { site.siteID }
    private let ineligibleExpansionService = StubCardPresentExpansionEligibilityService(isEligible: false)
    private let eligibleExpansionService = StubCardPresentExpansionEligibilityService(isEligible: true)

    init() async throws {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        storageManager = MockStorageManager()
        eligibilityService = MockPOSEligibilityService()
        siteSettings = MockSelectedSiteSettings()
        mockSystemStatusService = MockPOSSystemStatusService()
        mockSiteSettingService = MockPOSSiteSettingService()
        connectivityObserver = MockConnectivityObserver()
        connectivityObserver.setStatus(.reachable(type: .ethernetOrWiFi))
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
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .eligible)
    }

    @Test func checkEligibility_returns_expected_result_after_site_settings_available() async throws {
        // Given - no site settings are immediately available (empty stream that will emit values later)

        // Creates a publisher that will emit values after a delay to simulate site settings loading.
        // A CurrentValueSubject replays the latest value, so the test stays deterministic no matter
        // whether the eligibility check subscribes before or after the settings are sent.
        let countrySetting = mockCountrySetting(country: .us)
        let currencySetting = mockCurrencySetting(currency: .USD)
        let settingsSubject = CurrentValueSubject<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never>(
            (siteID: siteID, settings: [], source: .storageChange)
        )
        siteSettings.mockSettingsStream = settingsSubject.eraseToAnyPublisher()

        setupWooCommerceVersion("9.6.0")
        let checker = makeEligibilityChecker()

        // When - Call checkEligibility before site settings are available
        async let eligibilityTask = checker.checkEligibility(forceRemoteCheck: false)

        // Simulate site settings becoming available after methods are called. The stream is left
        // open so a late subscriber still receives the replayed value; the eligibility check
        // returns on the first matching value.
        Task {
            settingsSubject.send((siteID: siteID, settings: [countrySetting, currencySetting], source: .refresh))
        }

        let eligibilityResult = await eligibilityTask

        // Then - both methods should wait for site settings and return expected results.
        #expect(eligibilityResult == .eligible)
    }

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.USD),
        (country: Country.pr, currency: CurrencyCode.USD),
        (country: Country.gb, currency: CurrencyCode.GBP),
        (country: Country.ca, currency: CurrencyCode.CAD)
    ])
    fileprivate func is_eligible_when_all_conditions_satisfied(country: Country, currency: CurrencyCode) async throws {
        // Given
        setupCountry(country: country, currency: currency)
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [
        (country: Country.es, currency: CurrencyCode.EUR)
    ])
    fileprivate func is_ineligible_when_country_is_not_supported(country: Country, currency: CurrencyCode) async throws {
        // Given
        setupCountry(country: country, currency: currency)
        let checker = makeEligibilityChecker(expansionEligibilityService: ineligibleExpansionService)

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .siteSettingsNotAvailable))
    }

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.GBP, expectedSupportedCurrencies: [CurrencyCode.USD]),
        (country: Country.us, currency: CurrencyCode.CAD, expectedSupportedCurrencies: [CurrencyCode.USD]),
        (country: Country.gb, currency: CurrencyCode.EUR, expectedSupportedCurrencies: [CurrencyCode.GBP]),
        (country: Country.gb, currency: CurrencyCode.USD, expectedSupportedCurrencies: [CurrencyCode.GBP]),
        (country: Country.ca, currency: CurrencyCode.USD, expectedSupportedCurrencies: [CurrencyCode.CAD])
    ])
    fileprivate func is_ineligible_when_currency_is_not_supported(country: Country,
                                                                  currency: CurrencyCode,
                                                                  expectedSupportedCurrencies: [CurrencyCode]) async throws {
        // Given
        setupCountry(country: country, currency: currency)
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .unsupportedCurrency(countryCode: country.countryCode, supportedCurrencies: expectedSupportedCurrencies)))
    }

    func is_ineligible_when_woocommerce_version_is_below_minimum() async throws {
        // Given
        setupCountry(country: .us)
        setupWooCommerceVersion("9.5.0")
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta")))
    }

    func is_eligible_when_core_version_is_10_0_0_and_POS_feature_enabled() async throws {
        // Given
        setupCountry(country: .us)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: true)
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .eligible)
    }

    func is_ineligible_when_core_version_is_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        setupCountry(country: .us)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: false)
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    func is_eligible_when_core_version_is_below_10_0_0_and_POS_feature_disabled() async throws {
        // Given
        setupCountry(country: .us)
        setupWooCommerceVersion("9.9.9", featureSwitchEnabled: false)
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .eligible)
    }

    @Test func checkEligibility_returns_noInternetConnection_when_connectivity_is_not_reachable() async throws {
        // Given
        let offlineConnectivityObserver = MockConnectivityObserver()
        offlineConnectivityObserver.setStatus(.notReachable)
        let checker = makeEligibilityChecker(connectivityObserver: offlineConnectivityObserver)

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .noInternetConnection))
    }

    // MARK: - Offline Eligibility From Local State

    @Test func checkEligibility_returns_eligible_when_offline_with_synced_local_catalog() async throws {
        // Given
        let checker = makeOfflineCheckerWithSyncedCatalog()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .eligible)
    }

    @Test func checkEligibility_returns_noInternetConnection_when_offline_and_catalog_never_synced() async throws {
        // Given
        let checker = makeOfflineCheckerWithSyncedCatalog(hasCompletedFullSync: false)

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .noInternetConnection))
    }

    @Test func checkEligibility_returns_noInternetConnection_when_offline_and_local_catalog_feature_disabled() async throws {
        // Given
        let checker = makeOfflineCheckerWithSyncedCatalog(isLocalCatalogFeatureEnabled: false)

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .noInternetConnection))
    }

    @Test func checkEligibility_returns_noInternetConnection_when_offline_and_last_known_eligibility_is_false() async throws {
        // Given
        eligibilityService.cacheLastKnownPOSEligibility(siteID: siteID, isEligible: false)
        let checker = makeOfflineCheckerWithSyncedCatalog()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .noInternetConnection))
    }

    @Test func checkEligibility_returns_eligible_when_offline_and_cached_plugin_supports_POS() async throws {
        // Given: plugin data synced into local storage supports POS
        mockSystemStatusService.cachedPluginToReturn = createWooCommercePlugin(version: "9.6.0")
        let checker = makeOfflineCheckerWithSyncedCatalog()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .eligible)
    }

    @Test func checkEligibility_returns_noInternetConnection_when_offline_and_cached_plugin_is_inactive() async throws {
        // Given: plugin data synced into local storage shows WooCommerce was deactivated
        mockSystemStatusService.cachedPluginToReturn = createWooCommercePlugin(version: "9.6.0").copy(active: false)
        let checker = makeOfflineCheckerWithSyncedCatalog()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then: the locally known ineligibility blocks entry from local state
        #expect(result == .ineligible(reason: .noInternetConnection))
    }

    @Test func checkEligibility_returns_noInternetConnection_when_offline_and_cached_plugin_version_is_unsupported() async throws {
        // Given: plugin data synced into local storage shows an unsupported WooCommerce version
        mockSystemStatusService.cachedPluginToReturn = createWooCommercePlugin(version: "9.5.0")
        let checker = makeOfflineCheckerWithSyncedCatalog()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .noInternetConnection))
    }

    @Test func checkEligibility_falls_back_to_remote_check_when_online_and_cached_plugin_is_unsupported() async throws {
        // Given: local storage still holds an unsupported plugin, while the remote check finds
        // an updated, supported store
        mockSystemStatusService.cachedPluginToReturn = createWooCommercePlugin(version: "9.5.0")
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.6.0")
        let checker = makeEligibilityChecker(
            localCatalogEligibilityService: MockLocalCatalogEligibilityService(isLocalCatalogFeatureEnabled: true),
            syncStatusChecker: MockPOSCatalogSyncStatusChecker(hasCompletedFullSync: true)
        )

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then: the remote check ran instead of entering from local state
        #expect(result == .eligible)
    }

    @Test func checkEligibility_returns_eligible_from_local_state_when_online_with_synced_catalog() async throws {
        // Given: online, with a synced local catalog and no recorded ineligibility,
        // while the remote check would report a definite negative
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.5.0")
        let checker = makeEligibilityChecker(
            localCatalogEligibilityService: MockLocalCatalogEligibilityService(isLocalCatalogFeatureEnabled: true),
            syncStatusChecker: MockPOSCatalogSyncStatusChecker(hasCompletedFullSync: true)
        )

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then: entry comes from local state without waiting on the remote checks
        #expect(result == .eligible)
    }

    @Test func checkEligibility_revalidates_remotely_when_forceRemoteCheck_is_true() async throws {
        // Given: the same local state that allows entry, while the store became ineligible remotely
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.5.0")
        let checker = makeEligibilityChecker(
            localCatalogEligibilityService: MockLocalCatalogEligibilityService(isLocalCatalogFeatureEnabled: true),
            syncStatusChecker: MockPOSCatalogSyncStatusChecker(hasCompletedFullSync: true)
        )

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: true)

        // Then: the remote result wins and the definite negative is persisted
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta")))
        #expect(eligibilityService.loadLastKnownPOSEligibility(siteID: siteID) == false)
    }

    // MARK: - Last Known POS Eligibility Persistence

    @Test func checkEligibility_persists_positive_eligibility_from_online_check() async throws {
        // Given
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.6.0")
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .eligible)
        #expect(eligibilityService.loadLastKnownPOSEligibility(siteID: siteID) == true)
    }

    @Test func checkEligibility_persists_definite_ineligibility_from_online_check() async throws {
        // Given
        eligibilityService.cacheLastKnownPOSEligibility(siteID: siteID, isEligible: true)
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.5.0")
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0-beta")))
        #expect(eligibilityService.loadLastKnownPOSEligibility(siteID: siteID) == false)
    }

    @Test func checkEligibility_keeps_last_known_eligibility_on_indeterminate_result() async throws {
        // Given
        eligibilityService.cacheLastKnownPOSEligibility(siteID: siteID, isEligible: true)
        setupCountry(country: .us, currency: .USD)
        mockSystemStatusService.resultToReturn = .failure(URLError(.notConnectedToInternet))
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then: a check that could not determine eligibility does not downgrade the last known value
        #expect(result == .ineligible(reason: .noInternetConnection))
        #expect(eligibilityService.loadLastKnownPOSEligibility(siteID: siteID) == true)
    }

    @Test func checkEligibility_returns_noInternetConnection_when_system_status_request_fails_with_connectivity_error() async throws {
        // Given
        mockSystemStatusService.resultToReturn = .failure(URLError(.notConnectedToInternet))
        setupCountry(country: .us, currency: .USD)
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .noInternetConnection))
    }

    @Test func checkEligibility_returns_wooCommercePluginNotFound_when_system_status_request_fails_with_generic_error() async throws {
        // Given
        mockSystemStatusService.resultToReturn = .failure(NSError(domain: "test", code: 500))
        setupCountry(country: .us, currency: .USD)
        let checker = makeEligibilityChecker()

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .wooCommercePluginNotFound))
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

        let checker = makeEligibilityChecker()

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
                completion(NSError(domain: "test", code: 500)) // Generic error
            default:
                break
            }
        }

        let checker = makeEligibilityChecker()

        // When & Then - Should throw the generic error
        #expect(syncCalled == false) // Not called yet
        await #expect(throws: NSError.self) {
            try await checker.refreshEligibility(ineligibleReason: ineligibleReason)
        }
        #expect(syncCalled == true) // Called during the attempt
    }

    @Test func refreshEligibility_returns_noInternetConnection_when_site_settings_sync_fails_with_connectivity_error() async throws {
        // Given
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.6.0")

        var syncCalled = false
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .synchronizeGeneralSiteSettings(_, let completion):
                syncCalled = true
                completion(URLError(.notConnectedToInternet))
            default:
                break
            }
        }

        let checker = makeEligibilityChecker()

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: .siteSettingsNotAvailable)

        // Then
        #expect(syncCalled == true)
        #expect(result == .ineligible(reason: .noInternetConnection))
    }

    @Test func refreshEligibility_checks_eligibility_for_featureSwitchDisabled() async throws {
        // Given
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("10.0.0", featureSwitchEnabled: true)

        let checker = makeEligibilityChecker(siteSettingService: mockSiteSettingService)

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: .featureSwitchDisabled)

        // Then - Should check eligibility again (now eligible)
        #expect(result == .eligible)
    }

    @Test func refreshEligibility_checks_eligibility_for_selfDeallocated() async throws {
        // Given
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.6.0", featureSwitchEnabled: true)

        let checker = makeEligibilityChecker()

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: .selfDeallocated)

        // Then - Should check eligibility again (now eligible)
        #expect(result == .eligible)
    }

    @Test func refreshEligibility_rechecks_eligibility_for_noInternetConnection() async throws {
        // Given
        setupCountry(country: .us, currency: .USD)
        setupWooCommerceVersion("9.6.0", featureSwitchEnabled: true)

        let checker = makeEligibilityChecker()

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: .noInternetConnection)

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
        let checker = makeEligibilityChecker()

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
        let checker = makeEligibilityChecker()

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
        let checker = makeEligibilityChecker()

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
        let checker = makeEligibilityChecker()

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
        let checker = makeEligibilityChecker()

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
        let checker = makeEligibilityChecker()

        // When
        let result = try await checker.refreshEligibility(ineligibleReason: ineligibleReason)

        // Then
        #expect(result == .ineligible(reason: .wooCommercePluginNotFound))
    }

    // MARK: - IPP Country Expansion Gate Tests

    @Test(arguments: [
        (country: Country.nl, currency: CurrencyCode.EUR),
        (country: Country.sg, currency: CurrencyCode.SGD),
        (country: Country.nz, currency: CurrencyCode.NZD),
        (country: Country.au, currency: CurrencyCode.AUD)
    ])
    fileprivate func is_eligible_when_expansion_eligibility_is_enabled(country: Country, currency: CurrencyCode) async throws {
        // Given
        setupCountry(country: country, currency: currency)
        let checker = makeEligibilityChecker(expansionEligibilityService: eligibleExpansionService)

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .eligible)
    }

    @Test(arguments: [
        Country.nl,
        Country.sg,
        Country.nz,
        Country.au
    ])
    fileprivate func is_ineligible_when_expansion_eligibility_is_disabled(country: Country) async throws {
        // Given - currencies that would be valid if eligibility were enabled
        let currency: CurrencyCode = country == .sg ? .SGD : (country == .nz ? .NZD : (country == .au ? .AUD : .EUR))
        setupCountry(country: country, currency: currency)
        let checker = makeEligibilityChecker(expansionEligibilityService: ineligibleExpansionService)

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then - falls through with `siteSettingsNotAvailable` (the unsupportedCountry path is mapped here)
        #expect(result == .ineligible(reason: .siteSettingsNotAvailable))
    }

    @Test(arguments: [
        Country.at,
        Country.be,
        Country.de,
        Country.es,
        Country.fr,
        Country.it,
        Country.pt
    ])
    fileprivate func fiscalization_country_is_ineligible_when_expansion_eligibility_is_enabled(country: Country) async throws {
        // Given
        setupCountry(country: country, currency: .EUR)
        let checker = makeEligibilityChecker(expansionEligibilityService: eligibleExpansionService)

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then - falls through with `siteSettingsNotAvailable` (the unsupportedCountry path is mapped here)
        #expect(result == .ineligible(reason: .siteSettingsNotAvailable))
    }

    @Test func expansion_country_with_mismatched_currency_is_ineligible_when_expansion_eligibility_is_enabled() async throws {
        // Given - NL store with USD currency (mismatch)
        setupCountry(country: .nl, currency: .USD)
        let checker = makeEligibilityChecker(expansionEligibilityService: eligibleExpansionService)

        // When
        let result = await checker.checkEligibility(forceRemoteCheck: false)

        // Then
        #expect(result == .ineligible(reason: .unsupportedCurrency(countryCode: .NL, supportedCurrencies: [.EUR])))
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

private extension POSTabEligibilityCheckerTests {
    func makeEligibilityChecker(
        siteSettingService: POSSiteSettingServiceProtocol? = nil,
        connectivityObserver: ConnectivityObserver? = nil,
        expansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol =
            CardPresentPaymentsCountryExpansionEligibilityService(),
        localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol? = nil,
        syncStatusChecker: POSCatalogSyncStatusCheckerProtocol = MockPOSCatalogSyncStatusChecker(hasCompletedFullSync: false)
    ) -> POSTabEligibilityChecker {
        POSTabEligibilityChecker(siteID: siteID,
                                 siteSettings: siteSettings,
                                 stores: stores,
                                 systemStatusService: mockSystemStatusService,
                                 siteSettingService: siteSettingService,
                                 connectivityObserver: connectivityObserver ?? self.connectivityObserver,
                                 expansionEligibilityService: expansionEligibilityService,
                                 eligibilityService: eligibilityService,
                                 localCatalogEligibilityService: localCatalogEligibilityService,
                                 syncStatusChecker: syncStatusChecker)
    }

    /// Sets up an offline environment where the local catalog completed a full sync.
    func makeOfflineCheckerWithSyncedCatalog(
        isLocalCatalogFeatureEnabled: Bool = true,
        hasCompletedFullSync: Bool = true
    ) -> POSTabEligibilityChecker {
        let offlineConnectivityObserver = MockConnectivityObserver()
        offlineConnectivityObserver.setStatus(.notReachable)
        return makeEligibilityChecker(
            connectivityObserver: offlineConnectivityObserver,
            localCatalogEligibilityService: MockLocalCatalogEligibilityService(isLocalCatalogFeatureEnabled: isLocalCatalogFeatureEnabled),
            syncStatusChecker: MockPOSCatalogSyncStatusChecker(hasCompletedFullSync: hasCompletedFullSync)
        )
    }

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
        case pr = "PR"
        case at = "AT"
        case be = "BE"
        case ca = "CA:NS"
        case gb = "GB"
        case es = "ES"
        case de = "DE"
        case fr = "FR"
        case it = "IT"
        case nl = "NL"
        case pt = "PT"
        case sg = "SG"
        case nz = "NZ"
        case au = "AU"

        var countryCode: CountryCode {
            switch self {
            case .us:
                return .US
            case .pr:
                return .PR
            case .at:
                return .AT
            case .be:
                return .BE
            case .ca:
                return .CA
            case .gb:
                return .GB
            case .es:
                return .ES
            case .de:
                return .DE
            case .fr:
                return .FR
            case .it:
                return .IT
            case .nl:
                return .NL
            case .pt:
                return .PT
            case .sg:
                return .SG
            case .nz:
                return .NZ
            case .au:
                return .AU
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
    var cachedPluginToReturn: SystemPlugin?

    func loadWooCommercePluginAndPOSFeatureSwitch(siteID: Int64) async throws -> POSPluginAndFeatureInfo {
        switch resultToReturn {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        }
    }

    @MainActor
    func loadCachedWooCommercePlugin(siteID: Int64) -> SystemPlugin? {
        cachedPluginToReturn
    }
}

/// Mock local catalog eligibility service for the offline eligibility gate,
/// which only consults `isLocalCatalogFeatureEnabled`.
private actor MockLocalCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol {
    private let isLocalCatalogFeatureEnabledResult: Bool

    init(isLocalCatalogFeatureEnabled: Bool) {
        self.isLocalCatalogFeatureEnabledResult = isLocalCatalogFeatureEnabled
    }

    func catalogEligibility(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        .eligible
    }

    func updatePOSEligibility(isEligible: Bool, for siteID: Int64) async {}

    func refreshEligibilityState(for siteID: Int64) async -> POSLocalCatalogEligibilityState {
        .eligible
    }

    func isLocalCatalogFeatureEnabled() async -> Bool {
        isLocalCatalogFeatureEnabledResult
    }
}

/// Mock sync status checker for the offline eligibility gate.
private struct MockPOSCatalogSyncStatusChecker: POSCatalogSyncStatusCheckerProtocol {
    let hasCompletedFullSync: Bool

    func hasCompletedFullSync(for siteID: Int64) async -> Bool {
        hasCompletedFullSync
    }
}
