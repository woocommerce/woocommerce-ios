import Yosemite
import Combine
import enum Networking.DotcomError
import enum Storage.StatsVersion
import protocol Storage.StorageManagerType
import protocol Experiments.FeatureFlagService
import protocol WooFoundation.Analytics

/// Syncs data for dashboard stats UI and determines the state of the dashboard UI based on stats version.
@MainActor
final class DashboardViewModel: ObservableObject {
    /// Stats v4 is shown by default, then falls back to v3 if store stats are unavailable.
    @Published private(set) var statsVersion: StatsVersion = .v4

    @Published var announcementViewModel: AnnouncementCardViewModelProtocol? = nil

    @Published var modalJustInTimeMessageViewModel: JustInTimeMessageViewModel? = nil

    let storeOnboardingViewModel: StoreOnboardingViewModel
    let blazeCampaignDashboardViewModel: BlazeCampaignDashboardViewModel

    let storePerformanceViewModel: StorePerformanceViewModel
    let topPerformersViewModel: TopPerformersDashboardViewModel
    let inboxViewModel: InboxDashboardCardViewModel
    let reviewsViewModel: ReviewsDashboardCardViewModel
    let mostActiveCouponsViewModel: MostActiveCouponsCardViewModel
    let productStockCardViewModel: ProductStockDashboardCardViewModel
    let lastOrdersCardViewModel: LastOrdersDashboardCardViewModel
    let googleAdsDashboardCardViewModel: GoogleAdsDashboardCardViewModel

    @Published var justInTimeMessagesWebViewModel: WebViewSheetViewModel? = nil

    @Published private(set) var dashboardCards: [DashboardCard] = []

    /// Used to compare and reload only newly enabled cards
    ///
    private var previousDashboardCards: [DashboardCard] = []

    /// Cards fetched from storage
    ///
    private var savedCards: [DashboardCard] = []

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

    @Published private(set) var hasOrders = false

    @Published private(set) var isEligibleForInbox = false

    @Published var showingCustomization = false

    @Published private(set) var showNewCardsNotice = false

    @Published private(set) var isReloadingAllData = false

