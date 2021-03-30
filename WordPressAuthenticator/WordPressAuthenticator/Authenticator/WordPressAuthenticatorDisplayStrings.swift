import Foundation

// MARK: - WordPress Authenticator Display Strings
//
public struct WordPressAuthenticatorDisplayStrings {
    /// Strings: Login instructions.
    ///
    public let emailLoginInstructions: String
    public let getStartedInstructions: String
    public let jetpackLoginInstructions: String
    public let siteLoginInstructions: String
	public let siteCredentialInstructions: String
    public let usernamePasswordInstructions: String
    public let twoFactorInstructions: String
    public let magicLinkSignupInstructions: String
    public let openMailSignupInstructions: String
    public let openMailLoginInstructions: String
    public let checkSpamInstructions: String
    public let oopsInstructions: String
    public let googleSignupInstructions: String
    public let googlePasswordInstructions: String
    public let applePasswordInstructions: String

    /// Strings: primary call-to-action button titles.
    ///
    public let continueButtonTitle: String
    public let magicLinkButtonTitle: String
    public let openMailButtonTitle: String
    public let createAccountButtonTitle: String
    public let continueWithWPButtonTitle: String
    public let enterYourSiteAddressButtonTitle: String

    /// Large titles displayed in unified auth flows.
    ///
    public let getStartedTitle: String
    public let logInTitle: String
    public let signUpTitle: String
    public let waitingForGoogleTitle: String

    /// Strings: secondary call-to-action button titles.
    ///
    public let findSiteButtonTitle: String
    public let resetPasswordButtonTitle: String
    public let getLoginLinkButtonTitle: String
    public let textCodeButtonTitle: String
    public let loginTermsOfService: String
    public let signupTermsOfService: String

	/// Placeholder text for textfields.
	///
	public let usernamePlaceholder: String
	public let passwordPlaceholder: String
    public let siteAddressPlaceholder: String
    public let twoFactorCodePlaceholder: String
    public let emailAddressPlaceholder: String

