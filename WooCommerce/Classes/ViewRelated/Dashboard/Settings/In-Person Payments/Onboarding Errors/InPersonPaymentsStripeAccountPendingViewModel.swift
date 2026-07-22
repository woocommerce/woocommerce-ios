import Foundation
import enum Yosemite.CardPresentPaymentsPlugin

struct InPersonPaymentsStripeAccountPendingViewModel {
    let deadline: Date?
    let plugin: CardPresentPaymentsPlugin
    let analyticReason: String
    let onSkip: () -> ()

    var title: String {
        Localization.title
    }

    var message: String {
        guard let deadline else {
            DDLogError("In-Person Payments not available. Stripe has pending requirements without known deadline")
            return Localization.messageUnknownDeadline
        }
        return String(format: Localization.messageDeadline, deadline.toString(dateStyle: .long, timeStyle: .none))
    }

    var skipButtonTitle: String {
        Localization.skipButton
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Your payments account has pending requirements",
        comment: "Title for the error screen when the merchant's In-Person Payments account has pending " +
        "requirements which will result in their account being restricted if not resolved by a deadline"
    )

    static let messageDeadline = NSLocalizedString(
        "There are pending requirements for your account. Please complete those requirements by %1$@ to keep accepting In‑Person Payments.",
        comment: """
                 Error message when because there are pending requirements in the merchant's
                 In-Person Payments account.
                 %1$d will contain the localized deadline (e.g. August 11, 2021)
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let messageUnknownDeadline = NSLocalizedString(
        "There are pending requirements for your account. Please complete those requirements to keep accepting In‑Person Payments.",
        comment: """
                 Error message when there are pending requirements in the merchant's payment account (without a known deadline)
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let skipButton = NSLocalizedString(
        "Skip",
        comment: "Title for the button to skip the onboarding step informing the merchant of pending account requirements")
}
