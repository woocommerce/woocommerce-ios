
import Foundation
import Yosemite

/// Encapsulates data management for `OrdersMasterViewController`.
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

    /// The current `storeID`.
    ///
    var storeID: Int64? {
        sessionManager.defaultStoreID
    }

    /// The current list of order statuses for the default site
    ///
    var currentSiteStatuses: [OrderStatus] {
        return statusResultsController.fetchedObjects
    }

    /// The current `OrderStatus` to filter by.
    ///
    /// If the this is `nil`, that means that all orders should be shown. The `statusFilterChanged`
    /// callback will be called whenever this is changed.
    ///
    var statusFilter: OrderStatus? {
        didSet {
            statusFilterChanged(statusFilter)
        }
    }

    /// Called whenever `statusFilter` is changed.
    ///
    private let statusFilterChanged: (OrderStatus?) -> ()

    /// Designated initializer.
    ///
    init(statusFilterChanged: @escaping (OrderStatus?) -> ()) {
        self.statusFilterChanged = statusFilterChanged
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
        nc.addObserver(self, selector: #selector(stopListeningToNotifications), name: .logOutEventReceived, object: nil)
    }

    /// Fetch all `OrderStatus` from the API
    ///
    func syncOrderStatuses() {
        resetStatusFilterIfNeeded()

        guard let siteID = storeID else {
            return
        }

        // First, let's verify our FRC predicate is up to date
        refreshStatusPredicate()

        let action = OrderStatusAction.retrieveOrderStatuses(siteID: siteID) { [weak self] (_, error) in
            if let error = error {
                DDLogError("⛔️ Order List — Error synchronizing order statuses: \(error)")
            }

            self?.resetStatusFilterIfNeeded()
        }

        stores.dispatch(action)
    }

    /// Runs whenever the default Account is updated.
    ///
    @objc private func defaultAccountWasUpdated() {
        statusFilter = nil
        refreshStatusPredicate()
    }

    /// Stops listening to all related Notifications
    ///
    @objc private func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
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

        statusResultsController.predicate = NSPredicate(format: "siteID == %lld", storeID ?? Int.min)
    }

    /// Reset the current status filter if needed (e.g. when changing stores and the currently
    /// selected filter does not exist in the new store)
    ///
    func resetStatusFilterIfNeeded() {
        guard let statusFilter = statusFilter else {
            // "All" is the current filter so bail
            return
        }
        guard currentSiteStatuses.isEmpty == false else {
            self.statusFilter = nil
            return
        }

        if !currentSiteStatuses.contains(where: { $0.name == statusFilter.name && $0.slug == statusFilter.slug }) {
            self.statusFilter = nil
        }
    }
}
