import Foundation
import Yosemite

import class AutomatticTracks.CrashLogging

// MARK: - MainTabViewModel Notifications
//
extension NSNotification.Name {

    /// Posted whenever an OrderBadge refresh is required.
    ///
    public static let ordersBadgeReloadRequired = Foundation.Notification.Name(rawValue: "com.woocommerce.ios.ordersBadgeReloadRequired")

    /// Posted whenever a refresh of Reviews tab is required.
    ///
    public static let reviewsBadgeReloadRequired = Foundation.Notification.Name(rawValue: "com.woocommerce.ios.reviewsBadgeReloadRequired")
}

final class MainTabViewModel {

    private let storesManager: StoresManager

    private var statusResultsController: ResultsController<StorageOrderStatus>?

    init(storesManager: StoresManager = ServiceLocator.stores) {
        self.storesManager = storesManager

        if let siteID = storesManager.sessionManager.defaultStoreID {
            configureOrdersStatusesListener(for: siteID)
        }
    }

    /// Setup: ResultsController for `processing` OrderStatus updates
    ///
    func configureOrdersStatusesListener(for siteID: Int64) {
        statusResultsController = createStatusResultsController(siteID: siteID)
        configureStatusResultsController()
    }

    /// Callback to be executed when this view model receives new data
    /// passing the string to be presented in the badge as a parameter
    ///
    var onBadgeReload: ((String?) -> Void)?

    /// Must be called during `MainTabBarController.viewDidAppear`. This will try and save the
    /// app installation date.
    ///
    func onViewDidAppear() {
        saveInstallationDateIfNecessary()
    }

    /// Bootstrap the data pipeline for the orders badge
    /// Fetches the initial badge count and observes notifications requesting a refresh
    /// The notification observed will be `ordersBadgeReloadRequired`
    ///
    func startObservingOrdersCount() {
        observeBadgeRefreshNotifications()
        updateBadgeFromCache()
        requestBadgeCount()
    }
}


private extension MainTabViewModel {

    /// Construct `ResultsController` with `siteID`
    ///
    func createStatusResultsController(siteID: Int64) -> ResultsController<StorageOrderStatus> {
        let predicate = NSPredicate(format: "siteID == %lld AND slug == %@", siteID, OrderStatusEnum.processing.rawValue)
        return ResultsController<StorageOrderStatus>(storageManager: ServiceLocator.storageManager, matching: predicate, sortedBy: [])
    }

    /// Connect hooks on `ResultsController` and query cached data
    ///
    func configureStatusResultsController() {
        statusResultsController?.onDidChangeObject = { [weak self] (updatedOrdersStatus, _, _, _) in
            self?.processBadgeCount(updatedOrdersStatus)
        }

        try? statusResultsController?.performFetch()
        updateBadgeFromCache()
    }

    /// Get last known data from cache (if exists) and draw it on a badge
    ///
    func updateBadgeFromCache() {
        let initialCachedOrderStatus = statusResultsController?.fetchedObjects.first
        processBadgeCount(initialCachedOrderStatus)
    }

    /// Trigger network action to update underlying cache. Badge redraw will be triggered by `statusResultsController`
    ///
    @objc func requestBadgeCount() {
        guard let siteID = storesManager.sessionManager.defaultStoreID else {
            DDLogError("# Error: Cannot fetch order count")
            return
        }

        let action = OrderStatusAction.retrieveOrderStatuses(siteID: siteID) { result in
            if case let .failure(error) = result {
                DDLogError("⛔️ Could not successfully fetch order statuses for siteID \(siteID): \(error)")
            }
        }

        storesManager.dispatch(action)
    }

    /// Validate `OrderStatus` and trigger badge redraw
    ///
    func processBadgeCount(_ ordersStatus: OrderStatus?) {
        // Exit early if there is not data, or the count is zero
        guard let ordersStatus = ordersStatus,
              ordersStatus.slug == OrderStatusEnum.processing.rawValue,
              ordersStatus.total > 0 else {
            onBadgeReload?(nil)
            return
        }

        onBadgeReload?(NumberFormatter.localizedOrNinetyNinePlus(ordersStatus.total))
    }

    func observeBadgeRefreshNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestBadgeCount),
                                               name: .ordersBadgeReloadRequired,
                                               object: nil)
    }

    /// Persists the installation date if it hasn't been done already.
    func saveInstallationDateIfNecessary() {
        // Unfortunately, our `StoresManager` cannot handle actions (e.g. `AppSettingsAction`) if
        // the user is not logged in. That's because the state will be a `DeauthenticatedState`
        // which just ignores all dispatched actions.
        //
        // So, for now, we will just save the "installation date" if the user is logged in. We
        // currently have no need for this date to be very accurate anyway so I think this is fine.
        //
        // But why do we need to check for `isAuthenticated` anyway? We don't really need too. I
        // just wanted to save a few CPU cycles so `AppSettingsAction.setInstallationDateIfNecessary`
        // is really only dispatched if the user is logged in.
        //
        // Also, note that `MainTabBarController` is **always present and active** even if the
        // user is not logged in. (◞‸◟；)
        guard storesManager.isAuthenticated else {
            return
        }

        let action = AppSettingsAction.setInstallationDateIfNecessary(date: Date()) { result in
            if case let .failure(error) = result {
                ServiceLocator.crashLogging.logError(error)
            }
        }
        storesManager.dispatch(action)
    }
}
