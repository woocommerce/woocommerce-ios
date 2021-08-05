import AuthenticationServices
import CocoaLumberjack
import GoogleSignIn
import NSURL_IDN
import UIKit
import WordPressShared
import WordPressUI
import WordPressKit

// MARK: - WordPressAuthenticator: Public API to deal with WordPress.com and WordPress.org authentication.
//
@objc public class WordPressAuthenticator: NSObject {

    /// (Private) Shared Instance.
    ///
    private static var privateInstance: WordPressAuthenticator?

    /// Observer for AppleID Credential State
    ///
    private var appleIDCredentialObserver: NSObjectProtocol?

    /// Shared Instance.
    ///
    @objc public static var shared: WordPressAuthenticator {
        guard let privateInstance = privateInstance else {
            fatalError("WordPressAuthenticator wasn't initialized")
        }

        return privateInstance
    }

    /// Authenticator's Delegate.
    ///
    public weak var delegate: WordPressAuthenticatorDelegate?

    /// Authenticator's Configuration.
    ///
    public let configuration: WordPressAuthenticatorConfiguration

    /// Authenticator's Styles.
    ///
    public let style: WordPressAuthenticatorStyle

    /// Authenticator's Styles for unified flows.
    ///
    public let unifiedStyle: WordPressAuthenticatorUnifiedStyle?

    /// Authenticator's Display Images.
    ///
    public let displayImages: WordPressAuthenticatorDisplayImages

    /// Authenticator's Display Texts.
    ///
    public let displayStrings: WordPressAuthenticatorDisplayStrings

    /// Notification to be posted whenever the signing flow completes.
    ///
    @objc public static let WPSigninDidFinishNotification = "WPSigninDidFinishNotification"

    /// The host name that identifies magic link URLs
    ///
    private static let magicLinkUrlHostname = "magic-login"

    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(configuration: WordPressAuthenticatorConfiguration,
                 style: WordPressAuthenticatorStyle,
                 unifiedStyle: WordPressAuthenticatorUnifiedStyle?,
                 displayImages: WordPressAuthenticatorDisplayImages,
                 displayStrings: WordPressAuthenticatorDisplayStrings) {
        self.configuration = configuration
        self.style = style
        self.unifiedStyle = unifiedStyle
        self.displayImages = displayImages
        self.displayStrings = displayStrings
    }

    /// Initializes the WordPressAuthenticator with the specified Configuration.
    ///
    public static func initialize(configuration: WordPressAuthenticatorConfiguration,
                                  style: WordPressAuthenticatorStyle,
                                  unifiedStyle: WordPressAuthenticatorUnifiedStyle?,
                                  displayImages: WordPressAuthenticatorDisplayImages = .defaultImages,
                                  displayStrings: WordPressAuthenticatorDisplayStrings = .defaultStrings) {
        privateInstance = WordPressAuthenticator(configuration: configuration,
                                                 style: style,
                                                 unifiedStyle: unifiedStyle,
                                                 displayImages: displayImages,
                                                 displayStrings: displayStrings)
    }

    // MARK: - Testing Support

    class func isInitialized() -> Bool {
        return privateInstance != nil
    }

    // MARK: - Public Methods

    public func supportPushNotificationReceived() {
        NotificationCenter.default.post(name: .wordpressSupportNotificationReceived, object: nil)
    }

    public func supportPushNotificationCleared() {
        NotificationCenter.default.post(name: .wordpressSupportNotificationCleared, object: nil)
    }

    /// Indicates if the specified ViewController belongs to the Authentication Flow, or not.
    ///
    public class func isAuthenticationViewController(_ viewController: UIViewController) -> Bool {
        return viewController is LoginPrologueViewController || viewController is NUXViewControllerBase
    }

    /// Indicates if the received URL is a Google Authentication Callback.
    ///
    @objc public func isGoogleAuthUrl(_ url: URL) -> Bool {
        return url.absoluteString.hasPrefix(configuration.googleLoginScheme)
    }

