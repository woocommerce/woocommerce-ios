import SwiftUI

struct InPersonPaymentsStripeAccountOverdue: View {
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
         comment: "Title for the error screen when the Stripe account is restricted because there are overdue requirements."
     )

     static let message = NSLocalizedString(
         "You have at least one overdue requirement on your account. Please take care of that to resume In-Person Payments.",
         comment: "Error message when WooCommerce Payments is not supported because the Stripe account has overdue requirements"
     )
 }


struct InPersonPaymentsStripeAccountOverdue_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAccountOverdue()
    }
}
