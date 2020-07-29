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
    public let twoFactorInstructions: String

    /// Strings: primary call-to-action button titles.
    ///
    public let continueButtonTitle: String
    
    /// Large titles displayed in unified auth flows.
    ///
    public let gettingStartedTitle: String
    public let logInTitle: String
    public let signUpTitle: String
    public let waitingForGoogleTitle: String

    /// Strings: secondary call-to-action button titles.
    ///
    public let findSiteButtonTitle: String
    public let resetPasswordButtonTitle: String
    public let textCodeButtonTitle: String

	/// Placeholder text for textfields.
	///
	public let usernamePlaceholder: String
	public let passwordPlaceholder: String
    public let siteAddressPlaceholder: String
    public let twoFactorCodePlaceholder: String

    /// Designated initializer.
    ///
    public init(emailLoginInstructions: String,
                jetpackLoginInstructions: String,
                siteLoginInstructions: String,
				siteCredentialInstructions: String,
                twoFactorInstructions: String,
                continueButtonTitle: String,
                findSiteButtonTitle: String,
                resetPasswordButtonTitle: String,
                textCodeButtonTitle: String,
                gettingStartedTitle: String,
                logInTitle: String,
                signUpTitle: String,
                waitingForGoogleTitle: String,
				usernamePlaceholder: String,
				passwordPlaceholder: String,
                siteAddressPlaceholder: String,
                twoFactorCodePlaceholder: String) {
        self.emailLoginInstructions = emailLoginInstructions
        self.jetpackLoginInstructions = jetpackLoginInstructions
        self.siteLoginInstructions = siteLoginInstructions
		self.siteCredentialInstructions = siteCredentialInstructions
        self.twoFactorInstructions = twoFactorInstructions
        self.continueButtonTitle = continueButtonTitle
        self.findSiteButtonTitle = findSiteButtonTitle
        self.resetPasswordButtonTitle = resetPasswordButtonTitle
        self.textCodeButtonTitle = textCodeButtonTitle
        self.gettingStartedTitle = gettingStartedTitle
        self.logInTitle = logInTitle
        self.signUpTitle = signUpTitle
        self.waitingForGoogleTitle = waitingForGoogleTitle
		self.usernamePlaceholder = usernamePlaceholder
		self.passwordPlaceholder = passwordPlaceholder
        self.siteAddressPlaceholder = siteAddressPlaceholder
        self.twoFactorCodePlaceholder = twoFactorCodePlaceholder
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
			siteCredentialInstructions: NSLocalizedString("Enter your account information for %@.",
														  comment: "Enter your account information for {site url}. Asks the user to enter a username and password for their self-hosted site."),
            twoFactorInstructions: NSLocalizedString("Please enter the verification code from your authenticator app, or tap the link below to receive a code via SMS.",
                                                     comment: "Instruction text on the two-factor screen."),
            continueButtonTitle: NSLocalizedString("Continue",
                                                    comment: "The button title text when there is a next step for logging in or signing up."),
            findSiteButtonTitle: NSLocalizedString("Find your site address",
                                                   comment: "The hint button's title text to help users find their site address."),
            resetPasswordButtonTitle: NSLocalizedString("Reset your password",
                                                        comment: "The secondary call-to-action button title text, for when the user can't remember their password."),
            textCodeButtonTitle: NSLocalizedString("Text me a code instead",
                                                   comment: "The button's title text to send a 2FA code via SMS text message."),
            
            gettingStartedTitle: NSLocalizedString("Getting Started",
                                                   comment: "View title for initial auth views."),
            logInTitle: NSLocalizedString("Log In",
                                          comment: "View title during the log in process."),
            signUpTitle: NSLocalizedString("Sign Up",
                                           comment: "View title during the sign up process."),
            waitingForGoogleTitle: NSLocalizedString("Waiting...",
                                                     comment: "View title during the Google auth process."),
			usernamePlaceholder: NSLocalizedString("Username",
												   comment: "Placeholder for the username textfield."),
			passwordPlaceholder: NSLocalizedString("Password",
												   comment: "Placeholder for the password textfield."),
            siteAddressPlaceholder: NSLocalizedString("example.com",
                                                  comment: "Placeholder for the site url textfield."),
            twoFactorCodePlaceholder: NSLocalizedString("Authentication code",
                                                  comment: "Placeholder for the 2FA code textfield.")
        )
    }
}
