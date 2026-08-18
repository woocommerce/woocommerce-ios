/// The authentication endpoint a site credential login attempt is currently trying to establish.
///
public enum SiteCredentialRecoveryEndpoint: Equatable {
    case login
    case admin
}

/// Why a candidate endpoint entered by the merchant could not be used.
///
public enum SiteCredentialRecoveryError: Equatable {
    case invalidURL
    case differentSite
    case notFound
}

/// A request for the merchant to confirm where one of the site's authentication endpoints lives.
///
/// `draftURL` is the address to prefill. The `admin` case also carries the already verified login
/// entry so it survives the second round trip.
///
public enum SiteCredentialRecovery: Equatable {
    case login(draftURL: String, error: SiteCredentialRecoveryError?)
    case admin(verifiedLoginURL: String, draftURL: String, error: SiteCredentialRecoveryError?)
}

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
    /// - Parameters:
    ///   - navigationController: navigation stack for any epilogue views to be shown on.
    ///   - credentials: WPCOM or WPORG credentials.
    ///   - source: an optional identifier of the login flow, can be from the login prologue or provided by the host app.
    ///   - onDismiss: called when the auth flow is dismissed.
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, source: SignInSource?, onDismiss: @escaping () -> Void)

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(
        in navigationController: UINavigationController,
        for credentials: AuthenticatorCredentials,
        socialUser: SocialUser?
    )

    /// Presents the Support Interface from a given ViewController.
    ///
    /// - Parameters:
    ///     - from: ViewController from which to present the support interface from
    ///     - sourceTag: Support source tag of the view controller.
    ///     - lastStep: Last `Step` tracked in `AuthenticatorAnalyticsTracker`
    ///     - lastFlow: Last `Flow` tracked in `AuthenticatorAnalyticsTracker`
    ///
    func presentSupport(from sourceViewController: UIViewController,
                        sourceTag: WordPressSupportSourceTag,
                        lastStep: AuthenticatorAnalyticsTracker.Step,
                        lastFlow: AuthenticatorAnalyticsTracker.Flow,
                        siteURL: String?)

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

    /// Sends site credentials to the host app so that it can handle login locally.
    /// This method is only triggered when the config `skipXMLRPCCheckForSiteAddressLogin` is enabled.
    ///
    /// - Parameters:
    ///     - credentials: WordPress.org credentials submitted in the site credentials form.
    ///     - onLoading: the block to update the loading state on the site credentials form when necessary.
    ///     - onSuccess: the block to finish the login flow after login succeeds.
    ///     - onFailure: the block to trigger error handling. The closure accepts an error and a boolean indicating if the login failed with incorrect credentials.
    ///
    func handleSiteCredentialLogin(credentials: WordPressOrgCredentials,
                                   onLoading: @escaping (Bool) -> Void,
                                   onSuccess: @escaping () -> Void,
                                   onFailure: @escaping (Error, Bool) -> Void)

    /// Asks the Host App to authenticate site credentials against explicitly configured endpoints.
    ///
    /// This is the endpoint-aware counterpart of `handleSiteCredentialLogin`. It lets the Host App ask the merchant
    /// where the sign-in page or the dashboard lives when they are not at the standard addresses.
    ///
    /// - Parameters:
    ///     - credentials: WordPress.org credentials submitted in the site credentials form.
    ///     - loginURL: the login entry address to use, or `nil` to use the standard one.
    ///     - adminURL: the admin base address to use, or `nil` to use the standard one.
    ///     - endpointUnderVerification: the endpoint this attempt is trying to confirm, or `nil` for an ordinary attempt.
    ///     - onLoading: the block to update the loading state on the site credentials form when necessary.
    ///     - onSuccess: the block to finish the login flow, carrying credentials that record the verified endpoints.
    ///     - onRecovery: the block asking the merchant to supply an endpoint address.
    ///     - onFailure: the block to trigger error handling. The closure accepts an error, a boolean indicating if the
    ///       login failed with incorrect credentials, the verified login entry address when one is already known,
    ///       and whether browser authentication could plausibly solve this credential-response failure.
    ///
    func authenticateSiteCredentials(credentials: WordPressOrgCredentials,
                                     loginURL: String?,
                                     adminURL: String?,
                                     endpointUnderVerification: SiteCredentialRecoveryEndpoint?,
                                     onLoading: @escaping (Bool) -> Void,
                                     onSuccess: @escaping (WordPressOrgCredentials) -> Void,
                                     onRecovery: @escaping (SiteCredentialRecovery) -> Void,
                                     onFailure: @escaping (Error, Bool, String?, Bool) -> Void)

    /// Signals to the Host App that the merchant explicitly asked to authenticate with a browser instead.
    ///
    /// - Parameters:
    ///     - siteURL: The site URL being authenticated.
    ///     - viewController: the view controller containing the site credential input.
    ///
    func presentSiteCredentialBrowserAlternative(for siteURL: String, in viewController: UIViewController)

    /// Signals to the Host App to handle an error for site credential login, stating whether a browser
    /// alternative may still be offered to the merchant.
    ///
    /// - Parameters:
    ///     - error: The site credential login failure.
    ///     - offersBrowserAlternative: whether the failure is one the browser flow could plausibly solve.
    ///     - siteURL: The site URL of the login failure.
    ///     - viewController: the view controller containing the site credential input.
    ///
    func presentSiteCredentialLoginFailure(error: Error,
                                           offersBrowserAlternative: Bool,
                                           for siteURL: String,
                                           in viewController: UIViewController)

    /// Signals to the Host App to handle an error for site credential login.
    ///
    /// - Parameters:
    ///     - error: The site credential login failure.
    ///     - siteURL: The site URL of the login failure.
    ///     - viewController: the view controller containing the site credential input.
    ///
    func handleSiteCredentialLoginFailure(error: Error,
                                          for siteURL: String,
                                          in viewController: UIViewController)

    /// Signals to the Host App to navigate to the site creation flow.
    /// This method is currently used only in the simplified login flow
    /// when the configs `enableSimplifiedLoginI1` and `enableSiteCreationForSimplifiedLoginI1` is enabled
    ///
    /// - Parameters:
    ///     - navigationController: the current navigation stack of the login flow.
    ///
    func showSiteCreation(in navigationController: UINavigationController)

    /// Signals to the Host App to navigate to the site creation guide.
    /// This method triggered only if `enableSiteCreationGuide` config is enabled.
    ///
    /// - Parameters:
    ///     - navigationController: the current navigation stack of the login flow.
    ///
    func showSiteCreationGuide(in navigationController: UINavigationController)

    /// Called when the site-info check fails. The host app should attempt API discovery
    /// to determine if the site has a WordPress REST API, log the failure, and report back.
    ///
    /// - Parameters:
    ///     - siteURL: The site URL that failed the site-info check.
    ///     - error: The error from the site-info check.
    ///     - completion: Called with `true` if API discovery found a WordPress REST API, `false` otherwise.
    ///
    func handleSiteInfoFailure(siteURL: String, error: Error, completion: @escaping (Bool) -> Void)

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

    func showSiteCreation(in navigationController: UINavigationController) {
        // No-op
    }

    func showSiteCreationGuide(in navigationController: UINavigationController) {
        // No-op
    }

    func handleSiteCredentialLogin(credentials: WordPressOrgCredentials,
                                   onLoading: @escaping (Bool) -> Void,
                                   onSuccess: @escaping () -> Void,
                                   onFailure: @escaping (Error, Bool) -> Void) {
        // No-op
    }

    /// Bridges the endpoint-aware contract onto Host Apps that only adopt the legacy one, so they keep
    /// their existing behaviour and never see an endpoint recovery request.
    ///
    func authenticateSiteCredentials(credentials: WordPressOrgCredentials,
                                     loginURL: String?,
                                     adminURL: String?,
                                     endpointUnderVerification: SiteCredentialRecoveryEndpoint?,
                                     onLoading: @escaping (Bool) -> Void,
                                     onSuccess: @escaping (WordPressOrgCredentials) -> Void,
                                     onRecovery: @escaping (SiteCredentialRecovery) -> Void,
                                     onFailure: @escaping (Error, Bool, String?, Bool) -> Void) {
        handleSiteCredentialLogin(
            credentials: credentials,
            onLoading: onLoading,
            onSuccess: { onSuccess(credentials) },
            onFailure: { error, incorrectCredentials in
                onFailure(error, incorrectCredentials, nil, false)
            }
        )
    }

    func presentSiteCredentialBrowserAlternative(for siteURL: String, in viewController: UIViewController) {
        // No-op
    }

    func presentSiteCredentialLoginFailure(error: Error,
                                           offersBrowserAlternative: Bool,
                                           for siteURL: String,
                                           in viewController: UIViewController) {
        handleSiteCredentialLoginFailure(error: error, for: siteURL, in: viewController)
    }

    func handleSiteCredentialLoginFailure(error: Error,
                                          for siteURL: String,
                                          in viewController: UIViewController) {
        // No-op
    }
}
