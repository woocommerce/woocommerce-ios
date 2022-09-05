import SwiftUI

struct InPersonPaymentsPluginNotInstalled: View {
    let analyticReason: String
    let onRefresh: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: Localization.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .wcPayPlugin,
                height: 126.0
            ),
            supportLink: false,
            learnMore: true,
            analyticReason: analyticReason,
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(
                text: Localization.primaryButton,
                analyticReason: analyticReason,
                action: onRefresh
            )
        )
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Install WooCommerce Payments",
        comment: "Title for the error screen when WooCommerce Payments is not installed"
    )

    static let message = NSLocalizedString(
        "You’ll need to install the free WooCommerce Payments extension on your store to accept In-Person Payments.",
        comment: "Error message when WooCommerce Payments is not installed"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Installing",
        comment: "Button to reload plugin data after installing the WooCommerce Payments plugin"
    )
}

struct InPersonPaymentsPluginNotInstalled_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotInstalled(analyticReason: "", onRefresh: {})
    }
}
