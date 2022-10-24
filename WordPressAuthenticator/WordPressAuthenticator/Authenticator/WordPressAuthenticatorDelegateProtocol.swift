// MARK: - WordPressAuthenticator Delegate Protocol
//
public protocol WordPressAuthenticatorDelegate: AnyObject {

    /// Indicates if the active Authenticator can be dismissed, or not.
    ///
    var dismissActionEnabled: Bool { get }

    /// Indicates if the Support button action should be enabled, or not.
    ///
    var supportActionEnabled: Bool { get }

    /// Indicates if the WordPress.com's Terms of Service should be enabled, or not.
    ///
    var wpcomTermsOfServiceEnabled: Bool { get }

    /// Indicates if the Support notification indicator should be displayed.
    ///
    var showSupportNotificationIndicator: Bool { get }

    /// Indicates if Support is available or not.
    ///
    var supportEnabled: Bool { get }

    /// Returns true if there isn't a default WordPress.com account connected in the app.
    var allowWPComLogin: Bool { get }

    /// Signals the Host App that a new WordPress.com account has just been created.
    ///
    /// - Parameters:
    ///     - username: WordPress.com Username.
    ///     - authToken: WordPress.com Bearer Token.
    ///
    func createdWordPressComAccount(username: String, authToken: String)

    /// Signals the Host App that the user has successfully authenticated with an Apple account.
    ///
    /// - Parameters:
    ///     - appleUserID: User ID received in the Apple credentials.
    ///
    func userAuthenticatedWithAppleUserID(_ appleUserID: String)

    /// Presents the Support new request, from a given ViewController, with a specified SourceTag.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag)

    /// Signals to the Host App that a WordPress site is available and needs validated
    /// before presenting the username and password view controller.
    /// - Parameters:
    ///     - site: passes in the site information to the delegate method.
    ///     - onCompletion: Closure to be executed on completion.
    ///
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void)

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void)

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?)

    /// Presents the Support Interface from a given ViewController.
    ///
    /// - Parameters:
    ///     - from: ViewController from which to present the support interface from
    ///     - sourceTag: Support source tag of the view controller.
    ///     - lastStep: Last `Step` tracked in `AuthenticatorAnalyticsTracker`
    ///     - lastFlow: Last `Flow` tracked in `AuthenticatorAnalyticsTracker`
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, lastStep: AuthenticatorAnalyticsTracker.Step, lastFlow: AuthenticatorAnalyticsTracker.Flow)

    /// Indicates if the Login Epilogue should be displayed.
    ///
    /// - Parameter isJetpackLogin: Indicates if we've just logged into a WordPress.com account for Jetpack purposes!.
    ///
    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool

    /// Indicates the Host app wants to handle and display a given error.
    ///
    func shouldHandleError(_ error: Error) -> Bool

    /// Signals the Host app that there is an error that needs to be handled.
    ///
    func handleError(_ error: Error, onCompletion: @escaping (UIViewController) -> Void)

    /// Indicates if the Signup Epilogue should be displayed.
    ///
    func shouldPresentSignupEpilogue() -> Bool

    /// Signals the Host App that a WordPress Site (wpcom or wporg) is available with the specified credentials.
    ///
    /// - Parameters:
    ///     - credentials: WordPress Site Credentials.
    ///     - onCompletion: Closure to be executed on completion.
    ///
    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void)

    /// Signals to the Host App that a WordPress site is available and needs validated.
    /// This method is only triggered in the site discovery flow.
    ///
    /// - Parameters:
    ///     - siteInfo: The fetched site information - can be nil the site doesn't exist or have WordPress
    ///     - navigationController: the current navigation stack of the site discovery flow.
    ///
    func troubleshootSite(_ siteInfo: WordPressComSiteInfo?, in navigationController: UINavigationController?)

    /// Signals to the Host App to navigate to the account creation flow.
    /// This method is currently used only in the simplified login flow
    /// when the configuration `enableSimplifiedLoginI1` is enabled
    ///
    /// - Parameters:
    ///     - navigationController: the current navigation stack of the login flow.
    ///
    func showAccountCreation(in navigationController: UINavigationController?)

    /// Signals the Host App that a given Analytics Event has occurred.
    ///
    func track(event: WPAnalyticsStat)

    /// Signals the Host App that a given Analytics Event (with the specified properties) has occurred.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any])

    /// Signals the Host App that a given Analytics Event (with an associated Error) has occurred.
    ///
    func track(event: WPAnalyticsStat, error: Error)
}

/// Extension with default implementation for optional delegate methods.
///
public extension WordPressAuthenticatorDelegate {
    func troubleshootSite(_ siteInfo: WordPressComSiteInfo?, in navigationController: UINavigationController?) {
        // No-op
    }

    func showAccountCreation(in navigationController: UINavigationController?) {
        // No-op
    }
}
