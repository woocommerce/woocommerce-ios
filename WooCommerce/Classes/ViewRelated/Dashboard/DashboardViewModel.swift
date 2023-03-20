import Yosemite
import Combine
import enum Networking.DotcomError
import enum Storage.StatsVersion
import protocol Experiments.FeatureFlagService

private enum ProductsOnboardingSyncingError: Error {
    case noContentToShow // there is no content to show, because the site is not eligible, it was already shown, or other reason
}

/// Syncs data for dashboard stats UI and determines the state of the dashboard UI based on stats version.
final class DashboardViewModel {
    /// Stats v4 is shown by default, then falls back to v3 if store stats are unavailable.
    @Published private(set) var statsVersion: StatsVersion = .v4

    @Published var announcementViewModel: AnnouncementCardViewModelProtocol? = nil

    var storeOnboardingViewModel: StoreOnboardingViewModel? = nil {
        didSet {
            setupObserverForShowOnboarding()
        }
    }

    @Published private(set) var showWebViewSheet: WebViewSheetViewModel? = nil

    @Published private(set) var showOnboarding: Bool = false

    @Published private(set) var freeTrialBannerViewModel: FreeTrialBannerViewModel? = nil

    /// Trigger to start the Add Product flow
    ///
    let addProductTrigger = PassthroughSubject<Void, Never>()

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let analytics: Analytics
    private let userDefaults: UserDefaults
    private let justInTimeMessagesManager: JustInTimeMessagesProvider
    private var showOnboardingCancellable: AnyCancellable?

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlags: FeatureFlagService = ServiceLocator.featureFlagService,
         analytics: Analytics = ServiceLocator.analytics,
         userDefaults: UserDefaults = .standard) {
        self.stores = stores
        self.featureFlagService = featureFlags
        self.analytics = analytics
        self.justInTimeMessagesManager = JustInTimeMessagesProvider(stores: stores, analytics: analytics)
        self.userDefaults = userDefaults
        setupObserverForShowOnboarding()
    }

    /// Reloads store onboarding tasks
    ///
    func reloadStoreOnboardingTasks() async {
        await storeOnboardingViewModel?.reloadTasks()
    }

    /// Syncs store stats for dashboard UI.
    func syncStats(for siteID: Int64,
                   siteTimezone: TimeZone,
                   timeRange: StatsTimeRangeV4,
                   latestDateToInclude: Date,
                   forceRefresh: Bool,
                   onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardMainStats)
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        let action = StatsActionV4.retrieveStats(siteID: siteID,
                                                 timeRange: timeRange,
                                                 earliestDateToInclude: earliestDateToInclude,
                                                 latestDateToInclude: latestDateToInclude,
                                                 quantity: timeRange.maxNumberOfIntervals,
                                                 forceRefresh: forceRefresh,
                                                 onCompletion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                waitingTracker.end()
                self.statsVersion = .v4
            case .failure(let error):
                DDLogError("⛔️ Dashboard (Order Stats) — Error synchronizing order stats v4: \(error)")
                if error as? DotcomError == .noRestRoute {
                    self.statsVersion = .v3
                } else {
                    self.statsVersion = .v4
                }
            }
            onCompletion?(result)
        })
        stores.dispatch(action)
    }

    /// Syncs visitor stats for dashboard UI.
    func syncSiteVisitStats(for siteID: Int64,
                            siteTimezone: TimeZone,
                            timeRange: StatsTimeRangeV4,
                            latestDateToInclude: Date,
                            onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let action = StatsActionV4.retrieveSiteVisitStats(siteID: siteID,
                                                          siteTimezone: siteTimezone,
                                                          timeRange: timeRange,
                                                          latestDateToInclude: latestDateToInclude,
                                                          onCompletion: { result in
            if case let .failure(error) = result {
                DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
            }
            onCompletion?(result)
        })
        stores.dispatch(action)
    }

    /// Syncs summary stats for dashboard UI.
    func syncSiteSummaryStats(for siteID: Int64,
                              siteTimezone: TimeZone,
                              timeRange: StatsTimeRangeV4,
                              latestDateToInclude: Date,
                              onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let action = StatsActionV4.retrieveSiteSummaryStats(siteID: siteID,
                                                            siteTimezone: siteTimezone,
                                                            period: timeRange.summaryStatsGranularity,
                                                            quantity: 1,
                                                            latestDateToInclude: latestDateToInclude,
                                                            saveInStorage: true) { result in
            if case let .failure(error) = result {
                DDLogError("⛔️ Error synchronizing summary stats: \(error)")
            }

            let voidResult = result.map { _ in () } // Caller expects no entity in the result.
            onCompletion?(voidResult)
        }
        stores.dispatch(action)
    }

    /// Syncs top performers data for dashboard UI.
    func syncTopEarnersStats(for siteID: Int64,
                             siteTimezone: TimeZone,
                             timeRange: StatsTimeRangeV4,
                             latestDateToInclude: Date,
                             forceRefresh: Bool,
                             onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardTopPerformers)
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        let action = StatsActionV4.retrieveTopEarnerStats(siteID: siteID,
                                                          timeRange: timeRange,
                                                          earliestDateToInclude: earliestDateToInclude,
                                                          latestDateToInclude: latestDateToInclude,
                                                          quantity: Constants.topEarnerStatsLimit,
                                                          forceRefresh: forceRefresh,
                                                          saveInStorage: true,
                                                          onCompletion: { result in
            switch result {
            case .success:
                waitingTracker.end()
                ServiceLocator.analytics.track(event:
                        .Dashboard.dashboardTopPerformersLoaded(timeRange: timeRange))
            case .failure(let error):
                DDLogError("⛔️ Dashboard (Top Performers) — Error synchronizing top earner stats: \(error)")
            }

            let voidResult = result.map { _ in () } // Caller expects no entity in the result.
            onCompletion?(voidResult)
        })
        stores.dispatch(action)
    }

    /// Checks for announcements to show on the dashboard
    ///
    func syncAnnouncements(for siteID: Int64) async {
        // For now, products onboarding takes precedence over Just In Time Messages,
        // so we can stop if there is an onboarding announcement to display.
        // This should be revisited when either onboarding or JITMs are expanded. See: pe5pgL-11B-p2
        do {
            try await syncProductsOnboarding(for: siteID)
        } catch {
            await syncJustInTimeMessages(for: siteID)
        }
    }

    /// Fetches the current site plan.
    ///
    func syncFreeTrialBanner(siteID: Int64) {
        // Only fetch free trial information when the local feature flag is enabled.
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.freeTrial) else {
            return
        }

        // Only fetch free trial information is the site is a WPCom site.
        guard stores.sessionManager.defaultSite?.isWordPressComStore == true else {
            return DDLogInfo("⚠️ Site is not a WPCOM site.")
        }

        let action = PaymentAction.loadSiteCurrentPlan(siteID: siteID) { [weak self] result in
            switch result {
            case .success(let plan):
                if plan.isFreeTrial {
                    self?.freeTrialBannerViewModel = FreeTrialBannerViewModel(sitePlan: plan)
                } else {
                    self?.freeTrialBannerViewModel = nil
                }
            case .failure(let error):
                DDLogError("⛔️ Error fetching the current site's plan information: \(error)")
            }
        }
        stores.dispatch(action)
    }

    /// Checks if a store is eligible for products onboarding -returning error otherwise- and prepares the onboarding announcement if needed.
    ///
    private func syncProductsOnboarding(for siteID: Int64) async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            let action = ProductAction.checkProductsOnboardingEligibility(siteID: siteID) { [weak self] result in
                switch result {
                case .success(let isEligible):
                    if isEligible {
                        ServiceLocator.analytics.track(event: .ProductsOnboarding.storeIsEligible())

                        self?.setProductsOnboardingBannerIfNeeded()
                    }

                    if self?.announcementViewModel is ProductsOnboardingAnnouncementCardViewModel {
                        continuation.resume(returning: (()))
                    } else {
                        continuation.resume(throwing: ProductsOnboardingSyncingError.noContentToShow)
                    }

                case .failure(let error):
                    DDLogError("⛔️ Dashboard — Error checking products onboarding eligibility: \(error)")
                    continuation.resume(throwing: error)
                }
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    /// Sets the view model for the products onboarding banner if the user hasn't dismissed it before.
    ///
    private func setProductsOnboardingBannerIfNeeded() {
        let getVisibility = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: .productsOnboarding) { [weak self] result in
            guard let self else { return }
            if case let .success(isVisible) = result, isVisible {
                let viewModel = ProductsOnboardingAnnouncementCardViewModel(onCTATapped: { [weak self] in
                    self?.addProductTrigger.send()
                })
                self.announcementViewModel = viewModel
            }
        }
        stores.dispatch(getVisibility)
    }

    /// Checks for Just In Time Messages and prepares the announcement if needed.
    ///
    private func syncJustInTimeMessages(for siteID: Int64) async {
        guard featureFlagService.isFeatureFlagEnabled(.justInTimeMessagesOnDashboard) else {
            return
        }

        let viewModel = try? await justInTimeMessagesManager.loadMessage(for: .dashboard, siteID: siteID)
        viewModel?.$showWebViewSheet.assign(to: &self.$showWebViewSheet)
        announcementViewModel = viewModel
    }

    /// Sets up observer to decide store onboarding task lists visibility
    ///
    private func setupObserverForShowOnboarding() {
        guard featureFlagService.isFeatureFlagEnabled(.dashboardOnboarding) else {
            return
        }

        let noOnboardingTasksAvailablePublisher: AnyPublisher<Bool, Never>
        if let storeOnboardingViewModel {
            noOnboardingTasksAvailablePublisher = storeOnboardingViewModel.$noTasksAvailableForDisplay.eraseToAnyPublisher()
        } else {
            noOnboardingTasksAvailablePublisher = Just(false).eraseToAnyPublisher()
        }

        self.showOnboardingCancellable = Publishers.CombineLatest(noOnboardingTasksAvailablePublisher,
                                                                  userDefaults.publisher(for: \.completedAllStoreOnboardingTasks))
        .sink { [weak self] noTasksAvailableForDisplay, completedAllStoreOnboardingTasks in
            self?.showOnboarding = !(noTasksAvailableForDisplay || completedAllStoreOnboardingTasks)
        }
    }
}

// MARK: - Constants
//
private extension DashboardViewModel {
    enum Constants {
        static let topEarnerStatsLimit: Int = 5
        static let dashboardScreenName = "my_store"
    }
}

private extension UserDefaults {
     @objc dynamic var completedAllStoreOnboardingTasks: Bool {
         bool(forKey: Key.completedAllStoreOnboardingTasks.rawValue)
     }
 }
