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

    func test_onboarding_returns_generic_error_with_no_account() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)

        let plugin = wcPayPluginBase
            .copy(
                status: .active,
                version: "2.5"
            )
        storageManager.insertSampleSitePlugin(readOnlySitePlugin: plugin)

        // When
        let useCase = CardPresentPaymentsOnboardingUseCase(storageManager: storageManager, stores: stores)
        let state = useCase.checkOnboardingState()

        // Then
        XCTAssertEqual(state, .genericError)
    }

    func test_onboarding_returns_generic_error_when_account_is_not_eligible() {
        // Given
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: supportedCountrySetting)

        let plugin = wcPayPluginBase
            .copy(
                status: .active,
                version: "2.5"
            )
        storageManager.insertSampleSitePlugin(readOnlySitePlugin: plugin)
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

        let plugin = wcPayPluginBase
            .copy(
                status: .active,
                version: "2.5"
            )
        storageManager.insertSampleSitePlugin(readOnlySitePlugin: plugin)
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

private extension CardPresentPaymentsOnboardingUseCaseTests {
    var wcPayPluginBase: SitePlugin {
        SitePlugin
            .fake()
            .copy(
                siteID: sampleSiteID,
                plugin: "woocommerce-payments",
                name: "WooCommerce Payments"
            )
    }

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
