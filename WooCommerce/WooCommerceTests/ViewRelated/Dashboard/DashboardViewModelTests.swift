import XCTest
import Fakes
import enum Networking.DotcomError
import enum Yosemite.StatsActionV4
import enum Yosemite.ProductAction
import enum Yosemite.OrderAction
import enum Yosemite.AppSettingsAction
import enum Yosemite.JustInTimeMessageAction
import protocol WooFoundation.Analytics
import struct Yosemite.JustInTimeMessage
import struct Yosemite.Order
import struct Yosemite.StoreOnboardingTask
import enum Yosemite.StoreOnboardingTasksAction
import enum Yosemite.ProductStatus
import struct Yosemite.Site
import struct Yosemite.DashboardCard
@testable import WooCommerce

final class DashboardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 122

    private var analytics: Analytics!
    private var analyticsProvider: MockAnalyticsProvider!
    private var stores: MockStoresManager!
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        stores = MockStoresManager(sessionManager: .makeForTesting())
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: "DashboardViewModelTests"))
    }

    func test_default_statsVersion_is_v4() {
        // Given
        let viewModel = DashboardViewModel(siteID: 0)

        // Then
        XCTAssertEqual(viewModel.statsVersion, .v4)
    }

    func test_view_model_syncs_just_in_time_messages() async {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(title: "JITM Message")
        prepareStoresToShowJustInTimeMessage(.success([message]))
        let viewModel = DashboardViewModel(siteID: 0, stores: stores)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertEqual( viewModel.announcementViewModel?.title, "JITM Message")
    }

    func prepareStoresToShowJustInTimeMessage(_ response: Result<[Yosemite.JustInTimeMessage], Error>) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .checkIfStoreHasProducts(_, _, completion):
                completion(.success(true))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        stores.whenReceivingAction(ofType: JustInTimeMessageAction.self) { action in
            switch action {
            case let .loadMessage(_, _, _, completion):
                completion(response)
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
    }

    func test_no_announcement_to_display_when_no_announcements_are_synced() async {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .checkIfStoreHasProducts(_, _, completion):
                completion(.success(true))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        stores.whenReceivingAction(ofType: JustInTimeMessageAction.self) { action in
            switch action {
            case let .loadMessage(_, _, _, completion):
                completion(.success([]))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        let viewModel = DashboardViewModel(siteID: 0, stores: stores)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertNil(viewModel.announcementViewModel)
    }

    func test_fetch_success_analytics_logged_when_just_in_time_messages_retrieved() async {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(messageID: "test-message-id",
                                                             featureClass: "test-feature-class")

        let secondMessage = Yosemite.JustInTimeMessage.fake().copy(messageID: "test-message-id-2",
                                                                   featureClass: "test-feature-class-2")
        prepareStoresToShowJustInTimeMessage(.success([message, secondMessage]))
        let viewModel = DashboardViewModel(siteID: 0, stores: stores, analytics: analytics)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

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

    func test_when_two_messages_are_received_only_the_first_is_displayed() async {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(title: "Higher priority JITM")

        let secondMessage = Yosemite.JustInTimeMessage.fake().copy(title: "Lower priority JITM")
        prepareStoresToShowJustInTimeMessage(.success([message, secondMessage]))
        let viewModel = DashboardViewModel(siteID: 0, stores: stores, analytics: analytics)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertEqual(viewModel.announcementViewModel?.title, "Higher priority JITM")
    }

    func test_fetch_failure_analytics_logged_when_just_in_time_message_errors() async {
        // Given
        let error = DotcomError.noRestRoute
        prepareStoresToShowJustInTimeMessage(.failure(error))
        let viewModel = DashboardViewModel(siteID: 0, stores: stores, analytics: analytics)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

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

    func test_when_no_messages_are_received_existing_messages_are_removed() async {
        // Given
        prepareStoresToShowJustInTimeMessage(.success([]))

        let viewModel = DashboardViewModel(siteID: 0, stores: stores, analytics: analytics)
        viewModel.announcementViewModel = JustInTimeMessageViewModel(
            justInTimeMessage: .fake(),
            screenName: "my_store",
            siteID: sampleSiteID)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertNil(viewModel.announcementViewModel)
    }

    // MARK: Local announcements

    @MainActor
    func test_it_does_not_trigger_AppSettingsAction_for_local_announcement_when_jitm_is_available() async {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(template: .modal)
        prepareStoresToShowJustInTimeMessage(.success([message]))
        // Sets the prerequisites for the product description AI local announcement.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID, isWordPressComStore: true))
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)

        let viewModel = DashboardViewModel(siteID: 0, stores: stores, featureFlags: featureFlagService)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case .getLocalAnnouncementVisibility = action {
                XCTFail("Local announcement should not be loaded when JITM is available.")
            }
        }

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertNotNil(viewModel.modalJustInTimeMessageViewModel)
        XCTAssertNil(viewModel.localAnnouncementViewModel)
    }

    @MainActor
    func test_it_sets_localAnnouncementViewModel_when_jitm_is_nil_and_local_announcement_is_available() async {
        // Given
        // No JITM.
        prepareStoresToShowJustInTimeMessage(.success([]))
        // Sets the prerequisites for the product description AI local announcement.
        stores.updateDefaultStore(storeID: sampleSiteID)
        stores.updateDefaultStore(.fake().copy(siteID: sampleSiteID, isWordPressComStore: true))
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)

        let viewModel = DashboardViewModel(siteID: 0, stores: stores, featureFlags: featureFlagService)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .getLocalAnnouncementVisibility(_, completion) = action {
                completion(true)
            }
        }

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertNil(viewModel.modalJustInTimeMessageViewModel)
        XCTAssertNotNil(viewModel.localAnnouncementViewModel)
    }

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
    // TODO: Add unit test for initially generated cards, and for the synchronizing between generated and saved cards.

    func test_dashboard_cards_are_saved_to_app_settings() async throws {
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
    }

    // MARK: Install theme
    func test_it_triggers_pending_theme_install_upon_initialization() async throws {
        // Given
        let themeInstaller = MockThemeInstaller()
        _ = DashboardViewModel(siteID: sampleSiteID,
                               themeInstaller: themeInstaller)

        waitUntil {
            themeInstaller.installPendingThemeCalled == true
        }

        //  Then
        XCTAssertEqual(themeInstaller.installPendingThemeCalledForSiteID, sampleSiteID)
    }

    // MARK: hasOrders state
    func test_hasOrders_is_true_when_site_has_orders() {
        // Given
        let storage = MockStorageManager()
        let insertOrder = Order.fake().copy(siteID: sampleSiteID)
        storage.insertSampleOrder(readOnlyOrder: insertOrder)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, storageManager: storage)

        // Then
        XCTAssertTrue(viewModel.hasOrders)
    }

    func test_hasOrders_is_false_when_site_has_no_orders() {
        // Given
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertFalse(viewModel.hasOrders)
    }

    func test_hasOrders_is_updated_correctly_when_orders_availability_changes() {
        // Given
        let storage = MockStorageManager()
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, storageManager: storage)

        // Then
        XCTAssertFalse(viewModel.hasOrders)

        // When
        let insertOrder = Order.fake().copy(siteID: sampleSiteID)
        storage.insertSampleOrder(readOnlyOrder: insertOrder)

        // Then
        waitUntil {
            viewModel.hasOrders == true
        }
    }

    // MARK: Dashboard cards

    func test_generated_default_cards_are_as_expected_with_m2_feature_flag_enabled_when_site_is_eligible_for_inbox() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: true)
        let inboxEligibilityChecker = MockInboxEligibilityChecker()
        inboxEligibilityChecker.isEligible = true

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           featureFlags: featureFlagService,
                                           inboxEligibilityChecker: inboxEligibilityChecker)
        mockLoadDashboardCards(withStoredCards: [])

        let expectedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
                             DashboardCard(type: .performance, availability: .unavailable, enabled: false),
                             DashboardCard(type: .topPerformers, availability: .unavailable, enabled: false),
                             DashboardCard(type: .blaze, availability: .hide, enabled: false),
                             DashboardCard(type: .inbox, availability: .show, enabled: false),
                             DashboardCard(type: .reviews, availability: .show, enabled: false),
                             DashboardCard(type: .coupons, availability: .show, enabled: false),
                             DashboardCard(type: .stock, availability: .show, enabled: false),
                             DashboardCard(type: .lastOrders, availability: .unavailable, enabled: false)]

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards == expectedCards
        }

    }

    func test_generated_default_cards_are_as_expected_with_m2_feature_flag_enabled_when_site_is_not_eligible_for_inbox() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: true)
        let inboxEligibilityChecker = MockInboxEligibilityChecker()
        inboxEligibilityChecker.isEligible = false

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           featureFlags: featureFlagService,
                                           inboxEligibilityChecker: inboxEligibilityChecker)
        mockLoadDashboardCards(withStoredCards: [])

        let expectedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
                             DashboardCard(type: .performance, availability: .unavailable, enabled: false),
                             DashboardCard(type: .topPerformers, availability: .unavailable, enabled: false),
                             DashboardCard(type: .blaze, availability: .hide, enabled: false),
                             DashboardCard(type: .inbox, availability: .hide, enabled: false),
                             DashboardCard(type: .reviews, availability: .show, enabled: false),
                             DashboardCard(type: .coupons, availability: .show, enabled: false),
                             DashboardCard(type: .stock, availability: .show, enabled: false),
                             DashboardCard(type: .lastOrders, availability: .unavailable, enabled: false)]

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards == expectedCards
        }

    }

    func test_generated_default_cards_are_as_expected_with_m2_feature_flag_disabled() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: false)

        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, featureFlags: featureFlagService)
        mockLoadDashboardCards(withStoredCards: [])

        let expectedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
                             DashboardCard(type: .performance, availability: .unavailable, enabled: false),
                             DashboardCard(type: .topPerformers, availability: .unavailable, enabled: false),
                             DashboardCard(type: .blaze, availability: .hide, enabled: false)]

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards == expectedCards
        }
    }

    func test_dashboard_cards_contain_unavailable_and_disabled_analytics_cards_when_there_are_no_orders() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: false)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, featureFlags: featureFlagService)
        mockLoadDashboardCards(withStoredCards: [])

        // Analytics cards need to say "Unavailable" in the Customize screen and be disabled so they don't appear on Dashboard
        // This is set as availability: .unavailable and enabled: false in the expected cards.
        let expectedPerformanceCard = DashboardCard(type: .performance, availability: .unavailable, enabled: false)
        let expectedTopPerformersCard = DashboardCard(type: .topPerformers, availability: .unavailable, enabled: false)

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards.contains(expectedPerformanceCard) &&
            viewModel.dashboardCards.contains(expectedTopPerformersCard)
        }
    }

    func test_dashboard_cards_contain_enabled_analytics_cards_when_there_is_order() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: true)
        let storage = MockStorageManager()
        let insertOrder = Order.fake().copy(siteID: sampleSiteID)
        storage.insertSampleOrder(readOnlyOrder: insertOrder)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, storageManager: storage, featureFlags: featureFlagService)
        mockLoadDashboardCards(withStoredCards: [])

        // Analytics cards need to be set with availability: .show and enabled: true to make them available and shown.
        let expectedPerformanceCard = DashboardCard(type: .performance, availability: .show, enabled: true)
        let expectedTopPerformersCard = DashboardCard(type: .topPerformers, availability: .show, enabled: true)

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards.contains(expectedPerformanceCard) &&
            viewModel.dashboardCards.contains(expectedTopPerformersCard)
        }
    }

    func test_dashboard_cards_contain_enabled_last_orders_cards_when_there_is_order() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: true)
        let storage = MockStorageManager()
        let insertOrder = Order.fake().copy(siteID: sampleSiteID)
        storage.insertSampleOrder(readOnlyOrder: insertOrder)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, storageManager: storage, featureFlags: featureFlagService)
        mockLoadDashboardCards(withStoredCards: [])

        // Last orders cards need to be set with availability: .show and enabled: false to make them available.
        let expectedLastOrdersCard = DashboardCard(type: .lastOrders, availability: .show, enabled: false)

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards.contains(expectedLastOrdersCard)
        }
    }

    func test_dashboard_cards_has_disabled_onboarding_card_if_all_tasks_are_completed() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: false)
        userDefaults[.completedAllStoreOnboardingTasks] = true

        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, featureFlags: featureFlagService, userDefaults: userDefaults)

        mockLoadDashboardCards(withStoredCards: [])

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards.isNotEmpty
        }

        let onboardingCard = try XCTUnwrap(viewModel.dashboardCards.first(where: {$0.type == .onboarding }))
        XCTAssertFalse(onboardingCard.enabled)
    }

    func test_dashboard_cards_is_loaded_from_storage_if_they_exist() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: false)
        let storage = MockStorageManager()
        let insertOrder = Order.fake().copy(siteID: sampleSiteID)
        storage.insertSampleOrder(readOnlyOrder: insertOrder)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, storageManager: storage, featureFlags: featureFlagService)

        let storedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
                           DashboardCard(type: .performance, availability: .show, enabled: true),
                           DashboardCard(type: .topPerformers, availability: .show, enabled: true)]

        mockLoadDashboardCards(withStoredCards: storedCards)

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards == storedCards
        }
    }

    func test_dashboard_cards_respects_existing_ordering_from_saved_cards() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: false)
        let storage = MockStorageManager()

        // Add order so that analytics cards are enabled
        let insertOrder = Order.fake().copy(siteID: sampleSiteID)
        storage.insertSampleOrder(readOnlyOrder: insertOrder)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, storageManager: storage, featureFlags: featureFlagService)

        let storedCards = [DashboardCard(type: .topPerformers, availability: .show, enabled: true),
                           DashboardCard(type: .onboarding, availability: .show, enabled: true),
                           DashboardCard(type: .performance, availability: .show, enabled: true)]

        mockLoadDashboardCards(withStoredCards: storedCards)

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            // Equality implies identical ordering
            viewModel.dashboardCards == storedCards
        }
    }

    func test_dashboard_cards_respects_enabled_setting_from_saved_cards() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: false)
        let storage = MockStorageManager()

        // Add order so that analytics cards are enabled
        let insertOrder = Order.fake().copy(siteID: sampleSiteID)
        storage.insertSampleOrder(readOnlyOrder: insertOrder)
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, storageManager: storage, featureFlags: featureFlagService)

        let storedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
                           DashboardCard(type: .performance, availability: .show, enabled: true),
                           DashboardCard(type: .topPerformers, availability: .show, enabled: false)]

        mockLoadDashboardCards(withStoredCards: storedCards)

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards.isNotEmpty
        }

        let performanceCard = try XCTUnwrap(viewModel.dashboardCards.first(where: {$0.type == .performance }))
        XCTAssertTrue(performanceCard.enabled)

        let topPerformersCard = try XCTUnwrap(viewModel.dashboardCards.first(where: {$0.type == .topPerformers }))
        XCTAssertFalse(topPerformersCard.enabled)
    }

    // MARK: Show New Cards Notice

    func test_showNewCardsNotice_is_false_when_all_new_cards_are_already_in_saved_cards() async {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: true)
        let inboxEligibilityChecker = MockInboxEligibilityChecker()
        inboxEligibilityChecker.isEligible = true

        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           featureFlags: featureFlagService,
                                           inboxEligibilityChecker: inboxEligibilityChecker)
        let completeCardsSet: [DashboardCard] = [
            .init(type: .inbox, availability: .show, enabled: true),
            .init(type: .reviews, availability: .show, enabled: true),
            .init(type: .coupons, availability: .show, enabled: true),
            .init(type: .stock, availability: .show, enabled: true),
            .init(type: .lastOrders, availability: .show, enabled: true)
        ]
        mockLoadDashboardCards(withStoredCards: completeCardsSet)

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards.isNotEmpty
        }
        XCTAssertFalse(viewModel.showNewCardsNotice)
    }

    func test_showNewCardsNotice_is_true_when_not_all_new_cards_are_in_saved_cards() async {
        // Given
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores)
        let incompleteNewCardsSet: [DashboardCard] = []
        mockLoadDashboardCards(withStoredCards: incompleteNewCardsSet)

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards.isNotEmpty
        }

        XCTAssertTrue(viewModel.showNewCardsNotice)
    }

    func test_showNewCardsNotice_changes_from_true_to_false_after_showing_customize_screen_and_dismissing_it() async {
        // Given
        let incompleteNewCardsSet: [DashboardCard] = [
            .init(type: .inbox, availability: .show, enabled: false),
            .init(type: .reviews, availability: .show, enabled: false)
        ]
        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores)
        mockLoadDashboardCards(withStoredCards: incompleteNewCardsSet)

        // When
        viewModel.refreshDashboardCards()

        waitUntil {
            viewModel.dashboardCards.isNotEmpty
        }

        XCTAssertTrue(viewModel.showNewCardsNotice)
        viewModel.showCustomizationScreen() // Simulate showing Customize screen

        // Simulate saving complete cards since initially we mocked it with empty array
        let completeCardsSet: [DashboardCard] = [
            .init(type: .inbox, availability: .show, enabled: true),
            .init(type: .reviews, availability: .show, enabled: true),
            .init(type: .coupons, availability: .show, enabled: true),
            .init(type: .stock, availability: .show, enabled: true),
            .init(type: .lastOrders, availability: .show, enabled: true)
        ]
        mockLoadDashboardCards(withStoredCards: completeCardsSet)

        viewModel.handleCustomizationDismissal() // Simulate dismissing Customize screen

        // Then
        XCTAssertFalse(viewModel.showNewCardsNotice) // Check it's false after dismissing Customize screen
    }
}

private extension DashboardViewModelTests {
    func mockLoadOnboardingTasks(result: Result<[StoreOnboardingTask], Error>) {
        stores.whenReceivingAction(ofType: StoreOnboardingTasksAction.self) { action in
            guard case let .loadOnboardingTasks(_, completion) = action else {
                return XCTFail()
            }
            completion(result)
        }
    }

    /// Mock saved cards. Pass empty array to simulate no saved cards situation.
    func mockLoadDashboardCards(withStoredCards cards: [DashboardCard]) {
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadDashboardCards(_, onCompletion):
                onCompletion(cards)
            default:
                break
            }
        }
    }

    final class MockError: Error { }
}
