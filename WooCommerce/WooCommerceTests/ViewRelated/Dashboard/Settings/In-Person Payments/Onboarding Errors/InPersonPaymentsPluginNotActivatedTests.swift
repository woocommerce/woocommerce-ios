import Testing
import Yosemite
@testable import WooCommerce

struct InPersonPaymentsPluginNotActivatedTests {

    @Test func test_buttonViewModel_when_userIsAdministrator_then_activate_CTA_is_shown() {
        // Given
        let view = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: true, onActivate: {})

        // When
        let buttonViewModel = view.buttonViewModel

        // Then
        #expect(buttonViewModel != nil)
    }

    @Test func test_buttonViewModel_when_user_is_not_administrator_then_activate_CTA_is_hidden() {
        // Given
        let view = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: false, onActivate: {})

        // When
        let buttonViewModel = view.buttonViewModel

        // Then
        #expect(buttonViewModel == nil)
    }

    @Test func test_message_when_user_is_not_administrator_then_it_differs_from_the_administrator_message() {
        // Given
        let administratorView = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: true, onActivate: {})
        let nonAdministratorView = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: false, onActivate: {})

        // When
        let administratorMessage = administratorView.message
        let nonAdministratorMessage = nonAdministratorView.message

        // Then
        #expect(administratorMessage != nonAdministratorMessage)
    }

    @Test func test_message_when_user_is_not_administrator_then_it_includes_the_plugin_name() {
        // Given
        let view = InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: false, onActivate: {})

        // When
        let message = view.message

        // Then
        #expect(message.contains(CardPresentPaymentsPlugin.wcPay.pluginName))
    }
}
