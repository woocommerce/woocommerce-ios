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
    private var loginNavigationController: UINavigationController?

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
    func checkJetpackStatus(_ result: Result<JetpackUser, Error>) {
        switch result {
        case .success(let user):
            let connectedEmail = user.wpcomUser?.email
            requiresConnectionOnly = !user.isConnected
            if let connectedEmail {
                Task { @MainActor in
                    await checkWordPressComAccount(email: connectedEmail)
                }
            } else {
                showWPComEmailLogin()
            }
        case .failure(let error):
            DDLogError("⛔️ Jetpack status fetched error: \(error)")
            switch error {
            case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)):
                /// 404 error means Jetpack is not installed or activated yet.
                requiresConnectionOnly = false
                let roles = stores.sessionManager.defaultRoles
                if roles.contains(.administrator) {
                    showWPComEmailLogin()
                } else {
                    displayAdminRoleRequiredError()
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
}

// MARK: - WPCom Login flow
//
private extension JetpackSetupCoordinator {
    func showWPComEmailLogin() {
        let emailLoginController = WPComEmailLoginHostingController(siteURL: site.url,
                                                                    requiresConnectionOnly: requiresConnectionOnly,
                                                                    onSubmit: checkWordPressComAccount(email:))
        let loginNavigationController = UINavigationController(rootViewController: emailLoginController)
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
    }
}
