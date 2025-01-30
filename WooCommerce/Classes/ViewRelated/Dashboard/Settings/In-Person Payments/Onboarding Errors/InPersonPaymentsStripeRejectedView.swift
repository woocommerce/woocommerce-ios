import SwiftUI

struct InPersonPaymentsStripeRejected: View {
    let analyticReason: String
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
            plugin: .stripe
        )
    }
}

private enum Localization {
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
        InPersonPaymentsStripeRejected(analyticReason: "")
    }
}
