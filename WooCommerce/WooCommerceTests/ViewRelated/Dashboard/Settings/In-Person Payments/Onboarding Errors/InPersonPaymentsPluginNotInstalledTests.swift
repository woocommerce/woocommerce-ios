import Testing
@testable import WooCommerce

struct InPersonPaymentsPluginNotInstalledTests {

    @Test func test_buttonViewModel_when_userIsAdministrator_then_install_action_is_called() {
        // Given
        var didPerformPluginAction = false
        var didRefresh = false
        let view = InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: true,
                                                      onInstall: { didPerformPluginAction = true }, onRefresh: { didRefresh = true })

        // When
        view.buttonViewModel.action()

        // Then
        #expect(didPerformPluginAction)
        #expect(!didRefresh)
    }

    @Test func test_buttonViewModel_when_user_is_not_administrator_then_refresh_action_is_called() {
        // Given
        var didPerformPluginAction = false
        var didRefresh = false
        let view = InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: false,
                                                      onInstall: { didPerformPluginAction = true }, onRefresh: { didRefresh = true })

        // When
        let buttonViewModel = view.buttonViewModel
        buttonViewModel.action()

        // Then
        #expect(buttonViewModel.text == "Refresh")
        #expect(didRefresh)
        #expect(!didPerformPluginAction)
    }

    @Test func test_message_when_user_is_not_administrator_then_it_differs_from_the_administrator_message() {
        // Given
        let administratorView = InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: true, onInstall: {}, onRefresh: {})
        let nonAdministratorView = InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: false, onInstall: {}, onRefresh: {})

        // When
        let administratorMessage = administratorView.message
        let nonAdministratorMessage = nonAdministratorView.message

        // Then
        #expect(administratorMessage != nonAdministratorMessage)
    }
}
