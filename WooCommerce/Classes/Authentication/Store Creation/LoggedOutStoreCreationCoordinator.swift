import UIKit

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

    private let analytics: Analytics
    private let source: Source

    init(source: Source,
         navigationController: UINavigationController,
         analytics: Analytics = ServiceLocator.analytics) {
        self.source = source
        self.navigationController = navigationController
        self.analytics = analytics
    }

    func start() {
        let accountCreationController = AccountCreationFormHostingController(
            viewModel: .init(),
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
    func startStoreCreation(in navigationController: UINavigationController) {
        // Shows the store picker first, so that after dismissal of the store creation view it goes back to the store picker.
        let coordinator = StorePickerCoordinator(navigationController, config: .storeCreationFromLogin(source: source))
        storePickerCoordinator = coordinator
        coordinator.start()
    }
}
