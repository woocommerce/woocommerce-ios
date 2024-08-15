import XCTest
import Fakes
import Yosemite
@testable import WooCommerce

class CardPresentPaymentsOnboardingUseCaseTests: XCTestCase {
    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    private var onboardingStateCache: CardPresentPaymentOnboardingStateCache!

    /// Mock Stores
    ///
    private var stores: MockStoresManager!

    /// Mock Analytics
    ///
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Preferred payment gateways
    ///
    private var preferredInPersonPaymentGatewayBySite = [Int64: String]()

    private var skippedCodOnboardingStep = true

    override func setUpWithError() throws {
        try super.setUpWithError()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        onboardingStateCache = CardPresentPaymentOnboardingStateCache()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.sessionManager.setStoreId(sampleSiteID)
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings(stores: stores, storageManager: storageManager))
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .setPreferredInPersonPaymentGateway(let siteID, let gateway):
                self.preferredInPersonPaymentGatewayBySite[siteID] = gateway
            case .getPreferredInPersonPaymentGateway(let siteID, let onCompletion):
                onCompletion(self.preferredInPersonPaymentGatewayBySite[siteID])
            case .forgetPreferredInPersonPaymentGateway:
                break
            case .setSkippedCashOnDeliveryOnboardingStep:
                break
            case .getSkippedCashOnDeliveryOnboardingStep(_, let completion):
                completion(self.skippedCodOnboardingStep)
                break
            default:
                fatalError("Not available")
            }
        }
    }

    override func tearDownWithError() throws {
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings())
        storageManager.reset()
        onboardingStateCache = nil
        storageManager = nil
        stores = nil
        analyticsProvider = nil
        analytics = nil
        preferredInPersonPaymentGatewayBySite.removeAll()
        try super.tearDownWithError()
    }

    // MARK: - Country checks

    func test_onboarding_returns_generic_error_with_no_country() {
        // Given

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_country_unsupported_with_unsupported_country() {
        // Given
        setupCountry(country: .es)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .countryNotSupported(countryCode: .ES))
    }

    func test_onboarding_does_not_return_country_unsupported_with_canada_when_neither_wcpay_nor_stripe_plugin_installed() {
        // Given
        setupCountry(country: .ca)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertNotEqual(state, .countryNotSupported(countryCode: .CA))
    }

    func test_onboarding_returns_country_unsupported_with_canada_when_stripe_plugin_installed() {
        // Given
        setupCountry(country: .ca)
        setupStripePlugin(status: .active, version: .minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .countryNotSupportedStripe(plugin: .stripe, countryCode: .CA))
    }

    func test_onboarding_returns_setup_not_completed_stripe_when_stripe_and_wcPay_plugins_are_installed_in_Canada() {
        // Given
        setupCountry(country: .ca)
        setupStripePlugin(status: .active, version: .minimumSupportedVersion)
        setupWCPayPlugin(status: .active, version: .minimumSupportedVersionCanada)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .wcPay))
    }

    func test_onboarding_returns_wcpay_plugin_unsupported_version_for_canada_when_version_unsupported() {
        // Given
        setupCountry(country: .ca)
        setupWCPayPlugin(status: .active, version: .unsupportedVersionCanada)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginUnsupportedVersion(plugin: .wcPay))
    }

    func test_onboarding_does_not_return_plugin_unsupported_version_for_canada_when_version_is_supported() {
        // Given
        setupCountry(country: .ca)
        setupWCPayPlugin(status: .active, version: .minimumSupportedVersionCanada)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertNotEqual(state, .pluginUnsupportedVersion(plugin: .wcPay))
    }

    func test_onboarding_returns_country_unsupported_with_canada_for_stripe() {
        // Given
        setupCountry(country: .ca)
        setupStripePlugin(status: .active, version: .minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertNotEqual(state, .countryNotSupported(countryCode: .CA))
    }

    func test_onboarding_does_not_return_country_unsupported_with_uk_when_neither_wcpay_nor_stripe_plugin_installed() {
        // Given
        setupCountry(country: .gb)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertNotEqual(state, .countryNotSupported(countryCode: .GB))
    }

    func test_onboarding_returns_country_unsupported_with_uk_when_stripe_plugin_installed() {
        // Given
        setupCountry(country: .gb)
        setupStripePlugin(status: .active, version: .minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .countryNotSupportedStripe(plugin: .stripe, countryCode: .GB))
    }

    func test_onboarding_returns_setup_not_completed_stripe_when_stripe_and_wcPay_plugins_are_installed_in_UK() {
        // Given
        setupCountry(country: .gb)
        setupStripePlugin(status: .active, version: .minimumSupportedVersion)
        setupWCPayPlugin(status: .active, version: .minimumSupportedVersionUK)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .wcPay))
    }

    func test_onboarding_returns_wcpay_plugin_unsupported_version_for_uk_when_version_unsupported() {
        // Given
        setupCountry(country: .gb)
        setupWCPayPlugin(status: .active, version: .unsupportedVersionUK)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginUnsupportedVersion(plugin: .wcPay))
    }

    func test_onboarding_does_not_return_plugin_unsupported_version_for_uk_when_version_is_supported() {
        // Given
        setupCountry(country: .gb)
        setupWCPayPlugin(status: .active, version: .minimumSupportedVersionUK)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertNotEqual(state, .pluginUnsupportedVersion(plugin: .wcPay))
    }

    func test_onboarding_returns_country_unsupported_with_uk_for_stripe() {
        // Given
        setupCountry(country: .gb)
        setupStripePlugin(status: .active, version: .minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertNotEqual(state, .countryNotSupported(countryCode: .GB))
    }


    // MARK: - Plugin checks

    func test_onboarding_returns_plugin_not_installed_when_neither_wcpay_nor_stripe_plugin_installed() {
        // Given
        setupCountry(country: .us)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginNotInstalled)

    }

    func test_onboarding_sends_install_plugin_action_for_wcpay_plugin_when_installPlugin_is_invoked_then_installs_wcpay_plugin() throws {
        // Given
        setupCountry(country: .us)
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)

        // When
        useCase.installCardPresentPlugin()

        // Then
        let action = try XCTUnwrap(stores.receivedActions.last as? SitePluginAction)

        switch action {
        case let .installSitePlugin(_, slug, _):
            XCTAssertEqual(slug, "woocommerce-payments")
        default:
            XCTFail("Did not send installSitePlugin SitePluginAction")
        }
    }

    func test_onboarding_returns_wcpay_plugin_not_activated_when_wcpay_installed_but_not_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .inactive, version: WCPayPluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginNotActivated(plugin: .wcPay))
    }

    func test_onboarding_returns_stripe_plugin_not_activated_when_stripe_installed_but_not_active() {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .inactive, version: StripePluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginNotActivated(plugin: .stripe))
    }

    func test_onboarding_returns_select_wcpay_plugin_not_activated_when_both_stripe_and_wcpay_plugins_are_installed_but_not_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .inactive, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .inactive, version: StripePluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginNotActivated(plugin: .wcPay))
    }

    func test_onboarding_returns_select_plugin_when_both_stripe_and_wcpay_plugins_are_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .selectPlugin(pluginSelectionWasCleared: false))
    }

    func test_onboarding_uses_selected_plugin_wcpay_when_both_stripe_and_wcpay_plugins_are_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        XCTAssertEqual(useCase.state, .selectPlugin(pluginSelectionWasCleared: false))
        useCase.selectPlugin(.wcPay)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .wcPay))
    }

    func test_onboarding_uses_selected_plugin_stripe_when_both_stripe_and_wcpay_plugins_are_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        XCTAssertEqual(useCase.state, .selectPlugin(pluginSelectionWasCleared: false))
        useCase.selectPlugin(.stripe)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .stripe))
    }

    func test_onboarding_when_clearing_plugin_selection_then_sets_right_state() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        XCTAssertEqual(useCase.state, .selectPlugin(pluginSelectionWasCleared: false))
        useCase.selectPlugin(.stripe)
        useCase.clearPluginSelection()

        // Then
        XCTAssertEqual(useCase.state, .selectPlugin(pluginSelectionWasCleared: true))
    }

    func test_onboarding_uses_preferred_plugin_wcpay_when_both_stripe_and_wcpay_plugins_are_active_and_preferred_plugin_is_not_complete() {
        // Given
        setupCountry(country: .us)
        // Stripe is fully set up and WCPay isn't but there's a stored preference to use WCPay
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: StripeAccount.self, status: .complete)
        setupPreferredPaymentGateway(.wcPay)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .wcPay))
    }

    func test_onboarding_returns_complete_with_wcpay_when_both_stripe_and_wcpay_plugins_are_active_and_has_stored_preference() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)
        setupPreferredPaymentGateway(.wcPay)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .wcPayPreferred))
    }

    func test_onboarding_uses_preferred_plugin_stripe_when_both_stripe_and_wcpay_plugins_are_active_and_preferred_plugin_is_not_complete() {
        // Given
        setupCountry(country: .us)
        // WCPay is fully set up and Stripe isn't but there's a stored preference to use Stripe
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)
        setupPreferredPaymentGateway(.stripe)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .stripe))
    }

    func test_onboarding_returns_complete_with_stripe_when_both_stripe_and_wcpay_plugins_are_active_and_has_stored_preference() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: StripeAccount.self, status: .complete)
        setupPreferredPaymentGateway(.stripe)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .stripePreferred))
    }
    func test_onboarding_returns_wcpay_plugin_unsupported_version_when_unpatched_wcpay_outdated() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.unsupportedVersionWithoutPatch)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginUnsupportedVersion(plugin: .wcPay))
    }

    func test_onboarding_returns_stripe_plugin_unsupported_version_when_stripe_outdated() {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .active, version: StripePluginVersion.unsupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginUnsupportedVersion(plugin: .stripe))
    }

    func test_onboarding_returns_wcpay_in_test_mode_with_live_stripe_account_when_live_account_in_test_mode() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete, isLive: true, isInTestMode: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginInTestModeWithLiveStripeAccount(plugin: .wcPay))
    }

    func test_onboarding_returns_stripe_in_test_mode_with_live_stripe_account_when_live_account_in_test_mode() {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: StripeAccount.self, status: .complete, isLive: true, isInTestMode: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginInTestModeWithLiveStripeAccount(plugin: .stripe))
    }

    func test_onboarding_returns_wcpay_unsupported_version_when_patched_wcpay_plugin_outdated() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.unsupportedVersionWithPatch)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginUnsupportedVersion(plugin: .wcPay))
    }

    func test_onboarding_returns_complete_when_wcpay_plugin_version_matches_minimum_exactly() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .networkActive, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .wcPayOnly))
    }

    func test_onboarding_returns_complete_when_wcpay_plugin_version_has_newer_patch_release() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .networkActive, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .wcPayOnly))
    }

    func test_onboarding_returns_complete_when_wcpay_plugin_version_has_newer_unpatched_release() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .networkActive, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .wcPayOnly))
    }

    func test_onboarding_returns_complete_when_wcpay_active_and_stripe_plugin_installed_but_not_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .inactive, version: StripePluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .wcPayOnly))
    }

    func test_onboarding_returns_complete_when_stripe_active_and_wcpay_plugin_installed_but_not_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .inactive, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: StripeAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .stripeOnly))
    }

    func test_onboarding_returns_complete_when_wcpay_plugin_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .wcPayOnly))
    }

    func test_onboarding_returns_complete_when_wcpay_plugin_is_network_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .networkActive, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .wcPayOnly))
    }

    func test_onboarding_sends_use_wcpay_account_action_when_wcpay_plugin_is_used_with_an_account_meeting_requirements() throws {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .networkActive, version: WCPayPluginVersion.minimumSupportedVersion)
        let paymentGatewayAccount = setupPaymentGatewayAccount(accountType: WCPayAccount.self,
                                                               status: .complete,
                                                               hasPendingRequirements: false,
                                                               hasOverdueRequirements: false,
                                                               isLive: true,
                                                               isInTestMode: false)

        // When
        _ = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores, cardPresentPaymentOnboardingStateCache: onboardingStateCache)

        // Then

        let action = try XCTUnwrap(stores.receivedActions.last as? CardPresentPaymentAction)

        switch action {
        case .use(let account):
            XCTAssertEqual(account, paymentGatewayAccount)
        default:
            XCTFail("Completing onboarding did not send use account CardPresentPaymentAction")
        }
    }

    func test_onboarding_returns_complete_when_stripe_plugin_is_used_with_an_account_meeting_requirements() {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .networkActive, version: StripePluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: StripeAccount.self,
                                   status: .complete,
                                   hasPendingRequirements: false,
                                   hasOverdueRequirements: false,
                                   isLive: true,
                                   isInTestMode: false)


        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .stripeOnly))
    }

    func test_onboarding_sends_use_stripe_account_action_when_stripe_plugin_is_used_with_an_account_meeting_requirements() throws {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .networkActive, version: StripePluginVersion.minimumSupportedVersion)
        let paymentGatewayAccount = setupPaymentGatewayAccount(accountType: StripeAccount.self,
                                                               status: .complete,
                                                               hasPendingRequirements: false,
                                                               hasOverdueRequirements: false,
                                                               isLive: true,
                                                               isInTestMode: false)

        // When
        _ = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores, cardPresentPaymentOnboardingStateCache: onboardingStateCache)

        // Then

        let action = try XCTUnwrap(stores.receivedActions.last as? CardPresentPaymentAction)

        switch action {
        case .use(let account):
            XCTAssertEqual(account, paymentGatewayAccount)
        default:
            XCTFail("Completing onboarding did not send use account CardPresentPaymentAction")
        }
    }

    // MARK: - Payment Account checks

    func test_onboarding_returns_plugin_setup_not_completed_with_nil_account_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)

        // When
        // i.e. getPaymentGatewayAccount returns nil account
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .wcPay))
    }

    func test_onboarding_returns_plugin_setup_not_completed_with_no_account_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .noAccount, hasPendingRequirements: false)

        // When
        // i.e. getPaymentGatewayAccount returns status.noAccount
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .wcPay))
    }

    func test_onboarding_returns_plugin_setup_not_completed_with_nil_account_for_stripe_plugin() {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)

        // When
        // i.e. getPaymentGatewayAccount returns nil account
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .stripe))
    }

    func test_onboarding_returns_plugin_setup_not_completed_with_no_account_for_stripe_plugin() {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: StripeAccount.self, status: .noAccount, hasPendingRequirements: false)

        // When
        // i.e. getPaymentGatewayAccount returns status.noAccount
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted(plugin: .stripe))
    }

    func test_onboarding_returns_pending_requirements_when_account_is_restricted_with_pending_requirements_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restricted, hasPendingRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountPendingRequirement(plugin: .wcPay, deadline: nil))
    }

    func test_onboarding_returns_pending_requirements_when_account_is_restricted_soon_with_pending_requirements_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restrictedSoon, hasPendingRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state
        // Then
        XCTAssertEqual(state, .stripeAccountPendingRequirement(plugin: .wcPay, deadline: nil))
    }

    func test_onboarding_when_account_is_restricted_soon_with_pending_requirements_skipped_for_wcpay_plugin_returns_complete() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restrictedSoon, hasPendingRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)

        useCase.skipPendingRequirements()
        useCase.updateState()

        let state = useCase.state
        // Then
        XCTAssertEqual(state, .completed(plugin: CardPresentPaymentsPluginState(preferred: .wcPay, available: [.wcPay])))
    }

    func test_onboarding_returns_complete_when_account_status_is_enabled_using_wcpay_plugin() {
        // Given
        let accountStatus: WCPayAccountStatusEnum = .enabled

        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: accountStatus)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: CardPresentPaymentsPluginState(preferred: .wcPay, available: [.wcPay])))
    }

    func test_onboarding_returns_complete_when_account_status_is_pending_verification_using_wcpay_plugin() {
        // Given
        let accountStatus: WCPayAccountStatusEnum = .pendingVerification

        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: accountStatus)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: CardPresentPaymentsPluginState(preferred: .wcPay, available: [.wcPay])))
    }

    func test_onboarding_returns_complete_when_account_status_is_enabled_using_stripe_plugin() {
        // Given
        let accountStatus: WCPayAccountStatusEnum = .enabled

        setupCountry(country: .us)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: StripeAccount.self, status: accountStatus)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: CardPresentPaymentsPluginState(preferred: .stripe, available: [.stripe])))
    }

    func test_onboarding_returns_overdue_requirements_when_account_is_restricted_with_overdue_requirements_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restricted, hasOverdueRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountOverdueRequirement(plugin: .wcPay))
    }

    func test_onboarding_returns_overdue_requirements_when_account_is_restricted_with_overdue_and_pending_requirements_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restricted, hasPendingRequirements: true, hasOverdueRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountOverdueRequirement(plugin: .wcPay))
    }

    func test_onboarding_returns_review_when_account_is_restricted_with_no_requirements_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restricted)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountUnderReview(plugin: .wcPay))
    }


    func test_onboarding_returns_rejected_when_account_is_rejected_for_fraud_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .rejectedFraud)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected(plugin: .wcPay))
    }

    func test_onboarding_returns_rejected_when_account_is_rejected_for_tos_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .rejectedTermsOfService)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected(plugin: .wcPay))
    }

    func test_onboarding_returns_rejected_when_account_is_listed_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .rejectedListed)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected(plugin: .wcPay))
    }

    func test_onboarding_returns_rejected_when_account_is_rejected_for_other_reasons_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .rejectedOther)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected(plugin: .wcPay))
    }

    func test_onboarding_returns_enable_COD_prompt_when_cod_disabled_and_not_skipped() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)
        setupCodPaymentGateway(enabled: false)
        skippedCodOnboardingStep = false

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        assertEqual(.codPaymentGatewayNotSetUp(plugin: .wcPay), state)
    }

    func test_onboarding_returns_complete_when_cod_disabled_and_cod_step_was_skipped() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)
        setupCodPaymentGateway(enabled: false)
        skippedCodOnboardingStep = true

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        assertEqual(.completed(plugin: .wcPayOnly), state)
    }

    func test_onboarding_returns_complete_when_cod_enabled() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)
        setupCodPaymentGateway(enabled: true)
        skippedCodOnboardingStep = false

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        assertEqual(.completed(plugin: .wcPayOnly), state)
    }

    func test_onboarding_returns_generic_error_when_account_status_unknown_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .unknown)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_complete_when_account_is_setup_successfully_for_wcpay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed(plugin: .wcPayOnly))
    }

    func test_refreshIfNecessary_when_there_is_a_completed_cached_value_then_returns_cached_value() {
        onboardingStateCache.update(.completed(plugin: .stripeOnly))

        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache)
        useCase.refreshIfNecessary()

        XCTAssertEqual(useCase.state, onboardingStateCache.value)
    }

    func test_installCardPresentPlugin_when_failure_to_install_plugin_then_event_is_tracked_with_correct_properties() throws {
        // Given
        setupCountry(country: .us)
        let expectedEvent = "card_present_onboarding_cta_failed"
        let expectedReason = "plugin_install_tapped"
        let expectedError = NSError(domain: "Dotcom Error: Plugin not found", code: 0)
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache, analytics: analytics)

        // When
        stores.whenReceivingAction(ofType: SitePluginAction.self, thenCall: { action in
            switch action {
            case .installSitePlugin(_, _, let onCompletion):
                onCompletion(.failure(expectedError))
            default:
                break
            }
        })
        useCase.installCardPresentPlugin()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, [expectedEvent])

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == expectedEvent }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])

        XCTAssertEqual(eventProperties["reason"] as? String, expectedReason)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["error_description"] as? String, expectedError.description)
    }

    func test_activateCardPresentPlugin_when_failure_to_activate_plugin_then_event_is_tracked_with_correct_properties() throws {
        // Given
        setupCountry(country: .us)
        let expectedEvent = "card_present_onboarding_cta_failed"
        let expectedReason = "plugin_activate_tapped"
        let expectedError = NSError(domain: "Dotcom Error: Plugin not found", code: 0)
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager,
                                                           stores: stores,
                                                           cardPresentPaymentOnboardingStateCache: onboardingStateCache, analytics: analytics)

        // When
        stores.whenReceivingAction(ofType: SitePluginAction.self, thenCall: { action in
            switch action {
            case .activateSitePlugin(_, _, let onCompletion):
                onCompletion(.failure(expectedError))
            default:
                break
            }
        })
        useCase.activateCardPresentPlugin()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, [expectedEvent])

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == expectedEvent }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])

        XCTAssertEqual(eventProperties["reason"] as? String, expectedReason)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["error_description"] as? String, expectedError.description)
    }
}

