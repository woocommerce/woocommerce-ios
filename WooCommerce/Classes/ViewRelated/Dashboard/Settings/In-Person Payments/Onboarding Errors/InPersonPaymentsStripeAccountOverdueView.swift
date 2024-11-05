import SwiftUI
import enum Yosemite.CardPresentPaymentsPlugin

struct InPersonPaymentsStripeAccountOverdue: View {
    let analyticReason: String
    let onRefresh: () -> Void
    @State private var presentedSetupURL: URL? = nil

    private let plugin: CardPresentPaymentsPlugin = .stripe

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
            secondaryButtonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(text: Localization.secondaryButtonTitle,
                                                                                     analyticReason: analyticReason,
                                                                                     plugin: plugin,
                                                                                     action: onRefresh)
        )
        .safariSheet(url: $presentedSetupURL, onDismiss: onRefresh)
     }

    private var setupURL: URL? {
        guard let pluginSectionURL = ServiceLocator.stores.sessionManager.defaultSite?.cardPresentPluginHasPendingTasksURL() else {
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
         "In-Person Payments is currently unavailable",
         comment: "Title for the error screen when the Stripe account is restricted because there are overdue requirements."
     )

     static let message = NSLocalizedString(
         "You have at least one overdue requirement on your account. Please take care of that to resume In-Person Payments.",
         comment: "Error message when WooCommerce Payments is not supported because the Stripe account has overdue requirements"
     )

    static let primaryButtonTitle = NSLocalizedString(
        "Resolve Now",
        comment: "Button to open a web view and resolve pending plugin requirements before using it.")

    static let secondaryButtonTitle = NSLocalizedString(
        "Refresh",
        comment: "Button to refresh the state of the in-person payments setup.")
 }


struct InPersonPaymentsStripeAccountOverdue_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAccountOverdue(analyticReason: "", onRefresh: { })
    }
}
