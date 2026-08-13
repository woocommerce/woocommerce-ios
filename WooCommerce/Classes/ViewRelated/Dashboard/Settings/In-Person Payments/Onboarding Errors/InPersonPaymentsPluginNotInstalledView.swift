import SwiftUI

struct InPersonPaymentsPluginNotInstalled: View {
    let analyticReason: String
    let userIsAdministrator: Bool
    let onInstall: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .wcPayPlugin,
                height: 126.0
            ),
            supportLink: false,
            learnMore: true,
            analyticReason: analyticReason,
            plugin: nil,
            buttonViewModel: buttonViewModel
        )
    }
}

extension InPersonPaymentsPluginNotInstalled {
    var message: String {
        userIsAdministrator ? Localization.message : Localization.messageForNonAdministrator
    }

    var buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel? {
        guard userIsAdministrator else {
            return nil
        }

        return InPersonPaymentsOnboardingErrorButtonViewModel(
            text: Localization.title,
            analyticReason: analyticReason,
            plugin: nil,
            action: onInstall
        )
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "inPersonPaymentsPluginNotInstalled.title",
        value: "Install WooPayments",
        comment: "Title for the error screen when WooPayments is not installed"
    )

    static let message = NSLocalizedString(
        "inPersonPaymentsPluginNotInstalled.message",
        value: "You’ll need to install the free WooPayments extension on your store to accept In‑Person Payments.",
        comment: """
                 Error message when WooPayments is not installed
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it.
                 """
    )

    static let messageForNonAdministrator = NSLocalizedString(
        "inPersonPaymentsPluginNotInstalled.messageForNonAdministrator",
        value: "You’ll need the free WooPayments extension installed on your store to accept In‑Person Payments. "
        + "Please ask a store administrator to install it.",
        comment: """
                 Error message when WooPayments is not installed, shown to users who cannot install it themselves.
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it.
                 """
    )
}

struct InPersonPaymentsPluginNotInstalled_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: true, onInstall: {})
            .previewDisplayName("Administrator")

        InPersonPaymentsPluginNotInstalled(analyticReason: "", userIsAdministrator: false, onInstall: {})
            .previewDisplayName("Non-administrator")
    }
}
