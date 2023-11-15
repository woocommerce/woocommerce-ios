import UIKit
import Yosemite
import enum Alamofire.AFError
import class Networking.AlamofireNetwork
import WordPressAuthenticator
import WooFoundation

/// Coordinates the Jetpack setup flow in the authenticated state.
///
final class JetpackSetupCoordinator {
    let rootViewController: UIViewController

    private let site: Site
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private var requiresConnectionOnly: Bool
    private var jetpackConnectedEmail: String?
    private let stores: StoresManager
    private let analytics: Analytics
    private let dotcomAuthScheme: String

    private var loginNavigationController: LoginNavigationController?
    private var setupStepsNavigationController: UINavigationController?

    private lazy var emailLoginViewModel: WPComEmailLoginViewModel = {
        .init(siteURL: site.url,
              requiresConnectionOnly: requiresConnectionOnly,
              onPasswordUIRequest: showPasswordUI(email:),
              onMagicLinkUIRequest: showMagicLinkUI(email:),
              onError: { [weak self] message in
            self?.showAlert(message: message)
        })
    }()

    /// Title for login views
    private var loginViewTitle: String {
        requiresConnectionOnly ? Localization.connectJetpack : Localization.installJetpack
    }

    init(site: Site,
         dotcomAuthScheme: String = ApiCredentials.dotcomAuthScheme,
         rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.site = site
        self.dotcomAuthScheme = dotcomAuthScheme
        self.requiresConnectionOnly = false // to be updated later after fetching Jetpack status
        self.rootViewController = rootViewController
        self.stores = stores
        self.analytics = analytics

        /// the authenticator needs to be initialized with configs
        /// to be used for requesting authentication link and handle login later.
        WordPressAuthenticator.initializeWithCustomConfigs(dotcomAuthScheme: dotcomAuthScheme)
    }

    func showBenefitModal() {
        let benefitsController = JetpackBenefitsHostingController(siteURL: site.url, isJetpackCPSite: site.isJetpackCPConnected, onSubmit: { [weak self] in
            await self?.handleBenefitModalCTA()
        }, onDismiss: { [weak self] in
            self?.rootViewController.dismiss(animated: true, completion: nil)
        })
        rootViewController.present(benefitsController, animated: true, completion: nil)
    }

    func handleAuthenticationUrl(_ url: URL) -> Bool {
        let expectedPrefix = dotcomAuthScheme + "://" + Constants.magicLinkUrlHostname
        guard url.absoluteString.hasPrefix(expectedPrefix) else {
            return false
        }

        guard let queryDictionary = url.query?.dictionaryFromQueryString() else {
            DDLogError("⛔️ Magic link error: we couldn't retrieve the query dictionary from the sign-in URL.")
            return false
        }

        guard let authToken = queryDictionary.string(forKey: "token") else {
            DDLogError("⛔️ Magic link error: we couldn't retrieve the authentication token from the sign-in URL.")
            return false
        }

        startJetpackSetupFlow(authToken: authToken)
        return true
    }
}

// MARK: - Private helpers
//
private extension JetpackSetupCoordinator {
    @MainActor
    func handleBenefitModalCTA() async {
        guard site.isNonJetpackSite else {
            return presentJCPJetpackInstallFlow()
        }
        do {
            try await checkJetpackConnectionState()
            analytics.track(event: .JetpackSetup.connectionCheckCompleted(
                isAlreadyConnected: jetpackConnectedEmail != nil,
                requiresConnectionOnly: requiresConnectionOnly
            ))
            if let connectedEmail = jetpackConnectedEmail {
                startAuthentication(with: connectedEmail)
            } else {
                showWPComEmailLogin()
            }
        } catch JetpackCheckError.missingPermission {
            displayAdminRoleRequiredError()
            analytics.track(.jetpackSetupConnectionCheckFailed, withError: JetpackCheckError.missingPermission)
        } catch {
            DDLogError("⛔️ Jetpack status fetched error: \(error)")
            analytics.track(.jetpackSetupConnectionCheckFailed, withError: error)
            showAlert(message: Localization.errorCheckingJetpack)
        }
    }

    /// Navigates to the Jetpack installation flow for JCP sites.
    func presentJCPJetpackInstallFlow() {
        rootViewController.dismiss(animated: true, completion: { [weak self] in
            guard let self else { return }
            let installController = JCPJetpackInstallHostingController(siteID: self.site.siteID,
                                                                       siteURL: self.site.url,
                                                                       siteAdminURL: self.site.adminURL)

            installController.setDismissAction { [weak self] in
                self?.rootViewController.dismiss(animated: true, completion: nil)
            }
            self.rootViewController.present(installController, animated: true, completion: nil)
        })
    }

