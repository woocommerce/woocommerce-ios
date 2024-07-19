import Combine
import WooFoundation
import XCTest
import Yosemite
@testable import WooCommerce

final class POSEligibilityCheckerTests: XCTestCase {
    private var onboardingUseCase: MockCardPresentPaymentsOnboardingUseCase!
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var siteSettings: SelectedSiteSettings!
    @Published private var isEligible: Bool = false

    private let siteID: Int64 = 2

    override func setUp() {
        super.setUp()
        onboardingUseCase = MockCardPresentPaymentsOnboardingUseCase(initial: .completed(plugin: .wcPayPreferred))
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.updateDefaultStore(storeID: siteID)
        setupWooCommerceVersion()
        storageManager = MockStorageManager()
        siteSettings = SelectedSiteSettings(stores: stores, storageManager: storageManager)
    }

    override func tearDown() {
        siteSettings = nil
        storageManager = nil
        stores = nil
        onboardingUseCase = nil
        super.tearDown()
    }

    func test_is_eligible_when_all_conditions_satisfied_then_returns_true() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDisplayPointOfSaleToggleEnabled: true)
        setupCountry(country: .us)
        let checker = POSEligibilityChecker(userInterfaceIdiom: .pad,
                                            cardPresentPaymentsOnboarding: onboardingUseCase,
                                            siteSettings: siteSettings,
                                            currencySettings: Fixtures.usdCurrencySettings,
                                            stores: stores,
                                            featureFlagService: featureFlagService)
        checker.isEligible.assign(to: &$isEligible)

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_is_eligible_when_non_iPad_device_then_returns_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDisplayPointOfSaleToggleEnabled: true)
        setupCountry(country: .us)
        [UIUserInterfaceIdiom.phone, UIUserInterfaceIdiom.mac, UIUserInterfaceIdiom.tv, UIUserInterfaceIdiom.carPlay]
            .forEach { userInterfaceIdiom in
                let checker = POSEligibilityChecker(userInterfaceIdiom: userInterfaceIdiom,
                                                    cardPresentPaymentsOnboarding: onboardingUseCase,
                                                    siteSettings: siteSettings,
                                                    currencySettings: Fixtures.usdCurrencySettings,
                                                    stores: stores,
                                                    featureFlagService: featureFlagService)
                checker.isEligible.assign(to: &$isEligible)

                // Then
                XCTAssertFalse(isEligible)
            }
    }

    func test_is_eligible_when_non_us_site_then_returns_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDisplayPointOfSaleToggleEnabled: true)
        [Country.ca, Country.es, Country.gb].forEach { country in
            // When
            setupCountry(country: country)
            let checker = POSEligibilityChecker(userInterfaceIdiom: .pad,
                                                cardPresentPaymentsOnboarding: onboardingUseCase,
                                                siteSettings: siteSettings,
                                                currencySettings: Fixtures.usdCurrencySettings,
                                                stores: stores,
                                                featureFlagService: featureFlagService)
            checker.isEligible.assign(to: &$isEligible)

            // Then
            XCTAssertFalse(isEligible)
        }
    }

    func test_is_eligible_when_non_usd_currency_then_returns_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDisplayPointOfSaleToggleEnabled: true)
        setupCountry(country: .us)
        let checker = POSEligibilityChecker(userInterfaceIdiom: .pad,
                                            cardPresentPaymentsOnboarding: onboardingUseCase,
                                            siteSettings: siteSettings,
                                            currencySettings: Fixtures.nonUSDCurrencySettings,
                                            stores: stores,
                                            featureFlagService: featureFlagService)
        checker.isEligible.assign(to: &$isEligible)

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_is_eligible_when_feature_flag_is_disabled_then_returns_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDisplayPointOfSaleToggleEnabled: false)
        setupCountry(country: .us)
        let checker = POSEligibilityChecker(userInterfaceIdiom: .pad,
                                            cardPresentPaymentsOnboarding: onboardingUseCase,
                                            siteSettings: siteSettings,
                                            currencySettings: Fixtures.usdCurrencySettings,
                                            stores: stores,
                                            featureFlagService: featureFlagService)
        checker.isEligible.assign(to: &$isEligible)

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_is_eligible_when_onboarding_state_is_not_completed_wcpay_then_returns_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDisplayPointOfSaleToggleEnabled: true)
        setupCountry(country: .us)
        let checker = POSEligibilityChecker(userInterfaceIdiom: .pad,
                                            cardPresentPaymentsOnboarding: onboardingUseCase,
                                            siteSettings: siteSettings,
                                            currencySettings: Fixtures.usdCurrencySettings,
                                            stores: stores,
                                            featureFlagService: featureFlagService)
        checker.isEligible.assign(to: &$isEligible)
        XCTAssertTrue(isEligible)

        // When onboarding state is loading
        onboardingUseCase.state = .loading
        // Then
        XCTAssertFalse(isEligible)

        // When onboarding state is stripeOnly
        onboardingUseCase.state = .completed(plugin: .stripeOnly)
        // Then
        XCTAssertFalse(isEligible)

        // When onboarding state is wcPayOnly
        onboardingUseCase.state = .completed(plugin: .wcPayOnly)
        // Then
        XCTAssertTrue(isEligible)

        // When onboarding state is stripePreferred
        onboardingUseCase.state = .completed(plugin: .stripePreferred)
        // Then
        XCTAssertFalse(isEligible)

        // When onboarding state is pluginNotInstalled
        onboardingUseCase.state = .pluginNotInstalled
        // Then
        XCTAssertFalse(isEligible)
    }

    func test_is_eligible_when_WooCommerce_version_is_below_6_6_then_returns_false() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDisplayPointOfSaleToggleEnabled: true)
        setupCountry(country: .us)

        // Unsupported WooCommerce version
        setupWooCommerceVersion("6.5.0")

        // When
        let checker = POSEligibilityChecker(userInterfaceIdiom: .pad,
                                            cardPresentPaymentsOnboarding: onboardingUseCase,
                                            siteSettings: siteSettings,
                                            currencySettings: Fixtures.usdCurrencySettings,
                                            stores: stores,
                                            featureFlagService: featureFlagService)
        checker.isEligible.assign(to: &$isEligible)

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_is_eligible_when_WooCommerce_version_is_above_6_6_then_returns_true() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDisplayPointOfSaleToggleEnabled: true)
        setupCountry(country: .us)

        // Supported WooCommerce version
        setupWooCommerceVersion("6.6.0")

        // When
        let checker = POSEligibilityChecker(userInterfaceIdiom: .pad,
                                            cardPresentPaymentsOnboarding: onboardingUseCase,
                                            siteSettings: siteSettings,
                                            currencySettings: Fixtures.usdCurrencySettings,
                                            stores: stores,
                                            featureFlagService: featureFlagService)
        checker.isEligible.assign(to: &$isEligible)

        // Then
        XCTAssertTrue(isEligible)
    }
}

private extension POSEligibilityCheckerTests {
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

    func setupWooCommerceVersion(_ version: String = "6.6.0") {
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case .fetchSystemPlugin(_, _, let completion):
                completion(SystemPlugin.fake().copy(name: "WooCommerce", version: version, active: true))
            default:
                break
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
