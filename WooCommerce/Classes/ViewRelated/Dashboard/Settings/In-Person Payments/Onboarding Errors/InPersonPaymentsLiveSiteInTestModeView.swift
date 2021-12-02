import SwiftUI

struct InPersonPaymentsLiveSiteInTestMode: View {
    let onRefresh: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: Localization.message,
            image: InPersonPaymentsOnboardingError.ImageInfo(
                image: .paymentsPlugin,
                height: 108.0
            ),
            supportLink: false,
            learnMore: true,
            button: InPersonPaymentsOnboardingError.ButtonInfo(
                text: Localization.primaryButton,
                action: onRefresh
            )
        )
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "WooCommerce Payments is in Test Mode",
        comment: "Title for the error screen when WooCommerce Payments is in test mode on a live site"
    )

    static let message = NSLocalizedString(
        "The WooCommerce Payments extension cannot be in test mode for In-Person Payments. "
            + "Please disable test mode.",
        comment: "Error message when WooCommerce Payments is in test mode on a live site"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Updating",
        comment: "Button to reload plugin data after updating the WooCommerce Payments plugin settings"
    )
}

struct InPersonPaymentsLiveSiteInTestMode_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLiveSiteInTestMode(onRefresh: {})
    }
}