    /// Checks the Jetpack connection status for non-Jetpack sites to save the status and connected email locally if available.
    /// Throws any error if the Jetpack user fetch failed.
    ///
    func checkJetpackConnectionState() async throws {
        do {
            let user = try await fetchJetpackUser()
            jetpackConnectedEmail = user.wpcomUser?.email
        } catch AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)) {
            /// 404 error means Jetpack is not installed or activated yet.
            requiresConnectionOnly = false
            jetpackConnectedEmail = nil
            /// Early return because we know that Jetpack is not installed
            /// We don't have to check installation status by checking with the system plugin list.
            return
        } catch AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403)) {
            /// 403 means the site Jetpack connection is not established yet
            /// and the user has no permission to handle this.
            throw JetpackCheckError.missingPermission
        } catch {
            throw error
        }

        /// confirms Jetpack plugin status by checking with the system plugin list.
        /// this is to avoid the edge case when Jetpack user is returned even though Jetpack plugin is not installed.
        requiresConnectionOnly = try await isJetpackInstalledAndActive()
    }

    func startAuthentication(with email: String?) {
        if let email {
            Task { @MainActor in
                analytics.track(event: .JetpackSetup.loginFlow(step: .emailAddress))
                await emailLoginViewModel.checkWordPressComAccount(email: email)
            }
        } else {
            showWPComEmailLogin()
        }
    }

    func displayAdminRoleRequiredError() {
        let viewController = AdminRoleRequiredHostingController(siteID: site.siteID, onClose: { [weak self] in
            self?.rootViewController.dismiss(animated: true)
        }, onSuccess: { [weak self] in
            self?.rootViewController.dismiss(animated: true) {
                self?.showWPComEmailLogin()
            }
        })
        rootViewController.topmostPresentedViewController.present(UINavigationController(rootViewController: viewController), animated: true)
    }

    /// After magic link login, fetch username and Jetpack connection details.
    func startJetpackSetupFlow(authToken: String) {
        /// Dismiss any existing login flow if possible.
        if rootViewController.presentedViewController != nil {
            return rootViewController.dismiss(animated: true) {
                self.startJetpackSetupFlow(authToken: authToken)
            }
        }
        let progressView = InProgressViewController(viewProperties: .init(title: Localization.pleaseWait, message: ""))
        rootViewController.topmostPresentedViewController.present(progressView, animated: true)
        Task { @MainActor in
            guard let username = await loadWPComAccountUsername(authToken: authToken) else {
                return showAlert(message: Localization.errorFetchingWPComAccount, onRetry: { [weak self] in
                    self?.startJetpackSetupFlow(authToken: authToken)
                })
            }

            do {
                try await checkJetpackConnectionState()
                await progressView.dismiss(animated: true)
                showSetupSteps(username: username, authToken: authToken)
            } catch JetpackCheckError.missingPermission {
                await progressView.dismiss(animated: true)
                displayAdminRoleRequiredError()
            } catch {
                await progressView.dismiss(animated: true)
                DDLogError("⛔️ Jetpack status fetched error: \(error)")
                showAlert(message: Localization.errorCheckingJetpack)
            }
        }
    }

    func showSetupSteps(username: String, authToken: String) {
        analytics.track(.jetpackSetupLoginCompleted)

        /// WPCom credentials to authenticate the user in the Jetpack connection web view automatically
        let credentials: Credentials = .wpcom(username: username, authToken: authToken, siteAddress: site.url)
        guard jetpackConnectedEmail == nil else {
            // authenticate user immediately
            return authenticateUserAndRefreshSite(with: credentials)
        }
        let setupUI = JetpackSetupHostingController(siteURL: site.url,
                                                    connectionOnly: requiresConnectionOnly,
                                                    connectionWebViewCredentials: credentials,
                                                    onStoreNavigation: { [weak self] _ in
            DDLogInfo("🎉 Jetpack setup completes!")
            self?.rootViewController.topmostPresentedViewController.dismiss(animated: true, completion: {
                self?.authenticateUserAndRefreshSite(with: credentials)
            })
        })
        let navigationController = UINavigationController(rootViewController: setupUI)
        self.setupStepsNavigationController = navigationController
        if let loginNavigationController {
            loginNavigationController.dismiss(animated: true, completion: {
                self.rootViewController.topmostPresentedViewController.present(navigationController, animated: true)
            })
            self.loginNavigationController = nil
        } else {
            /// If user reaches this from the magic link flow, no loginNavigationController is available
            /// So present the Jetpack setup flow on the topmost presented controller.
            rootViewController.topmostPresentedViewController.present(navigationController, animated: true)
        }
    }

    func authenticateUserAndRefreshSite(with credentials: Credentials) {
        analytics.track(.jetpackSetupCompleted)
        stores.sessionManager.deleteApplicationPassword()
        stores.authenticate(credentials: credentials)
        let progressView = InProgressViewController(viewProperties: .init(title: Localization.syncingData, message: ""))
        rootViewController.topmostPresentedViewController.present(progressView, animated: true)

        let action = AccountAction.synchronizeSitesAndReturnSelectedSiteInfo(siteAddress: site.url) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let site):
                self.stores.updateDefaultStore(storeID: site.siteID)
                self.stores.synchronizeEntities { [weak self] in
                    self?.stores.updateDefaultStore(site)
                    self?.rootViewController.dismiss(animated: true, completion: {
                        self?.analytics.track(.jetpackSetupSynchronizationCompleted)
                        self?.registerForPushNotifications()
                        if site.isJetpackCPConnected {
                            self?.presentJCPJetpackInstallFlow()
                        }
                    })
                }

            case .failure(let error):
                DDLogError("⛔️ Error fetching sites after Jetpack setup: \(error)")
                progressView.dismiss(animated: true, completion: { [weak self] in
                    self?.showAlert(message: Localization.errorFetchingSites, onRetry: {
                        self?.authenticateUserAndRefreshSite(with: credentials)
                    })
                })

            }
        }
        stores.dispatch(action)
    }

    func registerForPushNotifications() {
        #if targetEnvironment(simulator)
            DDLogVerbose("👀 Push Notifications are not supported in the Simulator!")
        #else
            let pushNotesManager = ServiceLocator.pushNotesManager
            pushNotesManager.registerForRemoteNotifications()
            pushNotesManager.ensureAuthorizationIsRequested(includesProvisionalAuth: false, onCompletion: nil)
        #endif
    }
}

