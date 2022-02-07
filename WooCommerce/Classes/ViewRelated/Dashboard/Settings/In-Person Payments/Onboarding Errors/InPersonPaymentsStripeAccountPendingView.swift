import SwiftUI

struct InPersonPaymentsStripeAccountPending: View {
    let deadline: Date?

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: message,
            image: InPersonPaymentsOnboardingError.ImageInfo(
                image: .paymentErrorImage,
                height: 180.0
            ),
            supportLink: true,
            learnMore: true
        )
      }

    private var message: String {
        guard let deadline = deadline else {
            DDLogError("In-Person Payments not available. Stripe has pending requirements without known deadline")
            return Localization.messageUnknownDeadline
        }
        return String(format: Localization.messageDeadline, deadline.toString(dateStyle: .long, timeStyle: .none))
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Your payments account has pending requirements",
        comment: "Title for the error screen when the merchant's In-Person Payments account is restricted because there are pending requirements"
    )

    static let messageDeadline = NSLocalizedString(
        "There are pending requirements for your account. Please complete those requirements by %1$@ to keep accepting In-Person Payments.",
        comment: "Error message when In-Person Payments is not supported because there are pending requirements in the merchant's payment account."
            +
            "%1$d will contain the localized deadline (e.g. August 11, 2021)"
    )

    static let messageUnknownDeadline = NSLocalizedString(
        "There are pending requirements for your account. Please complete those requirements to keep accepting In-Person Payments.",
        comment: "Error message when In-Person Payments is not supported"
            +
            "There are pending requirements in the merchant's payment account (without a known deadline)"
    )

     static let message = NSLocalizedString(
         "There are pending requirements for your account. Please complete those requirements by",
         comment: "Error message when the Stripe account is restricted because there are pending requirements"
     )
 }

struct InPersonPaymentsStripeAccountPending_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAccountPending(deadline: Date())
    }
}