    /// Designated initializer.
    ///
    public init(emailLoginInstructions: String = defaultStrings.emailLoginInstructions,
                getStartedInstructions: String = defaultStrings.getStartedInstructions,
                jetpackLoginInstructions: String = defaultStrings.jetpackLoginInstructions,
                siteLoginInstructions: String = defaultStrings.siteLoginInstructions,
                siteCredentialInstructions: String = defaultStrings.siteCredentialInstructions,
                usernamePasswordInstructions: String = defaultStrings.usernamePasswordInstructions,
                twoFactorInstructions: String = defaultStrings.twoFactorInstructions,
                magicLinkSignupInstructions: String = defaultStrings.magicLinkSignupInstructions,
                openMailSignupInstructions: String = defaultStrings.openMailSignupInstructions,
                openMailLoginInstructions: String = defaultStrings.openMailLoginInstructions,
                checkSpamInstructions: String = defaultStrings.checkSpamInstructions,
                oopsInstructions: String = defaultStrings.oopsInstructions,
                googleSignupInstructions: String = defaultStrings.googleSignupInstructions,
                googlePasswordInstructions: String = defaultStrings.googlePasswordInstructions,
                applePasswordInstructions: String = defaultStrings.applePasswordInstructions,
                continueButtonTitle: String = defaultStrings.continueButtonTitle,
                magicLinkButtonTitle: String = defaultStrings.magicLinkButtonTitle,
                openMailButtonTitle: String = defaultStrings.openMailButtonTitle,
                createAccountButtonTitle: String = defaultStrings.createAccountButtonTitle,
                continueWithWPButtonTitle: String = defaultStrings.continueWithWPButtonTitle,
                enterYourSiteAddressButtonTitle: String = defaultStrings.enterYourSiteAddressButtonTitle,
                findSiteButtonTitle: String = defaultStrings.findSiteButtonTitle,
                resetPasswordButtonTitle: String = defaultStrings.resetPasswordButtonTitle,
                getLoginLinkButtonTitle: String = defaultStrings.getLoginLinkButtonTitle,
                textCodeButtonTitle: String = defaultStrings.textCodeButtonTitle,
                loginTermsOfService: String = defaultStrings.loginTermsOfService,
                signupTermsOfService: String = defaultStrings.signupTermsOfService,
                getStartedTitle: String = defaultStrings.getStartedTitle,
                logInTitle: String = defaultStrings.logInTitle,
                signUpTitle: String = defaultStrings.signUpTitle,
                waitingForGoogleTitle: String = defaultStrings.waitingForGoogleTitle,
                usernamePlaceholder: String = defaultStrings.usernamePlaceholder,
                passwordPlaceholder: String = defaultStrings.passwordPlaceholder,
                siteAddressPlaceholder: String = defaultStrings.siteAddressPlaceholder,
                twoFactorCodePlaceholder: String = defaultStrings.twoFactorCodePlaceholder,
                emailAddressPlaceholder: String = defaultStrings.emailAddressPlaceholder) {
        self.emailLoginInstructions = emailLoginInstructions
        self.getStartedInstructions = getStartedInstructions
        self.jetpackLoginInstructions = jetpackLoginInstructions
        self.siteLoginInstructions = siteLoginInstructions
		self.siteCredentialInstructions = siteCredentialInstructions
        self.usernamePasswordInstructions = usernamePasswordInstructions
        self.twoFactorInstructions = twoFactorInstructions
        self.magicLinkSignupInstructions = magicLinkSignupInstructions
        self.openMailSignupInstructions = openMailSignupInstructions
        self.openMailLoginInstructions = openMailLoginInstructions
        self.checkSpamInstructions = checkSpamInstructions
        self.oopsInstructions = oopsInstructions
        self.googleSignupInstructions = googleSignupInstructions
        self.googlePasswordInstructions = googlePasswordInstructions
        self.applePasswordInstructions = applePasswordInstructions
        self.continueButtonTitle = continueButtonTitle
        self.magicLinkButtonTitle = magicLinkButtonTitle
        self.openMailButtonTitle = openMailButtonTitle
        self.createAccountButtonTitle = createAccountButtonTitle
        self.continueWithWPButtonTitle = continueWithWPButtonTitle
        self.enterYourSiteAddressButtonTitle = enterYourSiteAddressButtonTitle
        self.findSiteButtonTitle = findSiteButtonTitle
        self.resetPasswordButtonTitle = resetPasswordButtonTitle
        self.getLoginLinkButtonTitle = getLoginLinkButtonTitle
        self.textCodeButtonTitle = textCodeButtonTitle
        self.loginTermsOfService = loginTermsOfService
        self.signupTermsOfService = signupTermsOfService
        self.getStartedTitle = getStartedTitle
        self.logInTitle = logInTitle
        self.signUpTitle = signUpTitle
        self.waitingForGoogleTitle = waitingForGoogleTitle
		self.usernamePlaceholder = usernamePlaceholder
		self.passwordPlaceholder = passwordPlaceholder
        self.siteAddressPlaceholder = siteAddressPlaceholder
        self.twoFactorCodePlaceholder = twoFactorCodePlaceholder
        self.emailAddressPlaceholder = emailAddressPlaceholder
    }
}

