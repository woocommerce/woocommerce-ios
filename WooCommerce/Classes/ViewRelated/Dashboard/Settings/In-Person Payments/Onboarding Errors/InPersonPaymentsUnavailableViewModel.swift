import Foundation

struct InPersonPaymentsUnavailableViewModel {
    let analyticReason: String

    var title: String {
        Localization.unavailable
    }

    var message: String {
        Localization.message
    }
}

private enum Localization {
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
