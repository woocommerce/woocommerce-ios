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
    /// Login with Jetpack instructions.
    ///
    static let jetpackInstructions = NSLocalizedString(
        "Log in with your WordPress.com account email address to manage your WooCommerce stores.",
        comment: "Sign in instructions on the 'log in using email' screen."
    )

    /// Login with site URL instructions.
    ///
    static let siteInstructions = NSLocalizedString(
        "Enter the address of your WooCommerce store you'd like to connect.",
        comment: "Sign in instructions for logging in with a URL."
    )

    static let usernamePasswordInstructions = NSLocalizedString(
        "Log in with your WordPress.com account to manage your WooCommerce stores.",
        comment: "Sign in instructions for logging in with a username and password."
    )
    
    /// Title of "Continue With WordPress.com" button in Login Prologue
    //
    static let continueWithWPButtontitle = NSLocalizedString(
        "Continue With WordPress.com",
        comment: "Button title. Takes the user to the login by email flow."
    )
    
    /// Title of "Enter your store address" button in Login Prologue
    //
    static let enterYourSiteAddressButtonTitle = NSLocalizedString(
        "Enter Your Store Address",
        comment: "Button title. Takes the user to the login by store address flow."
    )
}
