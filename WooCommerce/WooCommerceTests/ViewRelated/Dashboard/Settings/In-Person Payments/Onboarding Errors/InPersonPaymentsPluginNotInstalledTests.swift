import Testing
@testable import WooCommerce

struct InPersonPaymentsPluginNotInstalledTests {

    @Test func test_buttonViewModel_when_userIsAdministrator_then_install_CTA_is_shown() {
        // Given
        let view = InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: true, onInstall: {})

        // When
        let buttonViewModel = view.buttonViewModel

        // Then
        #expect(buttonViewModel != nil)
    }

    @Test func test_buttonViewModel_when_user_is_not_administrator_then_install_CTA_is_hidden() {
        // Given
        let view = InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: false, onInstall: {})

        // When
        let buttonViewModel = view.buttonViewModel

        // Then
        #expect(buttonViewModel == nil)
    }

    @Test func test_message_when_user_is_not_administrator_then_it_differs_from_the_administrator_message() {
        // Given
        let administratorView = InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: true, onInstall: {})
        let nonAdministratorView = InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: false, onInstall: {})

        // When
        let administratorMessage = administratorView.message
        let nonAdministratorMessage = nonAdministratorView.message

        // Then
        #expect(administratorMessage != nonAdministratorMessage)
    }
}
