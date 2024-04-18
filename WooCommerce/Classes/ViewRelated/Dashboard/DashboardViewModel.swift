import Yosemite
import Combine
import enum Networking.DotcomError
import enum Storage.StatsVersion
import protocol Experiments.FeatureFlagService

/// Syncs data for dashboard stats UI and determines the state of the dashboard UI based on stats version.
final class DashboardViewModel: ObservableObject {
    /// Stats v4 is shown by default, then falls back to v3 if store stats are unavailable.
    @Published private(set) var statsVersion: StatsVersion = .v4

    @Published var announcementViewModel: AnnouncementCardViewModelProtocol? = nil

    @Published var modalJustInTimeMessageViewModel: JustInTimeMessageViewModel? = nil

    @Published var localAnnouncementViewModel: LocalAnnouncementViewModel? = nil

    let storeOnboardingViewModel: StoreOnboardingViewModel

    let blazeCampaignDashboardViewModel: BlazeCampaignDashboardViewModel

    let storePerformanceViewModel: StorePerformanceViewModel
    let topPerformersViewModel: TopPerformersDashboardViewModel

    @Published var justInTimeMessagesWebViewModel: WebViewSheetViewModel? = nil

    @Published private(set) var showOnboarding: Bool = false
    @Published private(set) var showBlazeCampaignView: Bool = false

    @Published private(set) var dashboardCards: [DashboardCard] = [
        DashboardCard(type: .performance, enabled: true),
        DashboardCard(type: .topPerformers, enabled: true)
    ]
    @Published private(set) var unavailableDashboardCards: [DashboardCard] = []

    @Published private(set) var jetpackBannerVisibleFromAppSettings = false
    @Published var statSyncingError: Error?

    let siteID: Int64
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let analytics: Analytics
    private let justInTimeMessagesManager: JustInTimeMessagesProvider
    private let localAnnouncementsProvider: LocalAnnouncementsProvider
    private let userDefaults: UserDefaults
    private let storeCreationProfilerUploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol
    private let themeInstaller: ThemeInstaller
    private var subscriptions: Set<AnyCancellable> = []

    var siteURLToShare: URL? {
        if let site = stores.sessionManager.defaultSite,
           site.isPublic, // only show share button if the site is public.
           let url = URL(string: site.url) {
            return url
        }
        return nil
    }

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         featureFlags: FeatureFlagService = ServiceLocator.featureFlagService,
         analytics: Analytics = ServiceLocator.analytics,
         userDefaults: UserDefaults = .standard,
         storeCreationProfilerUploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol? = nil,
         themeInstaller: ThemeInstaller = DefaultThemeInstaller(),
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter = StoreStatsUsageTracksEventEmitter()) {
        self.siteID = siteID
        self.stores = stores
        self.featureFlagService = featureFlags
        self.analytics = analytics
        self.userDefaults = userDefaults
        self.justInTimeMessagesManager = JustInTimeMessagesProvider(stores: stores, analytics: analytics)
        self.localAnnouncementsProvider = .init(stores: stores, analytics: analytics, featureFlagService: featureFlags)
        self.storeOnboardingViewModel = .init(siteID: siteID, isExpanded: false, stores: stores, defaults: userDefaults)
        self.blazeCampaignDashboardViewModel = .init(siteID: siteID)
        self.storePerformanceViewModel = .init(siteID: siteID,
                                               usageTracksEventEmitter: usageTracksEventEmitter)
        self.topPerformersViewModel = .init(siteID: siteID,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
        self.storeCreationProfilerUploadAnswersUseCase = storeCreationProfilerUploadAnswersUseCase ?? StoreCreationProfilerUploadAnswersUseCase(siteID: siteID)
        self.themeInstaller = themeInstaller
        setupObserverForShowOnboarding()
        setupObserverForBlazeCampaignView()
        setupDashboardCards()
        installPendingThemeIfNeeded()
        configureStorePerformanceViewModel()
    }

    /// Uploads the answers from the store creation profiler flow
    ///
    func uploadProfilerAnswers() async {
        await storeCreationProfilerUploadAnswersUseCase.uploadAnswers()
    }

    @MainActor
    func reloadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self else { return }
                await self.syncAnnouncements(for: self.siteID)
            }
            group.addTask { [weak self] in
                await self?.reloadStoreOnboardingTasks()
            }
            group.addTask { [weak self] in
                await self?.reloadBlazeCampaignView()
            }
            group.addTask { [weak self] in
                await self?.updateJetpackBannerVisibilityFromAppSettings()
            }
            if featureFlagService.isFeatureFlagEnabled(.dynamicDashboard) {
                if dashboardCards.contains(where: { $0.type == .performance }) {
                    group.addTask { [weak self] in
                        await self?.storePerformanceViewModel.reloadData()
                    }
                }

                if dashboardCards.contains(where: { $0.type == .topPerformers }) {
                    group.addTask { [weak self] in
                        await self?.topPerformersViewModel.reloadData()
                    }
                }
            }
        }
    }

    /// Reloads store onboarding tasks
    ///
    @MainActor
    func reloadStoreOnboardingTasks() async {
        await storeOnboardingViewModel.reloadTasks()
    }

    /// Reloads Blaze dashboard campaign view
    ///
    @MainActor
    func reloadBlazeCampaignView() async {
        await blazeCampaignDashboardViewModel.reload()
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
    @MainActor
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

    func saveJetpackBenefitBannerDismissedTime() {
        let dismissAction = AppSettingsAction.setJetpackBenefitsBannerLastDismissedTime(time: Date())
        stores.dispatch(dismissAction)
    }

    func maybeSyncAnnouncementsAfterWebViewDismissed() {
        // Sync announcements again only when the JITM modal has been dismissed to avoid showing duplicated modals.
        if modalJustInTimeMessageViewModel == nil {
            Task {
                await syncAnnouncements(for: siteID)
            }
        }
    }

    func didCustomizeDashboardCards(_ cards: [DashboardCard]) {
        stores.dispatch(AppSettingsAction.setDashboardCards(siteID: siteID, cards: cards))
        dashboardCards = cards
    }
}

