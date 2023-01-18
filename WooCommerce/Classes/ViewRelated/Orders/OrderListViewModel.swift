import Combine
import Yosemite
import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType

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
    private var foregroundNotificationsSubscription: AnyCancellable?

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

    private var isCODEnabled: Bool {
        guard let codGateway = storageManager.viewStorage.loadPaymentGateway(siteID: siteID, gatewayID: "cod")?.toReadOnly() else {
            return false
        }
        return codGateway.enabled
    }

    private var isIPPSupportedCountry: Bool {
        CardPresentConfigurationLoader().configuration.isSupportedCountry
    }

    /// Results controller that fetches any IPP transactions via WooCommerce Payments
    ///
    private lazy var IPPOrdersResultsController: ResultsController<StorageOrder> = {
        let paymentGateway = Constants.paymentMethodID
        let predicate = NSPredicate(
            format: "siteID == %lld AND paymentMethodID == %@",
            argumentArray: [siteID, paymentGateway]
        )
        return ResultsController<StorageOrder>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    /// Results controller that fetches IPP transactions via WooCommerce Payments, within the last 30 days
    ///
    private lazy var recentIPPOrdersResultsController: ResultsController<StorageOrder> = {
        let today = Date()
        let paymentGateway = Constants.paymentMethodID
        let thirtyDaysBeforeToday = Calendar.current.date(
            byAdding: .day,
            value: -30,
            to: today
        ) ?? Date()

        let predicate = NSPredicate(
            format: "siteID == %lld AND paymentMethodID == %@ AND datePaid >= %@",
            argumentArray: [siteID, paymentGateway, thirtyDaysBeforeToday]
        )

        return ResultsController<StorageOrder>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

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

    /// If true, no orders banner will be shown as the user has told us that they are not interested in this information.
    /// It is persisted through app sessions.
    ///
    @Published var hideOrdersBanners: Bool = true

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
        loadOrdersBannerVisibility()

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.IPPInAppFeedbackBanner) {
            fetchIPPTransactions()
        }
    }

    func dismissOrdersBanner() {
        let action = AppSettingsAction.updateFeedbackStatus(type: .ordersCreation,
                                               status: .dismissed) { [weak self] result in
            if let error = result.failure {
                ServiceLocator.crashLogging.logError(error)
            }

            self?.hideOrdersBanners = true
        }

        stores.dispatch(action)
    }

    /// Starts the snapshotsProvider, logging any errors.
    private func startReceivingSnapshots() {
        do {
            try snapshotsProvider.start()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    private func loadOrdersBannerVisibility() {
        let action = AppSettingsAction.loadFeedbackVisibility(type: .ordersCreation) { [weak self] result in
            switch result {
            case .success(let visible):
                self?.hideOrdersBanners = !visible
            case.failure(let error):
                self?.hideOrdersBanners = true
                ServiceLocator.crashLogging.logError(error)
            }
        }

        stores.dispatch(action)
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

    private func fetchIPPTransactions() {
        do {
            try IPPOrdersResultsController.performFetch()
            try recentIPPOrdersResultsController.performFetch()
        } catch {
            DDLogError("Error fetching IPP transactions: \(error)")
        }
    }

    func displayIPPFeedbackBannerIfEligible() {
        if isCODEnabled && isIPPSupportedCountry {
            let hasResults = IPPOrdersResultsController.fetchedObjects.isEmpty ? false : true
            let IPPresultsCount = IPPOrdersResultsController.fetchedObjects.count

            /// In order to filter WCPay transactions processed through IPP within the last 30 days,
            /// we check if these contain `receipt_url` in their metadata, unlike those processed through a website,
            /// which doesn't
            ///
            let recentIPPTransactionsFound = recentIPPOrdersResultsController.fetchedObjects.filter({
                $0.customFields.contains(where: {$0.key == Constants.receiptURLKey }) &&
                $0.paymentMethodTitle == Constants.paymentMethodTitle})
            let recentIPPresultsCount = recentIPPTransactionsFound.count

            // TODO: Debug. Remove before merging
            print("COD enabled? \(isCODEnabled) - Eligible Country? \(isIPPSupportedCountry)")
            print("hasResults? \(hasResults)")
            print("IPP transactions (all): \(IPPresultsCount)")
            print("IPP transactions within 30 days: \(recentIPPresultsCount)")
            print(recentIPPOrdersResultsController.fetchedObjects.map {
                ("OrderID: \($0.orderID) - PaymentMethodID: \($0.paymentMethodID) (\($0.paymentMethodTitle) - DatePaid: \(String(describing: $0.datePaid))")
            })

            if !hasResults {
                 print("0 transactions. Banner 1 shown")
             } else if IPPresultsCount < Constants.numberOfTransactions {
                 print("< 10 transactions (all). Banner 2 shown")
             } else if recentIPPresultsCount >= Constants.numberOfTransactions {
                 print(">= 10 transactions within 30 days. Banner 3 shown")
             }
        }
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
        foregroundNotificationsSubscription = pushNotificationsManager.foregroundNotifications.sink { [weak self] notification in
            guard notification.kind == .storeOrder else {
                return
            }

            self?.onShouldResynchronizeIfViewIsVisible?()
        }
    }

    func stopObservingForegroundRemoteNotifications() {
        foregroundNotificationsSubscription?.cancel()
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

// MARK: - Banners

extension OrderListViewModel {
    /// Figures out what top banner should be shown based on the view model internal state.
    ///
    private func bindTopBannerState() {
        let errorState = $hasErrorLoadingData.removeDuplicates()

        Publishers.CombineLatest(errorState, $hideOrdersBanners)
            .map { hasError, hasDismissedOrdersBanners  -> TopBanner in

                if hasError {
                    return .error
                }

                if hasDismissedOrdersBanners {
                    return .none
                }

                return .orderCreation
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
        case orderCreation
        case none
    }
}

// MARK: IPP feedback constants
private extension OrderListViewModel {
    enum Constants {
        static let paymentMethodID = "woocommerce_payments"
        static let paymentMethodTitle = "WooCommerce In-Person Payments"
        static let receiptURLKey = "receipt_url"
        static let numberOfTransactions = 10
    }
}
