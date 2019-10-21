import Foundation

enum AuthenticationConstants {
    // MARK: - WordPress Authenticator display text customizations
    //

    /// Email login instructions.
    ///
    static let emailInstructions = NSLocalizedString(
        "Log in with your WordPress.com account email address to manage your WooCommerce stores.",
        comment: "Sign in instructions on the 'log in using email' screen."
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
}
