import SwiftUI

struct InPersonPaymentsSelectPlugin: View {
    let onRefresh: () -> Void

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
        "Please select an extension",
        comment: "Title for the error screen when there is more than one extension active."
    )

    static let message = NSLocalizedString(
        "Choose between WooCommerce Payments and Stripe Extension",
        comment: "Message requesting merchants to select between available payments processors"
    )
}

struct InPersonPaymentsSelectPlugin_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsSelectPlugin(onRefresh: {})
    }
}
