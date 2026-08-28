import Combine
import Foundation
import UIKit
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
    private let selectedSiteSettings: SelectedSiteSettingsProtocol

    /// Used for cancelling the observer for Remote Notifications when `self` is deallocated.
    ///
    private var foregroundNotificationsSubscription: AnyCancellable?

    /// Emits when the stored order statuses change, so visible cells can be refreshed.
    ///
    private let statusesDidChangeSubject = PassthroughSubject<Void, Never>()

    /// Publisher that fires when the stored order statuses change.
    ///
    var statusesDidChange: AnyPublisher<Void, Never> {
        statusesDidChangeSubject.eraseToAnyPublisher()
    }

    /// The block called if self requests a resynchronization of the first page.
    ///
    var onShouldResynchronize: ((OrderListSyncActionUseCase.SyncReason) -> Void)?

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

    /// Minimum quiet period before a burst of order notifications triggers a single resynchronization.
    ///
    private let pushNotificationSyncInterval: DispatchQueue.SchedulerTimeType.Stride

    private let snapshotsProvider: FetchResultSnapshotsProvider<StorageOrder>

    /// Emits snapshots of orders that should be displayed in the table view.
    var snapshot: AnyPublisher<FetchResultSnapshot, Never> {
        snapshotsProvider.snapshot
    }

    /// Set when sync fails, and used to display the corresponding error loading data banner
    ///
    @Published var dataLoadingError: Error? = nil {
        didSet { updateTopBanner() }
    }

    /// Determines what top banner should be shown
    ///
    @Published private(set) var topBanner: TopBanner = .none

    private var siteSettingsSubscription: AnyCancellable?

    init(siteID: Int64,
         cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         notificationCenter: NotificationCenter = .default,
         pushNotificationSyncInterval: DispatchQueue.SchedulerTimeType.Stride = .seconds(1),
         filters: FilterOrderListViewModel.Filters?,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         selectedSiteSettings: SelectedSiteSettingsProtocol = ServiceLocator.selectedSiteSettings) {
        self.siteID = siteID
        self.cardPresentPaymentsConfiguration = cardPresentPaymentsConfiguration
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.pushNotificationsManager = pushNotificationsManager
        self.notificationCenter = notificationCenter
        self.pushNotificationSyncInterval = pushNotificationSyncInterval
        self.filters = filters
        self.featureFlagService = featureFlagService
        self.selectedSiteSettings = selectedSiteSettings
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
        onShouldResynchronize?(.viewWillAppear)
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

    private static func createQuery(siteID: Int64,
                                     filters: FilterOrderListViewModel.Filters?) -> FetchResultSnapshotsProvider<StorageOrder>.Query {
        let predicateStatus: NSPredicate = {
            let excludeSearchCache = NSPredicate(format: "exclusiveForSearch = false")
            let excludeNonMatchingStatus = filters?.orderStatus.map { statuses in
                return NSPredicate(format: "statusKey IN %@", statuses.map { $0.rawValue })
            }

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

        let predicateSalesChannel: NSPredicate? = {
            guard let salesChannelFilter = filters?.salesChannel else {
                return nil
            }

            switch salesChannelFilter {
            case .pointOfSale:
                return NSPredicate(format: "createdVia == %@", "pos-rest-api")
            case .webCheckout:
                return NSPredicate(format: "createdVia IN %@", ["checkout", "store-api"])
            case .wpAdmin:
                return NSPredicate(format: "createdVia == %@", "admin")
            case .any:
                return nil
            }
        }()

        let siteIDPredicate = NSPredicate(format: "siteID = %lld", siteID)
        let allPredicates = [siteIDPredicate, predicateStatus, predicateDateRanges, predicateSalesChannel].compactMap { $0 }
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: allPredicates)

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
    /// A refresh will be requested when receiving them. Notifications for other stores are ignored,
    /// and a burst of new orders is coalesced into a single resynchronization rather than one per
    /// notification.
    ///
    func observeForegroundRemoteNotifications() {
        foregroundNotificationsSubscription = pushNotificationsManager.foregroundNotifications
            .filter { [weak self] notification in
                guard let self, notification.kind == .storeOrder else {
                    return false
                }
                return notification.resolvedSiteID(stores: stores) == siteID
            }
            .debounce(for: pushNotificationSyncInterval, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onShouldResynchronize?(.pushNotification)
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
        statusResultsController.onDidChangeContent = { [weak self] in
            self?.statusesDidChangeSubject.send()
        }
        statusResultsController.onDidResetContent = { [weak self] in
            self?.statusesDidChangeSubject.send()
        }

        do {
            try statusResultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }
}

// MARK: - Banners

extension OrderListViewModel {
    /// Sets up the header banner. The header has a single banner slot, fed by two independent inputs: the orders
    /// load error (`dataLoadingError`, via its `didSet`) and the store-currency state (site settings, via the sink
    /// below). Both call `updateTopBanner()`, which owns the precedence between them.
    ///
    private func bindTopBannerState() {
        siteSettingsSubscription = selectedSiteSettings.settingsStream
            .sink { [weak self] _ in
                self?.updateTopBanner()
            }
        updateTopBanner()
    }

    /// Resolves the header's single banner slot: a data-loading error takes precedence over the currency warning.
    ///
    private func updateTopBanner() {
        let banner: TopBanner
        if let dataLoadingError {
            banner = .error(dataLoadingError)
        } else if selectedSiteSettings.isUsingFallbackCurrency {
            banner = .currencyUnavailable
        } else {
            banner = .none
        }

        if banner != topBanner {
            topBanner = banner
        }
    }

    /// Re-syncs general site settings so the store currency can be resolved. The banner is hidden immediately;
    /// once the sync completes, `settingsStream` re-emits and the banner re-appears if the currency is still
    /// unavailable.
    ///
    func retryStoreCurrencySync() {
        topBanner = .none

        let action = SettingAction.synchronizeGeneralSiteSettings(siteID: siteID) { [weak self] error in
            guard let self else { return }
            if let error {
                DDLogError("⛔️ Retrying store currency sync failed for siteID \(self.siteID): \(error)")
            }
            self.selectedSiteSettings.refresh()
        }
        stores.dispatch(action)
    }
}

// MARK: - TableView Support

extension OrderListViewModel {

    /// Creates an `OrderListCellViewModel` for the `Order` pointed to by `objectID`.
    func cellViewModel(withID objectID: FetchResultSnapshotObjectID) -> OrderListCellViewModel? {
        guard let order = snapshotsProvider.object(withID: objectID) else {
            return nil
        }

        return OrderListCellViewModel(order: order,
                                      currencySettings: ServiceLocator.currencySettings,
                                      siteStatuses: currentSiteStatuses)
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
        case currencyUnavailable
        case none

        static func ==(lhs: TopBanner, rhs: TopBanner) -> Bool {
            switch (lhs, rhs) {
            case let (.error(lhsError), .error(rhsError)):
                // Compare the payloads so that a different error re-renders the banner (which shows
                // error-specific title/info), while repeated identical errors still dedup to avoid churn.
                return (lhsError as NSError).domain == (rhsError as NSError).domain
                    && (lhsError as NSError).code == (rhsError as NSError).code
            case (.currencyUnavailable, .currencyUnavailable),
                (.none, .none):
                return true
            default:
                return false
            }
        }
    }
}