    /// Indicates if the received URL is a WordPress.com Authentication Callback.
    ///
    @objc public func isWordPressAuthUrl(_ url: URL) -> Bool {
        let expectedPrefix = configuration.wpcomScheme + "://" + Self.magicLinkUrlHostname
        return url.absoluteString.hasPrefix(expectedPrefix)
    }

    /// Attempts to process the specified URL as a Google Authentication Link. Returns *true* on success.
    ///
    @objc public func handleGoogleAuthUrl(_ url: URL, sourceApplication: String?, annotation: Any?) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    /// Attempts to process the specified URL as a WordPress Authentication Link. Returns *true* on success.
    ///
    @objc public func handleWordPressAuthUrl(_ url: URL, rootViewController: UIViewController, automatedTesting: Bool = false) -> Bool {
        return WordPressAuthenticator.openAuthenticationURL(url, fromRootViewController: rootViewController, automatedTesting: automatedTesting)
    }

    // MARK: - Helpers for presenting the login flow

    /// Used to present the new login flow from the app delegate
    @objc public class func showLoginFromPresenter(_ presenter: UIViewController, animated: Bool) {
        showLogin(from: presenter, animated: animated)
    }

    /// Shows login UI from the given presenter view controller.
    ///
    /// - Parameters:
    ///   - presenter: The view controller that presents the login UI.
    ///   - animated: Whether the login UI is presented with animation.
    ///   - showCancel: Whether a cancel CTA is shown on the login prologue screen.
    ///   - restrictToWPCom: Whether only WordPress.com login is enabled.
    ///   - onLoginButtonTapped: Called when the login button on the prologue screen is tapped.
    ///   - onCompletion: Called when the login UI presentation completes.
    public class func showLogin(from presenter: UIViewController, animated: Bool, showCancel: Bool = false, restrictToWPCom: Bool = false, onLoginButtonTapped: (() -> Void)? = nil, onCompletion: (() -> Void)? = nil) {
        guard let loginViewController = loginUI(showCancel: showCancel, restrictToWPCom: restrictToWPCom, onLoginButtonTapped: onLoginButtonTapped) else {
            return
        }
        presenter.present(loginViewController, animated: animated, completion: onCompletion)
        trackOpenedLogin()
    }

    /// Returns the view controller for the login flow.
    /// The caller is responsible for tracking `.openedLogin` event when displaying the view controller as in `showLogin`.
    ///
    /// - Parameters:
    ///   - showCancel: Whether a cancel CTA is shown on the login prologue screen.
    ///   - restrictToWPCom: Whether only WordPress.com login is enabled.
    ///   - onLoginButtonTapped: Called when the login button on the prologue screen is tapped.
    /// - Returns: The root view controller for the login flow.
    public class func loginUI(showCancel: Bool = false, restrictToWPCom: Bool = false, onLoginButtonTapped: (() -> Void)? = nil) -> UIViewController? {
        let storyboard = Storyboard.login.instance
        guard let controller = storyboard.instantiateInitialViewController() else {
            assertionFailure("Cannot instantiate initial login controller from Login.storyboard")
            return nil
        }
        if let childController = controller.children.first as? LoginPrologueViewController {
            childController.loginFields.restrictToWPCom = restrictToWPCom
            childController.showCancel = showCancel
            childController.onLoginButtonTapped = onLoginButtonTapped
        }
        controller.modalPresentationStyle = .fullScreen
        return controller
    }

    /// Used to present the new wpcom-only login flow from the app delegate
    @objc public class func showLoginForJustWPCom(from presenter: UIViewController, jetpackLogin: Bool = false, connectedEmail: String? = nil) {
        defer {
            trackOpenedLogin()
        }

        guard WordPressAuthenticator.shared.configuration.enableUnifiedAuth else {
            showEmailLogin(from: presenter, jetpackLogin: jetpackLogin, connectedEmail: connectedEmail)
            return
        }

        showGetStarted(from: presenter, jetpackLogin: jetpackLogin, connectedEmail: connectedEmail)
    }

