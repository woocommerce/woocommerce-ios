import Foundation
import KeychainAccess
import WordPressAuthenticator
import WordPressUI
import Yosemite
import class Networking.UserAgent
import enum Experiments.ABTest
import struct Networking.Settings
import protocol Experiments.FeatureFlagService
import protocol Storage.StorageManagerType
import protocol Networking.ApplicationPasswordUseCase
import class Networking.OneTimeApplicationPasswordUseCase
import class Networking.DefaultApplicationPasswordUseCase
import protocol Experiments.ABTestVariationProvider
import struct Experiments.CachedABTestVariationProvider

/// Encapsulates all of the interactions with the WordPress Authenticator
///
class AuthenticationManager: Authentication {

    /// Store Picker Coordinator
    ///
    private var storePickerCoordinator: StorePickerCoordinator?

    /// Store creation coordinator in the logged-out state.
    private var loggedOutStoreCreationCoordinator: LoggedOutStoreCreationCoordinator?

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

    private let featureFlagService: FeatureFlagService

    private let analytics: Analytics

    private let abTestVariationProvider: ABTestVariationProvider

    /// Keeps a reference to the checker
    private var postSiteCredentialLoginChecker: PostSiteCredentialLoginChecker?

    /// Keeps a reference to the use case
    private var siteCredentialLoginUseCase: SiteCredentialLoginUseCase?

    init(storageManager: StorageManagerType = ServiceLocator.storageManager,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         analytics: Analytics = ServiceLocator.analytics,
         abTestVariationProvider: ABTestVariationProvider = CachedABTestVariationProvider()) {
        self.storageManager = storageManager
        self.featureFlagService = featureFlagService
        self.analytics = analytics
        self.abTestVariationProvider = abTestVariationProvider
    }

