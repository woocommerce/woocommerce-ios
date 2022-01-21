import SwiftUI
import Yosemite

struct InPersonPaymentsLiveSiteInTestMode: View {
    let plugin: CardPresentPaymentsPlugins
    let onRefresh: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: String(format: Localization.title, plugin.pluginName),
            message: String(format: Localization.message, plugin.pluginName),
            image: InPersonPaymentsOnboardingError.ImageInfo(
                image: plugin.image,
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
        "%1$@ is in Test Mode",
        comment: "Title for the error screen when a card present payments plugin is in test mode on a live site"
    )

    static let message = NSLocalizedString(
        "The %1$@ extension cannot be in test mode for In-Person Payments. "
            + "Please disable test mode.",
        comment: "Error message when a card present payments plugin is in test mode on a live site"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Updating",
        comment: "Button to reload plugin data after updating a card present payments plugin settings"
    )
}

struct InPersonPaymentsLiveSiteInTestMode_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLiveSiteInTestMode(plugin: .wcPay, onRefresh: {})
    }
}
