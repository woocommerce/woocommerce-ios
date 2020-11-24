
import Foundation
import Yosemite
import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType

/// ViewModel for `OrdersViewController`.
///
/// This is an incremental WIP. Eventually, we should move all the data loading in here.
///
/// Important: The `OrdersViewController` **owned** by `OrdersTabbedViewController` currently
/// does not get deallocated when switching sites. This `ViewModel` should consider that and not
/// keep site-specific information as much as possible. For example, we shouldn't keep `siteID`
/// in here but grab it from the `SessionManager` when we need it. Hopefully, we will be able to
/// fix this in the future.
///
/// ## Deprecated
///
/// This will be replaced with `OrderListViewModel` when the minimum iOS version is 13.0.
///
final class OrdersViewModel {

    private let storageManager: StorageManagerType
    private let pushNotificationsManager: PushNotesManager
    private let notificationCenter: NotificationCenter

    /// Used for cancelling the observer for Remote Notifications when `self` is deallocated.
    ///
    private var cancellable: ObservationToken?

    /// The block called if self requests a resynchronization of the first page. The
    /// resynchronization should only be done if the view is visible.
    ///
    var onShouldResynchronizeIfViewIsVisible: (() -> ())?

    /// OrderStatus that must be matched by retrieved orders.
    ///
    let statusFilter: OrderStatus?

    /// Used for tracking whether the app was _previously_ in the background.
    ///
    private var isAppActive: Bool = true

    /// Should be bound to the UITableView to auto-update the list of Orders.
    ///
    private lazy var resultsController: ResultsController<StorageOrder> = {
        let descriptor = NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false)
        let sectionNameKeyPath = #selector(StorageOrder.normalizedAgeAsString)
        return ResultsController<StorageOrder>(storageManager: storageManager,
                                               sectionNameKeyPath: "\(sectionNameKeyPath)",
                                               sortedBy: [descriptor])
    }()

    /// Indicates if there are no results.
    ///
    var isEmpty: Bool {
        resultsController.isEmpty
    }

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         notificationCenter: NotificationCenter = .default,
         statusFilter: OrderStatus?,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.pushNotificationsManager = pushNotificationsManager
        self.notificationCenter = notificationCenter
        self.statusFilter = statusFilter
        self.stores = stores
    }

    deinit {
        stopObservingForegroundRemoteNotifications()
    }

    /// Start fetching DB results and forward new changes to the given `tableView`.
    ///
    /// This is the main activation method for this ViewModel. This should only be called once.
    /// And only when the corresponding view was loaded.
    ///
    func activateAndForwardUpdates(to tableView: UITableView) {
        resultsController.predicate = createResultsControllerPredicate()
        resultsController.startForwardingEvents(to: tableView)
        performFetch()

        notificationCenter.addObserver(self, selector: #selector(handleAppDeactivation),
                                       name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleAppActivation),
                                       name: UIApplication.didBecomeActiveNotification, object: nil)

        observeForegroundRemoteNotifications()
    }

    /// Execute the `resultsController` query, logging the error if there's any.
    ///
    private func performFetch() {
        do {
            try resultsController.performFetch()
        } catch {
            CrashLogging.logError(error)
        }
    }

    private func createResultsControllerPredicate() -> NSPredicate {
        let predicate: NSPredicate = {
            let excludeSearchCache = NSPredicate(format: "exclusiveForSearch = false")
            let excludeNonMatchingStatus = statusFilter.map { NSPredicate(format: "statusKey = %@", $0.slug) }

            let predicates = [ excludeSearchCache, excludeNonMatchingStatus ].compactMap { $0 }

            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }()

        let siteIDPredicate = NSPredicate(format: "siteID = %lld", siteID)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [siteIDPredicate, predicate])
    }

    @objc private func handleAppDeactivation() {
        isAppActive = false
    }

    /// Request a resynchornization if the app was previously in the background.
    ///
    @objc private func handleAppActivation() {
        guard !isAppActive else {
            return
        }

        isAppActive = true
        onShouldResynchronizeIfViewIsVisible?()
    }

    /// Returns what `OrderAction` should be used when synchronizing.
    func synchronizationAction(siteID: Int64,
                               pageNumber: Int,
                               pageSize: Int,
                               reason: OrderListSyncActionUseCase.SyncReason?,
                               completionHandler: @escaping (Error?) -> Void) -> OrderAction {
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 statusFilter: statusFilter)
        return useCase.actionFor(pageNumber: pageNumber,
                                 pageSize: pageSize,
                                 reason: reason,
                                 completionHandler: completionHandler)
    }
}

// MARK: - Remote Notifications Observation

private extension OrdersViewModel {
    /// Watch for "new order" Remote Notifications that are received while the app is in the
    /// foreground.
    ///
    /// A refresh will be requested when receiving them.
    ///
    func observeForegroundRemoteNotifications() {
        cancellable = pushNotificationsManager.foregroundNotifications.subscribe { [weak self] notification in
            guard notification.kind == .storeOrder else {
                return
            }

            self?.onShouldResynchronizeIfViewIsVisible?()
        }
    }

    func stopObservingForegroundRemoteNotifications() {
        cancellable?.cancel()
    }
}

// MARK: - TableView Support

extension OrdersViewModel {
    /// Returns an `OrdersViewModel` instance for the `StorageOrder` at the given `indexPath`.
    ///
    /// TODO Ideally we should have a very tiny ViewModel for the cell instead of
    /// `OrderDetailsViewModel` which is used in `OrderDetailsViewController` too.
    ///
    func detailsViewModel(at indexPath: IndexPath) -> OrderDetailsViewModel? {
        guard let order = resultsController.safeObject(at: indexPath) else {
            return nil
        }

        return OrderDetailsViewModel(order: order)
    }

    /// The number of DB results
    ///
    var numberOfObjects: Int {
        resultsController.numberOfObjects
    }

    /// Converts the `rowIndexPath` to an `index` belonging to `numberOfObjects`.
    ///
    func objectIndex(from rowIndexPath: IndexPath) -> Int {
        resultsController.objectIndex(from: rowIndexPath)
    }

    /// The number of sections that should be displayed
    ///
    var numberOfSections: Int {
        resultsController.sections.count
    }

    /// Returns the number of rows in the given `section` index.
    ///
    func numberOfRows(in section: Int) -> Int {
        resultsController.sections[section].numberOfObjects
    }

    /// Returns the `SectionInfo` for the given section index.
    ///
    func sectionInfo(at index: Int) -> ResultsController<StorageOrder>.SectionInfo {
        resultsController.sections[index]
    }
}

// MARK: - Constants

extension OrdersViewModel {
    enum Defaults {
        static let pageFirstIndex = SyncingCoordinator.Defaults.pageFirstIndex
    }
}
