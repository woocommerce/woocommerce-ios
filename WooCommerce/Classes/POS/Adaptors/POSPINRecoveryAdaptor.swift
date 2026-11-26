import SwiftUI
import UIKit
import WordPressAuthenticator
import Yosemite
import protocol PointOfSale.POSPINRecoveryProviding
import enum PointOfSale.POSPINRecoveryResult

@MainActor
final class POSPINRecoveryAdaptor: POSPINRecoveryProviding {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func authenticateForPINRecovery(siteID: Int64, from presenter: UIViewController) async -> POSPINRecoveryResult {
        let sessionManager = stores.sessionManager
        guard stores.isAuthenticated,
              sessionManager.defaultStoreID == siteID,
              let credentials = sessionManager.defaultCredentials,
              presenter.viewIfLoaded?.window != nil,
              presenter.presentedViewController == nil,
              !Task.isCancelled else {
            return .failed
        }

        let outcome: POSPINRecoveryOutcome
        switch credentials {
        case let .wporg(username, _, siteAddress):
            let endpoints = sessionManager.cookieNonceAuthenticationEndpoints(for: credentials)
            outcome = await POSPINRecoverySiteSignIn(siteURL: siteAddress, username: username, endpoints: endpoints).present(from: presenter)
        case let .applicationPassword(username, _, siteAddress):
            outcome = await POSPINRecoveryBrowserSignIn(siteURL: siteAddress, username: username).present(from: presenter)
        case .wpcom:
            guard let account = sessionManager.defaultAccount else {
                return .failed
            }
            outcome = await POSPINRecoveryWPComSignIn(account: account, siteID: siteID).present(from: presenter)
        }

        guard outcome == .verified,
              stores.isAuthenticated,
              sessionManager.defaultStoreID == siteID,
              sessionManager.defaultCredentials == credentials else {
            return outcome == .canceled ? .canceled : .failed
        }
        return .verified(siteID: siteID)
    }
}

private enum POSPINRecoveryOutcome {
    case verified
    case canceled
    case failed
}

private extension POSPINRecoveryIdentity {
    var errorMessage: String {
        switch self {
        case .sameEligibleAccount: ""
        case .differentAccount: Localization.differentAccount
        case .notEligible: Localization.notEligible
        case .failed: Localization.genericFailure
        case .cleanupFailed: Localization.cleanupFailed
        }
    }

    enum Localization {
        static let differentAccount = NSLocalizedString(
            "pos.pinRecovery.signIn.differentAccount",
            value: "Sign in with the same account that is signed in to the app.",
            comment: "Error shown when POS PIN recovery is attempted with a different account."
        )
        static let notEligible = NSLocalizedString(
            "pos.pinRecovery.signIn.signedInAccountNotEligible",
            value: "The signed-in account needs the Administrator or Shop Manager role for this store.",
            comment: "Error shown when the account used for POS PIN recovery can't open POS for the store."
        )
        static let cleanupFailed = NSLocalizedString(
            "pos.pinRecovery.signIn.cleanupFailed",
            value: "A temporary application password could not be removed. Check Application Passwords in your store profile.",
            comment: "Error shown when POS PIN recovery cannot remove a temporary application password."
        )
        static let genericFailure = NSLocalizedString(
            "pos.pinRecovery.signIn.genericFailure",
            value: "Sign-in failed. Please try again.",
            comment: "Generic error shown when POS PIN recovery sign-in fails."
        )
        static let title = NSLocalizedString(
            "pos.pinRecovery.signIn.title",
            value: "Forgot PIN",
            comment: "Title of the sign-in modal used for POS PIN recovery."
        )
        static let cancel = NSLocalizedString(
            "pos.pinRecovery.signIn.cancel",
            value: "Cancel",
            comment: "Cancel button in the POS PIN recovery sign-in modal."
        )
        static let ok = NSLocalizedString(
            "pos.pinRecovery.signIn.ok",
            value: "OK",
            comment: "Dismisses an error in the POS PIN recovery sign-in modal."
        )
        static let signingIn = NSLocalizedString("pos.pinRecovery.signIn.signingIn", value: "Signing in", comment: "Sign-in progress label.")
    }
}

@MainActor
private class POSPINRecoveryModalFlow: NSObject {
    let navigationController = UINavigationController()
    private var continuation: CheckedContinuation<POSPINRecoveryOutcome, Never>?
    var isPresenting: Bool { continuation != nil }

