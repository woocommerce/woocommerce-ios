import Foundation
import UIKit
import Yosemite


/// Configuration option enum for the StorePicker
///
enum StorePickerConfiguration {

    /// Setup the store picker for use in the login flow
    ///
    case login

    /// Setup the store picker for use in the store switching flow
    ///
    case switchingStores
}


/// Simplifies and decouples the store picker from the caller
///
final class StorePickerCoordinator: Coordinator {

    unowned var navigationController: UINavigationController

    /// Determines how the store picker should initialized
    ///
    var config: StorePickerConfiguration

    /// Closure to be executed upon dismissal of the store picker
    ///
    var onDismiss: (() -> Void)?

    /// Site Picker VC
    ///
    private lazy var storePicker: StorePickerViewController = {
        let pickerVC = StorePickerViewController()
        pickerVC.delegate = self
        return pickerVC
    }()

    init(_ navigationController: UINavigationController, config: StorePickerConfiguration) {
        self.navigationController = navigationController
        self.config = config
    }

    func start() {
        showStorePicker()
    }
}


// MARK: - Private Helpers
//
extension StorePickerCoordinator: StorePickerViewControllerDelegate {
    func shouldProceed(with storeID: Int) -> Bool {
        guard config == .switchingStores else {
            return true
        }

        logOutOfCurrentStore()
        return true
    }

    func didCompleteStoreSelection() {
        onDismiss?()
    }
}

// MARK: - Private Helpers
//
private extension StorePickerCoordinator {

    func showStorePicker() {
        navigationController.pushViewController(setupStorePicker(), animated: true)
    }

    func setupStorePicker() -> StorePickerViewController {
        let pickerVC = storePicker

        switch config {
        case .login:
            // TODO: Setup the store picker for login
            break
        case .switchingStores:
            // TODO: Setup the store picker for switching stores
            break
        }

        return pickerVC
    }

    func logOutOfCurrentStore(onCompletion: (() -> Void)? = nil) {
        StoresManager.shared.removeDefaultStore()

        let group = DispatchGroup()

        group.enter()
        let statsAction = StatsAction.resetStoredStats {
            group.leave()
        }
        StoresManager.shared.dispatch(statsAction)

        group.enter()
        let orderAction = OrderAction.resetStoredOrders {
            group.leave()
        }
        StoresManager.shared.dispatch(orderAction)

        group.notify(queue: .main) {
            onCompletion?()
        }
    }
}
