import Yosemite
import protocol Networking.ApplicationPasswordUseCase
import enum Networking.ApplicationPasswordUseCaseError

/// Checks if the user is eligible to use the app after logging in with site credentials only.
/// The following checks are made:
/// - Application password availability
/// - Role eligibility
/// - Whether WooCommerce is installed and activated on the logged in site.
///
final class PostSiteCredentialLoginChecker {
    private let stores: StoresManager
    private let applicationPasswordUseCase: ApplicationPasswordUseCase
    private let roleEligibilityUseCase: RoleEligibilityUseCaseProtocol
    private let analytics: Analytics

    init(applicationPasswordUseCase: ApplicationPasswordUseCase,
         roleEligibilityUseCase: RoleEligibilityUseCaseProtocol = RoleEligibilityUseCase(stores: ServiceLocator.stores),
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.applicationPasswordUseCase = applicationPasswordUseCase
        self.roleEligibilityUseCase = roleEligibilityUseCase
        self.stores = stores
        self.analytics = analytics
    }

    /// Checks whether the user is eligible to use the app.
    ///
    func checkEligibility(for siteURL: String, from navigationController: UINavigationController, onSuccess: @escaping () -> Void) {
        checkApplicationPassword(for: siteURL,
                                 with: applicationPasswordUseCase,
                                 in: navigationController) { [weak self] in
            self?.checkRoleEligibility(in: navigationController) {
                self?.checkWooInstallation(for: siteURL, in: navigationController, onSuccess: onSuccess)
            }
        }
    }
}

private extension PostSiteCredentialLoginChecker {
    /// Checks if application password is enabled for the specified site.
    ///
    func checkApplicationPassword(for siteURL: String,
                                  with useCase: ApplicationPasswordUseCase,
                                  in navigationController: UINavigationController, onSuccess: @escaping () -> Void) {
        Task { @MainActor in
            do {
                let _ = try await useCase.generateNewPassword()
                onSuccess()
            } catch {
                analytics.track(event: .RESTAPILogin.loginSiteCredentialFailed(step: .applicationPasswordGeneration, error: error))
                switch error {
                case ApplicationPasswordUseCaseError.applicationPasswordsDisabled:
                    // show application password disabled error
                    let errorUI = applicationPasswordDisabledUI(for: siteURL)
                    navigationController.show(errorUI, sender: nil)
                case ApplicationPasswordUseCaseError.unauthorizedRequest:
                    showAlert(message: Localization.invalidLoginOrAdminURL, in: navigationController)
                default:
                    DDLogError("⛔️ Error generating application password: \(error)")
                    showAlert(
                        message: Localization.applicationPasswordError,
                        in: navigationController,
                        onRetry: { [weak self] in
                            self?.checkApplicationPassword(for: siteURL, with: useCase, in: navigationController, onSuccess: onSuccess)
                        }
                    )
                }
            }
        }
    }

