import SwiftUI

struct InPersonPaymentsStripeAccountReview: View {
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
            analyticReason: analyticReason
        )
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "In-Person Payments is currently unavailable",
        comment: "Title for the error screen when the merchant's payment account is restricted because it's under reviw"
    )

    static let message = NSLocalizedString(
        "You'll be able to accept In-Person Payments as soon as we finish reviewing your account.",
        comment: "Error message when the merchant's payment account is under review"
    )
}

struct InPersonPaymentsStripeAccountReview_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAccountReview(analyticReason: "")
    }
}
