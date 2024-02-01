import Yosemite
import Combine
import enum Networking.DotcomError
import enum Storage.StatsVersion
import protocol Experiments.FeatureFlagService

/// Syncs data for dashboard stats UI and determines the state of the dashboard UI based on stats version.
final class DashboardViewModel {
    /// Stats v4 is shown by default, then falls back to v3 if store stats are unavailable.
    @Published private(set) var statsVersion: StatsVersion = .v4

    @Published var announcementViewModel: AnnouncementCardViewModelProtocol? = nil

    @Published var modalJustInTimeMessageViewModel: JustInTimeMessageViewModel? = nil

    @Published var localAnnouncementViewModel: LocalAnnouncementViewModel? = nil

    let storeOnboardingViewModel: StoreOnboardingViewModel

    let blazeCampaignDashboardViewModel: BlazeCampaignDashboardViewModel

    @Published private(set) var showWebViewSheet: WebViewSheetViewModel? = nil

    @Published private(set) var showOnboarding: Bool = false

    @Published private(set) var showBlazeCampaignView: Bool = false

    private let siteID: Int64
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let analytics: Analytics
    private let justInTimeMessagesManager: JustInTimeMessagesProvider
    private let localAnnouncementsProvider: LocalAnnouncementsProvider
    private let userDefaults: UserDefaults
    private let storeCreationProfilerUploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol
    private let themeInstaller: ThemeInstaller
    private let startupWaitingTimeTracker: AppStartupWaitingTimeTracker

    var siteURLToShare: URL? {
        if let site = stores.sessionManager.defaultSite,
           site.isPublic, // only show share button if the site is public.
           let url = URL(string: site.url) {
            return url
        }
        return nil
    }

    init(siteID: Int64,
         siteURL: String,
         stores: StoresManager = ServiceLocator.stores,
         featureFlags: FeatureFlagService = ServiceLocator.featureFlagService,
         analytics: Analytics = ServiceLocator.analytics,
         userDefaults: UserDefaults = .standard,
         storeCreationProfilerUploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol? = nil,
         themeInstaller: ThemeInstaller = DefaultThemeInstaller(),
         startupWaitingTimeTracker: AppStartupWaitingTimeTracker = ServiceLocator.startupWaitingTimeTracker) {
        self.siteID = siteID
        self.stores = stores
        self.featureFlagService = featureFlags
        self.analytics = analytics
        self.userDefaults = userDefaults
        self.justInTimeMessagesManager = JustInTimeMessagesProvider(stores: stores, analytics: analytics)
        self.localAnnouncementsProvider = .init(stores: stores, analytics: analytics, featureFlagService: featureFlags)
        self.storeOnboardingViewModel = .init(siteID: siteID, isExpanded: false, stores: stores, defaults: userDefaults)
        self.blazeCampaignDashboardViewModel = .init(siteID: siteID, siteURL: siteURL)
        self.storeCreationProfilerUploadAnswersUseCase = storeCreationProfilerUploadAnswersUseCase ?? StoreCreationProfilerUploadAnswersUseCase(siteID: siteID)
        self.themeInstaller = themeInstaller
        self.startupWaitingTimeTracker = startupWaitingTimeTracker
        setupObserverForShowOnboarding()
        setupObserverForBlazeCampaignView()
        installPendingThemeIfNeeded()
    }

    /// Uploads the answers from the store creation profiler flow
    ///
    func uploadProfilerAnswers() async {
        await storeCreationProfilerUploadAnswersUseCase.uploadAnswers()
    }

    /// Reloads store onboarding tasks
    ///
    func reloadStoreOnboardingTasks() async {
        await storeOnboardingViewModel.reloadTasks()
    }

    /// Reloads Blaze dashboard campaign view
    ///
    func reloadBlazeCampaignView() async {
        await blazeCampaignDashboardViewModel.reload()
        startupWaitingTimeTracker.end(action: .syncBlazeCampaigns)
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
                                                 timeZone: siteTimezone,
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
        guard stores.isAuthenticatedWithoutWPCom == false else { // Visit stats are only available for stores connected to WPCom
            onCompletion?(.success(()))
            return
        }

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
        guard stores.isAuthenticatedWithoutWPCom == false else { // Summary stats are only available for stores connected to WPCom
            onCompletion?(.success(()))
            return
        }

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
                                                          timeZone: siteTimezone,
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
        await syncJustInTimeMessages(for: siteID)
        await loadLocalAnnouncement()
    }

    /// Triggers the `.dashboardTimezonesDiffer` track event whenever the device local timezone and the current site timezone are different from each other
    /// 
    func trackStatsTimezone(localTimezone: TimeZone, siteGMTOffset: Double) {
        let localGMTOffsetInHours = Double(localTimezone.secondsFromGMT()) / 3600
        guard localGMTOffsetInHours != siteGMTOffset else {
            return
        }

        analytics.track(event: .Dashboard.dashboardTimezonesDiffers(localTimezone: localGMTOffsetInHours, storeTimezone: siteGMTOffset))
    }

    /// Checks for Just In Time Messages and prepares the announcement if needed.
    ///
    private func syncJustInTimeMessages(for siteID: Int64) async {
        let viewModel = try? await justInTimeMessagesManager.loadMessage(for: .dashboard, siteID: siteID)
        viewModel?.$showWebViewSheet.assign(to: &self.$showWebViewSheet)
        switch viewModel?.template {
        case .some(.banner):
            announcementViewModel = viewModel
        case .some(.modal):
            modalJustInTimeMessageViewModel = viewModel
        default:
            announcementViewModel = nil
            modalJustInTimeMessageViewModel = nil
        }
    }

    @MainActor
    /// If JITM modal isn't displayed, it loads a local announcement to be displayed modally if available.
    /// When a local announcement is available, the view model is set. Otherwise, the view model is set to `nil`.
    private func loadLocalAnnouncement() async {
        // Local announcement modal can only be shown when JITM modal is not shown.
        guard modalJustInTimeMessageViewModel == nil else {
            return
        }
        guard let viewModel = await localAnnouncementsProvider.loadAnnouncement() else {
            localAnnouncementViewModel = nil
            return
        }
        localAnnouncementViewModel = viewModel
    }

    /// Sets up observer to decide store onboarding task lists visibility
    ///
    private func setupObserverForShowOnboarding() {
        guard featureFlagService.isFeatureFlagEnabled(.dashboardOnboarding) else {
            return
        }

        storeOnboardingViewModel.$shouldShowInDashboard
            .assign(to: &$showOnboarding)
    }

    /// Sets up observer to decide Blaze campaign view visibility
    ///
    private func setupObserverForBlazeCampaignView() {
        blazeCampaignDashboardViewModel.$shouldShowInDashboard
            .assign(to: &$showBlazeCampaignView)
    }
}

// MARK: Theme install
//
private extension DashboardViewModel {
    /// Installs themes for newly created store.
    ///
    func installPendingThemeIfNeeded() {
        Task { @MainActor in
            do {
                try await themeInstaller.installPendingThemeIfNeeded(siteID: siteID)
            } catch {
                DDLogError("⛔️ Dashboard - Error installing pending theme: \(error)")
            }
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
