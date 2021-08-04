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
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_country_unsupported_with_unsupported_country() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: unsupportedCountrySetting)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .countryNotSupported)
    }

    // MARK: - Plugin checks

    func test_onboarding_returns_wcpay_not_installed_without_wcpay_plugin() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .wcpayNotInstalled)

    }

    func test_onboarding_returns_wcpay_not_activated_when_wcpay_installed_but_not_active() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)
        setupPlugin(status: .inactive, version: .supported)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .wcpayNotActivated)
    }

    func test_onboarding_returns_wcpay_unsupported_version_when_wcpay_outdated() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)
        setupPlugin(status: .active, version: .unsupported)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .wcpayUnsupportedVersion)
    }

    func test_onboarding_returns_complete_when_supported_exact() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)

        setupPlugin(status: .networkActive, version: .supportedExact)
        let paymentGatewayAccount = PaymentGatewayAccount
            .fake()
            .copy(
                siteID: sampleSiteID,
                isCardPresentEligible: true
            )
        storageManager.insertSamplePaymentGatewayAccount(readOnlyAccount: paymentGatewayAccount)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_active() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)

        setupPlugin(status: .networkActive, version: .supported)
        let paymentGatewayAccount = PaymentGatewayAccount
            .fake()
            .copy(
                siteID: sampleSiteID,
                isCardPresentEligible: true
            )
        storageManager.insertSamplePaymentGatewayAccount(readOnlyAccount: paymentGatewayAccount)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .completed)
    }

    func test_onboarding_returns_complete_when_network_active() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)

        setupPlugin(status: .networkActive, version: .supported)
        let paymentGatewayAccount = PaymentGatewayAccount
            .fake()
            .copy(
                siteID: sampleSiteID,
                isCardPresentEligible: true
            )
        storageManager.insertSamplePaymentGatewayAccount(readOnlyAccount: paymentGatewayAccount)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .completed)
    }

    // MARK: - Payment Account checks

    func test_onboarding_returns_generic_error_with_no_account() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)

        setupPlugin(status: .active, version: .supported)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_generic_error_when_account_is_not_eligible() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)

        setupPlugin(status: .active, version: .supported)
        let paymentGatewayAccount = PaymentGatewayAccount
            .fake()
            .copy(
                siteID: sampleSiteID,
                isCardPresentEligible: false
            )
        storageManager.insertSamplePaymentGatewayAccount(readOnlyAccount: paymentGatewayAccount)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_complete_when_account_is_setup_successfully() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)

        setupPlugin(status: .active, version: .supported)
        let paymentGatewayAccount = PaymentGatewayAccount
            .fake()
            .copy(
                siteID: sampleSiteID,
                isCardPresentEligible: true
            )
        storageManager.insertSamplePaymentGatewayAccount(readOnlyAccount: paymentGatewayAccount)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .completed)
    }
}

// MARK: - Country helpers
private extension CardPresentPaymentsOnboardingUseCaseTests {
    var countrySettingBase: SiteSetting {
        SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
    }

    var supportedCountrySetting: SiteSetting {
        countrySettingBase.copy(value: "US:CA")
    }

    var unsupportedCountrySetting: SiteSetting {
        countrySettingBase.copy(value: "ES")
    }
}

// MARK: - Plugin helpers
private extension CardPresentPaymentsOnboardingUseCaseTests {
    func setupPlugin(status: SitePluginStatusEnum, version: PluginVersion) {
        let plugin = SitePlugin
            .fake()
            .copy(
                siteID: sampleSiteID,
                plugin: "woocommerce-payments",
                status: status,
                name: "WooCommerce Payments",
                version: version.rawValue
            )
        storageManager.insertSampleSitePlugin(readOnlySitePlugin: plugin)
    }

    enum PluginVersion: String {
        case supported = "2.6.1"
        case supportedExact = "2.5"
        case unsupported = "2.4.2"
    }
}
