import Foundation
import UIKit
import Yosemite


/// Simplifies and decouples the store picker from the caller
///
final class StorePickerCoordinator: Coordinator {

    unowned private(set) var navigationController: UINavigationController

    /// Determines how the store picker should initialized
    ///
    var selectedConfiguration: StorePickerConfiguration

    /// Closure to be executed upon dismissal of the store picker
    ///
    var onDismiss: (() -> Void)?

    /// The switchStoreUseCase object initialized with the ServiceLocator stores
    ///
    private let switchStoreUseCase = SwitchStoreUseCase(stores: ServiceLocator.stores)

    /// The RoleEligibilityUseCase object initialized with the ServiceLocator stores
    ///
    private let roleEligibilityUseCase = RoleEligibilityUseCase(stores: ServiceLocator.stores)

    private var storeCreationCoordinator: StoreCreationCoordinator?

    /// Site Picker VC
    ///
    private lazy var storePicker: StorePickerViewController = {
        let pickerVC = StorePickerViewController(configuration: selectedConfiguration)
        pickerVC.delegate = self
        return pickerVC
    }()

    init(_ navigationController: UINavigationController, config: StorePickerConfiguration) {
        self.navigationController = navigationController
        self.selectedConfiguration = config
    }

    func start() {
        showStorePicker()
    }
}


// MARK: - StorePickerViewControllerDelegate Conformance
//
extension StorePickerCoordinator: StorePickerViewControllerDelegate {

    func didSelectStore(with storeID: Int64, onCompletion: @escaping SelectStoreClosure) {
        switchStore(with: storeID, onCompletion: onCompletion)
    }

    /// Shows a Role Error page using the provided error information.
    /// The error page is pushed to the navigation stack so the user is not locked out, and can go back to select another store.
    func showRoleErrorScreen(for siteID: Int64, errorInfo: StorageEligibilityErrorInfo, onCompletion: @escaping SelectStoreClosure) {
        let errorViewModel = RoleErrorViewModel(siteID: siteID, title: errorInfo.name, subtitle: errorInfo.humanizedRoles, useCase: self.roleEligibilityUseCase)
        let errorViewController = RoleErrorViewController(viewModel: errorViewModel)

        // when the retry is successful, resume the original switchStore intention.
        errorViewModel.onSuccess = {
            self.switchStore(with: siteID, onCompletion: onCompletion)
        }

        errorViewModel.onDeauthenticationRequest = {
            self.restartAuthentication()
        }

        // find the top-most navigation controller by checking if there's a navigationController being presented.
        // this takes care of the different variation of presentation, based on configurations.
        var topNavigationController = navigationController
        while let presented = topNavigationController.presentedViewController as? UINavigationController {
            topNavigationController = presented
        }
        topNavigationController.show(errorViewController, sender: self)
    }

    func restartAuthentication() {
        navigationController.dismiss(animated: false) { [weak self] in
            ServiceLocator.stores.deauthenticate()
            self?.onDismiss?()
        }
    }

    func createStore() {
        let source: StoreCreationCoordinator.Source
        switch selectedConfiguration {
        case .storeCreationFromLogin(let loggedOutSource):
            source = .loggedOut(source: loggedOutSource)
        default:
            source = .storePicker
        }

        switch selectedConfiguration.presentationStyle {
        case .fullscreen:
            // The store picker was presented modally in fullscreen, and thus we need to present the
            // store creation flow on top of the store picker instead of the store picker's navigation controller
            // (invisible behind the store picker).
            guard let presentedNavigationController = navigationController.topmostPresentedViewController as? UINavigationController else {
                return
            }
            let coordinator = StoreCreationCoordinator(source: source,
                                                       navigationController: presentedNavigationController)
            self.storeCreationCoordinator = coordinator
            coordinator.start()
        case .modally, .navigationStack:
            let coordinator = StoreCreationCoordinator(source: source,
                                                       navigationController: navigationController)
            self.storeCreationCoordinator = coordinator
            coordinator.start()
        }
    }
}

// MARK: - Private Helpers
//
private extension StorePickerCoordinator {

    func showStorePicker() {
        showStorePicker(presentationStyle: selectedConfiguration.presentationStyle)
    }

    func showStorePicker(presentationStyle: PresentationStyle) {
        switch presentationStyle {
        case .fullscreen:
            let wrapper = WooNavigationController(rootViewController: storePicker)
            wrapper.modalPresentationStyle = .fullScreen
            navigationController.present(wrapper, animated: false)
        case .modally:
            let wrapper = WooNavigationController(rootViewController: storePicker)
            navigationController.present(wrapper, animated: true)
        case .navigationStack(let animated):
            navigationController.pushViewController(storePicker, animated: animated)
        }
    }

    /// Switches the current user's default store to the one having the provided `storeID`.
    /// After successfully switching, the store picker screen should be dismissed.
    func switchStore(with storeID: Int64, onCompletion: @escaping SelectStoreClosure) {
        switchStoreUseCase.switchStore(with: storeID) { [weak self] siteChanged in
            guard let self = self else { return }
            if self.selectedConfiguration == .login {
                MainTabBarController.switchToMyStoreTab(animated: true)
            }

            if siteChanged {
                let presenter = SwitchStoreNoticePresenter(siteID: storeID)
                presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: self.selectedConfiguration)
            }
            onCompletion()
            self.onDismiss?()
        }
    }
}

private extension StorePickerCoordinator {
    /// How the store picker view is presented.
    enum PresentationStyle {
        /// Pushed to the given navigation stack `navigationController`.
        case navigationStack(animated: Bool)

        /// Presented modally on top of the given `navigationController`.
        case modally

        /// Presented modally without animation and in fullscreen.
        case fullscreen
    }
}

private extension StorePickerConfiguration {
    /// How the store picker view is presented for each configuration.
    var presentationStyle: StorePickerCoordinator.PresentationStyle {
        switch self {
        case .standard:
            return .fullscreen
        case .switchingStores:
            return .modally
        case .storeCreationFromLogin:
            return .navigationStack(animated: true)
        default:
            return .navigationStack(animated: true)
        }
    }
}