    /// Initializes the WordPress Authenticator.
    ///
    func initialize(loggedOutAppSettings: LoggedOutAppSettingsProtocol) {
        WordPressAuthenticator.initializeWithCustomConfigs()
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

                self.analytics.track(.loginPrologueContinueTapped)
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
                             credentials: AuthenticatorCredentials? = nil,
                             navigationController: UINavigationController,
                             onStorePickerDismiss: @escaping () -> Void) -> UIViewController? {

        /// Account mismatched case
        guard matcher.match(originalURL: siteURL) else {
            DDLogWarn("⚠️ Present account mismatch error for site: \(String(describing: siteURL))")
            return accountMismatchUI(for: siteURL, siteCredentials: credentials?.wporg, with: matcher, in: navigationController)
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
        if let site = siteInfo {
            analytics.track(event: .Login.siteInfoFetched(
                exists: site.exists,
                hasWordPress: site.isWP,
                isWPCom: site.isWPCom,
                isJetpackInstalled: site.hasJetpack,
                isJetpackActive: site.isJetpackActive,
                isJetpackConnected: site.isJetpackConnected,
                urlAfterRedirects: site.url
            ))
        }

        /// WordPress must be present.
        guard let site = siteInfo, site.isWP else {
            let authenticationResult: WordPressAuthenticatorResult = .injectViewController(value: noWPUI)

            onCompletion(authenticationResult)

            return
        }

        /// save the site to memory to check for jetpack requirement in epilogue
        currentSelfHostedSite = site

        if site.isWPCom || site.isJetpackConnected {
            let authenticationResult: WordPressAuthenticatorResult = .presentEmailController
            onCompletion(authenticationResult)
        } else {
            let authenticationResult: WordPressAuthenticatorResult = .presentPasswordController(value: true)
            onCompletion(authenticationResult)
        }
    }

    /// Displays appropriate error based on the input `siteInfo`.
    /// Data flow following ZwYqDGHdenvYZoPHXZ1SOf-fi
    ///
    func troubleshootSite(_ siteInfo: WordPressComSiteInfo?, in navigationController: UINavigationController?) {
        analytics.track(event: .SitePicker.siteDiscovery(hasWordPress: siteInfo?.isWP ?? false,
                                                         isWPCom: siteInfo?.isWPCom ?? false,
                                                         isJetpackInstalled: siteInfo?.hasJetpack ?? false,
                                                         isJetpackActive: siteInfo?.isJetpackActive ?? false,
                                                         isJetpackConnected: siteInfo?.isJetpackConnected ?? false))

        guard let site = siteInfo, let navigationController = navigationController else {
            navigationController?.show(noWPUI, sender: nil)
            return
        }

        let errorUI = errorUI(for: site, in: navigationController)
        navigationController.show(errorUI, sender: nil)
    }

    /// Handles site credential login
    func handleSiteCredentialLogin(credentials: WordPressOrgCredentials,
                                   onLoading: @escaping (Bool) -> Void,
                                   onSuccess: @escaping () -> Void,
                                   onFailure: @escaping  (Error, Bool) -> Void) {
        let useCase = SiteCredentialLoginUseCase(siteURL: credentials.siteURL)
        useCase.setupHandlers(onLoginSuccess: onSuccess, onLoginFailure: { [weak self] error in
            guard let self else { return }
            onLoading(false)
            onFailure(error.underlyingError, false)
            self.analytics.track(event: .Login.siteCredentialFailed(step: .authentication, error: error))
        })
        self.siteCredentialLoginUseCase = useCase

        useCase.handleLogin(username: credentials.username, password: credentials.password)
        onLoading(true)
    }

    func handleSiteCredentialLoginFailure(error: Error,
                                          for siteURL: String,
                                          in viewController: UIViewController) {
        guard featureFlagService.isFeatureFlagEnabled(.manualErrorHandlingForSiteCredentialLogin) else {
            return
        }
        let alertController = FancyAlertViewController.makeSiteCredentialLoginErrorAlert(
            message: (error as NSError).localizedDescription,
            defaultAction: { [weak self] in
                guard let self else { return }
                let webViewController = self.applicationPasswordWebView(for: siteURL)
                viewController.navigationController?.pushViewController(webViewController, animated: true)
            }
        )
        viewController.present(alertController, animated: true)
    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController,
                              for credentials: AuthenticatorCredentials,
                              source: SignInSource?,
                              onDismiss: @escaping () -> Void) {

        guard let siteURL = credentials.wpcom?.siteURL ?? credentials.wporg?.siteURL else {
            // This should not happen since the resulting credentials should be either `wpcom` or `wporg`
            return DDLogError("⛔️ No site URL found to present Login Epilogue.")
        }

        /// If the user logged in with site credentials,
        /// check if they can use the app and navigates to the home screen.
        if let siteCredentials = credentials.wporg {
            return didAuthenticateUser(to: siteURL,
                                       with: siteCredentials,
                                       in: navigationController)
        }

        /// Jetpack is required. Present an error if we don't detect a valid installation for a self-hosted site.
        if isJetpackInvalidForSelfHostedSite(url: siteURL) {
            return presentJetpackError(for: siteURL, with: credentials, in: navigationController, onDismiss: onDismiss)
        }

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.loginErrorNotifications) {
            ServiceLocator.pushNotesManager.cancelLocalNotification(scenarios: LocalNotification.Scenario.allCases)
        }

        let matcher = ULAccountMatcher(storageManager: storageManager)
        matcher.refreshStoredSites()

        if let vc = errorViewController(for: siteURL,
                                        with: matcher,
                                        credentials: credentials,
                                        navigationController: navigationController,
                                        onStorePickerDismiss: onDismiss) {
            loggedOutAppSettings?.setErrorLoginSiteAddress(siteURL)
            navigationController.show(vc, sender: nil)
        } else {
            loggedOutAppSettings?.setErrorLoginSiteAddress(nil)
            let matchedSite = matcher.matchedSite(originalURL: siteURL)
            startStorePicker(with: matchedSite?.siteID, source: source, in: navigationController, onDismiss: onDismiss)
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

    /// Presents the Support Interface
    ///
    /// - Parameters:
    ///     - from: UIViewController instance from which to present the support interface
    ///     - screen: A case from `CustomHelpCenterContent.Screen` enum. This represents authentication related screens from WCiOS.
    ///
    func presentSupport(from sourceViewController: UIViewController, screen: CustomHelpCenterContent.Screen) {
        let customHelpCenterContent = CustomHelpCenterContent(screen: screen,
                                                              flow: AuthenticatorAnalyticsTracker.shared.state.lastFlow)
        presentSupport(from: sourceViewController, customHelpCenterContent: customHelpCenterContent)
    }

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        presentSupport(from: sourceViewController)
    }

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
                        lastFlow: AuthenticatorAnalyticsTracker.Flow) {
        guard let customHelpCenterContent = CustomHelpCenterContent(step: lastStep, flow: lastFlow) else {
            presentSupport(from: sourceViewController)
            return
        }

        presentSupport(from: sourceViewController, customHelpCenterContent: customHelpCenterContent)
    }

