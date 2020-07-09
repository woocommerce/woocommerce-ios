import Foundation


// MARK: - WordPress Authenticator Display Strings
//
public struct WordPressAuthenticatorDisplayStrings {
    /// Strings: Login instructions.
    ///
    public let emailLoginInstructions: String
    public let jetpackLoginInstructions: String
    public let siteLoginInstructions: String
	public let siteCredentialInstructions: String

    /// Strings: primary call-to-action button titles.
    ///
    public let continueButtonTitle: String
    
    /// Large titles displayed in unified auth flows.
    ///
    public let gettingStartedTitle: String
    public let logInTitle: String
    public let signUpTitle: String

    /// Strings: secondary call-to-action button titles.
    ///
    public let findSiteButtonTitle: String
    public let resetPasswordButtonTitle: String

    /// Designated initializer.
    ///
    public init(emailLoginInstructions: String,
                jetpackLoginInstructions: String,
                siteLoginInstructions: String,
				siteCredentialInstructions: String,
                continueButtonTitle: String,
                findSiteButtonTitle: String,
                resetPasswordButtonTitle: String,
                gettingStartedTitle: String,
                logInTitle: String,
                signUpTitle: String) {
        self.emailLoginInstructions = emailLoginInstructions
        self.jetpackLoginInstructions = jetpackLoginInstructions
        self.siteLoginInstructions = siteLoginInstructions
		self.siteCredentialInstructions = siteCredentialInstructions
        self.continueButtonTitle = continueButtonTitle
        self.findSiteButtonTitle = findSiteButtonTitle
        self.resetPasswordButtonTitle = resetPasswordButtonTitle
        self.gettingStartedTitle = gettingStartedTitle
        self.logInTitle = logInTitle
        self.signUpTitle = signUpTitle
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
			siteCredentialInstructions: NSLocalizedString("Enter your account information for %@",
														  comment: "Enter your account information for {site url}. Asks the user to enter a username and password for their self-hosted site."),
            continueButtonTitle: NSLocalizedString("Continue",
                                                    comment: "The button title text when there is a next step for logging in or signing up."),
            findSiteButtonTitle: NSLocalizedString("Find your site address",
                                                   comment: "The hint button's title text to help users find their site address."),
            resetPasswordButtonTitle: NSLocalizedString("Reset your password",
                                                        comment: "The secondary call-to-action button title text, for when the user can't remember their password."),
            gettingStartedTitle: NSLocalizedString("Getting Started",
                                                   comment: "View title for initial auth views."),
            logInTitle: NSLocalizedString("Log In",
                                          comment: "View title during the log in process."),
            signUpTitle: NSLocalizedString("Sign Up",
                                           comment: "View title during the sign up process.")
        )
    }
}
