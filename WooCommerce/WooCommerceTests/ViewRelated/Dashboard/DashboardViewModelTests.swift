import XCTest
import Fakes
import Yosemite
import enum NetworkingCore.DotcomError
import protocol WooFoundation.Analytics
import protocol Storage.StorageType
import YosemiteTestHelpers
@testable import WooCommerce

final class DashboardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 122

    private var analytics: Analytics!
    private var analyticsProvider: MockAnalyticsProvider!
    private var stores: MockStoresManager!
    private var userDefaults: UserDefaults!

    private let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)

    private let inboxEligibilityChecker = MockInboxEligibilityChecker()
    private let googleAdsEligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: false)

    /// Mock Storage: InMemory
    private var storageManager: MockStorageManager!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    private lazy var site = Site.fake().copy(
        siteID: sampleSiteID,
        isJetpackThePluginInstalled: true,
        isJetpackConnected: true
    )

    override func setUpWithError() throws {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        storageManager = MockStorageManager()

        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(site)

        // Set up basic mocks for actions dispatched during DashboardViewModel initialization.
        // Child view models dispatch actions in Task blocks during init, so these mocks
        // must be in place before any DashboardViewModel is created.
        setUpBasicMocks()
    }

    /// Sets up mock handlers for actions that are dispatched during DashboardViewModel initialization.
    /// This prevents Swift continuation leaks from unhandled async actions in child view models.
    private func setUpBasicMocks(for targetStores: MockStoresManager? = nil) {
        let storesManager = targetStores ?? stores!

        // AppSettingsAction - dispatched by child view models during init and data loading
        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadLastSelectedPerformanceTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedTopPerformersTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedMostActiveCouponsTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedStockType(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedOrderStatus(_, onCompletion):
                onCompletion(nil)
            case let .getPOSSurveyPotentialMerchantNotificationScheduled(onCompletion):
                onCompletion(false)
            case let .getPOSSurveyCurrentMerchantNotificationScheduled(onCompletion):
                onCompletion(false)
            default:
                break
            }
        }

        // OrderAction - dispatched by configureOrdersResultController during init
        storesManager.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .checkIfStoreHasOrders(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        // StatsActionV4 - dispatched by stats view models during data sync
        storesManager.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveStats(_, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteVisitStats(_, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            default:
                break
            }
        }

        // GoogleAdsAction - dispatched by Google Ads view models
        storesManager.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .checkConnection(_, onCompletion):
                onCompletion(.success(.fake()))
            case let .fetchAdsCampaigns(_, onCompletion):
                onCompletion(.success([]))
            default:
                break
            }
        }
    }

    @MainActor
    func test_default_statsVersion_is_v4() {
        // Given
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // Then
        XCTAssertEqual(viewModel.statsVersion, .v4)
    }

    @MainActor
    func test_view_model_syncs_just_in_time_messages() async {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(title: "JITM Message")
        mockReloadingData(jitmResult: .success([message]))
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertEqual( viewModel.announcementViewModel?.title, "JITM Message")
    }

    @MainActor
    func test_no_announcement_to_display_when_no_announcements_are_synced() async {
        // Given
        mockReloadingData(jitmResult: .success([]))
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertNil(viewModel.announcementViewModel)
    }

    @MainActor
    func test_fetch_success_analytics_logged_when_just_in_time_messages_retrieved() async {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(messageID: "test-message-id",
                                                             featureClass: "test-feature-class")

        let secondMessage = Yosemite.JustInTimeMessage.fake().copy(messageID: "test-message-id-2",
                                                                   featureClass: "test-feature-class-2")
        mockReloadingData(jitmResult: .success([message, secondMessage]))
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           storageManager: storageManager,
                                           analytics: analytics,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(of: "jitm_fetch_success"),
              let properties = analyticsProvider.receivedProperties[eventIndex] as? [String: AnyHashable]
        else {
            return XCTFail("Expected event was not logged")
        }

        assertEqual("my_store", properties["source"] as? String)
        assertEqual("test-message-id", properties["jitm"] as? String)
        assertEqual(2, properties["count"] as? Int64)
    }

    @MainActor
    func test_when_two_messages_are_received_only_the_first_is_displayed() async {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(title: "Higher priority JITM")

        let secondMessage = Yosemite.JustInTimeMessage.fake().copy(title: "Lower priority JITM")
        mockReloadingData(jitmResult: .success([message, secondMessage]))
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           storageManager: storageManager,
                                           analytics: analytics,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertEqual(viewModel.announcementViewModel?.title, "Higher priority JITM")
    }

    @MainActor
    func test_fetch_failure_analytics_logged_when_just_in_time_message_errors() async {
        // Given
        let error = DotcomError.noRestRoute()
        mockReloadingData(jitmResult: .failure(error))
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           storageManager: storageManager,
                                           analytics: analytics,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(of: "jitm_fetch_failure"),
              let properties = analyticsProvider.receivedProperties[eventIndex] as? [String: AnyHashable]
        else {
            return XCTFail("Expected event was not logged")
        }

        assertEqual("my_store", properties["source"] as? String)
        assertEqual("NetworkingCore.DotcomError", properties["error_domain"] as? String)
        assertEqual("Dotcom Invalid REST Route", properties["error_description"] as? String)
    }

    @MainActor
    func test_when_no_messages_are_received_existing_messages_are_removed() async {
        // Given
        mockReloadingData(jitmResult: .success([]))

        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           storageManager: storageManager,
                                           analytics: analytics,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        viewModel.announcementViewModel = JustInTimeMessageViewModel(
            justInTimeMessage: .fake(),
            screenName: "my_store",
            siteID: sampleSiteID)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertNil(viewModel.announcementViewModel)
    }

    @MainActor
    func test_siteURLToShare_return_nil_if_site_is_not_public() {
        // Given
        let sessionManager = SessionManager.makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(visibility: .privateSite)
        let localStores = MockStoresManager(sessionManager: sessionManager)
        setUpBasicMocks(for: localStores)
        let viewModel = DashboardViewModel(siteID: 123,
                                           stores: localStores,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        let siteURLToShare = viewModel.siteURLToShare

        // Then
        XCTAssertNil(siteURLToShare)
    }

    @MainActor
    func test_siteURLToShare_return_url_if_site_is_public() {
        // Given
        let sessionManager = SessionManager.makeForTesting()
        let expectedURL = "https://example.com"
        sessionManager.defaultSite = Site.fake().copy(url: expectedURL, visibility: .publicSite)
        let localStores = MockStoresManager(sessionManager: sessionManager)
        setUpBasicMocks(for: localStores)
        let viewModel = DashboardViewModel(siteID: 123,
                                           stores: localStores,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        let siteURLToShare = viewModel.siteURLToShare

        // Then
        assertEqual(expectedURL, siteURLToShare?.absoluteString)
    }

    @MainActor
    func test_different_timezones_correctly_trigger_tracks_with_parameters() {
        // Given
        let localTimezone = TimeZone(secondsFromGMT: -3600)
        let siteGMTOffset = 0.0
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           analytics: analytics,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        viewModel.trackStatsTimezone(localTimezone: localTimezone!, siteGMTOffset: siteGMTOffset)

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(of: "dashboard_store_timezone_differ_from_device"),
              let properties = analyticsProvider.receivedProperties[eventIndex] as? [String: AnyHashable]
        else {
            return XCTFail("Expected event was not logged")
        }

        assertEqual("-1", properties["local_timezone"] as? String)
        assertEqual("0", properties["store_timezone"] as? String)
    }

    @MainActor
    func test_different_decimal_timezones_correctly_trigger_tracks_with_parameters() {
        // Given
        let localTimezone = TimeZone(secondsFromGMT: -5400)
        let siteGMTOffset = 2.50000
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           analytics: analytics,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        viewModel.trackStatsTimezone(localTimezone: localTimezone!, siteGMTOffset: siteGMTOffset)

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(of: "dashboard_store_timezone_differ_from_device"),
              let properties = analyticsProvider.receivedProperties[eventIndex] as? [String: AnyHashable]
        else {
            return XCTFail("Expected event was not logged")
        }

        assertEqual("-1.5", properties["local_timezone"] as? String)
        assertEqual("2.5", properties["store_timezone"] as? String)
    }

    @MainActor
    func test_same_local_and_store_timezone_do_not_trigger_tracks() {
        // Given
        let localTimezone = TimeZone(secondsFromGMT: -7200)
        let siteGMTOffset = -2.0
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           analytics: analytics,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        viewModel.trackStatsTimezone(localTimezone: localTimezone!, siteGMTOffset: siteGMTOffset)

        // Then
        XCTAssertNil(analyticsProvider.receivedEvents.firstIndex(of: "dashboard_store_timezone_differ_from_device"))
    }

    // MARK: Customize dashboard cards
    @MainActor
    func test_dashboard_cards_are_saved_to_app_settings() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = ["0": true]
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           userDefaults: defaults,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        var setDashboardCardsActionCalled = false

        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case .setDashboardCards = action {
                setDashboardCardsActionCalled = true
            }
        }

        // When
        viewModel.didCustomizeDashboardCards([.init(type: .onboarding, availability: .show, enabled: true)])

        // Then
        XCTAssertTrue(setDashboardCardsActionCalled)
    }

    @MainActor
    func test_editorSaveTapped_is_tracked_when_customizing_onboarding_card() throws {
        // Given
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           analytics: analytics,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        let cards: [DashboardCard] = [DashboardCard(type: .onboarding, availability: .show, enabled: false),
                                      DashboardCard(type: .performance, availability: .show, enabled: true),
                                      DashboardCard(type: .blaze, availability: .show, enabled: true),
                                      DashboardCard(type: .topPerformers, availability: .show, enabled: false)]

        // When
        viewModel.didCustomizeDashboardCards(cards)

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "dynamic_dashboard_editor_save_tapped" }))
        let properties = analyticsProvider.receivedProperties[index] as? [String: AnyHashable]
        XCTAssertEqual(properties?["cards"], "blaze,performance")
        XCTAssertEqual(properties?["sorted_cards"], "performance,blaze")
    }

    // MARK: Dashboard cards

    @MainActor
    func test_generated_default_cards_are_as_expected_when_site_is_eligible_for_inbox() async throws {
        // Given
        let inboxEligibilityChecker = MockInboxEligibilityChecker()
        inboxEligibilityChecker.isEligible = true

        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: MockAIAssistantEligibilityChecker(isEligible: false))
        mockReloadingData(storeHasOrders: false)

        let expectedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
                             DashboardCard(type: .aiAssistant, availability: .hide, enabled: false),
                             DashboardCard(type: .performance, availability: .unavailable, enabled: false),
                             DashboardCard(type: .topPerformers, availability: .unavailable, enabled: false),
                             DashboardCard(type: .blaze, availability: .hide, enabled: false),
                             DashboardCard(type: .inbox, availability: .show, enabled: false),
                             DashboardCard(type: .reviews, availability: .show, enabled: false),
                             DashboardCard(type: .coupons, availability: .show, enabled: false),
                             DashboardCard(type: .stock, availability: .show, enabled: false),
                             DashboardCard(type: .lastOrders, availability: .unavailable, enabled: false),
                             DashboardCard(type: .googleAds, availability: .hide, enabled: false)]

        // When
        await viewModel.reloadAllData()

        // Then
        assertEqual(expectedCards, viewModel.dashboardCards)

        assertEqual([.onboarding, .shareStore],
                    viewModel.showOnDashboardCards.map(\.type))
        assertEqual([.onboarding], viewModel.showOnDashboardFirstColumn.map(\.type))
        assertEqual([.shareStore], viewModel.showOnDashboardSecondColumn.map(\.type))
    }

    @MainActor
    func test_generated_default_cards_are_as_expected_when_site_is_not_eligible_for_inbox() async throws {
        // Given
        inboxEligibilityChecker.isEligible = false

        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: MockAIAssistantEligibilityChecker(isEligible: false))
        mockReloadingData(storeHasOrders: false)

        let expectedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
                             DashboardCard(type: .aiAssistant, availability: .hide, enabled: false),
                             DashboardCard(type: .performance, availability: .unavailable, enabled: false),
                             DashboardCard(type: .topPerformers, availability: .unavailable, enabled: false),
                             DashboardCard(type: .blaze, availability: .hide, enabled: false),
                             DashboardCard(type: .inbox, availability: .hide, enabled: false),
                             DashboardCard(type: .reviews, availability: .show, enabled: false),
                             DashboardCard(type: .coupons, availability: .show, enabled: false),
                             DashboardCard(type: .stock, availability: .show, enabled: false),
                             DashboardCard(type: .lastOrders, availability: .unavailable, enabled: false),
                             DashboardCard(type: .googleAds, availability: .hide, enabled: false)]

        // When
        await viewModel.reloadAllData()

        // Then
        assertEqual(expectedCards, viewModel.dashboardCards)

        assertEqual([.onboarding, .shareStore],
                    viewModel.showOnDashboardCards.map(\.type))
        assertEqual([.onboarding], viewModel.showOnDashboardFirstColumn.map(\.type))
        assertEqual([.shareStore], viewModel.showOnDashboardSecondColumn.map(\.type))
    }

    @MainActor
    func test_dashboard_cards_contain_enabled_analytics_cards_when_there_is_order() async throws {
        // Given
        let order = Order.fake().copy(siteID: sampleSiteID)
        insertSampleOrder(readOnlyOrder: order)

        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: MockAIAssistantEligibilityChecker(isEligible: false))

        mockReloadingData(storeHasOrders: true)

        // Analytics cards need to be set with availability: .show and enabled: true to make them available and shown.
        let expectedPerformanceCard = DashboardCard(type: .performance, availability: .show, enabled: true)
        let expectedTopPerformersCard = DashboardCard(type: .topPerformers, availability: .show, enabled: true)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.dashboardCards.contains(expectedPerformanceCard))
        XCTAssertTrue(viewModel.dashboardCards.contains(expectedTopPerformersCard))

        assertEqual([.onboarding, .performance, .topPerformers, .newCardsNotice],
                    viewModel.showOnDashboardCards.map(\.type))
        assertEqual([.onboarding, .topPerformers],
                    viewModel.showOnDashboardFirstColumn.map(\.type))
        assertEqual([.performance, .newCardsNotice],
                    viewModel.showOnDashboardSecondColumn.map(\.type))
    }

    @MainActor
    func test_dashboard_cards_contain_enabled_last_orders_cards_when_there_is_order() async {
        // Given
        let order = Order.fake().copy(siteID: sampleSiteID)
        insertSampleOrder(readOnlyOrder: order)
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        mockReloadingData()

        // Last orders cards need to be set with availability: .show and enabled: false to make them available.
        let expectedLastOrdersCard = DashboardCard(type: .lastOrders, availability: .show, enabled: false)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.dashboardCards.contains(expectedLastOrdersCard))
    }

    @MainActor
    func test_dashboard_cards_has_disabled_onboarding_card_if_all_tasks_are_completed() async throws {
        // Given
        userDefaults[.completedAllStoreOnboardingTasks] = [String(sampleSiteID): true]

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        mockReloadingData()

        // When
        await viewModel.reloadAllData()

        // Then
        let onboardingCard = try XCTUnwrap(viewModel.dashboardCards.first(where: {$0.type == .onboarding }))
        XCTAssertFalse(onboardingCard.enabled)
    }

    @MainActor
    func test_dashboard_cards_respects_enabled_setting_from_saved_cards() async throws {
        // Given
        // Add order so that analytics cards are enabled
        let order = Order.fake().copy(siteID: sampleSiteID)
        insertSampleOrder(readOnlyOrder: order)

        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: MockAIAssistantEligibilityChecker(isEligible: false))

        let storedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
                           DashboardCard(type: .performance, availability: .show, enabled: true),
                           DashboardCard(type: .topPerformers, availability: .show, enabled: false)]

        mockReloadingData(storedDashboardCards: storedCards)

        // When
        await viewModel.reloadAllData()

        // Then
        let performanceCard = try XCTUnwrap(viewModel.dashboardCards.first(where: {$0.type == .performance }))
        XCTAssertTrue(performanceCard.enabled)

        let topPerformersCard = try XCTUnwrap(viewModel.dashboardCards.first(where: {$0.type == .topPerformers }))
        XCTAssertFalse(topPerformersCard.enabled)

        assertEqual([.onboarding, .performance, .newCardsNotice],
                    viewModel.showOnDashboardCards.map(\.type))
        assertEqual([.onboarding, .newCardsNotice],
                    viewModel.showOnDashboardFirstColumn.map(\.type))
        assertEqual([.performance], viewModel.showOnDashboardSecondColumn.map(\.type))
    }

    @MainActor
    func test_dashboard_cards_contain_google_ads_card_when_store_is_eligible() async throws {
        // Given
        let googleAdsEligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: true)

        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: MockAIAssistantEligibilityChecker(isEligible: false))

        mockReloadingData()

        // Google card need to be set with availability: .show and enabled: true by default if available.
        let expectedGoogleCard = DashboardCard(type: .googleAds, availability: .show, enabled: true)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.dashboardCards.contains(expectedGoogleCard))

        assertEqual([.onboarding, .performance, .topPerformers, .googleAds, .newCardsNotice],
                    viewModel.showOnDashboardCards.map(\.type))
        assertEqual([.onboarding, .topPerformers, .newCardsNotice],
                    viewModel.showOnDashboardFirstColumn.map(\.type))
        assertEqual([.performance, .googleAds], viewModel.showOnDashboardSecondColumn.map(\.type))
    }

    @MainActor
    func test_dashboard_cards_contain_stock_card_when_store_is_eligible_and_non_ciab() async throws {
        // Given
        let siteCIABChecker = MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: false)
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           siteIsCIABEligibilityChecker: siteCIABChecker)

        mockReloadingData()

        // Stock card need to be set with availability: .show and enabled: true by default if available.
        let expectedStockCard = DashboardCard(type: .stock, availability: .show, enabled: false)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.dashboardCards.contains(expectedStockCard))
    }

    @MainActor
    func test_dashboard_cards_does_not_contain_stock_card_when_store_is_eligible_and_ciab() async throws {
        // Given
        let siteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: true,
            mockedCIABSites: [site]
        )
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           siteIsCIABEligibilityChecker: siteCIABChecker)

        mockReloadingData()

        // Stock card need to be set with availability: .show and enabled: true by default if available.
        let expectedStockCard = DashboardCard(type: .stock, availability: .show, enabled: false)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.dashboardCards.contains(expectedStockCard))
    }

    @MainActor
    func test_dashboard_cards_contain_onboarding_card_when_store_is_non_ciab() async throws {
        // Given
        let siteCIABChecker = MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: false)
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           siteIsCIABEligibilityChecker: siteCIABChecker)

        mockReloadingData(storeHasOrders: false)

        let expectedOnboardingCard = DashboardCard(type: .onboarding, availability: .show, enabled: true)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.dashboardCards.contains(expectedOnboardingCard))
    }

    @MainActor
    func test_dashboard_cards_does_not_contain_onboarding_card_when_store_is_ciab() async throws {
        // Given
        let siteCIABChecker = MockCIABEligibilityChecker(
            mockedIsCurrentSiteCIAB: true,
            mockedCIABSites: [site]
        )
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           siteIsCIABEligibilityChecker: siteCIABChecker)

        mockReloadingData(storeHasOrders: false)

        let expectedOnboardingCard = DashboardCard(type: .onboarding, availability: .show, enabled: true)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.dashboardCards.contains(expectedOnboardingCard))
    }

    // MARK: Show New Cards Notice

    @MainActor
    func test_showNewCardsNotice_is_false_when_all_new_cards_are_already_in_saved_cards() async {
        // Given
        inboxEligibilityChecker.isEligible = true

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        let completeCardsSet: [DashboardCard] = [
            .init(type: .inbox, availability: .show, enabled: true),
            .init(type: .reviews, availability: .show, enabled: true),
            .init(type: .coupons, availability: .show, enabled: true),
            .init(type: .stock, availability: .show, enabled: true),
            .init(type: .lastOrders, availability: .show, enabled: true)
        ]
        mockReloadingData(storedDashboardCards: completeCardsSet)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.showNewCardsNotice)
        XCTAssert(!viewModel.showOnDashboardCards.contains(where: { $0.type == .newCardsNotice }))
    }

    @MainActor
    func test_showNewCardsNotice_is_true_when_not_all_new_cards_are_in_saved_cards() async {
        // Given
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        let incompleteNewCardsSet: [DashboardCard] = []
        mockReloadingData(storedDashboardCards: incompleteNewCardsSet)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.showNewCardsNotice)
        XCTAssert(viewModel.showOnDashboardCards.contains(where: { $0.type == .newCardsNotice }))
    }

    @MainActor
    func test_showNewCardsNotice_changes_from_true_to_false_after_showing_customize_screen_and_dismissing_it() async {
        // Given
        let incompleteNewCardsSet: [DashboardCard] = [
            .init(type: .inbox, availability: .show, enabled: false),
            .init(type: .reviews, availability: .show, enabled: false)
        ]
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        mockReloadingData(storedDashboardCards: incompleteNewCardsSet)

        // When
        await viewModel.reloadAllData()

        XCTAssertTrue(viewModel.showNewCardsNotice)
        XCTAssert(viewModel.showOnDashboardCards.contains(where: { $0.type == .newCardsNotice }))
        viewModel.showCustomizationScreen() // Simulate showing Customize screen
        viewModel.handleCustomizationDismissal() // Simulate dismissing Customize screen

        // Then
        XCTAssertFalse(viewModel.showNewCardsNotice) // Check it's false after dismissing Customize screen
        XCTAssert(!viewModel.showOnDashboardCards.contains(where: { $0.type == .newCardsNotice }))
    }

    // MARK: In app feedback card

    @MainActor
    func test_inAppFeedbackCard_is_not_available_when_feedback_is_not_needed() async {
        // Given
        let inboxEligibilityChecker = MockInboxEligibilityChecker()
        inboxEligibilityChecker.isEligible = true

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        mockReloadingData(shouldShowInAppFeedback: false)

        // When
        await viewModel.reloadAllData()
        await viewModel.onViewAppear()

        // Then
        let index = viewModel.showOnDashboardCards.firstIndex(where: { $0.type == .inAppFeedback })
        XCTAssert(index == nil)
    }

    @MainActor
    func test_inAppFeedbackCard_is_available_when_feedback_is_needed() async {
        // Given
        let inboxEligibilityChecker = MockInboxEligibilityChecker()
        inboxEligibilityChecker.isEligible = true

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: MockAIAssistantEligibilityChecker(isEligible: false))
        mockReloadingData(shouldShowInAppFeedback: true)

        // When
        await viewModel.reloadAllData()
        await viewModel.onViewAppear()

        // Then
        let index = viewModel.showOnDashboardCards.firstIndex(where: { $0.type == .inAppFeedback })
        XCTAssert(index == 1)
    }

    // MARK: Local notifications

    @MainActor
    func test_local_notification_scheduler_starts_observing_user_responses_upon_init() async throws {
        // Given
        let scheduler = MockBlazeLocalNotificationScheduler()
        _ = DashboardViewModel(siteID: sampleSiteID,
                               stores: stores,
                               storageManager: storageManager,
                               blazeEligibilityChecker: blazeEligibilityChecker,
                               inboxEligibilityChecker: inboxEligibilityChecker,
                               googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                               localNotificationScheduler: scheduler)

        // Then
        XCTAssertTrue(scheduler.observeNotificationUserResponseCalled)
    }

    @MainActor
    func test_no_campaign_reminder_local_notification_scheduler_starts_once_view_appears() async throws {
        // Given
        let scheduler = MockBlazeLocalNotificationScheduler()
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           localNotificationScheduler: scheduler)
        mockReloadingData()

        // When
        await viewModel.reloadAllData()
        await viewModel.onViewAppear()

        // Then
        await until {
            scheduler.scheduleNoCampaignReminderCalled == true
        }
    }

    // MARK: - Announcement Banner Visibility Tests

    @MainActor
    func test_shouldShowAnnouncementBanner_returns_false_when_no_announcement() async {
        // Given
        mockReloadingData(jitmResult: .success([]))
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertNil(viewModel.announcementViewModel)
        XCTAssertFalse(viewModel.shouldShowAnnouncementBanner)
    }

    @MainActor
    func test_shouldShowAnnouncementBanner_returns_true_when_announcement_exists() async throws {
        // Given - announcement exists and onboarding card is not enabled (all tasks completed)
        let message = Yosemite.JustInTimeMessage.fake().copy(title: "JITM Message")
        mockReloadingData(jitmResult: .success([message]))

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then - banner should be visible
        XCTAssertTrue(viewModel.shouldShowAnnouncementBanner)
    }

    // MARK: Self-driven push registration
    @MainActor
    func test_isSelfDrivenPushNotificationRegistered_returns_false_when_site_is_not_registered_with_Woo_PN() async {
        // Given
        mockReloadingData()
        let pushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [],
                                                            hasStoredSiteIDsRegisteredForWooPNs: true)
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           pushNotesManager: pushNotesManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.isSelfDrivenPushNotificationRegistered)
    }

    @MainActor
    func test_isSelfDrivenPushNotificationRegistered_returns_true_when_site_is_registered_and_not_wpcom_login() async {
        // Given
        mockReloadingData()
        stores.authenticate(credentials: SessionSettings.applicationPasswordCredentials)
        let pushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [sampleSiteID],
                                                            hasStoredSiteIDsRegisteredForWooPNs: true)
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           pushNotesManager: pushNotesManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.isSelfDrivenPushNotificationRegistered)
    }

    @MainActor
    func test_isSelfDrivenPushNotificationRegistered_returns_false_when_site_is_registered_and_wpcom_login() async {
        // Given
        mockReloadingData()
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        let pushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [sampleSiteID],
                                                            hasStoredSiteIDsRegisteredForWooPNs: true)

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           pushNotesManager: pushNotesManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.isSelfDrivenPushNotificationRegistered)
    }

    @MainActor
    func test_shouldSuggestWPComConnection_returns_false_when_site_is_not_registered_and_not_wpcom_login_and_not_eligible() async {
        // Given
        mockReloadingData()
        stores.authenticate(credentials: SessionSettings.applicationPasswordCredentials)
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = false
        let pushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [],
                                                            hasStoredSiteIDsRegisteredForWooPNs: true)

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           pushNotesManager: pushNotesManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           pushNotificationEligibilityChecker: eligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.shouldSuggestWPComConnection)
    }

    @MainActor
    func test_shouldSuggestWPComConnection_returns_true_when_site_is_not_registered_and_not_wpcom_login_and_eligible() async {
        // Given
        mockReloadingData()
        stores.authenticate(credentials: SessionSettings.applicationPasswordCredentials)
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let pushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [],
                                                            hasStoredSiteIDsRegisteredForWooPNs: true)

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           pushNotesManager: pushNotesManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           pushNotificationEligibilityChecker: eligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.shouldSuggestWPComConnection)
    }

    @MainActor
    func test_shouldSuggestWPComConnection_returns_false_when_site_is_registered_with_Woo_PN_and_not_wpcom_login() async {
        // Given
        mockReloadingData()
        stores.authenticate(credentials: SessionSettings.applicationPasswordCredentials)
        let pushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [sampleSiteID],
                                                            hasStoredSiteIDsRegisteredForWooPNs: true)

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           pushNotesManager: pushNotesManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.shouldSuggestWPComConnection)
    }

    @MainActor
    func test_shouldSuggestWPComConnection_returns_false_when_site_is_not_registered_and_wpcom_login() async {
        // Given
        mockReloadingData()
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        let pushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [],
                                                            hasStoredSiteIDsRegisteredForWooPNs: true)

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           pushNotesManager: pushNotesManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.shouldSuggestWPComConnection)
    }

    @MainActor
    func test_shouldSuggestWPComConnection_returns_true_when_site_is_JCP_and_not_registered_and_eligible() async {
        // Given
        let jcpSite = Site.fake().copy(siteID: sampleSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        stores.updateDefaultStore(jcpSite)
        mockReloadingData()
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let pushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [],
                                                            hasStoredSiteIDsRegisteredForWooPNs: true)

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           pushNotesManager: pushNotesManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           pushNotificationEligibilityChecker: eligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.shouldSuggestWPComConnection)
    }

    @MainActor
    func test_hideWPComConnectionSuggestion_updates_relevant_properties() async {
        // Given
        mockReloadingData()
        stores.authenticate(credentials: SessionSettings.wpcomCredentials)
        let pushNotesManager = MockPushNotificationsManager(siteIDsRegisteredForWooPNs: [sampleSiteID],
                                                            hasStoredSiteIDsRegisteredForWooPNs: true)

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           pushNotesManager: pushNotesManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        // When
        viewModel.hideWPComConnectionSuggestion()
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.shouldSuggestWPComConnection)
        XCTAssertTrue(viewModel.dismissedWPComConnectionSuggestion)
    }

    @MainActor
    func test_dashboard_when_aiAssistant_eligible_and_no_saved_cards_then_card_is_show_and_enabled() async throws {
        // Given
        mockReloadingData()
        let checker = MockAIAssistantEligibilityChecker(isEligible: true)
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: checker)

        // When
        await viewModel.reloadAllData()
        await until { viewModel.dashboardCards.contains(where: { $0.type == .aiAssistant }) }

        // Then
        let card = try XCTUnwrap(viewModel.dashboardCards.first(where: { $0.type == .aiAssistant }))
        XCTAssertEqual(card.availability, .show)
        XCTAssertTrue(card.enabled)
        XCTAssertTrue(viewModel.showOnDashboardCards.contains(where: { $0.type == .aiAssistant }))
    }

    @MainActor
    func test_dashboard_when_aiAssistant_not_eligible_then_card_is_hidden() async throws {
        // Given
        mockReloadingData()
        let checker = MockAIAssistantEligibilityChecker(isEligible: false)
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: checker)

        // When
        await viewModel.reloadAllData()

        // Then
        let card = try XCTUnwrap(viewModel.dashboardCards.first(where: { $0.type == .aiAssistant }))
        XCTAssertEqual(card.availability, .hide)
        XCTAssertFalse(viewModel.showOnDashboardCards.contains(where: { $0.type == .aiAssistant }))
    }

    @MainActor
    func test_dashboard_when_aiAssistant_disabled_in_customize_then_not_in_showOnDashboardCards() async {
        // Given
        let savedCards: [DashboardCard] = [
            DashboardCard(type: .performance, availability: .show, enabled: true),
            DashboardCard(type: .aiAssistant, availability: .show, enabled: false)
        ]
        mockReloadingData(storedDashboardCards: savedCards)
        let checker = MockAIAssistantEligibilityChecker(isEligible: true)
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: checker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.showOnDashboardCards.contains(where: { $0.type == .aiAssistant }))
    }

    @MainActor
    func test_aiAssistant_when_eligible_user_has_saved_cards_without_it_then_card_is_auto_inserted() async throws {
        // Given
        let savedCards: [DashboardCard] = [
            DashboardCard(type: .onboarding, availability: .show, enabled: true),
            DashboardCard(type: .performance, availability: .show, enabled: true),
            DashboardCard(type: .blaze, availability: .show, enabled: true)
        ]
        mockReloadingData(storedDashboardCards: savedCards)
        var capturedSaves: [[DashboardCard]] = []
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .setDashboardCards(_, cards):
                capturedSaves.append(cards)
            case let .loadDashboardCards(_, onCompletion):
                onCompletion(savedCards)
            case let .loadJetpackBenefitsBannerVisibility(_, _, completion):
                completion(false)
            case let .loadFeedbackVisibility(_, onCompletion):
                onCompletion(.success(false))
            case let .loadLastSelectedPerformanceTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedTopPerformersTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedMostActiveCouponsTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedStockType(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedOrderStatus(_, onCompletion):
                onCompletion(nil)
            case let .getPOSSurveyPotentialMerchantNotificationScheduled(onCompletion):
                onCompletion(false)
            case let .getPOSSurveyCurrentMerchantNotificationScheduled(onCompletion):
                onCompletion(false)
            default:
                break
            }
        }
        let checker = MockAIAssistantEligibilityChecker(isEligible: true)
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: checker)

        // When
        await viewModel.onViewAppear()

        // Then
        let updatedCards = try XCTUnwrap(capturedSaves.first)
        let aiIndex = try XCTUnwrap(updatedCards.firstIndex(where: { $0.type == .aiAssistant }))
        let onboardingIndex = try XCTUnwrap(updatedCards.firstIndex(where: { $0.type == .onboarding }))
        XCTAssertEqual(aiIndex, onboardingIndex + 1)
        XCTAssertTrue(updatedCards[aiIndex].enabled)
        XCTAssertEqual(updatedCards[aiIndex].availability, .show)
    }

    @MainActor
    func test_aiAssistant_when_already_in_saved_cards_disabled_then_no_re_insert() async {
        // Given
        let savedCards: [DashboardCard] = [
            DashboardCard(type: .onboarding, availability: .show, enabled: true),
            DashboardCard(type: .performance, availability: .show, enabled: true),
            DashboardCard(type: .aiAssistant, availability: .show, enabled: false)
        ]
        mockReloadingData(storedDashboardCards: savedCards)
        var setCardsCallCount = 0
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .setDashboardCards:
                setCardsCallCount += 1
            case let .loadDashboardCards(_, onCompletion):
                onCompletion(savedCards)
            case let .loadJetpackBenefitsBannerVisibility(_, _, completion):
                completion(false)
            case let .loadFeedbackVisibility(_, onCompletion):
                onCompletion(.success(false))
            case let .loadLastSelectedPerformanceTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedTopPerformersTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedMostActiveCouponsTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedStockType(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedOrderStatus(_, onCompletion):
                onCompletion(nil)
            case let .getPOSSurveyPotentialMerchantNotificationScheduled(onCompletion):
                onCompletion(false)
            case let .getPOSSurveyCurrentMerchantNotificationScheduled(onCompletion):
                onCompletion(false)
            default:
                break
            }
        }
        let checker = MockAIAssistantEligibilityChecker(isEligible: true)
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker,
                                           aiAssistantEligibilityChecker: checker)

        // When
        await viewModel.onViewAppear()

        // Then
        XCTAssertEqual(setCardsCallCount, 0)
    }

}

