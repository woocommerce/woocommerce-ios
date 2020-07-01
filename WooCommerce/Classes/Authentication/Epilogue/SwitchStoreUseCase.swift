import UIKit
import Yosemite


/// Simplifies and decouples the store picker from the caller
///
final class SwitchStoreUseCase {

    private let stores: StoresManager
    private let noticePresenter: NoticePresenter

    init(stores: StoresManager, noticePresenter: NoticePresenter) {
        self.stores = stores
        self.noticePresenter = noticePresenter
    }

    /// A static method which allows easily to switch store
    ///
    func switchStore(with storeID: Int64, onCompletion: @escaping SelectStoreClosure) {
        guard storeID != stores.sessionManager.defaultStoreID else {
            //onCompletion()
            return
        }

        logOutOfCurrentStore { [weak self] in
            self?.finalizeStoreSelection(storeID)

            // Reload orders badge
            NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
            onCompletion()
        }
    }

    /// Do all the operations to log out from the current selected store, mantaining the Authentication
    ///
    private func logOutOfCurrentStore(onCompletion: @escaping () -> Void) {
        guard stores.sessionManager.defaultStoreID != nil else {
            return onCompletion()
        }

        stores.removeDefaultStore()

        // Note: We are not deleting products here because products from multiple sites
        // can exist in Storage simultaneously. Eventually we should make orders and stats
        // behave this way. See https://github.com/woocommerce/woocommerce-ios/issues/279
        // for more details.
        let group = DispatchGroup()

        group.enter()
        let statsAction = StatsAction.resetStoredStats {
            group.leave()
        }
        stores.dispatch(statsAction)

        group.enter()
        let statsV4Action = StatsActionV4.resetStoredStats {
            group.leave()
        }
        stores.dispatch(statsV4Action)

        group.enter()
        let orderAction = OrderAction.resetStoredOrders {
            group.leave()
        }
        stores.dispatch(orderAction)

        group.enter()
        let reviewAction = ProductReviewAction.resetStoredProductReviews {
            group.leave()
        }
        stores.dispatch(reviewAction)

        group.notify(queue: .main) {
            onCompletion()
        }
    }

    /// Part of the switch store selection. This method will update the new default store selected.
    ///
    private func finalizeStoreSelection(_ storeID: Int64) {
        stores.updateDefaultStore(storeID: storeID)

        // We need to call refreshUserData() here because the user selected
        // their default store and tracks should to know about it.
        ServiceLocator.analytics.refreshUserData()
        ServiceLocator.analytics.track(.sitePickerContinueTapped,
                                  withProperties: ["selected_store_id": stores.sessionManager.defaultStoreID ?? String()])

        AppDelegate.shared.authenticatorWasDismissed()
    }
}
