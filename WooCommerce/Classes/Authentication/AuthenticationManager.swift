import Foundation
import KeychainAccess
import WordPressAuthenticator
import WordPressKit
import Yosemite
import class Networking.UserAgent
import struct Networking.Settings
import protocol Storage.StorageManagerType


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

    /// Info of the self-hosted site that was entered from the Enter a Site Address flow
    ///
    private var currentSelfHostedSite: WordPressComSiteInfo?

    /// App settings when the app is in logged out state.
    ///
    private var loggedOutAppSettings: LoggedOutAppSettingsProtocol?

    /// Storage manager to inject to account matcher
    ///
    private let storageManager: StorageManagerType

    init(storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager
    }

    /// Initializes the WordPress Authenticator.
    ///
    func initialize() {
        let isWPComMagicLinkPreferredToPassword = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.loginMagicLinkEmphasis)
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.dotcomAppId,
                                                                wpcomSecret: ApiCredentials.dotcomSecret,
                                                                wpcomScheme: ApiCredentials.dotcomAuthScheme,
                                                                wpcomTermsOfServiceURL: WooConstants.URLs.termsOfService.rawValue,
                                                                wpcomAPIBaseURL: Settings.wordpressApiBaseURL,
                                                                whatIsWPComURL: WooConstants.URLs.whatIsWPComURL.rawValue,
                                                                googleLoginClientId: ApiCredentials.googleClientId,
                                                                googleLoginServerClientId: ApiCredentials.googleServerId,
                                                                googleLoginScheme: ApiCredentials.googleAuthScheme,
                                                                userAgent: UserAgent.defaultUserAgent,
                                                                showLoginOptions: true,
                                                                enableSignUp: false,
                                                                enableSignInWithApple: true,
                                                                enableSignupWithGoogle: false,
                                                                enableUnifiedAuth: true,
                                                                continueWithSiteAddressFirst: true,
                                                                enableSiteCredentialsLoginForSelfHostedSites: true,
                                                                isWPComLoginRequiredForSiteCredentialsLogin: true,
                                                                isWPComMagicLinkPreferredToPassword: isWPComMagicLinkPreferredToPassword)

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
                                                                  siteCredentialInstructions: AuthenticationConstants.siteCredentialInstructions,
                                                                  usernamePasswordInstructions: AuthenticationConstants.usernamePasswordInstructions,
                                                                  continueWithWPButtonTitle: AuthenticationConstants.continueWithWPButtonTitle,
                                                                  enterYourSiteAddressButtonTitle: AuthenticationConstants.enterYourSiteAddressButtonTitle,
                                                                  signInWithSiteCredentialsButtonTitle: AuthenticationConstants.signInWithSiteCredsButtonTitle,
                                                                  findSiteButtonTitle: AuthenticationConstants.findYourStoreAddressButtonTitle,
                                                                  signupTermsOfService: AuthenticationConstants.signupTermsOfService,
                                                                  whatIsWPComLinkTitle: AuthenticationConstants.whatIsWPComLinkTitle,
                                                                  getStartedTitle: AuthenticationConstants.loginTitle)

        let unifiedStyle = WordPressAuthenticatorUnifiedStyle(borderColor: .divider,
                                                              errorColor: .error,
                                                              textColor: .text,
                                                              textSubtleColor: .textSubtle,
                                                              textButtonColor: .accent,
                                                              textButtonHighlightColor: .accentDark,
                                                              viewControllerBackgroundColor: .basicBackground,
                                                              prologueButtonsBackgroundColor: .authPrologueBottomBackgroundColor,
                                                              prologueViewBackgroundColor: .authPrologueBottomBackgroundColor,
                                                              navBarBackgroundColor: .basicBackground,
                                                              navButtonTextColor: .accent,
                                                              navTitleTextColor: .text,
                                                              gravatarEmailTextColor: .text)

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

    /// Injects `loggedOutAppSettings`
    ///
    func setLoggedOutAppSettings(_ settings: LoggedOutAppSettingsProtocol) {
        loggedOutAppSettings = settings
    }

    /// Checks the given site address and see if it's valid
    /// and returns an error view controller if not.
    func errorViewController(for siteURL: String,
                             with matcher: ULAccountMatcher,
                             navigationController: UINavigationController,
                             onStorePickerDismiss: @escaping () -> Void) -> UIViewController? {

        /// Account mismatched case
        guard matcher.match(originalURL: siteURL) else {
            DDLogWarn("⚠️ Present account mismatch error for site: \(String(describing: siteURL))")
            return accountMismatchUI(for: siteURL, with: matcher)
        }

        /// No Woo found
        if let matchedSite = matcher.matchedSite(originalURL: siteURL),
           matchedSite.isWooCommerceActive == false {
            return noWooUI(for: matchedSite,
                           with: matcher,
                           navigationController: navigationController,
                           onStorePickerDismiss: onStorePickerDismiss)
        }

        // All good!
        return nil
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
        return ZendeskProvider.shared.zendeskEnabled
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
        requestLocalNotificationIfApplicable(error: error)

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

        /// WordPress must be present.
        guard let site = siteInfo, site.isWP else {
            let viewModel = NotWPErrorViewModel()
            let notWPErrorUI = ULErrorViewController(viewModel: viewModel)

            let authenticationResult: WordPressAuthenticatorResult = .injectViewController(value: notWPErrorUI)

            onCompletion(authenticationResult)

            return
        }

        /// save the site to memory to check for jetpack requirement in epilogue
        currentSelfHostedSite = site

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

    /// Displays appropriate error based on the input `siteInfo`.
    ///
    func troubleshootSite(_ siteInfo: WordPressComSiteInfo?, in navigationController: UINavigationController?) {
        guard let site = siteInfo, let navigationController = navigationController else {
            DDLogWarn("⚠️ Missing site info or navigation controller when troubleshooting site")
            return
        }

        let matcher = ULAccountMatcher(storageManager: storageManager)
        guard !site.isWPCom else {
            guard site.hasValidJetpack else {
                // TODO: non-atomic site, do something
                return
            }
            let controller = accountMismatchUI(for: site.url, with: matcher)
            navigationController.show(controller, sender: nil)
            return
        }

        /// Jetpack is required. Present an error if we don't detect a valid installation.
        guard site.hasValidJetpack == true else {
            let jetpackUI = jetpackErrorUI(for: site.url, with: matcher, in: navigationController)
            navigationController.show(jetpackUI, sender: nil)
            return
        }

        let controller = accountMismatchUI(for: site.url, with: matcher)
        navigationController.show(controller, sender: nil)
    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void) {

        guard let siteURL = credentials.wpcom?.siteURL ?? credentials.wporg?.siteURL else {
            // This should not happen since the resulting credentials should be either `wpcom` or `wporg`
            return DDLogError("⛔️ No site URL found to present Login Epilogue.")
        }

        /// Jetpack is required. Present an error if we don't detect a valid installation for a self-hosted site.
        if isJetpackInvalidForSelfHostedSite(url: siteURL) {
            return presentJetpackError(for: siteURL, with: credentials, in: navigationController, onDismiss: onDismiss)
        }

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.loginErrorNotifications) {
            ServiceLocator.pushNotesManager.cancelLocalNotification(scenarios: [.loginSiteAddressError])
        }

        let matcher = ULAccountMatcher(storageManager: storageManager)
        matcher.refreshStoredSites()

        if let vc = errorViewController(for: siteURL, with: matcher, navigationController: navigationController, onStorePickerDismiss: onDismiss) {
            loggedOutAppSettings?.setErrorLoginSiteAddress(siteURL)
            navigationController.show(vc, sender: nil)
        } else {
            loggedOutAppSettings?.setErrorLoginSiteAddress(nil)
            let matchedSite = matcher.matchedSite(originalURL: siteURL)
            startStorePicker(with: matchedSite?.siteID, in: navigationController, onDismiss: onDismiss)
        }
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
            self?.startStorePicker(in: navigationController)
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

        let navController = WooNavigationController(rootViewController: supportViewController)
        navController.modalPresentationStyle = .formSheet

        sourceViewController.present(navController, animated: true, completion: nil)
    }

    /// Presents the Support new request, from a given ViewController, with a specified SourceTag.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        ZendeskProvider.shared.showNewRequestIfPossible(from: sourceViewController, with: sourceTag.name)
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
        let action = AccountAction.synchronizeAccount { result in
            switch result {
            case .success(let account):
                let credentials = Credentials(username: account.username, authToken: wpcom.authToken, siteAddress: wpcom.siteURL)
                ServiceLocator.stores
                    .authenticate(credentials: credentials)
                    .synchronizeEntities(onCompletion: onCompletion)
            case .failure:
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

// MARK: - Local notifications

private extension AuthenticationManager {
    func requestLocalNotificationIfApplicable(error: Error) {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.loginErrorNotifications) else {
            return
        }

        let wooAuthError = AuthenticationError.make(with: error)
        let notification: LocalNotification?
        switch wooAuthError {
        case .notWPSite, .notValidAddress, .noSecureConnection:
            notification = LocalNotification(scenario: .loginSiteAddressError)
        case .invalidEmailFromSiteAddressLogin:
            notification = LocalNotification(scenario: .invalidEmailFromSiteAddressLogin)
        case .invalidEmailFromWPComLogin:
            notification = LocalNotification(scenario: .invalidEmailFromWPComLogin)
        case .invalidPasswordFromSiteAddressLogin:
            notification = LocalNotification(scenario: .invalidPasswordFromSiteAddressLogin)
        case .invalidPasswordFromWPComLogin:
            notification = LocalNotification(scenario: .invalidPasswordFromWPComLogin)
        default:
            notification = nil
        }

        if let notification = notification {
            ServiceLocator.pushNotesManager.cancelLocalNotification(scenarios: [notification.scenario])
            ServiceLocator.pushNotesManager.requestLocalNotification(notification,
                                                                     // 24 hours from now.
                                                                     trigger: UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false))
        }
    }
}

