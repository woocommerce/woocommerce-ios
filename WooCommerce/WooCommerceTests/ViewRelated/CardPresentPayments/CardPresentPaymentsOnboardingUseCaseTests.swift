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

    // MARK: - Plugin checks

    func test_onboarding_returns_wcpay_not_installed_without_wcpay_plugin() {
        // Given
        setupCountry(country: .us)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .wcpayNotInstalled)

    }

    func test_onboarding_returns_wcpay_not_activated_when_wcpay_installed_but_not_active() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .inactive, version: .minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .wcpayNotActivated)
    }

    func test_onboarding_returns_wcpay_unsupported_version_when_unpatched_wcpay_outdated() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .unsupportedVersionWithoutPatch)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .wcpayUnsupportedVersion)
    }

    func test_onboarding_returns_wcpay_unsupported_version_when_patched_wcpay_outdated() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .unsupportedVersionWithPatch)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .wcpayUnsupportedVersion)
    }

    func test_onboarding_returns_complete_when_plugin_version_matches_minimum_exactly() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .networkActive, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_plugin_version_has_newer_patch_release() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .networkActive, version: .supportedVersionWithPatch)
        setupPaymentGatewayAccount(status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_plugin_version_has_newer_unpatched_release() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .networkActive, version: .supportedVersionWithoutPatch)
        setupPaymentGatewayAccount(status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_active() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .networkActive, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_network_active() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .networkActive, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .complete)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .completed)
    }

    // MARK: - Payment Account checks

    func test_onboarding_returns_generic_error_with_no_account() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_generic_error_when_account_is_not_eligible() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .complete, isCardPresentEligible: false)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_not_completed_when_account_is_not_connected() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .noAccount)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .wcpaySetupNotCompleted)
    }

    func test_onboarding_returns_pending_requirements_when_account_is_restricted_with_pending_requirements() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .restricted, hasPendingRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountPendingRequirement(deadline: nil))
    }

    func test_onboarding_returns_pending_requirements_when_account_is_restricted_soon_with_pending_requirements() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .restrictedSoon, hasPendingRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountPendingRequirement(deadline: nil))
    }

    func test_onboarding_returns_overdue_requirements_when_account_is_restricted_with_overdue_requirements() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .restricted, hasOverdueRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountOverdueRequirement)
    }

    func test_onboarding_returns_overdue_requirements_when_account_is_restricted_with_overdue_and_pending_requirements() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .restricted, hasPendingRequirements: true, hasOverdueRequirements: true)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountOverdueRequirement)
    }

    func test_onboarding_returns_review_when_account_is_restricted_with_no_requirements() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .restricted)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountUnderReview)
    }


    func test_onboarding_returns_rejected_when_account_is_rejected_for_fraud() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .rejectedFraud)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected)
    }

    func test_onboarding_returns_rejected_when_account_is_rejected_for_tos() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .rejectedTermsOfService)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected)
    }

    func test_onboarding_returns_rejected_when_account_is_listed() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .rejectedListed)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected)
    }

    func test_onboarding_returns_rejected_when_account_is_rejected_for_other_reasons() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .rejectedOther)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .stripeAccountRejected)
    }

    func test_onboarding_returns_generic_error_when_account_status_unknown() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .unknown)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.state

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_complete_when_account_is_setup_successfully() {
        // Given
        setupCountry(country: .us)
        setupPlugin(status: .active, version: .minimumSupportedVersion)
        setupPaymentGatewayAccount(status: .complete)

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
        case es = "ES"
    }
}

// MARK: - Plugin helpers
private extension CardPresentPaymentsOnboardingUseCaseTests {
    func setupPlugin(status: SitePluginStatusEnum, version: PluginVersion) {
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

    enum PluginVersion: String {
        case unsupportedVersionWithPatch = "2.4.2"
        case unsupportedVersionWithoutPatch = "3.2"
        case minimumSupportedVersion = "3.2.1" /// Should match `minimumSupportedWCPayVersion` in `CardPresentPaymentsOnboardingUseCase`
        case supportedVersionWithPatch = "3.2.5"
        case supportedVersionWithoutPatch = "3.3"
    }
}

// MARK: - Account helpers
private extension CardPresentPaymentsOnboardingUseCaseTests {
    func setupPaymentGatewayAccount(
        status: WCPayAccountStatusEnum,
        hasPendingRequirements: Bool = false,
        hasOverdueRequirements: Bool = false,
        isCardPresentEligible: Bool = true
    ) {
        let paymentGatewayAccount = PaymentGatewayAccount
            .fake()
            .copy(
                siteID: sampleSiteID,
                gatewayID: WCPayAccount.gatewayID,
                status: status.rawValue,
                hasPendingRequirements: hasPendingRequirements,
                hasOverdueRequirements: hasOverdueRequirements,
                isCardPresentEligible: isCardPresentEligible
            )
        storageManager.insertSamplePaymentGatewayAccount(readOnlyAccount: paymentGatewayAccount)
    }
}
