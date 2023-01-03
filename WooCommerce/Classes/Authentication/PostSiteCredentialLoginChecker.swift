import WordPressAuthenticator
import WordPressKit
import Yosemite
import protocol Networking.ApplicationPasswordUseCase
import class Networking.DefaultApplicationPasswordUseCase
import enum Networking.ApplicationPasswordUseCaseError
import enum Alamofire.AFError

/// Checks if the user is eligible to use the app after logging in with site credentials only.
/// The following checks are made:
/// - Application password availability
/// - Role eligibility
/// - Whether WooCommerce is installed and activated on the logged in site.
///
final class PostSiteCredentialLoginChecker {
    private let siteURL: String
    private let siteCredentials: WordPressOrgCredentials
    private let stores: StoresManager

    /// Keep strong reference of the use case to check for application password availability if necessary.
    private var applicationPasswordUseCase: ApplicationPasswordUseCase?

    /// Keep strong reference of the use case to check for role eligibility if necessary.
    private lazy var roleEligibilityUseCase: RoleEligibilityUseCase = .init(stores: stores)

    init(siteURL: String,
         siteCredentials: WordPressOrgCredentials,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.siteCredentials = siteCredentials
        self.stores = stores
    }

    /// Checks whether the user is eligible to use the app.
    ///
    func checkEligibility(from navigationController: UINavigationController, onSuccess: @escaping () -> Void) {
        // check if application password is enabled
        guard let applicationPasswordUseCase = try? DefaultApplicationPasswordUseCase(
            username: siteCredentials.username,
            password: siteCredentials.password,
            siteAddress: siteCredentials.siteURL
        ) else {
            return assertionFailure("⛔️ Error creating application password use case")
        }
        self.applicationPasswordUseCase = applicationPasswordUseCase
        checkApplicationPassword(for: siteURL,
                                 with: applicationPasswordUseCase,
                                 in: navigationController) { [weak self] in
            guard let self else { return }
            self.checkRoleEligibility(in: navigationController) { [weak self] in
                guard let self else { return }
                self.checkWooInstallation(in: navigationController, onSuccess: onSuccess)
            }
        }
    }
}

private extension PostSiteCredentialLoginChecker {
    func checkApplicationPassword(for siteURL: String,
                                  with useCase: ApplicationPasswordUseCase,
                                  in navigationController: UINavigationController, onSuccess: @escaping () -> Void) {
        Task {
            do {
                let _ = try await useCase.generateNewPassword()
                await MainActor.run {
                    onSuccess()
                }
            } catch ApplicationPasswordUseCaseError.applicationPasswordsDisabled {
                // show application password disabled error
                await MainActor.run {
                    let errorUI = applicationPasswordDisabledUI(for: siteURL)
                    navigationController.show(errorUI, sender: nil)
                }
            } catch {
                // show generic error
                await MainActor.run {
                    DDLogError("⛔️ Error generating application password: \(error)")
                    self.showAlert(
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
            guard let self else { return }
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                if case let RoleEligibilityError.insufficientRole(errorInfo) = error {
                    self.showRoleErrorScreen(for: WooConstants.placeholderStoreID,
                                             errorInfo: errorInfo,
                                             in: navigationController,
                                             onSuccess: onSuccess)
                } else {
                    // show generic error
                    DDLogError("⛔️ Error checking role eligibility: \(error)")
                    self.showAlert(
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
        let errorViewModel = RoleErrorViewModel(siteID: siteID, title: errorInfo.name, subtitle: errorInfo.humanizedRoles, useCase: self.roleEligibilityUseCase)
        let errorViewController = RoleErrorViewController(viewModel: errorViewModel)

        errorViewModel.onSuccess = onSuccess
        errorViewModel.onDeauthenticationRequest = { [weak self] in
            self?.stores.deauthenticate()
            navigationController.popToRootViewController(animated: true)
        }
        navigationController.show(errorViewController, sender: self)
    }

    func checkWooInstallation(in navigationController: UINavigationController,
                              onSuccess: @escaping () -> Void) {
        let action = SettingAction.checkIfWooCommerceIsActive(siteID: WooConstants.placeholderStoreID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                DDLogError("⛔️ Error checking Woo: \(error)")
                if case .responseValidationFailed(reason: .unacceptableStatusCode(code: 404)) = error as? AFError {
                    // if status code is 404, Woo is not active
                    self.showAlert(message: Localization.noWooError, in: navigationController)
                } else {
                    // otherwise, show generic error
                    self.showAlert(message: Localization.wooCheckError, in: navigationController, onRetry: { [weak self] in
                        self?.checkWooInstallation(in: navigationController, onSuccess: onSuccess)
                    })
                }
            }
        }
        stores.dispatch(action)
    }

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
            "It looks like this is not a WooCommerce site.",
            comment: "Message explaining that the site entered doesn't have WooCommerce installed or activated."
        )
        static let wooCheckError = NSLocalizedString(
            "Error checking for the WooCommerce plugin.",
            comment: "Error message displayed when the WooCommerce plugin detail cannot be fetched after authentication"
        )
        static let retryButton = NSLocalizedString("Try Again", comment: "Button to refetch application password for the current site")
        static let restartLoginButton = NSLocalizedString("Log In With Another Account", comment: "Button to restart the login flow.")
    }
}
