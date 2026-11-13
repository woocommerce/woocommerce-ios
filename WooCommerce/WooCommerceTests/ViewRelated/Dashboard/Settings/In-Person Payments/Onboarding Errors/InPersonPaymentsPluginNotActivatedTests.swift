import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct InPersonPaymentsPluginNotActivatedTests {

    @Test func test_buttonViewModel_when_userIsAdministrator_then_activate_action_is_called() {
        // Given
        var didPerformPluginAction = false
        var didRefresh = false
        let view = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: true,
                                                      onActivate: { didPerformPluginAction = true }, onRefresh: { didRefresh = true })

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
        let view = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: false,
                                                      onActivate: { didPerformPluginAction = true }, onRefresh: { didRefresh = true })

        // When
        let buttonViewModel = view.buttonViewModel
        buttonViewModel.action()

        // Then
        #expect(didRefresh)
        #expect(!didPerformPluginAction)
    }

    @Test func test_message_when_user_is_not_administrator_then_it_differs_from_the_administrator_message() {
        // Given
        let administratorView = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: true,
                                                                  onActivate: {}, onRefresh: {})
        let nonAdministratorView = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: false,
                                                                     onActivate: {}, onRefresh: {})

        // When
        let administratorMessage = administratorView.message
        let nonAdministratorMessage = nonAdministratorView.message

        // Then
        #expect(administratorMessage != nonAdministratorMessage)
    }

    @Test func test_message_when_user_is_not_administrator_then_it_includes_the_plugin_name() {
        // Given
        let view = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: false, onActivate: {}, onRefresh: {})

        // When
        let message = view.message

        // Then
        #expect(message.contains(CardPresentPaymentsPlugin.wcPay.pluginName))
    }
}
