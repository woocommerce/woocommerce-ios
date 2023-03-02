import Foundation

/// View model for `WPComPasswordLoginView`.
///
final class WPComPasswordLoginViewModel {

    /// Title of the view.
    let titleString: String

    /// Username/email address of the WPCom account
    private let username: String

    init(username: String, requiresConnectionOnly: Bool) {
        self.username = username
        self.titleString = requiresConnectionOnly ? Localization.connectJetpack : Localization.installJetpack
    }
}

extension WPComPasswordLoginViewModel {
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
