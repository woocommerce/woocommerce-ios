import Foundation
import enum Yosemite.CardPresentPaymentsPlugin

struct InPersonPaymentsPluginNotActivatedViewModel {
    let plugin: CardPresentPaymentsPlugin
    let analyticReason: String
    let onActivate: () -> Void

    var title: String {
        String(format: Localization.title, plugin.pluginName)
    }

    var message: String {
        String(format: Localization.message, plugin.pluginName)
    }

    var activateButtonTitle: String {
        Localization.primaryButton
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

    static let primaryButton = NSLocalizedString(
        "Activate plugin",
        comment: "Button to activate the Card Present Payments plugin"
    )
}
