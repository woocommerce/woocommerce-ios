import Foundation

struct AuthenticationConstants {
    // MARK: - WordPress Authenticator display text customizations
    //

    /// Email login instructions.
    ///
    static let emailInstructions = NSLocalizedString(
        "Log in with your WordPress.com account email address to manage your WooCommerce stores.",
        comment: "Sign in instructions on the 'log in using email' screen."
    )

    /// Get started instructions (Continue with WordPress.com)
    ///
    static let getStartedInstructions = NSLocalizedString(
        "Log in with your WordPress.com account email address to manage your WooCommerce stores.",
        comment: "Sign in instructions on the 'log in using WordPress.com account' screen."
    )

    /// Get started instructions (Continue with WordPress.com) when signup is enabled.
    ///
    static let getStartedInstructionsWithWPComSignupEnabled = NSLocalizedString(
        "Enter your email address to log in to manage your WooCommerce stores or create a WordPress.com account.",
        comment: "Sign in instructions on the 'log in using WordPress.com account' screen."
    )

    /// What is WordPress.com? link (Continue with WordPress.com)
    ///
    static let whatIsWPComLinkTitle = NSLocalizedString(
        "What is WordPress.com?",
        comment: "Navigates to page with details about What is WordPress.com."
    )

    /// Login with Jetpack instructions.
    ///
    static let jetpackInstructions = NSLocalizedString(
        "Log in with your WordPress.com account email address to manage your WooCommerce stores.",
        comment: "Sign in instructions on the 'log in using email' screen."
    )

    /// Login with site URL instructions.
    ///
    static let siteInstructions = NSLocalizedString(
        "Enter the address of the WooCommerce store you'd like to connect.",
        comment: "Sign in instructions for logging in with a URL."
    )

    static let usernamePasswordInstructions = NSLocalizedString(
        "Log in with your WordPress.com account to manage your WooCommerce stores.",
        comment: "Sign in instructions for logging in with a username and password."
    )

    /// Sign in using Apple screen's instructions.
    ///
    static let applePasswordInstructions = NSLocalizedString(
        "To proceed with this account, please first log in with your WordPress.com password. This will only be asked once.",
        comment: "Sign in instructions asking user to enter WordPress.com password to proceed with sign in using Apple process"
    )

    /// Title of "Continue With WordPress.com" button in Login Prologue
    //
    static let continueWithWPButtonTitle = NSLocalizedString(
        "Continue With WordPress.com",
        comment: "Button title. Takes the user to the login with WordPress.com flow."
    )

    /// Title of "Enter your store address" button in Login Prologue
    //
    static let enterYourSiteAddressButtonTitle = NSLocalizedString(
        "Enter Your Store Address",
        comment: "Button title. Takes the user to the login by store address flow."
    )

    /// Title of "Sign in with store credentials" button
    //
    static let signInWithSiteCredsButtonTitle = NSLocalizedString(
        "Sign in with store credentials",
        comment: "Button title. Takes the user to the site credentials entry screen."
    )

    /// Instruction in Enter Site Credentials screen.
    //
    static let siteCredentialInstructions = NSLocalizedString(
        "Enter your store credentials for %@.",
        comment: "Enter your store credentials for {site url}. Asks the user to enter .org site credentials for their store."
    )

    /// Title of views in Unified Login
    //
    static let loginTitle = NSLocalizedString(
        "Log In",
        comment: "View title during the log in process."
    )

    /// Title of "Find your store address" button in Unified Login flow
    //
    static let findYourStoreAddressButtonTitle = NSLocalizedString(
        "Find your store address",
        comment: "The hint button's title text to help users find their store address."
    )

    /// Footer for Terms of Service of Sign In With Apple and Sign In with Google
    //
    static let signupTermsOfService = NSLocalizedString(
        "If you continue with Apple and don't already have a WordPress.com account, you are creating an account and you agree to our _Terms of Service_.",
        comment: "Legal disclaimer for signing up. The underscores _..._ denote underline."
    )

    /// Get Started button in Simplified login flow
    ///
    static let createSiteButtonTitle = NSLocalizedString(
        "Get Started",
        comment: "Button displayed on the prologue screen of the simplified login flow to create a new store"
    )

    /// Instructions for WPCom password
    ///
    static let wpcomPasswordInstructions = NSLocalizedString(
        "Enter the password for your account.",
        comment: "Instructional text shown when requesting the user's password for WPCom login."
    )
}
