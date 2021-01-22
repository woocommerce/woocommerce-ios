import Foundation
import KeychainAccess
import WordPressAuthenticator
import Yosemite
import class Networking.UserAgent
import struct Networking.Settings


/// Encapsulates all of the interactions with the WordPress Authenticator
///
class AuthenticationManager: Authentication {

    /// Store Picker Coordinator
    ///
    private var storePickerCoordinator: StorePickerCoordinator?

    /// Keychain access for SIWA auth token
    ///
    private lazy var keychain = Keychain(service: WooConstants.keychainServiceName)

    /// Apple ID is temporarily stored in memory until we can save it to Keychain when the authentication is complete.
    ///
    private var appleUserID: String?

    /// Initializes the WordPress Authenticator.
    ///
    func initialize() {
        let isSignInWithAppleEnabled = true
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.dotcomAppId,
                                                                wpcomSecret: ApiCredentials.dotcomSecret,
                                                                wpcomScheme: ApiCredentials.dotcomAuthScheme,
                                                                wpcomTermsOfServiceURL: WooConstants.URLs.termsOfService.rawValue,
                                                                wpcomAPIBaseURL: Settings.wordpressApiBaseURL,
                                                                googleLoginClientId: ApiCredentials.googleClientId,
                                                                googleLoginServerClientId: ApiCredentials.googleServerId,
                                                                googleLoginScheme: ApiCredentials.googleAuthScheme,
                                                                userAgent: UserAgent.defaultUserAgent,
                                                                showLoginOptions: true,
                                                                enableSignUp: false,
                                                                enableSignInWithApple: isSignInWithAppleEnabled,
                                                                enableSignupWithGoogle: false,
                                                                enableUnifiedAuth: true,
                                                                continueWithSiteAddressFirst: true)

        let systemGray3LightModeColor = UIColor(red: 199/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1)
        let systemLabelLightModeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let style = WordPressAuthenticatorStyle(primaryNormalBackgroundColor: .primaryButtonBackground,
                                                primaryNormalBorderColor: .primaryButtonDownBackground,
                                                primaryHighlightBackgroundColor: .primaryButtonDownBackground,
                                                primaryHighlightBorderColor: .primaryButtonDownBorder,
                                                secondaryNormalBackgroundColor: .white,
                                                secondaryNormalBorderColor: systemGray3LightModeColor,
                                                secondaryHighlightBackgroundColor: systemGray3LightModeColor,
                                                secondaryHighlightBorderColor: systemGray3LightModeColor,
                                                disabledBackgroundColor: .buttonDisabledBackground,
                                                disabledBorderColor: .gray(.shade30),
                                                primaryTitleColor: .primaryButtonTitle,
                                                secondaryTitleColor: systemLabelLightModeColor,
                                                disabledTitleColor: .textSubtle,
                                                disabledButtonActivityIndicatorColor: .textSubtle,
                                                textButtonColor: .accent,
                                                textButtonHighlightColor: .accentDark,
                                                instructionColor: .textSubtle,
                                                subheadlineColor: .gray(.shade30),
                                                placeholderColor: .placeholderImage,
                                                viewControllerBackgroundColor: .listBackground,
                                                textFieldBackgroundColor: .listForeground,
                                                buttonViewBackgroundColor: .authPrologueBottomBackgroundColor,
                                                buttonViewTopShadowImage: nil,
                                                navBarImage: StyleManager.navBarImage,
                                                navBarBadgeColor: .primary,
                                                navBarBackgroundColor: .appBar,
                                                prologueTopContainerChildViewController: LoginPrologueViewController(),
                                                statusBarStyle: .default)