    /// Shows the unified Login/Signup flow.
    ///
    private class func showGetStarted(from presenter: UIViewController, jetpackLogin: Bool, connectedEmail: String? = nil) {
        guard let controller = GetStartedViewController.instantiate(from: .getStarted) else {
            DDLogError("Failed to navigate from LoginPrologueViewController to GetStartedViewController")
            return
        }

        controller.loginFields.restrictToWPCom = true
        controller.loginFields.username = connectedEmail ?? String()
        controller.loginFields.meta.jetpackLogin = jetpackLogin

        let navController = LoginNavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .fullScreen
        presenter.present(navController, animated: true, completion: nil)
    }

    /// Shows the Email Login view with Signup option.
    ///
    private class func showEmailLogin(from presenter: UIViewController, jetpackLogin: Bool, connectedEmail: String? = nil) {
        guard let controller = LoginEmailViewController.instantiate(from: .login) else {
            return
        }

        controller.loginFields.restrictToWPCom = true
        controller.loginFields.meta.jetpackLogin = jetpackLogin

        if let email = connectedEmail {
            controller.loginFields.username = email
        } else {
            controller.offerSignupOption = true
        }

        let navController = LoginNavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .fullScreen
        presenter.present(navController, animated: true, completion: nil)
    }

    /// Used to present the new self-hosted login flow from BlogListViewController
    @objc public class func showLoginForSelfHostedSite(_ presenter: UIViewController) {
        defer {
            trackOpenedLogin()
        }

        AuthenticatorAnalyticsTracker.shared.set(source: .selfHosted)

        guard let controller = signinForWPOrg() else {
            DDLogError("WordPressAuthenticator: Failed to instantiate Site Address view controller.")
            return
        }

        let navController = LoginNavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .fullScreen
        presenter.present(navController, animated: true, completion: nil)
    }

    /// Returns a Site Address view controller: allows the user to log into a WordPress.org website.
    ///
    @objc public class func signinForWPOrg() -> UIViewController? {
        guard WordPressAuthenticator.shared.configuration.enableUnifiedAuth else {
            return LoginSiteAddressViewController.instantiate(from: .login)
        }

        return SiteAddressViewController.instantiate(from: .siteAddress)
    }

    // Helper used by WPAuthTokenIssueSolver
    @objc
    public class func signinForWPCom(dotcomEmailAddress: String?, dotcomUsername: String?, onDismissed: ((_ cancelled: Bool) -> Void)? = nil) -> UIViewController {
        let loginFields = LoginFields()
        loginFields.emailAddress = dotcomEmailAddress ?? String()
        loginFields.username = dotcomUsername ?? String()

        guard WordPressAuthenticator.shared.configuration.enableUnifiedAuth else {
            guard let controller = LoginWPComViewController.instantiate(from: .login) else {
                DDLogError("WordPressAuthenticator: Failed to instantiate LoginWPComViewController")
                return UIViewController()
            }

            controller.loginFields = loginFields
            controller.dismissBlock = onDismissed

            return NUXNavigationController(rootViewController: controller)
        }

        AuthenticatorAnalyticsTracker.shared.set(source: .reauthentication)
        AuthenticatorAnalyticsTracker.shared.set(flow: .loginWithPassword)

        guard let controller = PasswordViewController.instantiate(from: .password) else {
            DDLogError("WordPressAuthenticator: Failed to instantiate PasswordViewController")
            return UIViewController()
        }

        controller.loginFields = loginFields
        controller.dismissBlock = onDismissed
        controller.trackAsPasswordChallenge = false

        return NUXNavigationController(rootViewController: controller)
    }

    /// Returns an instance of LoginEmailViewController.
    /// This allows the host app to configure the controller's features.
    ///
    public class func signinForWPCom() -> LoginEmailViewController {
        guard let controller = LoginEmailViewController.instantiate(from: .login) else {
            fatalError()
        }

        return controller
    }

