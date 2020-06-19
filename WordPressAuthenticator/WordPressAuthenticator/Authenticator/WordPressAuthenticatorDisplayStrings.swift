import Foundation


// MARK: - WordPress Authenticator Display Strings
//
public struct WordPressAuthenticatorDisplayStrings {
    /// Strings: Login instructions.
    ///
    public let emailLoginInstructions: String

    public let jetpackLoginInstructions: String

    public let siteLoginInstructions: String

    /// Strings: primary call-to-action button titles.
    ///
    public let continueButtonTitle: String

    /// Strings: secondary call-to-action button titles.
    ///
    public let resetPasswordButtonTitle: String

    /// Designated initializer.
    ///
    public init(emailLoginInstructions: String,
                jetpackLoginInstructions: String,
                siteLoginInstructions: String,
                continueButtonTitle: String,
                resetPasswordButtonTitle: String) {
        self.emailLoginInstructions = emailLoginInstructions
        self.jetpackLoginInstructions = jetpackLoginInstructions
        self.siteLoginInstructions = siteLoginInstructions
        self.continueButtonTitle = continueButtonTitle
        self.resetPasswordButtonTitle = resetPasswordButtonTitle
    }
}

public extension WordPressAuthenticatorDisplayStrings {
    static var defaultStrings: WordPressAuthenticatorDisplayStrings {
        return WordPressAuthenticatorDisplayStrings(
            emailLoginInstructions: NSLocalizedString("Log in to your WordPress.com account with your email address.",
                                                      comment: "Instruction text on the login's email address screen."),
            jetpackLoginInstructions: NSLocalizedString("Log in to the WordPress.com account you used to connect Jetpack.",
                                                        comment: "Instruction text on the login's email address screen."),
            siteLoginInstructions: NSLocalizedString("Enter the address of the WordPress site you'd like to connect.",
                                                     comment: "Instruction text on the login's site addresss screen."),
            continueButtonTitle: NSLocalizedString("Continue",
                                                    comment: "The button title text when there is a next step for logging in or signing up."),
            resetPasswordButtonTitle: NSLocalizedString("Reset your password",
                                                        comment: "The secondary call-to-action button title text, for when the user can't remember their password.")
        )
    }
}
