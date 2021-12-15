import Combine
import Yosemite
import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType
import Observables
import Combine

/// ViewModel for `OrderListViewController`.
///
/// This is an incremental WIP. Eventually, we should move all the data loading in here.
///
/// Important: The `OrdersViewController` **owned** by `OrdersTabbedViewController` currently
/// does not get deallocated when switching sites. This `ViewModel` should consider that and not
/// keep site-specific information as much as possible. For example, we shouldn't keep `siteID`
/// in here but grab it from the `SessionManager` when we need it. Hopefully, we will be able to
/// fix this in the future.
///
/// ## Work In Progress
///
/// This does not do anything at the moment. We will integrate `FetchResultsSnapshotsProvider`
/// in here next.
///
final class OrderListViewModel {
    private let stores: StoresManager
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

    /// The block called if new filters are applied
    ///
    var onShouldResynchronizeIfNewFiltersAreApplied: (() -> ())?

    /// Filters applied to the order list.
    ///
    private(set) var filters: FilterOrderListViewModel.Filters? {
        didSet {
            if filters != oldValue {
                onShouldResynchronizeIfNewFiltersAreApplied?()
            }
        }
    }

    private let siteID: Int64

    /// Used for tracking whether the app was _previously_ in the background.
    ///
    private var isAppActive: Bool = true

    /// Used for looking up the `OrderStatus` to show in the `OrderTableViewCell`.
    ///
    /// The `OrderStatus` data is fetched from the API by `OrdersTabbedViewModel`.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)
        let predicate = NSPredicate(format: "siteID == %lld", siteID)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// The current list of order statuses for the default site
    ///
    private var currentSiteStatuses: [OrderStatus] {
        return statusResultsController.fetchedObjects
    }

    private lazy var snapshotsProvider: FetchResultSnapshotsProvider<StorageOrder> = .init(storageManager: self.storageManager, query: createQuery())

    /// Emits snapshots of orders that should be displayed in the table view.
    var snapshot: AnyPublisher<FetchResultSnapshot, Never> {
        snapshotsProvider.snapshot
    }

    /// Set when sync fails, and used to display an error loading data banner
    ///
    @Published var hasErrorLoadingData: Bool = false

    /// Determines what top banner should be shown
    ///
    @Published private(set) var topBanner: TopBanner = .none

