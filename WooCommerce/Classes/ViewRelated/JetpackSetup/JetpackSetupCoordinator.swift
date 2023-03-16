import UIKit
import Yosemite
import enum Alamofire.AFError
import WordPressAuthenticator
import struct Networking.CookieNonceAuthenticatorConfiguration
import class Networking.WordPressOrgNetwork
import enum Yosemite.Credentials

/// Coordinates the Jetpack setup flow in the authenticated state.
///
final class JetpackSetupCoordinator {
    let rootViewController: UIViewController

    private let site: Site
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private var requiresConnectionOnly: Bool
    private let stores: StoresManager
    private let analytics: Analytics
    private let dotcomAuthScheme: String

    private var jetpackConnectedEmail: String?
    private var benefitsController: JetpackBenefitsHostingController?
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
        prepareCookieAuthenticationIfNeeded()
        let benefitsController = JetpackBenefitsHostingController(isJetpackCPSite: site.isJetpackCPConnected)
        benefitsController.setActions (installAction: { [weak self] result in
            guard let self else { return }
            self.analytics.track(event: .jetpackInstallButtonTapped(source: .benefitsModal))
            if self.site.isNonJetpackSite {
                self.checkJetpackStatus(result)
            } else {
                self.presentJCPJetpackInstallFlow()
            }
        }, dismissAction: { [weak self] in
            self?.rootViewController.dismiss(animated: true, completion: nil)
        })
        rootViewController.present(benefitsController, animated: true, completion: nil)
        self.benefitsController = benefitsController
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

    /// Checks the Jetpack connection status for non-Jetpack sites to infer the setup steps to be handled.
    func checkJetpackStatus(_ result: Result<JetpackUser, Error>, onSuccess: (() -> Void)? = nil) {
        switch result {
        case .success(let user):
            requiresConnectionOnly = !user.isConnected
            let connectedEmail = user.wpcomUser?.email
            jetpackConnectedEmail = connectedEmail
            if let onSuccess {
                onSuccess()
            } else {
                startAuthentication(with: connectedEmail)
            }

        case .failure(let error):
            DDLogError("⛔️ Jetpack status fetched error: \(error)")
            switch error {
            case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)):
                /// 404 error means Jetpack is not installed or activated yet.
                requiresConnectionOnly = false
                if let onSuccess {
                    onSuccess()
                } else {
                    checkAdminRoleAndStartLoginIfPossible()
                }
            case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403)):
                /// 403 means the site Jetpack connection is not established yet
                /// and the user has no permission to handle this.
                displayAdminRoleRequiredError()
                requiresConnectionOnly = true
            default:
                showAlert(message: Localization.errorCheckingJetpack)
            }
        }
    }

    func startAuthentication(with email: String?) {
        if let email {
            Task { @MainActor in
                await emailLoginViewModel.checkWordPressComAccount(email: email)
            }
        } else {
            showWPComEmailLogin()
        }
    }

    func checkAdminRoleAndStartLoginIfPossible() {
        let roles = stores.sessionManager.defaultRoles
        if roles.contains(.administrator) {
            showWPComEmailLogin()
        } else {
            displayAdminRoleRequiredError()
        }
    }

    func displayAdminRoleRequiredError() {
        let viewController = AdminRoleRequiredHostingController(siteID: site.siteID, onClose: { [weak self] in
            self?.rootViewController.dismiss(animated: true)
        }, onSuccess: { [weak self] in
            guard let self else { return }
            self.benefitsController?.dismiss(animated: true) {
                self.showWPComEmailLogin()
            }
        })
        benefitsController?.present(UINavigationController(rootViewController: viewController), animated: true)
    }

    func startJetpackSetupFlow(authToken: String) {
        /// Dismiss any existing login flow if possible.
        if rootViewController.topmostPresentedViewController is LoginNavigationController {
            return rootViewController.topmostPresentedViewController.dismiss(animated: true) {
                self.startJetpackSetupFlow(authToken: authToken)
            }
        }
        let progressView = InProgressViewController(viewProperties: .init(title: Localization.pleaseWait, message: ""))
        rootViewController.topmostPresentedViewController.present(progressView, animated: true)
        let action = JetpackConnectionAction.fetchJetpackUser { [weak self] result in
            guard let self else { return }
            progressView.dismiss(animated: true)
            self.checkJetpackStatus(result, onSuccess: { [weak self] in
                // TODO: find username based on token
                self?.showSetupSteps(username: nil, authToken: authToken)
            })
        }
        stores.dispatch(action)
    }

    func showSetupSteps(username: String?, authToken: String) {
        guard jetpackConnectedEmail == nil else {
            // TODO: authenticate user immediately
            return
        }
        let credentials: Credentials? = {
            guard let username else {
                return nil
            }
            return .wpcom(username: username, authToken: authToken, siteAddress: site.url)
        }()
        let setupUI = JetpackSetupHostingController(siteURL: site.url,
                                                    connectionOnly: requiresConnectionOnly,
                                                    connectionWebViewCredentials: credentials,
                                                    onStoreNavigation: { _ in
            // TODO-8921: Authenticate user with the logged in WPCom credentials
            DDLogInfo("🎉 Jetpack setup completes!")
        })
        let navigationController = UINavigationController(rootViewController: setupUI)
        self.setupStepsNavigationController = navigationController
        loginNavigationController?.dismiss(animated: true, completion: {
            self.rootViewController.topmostPresentedViewController.present(navigationController, animated: true)
        })
        loginNavigationController = nil
    }

    func prepareCookieAuthenticationIfNeeded() {
        guard let loginURL = URL(string: site.loginURL),
              let adminURL = URL(string: site.adminURL) else {
            DDLogWarn("⚠️ Cannot construct login URL and admin URL for site \(site.url)")
            return
        }
        if case let .wporg(username, password, _) = stores.sessionManager.defaultCredentials {
            // Prepares the authenticator with username and password
            let config = CookieNonceAuthenticatorConfiguration(username: username,
                                                               password: password,
                                                               loginURL: loginURL,
                                                               adminURL: adminURL)
            let network = WordPressOrgNetwork(configuration: config)
            let authenticationAction = JetpackConnectionAction.authenticate(siteURL: site.url, network: network)
            stores.dispatch(authenticationAction)
        } else {
            DDLogWarn("⚠️ Unsupported authentication state for cookie authentication")
        }
    }
}

