import SwiftUI

struct InPersonPaymentsStripeAccountPending: View {
    let deadline: Date?
    let onSkip: () -> ()

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .paymentErrorImage,
                height: Constants.imageHeight
            ),
            supportLink: true,
            learnMore: true,
            button: InPersonPaymentsOnboardingError.ButtonInfo(
                text: Localization.skipButton,
                action: onSkip
            )
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
        comment: "Title for the error screen when the merchant's In-Person Payments account has pending " +
        "requirements which will result in their account being restricted if not resolved by a deadline"
    )

    static let messageDeadline = NSLocalizedString(
        "There are pending requirements for your account. Please complete those requirements by %1$@ to keep accepting In-Person Payments.",
        comment: "Error message when because there are pending requirements in the merchant's " +
        "In-Person Payments account. %1$d will contain the localized deadline (e.g. August 11, 2021)"
    )

    static let messageUnknownDeadline = NSLocalizedString(
        "There are pending requirements for your account. Please complete those requirements to keep accepting In-Person Payments.",
        comment: "Error message when there are pending requirements in the merchant's payment account (without a known deadline)"
    )

    static let skipButton = NSLocalizedString(
        "Skip",
        comment: "Title for the button to skip the onboarding step informing the merchant of pending account requirements")
}

struct InPersonPaymentsStripeAccountPending_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAccountPending(deadline: Date(), onSkip: {})
    }
}

private enum Constants {
    static let imageHeight: CGFloat = 180.0
}
