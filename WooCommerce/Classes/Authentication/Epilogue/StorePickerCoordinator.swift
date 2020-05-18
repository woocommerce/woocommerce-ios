import Foundation
import UIKit


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

    func willSelectStore(with storeID: Int64, onCompletion: @escaping SelectStoreClosure) {
        guard selectedConfiguration == .switchingStores else {
            onCompletion()
            return
        }
        guard storeID != ServiceLocator.stores.sessionManager.defaultStoreID else {
            onCompletion()
            return
        }

        SwitchStoreUseCase(stores: ServiceLocator.stores, noticePresenter: ServiceLocator.noticePresenter).logOutOfCurrentStore(onCompletion: onCompletion)
    }

    func didSelectStore(with storeID: Int64) {
        guard storeID != ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        SwitchStoreUseCase(stores: ServiceLocator.stores, noticePresenter: ServiceLocator.noticePresenter).finalizeStoreSelection(storeID)
        if selectedConfiguration == .login {
            MainTabBarController.switchToMyStoreTab(animated: true)
        }
        SwitchStoreUseCase(stores: ServiceLocator.stores, noticePresenter: ServiceLocator.noticePresenter).presentStoreSwitchedNotice(configuration: selectedConfiguration)

        // Reload orders badge
        NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)

        onDismiss?()
    }
}

// MARK: - Private Helpers
//
private extension StorePickerCoordinator {

    func showStorePicker() {
        switch selectedConfiguration {
        case .standard:
            let wrapper = UINavigationController(rootViewController: storePicker)
            wrapper.modalPresentationStyle = .fullScreen
            navigationController.present(wrapper, animated: true)
        case .switchingStores:
            let wrapper = UINavigationController(rootViewController: storePicker)
            navigationController.present(wrapper, animated: true)
        default:
            navigationController.pushViewController(storePicker, animated: true)
        }
    }

}
