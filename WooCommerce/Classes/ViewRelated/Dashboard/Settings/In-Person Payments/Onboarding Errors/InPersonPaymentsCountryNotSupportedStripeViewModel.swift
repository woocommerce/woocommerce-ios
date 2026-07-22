import Foundation
import enum WooFoundation.CountryCode

struct InPersonPaymentsCountryNotSupportedStripeViewModel {
    let countryCode: CountryCode
    let analyticReason: String

    var title: String {
        guard let countryName = Locale.current.localizedString(forRegionCode: countryCode.rawValue) else {
            DDLogError("In-Person Payments unsupported in country code \(countryCode.rawValue), which can't be localized")
            return Localization.titleUnknownCountry
        }
        return String(format: Localization.title, countryName)
    }

    var message: String {
        Localization.message
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "We don’t support In‑Person Payments with Stripe in %1$@",
        comment: """
                 Title for the error screen when In-Person Payments is not supported in a specific country
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let titleUnknownCountry = NSLocalizedString(
        "We don’t support In‑Person Payments with Stripe in your country",
        comment: """
                 Title for the error screen when In-Person Payments is not supported because we don't know the name of the country
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let message = NSLocalizedString(
        "You can still accept in-person cash payments by enabling the “Cash on Delivery” payment method on your store.",
        comment: "Error message when In-Person Payments is not supported in a specific country"
    )
}
