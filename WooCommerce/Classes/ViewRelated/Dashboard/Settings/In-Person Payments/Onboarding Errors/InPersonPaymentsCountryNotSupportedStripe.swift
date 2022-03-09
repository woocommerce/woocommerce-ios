import SwiftUI

struct InPersonPaymentsCountryNotSupportedStripe: View {
    let countryCode: String

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: title,
            message: Localization.message,
            image: InPersonPaymentsOnboardingError.ImageInfo(
                image: .paymentErrorImage,
                height: 180.0
            ),
            supportLink: true,
            learnMore: true
        )
    }

    var title: String {
        guard let countryName = Locale.current.localizedString(forRegionCode: countryCode) else {
            DDLogError("In-Person Payments unsupported in country code \(countryCode), which can't be localized")
            return Localization.titleUnknownCountry
        }
        return String(format: Localization.title, countryName)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "We don’t support In-Person Payments with Stripe in %1$@",
        comment: "Title for the error screen when In-Person Payments is not supported in a specific country"
    )

    static let titleUnknownCountry = NSLocalizedString(
        "We don’t support In-Person Payments with Stripe in your country",
        comment: "Title for the error screen when In-Person Payments is not supported because we don't know the name of the country"
    )

    static let message = NSLocalizedString(
        "You can still accept in-person cash payments by enabling the “Cash on Delivery” payment method on your store.",
        comment: "Error message when In-Person Payments is not supported in a specific country"
    )
}

struct InPersonPaymentsCountryNotSupportedStripe_Previews: PreviewProvider {
    static var previews: some View {
        // Valid country code
        InPersonPaymentsCountryNotSupportedStripe(countryCode: "ES")
        // Invalid country code
        InPersonPaymentsCountryNotSupportedStripe(countryCode: "OO")
    }
}