        let displayStrings = WordPressAuthenticatorDisplayStrings(emailLoginInstructions: AuthenticationConstants.emailInstructions,
                                                                  getStartedInstructions: AuthenticationConstants.getStartedInstructions,
                                                                  jetpackLoginInstructions: AuthenticationConstants.jetpackInstructions,
                                                                  siteLoginInstructions: AuthenticationConstants.siteInstructions,
                                                                  usernamePasswordInstructions: AuthenticationConstants.usernamePasswordInstructions,
                                                                  continueWithWPButtonTitle: AuthenticationConstants.continueWithWPButtonTitle,
                                                                  enterYourSiteAddressButtonTitle: AuthenticationConstants.enterYourSiteAddressButtonTitle,
                                                                  findSiteButtonTitle: AuthenticationConstants.findYourStoreAddressButtonTitle,
                                                                  signupTermsOfService: AuthenticationConstants.signupTermsOfService,
                                                                  getStartedTitle: AuthenticationConstants.loginTitle)

        let unifiedStyle = WordPressAuthenticatorUnifiedStyle(borderColor: .divider,
                                                              errorColor: .error,
                                                              textColor: .text,
                                                              textSubtleColor: .textSubtle,
                                                              textButtonColor: .accent,
                                                              textButtonHighlightColor: .accent,
                                                              viewControllerBackgroundColor: .basicBackground,
                                                              prologueButtonsBackgroundColor: .authPrologueBottomBackgroundColor,
                                                              prologueViewBackgroundColor: .authPrologueBottomBackgroundColor,
                                                              navBarBackgroundColor: .basicBackground,
                                                              navButtonTextColor: .accent,
                                                              navTitleTextColor: .text)

        let displayImages = WordPressAuthenticatorDisplayImages(
            magicLink: .loginMagicLinkImage,
            siteAddressModalPlaceholder: .loginSiteAddressInfoImage
        )

        WordPressAuthenticator.initialize(configuration: configuration,
                                          style: style,
                                          unifiedStyle: unifiedStyle,
                                          displayImages: displayImages,
                                          displayStrings: displayStrings)
        WordPressAuthenticator.shared.delegate = self
    }

    /// Returns the Login Flow view controller.
    ///
    func authenticationUI() -> UIViewController {
        let loginViewController: UIViewController = {
            let loginUI = WordPressAuthenticator.loginUI(onLoginButtonTapped: { [weak self] in
                guard let self = self else { return }
                // Resets Apple ID at the beginning of the authentication.
                self.appleUserID = nil

                ServiceLocator.analytics.track(.loginPrologueContinueTapped)
            })
            guard let loginVC = loginUI else {
                fatalError("Cannot instantiate login UI from WordPressAuthenticator")
            }
            return loginVC
        }()
        return loginViewController
    }

    /// Handles an Authentication URL Callback. Returns *true* on success.
    ///
    func handleAuthenticationUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool {
        let source = options[.sourceApplication] as? String
        let annotation = options[.annotation]

        if WordPressAuthenticator.shared.isGoogleAuthUrl(url) {
            return WordPressAuthenticator.shared.handleGoogleAuthUrl(url, sourceApplication: source, annotation: annotation)
        }

        if WordPressAuthenticator.shared.isWordPressAuthUrl(url) {
            return WordPressAuthenticator.shared.handleWordPressAuthUrl(url,
                                                                        rootViewController: rootViewController)
        }

        return false
    }
}



// MARK: - WordPressAuthenticator Delegate
//
extension AuthenticationManager: WordPressAuthenticatorDelegate {
    func userAuthenticatedWithAppleUserID(_ appleUserID: String) {
        self.appleUserID = appleUserID
    }

    var allowWPComLogin: Bool {
        return true
    }

    /// Indicates if the active Authenticator can be dismissed or not.
    ///
    var dismissActionEnabled: Bool {
        // TODO: Return *true* only if there is no default account already set.
        return false
    }

    /// Indicates whether the Support Action should be enabled, or not.
    ///
    var supportActionEnabled: Bool {
        return true
    }

    /// Indicates whether a link to WP.com TOS should be available, or not.
    ///
    var wpcomTermsOfServiceEnabled: Bool {
        return false
    }

    /// Indicates if Support is Enabled.
    ///
    var supportEnabled: Bool {
        return ZendeskManager.shared.zendeskEnabled
    }

