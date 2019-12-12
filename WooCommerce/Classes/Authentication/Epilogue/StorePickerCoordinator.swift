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
        guard storeID != ServiceLocator.stores.sessionManager.defaultStoreID else {
            onCompletion()
            return
        }

        logOutOfCurrentStore(onCompletion: onCompletion)
    }

    func didSelectStore(with storeID: Int) {
        guard storeID != ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        finalizeStoreSelection(storeID)
        presentStoreSwitchedNotice()

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
            navigationController.present(wrapper, animated: true)
        case .switchingStores:
            let wrapper = UINavigationController(rootViewController: storePicker)
            navigationController.present(wrapper, animated: true)
        default:
            navigationController.pushViewController(storePicker, animated: true)
        }
    }

    func presentStoreSwitchedNotice() {
        guard selectedConfiguration == .switchingStores else {
            return
        }
        guard let newStoreName = ServiceLocator.stores.sessionManager.defaultSite?.name else {
            return
        }

        let message = NSLocalizedString("Switched to \(newStoreName). You will only receive notifications from this store.",
            comment: "Message presented after users switch to a new store. "
                + "Reads like: Switched to {store name}. You will only receive notifications from this store.")
        let notice = Notice(title: message, feedbackType: .success)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    func logOutOfCurrentStore(onCompletion: @escaping () -> Void) {
        ServiceLocator.stores.removeDefaultStore()

        // Note: We are not deleting products here because products from multiple sites
        // can exist in Storage simultaneously. Eventually we should make orders and stats
        // behave this way. See https://github.com/woocommerce/woocommerce-ios/issues/279
        // for more details.
        let group = DispatchGroup()

        group.enter()
        let statsAction = StatsAction.resetStoredStats {
            group.leave()
        }
        ServiceLocator.stores.dispatch(statsAction)

        group.enter()
        let statsV4Action = StatsActionV4.resetStoredStats {
            group.leave()
        }
        ServiceLocator.stores.dispatch(statsV4Action)

        group.enter()
        let orderAction = OrderAction.resetStoredOrders {
            group.leave()
        }
        ServiceLocator.stores.dispatch(orderAction)

        group.enter()
        let reviewAction = ProductReviewAction.resetStoredProductReviews {
            group.leave()
        }
        ServiceLocator.stores.dispatch(reviewAction)

        group.notify(queue: .main) {
            onCompletion()
        }
    }

    func finalizeStoreSelection(_ storeID: Int) {
        ServiceLocator.stores.updateDefaultStore(storeID: storeID)

        // We need to call refreshUserData() here because the user selected
        // their default store and tracks should to know about it.
        ServiceLocator.analytics.refreshUserData()
        ServiceLocator.analytics.track(.sitePickerContinueTapped,
                                  withProperties: ["selected_store_id": ServiceLocator.stores.sessionManager.defaultStoreID ?? String()])

        AppDelegate.shared.authenticatorWasDismissed()
        if selectedConfiguration == .login {
            MainTabBarController.switchToMyStoreTab(animated: true)
        }
    }
}