    private class func trackOpenedLogin() {
        WordPressAuthenticator.track(.openedLogin)
    }

    // MARK: - Authentication Link Helpers

    /// Present a signin view controller to handle an authentication link.
    ///
    /// - Parameters:
    ///     - url: The authentication URL
    ///     - rootViewController: The view controller to act as the presenter for the signin view controller.  By convention this is the app's root vc.
    ///     - automatedTesting: for calling this method for automated testing.  It won't sync the account or load any other VCs.
    ///
    @objc public class func openAuthenticationURL(
        _ url: URL,
        fromRootViewController rootViewController: UIViewController,
        automatedTesting: Bool = false) -> Bool {

        guard let queryDictionary = url.query?.dictionaryFromQueryString() else {
            DDLogError("Magic link error: we couldn't retrieve the query dictionary from the sign-in URL.")
            return false
        }

        guard let authToken = queryDictionary.string(forKey: "token") else {
            DDLogError("Magic link error: we couldn't retrieve the authentication token from the sign-in URL.")
            return false
        }

        guard let flowRawValue = queryDictionary.string(forKey: "flow") else {
            DDLogError("Magic link error: we couldn't retrieve the flow from the sign-in URL.")
            return false
        }

        let loginFields = LoginFields()

        if url.isJetpackConnect {
            loginFields.meta.jetpackLogin = true
        }

        // We could just use the flow, but since `MagicLinkFlow` is an ObjC enum, it always
        // allows a `default` value.  By mapping the ObjC enum to a Swift enum we can avoid that afterwards.
        let flow: NUXLinkAuthViewController.Flow

        switch MagicLinkFlow(rawValue: flowRawValue) {
        case .signup:
            flow = .signup
            loginFields.meta.emailMagicLinkSource = .signup
            Self.track(.signupMagicLinkOpened)
        case .login:
            flow = .login
            loginFields.meta.emailMagicLinkSource = .login
            Self.track(.loginMagicLinkOpened)
        default:
            DDLogError("Magic link error: the flow should be either `signup` or `login`. We can't handle an unsupported flow.")
            return false
        }

        if !automatedTesting {
            let storyboard = Storyboard.emailMagicLink.instance
            guard let loginVC = storyboard.instantiateViewController(withIdentifier: "LinkAuthView") as? NUXLinkAuthViewController else {
                DDLogInfo("App opened with authentication link but couldn't create login screen.")
                return false
            }
            loginVC.loginFields = loginFields

            let navController = LoginNavigationController(rootViewController: loginVC)
            navController.modalPresentationStyle = .fullScreen

            // The way the magic link flow works some view controller might
            // still be presented when the app is resumed by tapping on the auth link.
            // We need to do a little work to present the SigninLinkAuth controller
            // from the right place.
            // - If the rootViewController is not presenting another vc then just
            // present the auth controller.
            // - If the rootViewController is presenting another NUX vc, dismiss the
            // NUX vc then present the auth controller.
            // - If the rootViewController is presenting *any* other vc, present the
            // auth controller from the presented vc.
            let presenter = rootViewController.topmostPresentedViewController
            if presenter.isKind(of: NUXNavigationController.self) || presenter.isKind(of: LoginNavigationController.self),
                let parent = presenter.presentingViewController {
                parent.dismiss(animated: false, completion: {
                    parent.present(navController, animated: false, completion: nil)
                })
            } else {
                presenter.present(navController, animated: false, completion: nil)
            }

            loginVC.syncAndContinue(authToken: authToken, flow: flow, isJetpackConnect: url.isJetpackConnect)
        }

        return true
    }

    // MARK: - Site URL helper

    /// The base site URL path derived from `loginFields.siteUrl`
    ///
    /// - Parameter string: The source URL as a string.
    ///
    /// - Returns: The base URL or an empty string.
    ///
    class func baseSiteURL(string: String) -> String {

        guard !string.isEmpty,
              let siteURL = NSURL(string: NSURL.idnEncodedURL(string)),
              var path = siteURL.absoluteString else {
            return ""
        }