    let siteID: Int64
    let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let analytics: Analytics
    private let justInTimeMessagesManager: JustInTimeMessagesProvider
    private let userDefaults: UserDefaults
    private let storageManager: StorageManagerType
    private let inboxEligibilityChecker: InboxEligibilityChecker
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

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
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter = StoreStatsUsageTracksEventEmitter(),
         blazeEligibilityChecker: BlazeEligibilityCheckerProtocol = BlazeEligibilityChecker(),
         inboxEligibilityChecker: InboxEligibilityChecker = InboxEligibilityUseCase(),
         googleAdsEligibilityChecker: GoogleAdsEligibilityChecker = DefaultGoogleAdsEligibilityChecker()) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.featureFlagService = featureFlags
        self.analytics = analytics
        self.userDefaults = userDefaults
        self.justInTimeMessagesManager = JustInTimeMessagesProvider(stores: stores, analytics: analytics)
        self.storeOnboardingViewModel = .init(siteID: siteID, isExpanded: false, stores: stores, defaults: userDefaults)
        self.blazeCampaignDashboardViewModel = .init(siteID: siteID,
                                                     stores: stores,
                                                     storageManager: storageManager,
                                                     blazeEligibilityChecker: blazeEligibilityChecker)
        self.storePerformanceViewModel = .init(siteID: siteID,
                                               usageTracksEventEmitter: usageTracksEventEmitter)
        self.topPerformersViewModel = .init(siteID: siteID,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
        self.inboxViewModel = InboxDashboardCardViewModel(siteID: siteID)
        self.reviewsViewModel = ReviewsDashboardCardViewModel(siteID: siteID)
        self.mostActiveCouponsViewModel = MostActiveCouponsCardViewModel(siteID: siteID)
        self.productStockCardViewModel = ProductStockDashboardCardViewModel(siteID: siteID)
        self.lastOrdersCardViewModel = LastOrdersDashboardCardViewModel(siteID: siteID)
        self.googleAdsDashboardCardViewModel = GoogleAdsDashboardCardViewModel(
            siteID: siteID,
            eligibilityChecker: googleAdsEligibilityChecker
        )

        self.inboxEligibilityChecker = inboxEligibilityChecker
        self.usageTracksEventEmitter = usageTracksEventEmitter

        self.inAppFeedbackCardViewModel.onFeedbackGiven = { [weak self] feedback in
            self?.showingInAppFeedbackSurvey = feedback == .didntLike
            self?.onInAppFeedbackCardAction()
        }

        configureOrdersResultController()
        setupDashboardCards()
    }

    /// Must be called by the `View` during the `onAppear()` event. This will
    /// update the visibility of the in-app feedback card.
    ///
    /// The visibility is updated on `onAppear()` to consider scenarios when the app is
    /// never terminated.
    ///
    @MainActor
    func onViewAppear() async {
        refreshIsInAppFeedbackCardVisibleValue()

        /// When the user creates a Blaze campaign after hiding the Blaze card
        /// we add the Blaze card back in `BlazeCampaignCreationCoordinator`.
        /// Here we need to get the updated cards from storage and update the dashboard accordingly.
        await loadDashboardCardsFromStorage()
        updateDashboardCards(canShowOnboarding: storeOnboardingViewModel.canShowInDashboard,
                             canShowBlaze: blazeCampaignDashboardViewModel.canShowInDashboard,
                             canShowGoogle: googleAdsDashboardCardViewModel.canShowOnDashboard,
                             canShowInbox: isEligibleForInbox,
                             hasOrders: hasOrders)

        await reloadCardsWithBackgroundUpdateSupportIfNeeded()
    }

    func handleCustomizationDismissal() {
        configureNewCardsNotice(hasOrders: hasOrders)
    }

    @MainActor
    func reloadAllData(forceCardsRefresh: Bool = false) async {
        isReloadingAllData = true
        checkInboxEligibility()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.syncDashboardEssentialData()
            }
            if dashboardCards.isNotEmpty {
                group.addTask { [weak self] in
                    guard let self else { return }
                    await reloadCardsIfNeeded(showOnDashboardCards, forceRefresh: forceCardsRefresh)
                }
            }
            group.addTask { [weak self] in
                await self?.loadDashboardCardsFromStorage()
            }
        }
        isReloadingAllData = false
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

    func showCustomizationScreen() {
        // The app should remove the notice once a user opens the Customize screen (whether they end up customizing or not).
        // To do so, we save the current dashboard cards once when opening Customize. The current cards will already have
        // been generated with the new cards included, so saving it ensures that the notice is hidden in subsequent checks.
        if showNewCardsNotice {
            saveDashboardCards(cards: dashboardCards)
            showNewCardsNotice = false
        }
        showingCustomization = true
    }

    func didCustomizeDashboardCards(_ cards: [DashboardCard]) {
        let activeCardTypes = cards
            .filter { $0.enabled }
            .map(\.type)
        analytics.track(event: .DynamicDashboard.editorSaveTapped(types: activeCardTypes))
        saveDashboardCards(cards: cards)
        dashboardCards = cards
    }

    func onPullToRefresh() {
        /// Track `used_analytics` if stat cards are enabled.
        let hasStatsCards = availableCards.contains(where: { $0.type == .performance || $0.type == .topPerformers })
        if hasStatsCards {
            usageTracksEventEmitter.interacted()
        }

        Task { @MainActor in
            analytics.track(.dashboardPulledToRefresh)
            await reloadAllData(forceCardsRefresh: true)
        }
    }
}

// MARK: Dashboard card persistence
//
private extension DashboardViewModel {
    @MainActor
    func loadDashboardCardsFromStorage() async {
        let storageCards = await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadDashboardCards(siteID: siteID, onCompletion: { cards in
                continuation.resume(returning: cards)
            }))
        }
        savedCards = storageCards ?? []
        observeValuesForDashboardCards()
        observeDashboardCardsAndReload()
    }

    func saveDashboardCards(cards: [DashboardCard]) {
        stores.dispatch(AppSettingsAction.setDashboardCards(siteID: siteID, cards: cards))
        savedCards = cards
    }
}

// MARK: Reload cards

