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
        (country: Country.pr, currency: CurrencyCode.USD),
        (country: Country.gb, currency: CurrencyCode.GBP),
        (country: Country.ca, currency: CurrencyCode.CAD)
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
        (country: Country.es, currency: CurrencyCode.EUR),
        (country: Country.au, currency: CurrencyCode.AUD)
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
        (country: Country.gb, currency: CurrencyCode.USD),
        (country: Country.ca, currency: CurrencyCode.USD)
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

    @Test func is_visible_for_expansion_country_when_expansion_flag_enabled_even_with_empty_cache() async throws {
        // Given - NL (an expansion country) with an empty expansion-eligibility cache,
        // and the country-expansion remote feature flag enabled.
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .nl, currency: .EUR)
        accountWhitelistedInBackend(true, expansionFlagsEnabled: true)
        let expansionEligibilityService = MockCardPresentPaymentsCountryExpansionEligibilityService()
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              expansionEligibilityService: expansionEligibilityService)

        // When
        let result = await checker.checkVisibility()

        // Then - checkVisibility refreshes the expansion eligibility cache before validating,
        // so NL is reported as visible without requiring a prior pre-warm.
        #expect(result == true)
        #expect(expansionEligibilityService.isEligible(siteID: siteID) == true)
    }

    @Test func is_invisible_for_spain_when_expansion_flag_enabled_even_with_empty_cache() async throws {
        // Given - ES is a removed fiscalization country, even when the expansion flag is enabled.
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .es, currency: .EUR)
        accountWhitelistedInBackend(true, expansionFlagsEnabled: true)
        let expansionEligibilityService = MockCardPresentPaymentsCountryExpansionEligibilityService()
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              expansionEligibilityService: expansionEligibilityService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func is_visible_for_australia_when_au_feature_flag_enabled_even_with_empty_cache() async throws {
        // Given - AU with an empty country-eligibility cache and the AU remote feature flag enabled.
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .au, currency: .AUD)
        accountWhitelistedInBackend(true, australiaWooPaymentsFlagEnabled: true)
        let expansionEligibilityService = MockCardPresentPaymentsCountryExpansionEligibilityService()
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              expansionEligibilityService: expansionEligibilityService)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
        #expect(expansionEligibilityService.isEligible(siteID: siteID) == true)
    }

    @Test func is_visible_on_iPad_when_operating_system_is_below_iOS_26_and_all_conditions_satisfied() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .gb, currency: .GBP)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              isOperatingSystemAtLeast: { _ in false })

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test func is_invisible_for_australia_when_au_feature_flag_disabled_even_if_expansion_flags_are_enabled() async throws {
        // Given - AU must be controlled by its own remote feature flag, not the broader expansion flags.
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .au, currency: .AUD)
        accountWhitelistedInBackend(true, expansionFlagsEnabled: true, australiaWooPaymentsFlagEnabled: false)
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

    @Test func is_invisible_for_expansion_country_when_expansion_flag_disabled() async throws {
        // Given - NL (an expansion country) with the country-expansion remote feature flag disabled.
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: .nl, currency: .EUR)
        accountWhitelistedInBackend(true, expansionFlagsEnabled: false)
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
        // New settings - makes site ineligible (unsupported expansion country).
        let newSettings = [
            mockCountrySetting(country: .es),
            mockCurrencySetting(currency: .EUR)
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

        // Then - Should be invisible because fresh settings show unsupported ES (not cached US)
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

    @Test(arguments: phoneSupportedCountries)
    func is_visible_when_device_is_phone_and_phonePrototype_flag_enabled_for_supported_country(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSalePhonePrototype] = true
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .phone,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              isOperatingSystemAtLeast: { _ in true })

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test(arguments: phoneSupportedCountries)
    func is_invisible_when_device_is_phone_and_operating_system_is_below_iOS_26_for_supported_country(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSalePhonePrototype] = true
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .phone,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              isOperatingSystemAtLeast: { _ in false })

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test(arguments: [
        (country: Country.us, currency: CurrencyCode.USD),
        (country: Country.pr, currency: CurrencyCode.USD),
        (country: Country.ca, currency: CurrencyCode.CAD)
    ])
    func is_invisible_when_device_is_phone_and_store_is_supported_non_uk_country(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSalePhonePrototype] = true
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .phone,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              isOperatingSystemAtLeast: { _ in true })

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func is_visible_when_device_is_phone_and_US_store_and_phonePointOfSaleUS_flag_enabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSalePhonePrototype] = true
        setupCountry(country: .us, currency: .USD)
        accountWhitelistedInBackend(true, phonePointOfSaleUSFlagEnabled: true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .phone,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              isOperatingSystemAtLeast: { _ in true })

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == true)
    }

    @Test(arguments: [
        (country: Country.pr, currency: CurrencyCode.USD),
        (country: Country.ca, currency: CurrencyCode.CAD)
    ])
    func is_invisible_when_device_is_phone_and_non_US_store_even_if_phonePointOfSaleUS_flag_enabled(country: Country,
                                                                                                   currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSalePhonePrototype] = true
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true, phonePointOfSaleUSFlagEnabled: true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .phone,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              isOperatingSystemAtLeast: { _ in true })

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func is_invisible_when_device_is_phone_and_store_is_expansion_country() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSalePhonePrototype] = true
        setupCountry(country: .nl, currency: .EUR)
        accountWhitelistedInBackend(true, expansionFlagsEnabled: true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .phone,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              isOperatingSystemAtLeast: { _ in true })

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test(arguments: phoneSupportedCountries)
    func is_invisible_when_device_is_phone_and_phonePrototype_flag_disabled_for_supported_country(country: Country, currency: CurrencyCode) async throws {
        // Given
        let featureFlagService = MockFeatureFlagService()
        setupCountry(country: country, currency: currency)
        accountWhitelistedInBackend(true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .phone,
                                              siteSettings: siteSettings,
                                              stores: stores,
                                              featureFlagService: featureFlagService,
                                              isOperatingSystemAtLeast: { _ in true })

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

    // MARK: - Offline `checkVisibility` Tests

    @Test func checkVisibility_returns_cached_visibility_when_offline_and_cached_visible() async throws {
        // Given
        let connectivityObserver = MockConnectivityObserver()
        connectivityObserver.setStatus(.notReachable)
        setupPOSTabVisibility(siteID: siteID, isVisible: true)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              eligibilityService: eligibilityService,
                                              stores: stores,
                                              connectivityObserver: connectivityObserver)

        // When
        let result = await checker.checkVisibility()

        // Then: the cached value is returned without dispatching remote feature flag checks
        #expect(result == true)
        #expect(stores.receivedActions.contains { $0 is FeatureFlagAction } == false)
    }

    @Test func checkVisibility_returns_cached_visibility_when_offline_and_cached_hidden() async throws {
        // Given
        let connectivityObserver = MockConnectivityObserver()
        connectivityObserver.setStatus(.notReachable)
        setupPOSTabVisibility(siteID: siteID, isVisible: false)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              eligibilityService: eligibilityService,
                                              stores: stores,
                                              connectivityObserver: connectivityObserver)

        // When
        let result = await checker.checkVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkVisibility_performs_full_check_when_connectivity_is_unknown() async throws {
        // Given: connectivity is unknown (e.g. before the first path update at cold start),
        // remote checks pass while the cached visibility is hidden
        let connectivityObserver = MockConnectivityObserver()
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupPOSTabVisibility(siteID: siteID, isVisible: false)
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              siteSettings: siteSettings,
                                              eligibilityService: eligibilityService,
                                              stores: stores,
                                              connectivityObserver: connectivityObserver,
                                              expansionEligibilityService: MockCardPresentPaymentsCountryExpansionEligibilityService())

        // When
        let result = await checker.checkVisibility()

        // Then: the full check ran instead of falling back to the cached value
        #expect(result == true)
        #expect(stores.receivedActions.contains { $0 is FeatureFlagAction })
    }

    // MARK: - `checkInitialVisibility Tests

    @Test func checkInitialVisibility_returns_true_when_cached_tab_visibility_is_enabled() async throws {
        // Given
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              eligibilityService: eligibilityService,
                                              stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: true)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == true)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_disabled() async throws {
        // Given
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              eligibilityService: eligibilityService,
                                              stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: false)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkInitialVisibility_returns_false_when_cached_tab_visibility_is_unavailable() async throws {
        // Given
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .pad,
                                              eligibilityService: eligibilityService,
                                              stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: nil)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func checkInitialVisibility_returns_false_on_phone_when_cached_tab_visibility_is_enabled() async throws {
        // Given
        let checker = POSTabVisibilityChecker(site: site,
                                              userInterfaceIdiom: .phone,
                                              eligibilityService: eligibilityService,
                                              stores: stores)
        setupPOSTabVisibility(siteID: siteID, isVisible: true)

        // When
        let result = checker.checkInitialVisibility()

        // Then
        #expect(result == false)
    }

    @Test func static_checkInitialVisibility_returns_true_on_iPad_when_cached_tab_visibility_is_enabled() async throws {
        // Given
        setupPOSTabVisibility(siteID: siteID, isVisible: true)

        // When
        let result = POSTabVisibilityChecker.checkInitialVisibility(for: siteID,
                                                                    userInterfaceIdiom: .pad,
                                                                    eligibilityService: eligibilityService)

        // Then
        #expect(result == true)
    }

    @Test func static_checkInitialVisibility_returns_false_on_phone_when_cached_tab_visibility_is_enabled() async throws {
        // Given
        setupPOSTabVisibility(siteID: siteID, isVisible: true)

        // When
        let result = POSTabVisibilityChecker.checkInitialVisibility(for: siteID,
                                                                    userInterfaceIdiom: .phone,
                                                                    eligibilityService: eligibilityService)

        // Then
        #expect(result == false)
    }
}

