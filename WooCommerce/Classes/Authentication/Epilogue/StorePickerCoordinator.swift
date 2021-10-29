import Foundation
import UIKit
import Yosemite


/// Simplifies and decouples the store picker from the caller
///
final class StorePickerCoordinator: Coordinator {

    unowned var navigationController: UINavigationController

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

    /// Site Picker VC
    ///
    private lazy var storePicker: StorePickerViewController = {
        let pickerVC = StorePickerViewController()
        pickerVC.delegate = self
        pickerVC.configuration = selectedConfiguration
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
        roleEligibilityUseCase.checkEligibility(for: storeID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                // if user is eligible, then switch to the desired store.
                self.switchStore(with: storeID, onCompletion: onCompletion)

            case .failure(let error):
                if case let RoleEligibilityError.insufficientRole(errorInfo) = error {
                    self.showRoleErrorScreen(for: storeID, errorInfo: errorInfo, onCompletion: onCompletion)
                }
            }
        }
    }

    func restartAuthentication() {
        navigationController.dismiss(animated: false) { [weak self] in
            ServiceLocator.stores.deauthenticate()
            self?.onDismiss?()
        }
    }
}

// MARK: - Private Helpers
//
private extension StorePickerCoordinator {

    func showStorePicker() {
        switch selectedConfiguration {
        case .standard:
            let wrapper = WooNavigationController(rootViewController: storePicker)
            wrapper.modalPresentationStyle = .fullScreen
            navigationController.present(wrapper, animated: false)
        case .switchingStores:
            let wrapper = WooNavigationController(rootViewController: storePicker)
            navigationController.present(wrapper, animated: true)
        default:
            navigationController.pushViewController(storePicker, animated: true)
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

}
