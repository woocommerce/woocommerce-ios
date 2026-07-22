import Foundation

struct InPersonPaymentsStripeRejectedViewModel {
    let analyticReason: String

    var title: String {
        Localization.title
    }

    var message: String {
        Localization.message
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