// MARK: - Private helpers
private extension AuthenticationManager {
    func isJetpackInvalidForSelfHostedSite(url: String) -> Bool {
        if let site = currentSelfHostedSite,
           site.url == url, !site.hasValidJetpack {
            return true
        }
        return false
    }

    func presentJetpackError(for siteURL: String,
                             with credentials: AuthenticatorCredentials,
                             in navigationController: UINavigationController,
                             onDismiss: @escaping () -> Void) {
        let viewModel = JetpackErrorViewModel(siteURL: siteURL, onJetpackSetupCompletion: { [weak self] authorizedEmailAddress in
            guard let self = self else { return }
            // Resets the referenced site since the setup completed now.
            self.currentSelfHostedSite = nil
            guard credentials.wpcom != nil else {
                return WordPressAuthenticator.showLoginForJustWPCom(
                    from: navigationController,
                    jetpackLogin: true,
                    connectedEmail: authorizedEmailAddress,
                    siteURL: siteURL
                )
            }
            // Tries re-syncing to get an updated store list,
            // then attempts to present epilogue again.
            ServiceLocator.stores.synchronizeEntities { [weak self] in
                self?.presentLoginEpilogue(in: navigationController, for: credentials, onDismiss: onDismiss)
            }
        })
        let installJetpackUI = ULErrorViewController(viewModel: viewModel)
        navigationController.show(installJetpackUI, sender: nil)
    }