// MARK: - Settings helpers
private extension CardPresentPaymentsOnboardingUseCaseTests {
    func setupPreferredPaymentGateway(_ gateway: CardPresentPaymentsPlugin) {
        let action = AppSettingsAction.setPreferredInPersonPaymentGateway(siteID: sampleSiteID, gateway: gateway.gatewayID)
        stores.dispatch(action)
    }
}

// MARK: - Country helpers
private extension CardPresentPaymentsOnboardingUseCaseTests {
    func setupCountry(country: Country) {
        let setting = SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                value: country.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        ServiceLocator.selectedSiteSettings.refresh()
    }

    enum Country: String {
        case us = "US:CA"
        case ca = "CA:NS"
        case gb = "GB"
        case es = "ES"
    }
}

// MARK: - Plugin helpers
private extension CardPresentPaymentsOnboardingUseCaseTests {
    func setupWCPayPlugin(status: SitePluginStatusEnum, version: WCPayPluginVersion) {
        let active = status == .active || status == .networkActive
        let networkActivated = status == .networkActive
        let plugin = SystemPlugin
            .fake()
            .copy(
                siteID: sampleSiteID,
                plugin: "woocommerce-payments/woocommerce-payments.php",
                name: "WooCommerce Payments",
                version: version.rawValue,
                networkActivated: networkActivated,
                active: active
            )
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: plugin)
    }

    func setupStripePlugin(status: SitePluginStatusEnum, version: StripePluginVersion) {
        let active = status == .active || status == .networkActive
        let networkActivated = status == .networkActive
        let plugin = SystemPlugin
            .fake()
            .copy(
                siteID: sampleSiteID,
                plugin: "woocommerce-gateway-stripe/woocommerce-gateway-stripe.php",
                name: "WooCommerce Stripe Gateway",
                version: version.rawValue,
                networkActivated: networkActivated,
                active: active
            )
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: plugin)
    }

    enum WCPayPluginVersion: String {
        case unsupportedVersionWithPatch = "2.4.2"
        case unsupportedVersionWithoutPatch = "3.2"
        case unsupportedVersionCanada = "3.9.0"
        case unsupportedVersionUK = "4.3.0"
        case minimumSupportedVersion = "3.2.1" // Should match `CardPresentPaymentsConfiguration` `minimumSupportedPluginVersion` for the US
        case minimumSupportedVersionCanada = "4.0.0" // Should match `CardPresentPaymentsConfiguration` `minimumSupportedPluginVersion` for Canada
        case minimumSupportedVersionUK = "4.4.0" // Should match `CardPresentPaymentsConfiguration` `minimumSupportedPluginVersion` for UK
        case supportedVersionWithPatch = "3.2.5"
        case supportedVersionWithoutPatch = "3.3"
    }

    enum StripePluginVersion: String {
        case minimumSupportedVersion = "6.2.0" // Should match `CardPresentPaymentsConfiguration` `minimumSupportedPluginVersion`
        case unsupportedVersion = "6.1.0"
    }

}