extension POSTabVisibilityCheckerTests {
    nonisolated static let phoneSupportedCountries: [(country: Country, currency: CurrencyCode)] = [
        (country: .gb, currency: .GBP)
    ]

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

    /// Configures the mock stores to respond to `FeatureFlagAction.isRemoteFeatureFlagEnabled`.
    /// `isAllowed` controls the `.pointOfSale` flag (whitelisting).
    /// `expansionFlagsEnabled` controls the existing IPP country-expansion flags.
    /// `australiaWooPaymentsFlagEnabled` separately controls the AU WooPayments flag.
    /// `phonePointOfSaleUSFlagEnabled` controls the flag opening Phone POS to US stores.
    func accountWhitelistedInBackend(_ isAllowed: Bool = false,
                                     expansionFlagsEnabled: Bool = false,
                                     australiaWooPaymentsFlagEnabled: Bool = false,
                                     phonePointOfSaleUSFlagEnabled: Bool = false) {
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(flag, _, _, completion):
                switch flag {
                case .pointOfSale:
                    completion(isAllowed)
                case .inPersonPaymentsCountryExpansion, .inPersonPaymentsCountryExpansionEUExtended:
                    completion(expansionFlagsEnabled)
                case .inPersonPaymentsAustraliaWooPayments:
                    completion(australiaWooPaymentsFlagEnabled)
                case .phonePointOfSaleUS:
                    completion(phonePointOfSaleUSFlagEnabled)
                default:
                    completion(false)
                }
            }
        }
    }

    func setupPOSTabVisibility(siteID: Int64, isVisible: Bool?) {
        eligibilityService.cachedTabVisibility[siteID] = isVisible
    }

    enum Country: String {
        case us = "US:CA"
        case pr = "PR"
        case ca = "CA:NS"
        case gb = "GB"
        case es = "ES"
        case nl = "NL"
        case au = "AU"

        var countryCode: CountryCode {
            switch self {
            case .us:
                return .US
            case .pr:
                return .PR
            case .ca:
                return .CA
            case .gb:
                return .GB
            case .es:
                return .ES
            case .nl:
                return .NL
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
