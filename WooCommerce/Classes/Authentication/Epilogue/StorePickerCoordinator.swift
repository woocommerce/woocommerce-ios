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

    /// The switchStoreUseCase object initialized with the ServiceLocator stores
    ///
    private let switchStoreUseCase = SwitchStoreUseCase(stores: ServiceLocator.stores)

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
        switchStoreUseCase.switchStore(with: storeID) { [weak self] siteChanged in
            if self?.selectedConfiguration == .login {
                MainTabBarController.switchToMyStoreTab(animated: true)
            }

            if siteChanged {
                let presenter = SwitchStoreNoticePresenter()
                presenter.presentStoreSwitchedNotice(configuration: self?.selectedConfiguration)
            }
            onCompletion()
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
