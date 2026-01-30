import UIKit
import enum Yosemite.Credentials
import protocol Yosemite.StoresManager
import WordPressAuthenticator
import WooFoundation

enum WPComLoginFlow {
    case notificationSetup
    case jetpackSetup(requiresConnectionOnly: Bool)

    var pendingAuthFlow: PendingAuthFlow {
        switch self {
        case .notificationSetup: .notificationSetup
        case .jetpackSetup: .jetpackSetup
        }
    }
}

/// Coordinates navigation for the login flow with WPCom accounts.
final class WPComLoginCoordinator {
    let navigationController: UINavigationController

    /// Title to display on top of the login views
    private let title: String

    private let flow: WPComLoginFlow
    private let stores: StoresManager
    private let accountService: WordPressComAccountServiceProtocol
    private let completionHandler: (Credentials) -> Void

    private lazy var emailLoginViewModel: WPComEmailLoginViewModel = {
        .init(siteURL: stores.sessionManager.defaultSite?.url ?? "",
              flow: flow,
              allowAccountCreation: true,
              accountService: accountService,
              onPasswordUIRequest: showPasswordUIForLogin(email:),
              onMagicLinkRequest: showMagicLinkRequestUI,
              onMagicLinkSent: { [weak self] email, _ in self?.showMagicLinkSentUI(email: email) },
              onError: { [weak self] message in
            self?.showAlert(message: message)
        })
    }()

    init(title: String = Localization.login,
         flow: WPComLoginFlow,
         navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         accountService: WordPressComAccountServiceProtocol = WordPressComAccountService(),
         completionHandler: @escaping (Credentials) -> Void) {
        self.title = title
        self.flow = flow
        self.navigationController = navigationController
        self.stores = stores
        self.accountService = accountService
        self.completionHandler = completionHandler
    }

    func startWithoutEmail() {
        emailLoginViewModel.usernameOnly = false
        let emailLoginController = WPComEmailLoginHostingController(viewModel: emailLoginViewModel)
        navigationController.show(emailLoginController, sender: self)
    }

    @MainActor
    func start(with email: String) async {
        do {
            let passwordless = try await checkPasswordlessAccount(email: email)
            await startAuthentication(email: email, isPasswordlessAccount: passwordless)
        } catch {
            showAlert(message: error.localizedDescription)
        }
    }
}

// MARK: - Login steps
private extension WPComLoginCoordinator {
    @MainActor
    func startAuthentication(email: String, isPasswordlessAccount: Bool) async {
        if isPasswordlessAccount {
            await handleMagicLink(email: email)
        } else {
            showPasswordUIForLogin(email: email)
        }
    }

    @MainActor
    func handleMagicLink(email: String) async {
        do {
            try await requestAuthenticationLink(email: email)
            showMagicLinkSentUI(email: email)
        } catch {
            showAlert(message: error.localizedDescription)
        }
    }

    func showPasswordUIForLogin(email: String) {
        let viewModel = WPComPasswordLoginViewModel(
            email: email,
            onMagicLinkRequest: { [weak self] email in
                await self?.handleMagicLink(email: email)
            },
            onMultifactorCodeRequest: { [weak self] loginFields in
                self?.show2FALoginUI(with: loginFields)
            },
            onLoginFailure: { [weak self] error in
                guard let self else { return }
                let message = error.localizedDescription
                self.showAlert(message: message)
            },
            onLoginSuccess: { [weak self] authToken in
                self?.completeLogin(username: email, authToken: authToken)
            })
        let viewController = WPComPasswordLoginHostingController(
            title: title,
            flow: flow,
            viewModel: viewModel)
        navigationController.show(viewController, sender: self)
    }

    func show2FALoginUI(with loginFields: LoginFields) {
        guard let window = navigationController.view.window else {
            logErrorAndExit("⛔️ Error finding window for security key login")
        }
        let viewModel = WPCom2FALoginViewModel(
            loginFields: loginFields,
            onAuthWindowRequest: { window },
            onLoginFailure: { [weak self] error in
                guard let self else { return }
                // TODO: Analytics
                self.showAlert(message: error.errorMessage)
            },
            onLoginSuccess: { [weak self] authToken in
                self?.completeLogin(username: loginFields.username, authToken: authToken)
            })
        let viewController = WPCom2FALoginHostingController(title: title,
                                                            flow: flow,
                                                            viewModel: viewModel)
        navigationController.show(viewController, sender: self)
    }

    func showMagicLinkRequestUI(email: String) {
        let magicLinkRequestController = WPComMagicLinkRequestHostingController(
            title: title,
            flow: flow,
            viewModel: .init(email: email,
                             onMagicLinkSent: { [weak self] email in
                                 self?.showMagicLinkSentUI(email: email)
                             },
                             onUseUsernamePassword: showWPComUsernameLogin,
                             onError: { [weak self] message in
                                 self?.showAlert(message: message)
                             })
        )
        navigationController.show(magicLinkRequestController, sender: self)
    }

    /// Shows the UI saying magic link has been sent to the email address,
    /// asking the user to check their inbox to log in.
    /// We will be waiting for authentication request from the magic link in `AppDelegate` method for opening URL for deeplink.
    /// We're letting WPAuthenticator handle the deeplink for now.
    ///
    func showMagicLinkSentUI(email: String) {
        let storage = PendingAuthFlowStorage()
        storage.updateCurrentFlow(flow.pendingAuthFlow)
        let viewController = WPComMagicLinkHostingController(email: email,
                                                             title: title,
                                                             flow: flow,
                                                             isSignup: false)
        navigationController.show(viewController, sender: self)
    }

    func showWPComUsernameLogin() {
        emailLoginViewModel.usernameOnly = true
        emailLoginViewModel.emailOrUsername = ""

        let emailViewController = navigationController.viewControllers.first(where: { $0 is WPComEmailLoginHostingController })
        if let emailViewController {
            navigationController.popToViewController(emailViewController, animated: true)
        } else {
            navigationController.dismiss(animated: true) {
                self.navigationController.show(WPComEmailLoginHostingController(viewModel: self.emailLoginViewModel), sender: nil)
            }
        }
    }

    func completeLogin(username: String, authToken: String) {
        let credentials = Credentials(username: username, authToken: authToken)
        completionHandler(credentials)
    }
}

// MARK: - Private helpers
private extension WPComLoginCoordinator {
    @MainActor
    func checkPasswordlessAccount(email: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            accountService.isPasswordlessAccount(username: email, success: { passwordless in
                continuation.resume(returning: passwordless)
            }, failure: { error in
                DDLogError("⛔️ Error checking for passwordless account: \(error)")
                continuation.resume(throwing: error)
            })
        }
    }

    @MainActor
    func requestAuthenticationLink(email: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            accountService.requestAuthenticationLink(for: email,
                                                     jetpackLogin: false,
                                                     createAccountIfNotFound: false,
                                                     success: {
                continuation.resume()
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: message,
                                      message: nil,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: Localization.cancelButton, style: .cancel)
        alert.addAction(cancelAction)
        navigationController.topmostPresentedViewController.present(alert, animated: true)
    }
}

private extension WPComLoginCoordinator {
    enum Localization {
        static let login = NSLocalizedString(
            "wpComLoginCoordinator.title",
            value: "Log In",
            comment: "Title for the screens in the login flow"
        )
        static let cancelButton = NSLocalizedString(
            "wpComLoginCoordinator.cancelButton",
            value: "Cancel",
            comment: "Button to dismiss an error alert in the WPCom login flow"
        )
    }
}