private final class MockAIAssistantEligibilityChecker: AIAssistantEligibilityCheckerProtocol {
    let isEligibleResult: Bool

    init(isEligible: Bool) {
        self.isEligibleResult = isEligible
    }

    func isEligible(for site: Site?) -> Bool {
        isEligibleResult
    }

    func isEligible(for site: Site?, useCache: Bool) async -> Bool {
        isEligibleResult
    }
}

private extension DashboardViewModelTests {

    func mockReloadingData(jitmResult: Result<[Yosemite.JustInTimeMessage], Error> = .success([]),
                           storeHasOrders: Bool = true,
                           existingProducts: [Product] = [],
                           existingBlazeCampaigns: [BlazeCampaignListItem] = [],
                           storedDashboardCards: [DashboardCard] = [],
                           shouldShowInAppFeedback: Bool = false) {
        stores.whenReceivingAction(ofType: JustInTimeMessageAction.self) { action in
            switch action {
            case let .loadMessage(_, _, _, completion):
                completion(jitmResult)
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadJetpackBenefitsBannerVisibility(_, _, completion):
                completion(false)
            case let .loadDashboardCards(_, onCompletion):
                onCompletion(storedDashboardCards)
            case let .loadFeedbackVisibility(_, onCompletion):
                onCompletion(.success(shouldShowInAppFeedback))
            case let .loadLastSelectedPerformanceTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedTopPerformersTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedMostActiveCouponsTimeRange(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedStockType(_, onCompletion):
                onCompletion(nil)
            case let .loadLastSelectedOrderStatus(_, onCompletion):
                onCompletion(nil)
            case let .getPOSSurveyPotentialMerchantNotificationScheduled(onCompletion):
                onCompletion(false)
            case let .getPOSSurveyCurrentMerchantNotificationScheduled(onCompletion):
                onCompletion(false)
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .checkIfStoreHasOrders(_, onCompletion):
                onCompletion(.success(storeHasOrders))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: ProductAction.self) { [weak self] action in
            switch action {
            case .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, let onCompletion):
                for product in existingProducts {
                    self?.insertProduct(product)
                }
                onCompletion(.success(true))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: BlazeAction.self) { [weak self] action in
            switch action {
            case .synchronizeCampaignsList(_, _, _, let onCompletion):
                self?.insertCampaigns(existingBlazeCampaigns)
                onCompletion(.success(false))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveStats(_, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteVisitStats(_, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: GoogleAdsAction.self) { action in
            switch action {
            case let .checkConnection(_, onCompletion):
                onCompletion(.success(.fake()))
            case let .fetchAdsCampaigns(_, onCompletion):
                onCompletion(.success([]))
            default:
                break
            }
        }
    }

    func insertProduct(_ readOnlyProduct: Product) {
        storageManager.performAndSave({ storage in
            let newProduct = storage.insertNewObject(ofType: StorageProduct.self)
            newProduct.update(with: readOnlyProduct)
        }, completion: nil, on: .main)
    }

    func insertCampaigns(_ readOnlyCampaigns: [BlazeCampaignListItem]) {
        storageManager.performAndSave({ storage in
            readOnlyCampaigns.forEach { campaign in
                let newCampaign = storage.insertNewObject(ofType: StorageBlazeCampaignListItem.self)
                newCampaign.update(with: campaign)
            }
        }, completion: nil, on: .main)
    }

    func insertSampleOrder(readOnlyOrder: Order) {
        storageManager.performAndSave({ storage in
            let newOrder = storage.insertNewObject(ofType: StorageOrder.self)
            newOrder.update(with: readOnlyOrder)
        }, completion: nil, on: .main)
    }
}
