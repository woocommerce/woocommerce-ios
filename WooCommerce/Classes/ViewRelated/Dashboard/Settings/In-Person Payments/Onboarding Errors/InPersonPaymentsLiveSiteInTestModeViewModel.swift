import Foundation
import enum Yosemite.CardPresentPaymentsPlugin

struct InPersonPaymentsLiveSiteInTestModeViewModel {
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
        "%1$@ is in Test Mode",
        comment: "Title for the error screen when a card present payments plugin is in test mode on a live site. %1$@ is a placeholder for the plugin name."
    )

    static let message = NSLocalizedString(
        "The %1$@ extension cannot be in test mode for In‑Person Payments. "
            + "Please disable test mode.",
        comment: """
                 Error message when a card present payments plugin is in test mode on a live site. %1$@ is a placeholder for the plugin name.
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Updating",
        comment: "Button to reload plugin data after updating a card present payments plugin settings"
    )
}