// MARK: - Account helpers
private extension CardPresentPaymentsOnboardingUseCaseTests {
    @discardableResult
    func setupPaymentGatewayAccount(
        accountType: GatewayAccountProtocol.Type,
        status: WCPayAccountStatusEnum,
        hasPendingRequirements: Bool = false,
        hasOverdueRequirements: Bool = false,
        isLive: Bool = false,
        isInTestMode: Bool = false,
        isCardPresentEligible: Bool = true
    ) -> PaymentGatewayAccount {
        let paymentGatewayAccount = PaymentGatewayAccount
            .fake()
            .copy(
                siteID: sampleSiteID,
                gatewayID: accountType.gatewayID,
                status: status.rawValue,
                hasPendingRequirements: hasPendingRequirements,
                hasOverdueRequirements: hasOverdueRequirements,
                isCardPresentEligible: isCardPresentEligible,
                isLive: isLive,
                isInTestMode: isInTestMode
            )
        storageManager.insertSamplePaymentGatewayAccount(readOnlyAccount: paymentGatewayAccount)
        return paymentGatewayAccount
    }
}

private protocol GatewayAccountProtocol {
    static var gatewayID: String { get }
}

extension WCPayAccount: GatewayAccountProtocol {}
extension StripeAccount: GatewayAccountProtocol {}

// MARK: - Gateway helpers
private extension CardPresentPaymentsOnboardingUseCaseTests {
    @discardableResult
    func setupCodPaymentGateway(
        enabled: Bool = true,
        title: String = "",
        description: String = ""
    ) -> PaymentGateway {
        let paymentGateway = PaymentGateway
            .fake()
            .copy(
                siteID: sampleSiteID,
                gatewayID: PaymentGateway.Constants.cashOnDeliveryGatewayID,
                title: title,
                description: description,
                enabled: enabled
            )
        storageManager.insertSamplePaymentGateway(readOnlyGateway: paymentGateway)
        return paymentGateway
    }
}