    func present(root: UIViewController, from presenter: UIViewController) async -> POSPINRecoveryOutcome {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                addCancelButton(to: root)
                navigationController.viewControllers = [root]
                navigationController.modalPresentationStyle = .formSheet
                navigationController.isModalInPresentation = true
                presenter.present(navigationController, animated: true)
            }
        } onCancel: { [weak self] in
            Task { @MainActor in self?.cancel() }
        }
    }

    func addCancelButton(to controller: UIViewController) {
        let button = UIBarButtonItem(title: POSPINRecoveryIdentity.Localization.cancel, style: .plain, target: self, action: #selector(cancel))
        button.accessibilityIdentifier = "pos-pin-recovery-cancel"
        controller.navigationItem.leftBarButtonItem = button
    }

    @objc func cancel() {
        willFinish()
        finish(.canceled)
    }

    func willFinish() {}

    func finish(_ outcome: POSPINRecoveryOutcome) {
        guard let continuation else { return }
        self.continuation = nil
        guard navigationController.presentingViewController != nil else {
            continuation.resume(returning: outcome)
            return
        }
        navigationController.dismiss(animated: true) {
            continuation.resume(returning: outcome)
        }
    }

    func showError(_ message: String, onDismiss: (() -> Void)? = nil) {
        guard isPresenting else { return }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: POSPINRecoveryIdentity.Localization.ok, style: .default) { _ in onDismiss?() })
        (navigationController.topViewController ?? navigationController).present(alert, animated: true)
    }
}

@MainActor
private final class POSPINRecoveryWPComSignIn: POSPINRecoveryModalFlow {
    private let account: Account
    private let siteID: Int64
    private var coordinator: WPComLoginCoordinator?
    private weak var startupController: UIViewController?
    private var startupTask: Task<Void, Never>?
    private var verificationTask: Task<Void, Never>?

    init(account: Account, siteID: Int64) {
        self.account = account
        self.siteID = siteID
    }

    func present(from presenter: UIViewController) async -> POSPINRecoveryOutcome {
        let placeholder = UIHostingController(rootView: ProgressView().accessibilityLabel(POSPINRecoveryIdentity.Localization.signingIn))
        placeholder.title = POSPINRecoveryIdentity.Localization.title
        startupController = placeholder
        let coordinator = WPComLoginCoordinator(flow: .posPINRecovery,
                                                navigationController: navigationController) { [weak self] credentials in
            self?.verify(credentials)
        }
        self.coordinator = coordinator
        navigationController.delegate = self
        startupTask = Task { @MainActor [account] in
            await coordinator.start(with: account.email, username: account.username)
        }
        return await present(root: placeholder, from: presenter)
    }

    override func willFinish() {
        startupTask?.cancel()
        verificationTask?.cancel()
        coordinator?.cancelRecoveryLink()
        coordinator = nil
    }

    private func verify(_ credentials: Credentials) {
        guard coordinator != nil, verificationTask == nil else { return }
        guard case let .wpcom(_, authToken, _) = credentials else {
            return showError(POSPINRecoveryIdentity.failed.errorMessage)
        }
        verificationTask = Task { @MainActor [weak self, account, siteID] in
            let identity = await Self.identity(authToken: authToken, expectedUserID: account.userID, siteID: siteID)
            guard let self, !Task.isCancelled else { return }
            verificationTask = nil
            if identity == .sameEligibleAccount {
                finish(.verified)
            } else {
                showError(identity.errorMessage)
            }
        }
    }

    private static func identity(authToken: String, expectedUserID: Int64, siteID: Int64) async -> POSPINRecoveryIdentity {
        do {
            return try await POSPINRecoveryIdentity.verifyWordPressCom(authToken: authToken, expectedUserID: expectedUserID, siteID: siteID)
        } catch {
            DDLogError("⛔️ POS PIN recovery WordPress.com identity check failed")
            return .failed
        }
    }
}

extension POSPINRecoveryWPComSignIn: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        addCancelButton(to: viewController)
        viewController.navigationItem.leftItemsSupplementBackButton = viewController is WPCom2FALoginHostingController
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if let startupController,
           navigationController.viewControllers.count == 2,
           navigationController.viewControllers.first === startupController {
            navigationController.setViewControllers([viewController], animated: false)
        }
    }
}

@MainActor
private final class POSPINRecoveryBrowserSignIn: POSPINRecoveryModalFlow {
    private let siteURL: String
    private let username: String
    private var verificationTask: Task<Void, Never>?

