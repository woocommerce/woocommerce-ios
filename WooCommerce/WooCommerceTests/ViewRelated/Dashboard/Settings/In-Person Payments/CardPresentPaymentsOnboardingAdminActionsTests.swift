import Foundation
import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct CardPresentPaymentsOnboardingAdminActionsTests {
    @Test(arguments: [true, false])
    func test_pluginManagementURL_when_role_is_checked_then_only_administrator_can_open_plugins(_ isAdministrator: Bool) {
        // Given
        let model = makeViewModel(isAdministrator: isAdministrator)

        // When
        let url = model.pluginManagementURL

        // Then
        #expect(url?.absoluteString == (isAdministrator ? "https://example.com/wp-admin/plugins.php" : nil))
    }

    @Test(arguments: [CardPresentPaymentsPlugin.wcPay, .stripe])
    func test_paymentSettingsURL_when_administrator_then_opens_selected_plugin_settings(_ plugin: CardPresentPaymentsPlugin) {
        // Given
        let model = makeViewModel(isAdministrator: true)
        let section = plugin == .wcPay ? "woocommerce_payments" : "stripe&panel=settings"

        // When
        let url = model.paymentSettingsURL(for: plugin)

        // Then
        #expect(url?.absoluteString == "https://example.com/wp-admin/admin.php?page=wc-settings&tab=checkout&section=" + section)
    }

    @Test(arguments: [CardPresentPaymentsPlugin.wcPay, .stripe])
    func test_paymentSettingsURL_when_not_administrator_then_no_admin_action_is_available(_ plugin: CardPresentPaymentsPlugin) {
        // Given
        let model = makeViewModel(isAdministrator: false)

        // When
        let url = model.paymentSettingsURL(for: plugin)

        // Then
        #expect(url == nil)
    }

    @Test func test_admin_actions_when_store_is_missing_then_no_admin_action_is_available() {
        // Given
        let model = makeViewModel(isAdministrator: true, site: nil)

        // When
        let pluginsURL = model.pluginManagementURL
        let settingsURL = model.paymentSettingsURL(for: .wcPay)

        // Then
        #expect(pluginsURL == nil)
        #expect(settingsURL == nil)
    }

    @Test(arguments: ["", "wp-admin/"])
    func test_admin_actions_when_admin_url_is_not_absolute_then_no_admin_action_is_available(_ adminURL: String) {
        // Given
        let model = makeViewModel(isAdministrator: true, site: Site.fake().copy(adminURL: adminURL))

        // When
        let pluginsURL = model.pluginManagementURL
        let settingsURL = model.paymentSettingsURL(for: .stripe)

        // Then
        #expect(pluginsURL == nil)
        #expect(settingsURL == nil)
    }

    private func makeViewModel(isAdministrator: Bool,
                               site: Site? = Site.fake().copy(adminURL: "https://example.com/wp-admin/")) -> CardPresentPaymentsOnboardingViewModel {
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)
        return CardPresentPaymentsOnboardingViewModel(fixedState: .loading,
                                                       fixedUserIsAdministrator: isAdministrator,
                                                       useCase: MockCardPresentPaymentsOnboardingUseCase(initial: .loading),
                                                       stores: stores)
    }
}
