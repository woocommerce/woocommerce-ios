import Foundation
import enum Yosemite.CardPresentPaymentsPlugin

struct InPersonPaymentsPluginNotSupportedVersionViewModel {
    let plugin: CardPresentPaymentsPlugin
    let analyticReason: String
    let onRefresh: () -> Void

    var title: String {
        String(format: Localization.title, plugin.pluginName)
    }

    var message: String {
        String(format: Localization.message, plugin.pluginName)
    }

    var refreshButtonTitle: String {
        Localization.primaryButton
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Unsupported %1$@ version",
        comment: "Title for the error screen when the installed version of a Card Present Payments extension is unsupported"
    )

    static let message = NSLocalizedString(
        "The %1$@ extension is installed on your store, but needs to be updated for In‑Person Payments. "
            + "Please update it to the most recent version.",
        comment: """
                Error message when a Card Present Payments extension is installed but the version is not supported
                The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it.
                """
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Updating",
        comment: "Button to reload plugin data after updating a Card Present Payments extension plugin"
    )
}
