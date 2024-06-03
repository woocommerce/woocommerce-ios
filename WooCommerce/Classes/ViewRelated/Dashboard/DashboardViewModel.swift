import Yosemite
import Combine
import enum Networking.DotcomError
import enum Storage.StatsVersion
import protocol Storage.StorageManagerType
import protocol Experiments.FeatureFlagService
import protocol WooFoundation.Analytics

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
    let inboxViewModel: InboxDashboardCardViewModel
    let reviewsViewModel: ReviewsDashboardCardViewModel
    let mostActiveCouponsViewModel: MostActiveCouponsCardViewModel
    let productStockCardViewModel: ProductStockDashboardCardViewModel
    let lastOrdersCardViewModel: LastOrdersDashboardCardViewModel

    @Published var justInTimeMessagesWebViewModel: WebViewSheetViewModel? = nil

    @Published private(set) var dashboardCards: [DashboardCard] = []

    /// Used to compare and reload only newly enabled cards
    ///
    private var previousDashboardCards: [DashboardCard] = []

    var unavailableCards: [DashboardCard] {
        dashboardCards.filter { $0.availability == .unavailable }
    }

    var availableCards: [DashboardCard] {
        dashboardCards.filter { $0.availability != .hide }
    }

    var showOnDashboardCards: [DashboardCard] {
        dashboardCards.filter { $0.availability == .show && $0.enabled }
    }

    @Published private(set) var isInAppFeedbackCardVisible = false

    private(set) var inAppFeedbackCardViewModel = InAppFeedbackCardViewModel()

    @Published var showingInAppFeedbackSurvey = false

    @Published private(set) var jetpackBannerVisibleFromAppSettings = false

    @Published private(set) var hasOrders = true

    @Published private(set) var isEligibleForInbox = false

    @Published var showingCustomization = false

    @Published var showNewCardsNotice = false

    let siteID: Int64
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let analytics: Analytics
    private let justInTimeMessagesManager: JustInTimeMessagesProvider
    private let localAnnouncementsProvider: LocalAnnouncementsProvider
    private let userDefaults: UserDefaults
    private let themeInstaller: ThemeInstaller
    private let storageManager: StorageManagerType
    private let inboxEligibilityChecker: InboxEligibilityChecker
    private var subscriptions: Set<AnyCancellable> = []

    var siteURLToShare: URL? {
        if let site = stores.sessionManager.defaultSite,
           !site.isWordPressComStore || (site.visibility == .publicSite), // only show share button if it's a .org site or a public .com site
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
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter = StoreStatsUsageTracksEventEmitter(),
         inboxEligibilityChecker: InboxEligibilityChecker = InboxEligibilityUseCase()) {
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
        self.inboxViewModel = InboxDashboardCardViewModel(siteID: siteID)
        self.reviewsViewModel = ReviewsDashboardCardViewModel(siteID: siteID)
        self.mostActiveCouponsViewModel = MostActiveCouponsCardViewModel(siteID: siteID)
        self.productStockCardViewModel = ProductStockDashboardCardViewModel(siteID: siteID)
        self.lastOrdersCardViewModel = LastOrdersDashboardCardViewModel(siteID: siteID)

        self.themeInstaller = themeInstaller
        self.inboxEligibilityChecker = inboxEligibilityChecker
        self.inAppFeedbackCardViewModel.onFeedbackGiven = { [weak self] feedback in
            self?.showingInAppFeedbackSurvey = feedback == .didntLike
            self?.onInAppFeedbackCardAction()
        }
        configureOrdersResultController()
        setupDashboardCards()
        installPendingThemeIfNeeded()
        observeDashboardCardsAndReload()
        Task {
            await checkInboxEligibility()
        }
    }

    /// Must be called by the `View` during the `onAppear()` event. This will
    /// update the visibility of the in-app feedback card.
    ///
    /// The visibility is updated on `onAppear()` to consider scenarios when the app is
    /// never terminated.
    ///
    func onViewAppear() {
        refreshIsInAppFeedbackCardVisibleValue()
    }

    @MainActor
    func handleCustomizationDismissal() async {
        await configureNewCardsNotice()
    }

    @MainActor
    func reloadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.syncDashboardEssentialData()
            }
            group.addTask { [weak self] in
                guard let self else { return }
                await reloadCards(showOnDashboardCards)
            }
            group.addTask { [weak self] in
                await self?.checkInboxEligibility()
            }
        }
    }

    /// Sync essential data to construct the dashboard
    ///
    @MainActor
    func syncDashboardEssentialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self else { return }
                await self.syncAnnouncements(for: self.siteID)
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
            .combineLatest(blazeCampaignDashboardViewModel.$canShowInDashboard, $hasOrders, $isEligibleForInbox)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canShowOnboarding, canShowBlaze, hasOrders, isEligibleForInbox in
                guard let self else { return }
                Task {
                    await self.updateDashboardCards(canShowOnboarding: canShowOnboarding,
                                                    canShowBlaze: canShowBlaze,
                                                    canShowAnalytics: hasOrders,
                                                    canShowLastOrders: hasOrders,
                                                    canShowInbox: isEligibleForInbox)
                }
            }
            .store(in: &subscriptions)
    }

    func showCustomizationScreen() {
        // The app should remove the notice once a user opens the Customize screen (whether they end up customizing or not).
        // To do so, we save the current dashboard cards once when opening Customize. The current cards will already have
        // been generated with the new cards included, so saving it ensures that the notice is hidden in subsequent checks.
        if showNewCardsNotice {
            stores.dispatch(AppSettingsAction.setDashboardCards(siteID: siteID, cards: dashboardCards))
            showNewCardsNotice = false
        }
        showingCustomization = true
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

// MARK: Reload cards

private extension DashboardViewModel {
    func observeDashboardCardsAndReload() {
        $dashboardCards
            .filter({ $0.isNotEmpty })
            .removeDuplicates()
            .sink(receiveValue: { [weak self] cards in
                guard let self else { return }

                let newlyEnabledCards = {
                    let previouslyEnabledCards = Set(
                        self.previousDashboardCards
                            .filter { $0.enabled }
                    )
                    let currentlyEnabledCards = Set(
                        cards
                            .filter { $0.enabled }
                    )
                    return Array(currentlyEnabledCards.subtracting(previouslyEnabledCards))
                }()

                previousDashboardCards = cards

                if newlyEnabledCards.isNotEmpty {
                    Task { @MainActor in
                        await self.reloadCards(newlyEnabledCards)
                    }
                }
            })
            .store(in: &subscriptions)
    }

    @MainActor
    func reloadCards(_ cards: [DashboardCard]) async {
        await withTaskGroup(of: Void.self) { group in
            cards.forEach { card in
                switch card.type {
                case .onboarding:
                    group.addTask { [weak self] in
                        await self?.reloadStoreOnboardingTasks()
                    }
                case .performance:
                    group.addTask { [weak self] in
                        await self?.storePerformanceViewModel.reloadData()
                    }
                case .topPerformers:
                    group.addTask { [weak self] in
                        await self?.topPerformersViewModel.reloadData()
                    }
                case .blaze:
                    group.addTask { [weak self] in
                        await self?.reloadBlazeCampaignView()
                    }
                case .inbox:
                    guard featureFlagService.isFeatureFlagEnabled(.dynamicDashboardM2), isEligibleForInbox else {
                        return
                    }
                    group.addTask { [weak self] in
                        await self?.inboxViewModel.reloadData()
                    }
                case .coupons:
                    guard featureFlagService.isFeatureFlagEnabled(.dynamicDashboardM2) else {
                        return
                    }
                    group.addTask { [weak self] in
                        await self?.mostActiveCouponsViewModel.reloadData()
                    }
                case .stock:
                    guard featureFlagService.isFeatureFlagEnabled(.dynamicDashboardM2) else {
                        return
                    }
                    group.addTask { [weak self] in
                        await self?.productStockCardViewModel.reloadData()
                    }
                case .reviews:
                    guard featureFlagService.isFeatureFlagEnabled(.dynamicDashboardM2) else {
                        return
                    }
                    group.addTask { [weak self] in
                        await self?.reviewsViewModel.reloadData()
                    }
                case .lastOrders:
                    guard featureFlagService.isFeatureFlagEnabled(.dynamicDashboardM2) else {
                        return
                    }
                    group.addTask { [weak self] in
                        await self?.lastOrdersCardViewModel.reloadData()
                    }
                }
            }
        }
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

    @MainActor
    func checkInboxEligibility() async {
        guard featureFlagService.isFeatureFlagEnabled(.dynamicDashboardM2) else {
            return
        }
        isEligibleForInbox = await inboxEligibilityChecker.isEligibleForInbox(siteID: siteID)
    }

    func configureOrdersResultController() {
        func refreshHasOrders() {
            guard ordersResultsController.fetchedObjects.isEmpty else {
                hasOrders = true
                return
            }

            Task { @MainActor [weak self] in
                await self?.updateHasOrdersStatus()
            }
        }

        ordersResultsController.onDidChangeContent = {
            refreshHasOrders()
        }
        ordersResultsController.onDidResetContent = {
            refreshHasOrders()
        }

        do {
            try ordersResultsController.performFetch()
            refreshHasOrders()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func setupDashboardCards() {
        let showCustomizationScreen: (() -> Void) = { [weak self] in
            self?.showCustomizationScreen()
        }
        storeOnboardingViewModel.onDismiss = showCustomizationScreen
        blazeCampaignDashboardViewModel.onDismiss = showCustomizationScreen
        storePerformanceViewModel.onDismiss = showCustomizationScreen
        topPerformersViewModel.onDismiss = showCustomizationScreen
        inboxViewModel.onDismiss = showCustomizationScreen
        reviewsViewModel.onDismiss = showCustomizationScreen
        mostActiveCouponsViewModel.onDismiss = showCustomizationScreen
        productStockCardViewModel.onDismiss = showCustomizationScreen
        lastOrdersCardViewModel.onDismiss = showCustomizationScreen
    }

    func generateDefaultCards(canShowOnboarding: Bool,
                              canShowBlaze: Bool,
                              canShowAnalytics: Bool,
                              canShowLastOrders: Bool,
                              canShowInbox: Bool) -> [DashboardCard] {
        var cards = [DashboardCard]()

        // Onboarding card.
        // When not available, Onboarding card needs to be hidden from Dashboard and Customize
        cards.append(DashboardCard(type: .onboarding,
                                   availability: canShowOnboarding ? .show : .hide,
                                   enabled: canShowOnboarding))

        // Performance and Top Performance cards (also known as Analytics cards).
        // When not available, Analytics cards need to be hidden from Dashboard, but appear on Customize as "Unavailable"
        cards.append(DashboardCard(type: .performance,
                                   availability: canShowAnalytics ? .show : .unavailable,
                                   enabled: canShowAnalytics))

        cards.append(DashboardCard(type: .topPerformers,
                                   availability: canShowAnalytics ? .show : .unavailable,
                                   enabled: canShowAnalytics))

        // Blaze card.
        // When not available, Blaze card needs to be hidden from Dashboard and Customize
        cards.append(DashboardCard(type: .blaze,
                                   availability: canShowBlaze ? .show : .hide,
                                   enabled: canShowBlaze))

        let dynamicDashboardM2 = featureFlagService.isFeatureFlagEnabled(.dynamicDashboardM2)
        if dynamicDashboardM2 {
            cards.append(DashboardCard(type: .inbox,
                                       availability: canShowInbox ? .show : .hide,
                                       enabled: false))
            cards.append(DashboardCard(type: .reviews, availability: .show, enabled: false))
            cards.append(DashboardCard(type: .coupons, availability: .show, enabled: false))
            cards.append(DashboardCard(type: .stock, availability: .show, enabled: false))

            // When not available, Last orders cards need to be hidden from Dashboard, but appear on Customize as "Unavailable"
            cards.append(DashboardCard(type: .lastOrders,
                                       availability: canShowLastOrders ? .show : .unavailable,
                                       enabled: false))
        }

        return cards
    }

    @MainActor
    func updateDashboardCards(canShowOnboarding: Bool,
                              canShowBlaze: Bool,
                              canShowAnalytics: Bool,
                              canShowLastOrders: Bool,
                              canShowInbox: Bool) async {

        // First, generate latest cards state based on current canShow states
        let initialCards = generateDefaultCards(canShowOnboarding: canShowOnboarding,
                                                canShowBlaze: canShowBlaze,
                                                canShowAnalytics: canShowAnalytics,
                                                canShowLastOrders: canShowLastOrders,
                                                canShowInbox: canShowInbox)

        // Next, get saved cards and preserve existing enabled state for all available cards.
        // This is needed because even if a user already disabled an available card and saved it, in `initialCards`
        // the same card might be set to be enabled. To respect user's setting, we need to check the saved state and re-apply it.
        let savedCards = await loadDashboardCards() ?? []
        let updatedCards = initialCards.map { initialCard in
            if let savedCard = savedCards.first(where: { $0.type == initialCard.type }),
               savedCard.availability == .show && initialCard.availability == .show {
                return initialCard.copy(enabled: savedCard.enabled)
            } else {
                return initialCard
            }
        }

        /// If no saved cards are found, display the default cards.
        if savedCards.isEmpty {
            dashboardCards = updatedCards
        } else {

            // Reorder dashboardCards based on original ordering in savedCards
            let reorderedCards = savedCards.compactMap { savedCard in
                updatedCards.first(where: { $0.type == savedCard.type })
            }

            // Get any remaining available cards and disable them.
            let remainingCards = Set(updatedCards).subtracting(savedCards)
                .filter { card in
                    card.availability == .show &&
                    !savedCards.contains(where: { $0.type == card.type })
                }
                .map { $0.copy(enabled: false) }

            // Append the remaining cards to the end of the list
            dashboardCards = reorderedCards + remainingCards
        }

        await configureNewCardsNotice(with: savedCards)
    }

    /// Determines whether to show the notice that new cards now exist and can be found in Customize screen.
    /// Can optionally pass local cards in case they are recently loaded before calling this function.
    @MainActor
    func configureNewCardsNotice(with localCards: [DashboardCard]? = nil) async {
        guard featureFlagService.isFeatureFlagEnabled(.dynamicDashboardM2) else {
            return
        }
        var cards: [DashboardCard]

        if let localCards {
            cards = localCards
        } else {
            cards = await loadDashboardCards() ?? []
        }

        let savedCardTypes = Set(cards.map { $0.type })
        let savedCardContainsAllNewCards = Constants.m2CardSet.isSubset(of: savedCardTypes)

        if savedCardContainsAllNewCards {
            showNewCardsNotice = false
        } else {
            showNewCardsNotice = true
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

// MARK: InAppFeedback card
//
private extension DashboardViewModel {
    /// Updates the card visibility state stored in `isInAppFeedbackCardVisible` by updating the app last feedback date.
    ///
    func onInAppFeedbackCardAction() {
        let action = AppSettingsAction.updateFeedbackStatus(type: .general, status: .given(Date())) { [weak self] result in
            guard let self = self else {
                return
            }

            if let error = result.failure {
                ServiceLocator.crashLogging.logError(error)
            }

            self.refreshIsInAppFeedbackCardVisibleValue()
        }
        stores.dispatch(action)
    }

    /// Calculates and updates the value of `isInAppFeedbackCardVisible`.
    func refreshIsInAppFeedbackCardVisibleValue() {
        let action = AppSettingsAction.loadFeedbackVisibility(type: .general) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let shouldBeVisible):
                self.sendIsInAppFeedbackCardVisibleValueAndTrackIfNeeded(shouldBeVisible)
            case .failure(let error):
                ServiceLocator.crashLogging.logError(error)
                // We'll just send a `false` value. I think this is the safer bet.
                self.sendIsInAppFeedbackCardVisibleValueAndTrackIfNeeded(false)
            }
        }
        stores.dispatch(action)
    }

    /// Updates the value of `isInAppFeedbackCardVisible` and tracks a "shown" event
    /// if the value changed from `false` to `true`.
    func sendIsInAppFeedbackCardVisibleValueAndTrackIfNeeded(_ newValue: Bool) {
        let trackEvent = isInAppFeedbackCardVisible == false && newValue == true

        isInAppFeedbackCardVisible = newValue
        if trackEvent {
            analytics.track(event: .appFeedbackPrompt(action: .shown))
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

        static let m2CardSet: Set<DashboardCard.CardType> = [.inbox, .reviews, .coupons, .stock, .lastOrders]
    }
}
