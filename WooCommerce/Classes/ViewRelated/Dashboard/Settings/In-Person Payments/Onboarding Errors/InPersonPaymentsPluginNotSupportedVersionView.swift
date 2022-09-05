import SwiftUI
import Yosemite

struct InPersonPaymentsPluginNotSupportedVersion: View {
    let plugin: CardPresentPaymentsPlugin
    let analyticReason: String
    let onRefresh: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: String(format: Localization.title, plugin.pluginName),
            message: String(format: Localization.message, plugin.pluginName),
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: plugin.image,
                height: 108.0
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
        "Unsupported %1$@ version",
        comment: "Title for the error screen when the installed version of a Card Present Payments extension is unsupported"
    )

    static let message = NSLocalizedString(
        "The %1$@ extension is installed on your store, but needs to be updated for In-Person Payments. "
            + "Please update it to the most recent version.",
        comment: "Error message when a Card Present Payments extension is installed but the version is not supported"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Updating",
        comment: "Button to reload plugin data after updating a Card Present Payments extension plugin"
    )
}

struct InPersonPaymentsPluginNotSupportedVersion_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotSupportedVersion(plugin: .wcPay, analyticReason: "", onRefresh: {})
    }
}
