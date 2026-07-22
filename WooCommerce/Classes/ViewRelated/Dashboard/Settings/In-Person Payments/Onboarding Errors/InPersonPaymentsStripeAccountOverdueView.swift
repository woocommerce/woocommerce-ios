import SwiftUI
import enum Yosemite.CardPresentPaymentsPlugin

struct InPersonPaymentsStripeAccountOverdue: View {
    @ObservedObject var viewModel: InPersonPaymentsStripeAccountOverdueViewModel

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
            analyticReason: viewModel.analyticReason,
            plugin: viewModel.plugin,
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(text: Localization.primaryButtonTitle,
                                                                            analyticReason: viewModel.analyticReason,
                                                                            plugin: viewModel.plugin,
                                                                            action: viewModel.resolveNowTapped),
            secondaryButtonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(text: Localization.skipButtonTitle,
                                                                                     analyticReason: viewModel.analyticReason,
                                                                                     plugin: viewModel.plugin,
                                                                                     action: viewModel.onSkip)
        )
        .safariSheet(url: $viewModel.presentedSetupURL, onDismiss: viewModel.onRefresh)
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
        "cardPresentPayments.onboarding.stripeAccountOverdue.resolveButton",
        value: "Resolve Now",
        comment: "Button to open a web view and resolve overdue requirements before continuing with In-Person Payments."
    )

    static let skipButtonTitle = NSLocalizedString(
        "cardPresentPayments.onboarding.stripeAccountOverdue.skipButton",
        value: "Skip",
        comment: "Button to skip the overdue-requirements onboarding step and continue accepting In-Person Payments."
    )
 }


struct InPersonPaymentsStripeAccountOverdue_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAccountOverdue(
            viewModel: InPersonPaymentsStripeAccountOverdueViewModel(plugin: .stripe, analyticReason: "", onRefresh: { }, onSkip: { }))
    }
}
