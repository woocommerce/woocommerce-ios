import Foundation

/// View model for `WPComMagicLinkView`
///
final class WPComMagicLinkViewModel {
    /// The input address from the email login screen.
    let email: String

    /// Title for `WPComMagicLinkView`
    let titleString: String

    init(email: String, requiresConnectionOnly: Bool) {
        self.email = email
        self.titleString = requiresConnectionOnly ? Localization.connectJetpack : Localization.installJetpack
    }
}

extension WPComMagicLinkViewModel {
    enum Localization {
        static let installJetpack = NSLocalizedString(
            "Install Jetpack",
            comment: "Title for the WPCom magic link screen when Jetpack is not installed yet"
        )
        static let connectJetpack = NSLocalizedString(
            "Connect Jetpack",
            comment: "Title for the WPCom magic link screen when Jetpack is not connected yet"
        )
    }
}