public extension WordPressAuthenticatorDisplayStrings {
    static var defaultStrings: WordPressAuthenticatorDisplayStrings {
        return WordPressAuthenticatorDisplayStrings(
            emailLoginInstructions: NSLocalizedString("Log in to your WordPress.com account with your email address.",
                                                      comment: "Instruction text on the login's email address screen."),
            getStartedInstructions: NSLocalizedString("Enter your email address to log in or create a WordPress.com account.",
                                                      comment: "Instruction text on the initial email address entry screen."),
            jetpackLoginInstructions: NSLocalizedString("Log in to the WordPress.com account you used to connect Jetpack.",
                                                        comment: "Instruction text on the login's email address screen."),
            siteLoginInstructions: NSLocalizedString("Enter the address of the WordPress site you'd like to connect.",
                                                     comment: "Instruction text on the login's site addresss screen."),
            siteCredentialInstructions: NSLocalizedString("Enter your account information for %@.",
                                                          comment: "Enter your account information for {site url}. Asks the user to enter a username and password for their self-hosted site."),
            usernamePasswordInstructions: NSLocalizedString("Log in with your WordPress.com username and password.",
                                                            comment: "Instructions on the WordPress.com username / password log in form."),
            twoFactorInstructions: NSLocalizedString("Please enter the verification code from your authenticator app, or tap the link below to receive a code via SMS.",
                                                     comment: "Instruction text on the two-factor screen."),
            magicLinkSignupInstructions: NSLocalizedString("We'll email you a signup link to create your new WordPress.com account.",
                                                           comment: "Instruction text on the Sign Up screen."),
            openMailSignupInstructions: NSLocalizedString("We've emailed you a signup link to create your new WordPress.com account. Check your email on this device, and tap the link in the email you receive from WordPress.com.",
                                                          comment: "Instruction text after a signup Magic Link was requested."),
            openMailLoginInstructions: NSLocalizedString("Check your email on this device, and tap the link in the email you receive from WordPress.com.",
                                                         comment: "Instruction text after a login Magic Link was requested."),
            checkSpamInstructions: NSLocalizedString("Not seeing the email? Check your Spam or Junk Mail folder.", comment: "Instructions after a Magic Link was sent, but the email can't be found in their inbox."),
            oopsInstructions: NSLocalizedString("Didn't mean to create a new account? Go back to re-enter your email address.", comment: "Instructions after a Magic Link was sent, but email is incorrect."),
            googleSignupInstructions: NSLocalizedString("We'll use this email address to create your new WordPress.com account.", comment: "Text confirming email address to be used for new account."),
            googlePasswordInstructions: NSLocalizedString("To proceed with this Google account, please first log in with your WordPress.com password. This will only be asked once.",
                                                          comment: "Instructional text shown when requesting the user's password for Google login."),
            applePasswordInstructions: NSLocalizedString("To proceed with this Apple ID, please first log in with your WordPress.com password. This will only be asked once.",
                                                         comment: "Instructional text shown when requesting the user's password for Apple login."),
            continueButtonTitle: NSLocalizedString("Continue",
                                                   comment: "The button title text when there is a next step for logging in or signing up."),
            magicLinkButtonTitle: NSLocalizedString("Send Link by Email",
                                                    comment: "The button title text for sending a magic link."),
            openMailButtonTitle: NSLocalizedString("Open Mail",
                                                   comment: "The button title text for opening the user's preferred email app."),
            createAccountButtonTitle: NSLocalizedString("Create Account",
                                                        comment: "The button title text for creating a new account."),
            continueWithWPButtonTitle: NSLocalizedString("Log in or sign up with WordPress.com",
                                               comment: "Button title. Takes the user to the login by email flow."),
            enterYourSiteAddressButtonTitle: NSLocalizedString("Enter your existing site address",
                                                               comment: "Button title. Takes the user to the login by site address flow."),
            findSiteButtonTitle: NSLocalizedString("Find your site address",
                                                   comment: "The hint button's title text to help users find their site address."),
            resetPasswordButtonTitle: NSLocalizedString("Reset your password",
                                                        comment: "The button title for a secondary call-to-action button. When the user can't remember their password."),
            getLoginLinkButtonTitle: NSLocalizedString("Get a login link by email",
                                                       comment: "The button title for a secondary call-to-action button. When the user wants to try sending a magic link instead of entering a password."),
            textCodeButtonTitle: NSLocalizedString("Text me a code instead",
                                                   comment: "The button's title text to send a 2FA code via SMS text message."),
            loginTermsOfService: NSLocalizedString("By continuing, you agree to our _Terms of Service_.", comment: "Legal disclaimer for logging in. The underscores _..._ denote underline."),
            signupTermsOfService: NSLocalizedString("If you continue with Apple or Google and don't already have a WordPress.com account, you are creating an account and you agree to our _Terms of Service_.", comment: "Legal disclaimer for signing up. The underscores _..._ denote underline."),
            getStartedTitle: NSLocalizedString("Get Started",
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
                                                        comment: "Placeholder for the 2FA code textfield."),
            emailAddressPlaceholder: NSLocalizedString("Email address",
                                                       comment: "Placeholder for the email address textfield.")
        )
    }
}
