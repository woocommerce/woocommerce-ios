import Yosemite
import Combine
import enum Networking.DotcomError
import enum Storage.StatsVersion
import protocol Storage.StorageManagerType
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

    @Published private(set) var dashboardCards: [DashboardCard] = [
        DashboardCard(type: .performance, enabled: true),
        DashboardCard(type: .topPerformers, enabled: true)
    ]
    @Published private(set) var unavailableDashboardCards: [DashboardCard] = []

    @Published private(set) var jetpackBannerVisibleFromAppSettings = false

    @Published private(set) var hasOrders: Bool = true

    @Published var showingCustomization = false

    let siteID: Int64
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let analytics: Analytics
    private let justInTimeMessagesManager: JustInTimeMessagesProvider
    private let localAnnouncementsProvider: LocalAnnouncementsProvider
    private let userDefaults: UserDefaults
    private let themeInstaller: ThemeInstaller
    private let storageManager: StorageManagerType
    private var subscriptions: Set<AnyCancellable> = []

    var siteURLToShare: URL? {
        if let site = stores.sessionManager.defaultSite,
           !site.isWordPressComStore || site.isPublic, // only show share button if it's a .org site or a public .com site
           let url = URL(string: site.url) {
            return url
        }
        return nil
    }

    private lazy var ordersResultsController: ResultsController<StorageOrder> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageOrder.orderID, ascending: false)
        let resultsController = ResultsController<StorageOrder>(storageManager: storageManager,
                                                                matching: predicate,
                                                                fetchLimit: 1,
                                                                sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         featureFlags: FeatureFlagService = ServiceLocator.featureFlagService,
         analytics: Analytics = ServiceLocator.analytics,
         userDefaults: UserDefaults = .standard,
         themeInstaller: ThemeInstaller = DefaultThemeInstaller(),
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter = StoreStatsUsageTracksEventEmitter()) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
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
        self.themeInstaller = themeInstaller
        configureOrdersResultController()
        setupDashboardCards()
        installPendingThemeIfNeeded()
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
            group.addTask { [weak self] in
                await self?.updateHasOrdersStatus()
            }
            group.addTask { [weak self] in
                await self?.storePerformanceViewModel.reloadData()
            }
            group.addTask { [weak self] in
                await self?.topPerformersViewModel.reloadData()
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

    func refreshDashboardCards() {
        storeOnboardingViewModel.$canShowInDashboard
            .combineLatest(blazeCampaignDashboardViewModel.$canShowInDashboard, $hasOrders)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canShowOnboarding, canShowBlaze, hasOrders in
                guard let self else { return }
                Task {
                    await self.updateDashboardCards(canShowOnboarding: canShowOnboarding,
                                                    canShowBlaze: canShowBlaze,
                                                    canShowAnalytics: hasOrders
                    )
                }
            }
            .store(in: &subscriptions)
    }

    func didCustomizeDashboardCards(_ cards: [DashboardCard]) {
        let activeCardTypes = cards
            .filter { $0.enabled }
            .map(\.type)
        analytics.track(event: .DynamicDashboard.editorSaveTapped(types: activeCardTypes))
        stores.dispatch(AppSettingsAction.setDashboardCards(siteID: siteID, cards: cards))
        dashboardCards = cards
    }
}

// MARK: Private helpers
private extension DashboardViewModel {

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

    func configureOrdersResultController() {
        ordersResultsController.onDidChangeContent = { [weak self] in
            self?.updateResults()
        }
        ordersResultsController.onDidResetContent = { [weak self] in
            self?.updateResults()
        }

        do {
            try ordersResultsController.performFetch()
            updateResults()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func updateResults() {
        hasOrders = ordersResultsController.fetchedObjects.isNotEmpty
    }

    func setupDashboardCards() {
        storeOnboardingViewModel.onDismiss = { [weak self] in
            self?.showCustomizationScreen()
        }

        blazeCampaignDashboardViewModel.onDismiss = { [weak self] in
            self?.showCustomizationScreen()
        }

        storePerformanceViewModel.onDismiss = { [weak self] in
            self?.showCustomizationScreen()
        }

        topPerformersViewModel.onDismiss = { [weak self] in
            self?.showCustomizationScreen()
        }
    }

    func showCustomizationScreen() {
        showingCustomization = true
    }

    /// We are using separate user defaults for different cards -
    /// this should be updated to general app settings.
    ///
    @MainActor
    func updateDashboardCards(canShowOnboarding: Bool,
                              canShowBlaze: Bool,
                              canShowAnalytics: Bool) async {
        dashboardCards = await {
            if var stored = await loadDashboardCards() {
                let analyticCardTypes: [DashboardCard.CardType] = [.performance, .topPerformers]
                stored = canShowAnalytics ? stored : stored.filter { !analyticCardTypes.contains($0.type) }
                return stored
            } else {
                // Start with default values, cards could be updated further below as needed.
                return [DashboardCard(type: .onboarding, enabled: canShowOnboarding),
                        DashboardCard(type: .performance, enabled: canShowAnalytics),
                        DashboardCard(type: .topPerformers, enabled: canShowAnalytics),
                        DashboardCard(type: .blaze, enabled: canShowBlaze)]
            }
        }()

        // If should not be shown, ensure Onboarding is not visible on Dashboard
        if !canShowOnboarding {
            dashboardCards.removeAll { $0.type == .onboarding }
        }

        // If should not be shown, ensure Blaze is not visible on Dashboard
        if !canShowBlaze {
            dashboardCards.removeAll { $0.type == .blaze }
        }

        // Set cards to show "Unavailable" state in Customize screen when should not be shown.
        // Currently this applies to Top Performers and Performance cards.
        // For the other cards, when they should not be shown, they are simply not shown in Customize.
        unavailableDashboardCards = []
        if !canShowAnalytics {
            unavailableDashboardCards.append(DashboardCard(type: .performance, enabled: false))
            unavailableDashboardCards.append(DashboardCard(type: .topPerformers, enabled: false))
        }
    }
    @MainActor
    func updateHasOrdersStatus() async {
        do {
            hasOrders = try await loadHasOrdersStatus()
        } catch {
            DDLogError("⛔️ Dashboard (Share Your Store) — Error checking if site has orders: \(error)")
        }
    }

    @MainActor
    func loadHasOrdersStatus() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(OrderAction.checkIfStoreHasOrders(siteID: self.siteID, onCompletion: { result in
                switch result {
                case .success(let hasOrders):
                    continuation.resume(returning: hasOrders)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }))
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
        static let orderPageNumber = 1
        static let orderPageSize = 1
    }
}
