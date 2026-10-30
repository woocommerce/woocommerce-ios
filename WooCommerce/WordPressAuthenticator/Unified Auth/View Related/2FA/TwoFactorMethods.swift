import Foundation

public struct TwoFactorMethods {
    private enum Method: String {
        case backup
        case authenticator
        case sms
        case email
        case webauthn
    }

    private let methods: Set<Method>
    private let challengeMethods: Set<Method>

    public init(supportedAuthTypes: [String], challengeAuthTypes: [String] = []) {
        methods = Set(supportedAuthTypes.compactMap(Method.init(rawValue:)))
        challengeMethods = Set(challengeAuthTypes.compactMap(Method.init(rawValue:)))
    }

    /// Google and Apple logins clear the account's list, so texting a code follows their challenge's list.
    public var canTextCode: Bool {
        (methods.isEmpty ? challengeMethods : methods).contains(.sms)
    }

    /// A security key is the first option when no code method is available.
    public var startsWithSecurityKey: Bool {
        methods.contains(.webauthn) && methods.isDisjoint(with: [.authenticator, .sms, .email])
    }

    public var canUseBackupCode: Bool {
        methods.contains(.backup)
    }

    public func textCodeButtonTitle(defaultTitle: String, hasRequestedTextCode: Bool, isBackupCodeRequested: Bool) -> String {
        let instructions = self.instructions(hasRequestedTextCode: hasRequestedTextCode, isBackupCodeRequested: isBackupCodeRequested)
        return instructions == Localization.textMessage ? Localization.resendTextCode : defaultTitle
    }

    /// `nil` keeps the screen's own authenticator app instructions.
    public func instructions(hasRequestedTextCode: Bool, isBackupCodeRequested: Bool) -> String? {
        if isBackupCodeRequested {
            return Localization.backupCode
        }
        if hasRequestedTextCode {
            return Localization.textMessage
        }
        if startsWithSecurityKey {
            return Localization.securityKey
        }
        if methods.contains(.authenticator) {
            return nil
        }
        if methods.contains(.sms) {
            return Localization.textMessage
        }
        return methods.contains(.email) ? Localization.email : nil
    }
}

private extension TwoFactorMethods {
    enum Localization {
        static let textMessage = NSLocalizedString(
            "twoFactorMethods.textMessageInstructions",
            value: "We sent a text message. Enter the verification code from the message.",
            comment: "Instruction to enter a code sent by text message"
        )
        static let email = NSLocalizedString(
            "twoFactorMethods.emailInstructions",
            value: "Check your email for a verification code from WordPress.com, then enter it to continue.",
            comment: "Instruction to enter a code sent by email"
        )
        static let securityKey = NSLocalizedString(
            "twoFactorMethods.securityKeyInstructions",
            value: "Please provide your security key to continue.",
            comment: "Instruction to use a security key"
        )
        static let backupCode = NSLocalizedString(
            "twoFactorMethods.backupCodeInstructions",
            value: "Enter a backup code to continue.",
            comment: "Instruction to enter a backup code"
        )
        static let resendTextCode = NSLocalizedString(
            "twoFactorMethods.resendTextCodeButton",
            value: "Resend code via SMS",
            comment: "Button to text another verification code when one was already sent by text message"
        )
    }
}