        let isSiteURLSchemeEmpty = siteURL.scheme == nil || siteURL.scheme!.isEmpty

        if isSiteURLSchemeEmpty {
            path = "https://\(path)"
        } else if path.isWordPressComPath() && path.range(of: "http://") != nil {
            path = path.replacingOccurrences(of: "http://", with: "https://")
        }

        path.removeSuffix("/wp-login.php")

        // Remove wp-admin and everything after it.
        try? path.removeSuffix(pattern: "/wp-admin(.*)")

        path.removeSuffix("/")

        return path
    }

    // MARK: - Other Helpers

    /// Opens Safari to display the forgot password page for a wpcom or self-hosted
    /// based on the passed LoginFields instance.
    ///
    /// - Parameter loginFields: A LoginFields instance.
    ///
    class func openForgotPasswordURL(_ loginFields: LoginFields) {
        let baseURL = loginFields.meta.userIsDotCom ? "https://wordpress.com" : WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress)
        let forgotPasswordURL = URL(string: baseURL + "/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F")!
        UIApplication.shared.open(forgotPasswordURL)
    }

    /// Returns the WordPressAuthenticator Bundle
    /// If installed via CocoaPods, this will be WordPressAuthenticator.bundle,
    /// otherwise it will be the framework bundle.
    ///
    public class var bundle: Bundle {
        let defaultBundle = Bundle(for: WordPressAuthenticator.self)
        // If installed with CocoaPods, resources will be in WordPressAuthenticator.bundle
        if let bundleURL = defaultBundle.resourceURL,
            let resourceBundle = Bundle(url: bundleURL.appendingPathComponent("WordPressAuthenticatorResources.bundle")) {
            return resourceBundle
        }
        // Otherwise, the default bundle is used for resources
        return defaultBundle
    }

    // MARK: - 1Password Helper

    /// Request credentails from 1Password (if supported)
    ///
    /// - Parameter sender: A UIView. Typically the button the user tapped on.
    ///
    class func fetchOnePasswordCredentials(_ controller: UIViewController,
                                           sourceView: UIView,
                                           loginFields: LoginFields,
                                           allowUsernameChange: Bool = true,
                                           onePasswordFetcher: OnePasswordResultsFetcher = OnePasswordFacade(),
                                           success: @escaping ((_ loginFields: LoginFields) -> Void)) {

        let loginURL = loginFields.meta.userIsDotCom ? OnePasswordDefaults.dotcomURL : loginFields.siteAddress

        onePasswordFetcher.findLogin(for: loginURL, viewController: controller, sender: sourceView, success: { (username, password, otp) in
            if allowUsernameChange {
                loginFields.username = username
            }

            loginFields.password = password
            loginFields.multifactorCode = otp ?? String()

            WordPressAuthenticator.track(.onePasswordLogin)
            success(loginFields)

        }, failure: { error in
            guard error != .cancelledByUser else {
                return
            }

            DDLogError("OnePassword Error: \(error.localizedDescription)")
            WordPressAuthenticator.track(.onePasswordFailed)
        })
    }
}

@available(iOS 13.0, *)
public extension WordPressAuthenticator {

    func getAppleIDCredentialState(for userID: String, completion:  @escaping (ASAuthorizationAppleIDProvider.CredentialState, Error?) -> Void) {
        AppleAuthenticator.sharedInstance.getAppleIDCredentialState(for: userID) { (state, error) in
            // If credentialState == .notFound, error will have a value.
            completion(state, error)
        }
    }

    func startObservingAppleIDCredentialRevoked(completion:  @escaping () -> Void) {
        appleIDCredentialObserver = NotificationCenter.default.addObserver(forName: AppleAuthenticator.credentialRevokedNotification, object: nil, queue: nil) { (_) in
            completion()
        }
    }

    func stopObservingAppleIDCredentialRevoked() {
        if let observer = appleIDCredentialObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        appleIDCredentialObserver = nil
    }
}
