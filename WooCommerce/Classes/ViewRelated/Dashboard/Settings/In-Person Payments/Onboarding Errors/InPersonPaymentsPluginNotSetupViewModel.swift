import Foundation
import Yosemite
import protocol WooFoundation.Analytics

final class InPersonPaymentsPluginNotSetupViewModel: ObservableObject {
    let plugin: CardPresentPaymentsPlugin
    let analyticReason: String
    let onRefresh: () -> Void

    @Published var presentedSetupURL: URL? = nil

    private let stores: StoresManager
    private let analytics: Analytics
    private let cardPresentConfiguration: CardPresentPaymentsConfiguration

    init(plugin: CardPresentPaymentsPlugin,
         analyticReason: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         cardPresentConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         onRefresh: @escaping () -> Void) {
        self.plugin = plugin
        self.analyticReason = analyticReason
        self.stores = stores
        self.analytics = analytics
        self.cardPresentConfiguration = cardPresentConfiguration
        self.onRefresh = onRefresh
    }

    func setupButtonTapped() {
        presentedSetupURL = setupURL
        analytics.track(
            event: .InPersonPayments.cardPresentOnboardingCtaTapped(
                reason: analyticReason,
                countryCode: cardPresentConfiguration.countryCode,
                gatewayID: plugin.gatewayID
            ))
        trackPluginSetupTappedEvent()
    }

    var learnMoreAnalyticEvent: WooAnalyticsEvent? {
        .InPersonPayments.cardPresentOnboardingLearnMoreTapped(reason: analyticReason,
                                                               countryCode: cardPresentConfiguration.countryCode,
                                                               gatewayID: plugin.gatewayID)
    }

    private var setupURL: URL? {
        guard let pluginSectionURL = stores.sessionManager.defaultSite?.cardPresentPluginHasPendingTasksURL(plugin: plugin) else {
            return nil
        }

        return URL(string: pluginSectionURL)
    }

    private func trackPluginSetupTappedEvent() {
        analytics.track(event: .InPersonPayments.cardPresentOnboardingCtaFailed(
            reason: "plugin_setup_tapped",
            countryCode: cardPresentConfiguration.countryCode,
            gatewayID: plugin.gatewayID
        ))
    }
}
