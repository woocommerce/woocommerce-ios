import UIKit
import protocol Yosemite.StoresManager
import enum WordPressAuthenticator.SignInSource

/// Coordinates navigation for store creation flow in logged-out state that starts with WPCOM authentication.
final class LoggedOutStoreCreationCoordinator: Coordinator {
    /// Navigation source to store creation.
    enum Source: String, Equatable {
        /// Initiated from the login prologue in logged-out state.
        case prologue
        /// Initiated from the login email error screen in logged-out state.
        case loginEmailError
    }

    let navigationController: UINavigationController

    private var storePickerCoordinator: StorePickerCoordinator?
    private var storeCreationCoordinator: StoreCreationCoordinator?
    private var loginCoordinator: WPComLoginCoordinator?

    private let stores: StoresManager
    private let analytics: Analytics
    private let source: Source

    init(source: Source,
         navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.source = source
        self.navigationController = navigationController
        self.stores = stores
        self.analytics = analytics
    }

    func start() {
        let viewModel = AccountCreationFormViewModel(onExistingEmail: { [weak self] email in
            await self?.startLoginWithExistingAccount(email: email)
        }, emailSubmissionHandler: { [weak self] email in
            self?.handleEmailSubmission(email: email)
        })
        let accountCreationController = AccountCreationFormHostingController(
            field: .email,
            viewModel: viewModel,
            signInSource: .custom(source: source.rawValue),
            analytics: analytics
        ) { [weak self] in
            guard let self else { return }
            self.startStoreCreation(in: self.navigationController)
        }
        navigationController.show(accountCreationController, sender: self)
    }
}

private extension LoggedOutStoreCreationCoordinator {
    @MainActor
    func startLoginWithExistingAccount(email: String) async {
        let coordinator = WPComLoginCoordinator(navigationController: navigationController) { [weak self] in
            guard let self else { return }
            self.startStoreCreation(in: self.navigationController)
        }
        self.loginCoordinator = coordinator
        await coordinator.start(with: email)
    }

    func handleEmailSubmission(email: String) {
        let signInSource: SignInSource = .custom(source: source.rawValue)

        /// Navigates to password field for account creation
        let passwordView = AccountCreationFormHostingController(field: .password,
                                                                viewModel: .init(email: email),
                                                                signInSource: signInSource,
                                                                completion: { [weak self] in
            guard let self else { return }
            self.startStoreCreation(in: self.navigationController)
        })
        navigationController.show(passwordView, sender: nil)
    }

    func startStoreCreation(in navigationController: UINavigationController) {
        // Shows the store picker first, so that after dismissal of the store creation view it goes back to the store picker.
        let coordinator = StorePickerCoordinator(navigationController, config: .storeCreationFromLogin(source: source))
        storePickerCoordinator = coordinator
        coordinator.start()

        // Start store creation
        storeCreationCoordinator = StoreCreationCoordinator(source: .loggedOut(source: source),
                                                            navigationController: navigationController)
        storeCreationCoordinator?.start()
    }
}