    /// Checks role eligibility for the logged in user with the site address saved in the credentials.
    /// Placeholder store ID is used because we are checking for users logging in with site credentials.
    ///
    func checkRoleEligibility(in navigationController: UINavigationController, onSuccess: @escaping () -> Void) {
        roleEligibilityUseCase.checkEligibility(for: WooConstants.placeholderStoreID) { [weak self] result in
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                self?.analytics.track(event: .RESTAPILogin.loginSiteCredentialFailed(step: .userRole, error: error))
                if case let RoleEligibilityError.insufficientRole(errorInfo) = error {
                    self?.analytics.track(event: .LoginUserRole.loginWithInsufficientRole(currentRoles: errorInfo.roles))
                    self?.showRoleErrorScreen(for: WooConstants.placeholderStoreID,
                                             errorInfo: errorInfo,
                                             in: navigationController,
                                             onSuccess: onSuccess)
                } else {
                    // show generic error
                    DDLogError("⛔️ Error checking role eligibility: \(error)")
                    self?.showAlert(
                        message: Localization.roleEligibilityCheckError,
                        in: navigationController,
                        onRetry: { [weak self] in
                            self?.checkRoleEligibility(in: navigationController, onSuccess: onSuccess)
                        }
                    )
                }
            }
        }
    }

    /// Shows a Role Error page using the provided error information.
    ///
    func showRoleErrorScreen(for siteID: Int64,
                             errorInfo: StorageEligibilityErrorInfo,
                             in navigationController: UINavigationController,
                             onSuccess: @escaping () -> Void) {
        let errorViewModel = RoleErrorViewModel(siteID: siteID, title: errorInfo.name, subtitle: errorInfo.humanizedRoles, useCase: roleEligibilityUseCase)
        let errorViewController = RoleErrorViewController(viewModel: errorViewModel)

        errorViewModel.onSuccess = onSuccess
        errorViewModel.onDeauthenticationRequest = { [weak self] in
            self?.stores.deauthenticate()
            navigationController.popToRootViewController(animated: true)
        }
        navigationController.show(errorViewController, sender: self)
    }

    /// Checks if WooCommerce is active on the logged in site.
    ///
    func checkWooInstallation(for siteURL: String, in navigationController: UINavigationController,
                              onSuccess: @escaping () -> Void) {
        let action = WordPressSiteAction.fetchSiteInfo(siteURL: siteURL) { [weak self] result in
            switch result {
            case .success(let site):
                if site.isWooCommerceActive {
                    onSuccess()
                } else {
                    self?.analytics.track(event: .RESTAPILogin.loginSiteCredentialFailed(step: .wooStatus, error: nil))
                    self?.showAlert(message: Localization.noWooError, in: navigationController)
                }
            case .failure(let error):
                self?.analytics.track(event: .RESTAPILogin.loginSiteCredentialFailed(step: .wooStatus, error: error))
                DDLogError("⛔️ Error checking Woo: \(error)")
                // show generic error
                self?.showAlert(message: Localization.wooCheckError, in: navigationController, onRetry: {
                    self?.checkWooInstallation(for: siteURL, in: navigationController, onSuccess: onSuccess)
                })
            }
        }
        stores.dispatch(action)
    }

    /// Shows an error alert with a button to restart login and an optional button to retry the failed action.
    ///
    func showAlert(message: String,
                   in navigationController: UINavigationController,
                   onRetry: (() -> Void)? = nil) {
        let alert = UIAlertController(title: message,
                                      message: nil,
                                      preferredStyle: .alert)
        if let onRetry {
            let retryAction = UIAlertAction(title: Localization.retryButton, style: .default) { _ in
                onRetry()
            }
            alert.addAction(retryAction)
        } else {
            let supportAction = UIAlertAction(title: Localization.contactSupport, style: .default) { _ in
                navigationController.popViewController(animated: true)
                ServiceLocator.authenticationManager.presentSupport(from: navigationController, sourceTag: .loginSiteAddress)
            }
            alert.addAction(supportAction)
        }
        let restartAction = UIAlertAction(title: Localization.restartLoginButton, style: .cancel) { [weak self] _ in
            self?.stores.deauthenticate()
            navigationController.popToRootViewController(animated: true)
        }
        alert.addAction(restartAction)
        navigationController.present(alert, animated: true)
    }

    /// The error screen to be displayed when the user tries to log in with site credentials
    /// with application password disabled.
    ///
    func applicationPasswordDisabledUI(for siteURL: String) -> UIViewController {
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: siteURL)
        return ULErrorViewController(viewModel: viewModel)
    }
}

private extension PostSiteCredentialLoginChecker {
    enum Localization {
        static let applicationPasswordError = NSLocalizedString(
            "Error fetching application password for your site.",
            comment: "Error message displayed when application password cannot be fetched after authentication."
        )
        static let roleEligibilityCheckError = NSLocalizedString(
            "Error fetching user information.",
            comment: "Error message displayed when user information cannot be fetched after authentication."
        )
        static let noWooError = NSLocalizedString(
            "Please install and activate WooCommerce plugin on your site to use the app.",
            comment: "Message explaining that the site entered doesn't have WooCommerce installed or activated."
        )
        static let wooCheckError = NSLocalizedString(
            "Error checking for the WooCommerce plugin.",
            comment: "Error message displayed when the WooCommerce plugin detail cannot be fetched after authentication"
        )
        static let invalidLoginOrAdminURL = NSLocalizedString(
            "Application password cannot be generated due to a custom login or admin URL on your site.",
            comment: "Message to display when the constructed admin or login URL for the logged-in site is not accessible"
        )
        static let contactSupport = NSLocalizedString("Contact Support", comment: "Button to contact support for login")
        static let retryButton = NSLocalizedString("Try Again", comment: "Button to refetch application password for the current site")
        static let restartLoginButton = NSLocalizedString("Log In With Another Account", comment: "Button to restart the login flow.")
    }
}
