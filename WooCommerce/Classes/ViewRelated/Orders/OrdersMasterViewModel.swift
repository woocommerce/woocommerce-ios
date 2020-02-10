
import Foundation
import Yosemite

/// Encapsulates data management for `OrdersMasterViewController`.
///
/// ## Always Active
///
/// The corresponding view, `OrdersMaterViewController`, is never deallocated even if the user has
/// already logged out. There are some considerations in this class like `resetStatusPredicate` to
/// accommodate this behavior.
///
final class OrdersMasterViewModel {

    private lazy var storageManager = ServiceLocator.storageManager
    private lazy var stores = ServiceLocator.stores
    private lazy var sessionManager = stores.sessionManager

    /// ResultsController: Handles all things order status
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)
        return ResultsController<StorageOrderStatus>(storageManager: storageManager, sortedBy: [descriptor])
    }()

    /// The current `Site` `siteID`.
    ///
    var siteID: Int64? {
        sessionManager.defaultStoreID
    }

    /// The current list of order statuses for the default site
    ///
    var currentSiteStatuses: [OrderStatus] {
        return statusResultsController.fetchedObjects
    }

    /// Start all the operations that this `ViewModel` is responsible for.
    ///
    /// This should only be called once in the lifetime of `OrdersMasterViewController`.
    ///
    func activate() {
        // Initialize `statusResultsController`
        refreshStatusPredicate()
        try? statusResultsController.performFetch()

        // Listen to notifications
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultAccountWasUpdated), name: .defaultAccountWasUpdated, object: nil)
    }

    /// Fetch all `OrderStatus` from the API
    ///
    func syncOrderStatuses() {
        guard let siteID = siteID else {
            return
        }

        // First, let's verify our FRC predicate is up to date
        refreshStatusPredicate()

        let action = OrderStatusAction.retrieveOrderStatuses(siteID: siteID) { (_, error) in
            if let error = error {
                DDLogError("⛔️ Order List — Error synchronizing order statuses: \(error)")
            }
        }

        stores.dispatch(action)
    }

    /// Runs whenever the default Account is updated.
    ///
    @objc private func defaultAccountWasUpdated() {
        refreshStatusPredicate()
    }

    /// Update the `siteID` predicate of `statusResultsController` to the current `siteID`.
    ///
    private func refreshStatusPredicate() {
        // Bugfix for https://github.com/woocommerce/woocommerce-ios/issues/751.
        // Because we are listening for default account changes,
        // this will also fire upon logging out, when the account
        // is set to nil. So let's protect against multi-threaded
        // access attempts if the account is indeed nil.
        guard stores.isAuthenticated,
            stores.needsDefaultStore == false else {
                return
        }

        statusResultsController.predicate = NSPredicate(format: "siteID == %lld", siteID ?? Int.min)
    }
}
