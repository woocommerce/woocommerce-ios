import Foundation

/// View model for `WPCom2FALoginView`.
final class WPCom2FALoginViewModel: ObservableObject {
    @Published var verificationCode: String = ""

    /// Title for the view
    let titleString: String

    init(requiresConnectionOnly: Bool) {
        self.titleString = requiresConnectionOnly ? Localization.connectJetpack : Localization.installJetpack
    }
}

extension WPCom2FALoginViewModel {
    enum Localization {
        static let installJetpack = NSLocalizedString(
            "Install Jetpack",
            comment: "Title for the WPCom 2FA login screen when Jetpack is not installed yet"
        )
        static let connectJetpack = NSLocalizedString(
            "Connect Jetpack",
            comment: "Title for the WPCom 2FA login screen when Jetpack is not connected yet"
        )
    }
}
