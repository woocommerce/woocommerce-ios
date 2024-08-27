import Combine
import Experiments
import Yosemite
import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// ViewModel for `OrderListViewController`.
///
/// This is an incremental WIP. Eventually, we should move all the data loading in here.
///
final class OrderListViewModel {
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private let pushNotificationsManager: PushNotesManager
    private let notificationCenter: NotificationCenter
    private let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration
    private let featureFlagService: FeatureFlagService

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

    /// URL to site
    var siteURL: URL? {
        guard let site = stores.sessionManager.defaultSite else {
            return nil
        }
        return URL(string: site.url)
    }

    /// Whether the entry point to test order should be displayed on the empty state screen.
    ///
    var shouldEnableTestOrder: Bool {
        guard let site = stores.sessionManager.defaultSite,
              let url = siteURL,
              UIApplication.shared.canOpenURL(url) else {
            return false
        }

        /// Enabled if site is launched, has published at least 1 product and set up payments.
        return (site.visibility == .publicSite) && hasAnyPaymentGateways && hasAnyPublishedProducts
    }

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

    /// Checks whether the site has set up any payment method.
    ///
    private var hasAnyPaymentGateways: Bool {
        storageManager.viewStorage.loadAllPaymentGateways(siteID: siteID)
            .contains(where: { $0.enabled })
    }

    /// Checks whether the site has published any product.
    ///
    private var hasAnyPublishedProducts: Bool {
        (storageManager.viewStorage.loadProducts(siteID: siteID) ?? [])
            .map { $0.toReadOnly() }
            .contains(where: { $0.productStatus == .published })
    }

    private var isIPPSupportedCountry: Bool {
        cardPresentPaymentsConfiguration.isSupportedCountry
    }

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

    private let snapshotsProvider: FetchResultSnapshotsProvider<StorageOrder>

    /// Emits snapshots of orders that should be displayed in the table view.
    var snapshot: AnyPublisher<FetchResultSnapshot, Never> {
        snapshotsProvider.snapshot
    }

    /// Set when sync fails, and used to display the corresponding error loading data banner
    ///
    @Published var dataLoadingError: Error? = nil

    /// Determines what top banner should be shown
    ///
    @Published private(set) var topBanner: TopBanner = .none

    init(siteID: Int64,
         cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         notificationCenter: NotificationCenter = .default,
         filters: FilterOrderListViewModel.Filters?,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.cardPresentPaymentsConfiguration = cardPresentPaymentsConfiguration
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.pushNotificationsManager = pushNotificationsManager
        self.notificationCenter = notificationCenter
        self.filters = filters
        self.featureFlagService = featureFlagService
        self.snapshotsProvider = FetchResultSnapshotsProvider<StorageOrder>(storageManager: storageManager,
                                                                            query: Self.createQuery(siteID: siteID,
                                                                                                    filters: filters))
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

    /// Handles extra syncing upon pull-to-refresh.
    func onPullToRefresh() {
        /// syncs payment gateways
        stores.dispatch(PaymentGatewayAction.synchronizePaymentGateways(siteID: siteID, onCompletion: { _ in }))

        /// syncs first published product
        stores.dispatch(ProductAction.synchronizeProducts(siteID: siteID,
                                                          pageNumber: Store.Default.firstPageNumber,
                                                          pageSize: 1,
                                                          stockStatus: nil,
                                                          productStatus: .published,
                                                          productType: nil,
                                                          productCategory: nil,
                                                          sortOrder: .dateDescending,
                                                          shouldDeleteStoredProductsOnFirstPage: false,
                                                          onCompletion: { _ in }))
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
                               lastFullSyncTimestamp: Date?,
                               completionHandler: @escaping (TimeInterval, Error?) -> Void) -> OrderAction {
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 filters: filters)
        return useCase.actionFor(pageNumber: pageNumber,
                                 pageSize: pageSize,
                                 reason: reason,
                                 lastFullSyncTimestamp: lastFullSyncTimestamp,
                                 completionHandler: { timeInterval, error in
            completionHandler(timeInterval, error)
        })
    }

    private static func createQuery(siteID: Int64, filters: FilterOrderListViewModel.Filters?) -> FetchResultSnapshotsProvider<StorageOrder>.Query {
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
}

// MARK: - Banners

extension OrderListViewModel {
    /// Figures out if should show a data loading error as top banner based on the view model internal state.
    ///
    private func bindTopBannerState() {
        $dataLoadingError
            .map { loadingError -> TopBanner in
                if let error = loadingError {
                    return .error(error)
                } else {
                    return .none
                }
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

        return OrderListCellViewModel(order: order, currencySettings: ServiceLocator.currencySettings)
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

// MARK: - Total completed order count
//
extension OrderListViewModel {
    func totalCompletedOrderCount(pageNumber: Int) -> Int? {
        currentSiteStatuses.first { $0.status == .completed }?.total
    }
}

// MARK: Definitions
extension OrderListViewModel {
    /// Possible top banners this view model can show.
    ///
    enum TopBanner: Equatable {
        case error(Error)
        case none

        static func ==(lhs: TopBanner, rhs: TopBanner) -> Bool {
            switch (lhs, rhs) {
            case (.error, .error),
                (.none, .none):
                return true
            default:
                return false
            }
        }
    }
}
