import SwiftUI

struct InPersonPaymentsStripeAcountReview: View {
    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: Localization.message,
            image: InPersonPaymentsOnboardingError.ImageInfo(
                image: .paymentErrorImage,
                height: 180.0
            ),
            supportLink: true,
            learnMore: true
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

struct InPersonPaymentsStripeAcountReview_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAcountReview()
    }
}