private extension DashboardViewModel {
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
                await self?.blazeCampaignDashboardViewModel.checkAvailability()
            }
            group.addTask { [weak self] in
                await self?.updateJetpackBannerVisibilityFromAppSettings()
            }
            group.addTask { [weak self] in
                await self?.updateHasOrdersStatus()
            }
            group.addTask { [weak self] in
                await self?.googleAdsDashboardCardViewModel.checkAvailability()
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
    }

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
                        await self.reloadCardsIfNeeded(newlyEnabledCards)
                    }
                }
            })
            .store(in: &subscriptions)
    }

    @MainActor
    func reloadCardsIfNeeded(_ cards: [DashboardCard], forceRefresh: Bool = false) async {
        await withTaskGroup(of: Void.self) { group in
            cards.forEach { card in
                switch card.type {
                case .onboarding:
                    group.addTask { [weak self] in
                        await self?.reloadStoreOnboardingTasks()
                    }
                case .performance:
                    group.addTask { [weak self] in
                        await self?.storePerformanceViewModel.reloadDataIfNeeded(forceRefresh: forceRefresh)
                    }
                case .topPerformers:
                    group.addTask { [weak self] in
                        await self?.topPerformersViewModel.reloadDataIfNeeded(forceRefresh: forceRefresh)
                    }
                case .blaze:
                    group.addTask { [weak self] in
                        await self?.reloadBlazeCampaignView()
                    }
                case .inbox:
                    group.addTask { [weak self] in
                        await self?.inboxViewModel.reloadData()
                    }
                case .coupons:
                    group.addTask { [weak self] in
                        await self?.mostActiveCouponsViewModel.reloadData()
                    }
                case .stock:
                    group.addTask { [weak self] in
                        await self?.productStockCardViewModel.reloadData()
                    }
                case .reviews:
                    group.addTask { [weak self] in
                        await self?.reviewsViewModel.reloadData()
                    }
                case .lastOrders:
                    group.addTask { [weak self] in
                        await self?.lastOrdersCardViewModel.reloadData()
                    }
                case .googleAds:
                    group.addTask { [weak self] in
                        await self?.googleAdsDashboardCardViewModel.reloadCard()
                    }
                }
            }
        }
    }

    /// Reload supported card data if needed, but only if we are not already loading data.
    ///
    func reloadCardsWithBackgroundUpdateSupportIfNeeded() async {
        guard !isReloadingAllData else {
            return
        }

        let supportedCards = Set(DashboardTimestampStore.Card.allCases.map { $0.dashboardCard } )
        let supportedVisibleCards = showOnDashboardCards.filter { supportedCards.contains($0.type) }

        await reloadCardsIfNeeded(supportedVisibleCards)
    }
}

// MARK: Private helpers
private extension DashboardViewModel {
    func observeValuesForDashboardCards() {
        storeOnboardingViewModel.$canShowInDashboard
            .combineLatest(blazeCampaignDashboardViewModel.$canShowInDashboard)
            .combineLatest(googleAdsDashboardCardViewModel.$canShowOnDashboard,
                           $hasOrders,
                           $isEligibleForInbox)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] combinedResult in
                guard let self else { return }
                let ((canShowOnboarding, canShowBlaze), canShowGoogle, hasOrders, isEligibleForInbox) = combinedResult
                updateDashboardCards(canShowOnboarding: canShowOnboarding,
                                     canShowBlaze: canShowBlaze,
                                     canShowGoogle: canShowGoogle,
                                     canShowInbox: isEligibleForInbox,
                                     hasOrders: hasOrders)
            }
            .store(in: &subscriptions)
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

    func checkInboxEligibility() {
        isEligibleForInbox = inboxEligibilityChecker.isEligibleForInbox(siteID: siteID)
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
        googleAdsDashboardCardViewModel.onDismiss = showCustomizationScreen
    }

    func generateDefaultCards(canShowOnboarding: Bool,
                              canShowBlaze: Bool,
                              canShowGoogle: Bool,
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

        cards.append(DashboardCard(type: .googleAds,
                                   availability: canShowGoogle ? .show : .hide,
                                   enabled: canShowGoogle))

        return cards
    }

    func updateDashboardCards(canShowOnboarding: Bool,
                              canShowBlaze: Bool,
                              canShowGoogle: Bool,
                              canShowInbox: Bool,
                              hasOrders: Bool) {

        let canShowAnalytics = hasOrders
        let canShowLastOrders = hasOrders

        // First, generate latest cards state based on current canShow states
        let initialCards = generateDefaultCards(canShowOnboarding: canShowOnboarding,
                                                canShowBlaze: canShowBlaze,
                                                canShowGoogle: canShowGoogle,
                                                canShowAnalytics: canShowAnalytics,
                                                canShowLastOrders: canShowLastOrders,
                                                canShowInbox: canShowInbox)

        // Next, get saved cards and preserve existing enabled state for all available cards.
        // This is needed because even if a user already disabled an available card and saved it, in `initialCards`
        // the same card might be set to be enabled. To respect user's setting, we need to check the saved state and re-apply it.
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

        configureNewCardsNotice(hasOrders: hasOrders)
    }

    /// Determines whether to show the notice that new cards are available and can be found in the Customize screen.
    /// - Parameter hasOrders: A Boolean indicating whether the site has orders. If the site has no orders,
    ///   the app will display the "Share Your Store" card, and the notice should remain hidden.
    func configureNewCardsNotice(hasOrders: Bool) {
        guard hasOrders else {
            return
        }

        let savedCardTypes = Set(savedCards.map { $0.type })
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

// MARK: - Constants
//
private extension DashboardViewModel {
    enum Constants: Sendable {
        static let topEarnerStatsLimit: Int = 5
        static let dashboardScreenName = "my_store"
        static let orderPageNumber = 1
        static let orderPageSize = 1

        static let m2CardSet: Set<DashboardCard.CardType> = [.inbox, .reviews, .coupons, .stock, .lastOrders]
    }
}
