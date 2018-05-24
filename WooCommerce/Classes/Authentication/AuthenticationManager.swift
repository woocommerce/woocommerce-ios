import Foundation
import WordPressAuthenticator



/// Encapsulates all of the interactions with the WordPress Authenticator
///
class AuthenticationManager {

    func initialize() {
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.dotcomAppId,
                                                                wpcomSecret: ApiCredentials.dotcomSecret,
                                                                wpcomScheme: ApiCredentials.dotcomAuthScheme,
                                                                wpcomTermsOfServiceURL: Constants.termsOfServiceURL,
                                                                googleLoginClientId: ApiCredentials.googleClientId,
                                                                googleLoginServerClientId: ApiCredentials.googleServerId,
                                                                userAgent: UserAgent.defaultUserAgent,
                                                                supportNotificationIndicatorFeatureFlag: false)

        WordPressAuthenticator.initialize(configuration: configuration)
        WordPressAuthenticator.shared.delegate = self
    }

    func showLogin(from presenter: UIViewController, animated: Bool) {
        WordPressAuthenticator.showLoginForJustWPCom(from: presenter)
    }
}



// MARK: - WordPressAuthenticator Delegate
//
extension AuthenticationManager: WordPressAuthenticatorDelegate {

    /// Indicates if the active Authenticator can be dismissed, or not. Authentication is Dismissable when there is a
    /// default wpcom account, or at least one self-hosted blog.
    ///
    var dismissActionEnabled: Bool {
        return false
    }

    /// Indicates whether if the Support Action should be enabled, or not.
    ///
    var supportActionEnabled: Bool {
        return false
    }

    /// Indicates if Support is Enabled.
    ///
    var supportEnabled: Bool {
        return false
    }

    /// Indicates if the Support notification indicator should be displayed.
    ///
    var showSupportNotificationIndicator: Bool {
        return false
    }

    /// Returns Helpshift's Unread Messages Count.
    ///
    var supportBadgeCount: Int {
        return Int.min
    }

    /// Refreshes Helpshift's Unread Count.
    ///
    func refreshSupportBadgeCount() {

    }

    /// Returns an instance of a SupportView, configured to be displayed from a specified Support Source.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any] = [:]) {

    }

    /// Presents Support new request, with the specified ViewController as a source.
    /// Additional metadata is supplied, such as the sourceTag and Login details.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any]) {

    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, onDismiss: @escaping () -> Void) {

    }

    /// Presents the Signup Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, service: SocialService?) {

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
        return false
    }

    /// Whenever a WordPress.com acocunt has been created during the Auth flow, we'll add a new local WPCOM Account, and set it as
    /// the new DefaultWordPressComAccount.
    ///
    func createdWordPressComAccount(username: String, authToken: String) {

    }

    /// Synchronizes the specified WordPress Account.
    ///
    func sync(credentials: WordPressCredentials, onCompletion: @escaping (Error?) -> Void) {
        onCompletion(nil)
    }

    /// Tracks a given Analytics Event.
    ///
    func track(event: WPAnalyticsStat) {

    }

    /// Tracks a given Analytics Event, with the specified properties.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {

    }

    /// Tracks a given Analytics Event, with the specified error.
    ///
    func track(event: WPAnalyticsStat, error: Error) {

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
