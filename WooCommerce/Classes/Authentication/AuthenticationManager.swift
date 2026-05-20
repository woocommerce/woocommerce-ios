import Foundation
import SafariServices
import KeychainAccess
import SwiftUI
import WordPressAuthenticator
import WordPressUI
import Yosemite
import UIKit
import class Networking.UserAgent
import enum Experiments.ABTest
import struct Networking.Settings
import protocol Experiments.FeatureFlagService
import protocol Storage.StorageManagerType
import protocol Networking.ApplicationPasswordUseCase
import class Networking.OneTimeApplicationPasswordUseCase
import class Networking.DefaultApplicationPasswordUseCase
import protocol Experiments.ABTestVariationProvider
import protocol WooFoundation.Analytics
import struct Experiments.CachedABTestVariationProvider
import struct NetworkingCore.WordPressAPIDiscovery

/// Encapsulates all of the interactions with the WordPress Authenticator
///
class AuthenticationManager: Authentication {
    var displayAuthenticatorIfLoggedOut: (() -> UINavigationController?)?

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

    private let stores: StoresManager

    private let featureFlagService: FeatureFlagService

    private let analytics: Analytics

    private let abTestVariationProvider: ABTestVariationProvider

    /// Keeps a reference to the checker
    private var postSiteCredentialLoginChecker: PostSiteCredentialLoginChecker?

    /// Keeps a reference to the use case
    private var siteCredentialLoginUseCase: SiteCredentialLoginUseCase?

    /// Keeps a reference to the QR-login coordinator while the flow is active.
    private var qrLoginCoordinator: QRLoginCoordinator?

    /// Availability gate for the QR-login prologue / deep link entry.
    private let qrLoginAvailability: QRLoginAvailabilityProvider

    /// Injected for unit test purposes
    private let switchStoreUseCase: SwitchStoreUseCaseProtocol?

    private let userDefaults: UserDefaults

    init(stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         analytics: Analytics = ServiceLocator.analytics,
         abTestVariationProvider: ABTestVariationProvider = CachedABTestVariationProvider(),
         switchStoreUseCase: SwitchStoreUseCaseProtocol? = nil,
         userDefaults: UserDefaults = .standard,
         qrLoginAvailability: QRLoginAvailabilityProvider = QRLoginAvailability()) {
        self.stores = stores
        self.storageManager = storageManager
        self.featureFlagService = featureFlagService
        self.analytics = analytics
        self.abTestVariationProvider = abTestVariationProvider
        self.switchStoreUseCase = switchStoreUseCase
        self.userDefaults = userDefaults
        self.qrLoginAvailability = qrLoginAvailability
    }

    /// Initializes the WordPress Authenticator.
    ///
    func initialize() {
        WordPressAuthenticator.initializeWithCustomConfigs()
        WordPressAuthenticator.shared.delegate = self
    }

