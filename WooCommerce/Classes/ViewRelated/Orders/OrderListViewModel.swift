import Combine
import Yosemite
import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType

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
        cardPresentPaymentsConfiguration.isSupportedCountry
    }

    private lazy var wcPayIPPOrdersPredicate: NSPredicate = {
        /// In order to filter WCPay transactions processed through IPP we check if these contain `receipt_url`
        /// in their `customFields` metadata, unlike those processed through a website, which don't.
        /// This heuristic can't be relied on for other plugins, so the `paymentMethodID` limit is required.
        NSPredicate(
            format: "siteID == %lld AND paymentMethodID == %@ AND ANY customFields.key == %@",
            argumentArray: [siteID, Constants.wcpayPaymentMethodID, Constants.receiptURLKey]
        )
    }()

    /// Results controller that fetches any WooCommerce Payments In-Person Payments transactions
    ///
    private lazy var wcPayIPPOrdersResultsController: ResultsController<StorageOrder> = {
        return ResultsController<StorageOrder>(storageManager: storageManager, matching: wcPayIPPOrdersPredicate, sortedBy: [])
    }()

    private lazy var last30DaysPredicate: NSPredicate = {
        let today = Date()
        let thirtyDaysBeforeToday = Calendar.current.date(
            byAdding: .day,
            value: -30,
            to: today
        ) ?? Date()
        return NSPredicate(format: "datePaid >= %@", argumentArray: [thirtyDaysBeforeToday])
    }()

    /// Results controller that fetches WooCommerce Payments In-Person Payments within the last 30 days
    ///
    private lazy var recentWCPayIPPResultsController: ResultsController<StorageOrder> = {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [wcPayIPPOrdersPredicate, last30DaysPredicate])

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

    /// If true, no IPP feedback banner will be shown as the user has told us that they are not interested in this information.
    /// It is persisted through app sessions.
    ///
    @Published var hideIPPFeedbackBanner: Bool = true

    @Published var ippSurveySource: SurveyViewController.Source? = nil

    init(siteID: Int64,
         cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         notificationCenter: NotificationCenter = .default,
         filters: FilterOrderListViewModel.Filters?) {
        self.siteID = siteID
        self.cardPresentPaymentsConfiguration = cardPresentPaymentsConfiguration
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
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
        setupWCPayIPPResultsControllers()
        startReceivingSnapshots()

        notificationCenter.addObserver(self, selector: #selector(handleAppDeactivation),
                                       name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleAppActivation),
                                       name: UIApplication.didBecomeActiveNotification, object: nil)

        observeForegroundRemoteNotifications()
        bindTopBannerState()
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

    func updateBannerVisibility() {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.IPPInAppFeedbackBanner) {
            syncIPPBannerVisibility()
            loadOrdersBannerVisibility()
        } else {
            loadOrdersBannerVisibility()
        }
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

    // Requests if the In-Person Payments feedback banner should be shown,
    // in which case we proceed to sync the view model by fetching transactions
    private func syncIPPBannerVisibility() {
        let action = AppSettingsAction.loadFeedbackVisibility(type: .inPersonPayments) { [weak self] visibility in
            switch visibility {
            case .success(let visible):
                self?.hideIPPFeedbackBanner = !visible
                self?.fetchIPPTransactions()
            case .failure(let error):
                self?.hideIPPFeedbackBanner = true
                DDLogError("Couldn't load feedback visibility. \(error)")
            }
        }
        self.stores.dispatch(action)
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
                                 completionHandler: { [weak self] timeInterval, error in
            /// A bit of a side-effect: `onDidChangeContent` is not called for first load
            self?.ippSurveySource = self?.feedbackBannerSurveySource()
            completionHandler(timeInterval, error)
        })
    }

    private func setupWCPayIPPResultsControllers() {
        let updateFeedbackSurveySource = { [weak self] in
            guard let self = self else { return }
            self.ippSurveySource = self.feedbackBannerSurveySource()
        }
        wcPayIPPOrdersResultsController.onDidChangeContent = updateFeedbackSurveySource
        recentWCPayIPPResultsController.onDidChangeContent = updateFeedbackSurveySource

        ippSurveySource = feedbackBannerSurveySource()
    }

    private func fetchIPPTransactions() {
        do {
            try wcPayIPPOrdersResultsController.performFetch()
            try recentWCPayIPPResultsController.performFetch()
        } catch {
            DDLogError("Error fetching IPP transactions: \(error)")
        }
    }

    func trackInPersonPaymentsFeedbackBannerShown(for surveySource: SurveyViewController.Source?) {
        var campaign: FeatureAnnouncementCampaign? = nil

        switch surveySource {
        case .inPersonPaymentsCashOnDelivery:
            campaign = .inPersonPaymentsCashOnDelivery
        case .inPersonPaymentsFirstTransaction:
            campaign = .inPersonPaymentsFirstTransaction
        case .inPersonPaymentsPowerUsers:
            campaign = .inPersonPaymentsPowerUsers
        default:
            break
        }

        guard let campaign = campaign else {
            DDLogError("Couldn't assign a specific campaign for the Survey Source.")
            return
        }

        analytics.track(event: .InPersonPaymentsFeedbackBanner.shown(
            source: .orderList,
            campaign: campaign)
        )
    }

    func feedbackBannerSurveySource() -> SurveyViewController.Source? {
        if isIPPSupportedCountry {
            fetchIPPTransactions()
            let hasWCPayIPPResults = wcPayIPPOrdersResultsController.fetchedObjects.isNotEmpty
            let wcPayIPPResultsCount = wcPayIPPOrdersResultsController.fetchedObjects.count
            let hasRecentWCPayIPPResults = recentWCPayIPPResultsController.fetchedObjects.isNotEmpty
            let recentWCPayIPPResultsCount = recentWCPayIPPResultsController.fetchedObjects.count

            if !hasWCPayIPPResults {
                guard isCODEnabled else {
                    return .none
                }
                // Case 1: No WCPay IPP transactions
                return .inPersonPaymentsCashOnDelivery
            } else if hasRecentWCPayIPPResults && recentWCPayIPPResultsCount < Constants.numberOfTransactions {
                // Case 2: One or more WCPay IPP transactions, but fewer than 10 within the last 30 days
                return .inPersonPaymentsFirstTransaction
            } else if wcPayIPPResultsCount >= Constants.numberOfTransactions {
                // Case 3: More than 10 WCPay IPP transactions
                return .inPersonPaymentsPowerUsers
            }
        }
        return .none
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

// MARK: - In-Person Payments Feedback Banner

extension OrderListViewModel {
    func dismissIPPFeedbackBanner(remindAfterDays: Int?, campaign: FeatureAnnouncementCampaign) {
        //  Updates the IPP feedback banner status as dismissed
        let updateFeedbackStatus = AppSettingsAction.updateFeedbackStatus(type: .inPersonPayments, status: .dismissed) { [weak self] _ in
            self?.hideIPPFeedbackBanner = true
        }
        stores.dispatch(updateFeedbackStatus)

        //  Updates the IPP feedback banner status to be reminded later, or never
        let updateBannerVisibility = AppSettingsAction.setFeatureAnnouncementDismissed(
            campaign: campaign,
            remindAfterDays: remindAfterDays,
            onCompletion: nil
        )
        stores.dispatch(updateBannerVisibility)
    }

    func IPPFeedbackBannerCTATapped(for campaign: FeatureAnnouncementCampaign) {
        analytics.track(
            event: .InPersonPaymentsFeedbackBanner.ctaTapped(
                source: .orderList,
                campaign: campaign
            ))
    }

    func IPPFeedbackBannerRemindMeLaterTapped(for campaign: FeatureAnnouncementCampaign) {
        analytics.track(
            event: .InPersonPaymentsFeedbackBanner.dismissed(
                source: .orderList,
                campaign: campaign,
                remindLater: true)
        )
        dismissIPPFeedbackBanner(remindAfterDays: Constants.remindIPPBannerDismissalAfterDays, campaign: campaign)
    }

    func IPPFeedbackBannerDontShowAgainTapped(for campaign: FeatureAnnouncementCampaign) {
        analytics.track(
            event: .InPersonPaymentsFeedbackBanner.dismissed(
                source: .orderList,
                campaign: campaign,
                remindLater: false)
        )
        dismissIPPFeedbackBanner(remindAfterDays: nil, campaign: campaign)
    }

    func IPPFeedbackBannerWasDismissed(for campaign: FeatureAnnouncementCampaign) {
        dismissIPPFeedbackBanner(remindAfterDays: nil, campaign: campaign)
    }

    func IPPFeedbackBannerWasSubmitted() {
        //  Updates the IPP feedback banner status as given
        let updateFeedbackStatus = AppSettingsAction.updateFeedbackStatus(type: .inPersonPayments, status: .given(Date())) { [weak self] _ in
            self?.hideIPPFeedbackBanner = true
        }
        stores.dispatch(updateFeedbackStatus)

        //  Updates the IPP feedback banner status to not be reminded again
        let updateBannerVisibility = AppSettingsAction.setFeatureAnnouncementDismissed(
            campaign: .inPersonPaymentsPowerUsers,
            remindAfterDays: nil,
            onCompletion: nil
        )
        stores.dispatch(updateBannerVisibility)
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
        let ippSurvey = $ippSurveySource.removeDuplicates()

        Publishers.CombineLatest4(errorState, $hideIPPFeedbackBanner, ippSurvey, $hideOrdersBanners)
            .map { hasError, hasDismissedIPPFeedbackBanner, inPersonPaymentsSurvey, hasDismissedOrdersBanners -> TopBanner in

                guard !hasError else {
                    return .error
                }

                if !hasDismissedIPPFeedbackBanner,
                   let inPersonPaymentsSurvey = inPersonPaymentsSurvey {
                    return .inPersonPaymentsFeedback(inPersonPaymentsSurvey)
                }

                return hasDismissedOrdersBanners ? .none : .orderCreation
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
    enum TopBanner: Equatable {
        case error
        case orderCreation
        case inPersonPaymentsFeedback(SurveyViewController.Source)
        case none

        static func ==(lhs: TopBanner, rhs: TopBanner) -> Bool {
            switch (lhs, rhs) {
            case (.error, .error),
                (.orderCreation, .orderCreation),
                (.none, .none):
                return true
            case (.inPersonPaymentsFeedback(let lhsSource), .inPersonPaymentsFeedback(let rhsSource)):
                return lhsSource == rhsSource
            default:
                return false
            }
        }
    }
}

// MARK: IPP feedback constants
private extension OrderListViewModel {
    enum Constants {
        static let wcpayPaymentMethodID = "woocommerce_payments"
        static let receiptURLKey = "receipt_url"
        static let numberOfTransactions = 10
        static let remindIPPBannerDismissalAfterDays = 7
    }
}
