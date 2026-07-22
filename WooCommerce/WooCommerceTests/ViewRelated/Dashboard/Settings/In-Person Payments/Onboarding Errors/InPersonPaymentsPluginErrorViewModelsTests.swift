import Foundation
import Testing
@testable import WooCommerce
import Yosemite

/// Tests for the lightweight view models backing the plugin-related onboarding error views.
///
struct InPersonPaymentsPluginErrorViewModelsTests {

    @Test(arguments: [CardPresentPaymentsPlugin.wcPay, .stripe])
    func pluginNotActivated_title_and_message_include_the_plugin_name(plugin: CardPresentPaymentsPlugin) async throws {
        // Given
        let sut = InPersonPaymentsPluginNotActivatedViewModel(plugin: plugin, analyticReason: "", onActivate: {})

        // Then
        #expect(sut.title.contains(plugin.pluginName))
        #expect(sut.message.contains(plugin.pluginName))
    }

    @Test(arguments: [CardPresentPaymentsPlugin.wcPay, .stripe])
    func pluginNotSupportedVersion_title_and_message_include_the_plugin_name(plugin: CardPresentPaymentsPlugin) async throws {
        // Given
        let sut = InPersonPaymentsPluginNotSupportedVersionViewModel(plugin: plugin, analyticReason: "", onRefresh: {})

        // Then
        #expect(sut.title.contains(plugin.pluginName))
        #expect(sut.message.contains(plugin.pluginName))
    }

    @Test(arguments: [CardPresentPaymentsPlugin.wcPay, .stripe])
    func liveSiteInTestMode_title_and_message_include_the_plugin_name(plugin: CardPresentPaymentsPlugin) async throws {
        // Given
        let sut = InPersonPaymentsLiveSiteInTestModeViewModel(plugin: plugin, analyticReason: "", onRefresh: {})

        // Then
        #expect(sut.title.contains(plugin.pluginName))
        #expect(sut.message.contains(plugin.pluginName))
    }

    @Test func pluginNotInstalled_uses_the_title_as_the_install_button_title() async throws {
        // Given
        let sut = InPersonPaymentsPluginNotInstalledViewModel(analyticReason: "", onInstall: {})

        // Then
        #expect(sut.installButtonTitle == sut.title)
    }
}
