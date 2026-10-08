import UIKit
import Yosemite
import protocol Networking.ApplicationPasswordUseCase
import protocol WooFoundation.Analytics
import enum Networking.ApplicationPasswordUseCaseError

struct SiteCredentialAuthenticationEndpointPersistence {
    enum Behavior {
        case persist
        case removeVerifiedStandard
    }

    let credentials: Credentials
    let endpoints: CookieNonceAuthenticationEndpoints
    let behavior: Behavior

    init?(credentials: Credentials, endpoints: CookieNonceAuthenticationEndpoints) {
        guard case let .wporg(_, _, siteURL) = credentials,
              let siteURL = URL(string: siteURL),
              let standardEndpoints = try? CookieNonceAuthenticationEndpoints(siteURL: siteURL),
              standardEndpoints.siteURL == endpoints.siteURL else {
            return nil
        }
        self.credentials = credentials
        self.endpoints = endpoints
        self.behavior = endpoints == standardEndpoints ? .removeVerifiedStandard : .persist
    }
}

/// Checks if the user is eligible to use the app after logging in with site credentials only.
/// The following checks are made:
/// - Application password availability
/// - Role eligibility
/// - Whether WooCommerce is installed and activated on the logged in site.
///
final class PostSiteCredentialLoginChecker {
    typealias AuthenticationEndpointPersistenceAction = (SiteCredentialAuthenticationEndpointPersistence) -> Void

    private let loginFlow: LoginUnexpectedResponseFailure.LoginFlow
    private let stores: StoresManager
    private let applicationPasswordUseCase: ApplicationPasswordUseCase
    private let roleEligibilityUseCase: RoleEligibilityUseCaseProtocol
    private let analytics: Analytics
    private let previousViewController: UIViewController?
    private let authenticationEndpointPersistence: SiteCredentialAuthenticationEndpointPersistence?
    private let authenticationEndpointPersistenceAction: AuthenticationEndpointPersistenceAction
    private var checkID: UUID?
    private var generationTask: Task<Void, Never>?
    @MainActor private(set) lazy var unexpectedResponsePresenter = LoginUnexpectedResponsePresenter(analytics: analytics)

    init(applicationPasswordUseCase: ApplicationPasswordUseCase,
         loginFlow: LoginUnexpectedResponseFailure.LoginFlow = .siteCredentials,
         roleEligibilityUseCase: RoleEligibilityUseCaseProtocol? = nil,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         authenticationEndpointPersistence: SiteCredentialAuthenticationEndpointPersistence? = nil,
         authenticationEndpointPersistenceAction: AuthenticationEndpointPersistenceAction? = nil,
         previousViewController: UIViewController?) {
        self.applicationPasswordUseCase = applicationPasswordUseCase
        self.loginFlow = loginFlow
        self.roleEligibilityUseCase = roleEligibilityUseCase ?? RoleEligibilityUseCase(stores: stores, detectUnexpectedResponses: true)
        self.stores = stores
        self.analytics = analytics
        self.authenticationEndpointPersistence = authenticationEndpointPersistence
        self.authenticationEndpointPersistenceAction = authenticationEndpointPersistenceAction ?? { persistence in
            switch persistence.behavior {
            case .persist:
                stores.sessionManager.saveCookieNonceAuthenticationEndpoints(persistence.endpoints, for: persistence.credentials)
            case .removeVerifiedStandard:
                stores.sessionManager.removeCookieNonceAuthenticationEndpoints(for: persistence.credentials)
            }
        }
        self.previousViewController = previousViewController
    }

    /// Checks whether the user is eligible to use the app.
    ///
    func checkEligibility(for siteURL: String, from navigationController: UINavigationController, onSuccess: @escaping () -> Void) {
        cancel()
        checkID = UUID()
        checkApplicationPassword(for: siteURL,
                                 with: applicationPasswordUseCase,
                                 in: navigationController) { [weak self] in
            guard let self else { return }
            self.persistAuthenticationEndpointsIfNeeded()
            self.checkRoleEligibility(for: siteURL, in: navigationController) { [weak self] in
                self?.checkWooInstallation(for: siteURL, in: navigationController, onSuccess: onSuccess)
            }
        }
    }

