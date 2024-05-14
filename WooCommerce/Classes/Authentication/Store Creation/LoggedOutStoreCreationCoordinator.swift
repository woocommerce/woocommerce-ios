import UIKit
import Experiments
import enum WordPressAuthenticator.SignInSource
import protocol WooFoundation.Analytics
import struct WordPressAuthenticator.NavigateToEnterAccount

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

    private let analytics: Analytics
    private let source: Source
    private let featureFlagService: FeatureFlagService

    private lazy var signInSource: SignInSource = .custom(source: source.rawValue)

    init(source: Source,
         navigationController: UINavigationController,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.source = source
        self.navigationController = navigationController
        self.analytics = analytics
        self.featureFlagService = featureFlagService
    }

    func start() {
        let viewModel = AccountCreationFormViewModel(onExistingEmail: { [weak self] email in
            await self?.startLoginWithExistingAccount(email: email)
        }, completionHandler: { [weak self] in
            guard let self else { return }
            self.startStoreCreation(in: self.navigationController)
        })
        let accountCreationController = AccountCreationFormHostingController(
            viewModel: viewModel,
            signInSource: signInSource,
            analytics: analytics
        )
        navigationController.show(accountCreationController, sender: self)
    }
}

private extension LoggedOutStoreCreationCoordinator {
    @MainActor
    func startLoginWithExistingAccount(email: String) async {
        guard featureFlagService.isFeatureFlagEnabled(.customLoginUIForAccountCreation) else {
            /// Navigates to login with the authenticator library.
            let command = NavigateToEnterAccount(signInSource: signInSource, email: email)
            command.execute(from: navigationController.topViewController ?? navigationController)
            return
        }
        let coordinator = WPComLoginCoordinator(navigationController: navigationController) { [weak self] in
            guard let self else { return }
            self.startStoreCreation(in: self.navigationController)
        }
        self.loginCoordinator = coordinator
        await coordinator.start(with: email)
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