    /// Presents the Support new request, from a given ViewController, with a specified SourceTag.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        let supportForm = SupportFormHostingController(viewModel: .init(sourceTag: sourceTag.name))
        supportForm.show(from: sourceViewController)
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
        false
    }

    /// Synchronizes the specified WordPress Account.
    ///
    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {
        if let wporg = credentials.wporg {
            ServiceLocator.stores.authenticate(credentials: .wporg(username: wporg.username,
                                                                   password: wporg.password,
                                                                   siteAddress: wporg.siteURL))
            return onCompletion()
        }

        guard let wpcom = credentials.wpcom else {
            fatalError("No valid credentials found!")
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
        analytics.track(wooEvent)
    }

    /// Tracks a given Analytics Event, with the specified properties.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        guard let wooEvent = WooAnalyticsStat.valueOf(stat: event) else {
            DDLogWarn("⚠️ Could not convert WPAnalyticsStat with value: \(event.rawValue)")
            return
        }
        analytics.track(wooEvent, withProperties: properties)
    }

    /// Tracks a given Analytics Event, with the specified error.
    ///
    func track(event: WPAnalyticsStat, error: Error) {
        guard let wooEvent = WooAnalyticsStat.valueOf(stat: event) else {
            DDLogWarn("⚠️ Could not convert WPAnalyticsStat with value: \(event.rawValue)")
            return
        }
        analytics.track(wooEvent, withError: error)
    }

    // Navigate to store creation
    func showSiteCreation(in navigationController: UINavigationController) {
        analytics.track(event: .StoreCreation.loginPrologueCreateSiteTapped())

        let coordinator = LoggedOutStoreCreationCoordinator(source: .prologue,
                                                            navigationController: navigationController)
        self.loggedOutStoreCreationCoordinator = coordinator
        coordinator.start()
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
        case .invalidPasswordFromSiteAddressWPComLogin:
            notification = LocalNotification(scenario: .invalidPasswordFromSiteAddressWPComLogin)
        case .invalidPasswordFromWPComLogin:
            notification = LocalNotification(scenario: .invalidPasswordFromWPComLogin)
        default:
            notification = nil
        }

        if let notification = notification {
            ServiceLocator.pushNotesManager.cancelLocalNotification(scenarios: LocalNotification.Scenario.allCases)
            ServiceLocator.pushNotesManager.requestLocalNotification(notification,
                                                                     // 24 hours from now.
                                                                     trigger: UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false))
        }
    }
}

// MARK: - Private helpers
private extension AuthenticationManager {
    func isJetpackInvalidForSelfHostedSite(url: String) -> Bool {
        if let site = currentSelfHostedSite, site.url == url,
            (!site.hasJetpack || !site.isJetpackActive) {
            return true
        }
        return false
    }

