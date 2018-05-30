import Foundation
import WordPressAuthenticator



/// Encapsulates all of the interactions with the WordPress Authenticator
///
class AuthenticationManager {

    /// Initializes the WordPress Authenticator.
    ///
    func initialize() {
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.dotcomAppId,
                                                                wpcomSecret: ApiCredentials.dotcomSecret,
                                                                wpcomScheme: ApiCredentials.dotcomAuthScheme,
                                                                wpcomTermsOfServiceURL: Constants.termsOfServiceURL,
                                                                googleLoginClientId: ApiCredentials.googleClientId,
                                                                googleLoginServerClientId: ApiCredentials.googleServerId,
                                                                googleLoginScheme: ApiCredentials.googleAuthScheme,
                                                                userAgent: UserAgent.defaultUserAgent,
                                                                supportNotificationIndicatorFeatureFlag: false)

        WordPressAuthenticator.initialize(configuration: configuration)
        WordPressAuthenticator.shared.delegate = self
    }

    /// Displays the Login Flow using the specified UIViewController as presenter.
    ///
    func showLogin(from presenter: UIViewController) {
        let loginViewController = WordPressAuthenticator.signinForWordPress()
        loginViewController.restrictToWPCom = true
        loginViewController.offerSignupOption = false

        let navigationController = LoginNavigationController(rootViewController: loginViewController)
        presenter.present(navigationController, animated: true, completion: nil)
    }

    /// Handles an Authentication URL Callback. Returns *true* on success.
    ///
    func handleAuthenticationUrl(_ url: URL, options: [UIApplicationOpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool {
        let source = options[.sourceApplication] as? String
        let annotation = options[.annotation]

        if WordPressAuthenticator.shared.isGoogleAuthUrl(url) {
            return WordPressAuthenticator.shared.handleGoogleAuthUrl(url, sourceApplication: source, annotation: annotation)
        }

        if WordPressAuthenticator.shared.isWordPressAuthUrl(url) {
            return WordPressAuthenticator.shared.handleWordPressAuthUrl(url, allowWordPressComAuth: true, rootViewController: rootViewController)
        }

        return false
    }
}



// MARK: - WordPressAuthenticator Delegate
//
extension AuthenticationManager: WordPressAuthenticatorDelegate {

    /// Indicates if the active Authenticator can be dismissed or not.
    ///
    var dismissActionEnabled: Bool {
        // TODO: Return *true* only if there is no default account already set.
        return false
    }

    /// Indicates whether if the Support Action should be enabled, or not.
    ///
    var supportActionEnabled: Bool {
        // TODO: Wire Zendesk
        return false
    }

    /// Indicates if Support is Enabled.
    ///
    var supportEnabled: Bool {
        // TODO: Wire Zendesk
        return false
    }

    /// Indicates if the Support notification indicator should be displayed.
    ///
    var showSupportNotificationIndicator: Bool {
        // TODO: Wire Zendesk
        return false
    }

    /// Returns Helpshift's Unread Messages Count.
    ///
    var supportBadgeCount: Int {
        // TODO: Wire Zendesk
        return Int.min
    }

    /// Refreshes Helpshift's Unread Count.
    ///
    func refreshSupportBadgeCount() {
        // TODO: Wire Zendesk
    }

    /// Returns an instance of a SupportView, configured to be displayed from a specified Support Source.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any] = [:]) {
        // TODO: Wire Zendesk
    }

    /// Presents Support new request, with the specified ViewController as a source.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any]) {
        // TODO: Wire Zendesk
    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, onDismiss: @escaping () -> Void) {
        // TODO: Wire Store Picker
    }

    /// Presents the Signup Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, service: SocialService?) {
        // NO-OP: The current WC version does not support Signup.
    }

    /// Indicates if the Login Epilogue should be presented. This is false only when we're doing a Jetpack Connect, and the new
    /// WordPress.com account has no sites. Capicci?
    ///
    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
        return false
    }

    /// Indicates if the Signup Epilogue should be displayed.
    ///
    func shouldPresentSignupEpilogue() -> Bool {
        // Note: The current WC version does not support Signup.
        return false
    }

    /// Executed whenever a new WordPress.com account has been created.
    ///
    func createdWordPressComAccount(username: String, authToken: String) {
        // NO-OP: The current WC version does not support Signup.
    }

    /// Synchronizes the specified WordPress Account. Note: Only Dotcom is supported!
    ///
    func sync(credentials: WordPressCredentials, onCompletion: @escaping (Error?) -> Void) {
        guard case let .wpcom(username, authToken, _, _) = credentials else {
            fatalError("WordPress.org is not supported")
        }

        Mall.shared.accountStore.synchronizeDotcomAccount(username: username, authToken: authToken) { error in
            onCompletion(error)
        }
    }

    /// Tracks a given Analytics Event.
    ///
    func track(event: WPAnalyticsStat) {
        // TODO: Integrate Tracks
    }

    /// Tracks a given Analytics Event, with the specified properties.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        // TODO: Integrate Tracks
    }

    /// Tracks a given Analytics Event, with the specified error.
    ///
    func track(event: WPAnalyticsStat, error: Error) {
        // TODO: Integrate Tracks
    }
}


/// Nested Types
///
extension AuthenticationManager {

    struct Constants {

        /// Terms of Service Website. Displayed by the Authenticator (when / if needed).
        ///
        static let termsOfServiceURL = "https://wordpress.com/tos/"
    }
}
