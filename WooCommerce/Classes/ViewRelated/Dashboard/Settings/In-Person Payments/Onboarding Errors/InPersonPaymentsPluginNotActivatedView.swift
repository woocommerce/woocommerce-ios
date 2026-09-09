import SwiftUI
import Yosemite

struct InPersonPaymentsPluginNotActivated: View {
    let plugin: CardPresentPaymentsPlugin
    let analyticReason: String
    let userIsAdministrator: Bool
    let onActivate: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: String(format: Localization.title, plugin.pluginName),
            message: message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: plugin.image,
                height: 108.0
            ),
            supportLink: false,
            learnMore: true,
            analyticReason: analyticReason,
            plugin: plugin,
            buttonViewModel: buttonViewModel
        )
    }
}

extension InPersonPaymentsPluginNotActivated {
    var message: String {
        let format = userIsAdministrator ? Localization.message : Localization.messageForNonAdministrator
        return String(format: format, plugin.pluginName)
    }

    var buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel? {
        guard userIsAdministrator else {
            return nil
        }

        return InPersonPaymentsOnboardingErrorButtonViewModel(
            text: Localization.primaryButton,
            analyticReason: analyticReason,
            plugin: plugin,
            action: onActivate
        )
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Activate %1$@",
        comment: "Title for the error screen when a Card Present Payments extension is installed but not activated"
    )

    static let message = NSLocalizedString(
        "The %1$@ extension is installed on your store but not activated. Please activate it to accept In‑Person Payments",
        comment: """
                 Error message when a Card Present Payments extension is not activated
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let messageForNonAdministrator = NSLocalizedString(
        "inPersonPaymentsPluginNotActivated.messageForNonAdministrator",
        value: "The %1$@ extension is installed on your store but not activated. "
        + "Please ask a store administrator to activate it to accept In‑Person Payments.",
        comment: """
                 Error message when a Card Present Payments extension is not activated,
                 shown to users who cannot activate it themselves. %1$@ is the extension name.
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let primaryButton = NSLocalizedString(
        "Activate plugin",
        comment: "Button to activate the Card Present Payments plugin"
    )
}

struct InPersonPaymentsPluginNotActivated_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: true, onActivate: {})
            .previewDisplayName("Administrator")

        InPersonPaymentsPluginNotActivated(plugin: .wcPay, analyticReason: "", userIsAdministrator: false, onActivate: {})
            .previewDisplayName("Non-administrator")
    }
}