    /// Presents an error if the user tries to log in to a site without Jetpack.
    ///
    func presentJetpackError(for siteURL: String,
                             with credentials: AuthenticatorCredentials,
                             in navigationController: UINavigationController,
                             onDismiss: @escaping () -> Void) {
        let viewModel = JetpackErrorViewModel(siteURL: siteURL,
                                              siteCredentials: credentials.wporg,
                                              onJetpackSetupCompletion: { [weak self] authorizedEmailAddress in
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
                self?.presentLoginEpilogue(in: navigationController, for: credentials, source: nil, onDismiss: onDismiss)
            }
        })
        let installJetpackUI = ULErrorViewController(viewModel: viewModel)
        navigationController.show(installJetpackUI, sender: nil)
    }

    func startStorePicker(with siteID: Int64? = nil,
                          source: SignInSource? = nil,
                          in navigationController: UINavigationController,
                          onDismiss: @escaping () -> Void = {}) {
        let config: StorePickerConfiguration = {
            switch source {
            case .custom(let source):
                if let loggedOutSource = LoggedOutStoreCreationCoordinator.Source(rawValue: source) {
                    return .storeCreationFromLogin(source: loggedOutSource)
                } else {
                    return .login
                }
            default:
                return .login
            }
        }()
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: config)
        storePickerCoordinator?.onDismiss = onDismiss
        if let siteID = siteID {
            storePickerCoordinator?.didSelectStore(with: siteID, onCompletion: onDismiss)
        } else {
            storePickerCoordinator?.start()
        }
    }

    /// The error screen to be displayed when the user tries to enter a site
    /// whose Jetpack is not associated with their account.
    /// - Parameters:
    ///     - siteURL: URL for the site to log in to.
    ///     - siteCredentials: WP.org credentials used to log in to the site if available.
    ///     - matcher: the matcher used to check for matching sites.
    ///     - navigationController: the controller that will present the view.
    ///
    func accountMismatchUI(for siteURL: String,
                           siteCredentials: WordPressOrgCredentials?,
                           with matcher: ULAccountMatcher,
                           in navigationController: UINavigationController) -> UIViewController {
        let viewModel = WrongAccountErrorViewModel(siteURL: siteURL,
                                                   showsConnectedStores: matcher.hasConnectedStores,
                                                   siteCredentials: siteCredentials,
                                                   onJetpackSetupCompletion: { email, xmlrpc in
            WordPressAuthenticator.showVerifyEmailForWPCom(
                from: navigationController,
                xmlrpc: xmlrpc,
                connectedEmail: email,
                siteURL: siteURL
            )
        })
        let mismatchAccountUI = ULAccountMismatchViewController(viewModel: viewModel)
        return mismatchAccountUI
    }

    /// The error screen to be displayed when the user tries to enter a site without WooCommerce.
    ///
    func noWooUI(for site: Site,
                 with matcher: ULAccountMatcher = .init(),
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

    /// The error screen to be displayed when the user tries to enter a site without WordPress.
    ///
    var noWPUI: UIViewController {
        let viewModel = NotWPErrorViewModel()
        return ULErrorViewController(viewModel: viewModel)
    }

    /// Web view to authorize application password for a given site.
    ///
    func applicationPasswordWebView(for siteURL: String) -> UIViewController {
        let viewModel = ApplicationPasswordAuthorizationViewModel(siteURL: siteURL)
        let controller = ApplicationPasswordAuthorizationWebViewController(viewModel: viewModel,
                                                                           onSuccess: { [weak self] applicationPassword, navigationController in
            guard let navigationController else {
                DDLogInfo("⚠️ No navigation controller found")
                return
            }
            let credentials: Credentials = .applicationPassword(
                username: applicationPassword.wpOrgUsername,
                password: applicationPassword.password.secretValue,
                siteAddress: siteURL
            )
            ServiceLocator.stores.authenticate(credentials: credentials)
            let useCase = OneTimeApplicationPasswordUseCase(applicationPassword: applicationPassword,
                                                            siteAddress: siteURL)
            self?.checkSiteCredentialLogin(to: siteURL, with: useCase, in: navigationController)
        })
        return controller
    }

    /// The error screen to be displayed when Jetpack setup for a site is required.
    /// This is the entry point to the native Jetpack setup flow.
    ///
    func jetpackSetupUI(for siteURL: String,
                        connectionMissingOnly: Bool,
                        in navigationController: UINavigationController) -> UIViewController {
        let viewModel = JetpackSetupRequiredViewModel(siteURL: siteURL,
                                                      connectionOnly: connectionMissingOnly)
        let jetpackSetupUI = ULErrorViewController(viewModel: viewModel)
        return jetpackSetupUI
    }

    /// Appropriate error to display for a site when entered from the site discovery flow.
    /// More about this flow: pe5sF9-mz-p2
    ///
    func errorUI(for site: WordPressComSiteInfo, in navigationController: UINavigationController) -> UIViewController {
        guard site.isWP else {
            return noWPUI
        }

        let matcher = ULAccountMatcher(storageManager: storageManager)
        matcher.refreshStoredSites()

        guard !site.isWPCom else {
            // The site doesn't belong to the current account since it was not included in the site picker.
            return accountMismatchUI(for: site.url, siteCredentials: nil, with: matcher, in: navigationController)
        }

        // Shows the native Jetpack flow during the site discovery flow.
        return jetpackSetupUI(for: site.url,
                              connectionMissingOnly: site.hasJetpack && site.isJetpackActive,
                              in: navigationController)
    }

    /// Checks if the authenticated user is eligible to use the app and navigates to the home screen.
    ///
    func didAuthenticateUser(to siteURL: String,
                             with siteCredentials: WordPressOrgCredentials,
                             in navigationController: UINavigationController) {
        guard let useCase = try? DefaultApplicationPasswordUseCase(
            username: siteCredentials.username,
            password: siteCredentials.password,
            siteAddress: siteCredentials.siteURL
        ) else {
            return assertionFailure("⛔️ Error creating application password use case")
        }
        checkSiteCredentialLogin(to: siteURL, with: useCase, in: navigationController)
    }

    func checkSiteCredentialLogin(to siteURL: String,
                                  with useCase: ApplicationPasswordUseCase,
                                  in navigationController: UINavigationController) {
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: useCase)
        checker.checkEligibility(for: siteURL, from: navigationController) { [weak self] in
            guard let self else { return }
            // Tracking `signedIn` after the user logged in using site creds & application password is created
            // to ensure that we are measuring only the users who can actually start using the app
            WordPressAuthenticator.track(.signedIn)

            // clear scheduled local notifications
            if self.featureFlagService.isFeatureFlagEnabled(.loginErrorNotifications) {
                ServiceLocator.pushNotesManager.cancelLocalNotification(scenarios: LocalNotification.Scenario.allCases)
            }

            // navigates to home screen immediately with a placeholder store ID
            self.startStorePicker(with: WooConstants.placeholderStoreID, in: navigationController)
        }
        self.postSiteCredentialLoginChecker = checker
    }
}

