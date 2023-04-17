import UIKit
import enum WordPressAuthenticator.SignInSource
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
        let viewModel = AccountCreationFormViewModel(emailSubmissionHandler: { [weak self] email, isExisting in
            self?.handleEmailSubmission(email: email, isExisting: isExisting)
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
    func handleEmailSubmission(email: String, isExisting: Bool) {
        let signInSource: SignInSource = .custom(source: source.rawValue)
        guard !isExisting else {
            /// Navigates to login with the existing email address.
            let command = NavigateToEnterAccount(signInSource: signInSource, email: email)
            command.execute(from: navigationController)
            return
        }
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
    }
}
