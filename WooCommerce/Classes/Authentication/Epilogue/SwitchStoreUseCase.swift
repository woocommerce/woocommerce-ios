import UIKit
import Yosemite
import protocol Storage.StorageManagerType

protocol SwitchStoreUseCaseProtocol {
    func switchStore(with storeID: Int64, onCompletion: @escaping (Bool) -> Void)
}

/// Simplifies and decouples the store picker from the caller
///
final class SwitchStoreUseCase: SwitchStoreUseCaseProtocol {

    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let zendeskShared: ZendeskManagerProtocol = ZendeskProvider.shared

    private lazy var resultsController: ResultsController<StorageSite> = {
        return ResultsController(storageManager: storageManager, sortedBy: [])
    }()

    private var wooCommerceSites: [Site] {
        resultsController.fetchedObjects.filter { $0.isWooCommerceActive == true }
    }

    init(stores: StoresManager, storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.stores = stores
        self.storageManager = storageManager
    }

    /// The async version of `switchStore` that wraps the completion block version.
    /// - Parameter storeID: target store ID.
    /// - Returns: a boolean that indicates whether the site was changed.
    @MainActor
    func switchStore(with storeID: Int64) async -> Bool {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else { return }
            self.switchStore(with: storeID) { siteChanged in
                continuation.resume(returning: siteChanged)
            }
        }
    }

    /// Switches the to store with the given id if it was previously synced and stored.
    /// This is done to check whether the user has access to that store, avoiding undetermined states if we log out
    /// from the current one and try to switch to a store they don't have access to.
    ///
    /// - Parameter storeID: target store ID.
    /// - Returns: a boolean that indicates whether the site was changed.
    ///
    func switchToStoreIfSiteIsStored(with storeID: Int64, onCompletion: @escaping (Bool) -> Void) {
        refreshStoredSites()

        let siteWasStored = wooCommerceSites.first(where: { $0.siteID == storeID }) != nil

        guard siteWasStored else {
            return onCompletion(false)
        }

        switchStore(with: storeID, onCompletion: onCompletion)
    }

    /// A static method which allows easily to switch store. The boolean argument in `onCompletion` indicates that the site was changed.
    /// When `onCompletion` is called, the selected site ID is updated while `Site` might still not be available if the site does not exist in storage yet
    /// (e.g. a newly connected site).
    ///
    func switchStore(with storeID: Int64, onCompletion: @escaping (Bool) -> Void) {
        guard storeID != stores.sessionManager.defaultStoreID else {
            onCompletion(false)
            return
        }

        // This method doesn't use `[weak self]` because of this
        // https://github.com/woocommerce/woocommerce-ios/pull/2013#discussion_r454620804
        logOutOfCurrentStore {
            self.finalizeStoreSelection(storeID)
            onCompletion(true)
        }
    }

    /// Do all the operations to log out from the current selected store, maintaining the Authentication
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

        group.enter()
        let resetAction = CardPresentPaymentAction.reset

        stores.dispatch(resetAction)

        group.leave()

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

        let jetpackCPActivePlugins = (stores.sessionManager.defaultSite?.jetpackConnectionActivePlugins ?? []).joined(separator: ",")
        ServiceLocator.analytics.track(.sitePickerContinueTapped,
                                  withProperties: [
                                    "selected_store_id": stores.sessionManager.defaultStoreID ?? String(),
                                    "is_jetpack_cp_connected": stores.sessionManager.defaultSite?.isJetpackCPConnected == true,
                                    "jetpack_cp_active_plugins": jetpackCPActivePlugins
                                  ])

        AppDelegate.shared.authenticatorWasDismissed()
    }

    private func refreshStoredSites() {
        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to refresh stored sites: \(error) ")
        }
    }
}