    func startStorePicker(with siteID: Int64? = nil, in navigationController: UINavigationController, onDismiss: @escaping () -> Void = {}) {
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .login)
        storePickerCoordinator?.onDismiss = onDismiss
        if let siteID = siteID {
            storePickerCoordinator?.didSelectStore(with: siteID, onCompletion: onDismiss)
        } else {
            storePickerCoordinator?.start()
        }
    }

    func jetpackErrorUI(for siteURL: String, with matcher: ULAccountMatcher, in navigationController: UINavigationController) -> UIViewController {
        let viewModel = JetpackErrorViewModel(siteURL: siteURL, onJetpackSetupCompletion: { authorizedEmailAddress in
            guard let self = self else { return }

            // Tries re-syncing to get an updated store list
            ServiceLocator.stores.synchronizeEntities { [weak self] in
                guard let self = self else { return }

                if let matchedSite = matcher.matchedSite(originalURL: siteURL) {
                    // checks if the site has woo
                    if matchedSite.isWooCommerceActive == false {
                        let noWooUI = self.noWooUI(for: matchedSite,
                                                   with: matcher,
                                                   navigationController: navigationController,
                                                   onStorePickerDismiss: {})
                        navigationController.show(noWooUI, sender: nil)
                    } else {
                        self.startStorePicker(with: matchedSite.siteID, in: navigationController, onDismiss: {})
                    }
                } else {
                    // TODO: what now?
                }
            }
        })
        return ULErrorViewController(viewModel: viewModel)
    }

    func accountMismatchUI(for siteURL: String, with matcher: ULAccountMatcher) -> UIViewController {
        let viewModel = WrongAccountErrorViewModel(siteURL: siteURL, showsConnectedStores: matcher.hasConnectedStores)
        let mismatchAccountUI = ULAccountMismatchViewController(viewModel: viewModel)
        return mismatchAccountUI
    }

    func noWooUI(for site: Site,
                 with matcher: ULAccountMatcher,
                 navigationController: UINavigationController,
                 onStorePickerDismiss: @escaping () -> Void) -> UIViewController {

        let viewModel = NoWooErrorViewModel(
            site: site,
            showsConnectedStores: matcher.hasConnectedStores,
            onSetupCompletion: { [weak self] siteID in
                guard let self = self else { return }
                self.startStorePicker(with: siteID, in: navigationController, onDismiss: onStorePickerDismiss)
        })
        let noWooUI = ULErrorViewController(viewModel: viewModel)
        return noWooUI
    }
}

