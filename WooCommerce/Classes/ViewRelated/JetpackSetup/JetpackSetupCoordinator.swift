import UIKit
import Yosemite
import enum Alamofire.AFError
import WordPressAuthenticator

/// Coordinates the Jetpack setup flow in the authenticated state.
///
final class JetpackSetupCoordinator {
    let rootViewController: UIViewController

    private let site: Site
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private var requiresConnectionOnly: Bool
    private let stores: StoresManager
    private let analytics: Analytics
    private let accountService: WordPressComAccountService

    private var benefitsController: JetpackBenefitsHostingController?
    private var loginNavigationController: LoginNavigationController?

    init(site: Site,
         rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.site = site
        self.requiresConnectionOnly = false // to be updated later after fetching Jetpack status
        self.rootViewController = rootViewController
        self.stores = stores
        self.analytics = analytics

        /// the authenticator needs to be initialized with configs
        /// to be used for requesting authentication link and handle login later.
        WordPressAuthenticator.initializeWithCustomConfigs()
        self.accountService = WordPressComAccountService()
    }

    func showBenefitModal() {
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
        guard WordPressAuthenticator.shared.isWordPressAuthUrl(url) else {
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
    func checkJetpackStatus(_ result: Result<JetpackUser, Error>, skipsWPComLogin: Bool = false) {
        switch result {
        case .success(let user):
            requiresConnectionOnly = !user.isConnected
            if !skipsWPComLogin {
                let connectedEmail = user.wpcomUser?.email
                startAuthentication(with: connectedEmail)
            }

        case .failure(let error):
            DDLogError("⛔️ Jetpack status fetched error: \(error)")
            switch error {
            case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)):
                /// 404 error means Jetpack is not installed or activated yet.
                requiresConnectionOnly = false
                if !skipsWPComLogin {
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
                await checkWordPressComAccount(email: email)
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
            self.checkJetpackStatus(result, skipsWPComLogin: true)
            #warning("TODO: sync account with token and start Jetpack setup")
            DDLogInfo("✅ Ready for Jetpack setup - connection only: \(self.requiresConnectionOnly)")
        }
        stores.dispatch(action)
    }
}

// MARK: - WPCom Login flow
//
private extension JetpackSetupCoordinator {
    func showWPComEmailLogin() {
        let emailLoginController = WPComEmailLoginHostingController(siteURL: site.url,
                                                                    requiresConnectionOnly: requiresConnectionOnly,
                                                                    onSubmit: checkWordPressComAccount(email:))
        let loginNavigationController = LoginNavigationController(rootViewController: emailLoginController)
        rootViewController.dismiss(animated: true) {
            self.rootViewController.present(loginNavigationController, animated: true)
        }
        self.loginNavigationController = loginNavigationController
    }

    func checkWordPressComAccount(email: String) async {
        await withCheckedContinuation { continuation -> Void in
            accountService.isPasswordlessAccount(username: email, success: { [weak self] passwordless in
                self?.startAuthentication(email: email, isPasswordlessAccount: passwordless) {
                    continuation.resume()
                }
            }, failure: { [weak self] error in
                DDLogError("⛔️ Error checking for passwordless account: \(error)")
                continuation.resume()
                self?.handleAccountCheckError(error)
            })
        }
    }

    func startAuthentication(email: String, isPasswordlessAccount: Bool, onCompletion: @escaping () -> Void) {
        if isPasswordlessAccount {
            Task { @MainActor in
                do {
                    try await requestAuthenticationLink(email: email)
                    onCompletion()
                    #warning("TODO: show magic login UI")
                } catch {
                    onCompletion()
                    showAlert(message: Localization.errorRequestingAuthURL)
                }
            }
        } else {
            #warning("TODO: show password UI")
            onCompletion()
        }
    }

    func requestAuthenticationLink(email: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            accountService.requestAuthenticationLink(for: email, jetpackLogin: false, success: {
                continuation.resume()
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }
}

// MARK: - Error handling
//
private extension JetpackSetupCoordinator {
    func handleAccountCheckError(_ error: Error) {
        let userInfo = (error as NSError).userInfo
        let errorCode = userInfo[Constants.wpcomErrorCodeKey] as? String

        if errorCode == Constants.emailLoginNotAllowedCode {
            // If we get this error, we know we have a WordPress.com user but their
            // email address is flagged as suspicious.  They need to login via their
            // username instead.
            #warning("TODO: handle username login")
        } else {
            showAlert(message: Localization.errorCheckingWPComAccount)
        }
    }

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
        static let wpcomErrorCodeKey = "WordPressComRestApiErrorCodeKey"
        static let emailLoginNotAllowedCode = "email_login_not_allowed"
    }

    enum Localization {
        static let retryButton = NSLocalizedString("Try Again", comment: "Button to retry a failed action in the Jetpack setup flow")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Button to dismiss an error alert in the Jetpack setup flow")
        static let errorCheckingJetpack = NSLocalizedString(
            "Error checking the Jetpack connection on your site",
            comment: "Message shown on the error alert displayed when checking Jetpack connection fails during the Jetpack setup flow."
        )
        static let errorCheckingWPComAccount = NSLocalizedString(
            "Error checking the WordPress.com account associated with this email. Please try again.",
            comment: "Message shown on the error alert displayed when checking Jetpack connection fails during the Jetpack setup flow."
        )
        static let errorRequestingAuthURL = NSLocalizedString(
            "Error requesting authentication link for your account. Please try again.",
            comment: "Message shown on the error alert displayed when requesting authentication link for the Jetpack setup flow fails"
        )
        static let pleaseWait = NSLocalizedString(
            "Please wait",
            comment: "Message on the loading view displayed when the magic link authentication for Jetpack setup is in progress"
        )
    }
}