    /// Returns the Login Flow view controller.
    ///
    func authenticationUI() -> UIViewController {
        if qrLoginAvailability.isAvailableForPrologueSync() {
            return makeQRLoginUI()
        }
        let loginViewController: UIViewController = {
            let loginUI = WordPressAuthenticator.loginUI(onLoginButtonTapped: { [weak self] in
                guard let self else { return }
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

    /// Builds the QR-login navigation controller used as the root login UI when
    /// QR-login is available. The QR coordinator owns the prologue and
    /// scanner; the fallback CTA inside the prologue pushes the legacy
    /// site-address view onto the same navigation stack.
    ///
    private func makeQRLoginUI() -> UIViewController {
        let navigationController = LoginNavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        // `authenticationUI()` is always called on the main thread (it returns
        // the root login view controller). `QRLoginCoordinator` is @MainActor,
        // so we assert main-actor isolation to construct + start it.
        MainActor.assumeIsolated {
            makeQRLoginCoordinator(mode: .camera, navigationController: navigationController).start()
        }
        return navigationController
    }

    /// Builds a `QRLoginCoordinator` wired with the shared site-address
    /// fallback and success handlers, and retains it as `qrLoginCoordinator`.
    /// Starting it is the caller's responsibility.
    @MainActor
    private func makeQRLoginCoordinator(mode: QRLoginCoordinator.Mode,
                                        navigationController: UINavigationController) -> QRLoginCoordinator {
        let coordinator = QRLoginCoordinator(
            mode: mode,
            navigationController: navigationController,
            onEnterSiteURL: { [weak navigationController] in
                guard let navigationController else { return }
                NavigateToEnterSite().execute(from: navigationController)
            },
            onShowHelp: { [weak self, weak navigationController] in
                guard let self, let navigationController else { return }
                let presenter = navigationController.topViewController ?? navigationController
                self.presentSupport(from: presenter, sourceTag: .loginWithQRCode, siteURL: nil)
            },
            onSuccess: { [weak self, weak navigationController] in
                guard let self, let navigationController else { return }
                self.qrLoginCoordinator = nil
                self.startStorePicker(with: WooConstants.placeholderStoreID, in: navigationController)
            }
        )
        qrLoginCoordinator = coordinator
        return coordinator
    }

    /// Handles an Authentication URL Callback. Returns *true* on success.
    ///
    func handleAuthenticationUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool {
        if WordPressAuthenticator.shared.isWordPressAuthUrl(url) {
            return WordPressAuthenticator.shared.handleWordPressAuthUrl(url,
                                                                        rootViewController: rootViewController)
        }

        if isQRLoginUrl(url),
           let handled = handleQRLoginUrl(url) {
            return handled
        }

        if isAppLoginUrl(url) {
            guard let navigationController = displayAuthenticatorIfLoggedOut?() else {
                DDLogWarn("App login link error: cannot display authenticator UI.")
                return false
            }

            guard let queryDictionary = url.query?.dictionaryFromQueryString(),
                  let siteURL = queryDictionary.string(forKey: "siteUrl"),
                  siteURL.isNotEmpty else {
                DDLogWarn("App login link error: we couldn't retrieve the query dictionary from the sign-in URL.")
                analytics.track(event: .AppLoginDeepLink.appLoginLinkMalformed(url: url.absoluteString))
                showLoginURLFailure(rootViewController: rootViewController)
                return false
            }
            if let wpcomEmail = queryDictionary.string(forKey: "wpcomEmail"),
               wpcomEmail.isNotEmpty {
                analytics.track(event: .AppLoginDeepLink.appLoginLinkSuccess(flow: .wpCom))
                showWPCOMLogin(siteURL: siteURL, email: wpcomEmail, rootViewController: navigationController)
                return true
            }

            if let wporgUsername = queryDictionary.string(forKey: "username"),
               wporgUsername.isNotEmpty {
                analytics.track(event: .AppLoginDeepLink.appLoginLinkSuccess(flow: .noWpCom))
                showWPOrgLogin(siteURL: siteURL, username: wporgUsername, rootViewController: navigationController)
                return true
            }
        }

        showLoginURLFailure(rootViewController: rootViewController)
        analytics.track(event: .AppLoginDeepLink.appLoginLinkMalformed(url: url.absoluteString))
        return false
    }

    private func showWPCOMLogin(siteURL: String, email: String, rootViewController: UIViewController) {
        let loginFields = LoginFields()
        loginFields.siteAddress = siteURL
        loginFields.restrictToWPCom = true
        loginFields.username = email
        rootViewController.dismiss(animated: false)
        NavigateToEnterWPCOMPassword(loginFields: loginFields).execute(from: rootViewController)
    }

    private func showWPOrgLogin(siteURL: String, username: String, rootViewController: UIViewController) {
        let loginFields = LoginFields()
        loginFields.siteAddress = siteURL
        loginFields.restrictToWPCom = false
        loginFields.username = username
        rootViewController.dismiss(animated: false)
        NavigateToEnterSiteCredentials(loginFields: loginFields).execute(from: rootViewController)
    }

    private func showLoginURLFailure(rootViewController: UIViewController) {
        let contextNoticePresenter: NoticePresenter = {
            let noticePresenter = DefaultNoticePresenter()
            noticePresenter.presentingViewController = rootViewController
            return noticePresenter
        }()
        contextNoticePresenter.enqueue(notice: .init(title: AuthenticationConstants.appLinkLoginFailureMessage))
    }

    private func isAppLoginUrl(_ url: URL) -> Bool {
        let expectedPrefix = WooConstants.appLoginURLPrefix
        return url.absoluteString.hasPrefix(expectedPrefix)
    }

    /// Case-insensitive match for `woocommerce://qr-login` deep links
    /// (spec §3 footer: scheme + host check is case-insensitive). Uses a
    /// prefix check — matching `isAppLoginUrl` — because `URL.host` is
    /// unreliable for custom-scheme URLs across Foundation versions.
    private func isQRLoginUrl(_ url: URL) -> Bool {
        url.absoluteString.lowercased().hasPrefix(WooConstants.qrLoginURLPrefix)
    }

    /// Handles an inbound `woocommerce://qr-login?...` URL by driving the QR
    /// coordinator's deep-link flow.
    ///
    /// Returns `nil` when the feature isn't available — the caller falls
    /// through to the standard handlers so the user lands on the regular
    /// prologue instead of a no-op (spec §2.2).
    ///
    /// Token / grant lifetime is not managed here: clearing the URL from the
    /// launch state is the OS / scene-delegate's job; this method makes a
    /// best-effort to not retain the payload anywhere persistent.
    private func handleQRLoginUrl(_ url: URL) -> Bool? {
        // Sync availability check is enough: the merchant chose this path
        // by opening the link, so we just need the flag (or debug override)
        // to be on. Bucket and camera are bypassed.
        guard let overrideValue = (qrLoginAvailability as? QRLoginAvailability)?.deepLinkSyncOverride(),
              overrideValue else {
            return nil
        }

        guard let navigationController = displayAuthenticatorIfLoggedOut?() else {
            DDLogWarn("QR-login deep link: cannot display authenticator UI.")
            return false
        }

        let payload = QRLoginPayloadParser().parse(url)
        // `handleAuthenticationUrl` runs on the main thread (URL handling from
        // the scene/app delegate). `QRLoginCoordinator` is @MainActor.
        MainActor.assumeIsolated {
            if let qrLoginCoordinator {
                // Displaying the authenticator already built the QR-login UI
                // and started a coordinator on the prologue. Reuse it for the
                // deep-link payload — starting a second coordinator would
                // orphan the first and leave a dead prologue underneath the
                // number-match screen.
                qrLoginCoordinator.presentDeepLink(payload: payload)
            } else {
                // The legacy authenticator UI is the root; start a standalone
                // deep-link coordinator on its navigation stack.
                makeQRLoginCoordinator(mode: .deepLink(payload: payload),
                                       navigationController: navigationController).start()
            }
        }
        return true
    }

    /// Handles a `woocommerce://qr-login` deep link that arrived while the
    /// merchant is already signed in (spec §4.4). Shows a warning; confirming
    /// signs the merchant out and resumes the QR sign-in, cancelling keeps the
    /// current session. Returns `true` when the URL was a QR-login deep link
    /// this method took over, `false` otherwise (the caller then drops it).
    func handleSignedInQRLoginDeepLink(_ url: URL, rootViewController: UIViewController) -> Bool {
        guard isQRLoginUrl(url),
              let overrideValue = (qrLoginAvailability as? QRLoginAvailability)?.deepLinkSyncOverride(),
              overrideValue else {
            return false
        }
        // URL handling from the scene/app delegate runs on the main thread.
        MainActor.assumeIsolated {
            presentSessionReplaceWarning(for: url, from: rootViewController)
        }
        return true
    }

    @MainActor
    private func presentSessionReplaceWarning(for url: URL, from presentingViewController: UIViewController) {
        let analytics = DefaultQRLoginAnalyticsTracking()
        analytics.setFlow(.loginQR)
        analytics.trackStep(.qrSessionReplaceWarning)

        let warningView = QRLoginSessionReplaceView(
            onConfirm: { [weak self] in
                analytics.trackClick(.submit)
                presentingViewController.dismiss(animated: true) {
                    self?.signOutAndResumeQRLogin(url: url)
                }
            },
            onCancel: {
                analytics.trackClick(.dismiss)
                presentingViewController.dismiss(animated: true)
            }
        )
        let hostingController = UIHostingController(rootView: warningView)
        hostingController.modalPresentationStyle = .fullScreen
        presentingViewController.present(hostingController, animated: true)
    }

    /// Signs the merchant out and resumes the QR sign-in. `deauthenticate()` is
    /// best-effort local teardown that always leaves the app signed out, so the
    /// QR sign-in can always resume. The deep link is re-handled on the next
    /// run-loop tick, once `AppCoordinator` has reacted to the deauthentication
    /// and installed the logged-out login UI — re-handling synchronously would
    /// race that Combine-driven swap (spec §4.4).
    @MainActor
    private func signOutAndResumeQRLogin(url: URL) {
        ServiceLocator.stores.deauthenticate()
        DispatchQueue.main.async { [weak self] in
            _ = self?.handleQRLoginUrl(url)
        }
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
        updateUserDefaultsIfSuspendedSiteError(error)
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
        if let site = siteInfo {
            analytics.track(event: .Login.siteInfoFetched(
                exists: site.exists,
                hasWordPress: site.isWP,
                isWPCom: site.isWPCom,
                isCommerceGarden: site.isCommerceGarden,
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

        if site.isWPCom || site.isCommerceGarden || site.isJetpackConnected {
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
                                                         isCommerceGarden: siteInfo?.isCommerceGarden ?? false,
                                                         isJetpackInstalled: siteInfo?.hasJetpack ?? false,
                                                         isJetpackActive: siteInfo?.isJetpackActive ?? false,
                                                         isJetpackConnected: siteInfo?.isJetpackConnected ?? false))

        guard let site = siteInfo, let navigationController else {
            navigationController?.show(noWPUI, sender: nil)
            return
        }

        // Check if the site already belongs to the current account before showing
        // an error. The user may have typed a URL for a site they already have.
        let matcher = ULAccountMatcher(storageManager: storageManager)
        matcher.refreshStoredSites()
        if let matchedSite = matcher.matchedSite(originalURL: site.url) {
            if matchedSite.isWooCommerceActive {
                switchToAlreadyConnectedSite(matchedSite, in: navigationController)
                return
            } else {
                let noWoo = noWooUI(for: matchedSite,
                                    with: matcher,
                                    navigationController: navigationController,
                                    onStorePickerDismiss: {})
                navigationController.show(noWoo, sender: nil)
                return
            }
        }

        let errorUI = errorUI(for: site, in: navigationController)
        navigationController.show(errorUI, sender: nil)
    }

    /// Navigates back to the store picker and selects the site that the user
    /// entered via site discovery, as if they had tapped it in the list.
    private func switchToAlreadyConnectedSite(_ site: Site, in navigationController: UINavigationController) {
        navigationController.popToRootViewController(animated: true)
        if let storePicker = navigationController.viewControllers
            .compactMap({ $0 as? StorePickerViewController })
            .first {
            storePicker.selectSite(site)
        }
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
            onFailure(error, false)
            let challengeType: String? = {
                if case .basicAuthenticationRequired = error {
                    return "basic_auth"
                }
                return nil
            }()
            self.analytics.track(event: .Login.siteCredentialFailed(step: .authentication,
                                                                    error: error.underlyingError,
                                                                    challengeType: challengeType))
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

        let isAppPasswordAuthError = {
            switch error {
            case SiteCredentialLoginError.genericFailure,
                 SiteCredentialLoginError.invalidCredentials,
                 SiteCredentialLoginError.basicAuthenticationRequired:
                return false
            case is SiteCredentialLoginError:
                return true
            default:
                return false
            }
        }()

        // Show the tutorial immediately if it's obvious that the error can be solved by the app password flow.
        if isAppPasswordAuthError {
            presentAppPasswordTutorial(error: error, for: siteURL, in: viewController)
        } else {
            presentAppPasswordAlert(error: error, for: siteURL, in: viewController)
        }
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
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, socialUser: SocialUser?) {
        // NO-OP: The current WC version does not support Signup. Let SIWA through.
        guard case .apple = socialUser?.service else {
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
    func presentSupport(from sourceViewController: UIViewController, screen: CustomHelpCenterContent.Screen, siteURL: URL?) {
        let customHelpCenterContent = CustomHelpCenterContent(screen: screen,
                                                              flow: AuthenticatorAnalyticsTracker.shared.state.lastFlow)
        presentHelpAndSupport(from: sourceViewController, customHelpCenterContent: customHelpCenterContent, sourceTag: nil, siteURL: siteURL)
    }

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, siteURL: URL?) {
        presentHelpAndSupport(from: sourceViewController, sourceTag: sourceTag, siteURL: siteURL)
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
                        lastFlow: AuthenticatorAnalyticsTracker.Flow,
                        siteURL: String?) {
        let parsedURL: URL? = {
            // swiftlint:disable:next control_statement
            guard let siteURL, let url = URL(string: siteURL),
                  let scheme = url.scheme?.lowercased(),
                  (scheme == "http" || scheme == "https"),
                  url.host != nil else {
                return nil
            }
            return url
        }()
        guard let customHelpCenterContent = CustomHelpCenterContent(step: lastStep, flow: lastFlow) else {
            presentSupport(from: sourceViewController, sourceTag: sourceTag, siteURL: parsedURL)
            return
        }

        presentHelpAndSupport(from: sourceViewController, customHelpCenterContent: customHelpCenterContent, sourceTag: sourceTag, siteURL: parsedURL)
    }

    /// Presents the Support new request, from a given ViewController, with a specified SourceTag.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        let supportForm = SupportFormHostingController(viewModel: .init(sourceTag: sourceTag.origin))
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
        if let appleUserID {
            keychain.wooAppleID = appleUserID
        }
        appleUserID = nil

        ServiceLocator.stores.authenticate(credentials: .init(authToken: wpcom.authToken))
        let action = AccountAction.synchronizeAccount { result in
            switch result {
            case .success(let account):
                let credentials = Credentials.wpcom(username: account.username, authToken: wpcom.authToken, siteAddress: wpcom.siteURL)
                ServiceLocator.stores
                    .authenticate(credentials: credentials)
                    .synchronizeEntities(onCompletion: onCompletion)
            case .failure:
                ServiceLocator.stores.synchronizeEntities(onCompletion: onCompletion)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    func handleSiteInfoFailure(siteURL: String, error: Error, completion: @escaping (Bool) -> Void) {
        DDLogError("⚠️ Site info check failed for \(siteURL): \(error.localizedDescription)")

        let discovery = WordPressAPIDiscovery()
        Task { @MainActor in
            let discoveredRoot = await discovery.discoverRESTAPIRootURL(for: siteURL)
            let hasRESTAPI = discoveredRoot != nil

            DDLogInfo("🔍 API discovery for \(siteURL): REST API \(hasRESTAPI ? "found" : "not found")")
            completion(hasRESTAPI)
        }
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

    func showSiteCreationGuide(in navigationController: UINavigationController) {
        analytics.track(event: .StoreCreation.loginPrologueStartingANewStoreTapped())

        guard let url = try? AuthenticationConstants.hostingURL.asURL() else {
            return
        }
        let webView = SFSafariViewController(url: url)
        navigationController.present(webView, animated: true)
    }
}

// MARK: - Private helpers
private extension AuthenticationManager {

    func getAvailableStores() async -> [Site] {
        let storePickerViewModel = StorePickerViewModel(configuration: .switchingStores,
                                                        stores: stores,
                                                        storageManager: storageManager)
        await storePickerViewModel.refreshSites(currentlySelectedSiteID: nil)

        guard case let .available(sites) = storePickerViewModel.state, sites.isNotEmpty else {
            return []
        }

        return sites
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
            guard let self else { return }
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
        // Start the store picker
        let config = StorePickerConfiguration.login
        storePickerCoordinator = StorePickerCoordinator(navigationController,
                                                        config: config,
                                                        switchStoreUseCase: switchStoreUseCase)
        storePickerCoordinator?.onDismiss = onDismiss
        if let siteID {
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
                guard let self else { return }
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
    func applicationPasswordWebView(for siteURL: String, previousVC: UIViewController?) -> UIViewController {
        let viewModel = ApplicationPasswordAuthorizationViewModel(siteURL: siteURL)
        let controller = ApplicationPasswordAuthorizationWebViewController(viewModel: viewModel,
                                                                           previousViewController: previousVC,
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
            let useCase = OneTimeApplicationPasswordUseCase(applicationPassword: applicationPassword,
                                                            siteAddress: siteURL)
            /// IMPORTANT: authenticate after creating the use case above to make sure that
            /// the application password is saved into keychain.
            ServiceLocator.stores.authenticate(credentials: credentials)
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

        guard !site.isWPCom && !site.isCommerceGarden else {
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
        checkSiteCredentialLogin(to: siteURL, with: useCase, in: navigationController, previousViewController: nil)
    }

    func checkSiteCredentialLogin(to siteURL: String,
                                  with useCase: ApplicationPasswordUseCase,
                                  in navigationController: UINavigationController,
                                  previousViewController: UIViewController? = nil) {
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: useCase,
                                                     previousViewController: previousViewController)
        checker.checkEligibility(for: siteURL, from: navigationController) { [weak self] in
            guard let self else { return }
            // Tracking `signedIn` after the user logged in using site creds & application password is created
            // to ensure that we are measuring only the users who can actually start using the app
            WordPressAuthenticator.track(.signedIn)

            // navigates to home screen immediately with a placeholder store ID
            self.startStorePicker(with: WooConstants.placeholderStoreID, in: navigationController)
        }
        self.postSiteCredentialLoginChecker = checker
    }

    /// Presents Application Passwords tutorial before redirecting user to the site login using a web view.
    ///
    private func presentAppPasswordTutorial(error: Error, for siteURL: String, in viewController: UIViewController) {
        let tutorialVC = ApplicationPasswordTutorialViewController(error: error)
        tutorialVC.continueButtonTapped = { [weak self] in
            self?.presentApplicationPasswordWebView(for: siteURL, in: viewController)
            self?.analytics.track(event: .ApplicationPasswordAuthorization.explanationContinueButtonTapped())
        }
        tutorialVC.contactSupportButtonTapped = { [weak self] in
            let supportController = SupportFormHostingController(viewModel: .init(sourceTag: WordPressSupportSourceTag.loginUsernamePassword.origin))
            supportController.show(from: viewController)
            self?.analytics.track(event: .ApplicationPasswordAuthorization.explanationContactSupportTapped())
        }
        viewController.show(tutorialVC, sender: viewController)

        analytics.track(event: .ApplicationPasswordAuthorization.invalidLoginPageDetected())
    }

    /// Presents login error alert before redirecting user to the site login using a web view.
    ///
    private func presentAppPasswordAlert(error: Error, for siteURL: String, in viewController: UIViewController) {
        let shouldEnableWebFlow: Bool = {
            /// Since our detection of invalid credentials error might be inaccurate,
            /// adding the fallback to web flow would unblock users from login.
            if let siteCredentialError = error as? SiteCredentialLoginError,
               case .invalidCredentials = siteCredentialError {
                return true
            }
            return false
        }()
        let defaultAction = shouldEnableWebFlow ? { [weak self] in
            guard let self else { return }
            presentApplicationPasswordWebView(for: siteURL, in: viewController)
        } : nil
        let alertController = FancyAlertViewController.makeSiteCredentialLoginErrorAlert(
            message: (error as NSError).localizedDescription,
            defaultAction: defaultAction
        )

        viewController.present(alertController, animated: true)
    }

    /// Presents app password site login using a web view.
    ///
    private func presentApplicationPasswordWebView(for siteURL: String, in viewController: UIViewController) {
        let webViewController = applicationPasswordWebView(for: siteURL, previousVC: viewController)
        viewController.navigationController?.pushViewController(webViewController, animated: true)
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

    func updateUserDefaultsIfSuspendedSiteError(_ error: Error) {
        if let serviceError = error as? WordPressComBlogServiceError,
           serviceError == .wpcomSiteSuspended {
            analytics.track(event: .WPCOMSiteSuspended.siteSuspended(event: .login))
            userDefaults.setWPCOMSiteSuspended(true)
        }
    }

    func isSupportedError(_ error: Error) -> Bool {
        let wooAuthError = AuthenticationError.make(with: error)
        return wooAuthError != .unknown
    }
}


// MARK: - User defaults helpers
//
extension UserDefaults {
    func setWPCOMSiteSuspended(_ suspended: Bool) {
        self[.wpcomSiteSuspended] = suspended
    }

    @objc dynamic var wpcomSiteSuspended: Bool {
        bool(forKey: Key.wpcomSiteSuspended.rawValue)
    }
}

// MARK: - Help and support helpers
private extension AuthenticationManager {

    func presentHelpAndSupport(from sourceViewController: UIViewController,
                               customHelpCenterContent: CustomHelpCenterContent? = nil,
                               sourceTag: WordPressSupportSourceTag?,
                               siteURL: URL?) {
        let identifier = HelpAndSupportViewController.classNameWithoutNamespaces
        let supportViewController = UIStoryboard.settings.instantiateViewController(identifier: identifier,
                                                                                     creator: { coder -> HelpAndSupportViewController? in
            if let customHelpCenterContent {
                return HelpAndSupportViewController(customHelpCenterContent: customHelpCenterContent,
                                                    sourceTag: sourceTag?.origin,
                                                    loginSiteURL: siteURL,
                                                    coder: coder)
            }
            return HelpAndSupportViewController(sourceTag: sourceTag?.origin,
                                                loginSiteURL: siteURL,
                                                coder: coder)
        })
        supportViewController.displaysDismissAction = true

        let navController = WooNavigationController(rootViewController: supportViewController)
        navController.modalPresentationStyle = .formSheet

        sourceViewController.present(navController, animated: true, completion: nil)
    }
}
