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

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        stores = MockStoresManager(sessionManager: .makeForTesting())
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
        sessionManager.defaultSite = Site.fake().copy(isPublic: false)
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
        sessionManager.defaultSite = Site.fake().copy(url: expectedURL, isPublic: true)
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

    func test_generated_default_cards_are_as_expected() {
        // Given
        let featureFlagService = MockFeatureFlagService(isDynamicDashboardM2Enabled: true)

        let viewModel = DashboardViewModel(siteID: sampleSiteID, stores: stores, featureFlags: featureFlagService)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadDashboardCards(_, onCompletion):
                onCompletion([])
            default:
                break
            }
        }

        let expectedCards = [DashboardCard(type: .onboarding, availability: .show, enabled: true),
                             DashboardCard(type: .performance, availability: .unavailable, enabled: false),
                             DashboardCard(type: .topPerformers, availability: .unavailable, enabled: false),
                             DashboardCard(type: .blaze, availability: .hide, enabled: false),
                             DashboardCard(type: .inbox, availability: .show, enabled: false),
                             DashboardCard(type: .reviews, availability: .show, enabled: false),
                             DashboardCard(type: .coupons, availability: .show, enabled: false),
                             DashboardCard(type: .stock, availability: .show, enabled: false)]

        // When
        viewModel.refreshDashboardCards()

        // Then
        waitUntil {
            viewModel.dashboardCards.isNotEmpty
        }

        XCTAssertEqual(viewModel.dashboardCards.count, 8)
        XCTAssertEqual(viewModel.dashboardCards, expectedCards)
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

    final class MockError: Error { }
}
