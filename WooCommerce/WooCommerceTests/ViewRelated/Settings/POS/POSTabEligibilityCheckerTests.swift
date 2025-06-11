import Testing
import XCTest
import WooFoundation
import Yosemite
@testable import WooCommerce

@MainActor
struct POSTabEligibilityCheckerTests {
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var siteSettings: SelectedSiteSettings!
    private let siteID: Int64 = 2

    init() async throws {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        setupWooCommerceVersion()
        storageManager = MockStorageManager()
        siteSettings = SelectedSiteSettings(stores: stores, storageManager: storageManager)
    }

    @Test("When all conditions are satisfied, returns eligible")
    func test_is_eligible_when_all_conditions_satisfied() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .eligible)
    }

    @Test("When account is not whitelisted and feature flag is disabled, returns ineligible")
    func test_is_eligible_when_account_not_whitelisted_and_feature_flag_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: false)
        setupCountry(country: .us)
        accountWhitelistedInBackend(false)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .featureFlagDisabled))
    }

    @Test("When non-iPad device, returns ineligible")
    func test_is_eligible_when_non_ipad_device() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .phone,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .notTablet))
    }

    @Test("When non-US site, returns ineligible")
    func test_is_eligible_when_non_us_site() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .ca)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedCountry))
    }

    @Test("When non-USD currency, returns ineligible")
    func test_is_eligible_when_non_usd_currency() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.nonUSDCurrencySettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedCurrency))
    }

    @Test("When WooCommerce version is below minimum, returns ineligible")
    func test_is_eligible_when_woocommerce_version_below_minimum() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isPointOfSaleEnabled: true)
        setupCountry(country: .us)
        accountWhitelistedInBackend(true)
        setupWooCommerceVersion("9.5.0")
        let checker = POSTabEligibilityChecker(siteID: siteID,
                                               userInterfaceIdiom: .pad,
                                               siteSettings: siteSettings,
                                               currencySettings: Fixtures.usdCurrencySettings,
                                               stores: stores,
                                               featureFlagService: featureFlagService)

        // When
        let result = await checker.checkEligibility()

        // Then
        #expect(result == .ineligible(reason: .unsupportedWooCommerceVersion))
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
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        siteSettings.refresh()
    }

    func setupWooCommerceVersion(_ version: String = "9.6.0-beta") {
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case .fetchSystemPlugin(_, _, let completion):
                completion(SystemPlugin.fake().copy(name: "WooCommerce", version: version, active: true))
            default:
                break
            }
        }
    }

    func accountWhitelistedInBackend(_ isAllowed: Bool = false) {
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case .isRemoteFeatureFlagEnabled(_, _, completion: let completion):
                completion(isAllowed)
            }
        }
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