// MARK: - WPCom Login flow
//
private extension JetpackSetupCoordinator {
    func showWPComEmailLogin() {
        let emailLoginController = WPComEmailLoginHostingController(viewModel: emailLoginViewModel)
        let loginNavigationController = LoginNavigationController(rootViewController: emailLoginController)
        rootViewController.dismiss(animated: true) {
            self.rootViewController.present(loginNavigationController, animated: true)
        }
        self.loginNavigationController = loginNavigationController
    }

    func showMagicLinkUI(email: String) {
        let viewController = WPComMagicLinkHostingController(email: email, requiresConnectionOnly: requiresConnectionOnly)
        loginNavigationController?.pushViewController(viewController, animated: true)
    }

    func showPasswordUI(email: String) {
        let viewModel = WPComPasswordLoginViewModel(
            siteURL: site.url,
            email: email,
            requiresConnectionOnly: requiresConnectionOnly,
            onMultifactorCodeRequest: { [weak self] loginFields in
                self?.show2FALoginUI(with: loginFields)
            },
            onLoginFailure: { [weak self] error in
                guard let self else { return }
                let message = error.localizedDescription
                self.showAlert(message: message)
            },
            onLoginSuccess: { [weak self] authToken in
                self?.showSetupSteps(username: email, authToken: authToken)
            })
        let viewController = WPComPasswordLoginHostingController(
            viewModel: viewModel,
            onMagicLinkRequest: { [weak self] email in
            guard let self else { return }
            await self.emailLoginViewModel.requestAuthenticationLink(email: email)
        })

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
        let viewModel = WPCom2FALoginViewModel(
            loginFields: loginFields,
            requiresConnectionOnly: requiresConnectionOnly,
            onLoginFailure: { [weak self] error in
                guard let self else { return }
                let message = error.localizedDescription
                self.showAlert(message: message)
            },
            onLoginSuccess: { [weak self] authToken in
                self?.showSetupSteps(username: loginFields.username, authToken: authToken)
            })
        let viewController = WPCom2FALoginHostingController(viewModel: viewModel)
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
    enum Constants {
        static let magicLinkUrlHostname = "magic-login"
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
    }
}