    /// If true, no simple payments banner will be shown as the user has told us that they are not interested in this information.
    /// Resets with every session.
    ///
    @Published var hideSimplePaymentsBanners: Bool = false

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         notificationCenter: NotificationCenter = .default,
         filters: FilterOrderListViewModel.Filters?) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.pushNotificationsManager = pushNotificationsManager
        self.notificationCenter = notificationCenter
        self.filters = filters
    }

    deinit {
        stopObservingForegroundRemoteNotifications()
    }

    /// Start fetching DB results and forward new changes to the given `tableView`.
    ///
    /// This is the main activation method for this ViewModel. This should only be called once.
    /// And only when the corresponding view was loaded.
    ///
    func activate() {
        setupStatusResultsController()
        startReceivingSnapshots()

        notificationCenter.addObserver(self, selector: #selector(handleAppDeactivation),
                                       name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleAppActivation),
                                       name: UIApplication.didBecomeActiveNotification, object: nil)

        observeForegroundRemoteNotifications()
        bindTopBannerState()
    }

    /// Starts the snapshotsProvider, logging any errors.
    private func startReceivingSnapshots() {
        do {
            try snapshotsProvider.start()
        } catch {
            ServiceLocator.crashLogging.logError(error)
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
    func synchronizationAction(siteID: Int64,
                               pageNumber: Int,
                               pageSize: Int,
                               reason: OrderListSyncActionUseCase.SyncReason?,
                               completionHandler: @escaping (TimeInterval, Error?) -> Void) -> OrderAction {
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 filters: filters)
        return useCase.actionFor(pageNumber: pageNumber,
                                 pageSize: pageSize,
                                 reason: reason,
                                 completionHandler: completionHandler)
    }

    private func createQuery() -> FetchResultSnapshotsProvider<StorageOrder>.Query {
        let predicateStatus: NSPredicate = {
            let excludeSearchCache = NSPredicate(format: "exclusiveForSearch = false")
            let excludeNonMatchingStatus = filters?.orderStatus.map { NSPredicate(format: "statusKey IN %@", $0.map { $0.rawValue }) }

            let predicates = [excludeSearchCache, excludeNonMatchingStatus].compactMap { $0 }
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }()

        let predicateDateRanges: NSPredicate = {
            var startDateRangePredicate: NSPredicate?
            if let startDate = filters?.dateRange?.computedStartDate {
                startDateRangePredicate = NSPredicate(format: "dateCreated >= %@", startDate as NSDate)
            }

            var endDateRangePredicate: NSPredicate?
            if let endDate = filters?.dateRange?.computedStartDate {
                endDateRangePredicate = NSPredicate(format: "dateCreated <= %@", endDate as NSDate)
            }

            let predicates = [startDateRangePredicate, endDateRangePredicate].compactMap { $0 }
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }()

        let siteIDPredicate = NSPredicate(format: "siteID = %lld", siteID)
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [siteIDPredicate, predicateStatus, predicateDateRanges])

        return FetchResultSnapshotsProvider<StorageOrder>.Query(
            sortDescriptor: NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false),
            predicate: queryPredicate,
            sectionNameKeyPath: "\(#selector(StorageOrder.normalizedAgeAsString))"
        )
    }

    /// Fetch all `OrderStatus` from the API
    ///
    func syncOrderStatuses() {
        let action = OrderStatusAction.retrieveOrderStatuses(siteID: siteID) { result in
            if case let .failure(error) = result {
                DDLogError("⛔️ Order List — Error synchronizing order statuses: \(error)")
            }
        }

        stores.dispatch(action)
    }

    func updateFilters(filters: FilterOrderListViewModel.Filters?) {
        self.filters = filters
    }
}

// MARK: - Remote Notifications Observation

private extension OrderListViewModel {
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

// MARK: - Order Status

private extension OrderListViewModel {
    /// Setup: Status Results Controller
    ///
    func setupStatusResultsController() {
        do {
            try statusResultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func lookUpOrderStatus(for order: Order) -> OrderStatus? {
        return currentSiteStatuses.first(where: { $0.status == order.status })
    }
}

// MARK: Simple Payments

extension OrderListViewModel {
    /// Figures out what top banner should be shown based on the view model internal state.
    ///
    private func bindTopBannerState() {
        let errorState = $hasErrorLoadingData.removeDuplicates()
        Publishers.CombineLatest(errorState, $hideSimplePaymentsBanners)
            .map { hasError, hasDismissedBanners -> TopBanner in

                guard !hasError else {
                    return .error
                }

                guard !hasDismissedBanners else {
                    return .none
                }
                
                return .simplePaymentsEnabled
            }
            .assign(to: &$topBanner)
    }
}

// MARK: - TableView Support

extension OrderListViewModel {

    /// Creates an `OrderListCellViewModel` for the `Order` pointed to by `objectID`.
    func cellViewModel(withID objectID: FetchResultSnapshotObjectID) -> OrderListCellViewModel? {
        guard let order = snapshotsProvider.object(withID: objectID) else {
            return nil
        }

        let status = lookUpOrderStatus(for: order)

        return OrderListCellViewModel(order: order, status: status)
    }

    /// Creates an `OrderDetailsViewModel` for the `Order` pointed to by `objectID`.
    func detailsViewModel(withID objectID: FetchResultSnapshotObjectID) -> OrderDetailsViewModel? {
        guard let order = snapshotsProvider.object(withID: objectID) else {
            return nil
        }

        return OrderDetailsViewModel(order: order)
    }

    /// Returns the corresponding section title for the given identifier.
    func sectionTitleFor(sectionIdentifier: String) -> String? {
        Age(rawValue: sectionIdentifier)?.description
    }
}

// MARK: Definitions
extension OrderListViewModel {
    /// Possible top banners this view model can show.
    ///
    enum TopBanner {
        case error
        case simplePaymentsEnabled
        case none
    }
}
