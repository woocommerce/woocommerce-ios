import SwiftUI
import Yosemite

struct InPersonPaymentsPluginNotActivated: View {
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
        "Activate %1$@",
        comment: "Title for the error screen when a Card Present Payments extension is installed but not activated"
    )

    static let message = NSLocalizedString(
        "The %1$@ extension is installed on your store but not activated. Please activate it to accept In-Person Payments",
        comment: "Error message when a Card Present Payments extension is not activated"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Activating",
        comment: "Button to reload plugin data after activating a Card Present Payments extension"
    )
}

struct InPersonPaymentsPluginNotActivated_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotActivated(plugin: .wcPay, onRefresh: {})
    }
}