// MARK: - ViewModel Factory
extension AuthenticationManager {
    /// This is only exposed for testing.
    func viewModel(_ error: Error) -> ULErrorViewModel? {
        let wooAuthError = AuthenticationError.make(with: error)

        switch wooAuthError {
        case .emailDoesNotMatchWPAccount, .invalidEmailFromWPComLogin, .invalidEmailFromSiteAddressLogin:
            return NotWPAccountViewModel()
        case .notWPSite,
             .notValidAddress:
            return NotWPErrorViewModel()
        case .noSecureConnection:
            return NoSecureConnectionErrorViewModel()
        case .unknown, .invalidPasswordFromWPComLogin, .invalidPasswordFromSiteAddressLogin:
            return nil
        }
    }
}

// MARK: - Error handling
private extension AuthenticationManager {

    /// Maps error codes emitted by WPAuthenticator to a domain error object
    enum AuthenticationError: Int, Error {
        case emailDoesNotMatchWPAccount
        case invalidEmailFromSiteAddressLogin
        case invalidEmailFromWPComLogin
        case invalidPasswordFromSiteAddressLogin
        case invalidPasswordFromWPComLogin
        case notWPSite
        case notValidAddress
        case noSecureConnection
        case unknown

        static func make(with error: Error) -> AuthenticationError {
            if let error = error as? SignInError {
                switch error {
                case .invalidWPComEmail(let source):
                    switch source {
                    case .wpCom:
                        return .invalidEmailFromWPComLogin
                    case .wpComSiteAddress:
                        return .invalidEmailFromSiteAddressLogin
                    }
                case .invalidWPComPassword(let source):
                    switch source {
                    case .wpCom:
                        return .invalidPasswordFromWPComLogin
                    case .wpComSiteAddress:
                        return .invalidPasswordFromSiteAddressLogin
                    }
                }
            }

            let error = error as NSError

            switch error.code {
            case WordPressComRestApiError.unknown.rawValue:
                let restAPIErrorCode = error.userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String
                if restAPIErrorCode == "unknown_user" {
                    return .emailDoesNotMatchWPAccount
                } else {
                    return .unknown
                }
            case WordPressOrgXMLRPCValidatorError.invalid.rawValue:
                // We were able to connect to the site but it does not seem to be a WordPress site.
                return .notWPSite
            case NSURLErrorCannotFindHost,
                 NSURLErrorCannotConnectToHost:
                // The site cannot be found. This can mean that the domain is invalid.
                return .notValidAddress
            case NSURLErrorSecureConnectionFailed:
                // The site does not have a valid SSL. It could be that it is only HTTP.
                return .noSecureConnection
            default:
                return .unknown
            }
        }
    }

    func isSupportedError(_ error: Error) -> Bool {
        let wooAuthError = AuthenticationError.make(with: error)
        return wooAuthError != .unknown
    }
}
