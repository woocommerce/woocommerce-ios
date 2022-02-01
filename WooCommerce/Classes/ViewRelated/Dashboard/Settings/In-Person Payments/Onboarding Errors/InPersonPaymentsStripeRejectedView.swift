import SwiftUI

struct InPersonPaymentsStripeRejected: View {
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
        "In-Person Payments isn't available for this store",
        comment: "Title for the error screen when the merchant's payment account has been rejected."
    )

    static let message = NSLocalizedString(
        "We are sorry but we can't support In-Person Payments for this store.",
        comment: "Error message when the merchant's payment account has been rejected"
    )
}

struct InPersonPaymentsStripeRejected_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeRejected()
    }
}
