import Foundation


// MARK: - WordPress Authenticator Display Strings
//
public struct WordPressAuthenticatorDisplayStrings {
    /// Strings: Login instructions.
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

public extension WordPressAuthenticatorDisplayStrings {
    static var defaultStrings: WordPressAuthenticatorDisplayStrings {
        return WordPressAuthenticatorDisplayStrings(emailLoginInstructions: NSLocalizedString("Log in to your WordPress.com account with your email address.", comment: "Instruction text on the login's email address screen."),
                                                    jetpackLoginInstructions: NSLocalizedString("Log in to the WordPress.com account you used to connect Jetpack.", comment: "Instruction text on the login's email address screen."),
                                                    siteLoginInstructions: NSLocalizedString("Enter the address of your WordPress site you'd like to connect.", comment: "Instruction text on the login's site addresss screen."))
    }
}