    func cancel() {
        checkID = nil
        generationTask?.cancel()
        MainActor.assumeIsolated { unexpectedResponsePresenter.invalidate() }
    }
}

private extension PostSiteCredentialLoginChecker {
    func persistAuthenticationEndpointsIfNeeded() {
        guard let authenticationEndpointPersistence else {
            return
        }

        authenticationEndpointPersistenceAction(authenticationEndpointPersistence)
    }

    /// Checks if application password is enabled for the specified site.
    ///
    func checkApplicationPassword(for siteURL: String,
                                  with useCase: ApplicationPasswordUseCase,
                                  in navigationController: UINavigationController,
                                  onRetryResult: ((Bool) -> Void)? = nil, onSuccess: @escaping () -> Void) {
        guard let id = checkID else { return }
        guard useCase.applicationPassword == nil else {
            onRetryResult?(true)
            return onSuccess()
        }
        generationTask = Task { @MainActor in
            guard checkID == id else { return }
            do {
                let _ = try await useCase.generateNewPassword()
                guard checkID == id, !Task.isCancelled else { return }
                onRetryResult?(true)
                analytics.track(event: .ApplicationPassword.applicationPasswordGeneratedSuccessfully(scenario: .generation))
                onSuccess()
            } catch {
                guard checkID == id, !Task.isCancelled else { return }
                onRetryResult?(false)
                analytics.track(event: .ApplicationPassword.applicationPasswordGenerationFailed(scenario: .generation, error: error))
                switch error {
                case ApplicationPasswordUseCaseError.applicationPasswordsDisabled:
                    // show application password disabled error, and use the previous view controller.
                    let errorUI = applicationPasswordDisabledUI(for: siteURL, previousViewController: previousViewController)
                    navigationController.show(errorUI, sender: nil)
                case ApplicationPasswordUseCaseError.unauthorizedRequest:
                    showAlert(message: Localization.unauthorizedForAppPassword, siteURL: siteURL, in: navigationController)
                default:
                    DDLogError("⛔️ Error generating application password: \(error)")
                    showAlert(
                        message: Localization.applicationPasswordError,
                        failure: LoginUnexpectedResponseFailure(error: error, step: .appPasswordGeneration),
                        siteURL: siteURL,
                        in: navigationController,
                        onRetry: { [weak self] result in
                            self?.checkApplicationPassword(for: siteURL, with: useCase, in: navigationController,
                                                           onRetryResult: result, onSuccess: onSuccess)
                        }
                    )
                }
            }
        }
    }

