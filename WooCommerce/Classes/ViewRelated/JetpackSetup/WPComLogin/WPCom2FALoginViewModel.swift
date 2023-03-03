import Foundation

/// View model for `WPCom2FALoginView`.
final class WPCom2FALoginViewModel: ObservableObject {
    @Published var verificationCode: String = ""

    /// Title for the view
    let titleString: String

    /// In case the code is entered by pasting from the clipboard, we need to remove all white spaces.
    var strippedCode: String {
        verificationCode.components(separatedBy: .whitespacesAndNewlines).joined()
    }

    var isValidCode: Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let resultCharacterSet = CharacterSet(charactersIn: strippedCode)
        let isOnlyNumbers = allowedCharacters.isSuperset(of: resultCharacterSet)
        let isValidLength = strippedCode.count <= Constants.maximumCodeLength && strippedCode.isNotEmpty

        if isOnlyNumbers && isValidLength {
            return true
        }
        return false
    }

    init(requiresConnectionOnly: Bool) {
        self.titleString = requiresConnectionOnly ? Localization.connectJetpack : Localization.installJetpack
    }
}

extension WPCom2FALoginViewModel {
    enum Constants {
        // Following the implementation in WordPressAuthenticator
        static let maximumCodeLength = 8
    }
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
