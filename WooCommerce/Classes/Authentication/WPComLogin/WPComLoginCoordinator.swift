import UIKit
import enum Yosemite.Credentials
import protocol Yosemite.StoresManager
import WordPressAuthenticator
import WooFoundation

enum WPComLoginFlow {
    case jetpackSetup(requiresConnectionOnly: Bool)
    case posPINRecovery

    var pendingAuthFlow: PendingAuthFlow? {
        switch self {
        case .jetpackSetup: .jetpackSetup
        case .posPINRecovery: nil
        }
    }
}

/// Coordinates navigation for the login flow with WPCom accounts.
@MainActor
final class WPComLoginCoordinator {
    let navigationController: UINavigationController

    /// Title to display on top of the login views
    private let title: String

    private let flow: WPComLoginFlow
    private let stores: StoresManager
    private let accountService: WordPressComAccountServiceProtocol
    private let completionHandler: (Credentials) -> Void
    private var recoveryLinkRunner: WPComMagicLinkAuthRunner?

    private lazy var emailLoginViewModel: WPComEmailLoginViewModel = {
        .init(siteURL: stores.sessionManager.defaultSite?.url ?? "",
              flow: flow,
              allowAccountCreation: true,
              accountService: accountService,
              onPasswordUIRequest: { email in self.showPasswordUIForLogin(email: email) },
              onMagicLinkRequest: { email in self.showMagicLinkRequestUI(email: email) },
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

    func start(with email: String, username: String? = nil) async {
        do {
            let passwordless = try await checkPasswordlessAccount(email: email)
            guard !Task.isCancelled else { return }
            if passwordless {
                await handleMagicLink(email: email)
            } else {
                showPasswordUIForLogin(email: email, username: username)
            }
        } catch {
            guard !Task.isCancelled else { return }
            showAlert(message: error.localizedDescription)
        }
    }
}

// MARK: - Login steps
private extension WPComLoginCoordinator {
    func handleMagicLink(email: String) async {
        do {
            try await requestAuthenticationLink(email: email)
            if case .posPINRecovery = flow {
                guard !Task.isCancelled, navigationController.presentingViewController != nil else { return }
            }
            showMagicLinkSentUI(email: email)
        } catch {
            guard !Task.isCancelled else { return }
            showAlert(message: error.localizedDescription)
        }
    }

    func showPasswordUIForLogin(email: String, username: String? = nil) {
        let viewModel = WPComPasswordLoginViewModel(
            email: email,
            username: username,
            onMagicLinkRequest: { [weak self] email in
                await self?.handleMagicLink(email: email)
            },
            onMultifactorCodeRequest: { [weak self] loginFields in
                self?.show2FALoginUI(with: loginFields)
            },
            onLoginFailure: { [weak self] error in
                guard let self else { return }
                let message = (error as? WordPressComOAuthError)?.loginErrorMessage ?? error.localizedDescription
                self.showAlert(message: message)
            },
            onLoginSuccess: { [weak self] authToken in
                self?.completeLogin(username: username ?? email, authToken: authToken)
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
                             onUseUsernamePassword: { self.showWPComUsernameLogin() },
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
        if let pendingAuthFlow = flow.pendingAuthFlow {
            storage.updateCurrentFlow(pendingAuthFlow)
        }
        let viewController = WPComMagicLinkHostingController(email: email,
                                                             title: title,
                                                             flow: flow,
                                                             isSignup: false)
        if case .posPINRecovery = flow {
            viewController.rootView.onPasteSignInLink = { [weak self] url in
                self?.openRecoveryLink(url, email: email)
            }
        }
        navigationController.show(viewController, sender: self)
    }

    func openRecoveryLink(_ url: URL, email: String) {
        let scheme = Bundle.main.dotcomAuthScheme
        guard recoveryLinkRunner == nil else { return }
        guard POSPINRecoveryMagicLink.isSignInLink(url, callbackScheme: scheme), let window = navigationController.view.window else {
            return showAlert(message: Localization.invalidRecoveryLink)
        }
        let runner = WPComMagicLinkAuthRunner(anchor: window) { [weak self] callback in
            guard let self else { return }
            recoveryLinkRunner = nil
            guard let token = POSPINRecoveryMagicLink.token(from: callback, callbackScheme: scheme) else {
                return showAlert(message: Localization.invalidRecoveryLink)
            }
            completeLogin(username: email, authToken: token)
        } onCancel: { [weak self] in
            self?.recoveryLinkRunner = nil
        }
        recoveryLinkRunner = runner
        runner.start(url: url, callbackURLScheme: scheme)
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
        static let invalidRecoveryLink = NSLocalizedString(
            "wpComLoginCoordinator.posPINRecovery.invalidLink",
            value: "Copy the WordPress.com sign-in link from your email and try again.",
            comment: "Alert shown when an invalid WordPress.com link is pasted during POS PIN recovery."
        )
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

enum POSPINRecoveryMagicLink {
    static func isSignInLink(_ url: URL, callbackScheme: String) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "https", components.host == "wordpress.com", components.path == "/wp-login.php",
              components.user == nil, components.password == nil, components.port == nil else { return false }
        let items = components.queryItems ?? []
        return value("action", in: items) == "magic-login"
            && value("scheme", in: items) == callbackScheme
            && value("token", in: items) != nil
    }

    static func token(from url: URL, callbackScheme: String) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == callbackScheme, components.host == "magic-login", components.path.isEmpty,
              components.user == nil, components.password == nil, components.port == nil else { return nil }
        let items = components.queryItems ?? []
        guard items.allSatisfy({ $0.name != "flow" }) || value("flow", in: items) == "login" else { return nil }
        return value("token", in: items)
    }

    private static func value(_ name: String, in items: [URLQueryItem]) -> String? {
        let matches = items.filter { $0.name == name }
        guard matches.count == 1, let value = matches.first?.value, !value.isEmpty else { return nil }
        return value
    }
}