    /// Checks role eligibility for the logged in user with the site address saved in the credentials.
    /// Placeholder store ID is used because we are checking for users logging in with site credentials.
    ///
    func checkRoleEligibility(for siteURL: String, in navigationController: UINavigationController,
                              onRetryResult: ((Bool) -> Void)? = nil, onSuccess: @escaping () -> Void) {
        guard let id = checkID else { return }
        roleEligibilityUseCase.checkEligibility(for: WooConstants.placeholderStoreID) { [weak self] result in
            guard let self, checkID == id else { return }
            switch result {
            case .success:
                onRetryResult?(true)
                onSuccess()
            case .failure(let error):
                onRetryResult?(false)
                self.analytics.track(event: .Login.siteCredentialFailed(step: .userRole, error: error))
                if case let RoleEligibilityError.insufficientRole(errorInfo) = error {
                    self.analytics.track(event: .Login.insufficientRole(currentRoles: errorInfo.roles))
                    self.showRoleErrorScreen(for: WooConstants.placeholderStoreID,
                                             errorInfo: errorInfo,
                                             in: navigationController,
                                             onSuccess: onSuccess)
                } else {
                    // show generic error
                    DDLogError("⛔️ Error checking role eligibility: \(error)")
                    self.showAlert(
                        message: Localization.roleEligibilityCheckError,
                        failure: LoginUnexpectedResponseFailure(error: error, step: .userRoleCheck),
                        siteURL: siteURL,
                        in: navigationController,
                        onRetry: { [weak self] result in
                            self?.checkRoleEligibility(for: siteURL, in: navigationController, onRetryResult: result, onSuccess: onSuccess)
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
                              onRetryResult: ((Bool) -> Void)? = nil, onSuccess: @escaping () -> Void) {
        guard let id = checkID else { return }
        let action = WordPressSiteAction.fetchSiteInfo(siteURL: siteURL, detectUnexpectedResponses: true) { [weak self] result in
            guard let self, checkID == id else { return }
            switch result {
            case .success(let site):
                onRetryResult?(true)
                if site.isWooCommerceActive {
                    onSuccess()
                } else {
                    self.analytics.track(event: .Login.siteCredentialFailed(step: .wooStatus, error: nil))
                    self.showAlert(message: Localization.noWooError, siteURL: siteURL, in: navigationController)
                }
            case .failure(let error):
                onRetryResult?(false)
                self.analytics.track(event: .Login.siteCredentialFailed(step: .wooStatus, error: error))
                DDLogError("⛔️ Error checking Woo: \(error)")
                // show generic error
                self.showAlert(message: Localization.wooCheckError,
                                failure: LoginUnexpectedResponseFailure(error: error, step: .wooPluginCheck),
                                siteURL: siteURL, in: navigationController, onRetry: { [weak self] result in
                    self?.checkWooInstallation(for: siteURL, in: navigationController, onRetryResult: result, onSuccess: onSuccess)
                })
            }
        }
        stores.dispatch(action)
    }

    /// Shows an error alert with a button to restart login and an optional button to retry the failed action.
    ///
    func showAlert(message: String,
                   failure: LoginUnexpectedResponseFailure? = nil,
                   siteURL: String,
                   in navigationController: UINavigationController,
                   onRetry: LoginUnexpectedResponsePresenter.Retry? = nil) {
        // Generation runs in Task { @MainActor }; Remote delivers role/site callbacks on DispatchQueue.main.
        // Retry actions run through UIKit on the main actor and re-enter these same paths.
        MainActor.assumeIsolated {
            if let failure, let onRetry {
                unexpectedResponsePresenter.present(failure: failure, flow: loginFlow, from: navigationController, onRetry: onRetry,
                                                    onDismiss: { [weak self] in
                    self?.cancel()
                    self?.stores.deauthenticate()
                    if let previous = self?.previousViewController, navigationController.viewControllers.contains(previous) {
                        navigationController.popToViewController(previous, animated: false)
                    }
                })
                return
            }
            let alert = UIAlertController(title: message,
                                          message: nil,
                                          preferredStyle: .alert)
            if let onRetry {
                let retry = { onRetry { _ in } }
                let retryAction = UIAlertAction(title: Localization.retryButton, style: .default) { [weak alert] _ in
                    guard let alert, alert.presentingViewController != nil else {
                        return retry()
                    }
                    alert.dismiss(animated: true, completion: retry)
                }
                alert.addAction(retryAction)
            } else {
                let supportAction = UIAlertAction(title: Localization.contactSupport, style: .default) { _ in
                    navigationController.popViewController(animated: true)
                    ServiceLocator.authenticationManager.presentSupport(from: navigationController, sourceTag: .loginSiteAddress, siteURL: URL(string: siteURL))
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
    }

    /// The error screen to be displayed when the user tries to log in with site credentials
    /// with application password disabled.
    ///
    func applicationPasswordDisabledUI(for siteURL: String, previousViewController: UIViewController?) -> UIViewController {
        let viewModel = ApplicationPasswordDisabledViewModel(siteURL: siteURL, previousViewController: previousViewController)
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
        static let unauthorizedForAppPassword = NSLocalizedString(
            "The request to generate application password is not authorized.",
            comment: "Message to display when the generating application password fails with unauthorized error"
        )
        static let contactSupport = NSLocalizedString("Contact Support", comment: "Button to contact support for login")
        static let retryButton = NSLocalizedString("Try Again", comment: "Button to refetch application password for the current site")
        static let restartLoginButton = NSLocalizedString("Log In With Another Account", comment: "Button to restart the login flow.")
    }
}
