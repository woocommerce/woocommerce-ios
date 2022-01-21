import SwiftUI

struct InPersonPaymentsPluginNotActivated: View {
    let onRefresh: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: Localization.message,
            image: InPersonPaymentsOnboardingError.ImageInfo(
                image: .wcPayPlugin,
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
        "Activate WooCommerce Payments",
        comment: "Title for the error screen when WooCommerce Payments is installed but not activated"
    )

    static let message = NSLocalizedString(
        "The WooCommerce Payments extension is installed on your store but not activated. Please activate it to accept In-Person Payments",
        comment: "Error message when WooCommerce Payments is not activated"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Activating",
        comment: "Button to reload plugin data after activating the WooCommerce Payments plugin"
    )
}

struct InPersonPaymentsPluginNotActivated_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotActivated(onRefresh: {})
    }
}
