import XCTest
import Fakes
import Yosemite
import enum Networking.DotcomError
import protocol WooFoundation.Analytics
import protocol Storage.StorageType
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

    override func setUpWithError() throws {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        stores = MockStoresManager(sessionManager: .makeForTesting())
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: "DashboardViewModelTests"))
        storageManager = MockStorageManager()
    }

    @MainActor
    func test_default_statsVersion_is_v4() {
        // Given
        let viewModel = DashboardViewModel(siteID: 0)

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
                                           blazeEligibilityChecker: blazeEligibilityChecker)

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
                                           blazeEligibilityChecker: blazeEligibilityChecker)

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
                                           blazeEligibilityChecker: blazeEligibilityChecker)

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
                                           blazeEligibilityChecker: blazeEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertEqual(viewModel.announcementViewModel?.title, "Higher priority JITM")
    }

    @MainActor
    func test_fetch_failure_analytics_logged_when_just_in_time_message_errors() async {
        // Given
        let error = DotcomError.noRestRoute
        mockReloadingData(jitmResult: .failure(error))
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           storageManager: storageManager,
                                           analytics: analytics,
                                           blazeEligibilityChecker: blazeEligibilityChecker)

        // When
        await viewModel.reloadAllData()

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(of: "jitm_fetch_failure"),
              let properties = analyticsProvider.receivedProperties[eventIndex] as? [String: AnyHashable]
        else {
            return XCTFail("Expected event was not logged")
        }

        assertEqual("my_store", properties["source"] as? String)
        assertEqual("Networking.DotcomError", properties["error_domain"] as? String)
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
                                           blazeEligibilityChecker: blazeEligibilityChecker)
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
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = DashboardViewModel(siteID: 123, stores: stores)

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
        let stores = MockStoresManager(sessionManager: sessionManager)
        let viewModel = DashboardViewModel(siteID: 123, stores: stores)

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
        let viewModel = DashboardViewModel(siteID: 0, stores: stores, analytics: analytics)

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
        let viewModel = DashboardViewModel(siteID: 0, stores: stores, analytics: analytics)

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
        let viewModel = DashboardViewModel(siteID: 0, stores: stores, analytics: analytics)

        // When
        viewModel.trackStatsTimezone(localTimezone: localTimezone!, siteGMTOffset: siteGMTOffset)

        // Then
        XCTAssertNil(analyticsProvider.receivedEvents.firstIndex(of: "dashboard_store_timezone_differ_from_device"))
    }

    // MARK: Dashboard cards
    @MainActor
    func test_dashboard_cards_are_saved_to_app_settings() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = true
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           userDefaults: defaults)
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
        let viewModel = DashboardViewModel(siteID: sampleSiteID, analytics: analytics)
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

    // MARK: hasOrders state
    @MainActor
    func test_hasOrders_is_true_when_site_has_orders() {
        // Given
        let insertOrder = Order.fake().copy(siteID: sampleSiteID)
        insertSampleOrder(readOnlyOrder: insertOrder)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.hasOrders)
    }

    @MainActor
    func test_hasOrders_is_false_when_site_has_no_orders() async {
        // Given
        mockReloadingData(storeHasOrders: false)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertFalse(viewModel.hasOrders)
    }

    @MainActor
    func test_hasOrders_is_true_when_remote_request_returns_true() async {
        // Given
        mockReloadingData(storeHasOrders: true)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.hasOrders)
    }

    // MARK: Dashboard cards

    @MainActor
    func test_generated_default_cards_are_as_expected_when_site_is_eligible_for_inbox() async {
        // Given
        let inboxEligibilityChecker = MockInboxEligibilityChecker()
        inboxEligibilityChecker.isEligible = true

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        mockReloadingData(storeHasOrders: false)

        let expectedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
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
    }

    @MainActor
    func test_generated_default_cards_are_as_expected_when_site_is_not_eligible_for_inbox() async {
        // Given
        inboxEligibilityChecker.isEligible = false

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)
        mockReloadingData(storeHasOrders: false)

        let expectedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
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
    }

    @MainActor
    func test_dashboard_cards_contain_enabled_analytics_cards_when_there_is_order() async {
        // Given
        let order = Order.fake().copy(siteID: sampleSiteID)
        insertSampleOrder(readOnlyOrder: order)

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        mockReloadingData(storeHasOrders: true)

        // Analytics cards need to be set with availability: .show and enabled: true to make them available and shown.
        let expectedPerformanceCard = DashboardCard(type: .performance, availability: .show, enabled: true)
        let expectedTopPerformersCard = DashboardCard(type: .topPerformers, availability: .show, enabled: true)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.dashboardCards.contains(expectedPerformanceCard))
        XCTAssertTrue(viewModel.dashboardCards.contains(expectedTopPerformersCard))
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
        userDefaults[.completedAllStoreOnboardingTasks] = true

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

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

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
    }

    @MainActor
    func test_dashboard_cards_contain_google_ads_card_when_store_is_eligible() async {
        // Given
        let googleAdsEligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: true)

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           googleAdsEligibilityChecker: googleAdsEligibilityChecker)

        mockReloadingData()

        // Google card need to be set with availability: .show and enabled: true by default if available.
        let expectedGoogleCard = DashboardCard(type: .googleAds, availability: .show, enabled: true)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.dashboardCards.contains(expectedGoogleCard))
    }

    // MARK: Show New Cards Notice

    @MainActor
    func test_showNewCardsNotice_is_false_when_all_new_cards_are_already_in_saved_cards() async {
        // Given
        inboxEligibilityChecker.isEligible = true

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           inboxEligibilityChecker: inboxEligibilityChecker)
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
    }

    @MainActor
    func test_showNewCardsNotice_is_true_when_not_all_new_cards_are_in_saved_cards() async {
        // Given
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           blazeEligibilityChecker: blazeEligibilityChecker,
                                           inboxEligibilityChecker: inboxEligibilityChecker)
        let incompleteNewCardsSet: [DashboardCard] = []
        mockReloadingData(storedDashboardCards: incompleteNewCardsSet)

        // When
        await viewModel.reloadAllData()

        // Then
        XCTAssertTrue(viewModel.showNewCardsNotice)
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
                                           inboxEligibilityChecker: inboxEligibilityChecker)
        mockReloadingData(storedDashboardCards: incompleteNewCardsSet)

        // When
        await viewModel.reloadAllData()

        XCTAssertTrue(viewModel.showNewCardsNotice)
        viewModel.showCustomizationScreen() // Simulate showing Customize screen
        viewModel.handleCustomizationDismissal() // Simulate dismissing Customize screen

        // Then
        XCTAssertFalse(viewModel.showNewCardsNotice) // Check it's false after dismissing Customize screen
    }
}

private extension DashboardViewModelTests {

    func mockReloadingData(jitmResult: Result<[Yosemite.JustInTimeMessage], Error> = .success([]),
                           storeHasOrders: Bool = true,
                           existingProducts: [Product] = [],
                           existingBlazeCampaigns: [BlazeCampaignListItem] = [],
                           storedDashboardCards: [DashboardCard] = []) {
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
            case .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, let onCompletion):
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
    }

    func insertProduct(_ readOnlyProduct: Product) {
        let newProduct = storage.insertNewObject(ofType: StorageProduct.self)
        newProduct.update(with: readOnlyProduct)
        storage.saveIfNeeded()
    }

    func insertCampaigns(_ readOnlyCampaigns: [BlazeCampaignListItem]) {
        readOnlyCampaigns.forEach { campaign in
            let newCampaign = storage.insertNewObject(ofType: StorageBlazeCampaignListItem.self)
            newCampaign.update(with: campaign)
        }
        storage.saveIfNeeded()
    }

    func insertSampleOrder(readOnlyOrder: Order) {
        let newOrder = storage.insertNewObject(ofType: StorageOrder.self)
        newOrder.update(with: readOnlyOrder)
        storage.saveIfNeeded()
    }
}