// MARK: - ViewModel Factory
extension AuthenticationManager {
    /// This is only exposed for testing.
    func viewModel(_ error: Error) -> ULErrorViewModel? {
        let wooAuthError = AuthenticationError.make(with: error)

        switch wooAuthError {
        case .emailDoesNotMatchWPAccount, .invalidEmailFromWPComLogin, .invalidEmailFromSiteAddressLogin:
            return NotWPAccountViewModel(error: error)
        case .notWPSite,
             .notValidAddress:
            return NotWPErrorViewModel()
        case .noSecureConnection:
            return NoSecureConnectionErrorViewModel()
        case .unknown, .invalidPasswordFromWPComLogin, .invalidPasswordFromSiteAddressWPComLogin:
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
        case invalidPasswordFromSiteAddressWPComLogin
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
                    case .wpCom, .custom:
                        return .invalidEmailFromWPComLogin
                    case .wpComSiteAddress:
                        return .invalidEmailFromSiteAddressLogin
                    }
                case .invalidWPComPassword(let source):
                    switch source {
                    case .wpCom, .custom:
                        return .invalidPasswordFromWPComLogin
                    case .wpComSiteAddress:
                        return .invalidPasswordFromSiteAddressWPComLogin
                    }
                }
            }

            let error = error as NSError

            switch error.code {
            case NSURLErrorCannotFindHost,
                 NSURLErrorCannotConnectToHost:
                // The site cannot be found. This can mean that the domain is invalid.
                return .notValidAddress
            case NSURLErrorSecureConnectionFailed:
                // The site does not have a valid SSL. It could be that it is only HTTP.
                return .noSecureConnection
            default:
                let restAPIErrorCode = error.userInfo["WordPressComRestApiErrorCodeKey"] as? String
                if restAPIErrorCode == "unknown_user" {
                    return .emailDoesNotMatchWPAccount
                }
                return .unknown
            }
        }
    }

    func isSupportedError(_ error: Error) -> Bool {
        let wooAuthError = AuthenticationError.make(with: error)
        return wooAuthError != .unknown
    }
}

// MARK: - Help and support helpers
private extension AuthenticationManager {

    func presentSupport(from sourceViewController: UIViewController,
                        customHelpCenterContent: CustomHelpCenterContent? = nil) {
        let identifier = HelpAndSupportViewController.classNameWithoutNamespaces
        let supportViewController = UIStoryboard.dashboard.instantiateViewController(identifier: identifier,
                                                                                     creator: { coder -> HelpAndSupportViewController? in
            guard let customHelpCenterContent = customHelpCenterContent else {
                /// Returning nil as we don't need to customise the HelpAndSupportViewController
                /// In this case `instantiateViewController` method will use the default `HelpAndSupportViewController` created from storyboard.
                ///
                return nil
            }

            return HelpAndSupportViewController(customHelpCenterContent: customHelpCenterContent, coder: coder)
        })
        supportViewController.displaysDismissAction = true

        let navController = WooNavigationController(rootViewController: supportViewController)
        navController.modalPresentationStyle = .formSheet

        sourceViewController.present(navController, animated: true, completion: nil)
    }
}
