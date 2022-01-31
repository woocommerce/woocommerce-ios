import XCTest
import Fakes
import Yosemite
@testable import WooCommerce

class CardPresentPaymentsOnboardingUseCaseTests: XCTestCase {
    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Stores
    ///
    private var stores: MockStoresManager!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUpWithError() throws {
        try super.setUpWithError()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .loadStripeInPersonPaymentsSwitchState(let completion):
                completion(.success(true))
            default:
                break
            }
        }
        stores.sessionManager.setStoreId(sampleSiteID)
    }

    override func tearDownWithError() throws {
        storageManager = nil
        stores = nil
        try super.tearDownWithError()
    }

    // MARK: - Country checks

    func test_onboarding_returns_generic_error_with_no_country() {
        // Given

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_country_unsupported_with_unsupported_country() {
        // Given
        setupCountry(country: .es)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .countryNotSupported(countryCode: "ES"))
    }

    func test_onboarding_does_not_return_country_unsupported_with_canada_when_neither_wcpay_nor_stripe_plugin_installed() {
        // Given
        setupCountry(country: .ca)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertNotEqual(state, .countryNotSupported(countryCode: "CA"))
    }

    func test_onboarding_does_not_return_country_unsupported_with_canada_for_wcpay() {
        // Given
        setupCountry(country: .ca)
        setupWCPayPlugin(status: .active, version: .minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertNotEqual(state, .countryNotSupported(countryCode: "CA"))
    }

    func test_onboarding_returns_country_unsupported_with_canada_for_stripe() {
        // Given
        setupCountry(country: .es)
        setupStripePlugin(status: .active, version: .minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertNotEqual(state, .countryNotSupported(countryCode: "CA"))
    }


    // MARK: - Plugin checks

    func test_onboarding_returns_plugin_not_installed_when_neither_wcpay_nor_stripe_plugin_installed() {
        // Given
        setupCountry(country: .us)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginNotInstalled)

    }

    func test_onboarding_returns_wcpay_plugin_not_activated_when_wcpay_installed_but_not_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .inactive, version: WCPayPluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginNotActivated(plugin: .wcPay))
    }

    func test_onboarding_returns_stripe_plugin_not_activated_when_stripe_installed_but_not_active() {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .inactive, version: StripePluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginNotActivated(plugin: .stripe))
    }

    func test_onboarding_returns_select_plugin_when_both_stripe_and_wcpay_plugins_are_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .selectPlugin)
    }

    func test_onboarding_returns_wcpay_plugin_unsupported_version_when_unpatched_wcpay_outdated() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.unsupportedVersionWithoutPatch)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginUnsupportedVersion(plugin: .wcPay))
    }

    func test_onboarding_returns_stripe_plugin_unsupported_version_when_stripe_outdated() {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .active, version: StripePluginVersion.unsupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginUnsupportedVersion(plugin: .stripe))
    }

    func test_onboarding_returns_wcpay_in_test_mode_with_live_stripe_account_when_live_account_in_test_mode() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: StripeAccount.self, status: .complete, isLive: true, isInTestMode: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
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
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginInTestModeWithLiveStripeAccount(plugin: .stripe))
    }

    func test_onboarding_returns_wcpay_unsupported_version_when_patched_wcpay_plugin_outdated() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.unsupportedVersionWithPatch)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
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
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_wcpay_plugin_version_has_newer_patch_release() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .networkActive, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_wcpay_plugin_version_has_newer_unpatched_release() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .networkActive, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_wcpay_plugin_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_wcpay_plugin_is_network_active() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .networkActive, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
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
        _ = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)

        // Then
        XCTAssertEqual(stores.receivedActions.count, 2)
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
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
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
        _ = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)

        // Then
        XCTAssertEqual(stores.receivedActions.count, 2)
        let action = try XCTUnwrap(stores.receivedActions.last as? CardPresentPaymentAction)

        switch action {
        case .use(let account):
            XCTAssertEqual(account, paymentGatewayAccount)
        default:
            XCTFail("Completing onboarding did not send use account CardPresentPaymentAction")
        }
    }

    // MARK: - Payment Account checks

    func test_onboarding_returns_generic_error_with_no_account_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_generic_error_with_no_account_for_stripe_plugin() {
        // Given
        setupCountry(country: .us)
        setupStripePlugin(status: .active, version: StripePluginVersion.minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_generic_error_when_account_is_not_eligible_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete, isCardPresentEligible: false)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_not_completed_when_account_is_not_connected_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .noAccount)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .pluginSetupNotCompleted)
    }

    func test_onboarding_returns_pending_requirements_when_account_is_restricted_with_pending_requirements_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restricted, hasPendingRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountPendingRequirement(deadline: nil))
    }

    func test_onboarding_returns_pending_requirements_when_account_is_restricted_soon_with_pending_requirements_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restrictedSoon, hasPendingRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountPendingRequirement(deadline: nil))
    }

    func test_onboarding_returns_overdue_requirements_when_account_is_restricted_with_overdue_requirements_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restricted, hasOverdueRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountOverdueRequirement)
    }

    func test_onboarding_returns_overdue_requirements_when_account_is_restricted_with_overdue_and_pending_requirements_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restricted, hasPendingRequirements: true, hasOverdueRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountOverdueRequirement)
    }

    func test_onboarding_returns_review_when_account_is_restricted_with_no_requirements_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .restricted)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountUnderReview)
    }


    func test_onboarding_returns_rejected_when_account_is_rejected_for_fraud_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .rejectedFraud)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected)
    }

    func test_onboarding_returns_rejected_when_account_is_rejected_for_tos_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .rejectedTermsOfService)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected)
    }

    func test_onboarding_returns_rejected_when_account_is_listed_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .rejectedListed)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected)
    }

    func test_onboarding_returns_rejected_when_account_is_rejected_for_other_reasons_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .rejectedOther)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected)
    }

    func test_onboarding_returns_generic_error_when_account_status_unknown_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .unknown)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_complete_when_account_is_setup_successfully_for_wcplay_plugin() {
        // Given
        setupCountry(country: .us)
        setupWCPayPlugin(status: .active, version: WCPayPluginVersion.minimumSupportedVersion)
        setupPaymentGatewayAccount(accountType: WCPayAccount.self, status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
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
    }

    enum Country: String {
        case us = "US:CA"
        case ca = "CA:NS"
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
                plugin: "woocommerce-payments",
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
                plugin: "woocommerce-gateway-stripe",
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
        case minimumSupportedVersion = "3.2.1" // Should match `CardPresentPaymentsOnboardingState` `minimumSupportedPluginVersion`
        case supportedVersionWithPatch = "3.2.5"
        case supportedVersionWithoutPatch = "3.3"
    }

    enum StripePluginVersion: String {
        case minimumSupportedVersion = "5.9.0" // Should match `CardPresentPaymentsOnboardingState` `minimumSupportedPluginVersion`
        case unsupportedVersion = "5.8.1"
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
