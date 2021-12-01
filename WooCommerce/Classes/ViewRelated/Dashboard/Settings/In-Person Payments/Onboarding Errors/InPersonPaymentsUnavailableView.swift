import SwiftUI

struct InPersonPaymentsUnavailable: View {
    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.unavailable,
            message: Localization.message,
            image: InPersonPaymentsOnboardingError.ImageInfo(
                image: .paymentErrorImage,
                height: 180.0
            ),
            supportLink: false,
            learnMore: true
        )
    }
}

private enum Localization {
    static let unavailable = NSLocalizedString(
        "Unable to verify In-Person Payments for this store",
        comment: "Title for the error screen when In-Person Payments is unavailable"
    )

    static let message = NSLocalizedString(
        "We're sorry, we were unable to verify In-Person Payments for this store.",
        comment: "Generic error message when In-Person Payments is unavailable"
    )
}

struct InPersonPaymentsUnavailable_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsUnavailable()
    }
}