// MARK: - WPCom Login flow
//
private extension JetpackSetupCoordinator {

    @MainActor
    func loadWPComAccountUsername(authToken: String) async -> String? {
        await withCheckedContinuation { continuation in
            let network = AlamofireNetwork(credentials: Credentials(authToken: authToken))
            let accountAction = JetpackConnectionAction.loadWPComAccount(network: network) { account in
                continuation.resume(returning: account?.username)
            }
            stores.dispatch(accountAction)
        }
    }

    @MainActor
    func fetchJetpackUser() async throws -> JetpackUser {
        /// Jetpack setup will fail anyway without admin role, so check that first.
        let roles = stores.sessionManager.defaultRoles
        guard roles.contains(.administrator) else {
            throw JetpackCheckError.missingPermission
        }
        return try await withCheckedThrowingContinuation { continuation in
            let action = JetpackConnectionAction.fetchJetpackUser { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    @MainActor
    func isJetpackInstalledAndActive() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(SystemStatusAction.synchronizeSystemPlugins(siteID: 0) { result in
                switch result {
                case let .success(plugins):
                    if let plugin = plugins.first(where: { $0.name.lowercased() == Constants.jetpackPluginName.lowercased() }),
                       plugin.active {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                case let .failure(error):
                    DDLogError("⛔️ Failed to sync system plugins. Error: \(error)")
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    func showWPComEmailLogin() {
        analytics.track(event: .JetpackSetup.loginFlow(step: .emailAddress))
        let emailLoginController = WPComEmailLoginHostingController(viewModel: emailLoginViewModel)
        let loginNavigationController = LoginNavigationController(rootViewController: emailLoginController)
        rootViewController.dismiss(animated: true) {
            self.rootViewController.present(loginNavigationController, animated: true)
        }
        self.loginNavigationController = loginNavigationController
    }

    func showMagicLinkUI(email: String) {
        analytics.track(event: .JetpackSetup.loginFlow(step: .magicLink))
        let viewController = WPComMagicLinkHostingController(email: email,
                                                             title: loginViewTitle,
                                                             isJetpackSetup: true)
        loginNavigationController?.pushViewController(viewController, animated: true)
    }

    func showPasswordUI(email: String) {
        analytics.track(event: .JetpackSetup.loginFlow(step: .password))

        let viewModel = WPComPasswordLoginViewModel(
            siteURL: site.url,
            email: email,
            onMagicLinkRequest: { [weak self] email in
                guard let self else { return }
                await self.emailLoginViewModel.requestAuthenticationLink(email: email)
            },
            onMultifactorCodeRequest: { [weak self] loginFields in
                self?.show2FALoginUI(with: loginFields)
            },
            onLoginFailure: { [weak self] error in
                guard let self else { return }
                self.analytics.track(event: .JetpackSetup.loginFlow(step: .password, failure: error))
                let message = error.localizedDescription
                self.showAlert(message: message)
            },
            onLoginSuccess: { @MainActor [weak self] authToken in
                self?.showSetupSteps(username: email, authToken: authToken)
            })
        let viewController = WPComPasswordLoginHostingController(
            title: loginViewTitle,
            isJetpackSetup: true,
            viewModel: viewModel)

        if let loginNavigationController {
            loginNavigationController.pushViewController(viewController, animated: true)
        } else {
            /// If the user already is connected, the email screen is skipped.
            /// The login flow starts here, so create the navigation controller if needed.
            let loginNavigationController = LoginNavigationController(rootViewController: viewController)
            rootViewController.dismiss(animated: true) {
                self.rootViewController.present(loginNavigationController, animated: true)
            }
            self.loginNavigationController = loginNavigationController
        }
    }

    func show2FALoginUI(with loginFields: LoginFields) {
        analytics.track(event: .JetpackSetup.loginFlow(step: .verificationCode))
        guard let window = rootViewController.view.window else {
            logErrorAndExit("⛔️ Error finding window for security key login")
        }
        let viewModel = WPCom2FALoginViewModel(
            loginFields: loginFields,
            onAuthWindowRequest: { window },
            onLoginFailure: { [weak self] error in
                guard let self else { return }
                self.analytics.track(event: .JetpackSetup.loginFlow(step: .verificationCode, failure: error))
                self.showAlert(message: error.errorMessage)
            },
            onLoginSuccess: { @MainActor [weak self] authToken in
                self?.showSetupSteps(username: loginFields.username, authToken: authToken)
            })
        let viewController = WPCom2FALoginHostingController(title: loginViewTitle,
                                                            isJetpackSetup: true,
                                                            viewModel: viewModel)
        loginNavigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Error handling
//
private extension JetpackSetupCoordinator {
    /// Shows an error alert with a button to retry the failed action.
    ///
    func showAlert(message: String,
                   onRetry: (() -> Void)? = nil) {
        let alert = UIAlertController(title: message,
                                      message: nil,
                                      preferredStyle: .alert)
        if let onRetry {
            let retryAction = UIAlertAction(title: Localization.retryButton, style: .default) { _ in
                onRetry()
            }
            alert.addAction(retryAction)
        }
        let cancelAction = UIAlertAction(title: Localization.cancelButton, style: .cancel)
        alert.addAction(cancelAction)
        rootViewController.topmostPresentedViewController.present(alert, animated: true)
    }
}

// MARK: - Subtypes
private extension JetpackSetupCoordinator {
    enum JetpackCheckError: Int, Error {
        case missingPermission = 403
    }

    enum Constants {
        static let magicLinkUrlHostname = "magic-login"
        static let jetpackPluginName = "Jetpack"
    }

    enum Localization {
        static let retryButton = NSLocalizedString("Try Again", comment: "Button to retry a failed action in the Jetpack setup flow")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Button to dismiss an error alert in the Jetpack setup flow")
        static let errorCheckingJetpack = NSLocalizedString(
            "Error checking the Jetpack connection on your site",
            comment: "Message shown on the error alert displayed when checking Jetpack connection fails during the Jetpack setup flow."
        )
        static let pleaseWait = NSLocalizedString(
            "Please wait",
            comment: "Message on the loading view displayed when the magic link authentication for Jetpack setup is in progress"
        )
        static let syncingData = NSLocalizedString(
            "Syncing data",
            comment: "Message on the loading view displayed when the data is being synced after Jetpack setup completes"
        )
        static let errorFetchingWPComAccount = NSLocalizedString(
            "Unable to fetch the logged in WordPress.com account. Please try again.",
            comment: "Error message when failing to fetch the WPCom account after logging in with magic link.")
        static let errorFetchingSites = NSLocalizedString(
            "Unable to refresh current site info",
            comment: "Error message displayed when failing to fetch the current site info."
        )
        static let installJetpack = NSLocalizedString(
            "jetpackSetupCoordinator.loginTitle",
            value: "Install Jetpack",
            comment: "Title for the WPCom login screens when Jetpack is not installed yet"
        )
        static let connectJetpack = NSLocalizedString(
            "jetpackSetupCoordinator.loginSubtitle",
            value: "Connect Jetpack",
            comment: "Title for the WPCom login screens when Jetpack is not connected yet"
        )
    }
}
