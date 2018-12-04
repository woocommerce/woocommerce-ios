import Foundation


// MARK: - WordPress Authenticator Display Text
//
public struct WordPressAuthenticatorDisplayText {
    /// Text: Login instructions.
    ///
    public let emailLoginInstructions: String

    public let jetpackLoginInstructions: String

    public let siteLoginInstructions: String

    /// Designated initializer.
    ///
    public init(emailLoginInstructions: String, jetpackLoginInstructions: String, siteLoginInstructions: String) {
        self.emailLoginInstructions = emailLoginInstructions
        self.jetpackLoginInstructions = jetpackLoginInstructions
        self.siteLoginInstructions = siteLoginInstructions
    }
}

public extension WordPressAuthenticatorDisplayText {
    public static var defaultText: WordPressAuthenticatorDisplayText {
        return WordPressAuthenticatorDisplayText(emailLoginInstructions: NSLocalizedString("Log in to WordPress.com using an email address to manage all your WordPress sites.", comment: "Instruction text on the login's email address screen."),
                                                 jetpackLoginInstructions: NSLocalizedString("Log in to the WordPress.com account you used to connect Jetpack.", comment: "Instruction text on the login's email address screen."),
                                                 siteLoginInstructions: NSLocalizedString("Enter the address of your WordPress site you'd like to connect.", comment: "Instruction text on the login's site addresss screen."))
    }
}
