import Foundation
import Yosemite
import protocol WooFoundation.Analytics

final class InPersonPaymentsStripeAccountOverdueViewModel: ObservableObject {
    let plugin: CardPresentPaymentsPlugin
    let analyticReason: String
    let onRefresh: () -> Void
    let onSkip: () -> Void

    @Published var presentedSetupURL: URL? = nil

    private let stores: StoresManager
    private let analytics: Analytics
    private let cardPresentConfiguration: CardPresentPaymentsConfiguration

    init(plugin: CardPresentPaymentsPlugin,
         analyticReason: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         cardPresentConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         onRefresh: @escaping () -> Void,
         onSkip: @escaping () -> Void) {
        self.plugin = plugin
        self.analyticReason = analyticReason
        self.stores = stores
        self.analytics = analytics
        self.cardPresentConfiguration = cardPresentConfiguration
        self.onRefresh = onRefresh
        self.onSkip = onSkip
    }

    /// Invoked from the primary button, after `InPersonPaymentsOnboardingErrorButtonViewModel` has tracked the CTA tap.
    ///
    func resolveNowTapped() {
        presentedSetupURL = setupURL
        trackPluginSetupTappedEvent()
    }

    private var setupURL: URL? {
        guard let pluginSectionURL = stores.sessionManager.defaultSite?.cardPresentPluginHasPendingTasksURL(plugin: plugin) else {
            return nil
        }

        return URL(string: pluginSectionURL)
    }

    private func trackPluginSetupTappedEvent() {
        analytics.track(event: .InPersonPayments.cardPresentOnboardingCtaFailed(
            reason: "stripe_account_setup_tapped",
            countryCode: cardPresentConfiguration.countryCode,
            gatewayID: plugin.gatewayID
        ))
    }
}
