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

    func willSelectStore(with storeID: Int, onCompletion: @escaping SelectStoreClosure) {
        guard selectedConfiguration == .switchingStores else {
            onCompletion()
            return
        }

        logOutOfCurrentStore(onCompletion: onCompletion)
    }

    func didSelectStore() {
        finalizeStoreSelection()
        // FIXME: pop the picker VC here!
        onDismiss?()
    }
}

// MARK: - Private Helpers
//
private extension StorePickerCoordinator {

    func showStorePicker() {
        navigationController.pushViewController(storePicker, animated: true)
    }

    func logOutOfCurrentStore(onCompletion: @escaping () -> Void) {
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
            onCompletion()
        }
    }

    func finalizeStoreSelection() {
        // We need to call refreshUserData() here because the user selected
        // their default store and tracks should to know about it.
        WooAnalytics.shared.refreshUserData()
        WooAnalytics.shared.track(.sitePickerContinueTapped, withProperties: ["selected_store_id": StoresManager.shared.sessionManager.defaultStoreID ?? String()])

        AppDelegate.shared.authenticatorWasDismissed()
        if selectedConfiguration == .login {
            MainTabBarController.switchToMyStoreTab(animated: true)
        }
    }
}