// MARK: Private helpers
private extension DashboardViewModel {
    func configureStorePerformanceViewModel() {
        storePerformanceViewModel.onDataReload = { [weak self] in
            self?.statSyncingError = nil
        }

        storePerformanceViewModel.onSyncingError = { [weak self] error in
            self?.statSyncingError = error
        }
    }

    /// Checks for Just In Time Messages and prepares the announcement if needed.
    ///
    @MainActor
    func syncJustInTimeMessages(for siteID: Int64) async {
        let viewModel = try? await justInTimeMessagesManager.loadMessage(for: .dashboard, siteID: siteID)
        viewModel?.$showWebViewSheet.assign(to: &self.$justInTimeMessagesWebViewModel)
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
    func loadLocalAnnouncement() async {
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
    func setupObserverForShowOnboarding() {
        guard featureFlagService.isFeatureFlagEnabled(.dashboardOnboarding) else {
            return
        }

        storeOnboardingViewModel.$shouldShowInDashboard
            .assign(to: &$showOnboarding)
    }

    /// Sets up observer to decide Blaze campaign view visibility
    ///
    func setupObserverForBlazeCampaignView() {
        blazeCampaignDashboardViewModel.$shouldShowInDashboard
            .assign(to: &$showBlazeCampaignView)
    }

    func setupDashboardCards() {
        storeOnboardingViewModel.onDismiss = { [weak self] in
            self?.hideDashboardCard(type: .onboarding)
        }
        
        storeOnboardingViewModel.$canShowInDashboard
            .combineLatest(blazeCampaignDashboardViewModel.$canShowInDashboard)
            .receive(on: RunLoop.main)
            .sink { [weak self] canShowOnboarding, canShowBlaze in
                guard let self else { return }
                Task {
                    await self.updateDashboardCards(canShowOnboarding: canShowOnboarding,
                                                    canShowBlaze: canShowBlaze)
                }
            }
            .store(in: &subscriptions)
    }

    func hideDashboardCard(type: DashboardCard.CardType) {
        if let index = dashboardCards.firstIndex(where: { $0.type == type }) {
            dashboardCards[index] = dashboardCards[index].copy(enabled: false)
        }
    }

    /// We are using separate user defaults for different cards -
    /// this should be updated to general app settings.
    ///
    @MainActor
    func updateDashboardCards(canShowOnboarding: Bool, canShowBlaze: Bool) async {
        dashboardCards = await {
            if let stored = await loadDashboardCards() {
                return stored
            } else {
                return [DashboardCard(type: .onboarding, enabled: canShowOnboarding),
                        DashboardCard(type: .performance, enabled: true),
                        DashboardCard(type: .topPerformers, enabled: true),
                        DashboardCard(type: .blaze, enabled: canShowBlaze)]
            }
        }()

        unavailableDashboardCards = []

        if let onboardingCard = dashboardCards.first(where: { $0.type == .onboarding }),
           !canShowOnboarding {
            unavailableDashboardCards.append(onboardingCard)
        }

        if let blazeCard = dashboardCards.first(where: { $0.type == .blaze }),
           !canShowBlaze {
            unavailableDashboardCards.append(blazeCard)
        }
    }

    @MainActor
    func loadJetpackBannerVisibilityFromAppSettings() async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadJetpackBenefitsBannerVisibility(currentTime: Date(),
                                                                               calendar: .current) {  isVisibleFromAppSettings in
                continuation.resume(returning: isVisibleFromAppSettings)
            })
        }
    }

    @MainActor
    func updateJetpackBannerVisibilityFromAppSettings() async {
        jetpackBannerVisibleFromAppSettings = await loadJetpackBannerVisibilityFromAppSettings()
    }

    @MainActor
    func loadDashboardCards() async -> [DashboardCard]? {
        await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadDashboardCards(siteID: siteID, onCompletion: { cards in
                continuation.resume(returning: cards)
            }))
        }
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
