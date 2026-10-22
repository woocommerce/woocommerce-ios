import SwiftUI

struct InPersonPaymentsUnavailable: View {
    let analyticReason: String
    let onRefresh: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.unavailable,
            message: Localization.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .paymentErrorImage,
                height: 180.0
            ),
            supportLink: false,
            learnMore: true,
            analyticReason: analyticReason,
            plugin: nil,
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(
                text: Localization.primaryButton,
                analyticReason: analyticReason,
                plugin: nil,
                action: onRefresh
            )
        )
    }
}

private enum Localization {
    static let primaryButton = NSLocalizedString(
        "cardPresentPayments.onboarding.unavailable.retryButton",
        value: "Retry",
        comment: "Button to recheck In-Person Payments requirements when checking payment eligibility failed."
    )

    static let unavailable = NSLocalizedString(
        "Unable to verify In‑Person Payments for this store",
        comment: """
                 Title for the error screen when In-Person Payments is unavailable
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let message = NSLocalizedString(
        "We're sorry, we were unable to verify In‑Person Payments for this store.",
        comment: """
                 Generic error message when In-Person Payments is unavailable
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )
}

struct InPersonPaymentsUnavailable_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsUnavailable(analyticReason: "", onRefresh: {})
    }
}
