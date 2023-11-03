import UIKit
import enum Yosemite.Credentials
import protocol Yosemite.StoresManager
import WordPressAuthenticator
import WooFoundation

/// Coordinates navigation for the login flow with WPCom accounts.
final class WPComLoginCoordinator {
    /// Title to display on top of the login views
    private let title: String

    /// Whether the view is part of the login step of the Jetpack setup flow.
    private let isJetpackSetup: Bool
    private let navigationController: UINavigationController
    private let stores: StoresManager
    private let accountService: WordPressComAccountServiceProtocol
    private let completionHandler: () -> Void

    init(title: String = Localization.login,
         isJetpackSetup: Bool = false,
         navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         accountService: WordPressComAccountServiceProtocol = WordPressComAccountService(),
         completionHandler: @escaping () -> Void) {
        self.title = title
        self.isJetpackSetup = isJetpackSetup
        self.navigationController = navigationController
        self.stores = stores
        self.accountService = accountService
        self.completionHandler = completionHandler
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
            showMagicLinkForLogin(email: email)
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
                await self?.authenticateUserAndComplete(username: email, authToken: authToken)
            })
        let viewController = WPComPasswordLoginHostingController(
            title: title,
            isJetpackSetup: isJetpackSetup,
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
                await self?.authenticateUserAndComplete(username: loginFields.username,
                                                        authToken: authToken)
            })
        let viewController = WPCom2FALoginHostingController(title: title,
                                                            isJetpackSetup: isJetpackSetup,
                                                            viewModel: viewModel)
        navigationController.show(viewController, sender: self)
    }

    /// Shows the UI saying magic link has been sent to the email address,
    /// asking the user to check their inbox to log in.
    /// We will be waiting for authentication request from the magic link in `AppDelegate` method for opening URL for deeplink.
    /// We're letting WPAuthenticator handle the deeplink for now.
    ///
    func showMagicLinkForLogin(email: String) {
        let viewController = WPComMagicLinkHostingController(email: email,
                                                             title: title,
                                                             isJetpackSetup: isJetpackSetup)
        navigationController.show(viewController, sender: self)
    }

    @MainActor
    func authenticateUserAndComplete(username: String, authToken: String) async {
        await withCheckedContinuation { continuation in
            let credentials = Credentials(username: username, authToken: authToken)
            stores.authenticate(credentials: credentials)
                .synchronizeEntities(onCompletion: { [weak self] in
                    guard let self else { return }
                    self.completionHandler()
                    continuation.resume()
                })
        }
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
            accountService.requestAuthenticationLink(for: email, jetpackLogin: false, success: {
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
