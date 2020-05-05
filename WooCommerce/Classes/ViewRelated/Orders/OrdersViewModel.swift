
import Foundation
import Yosemite
import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType

/// ViewModel for `OrdersViewController`.
///
/// This is an incremental WIP. Eventually, we should move all the data loading in here.
///
/// Important: The `OrdersViewController` **owned** by `OrdersMasterViewController` currently
/// does not get deallocated when switching sites. This `ViewModel` should consider that and not
/// keep site-specific information as much as possible. For example, we shouldn't keep `siteID`
/// in here but grab it from the `SessionManager` when we need it. Hopefully, we will be able to
/// fix this in the future.
///
final class OrdersViewModel {
    /// The reasons passed to `SyncCoordinator` when synchronizing.
    ///
    /// We're only currently tracking one reason.
    ///
    enum SyncReason: String {
        case pullToRefresh = "pull_to_refresh"
    }

    /// Configuration for the view if the list is empty.
    struct EmptyStateAttributes {
        let message: String
        let image: UIImage
        let details: String?
        let actionButton: (title: String, url: URL)?
    }

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

    /// If true, orders created after today's day will be included in the result.
    ///
    /// This will generally only be false for the All Orders tab. All other screens should show orders in the future.
    ///
    /// Defaults to `true`.
    ///
    private let includesFutureOrders: Bool

    /// Used for tracking whether the app was _previously_ in the background.
    ///
    private var isAppActive: Bool = true

    /// The configuration to use for the view if the list is empty.
    ///
    let emptyStateAttributes: EmptyStateAttributes

    /// Should be bound to the UITableView to auto-update the list of Orders.
    ///
    private lazy var resultsController: ResultsController<StorageOrder> = {
        let descriptor = NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false)

        let sectionNameKeyPath = #selector(StorageOrder.normalizedAgeAsString)
        let resultsController = ResultsController<StorageOrder>(storageManager: storageManager,
                                                                sectionNameKeyPath: "\(sectionNameKeyPath)",
                                                                sortedBy: [descriptor])
        resultsController.predicate = {
            let excludeSearchCache = NSPredicate(format: "exclusiveForSearch = false")
            let excludeNonMatchingStatus = statusFilter.map { NSPredicate(format: "statusKey = %@", $0.slug) }

            var predicates = [ excludeSearchCache, excludeNonMatchingStatus ].compactMap { $0 }
            if !includesFutureOrders, let nextMidnight = Date().nextMidnight() {
                // Exclude orders on and after midnight of today's date
                let dateSubPredicate = NSPredicate(format: "dateCreated < %@", nextMidnight as NSDate)
                predicates.append(dateSubPredicate)
            }

            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }()

        return resultsController
    }()

    /// Indicates if there are no results.
    ///
    var isEmpty: Bool {
        resultsController.isEmpty
    }

    init(storageManager: StorageManagerType = ServiceLocator.storageManager,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         notificationCenter: NotificationCenter = .default,
         statusFilter: OrderStatus?,
         emptyStateAttributes: EmptyStateAttributes,
         includesFutureOrders: Bool = true) {
        self.storageManager = storageManager
        self.pushNotificationsManager = pushNotificationsManager
        self.notificationCenter = notificationCenter
        self.statusFilter = statusFilter
        self.emptyStateAttributes = emptyStateAttributes
        self.includesFutureOrders = includesFutureOrders
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
    ///
    /// Pulling to refresh on filtered lists, like the Processing tab, will perform 2 network GET
    /// requests:
    ///
    /// 1. Fetch the /orders?status=processed
    /// 2. Fetch the /orders?status=any
    ///
    /// We will also delete all the orders before saving the new fetched ones.
    ///
    /// We are currently doing this to avoid showing stale orders to users (https://git.io/JvMME).
    /// An example scenario is:
    ///
    /// 1. Load the Processing tab.
    /// 2. In the web, change one of the _processing_ orders to a different status (e.g. completed).
    /// 3. Pull to refresh on the Processing tab.
    ///
    /// If we were only doing one query, we would be fetching `GET /orders?status=processed` only.
    /// But that doesn't include the old order which was changed to a different status and is no
    /// longer in the response list. Hence, that updated order will stay on the tab and is stale.
    ///
    ///
    /// ## Why a Dual Fetch
    ///
    /// We could just delete all the orders and perform a single fetch of
    /// `GET /orders?status=processed`. But this could result into the user viewing an incomplete
    /// All Orders tab until we queried again. It's a jarring experience. Consider this scenario:
    ///
    /// 1. Navigate to Processing and All Orders tab to load their content.
    /// 2. Pull to refresh on the Processing tab.
    /// 3. Navigate back to the All Orders tab.
    ///
    /// On Step 3, since we deleted all the orders and only downloaded new processing orders, the
    /// All Orders tab will initially contain just those orders.
    ///
    /// The dual fetch is a "hack" to hide the sceanrio.
    ///
    ///
    /// ## Deleting all the Orders
    ///
    /// This sync strategy doesn't fix all our problems. I'm sure there are other scenarios that
    /// can cause stale data. In fact, synchronization by `pageNumber` almost always has bugs
    /// because orders could be on a different (previous) page when you load the next page. That
    /// order would then end up not getting loaded at all.
    ///
    /// Deleting all the orders during a pull to refresh is a "confidence button" for our users.
    /// When they use this, we are guaranteeing them that they will be viewing an up to date list.
    ///
    ///
    /// ## Spec
    ///
    /// This is how sync behaves on different scenarios.
    ///
    /// | Action           | Current Tab | Delete All | GET ?status=processing | GET ?status=any |
    /// |------------------|-------------|------------|------------------------|-----------------|
    /// | Pull-to-refresh  | Processing  | y          | y                      | y               |
    /// | App activated    | Processing  | .          | y                      | y               |
    /// | `viewWillAppear` | Processing  | .          | y                      | y               |
    /// | Load next page   | Processing  | .          | y                      | .               |
    /// | Pull-to-refresh  | All Orders  | y          | .                      | y               |
    /// | App activated    | All Orders  | .          | .                      | y               |
    /// | `viewWillAppear` | All Orders  | .          | .                      | y               |
    /// | Load next page   | All Orders  | .          | .                      | y               |
    ///
    func synchronizationAction(siteID: Int64,
                               pageNumber: Int,
                               pageSize: Int,
                               reason: SyncReason?,
                               completionHandler: @escaping (Error?) -> Void) -> OrderAction {

        let statusKey = statusFilter?.slug
        let before = includesFutureOrders ? nil : Date().nextMidnight()

        if pageNumber == Defaults.pageFirstIndex {
            let deleteAllBeforeSaving = reason == SyncReason.pullToRefresh

            return OrderAction.fetchFilteredAndAllOrders(
                siteID: siteID,
                statusKey: statusKey,
                before: before,
                deleteAllBeforeSaving: deleteAllBeforeSaving,
                pageSize: pageSize,
                onCompletion: completionHandler
            )
        }

        return OrderAction.synchronizeOrders(
            siteID: siteID,
            statusKey: statusKey,
            before: before,
            pageNumber: pageNumber,
            pageSize: pageSize,
            onCompletion: completionHandler
        )
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
    func detailsViewModel(at indexPath: IndexPath) -> OrderDetailsViewModel {
        let order = resultsController.object(at: indexPath)

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