    init(siteURL: String, username: String) {
        self.siteURL = siteURL
        self.username = username
    }

    func present(from presenter: UIViewController) async -> POSPINRecoveryOutcome {
        await present(root: makeAuthorizationController(), from: presenter)
    }

    private func makeAuthorizationController() -> UIViewController {
        ApplicationPasswordAuthorizationWebViewController(
            viewModel: ApplicationPasswordAuthorizationViewModel(siteURL: siteURL),
            previousViewController: nil,
            onSuccess: { [weak self] applicationPassword, _ in
                self?.verify(applicationPassword)
            })
    }

    private func verify(_ applicationPassword: ApplicationPassword) {
        guard verificationTask == nil else { return }
        let login = applicationPassword.wpOrgUsername
        let password = applicationPassword.password.secretValue
        let appID = applicationPassword.uuid
        verificationTask = Task { @MainActor [weak self, siteURL, username] in
            // WordPress already created this credential. Remove it even if the user closes the sheet.
            let identity = await POSPINRecoveryIdentity.verifyBrowserAuthorization(siteURL: siteURL,
                                                                                   login: login,
                                                                                   password: password,
                                                                                   appID: appID,
                                                                                   expectedLogin: username)
            guard let self, isPresenting else { return }
            if identity == .sameEligibleAccount {
                finish(.verified)
            } else {
                showError(identity.errorMessage) { [weak self] in
                    guard let self, isPresenting else { return }
                    if identity == .cleanupFailed {
                        finish(.canceled)
                        return
                    }
                    verificationTask = nil
                    let controller = makeAuthorizationController()
                    addCancelButton(to: controller)
                    navigationController.setViewControllers([controller], animated: false)
                }
            }
        }
    }
}

@MainActor
private final class POSPINRecoverySiteSignIn: POSPINRecoveryModalFlow {
    private let siteURL: String
    private let username: String
    private let endpoints: CookieNonceAuthenticationEndpoints?
    private var useCase: SiteCredentialLoginUseCase?
    private var verificationTask: Task<Void, Never>?

    init(siteURL: String, username: String, endpoints: CookieNonceAuthenticationEndpoints?) {
        self.siteURL = siteURL
        self.username = username
        self.endpoints = endpoints
    }

    func present(from presenter: UIViewController) async -> POSPINRecoveryOutcome {
        let controller = WordPressAuthenticator.makeSiteCredentialEntryController(siteURL: siteURL,
                                                                                  username: username) { [weak self] username, password, onFailure in
            self?.signIn(username: username, password: password, onFailure: onFailure)
        }
        guard let controller else { return .failed }
        return await present(root: controller, from: presenter)
    }

    override func willFinish() {
        useCase?.cancel()
        verificationTask?.cancel()
    }

    private func signIn(username: String, password: String, onFailure: @escaping @MainActor (String) -> Void) {
        guard isPresenting, useCase == nil else { return }
        let cookieJar = SiteCredentialLoginUseCase.makePrivateCookieJar()
        let useCase = SiteCredentialLoginUseCase(siteURL: siteURL, endpoints: endpoints, cookieJar: cookieJar)
        useCase.setupHandlers(onLoginSuccess: { [weak self] provenEndpoints in
            guard let self, isPresenting else { return }
            verificationTask = Task { @MainActor [weak self, expectedLogin = self.username] in
                let session = URLSession(configuration: SiteCredentialLoginUseCase.makeSessionConfiguration(cookieJar: cookieJar))
                let identity = await POSPINRecoveryIdentity.verifySiteCredentials(endpoints: provenEndpoints,
                                                                                  session: session, expectedLogin: expectedLogin)
                session.invalidateAndCancel()
                cookieJar.cookies?.forEach(cookieJar.deleteCookie)
                guard let self, !Task.isCancelled, isPresenting else { return }
                if identity == .sameEligibleAccount {
                    finish(.verified)
                } else {
                    self.useCase = nil
                    onFailure(identity.errorMessage)
                }
            }
        }, onLoginFailure: { [weak self] error, _, _ in
            cookieJar.cookies?.forEach(cookieJar.deleteCookie)
            guard let self, isPresenting else { return }
            self.useCase = nil
            onFailure(error.errorMessage.isEmpty ? POSPINRecoveryIdentity.failed.errorMessage : error.errorMessage)
        })
        self.useCase = useCase
        useCase.handleLogin(username: username, password: password)
    }
}
