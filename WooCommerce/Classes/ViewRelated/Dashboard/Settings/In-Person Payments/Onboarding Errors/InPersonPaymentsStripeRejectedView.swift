import SwiftUI
import enum Yosemite.CardPresentPaymentsPlugin

struct InPersonPaymentsStripeRejected: View {
    let analyticReason: String
    let plugin: CardPresentPaymentsPlugin
    let onRefresh: () -> Void
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
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(
                text: Localization.primaryButton,
                analyticReason: analyticReason,
                plugin: plugin,
                action: onRefresh
            )
        )
    }
}

private enum Localization {
    static let primaryButton = NSLocalizedString(
        "cardPresentPayments.onboarding.accountRejected.refreshButton",
        value: "Refresh",
        comment: "Button to recheck In-Person Payments requirements when the payment account was rejected."
    )

    static let title = NSLocalizedString(
        "In‑Person Payments isn't available for this store",
        comment: """
                 Title for the error screen when the merchant's payment account has been rejected.
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let message = NSLocalizedString(
        "We are sorry but we can't support In‑Person Payments for this store.",
        comment: """
                 Error message when the merchant's payment account has been rejected
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )
}

struct InPersonPaymentsStripeRejected_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeRejected(analyticReason: "", plugin: .stripe, onRefresh: {})
    }
}
