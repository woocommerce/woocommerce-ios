import SwiftUI
import enum Yosemite.CardPresentPaymentsPlugin

struct InPersonPaymentsStripeAccountOverdue: View {
    let analyticReason: String
    let onRefresh: () -> Void
    let onSkip: () -> Void
    let plugin: CardPresentPaymentsPlugin
    @State private var presentedSetupURL: URL? = nil


    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: Localization.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .paymentErrorImage,
                height: 180.0
            ),
            supportLink: true,
            learnMore: true,
            analyticReason: analyticReason,
            plugin: plugin,
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(text: Localization.primaryButtonTitle,
                                                                            analyticReason: analyticReason,
                                                                            plugin: plugin,
                                                                            action: {
                                                                                presentedSetupURL = setupURL
                                                                                trackPluginSetupTappedEvent()
                                                                            }),
            secondaryButtonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(text: Localization.skipButtonTitle,
                                                                                     analyticReason: analyticReason,
                                                                                     plugin: plugin,
                                                                                     action: onSkip)
        )
        .safariSheet(url: $presentedSetupURL, onDismiss: onRefresh)
     }

    private var setupURL: URL? {
        guard let pluginSectionURL = ServiceLocator.stores.sessionManager.defaultSite?.cardPresentPluginHasPendingTasksURL(plugin: plugin) else {
            return nil
        }

        return URL(string: pluginSectionURL)
    }
}

private extension InPersonPaymentsStripeAccountOverdue {
    func trackPluginSetupTappedEvent() {
        ServiceLocator.analytics.track(event: .InPersonPayments.cardPresentOnboardingCtaFailed(
            reason: "stripe_account_setup_tapped",
            countryCode: CardPresentConfigurationLoader().configuration.countryCode,
            gatewayID: plugin.gatewayID
        ))
    }
}

private enum Localization {
     static let title = NSLocalizedString(
         "cardPresentPayments.onboarding.stripeAccountOverdue.title",
         value: "Overdue requirements on your account",
         comment: "Title for the error screen when the Stripe account is restricted because there are overdue requirements."
     )

     static let message = NSLocalizedString(
         "cardPresentPayments.onboarding.stripeAccountOverdue.message",
         value: "You have at least one overdue requirement. You can skip and keep taking payments, but if the " +
         "requirement is blocking your account, some transactions may be declined until you resolve it.",
         comment: "Error message when the Stripe account has overdue requirements, explaining that the merchant can " +
         "skip and continue taking payments, with a caution that some transactions may be declined if the " +
         "account is actually blocked."
     )

    static let primaryButtonTitle = NSLocalizedString(
        "Resolve Now",
        comment: "Button to open a web view and resolve pending plugin requirements before using it.")

    static let skipButtonTitle = NSLocalizedString(
        "cardPresentPayments.onboarding.stripeAccountOverdue.skipButton",
        value: "Skip",
        comment: "Button to skip the overdue-requirements onboarding step and continue accepting In-Person Payments."
    )
 }


struct InPersonPaymentsStripeAccountOverdue_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAccountOverdue(analyticReason: "", onRefresh: { }, onSkip: { }, plugin: .stripe)
    }
}