    /// Indicates if the Support notification indicator should be displayed.
    ///
    var showSupportNotificationIndicator: Bool {
        // TODO: Wire Zendesk
        return false
    }

    /// Executed whenever a new WordPress.com account has been created.
    /// Note: As of now, this is a NO-OP, we're not supporting any signup flows.
    ///
    func createdWordPressComAccount(username: String, authToken: String) { }

    func shouldHandleError(_ error: Error) -> Bool {
        return isSupportedError(error)
    }

    func handleError(_ error: Error, onCompletion: @escaping (UIViewController) -> Void) {
        guard let errorViewModel = viewModel(error) else {
            return
        }

        let noWPErrorUI = ULErrorViewController(viewModel: errorViewModel)

        onCompletion(noWPErrorUI)
    }

    /// Validates that the self-hosted site contains the correct information
    /// and can proceed to the self-hosted username and password view controller.
    ///
    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void) {

        /// Jetpack is required. Present an error if we don't detect a valid installation.
        guard let site = siteInfo, site.hasValidJetpack == true else {
            let viewModel = JetpackErrorViewModel(siteURL: siteInfo?.url)
            let installJetpackUI = ULErrorViewController(viewModel: viewModel)

            let authenticationResult: WordPressAuthenticatorResult = .injectViewController(value: installJetpackUI)

            onCompletion(authenticationResult)

            return
        }

        /// WordPress must be present.
        guard site.isWP else {
            let viewModel = NotWPErrorViewModel()
            let notWPErrorUI = ULErrorViewController(viewModel: viewModel)

            let authenticationResult: WordPressAuthenticatorResult = .injectViewController(value: notWPErrorUI)

            onCompletion(authenticationResult)

            return
        }

        /// For self-hosted sites, navigate to enter the email address associated to the wp.com account:
        /// https://github.com/woocommerce/woocommerce-ios/issues/3426
        guard site.isWPCom else {
            let authenticationResult: WordPressAuthenticatorResult = .presentEmailController

            onCompletion(authenticationResult)

            return
        }

        /// We should never reach this point, as WPAuthenticator won't call its delegate for this case.
        ///
        DDLogWarn("⚠️ Present password controller for site: \(site.url)")
        let authenticationResult: WordPressAuthenticatorResult = .presentPasswordController(value: false)
        onCompletion(authenticationResult)
    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void) {
        let matcher = ULAccountMatcher()

        guard let siteURL = credentials.wpcom?.siteURL, matcher.match(originalURL: siteURL) else {
            DDLogWarn("⚠️ Present account mismatch error for site: \(String(describing: credentials.wpcom?.siteURL))")
            let viewModel = WrongAccountErrorViewModel(siteURL: credentials.wpcom?.siteURL)
            let mismatchAccountUI = ULAccountMismatchViewController(viewModel: viewModel)

            return navigationController.show(mismatchAccountUI, sender: nil)
        }

        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .login)
        storePickerCoordinator?.onDismiss = onDismiss
        storePickerCoordinator?.start()
    }

    /// Presents the Signup Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?) {
        // NO-OP: The current WC version does not support Signup. Let SIWA through.
        guard case .apple = service else {
            return
        }

        // For SIWA, signups are treating like signing in for now.
        // Signup code in Authenticator normally synchronizes the auth credentials but
        // since we're hacking in SIWA, that's never called in the pod. Call here so the
        // person's name and user ID show up on the picker screen.
        //
        // This is effectively a useless screen for them other than telling them to install Jetpack.
        sync(credentials: credentials) { [weak self] in
            self?.storePickerCoordinator = StorePickerCoordinator(navigationController, config: .login)
            self?.storePickerCoordinator?.start()
        }
    }

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        let identifier = HelpAndSupportViewController.classNameWithoutNamespaces
        guard let supportViewController = UIStoryboard.dashboard.instantiateViewController(withIdentifier: identifier) as? HelpAndSupportViewController else {
            return
        }

        supportViewController.displaysDismissAction = true

        let navController = UINavigationController(rootViewController: supportViewController)
        navController.modalPresentationStyle = .formSheet

        sourceViewController.present(navController, animated: true, completion: nil)
    }

    /// Presents the Support new request, from a given ViewController, with a specified SourceTag.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        ZendeskManager.shared.showNewRequestIfPossible(from: sourceViewController, with: sourceTag.name)
    }

    /// Indicates if the Login Epilogue should be presented.
    ///
    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
        return true
    }

    /// Indicates if the Signup Epilogue should be displayed.
    /// Note: As of now, this is a NO-OP, we're not supporting any signup flows.
    ///
    func shouldPresentSignupEpilogue() -> Bool {
        return false
    }

    /// Synchronizes the specified WordPress Account.
    ///
    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {
        guard let wpcom = credentials.wpcom else {
            fatalError("Self Hosted sites are not supported. Please review the Authenticator settings!")
        }

        // If Apple ID is previously set, saves it to Keychain now that authentication is complete.
        if let appleUserID = appleUserID {
            keychain.wooAppleID = appleUserID
        }
        appleUserID = nil

        ServiceLocator.stores.authenticate(credentials: .init(authToken: wpcom.authToken))
        let action = AccountAction.synchronizeAccount { (account, error) in
            if let account = account {
                let credentials = Credentials(username: account.username, authToken: wpcom.authToken, siteAddress: wpcom.siteURL)
                ServiceLocator.stores
                    .authenticate(credentials: credentials)
                    .synchronizeEntities(onCompletion: onCompletion)
            } else {
                ServiceLocator.stores.synchronizeEntities(onCompletion: onCompletion)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Tracks a given Analytics Event.
    ///
    func track(event: WPAnalyticsStat) {
        guard let wooEvent = WooAnalyticsStat.valueOf(stat: event) else {
            DDLogWarn("⚠️ Could not convert WPAnalyticsStat with value: \(event.rawValue)")
            return
        }
        ServiceLocator.analytics.track(wooEvent)
    }

    /// Tracks a given Analytics Event, with the specified properties.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        guard let wooEvent = WooAnalyticsStat.valueOf(stat: event) else {
            DDLogWarn("⚠️ Could not convert WPAnalyticsStat with value: \(event.rawValue)")
            return
        }
        ServiceLocator.analytics.track(wooEvent, withProperties: properties)
    }

    /// Tracks a given Analytics Event, with the specified error.
    ///
    func track(event: WPAnalyticsStat, error: Error) {
        guard let wooEvent = WooAnalyticsStat.valueOf(stat: event) else {
            DDLogWarn("⚠️ Could not convert WPAnalyticsStat with value: \(event.rawValue)")
            return
        }
        ServiceLocator.analytics.track(wooEvent, withError: error)
    }
}


// MARK: - Error handling
private extension AuthenticationManager {

    /// Maps error codes emitted by WPAuthenticator to a domain error object
    enum AuthenticationError: Int, Error {
        case emailDoesNotMatchWPAccount = 7
        case notWPSite = 406
        case notValidAddress = -1022
        case unknown

        static func make(with error: Error) -> AuthenticationError {
            let error = error as NSError

            switch error.code {
            case emailDoesNotMatchWPAccount.rawValue:
                return .emailDoesNotMatchWPAccount
            case notWPSite.rawValue:
                return .notWPSite
            case notValidAddress.rawValue:
                return .notValidAddress
            default:
                return .unknown
            }
        }
    }

    func isSupportedError(_ error: Error) -> Bool {
        let wooAuthError = AuthenticationError.make(with: error)
        return wooAuthError != .unknown
    }

    func viewModel(_ error: Error) -> ULErrorViewModel? {
        let wooAuthError = AuthenticationError.make(with: error)

        switch wooAuthError {
        case .emailDoesNotMatchWPAccount:
            return NotWPAccountViewModel()
        case .notWPSite,
             .notValidAddress:
            return NotWPErrorViewModel()
        default:
            return nil
        }
    }
}
