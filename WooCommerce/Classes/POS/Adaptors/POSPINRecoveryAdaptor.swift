import SwiftUI
import UIKit
import WordPressAuthenticator
import Yosemite
import enum PointOfSale.POSPINRecoveryResult

struct POSPINRecoveryView: UIViewControllerRepresentable {
    let siteID: Int64
    let onCompletion: (POSPINRecoveryResult) -> Void

    func makeCoordinator() -> POSPINRecoveryAdaptor {
        POSPINRecoveryAdaptor()
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        context.coordinator.start(siteID: siteID, onCompletion: onCompletion)
    }

    func updateUIViewController(_ controller: UINavigationController, context: Context) {}

    static func dismantleUIViewController(_ controller: UINavigationController, coordinator: POSPINRecoveryAdaptor) {
        coordinator.cancel()
    }
}

@MainActor
final class POSPINRecoveryAdaptor {
    private let stores: StoresManager
    private var flow: POSPINRecoveryModalFlow?

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func start(siteID: Int64, onCompletion: @escaping (POSPINRecoveryResult) -> Void) -> UINavigationController {
        let sessionManager = stores.sessionManager
        guard stores.isAuthenticated,
              sessionManager.defaultStoreID == siteID,
              let credentials = sessionManager.defaultCredentials,
              let flow = makeFlow(for: credentials, siteID: siteID) else {
            Task { @MainActor in onCompletion(.failed) }
            return UINavigationController()
        }
        self.flow = flow
        return flow.start { [weak self, stores] outcome in
            self?.flow = nil
            switch outcome {
            case .verified where stores.isAuthenticated
                && sessionManager.defaultStoreID == siteID
                && sessionManager.defaultCredentials == credentials:
                onCompletion(.verified(siteID: siteID))
            case .canceled:
                onCompletion(.canceled)
            default:
                onCompletion(.failed)
            }
        }
    }

    func cancel() {
        flow?.end()
        flow = nil
    }

    private func makeFlow(for credentials: Credentials, siteID: Int64) -> POSPINRecoveryModalFlow? {
        switch credentials {
        case let .wporg(_, _, siteAddress):
            let endpoints = stores.sessionManager.cookieNonceAuthenticationEndpoints(for: credentials)
            return POSPINRecoverySiteSignIn(siteURL: siteAddress, siteID: siteID, stores: stores, endpoints: endpoints)
        case let .applicationPassword(_, _, siteAddress):
            return POSPINRecoveryBrowserSignIn(siteURL: siteAddress, siteID: siteID, stores: stores)
        case .wpcom:
            return stores.sessionManager.defaultAccount.map { POSPINRecoveryWPComSignIn(account: $0, siteID: siteID) }
        }
    }

    static func siteUserID(siteID: Int64, stores: StoresManager) async -> Int64? {
        await withCheckedContinuation { continuation in
            stores.dispatch(UserAction.retrieveUser(siteID: siteID) { result in
                switch result {
                case .success(let user):
                    continuation.resume(returning: user.localID)
                case .failure(let error):
                    DDLogError("⛔️ POS PIN recovery could not load the signed-in site user: \(error)")
                    continuation.resume(returning: nil)
                }
            })
        }
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
    }
}

@MainActor
private class POSPINRecoveryModalFlow: NSObject {
    let navigationController = UINavigationController()
    private var completion: ((POSPINRecoveryOutcome) -> Void)?
    var isPresenting: Bool { completion != nil }

    func start(onCompletion: @escaping (POSPINRecoveryOutcome) -> Void) -> UINavigationController {
        completion = onCompletion
        guard let root = makeRoot() else {
            Task { @MainActor [weak self] in self?.finish(.failed) }
            return navigationController
        }
        addCancelButton(to: root)
        navigationController.viewControllers = [root]
        return navigationController
    }

