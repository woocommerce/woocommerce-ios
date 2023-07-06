import XCTest
import enum Networking.DotcomError
import enum Yosemite.StatsActionV4
import enum Yosemite.ProductAction
import enum Yosemite.AppSettingsAction
import enum Yosemite.JustInTimeMessageAction
import struct Yosemite.JustInTimeMessage
import struct Yosemite.StoreOnboardingTask
import enum Yosemite.StoreOnboardingTasksAction
import enum Yosemite.ProductStatus
import struct Yosemite.Site
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

    func test_statsVersion_changes_from_v4_to_v3_when_store_stats_sync_returns_noRestRoute_error() {
        // Given
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            if case let .retrieveStats(_, _, _, _, _, _, completion) = action {
                completion(.failure(DotcomError.noRestRoute))
            }
        }
        let viewModel = DashboardViewModel(siteID: 0, stores: stores)
        XCTAssertEqual(viewModel.statsVersion, .v4)

        // When
        viewModel.syncStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init(), forceRefresh: false)

        // Then
        XCTAssertEqual(viewModel.statsVersion, .v3)
    }

    func test_statsVersion_remains_v4_when_non_store_stats_sync_returns_noRestRoute_error() {
        // Given
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveStats(_, _, _, _, _, _, completion):
                completion(.failure(DotcomError.empty))
            case let .retrieveSiteVisitStats(_, _, _, _, completion):
                completion(.failure(DotcomError.noRestRoute))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, completion):
                completion(.failure(DotcomError.noRestRoute))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                completion(.failure(DotcomError.noRestRoute))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        let viewModel = DashboardViewModel(siteID: 0, stores: stores)
        XCTAssertEqual(viewModel.statsVersion, .v4)

        // When
        viewModel.syncStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init(), forceRefresh: false)
        viewModel.syncSiteVisitStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init())
        viewModel.syncTopEarnersStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init(), forceRefresh: false)
        viewModel.syncSiteSummaryStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init())

        // Then
        XCTAssertEqual(viewModel.statsVersion, .v4)
    }

    func test_statsVersion_changes_from_v3_to_v4_when_store_stats_sync_returns_success() {
        // Given
        // `DotcomError.noRestRoute` error indicates the stats are unavailable.
        var storeStatsResult: Result<Void, Error> = .failure(DotcomError.noRestRoute)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            if case let .retrieveStats(_, _, _, _, _, _, completion) = action {
                completion(storeStatsResult)
            }
        }
        let viewModel = DashboardViewModel(siteID: 0, stores: stores)
        viewModel.syncStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init(), forceRefresh: false)
        XCTAssertEqual(viewModel.statsVersion, .v3)

        // When
        storeStatsResult = .success(())
        viewModel.syncStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init(), forceRefresh: false)

        // Then
        XCTAssertEqual(viewModel.statsVersion, .v4)
    }

    func test_products_onboarding_announcements_take_precedence() async {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .checkIfStoreHasProducts(_, _, completion):
                completion(.success(false))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .getFeatureAnnouncementVisibility(_, completion):
                completion(.success(true))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        stores.whenReceivingAction(ofType: JustInTimeMessageAction.self) { action in
            switch action {
            case let .loadMessage(_, _, _, completion):
                completion(.success([Yosemite.JustInTimeMessage.fake()]))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        let viewModel = DashboardViewModel(siteID: 0, stores: stores)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then (check announcement image because it is unique and not localized)
        XCTAssertEqual(viewModel.announcementViewModel?.image, .emptyProductsImage)
    }

    func test_onboarding_announcement_not_displayed_when_previously_dismissed() async {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .checkIfStoreHasProducts(_, _, completion):
                completion(.success(false))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .getFeatureAnnouncementVisibility(_, completion):
                completion(.success(false))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        prepareStoresToShowJustInTimeMessage(.success([]))

        let viewModel = DashboardViewModel(siteID: 0, stores: stores)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertNil(viewModel.announcementViewModel)
    }

    func test_view_model_syncs_just_in_time_messages_when_ineligible_for_products_onboarding() async {
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
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true,
                                                        isJustInTimeMessagesOnDashboardEnabled: true)

        let viewModel = DashboardViewModel(siteID: 0, stores: stores, featureFlags: featureFlagService)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .getLocalAnnouncementVisibility(_, _):
                XCTFail("Local announcement should not be loaded when JITM is available.")
            default:
                XCTFail("Received unsupported action: \(action)")
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
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true,
                                                        isJustInTimeMessagesOnDashboardEnabled: true)

        let viewModel = DashboardViewModel(siteID: 0, stores: stores, featureFlags: featureFlagService)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .getLocalAnnouncementVisibility(_, completion):
                completion(true)
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertNil(viewModel.modalJustInTimeMessageViewModel)
        XCTAssertNotNil(viewModel.localAnnouncementViewModel)
    }

    // MARK: Store onboarding

    func test_showOnboarding_is_false_when_feature_flag_is_turned_off_and_completedAllStoreOnboardingTasks_is_false() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = false
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: false),
                                           userDefaults: defaults)
        // Then
        XCTAssertFalse(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_false_when_feature_flag_is_turned_off_and_completedAllStoreOnboardingTasks_is_true() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = true
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: false),
                                           userDefaults: defaults)
        // Then
        XCTAssertFalse(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_false_when_feature_flag_is_turned_on_and_completedAllStoreOnboardingTasks_is_true() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = true
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                           userDefaults: defaults)
        // Then
        XCTAssertFalse(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_true_when_feature_flag_is_turned_on_and_completedAllStoreOnboardingTasks_is_false() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = false
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                           userDefaults: defaults)
        // Then
        XCTAssertTrue(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_true_when_feature_flag_is_turned_on_and_completedAllStoreOnboardingTasks_is_not_set() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                           userDefaults: defaults)
        // Then
        XCTAssertTrue(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_set_to_false_upon_setting_user_defaults_value_completedAllStoreOnboardingTasks_as_true() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = DashboardViewModel(siteID: 0,
                                           stores: stores,
                                           featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                           userDefaults: defaults)
        // Then
        XCTAssertTrue(viewModel.showOnboarding)

        // When
        defaults[.completedAllStoreOnboardingTasks] = true

        // Then
        XCTAssertFalse(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_true_when_there_are_tasks_available_for_display() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = DashboardViewModel(siteID: 0,
                                     stores: stores,
                                     featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                     userDefaults: defaults)
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: true, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))

        // When
        await sut.reloadStoreOnboardingTasks()

        // Then
        XCTAssertTrue(sut.showOnboarding)
    }

    func test_showOnboarding_is_false_when_all_tasks_are_complete() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = DashboardViewModel(siteID: 0,
                                     stores: stores,
                                     featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                     userDefaults: defaults)
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: true, type: .addFirstProduct),
            .init(isComplete: true, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: true, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))

        // When
        await sut.reloadStoreOnboardingTasks()

        // Then
        XCTAssertFalse(sut.showOnboarding)
    }

    func test_showOnboarding_is_false_when_no_tasks_available_for_display_due_to_network_error() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = DashboardViewModel(siteID: 0,
                                     stores: stores,
                                     featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                     userDefaults: defaults)
        mockLoadOnboardingTasks(result: .failure(MockError()))

        // Then
        XCTAssertTrue(sut.showOnboarding)

        // When
        await sut.reloadStoreOnboardingTasks()

        // Then
        XCTAssertFalse(sut.showOnboarding)
    }

    func test_showOnboarding_is_false_when_no_tasks_available_for_display_due_to_empty_tasks_response() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = DashboardViewModel(siteID: 0,
                                     stores: stores,
                                     featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                     userDefaults: defaults)
        mockLoadOnboardingTasks(result: .success([]))

        // When
        await sut.reloadStoreOnboardingTasks()

        // Then
        XCTAssertFalse(sut.showOnboarding)
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

    // MARK: Blaze banner
    func test_updateBlazeBannerVisibility_triggers_loading_product_ids_with_published_status() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: checker)
        var productStatusToCheck: ProductStatus?

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, let productStatus, let completion):
                productStatusToCheck = productStatus
                completion(.success(false))
            default:
                break
            }
        }
        await viewModel.updateBlazeBannerVisibility()

        //  Then
        XCTAssertEqual(productStatusToCheck?.rawValue, "publish")
    }

    // swiftlint:disable:next line_length
    func test_updateBlazeBannerVisibility_updates_showBlazeBanner_to_true_if_site_is_eligible_for_blaze_and_banner_is_not_dismissed_yet_and_store_has_published_products() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: checker)
        XCTAssertFalse(viewModel.showBlazeBanner)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        await viewModel.updateBlazeBannerVisibility()

        //  Then
        XCTAssertTrue(viewModel.showBlazeBanner)
    }

    func test_updateBlazeBannerVisibility_updates_showBlazeBanner_to_false_if_site_is_not_eligible_for_blaze() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: false)
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: checker)
        XCTAssertFalse(viewModel.showBlazeBanner)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        await viewModel.updateBlazeBannerVisibility()

        //  Then
        XCTAssertFalse(viewModel.showBlazeBanner)
    }

    func test_updateBlazeBannerVisibility_updates_showBlazeBanner_to_false_if_banner_was_dismissed() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.hasDismissedBlazeBanner] = ["\(sampleSiteID)": true]
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: checker)
        XCTAssertFalse(viewModel.showBlazeBanner)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        await viewModel.updateBlazeBannerVisibility()

        //  Then
        XCTAssertFalse(viewModel.showBlazeBanner)
    }

    func test_updateBlazeBannerVisibility_updates_showBlazeBanner_to_false_if_store_does_not_have_any_products() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: checker)
        XCTAssertFalse(viewModel.showBlazeBanner)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        await viewModel.updateBlazeBannerVisibility()

        //  Then
        XCTAssertFalse(viewModel.showBlazeBanner)
    }

    func test_hideBlazeBanner_sets_showBlazeBanner_to_false_and_updates_hasDismissedBlazeBanner() async throws {
        // Given
        let checker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = DashboardViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           userDefaults: userDefaults,
                                           blazeEligibilityChecker: checker)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .checkIfStoreHasProducts(_, _, let onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        await viewModel.updateBlazeBannerVisibility()
        XCTAssertTrue(viewModel.showBlazeBanner)

        //  When
        viewModel.hideBlazeBanner()

        // Then
        XCTAssertFalse(viewModel.showBlazeBanner)
        let dictionary = try XCTUnwrap(userDefaults[.hasDismissedBlazeBanner] as? [String: Bool])
        XCTAssertEqual(dictionary["\(sampleSiteID)"], true)
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
