import UIKit
import Yosemite

final class SwitchStoreUseCase {
    /// A static method which allows easily to switch store
    ///
    static func switchStore(with storeID: Int64, onCompletion: @escaping SelectStoreClosure) {
        guard storeID != ServiceLocator.stores.sessionManager.defaultStoreID else {
            onCompletion()
            return
        }

        SwitchStoreUseCase.logOutOfCurrentStore {
            finalizeStoreSelection(storeID, configuration: .switchingStores)
            presentStoreSwitchedNotice(configuration: .switchingStores)

            // Reload orders badge
            NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
            onCompletion()
        }
    }
    
    static func logOutOfCurrentStore(onCompletion: @escaping () -> Void) {
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
    
    static func presentStoreSwitchedNotice(configuration: StorePickerConfiguration) {
        guard configuration == .switchingStores else {
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

    static func finalizeStoreSelection(_ storeID: Int64, configuration: StorePickerConfiguration) {
        ServiceLocator.stores.updateDefaultStore(storeID: storeID)

        // We need to call refreshUserData() here because the user selected
        // their default store and tracks should to know about it.
        ServiceLocator.analytics.refreshUserData()
        ServiceLocator.analytics.track(.sitePickerContinueTapped,
                                  withProperties: ["selected_store_id": ServiceLocator.stores.sessionManager.defaultStoreID ?? String()])

        AppDelegate.shared.authenticatorWasDismissed()
        if configuration == .login {
            MainTabBarController.switchToMyStoreTab(animated: true)
        }
    }
}