    func makeRoot() -> UIViewController? {
        nil
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

    func end() {
        willFinish()
        completion = nil
    }

    func willFinish() {}

    func finish(_ outcome: POSPINRecoveryOutcome) {
        guard let completion else { return }
        self.completion = nil
        completion(outcome)
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
    private var verificationTask: Task<Void, Never>?

    init(account: Account, siteID: Int64) {
        self.account = account
        self.siteID = siteID
    }

    override func makeRoot() -> UIViewController? {
        let coordinator = WPComLoginCoordinator(flow: .posPINRecovery,
                                                navigationController: navigationController) { [weak self] credentials in
            self?.verify(credentials)
        }
        self.coordinator = coordinator
        navigationController.delegate = self
        coordinator.startWithoutEmail()
        return navigationController.viewControllers.first
    }

    override func willFinish() {
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
        viewController.navigationItem.leftItemsSupplementBackButton = true
    }
}

@MainActor
private final class POSPINRecoveryBrowserSignIn: POSPINRecoveryModalFlow {
    private let siteURL: String
    private let siteID: Int64
    private let stores: StoresManager
    private var verificationTask: Task<Void, Never>?

    init(siteURL: String, siteID: Int64, stores: StoresManager) {
        self.siteURL = siteURL
        self.siteID = siteID
        self.stores = stores
    }

    override func makeRoot() -> UIViewController? {
        makeAuthorizationController()
    }

    private func makeAuthorizationController() -> UIViewController {
        ApplicationPasswordAuthorizationWebViewController(
            viewModel: ApplicationPasswordAuthorizationViewModel(siteURL: siteURL),
            previousViewController: nil,
            appNameSuffix: ".pos-pin-recovery." + UUID().uuidString.prefix(8).lowercased(),
            onSuccess: { [weak self] applicationPassword, _ in
                self?.verify(applicationPassword)
            })
    }

    private func verify(_ applicationPassword: ApplicationPassword) {
        guard verificationTask == nil else { return }
        let login = applicationPassword.wpOrgUsername
        let password = applicationPassword.password.secretValue
        let appID = applicationPassword.uuid
        verificationTask = Task { @MainActor [weak self, siteURL, siteID, stores] in
            let expectedUserID = await POSPINRecoveryAdaptor.siteUserID(siteID: siteID, stores: stores)
            // WordPress already created this credential. Remove it even if the user closes the sheet.
            let identity = await POSPINRecoveryIdentity.verifyBrowserAuthorization(siteURL: siteURL,
                                                                                   login: login,
                                                                                   password: password,
                                                                                   appID: appID,
                                                                                   expectedUserID: expectedUserID)
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
    private let siteID: Int64
    private let stores: StoresManager
    private let endpoints: CookieNonceAuthenticationEndpoints?
    private var useCase: SiteCredentialLoginUseCase?
    private var verificationTask: Task<Void, Never>?

    init(siteURL: String, siteID: Int64, stores: StoresManager, endpoints: CookieNonceAuthenticationEndpoints?) {
        self.siteURL = siteURL
        self.siteID = siteID
        self.stores = stores
        self.endpoints = endpoints
    }

    override func makeRoot() -> UIViewController? {
        WordPressAuthenticator.makeSiteCredentialEntryController(siteURL: siteURL) { [weak self] username, password, onFailure in
            self?.signIn(username: username, password: password, onFailure: onFailure)
        }
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
            verificationTask = Task { @MainActor [weak self, siteID, stores] in
                let session = URLSession(configuration: SiteCredentialLoginUseCase.makeSessionConfiguration(cookieJar: cookieJar))
                let identity: POSPINRecoveryIdentity
                if let expectedUserID = await POSPINRecoveryAdaptor.siteUserID(siteID: siteID, stores: stores) {
                    identity = await POSPINRecoveryIdentity.verifySiteCredentials(endpoints: provenEndpoints,
                                                                                 session: session, expectedUserID: expectedUserID)
                } else {
                    identity = .failed
                }
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
