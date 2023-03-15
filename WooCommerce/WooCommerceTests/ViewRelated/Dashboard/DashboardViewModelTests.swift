import XCTest
import enum Networking.DotcomError
import enum Yosemite.StatsActionV4
import enum Yosemite.ProductAction
import enum Yosemite.AppSettingsAction
import enum Yosemite.JustInTimeMessageAction
import struct Yosemite.JustInTimeMessage
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
        let viewModel = DashboardViewModel()

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
        let viewModel = DashboardViewModel(stores: stores)
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
        let viewModel = DashboardViewModel(stores: stores)
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
        let viewModel = DashboardViewModel(stores: stores)
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
            case let .checkProductsOnboardingEligibility(_, completion):
                completion(.success(true))
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

        let viewModel = DashboardViewModel(stores: stores)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then (check announcement image because it is unique and not localized)
        XCTAssertEqual(viewModel.announcementViewModel?.image, .emptyProductsImage)
    }

    func test_onboarding_announcement_not_displayed_when_previously_dismissed() async {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .checkProductsOnboardingEligibility(_, completion):
                completion(.success(true))
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

        let viewModel = DashboardViewModel(stores: stores)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertNil(viewModel.announcementViewModel)
    }

    func test_view_model_syncs_just_in_time_messages_when_ineligible_for_products_onboarding() async {
        // Given
        let message = Yosemite.JustInTimeMessage.fake().copy(title: "JITM Message")
        prepareStoresToShowJustInTimeMessage(.success([message]))
        let viewModel = DashboardViewModel(stores: stores)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertEqual( viewModel.announcementViewModel?.title, "JITM Message")
    }

    func prepareStoresToShowJustInTimeMessage(_ response: Result<[Yosemite.JustInTimeMessage], Error>) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .checkProductsOnboardingEligibility(_, completion):
                completion(.success(false))
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
            case let .checkProductsOnboardingEligibility(_, completion):
                completion(.success(false))
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
        let viewModel = DashboardViewModel(stores: stores)

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
        let viewModel = DashboardViewModel(stores: stores, analytics: analytics)

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
        let viewModel = DashboardViewModel(stores: stores, analytics: analytics)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertEqual(viewModel.announcementViewModel?.title, "Higher priority JITM")
    }

    func test_fetch_failure_analytics_logged_when_just_in_time_message_errors() async {
        // Given
        let error = DotcomError.noRestRoute
        prepareStoresToShowJustInTimeMessage(.failure(error))
        let viewModel = DashboardViewModel(stores: stores, analytics: analytics)

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

        let viewModel = DashboardViewModel(stores: stores, analytics: analytics)
        viewModel.announcementViewModel = JustInTimeMessageAnnouncementCardViewModel(
            justInTimeMessage: .fake(),
            screenName: "my_store",
            siteID: sampleSiteID)

        // When
        await viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertNil(viewModel.announcementViewModel)
    }

    // MARK: Store onboarding

    func test_showOnboarding_is_false_when_feature_flag_is_turned_off_and_completedAllStoreOnboardingTasks_is_false() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = false
        let viewModel = DashboardViewModel(featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: false),
                                           userDefaults: defaults)
        // Then
        XCTAssertFalse(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_false_when_feature_flag_is_turned_off_and_completedAllStoreOnboardingTasks_is_true() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = true
        let viewModel = DashboardViewModel(featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: false),
                                           userDefaults: defaults)
        // Then
        XCTAssertFalse(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_false_when_feature_flag_is_turned_on_and_completedAllStoreOnboardingTasks_is_true() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = true
        let viewModel = DashboardViewModel(featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                           userDefaults: defaults)
        // Then
        XCTAssertFalse(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_true_when_feature_flag_is_turned_on_and_completedAllStoreOnboardingTasks_is_false() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.completedAllStoreOnboardingTasks] = false
        let viewModel = DashboardViewModel(featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                           userDefaults: defaults)
        // Then
        XCTAssertTrue(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_true_when_feature_flag_is_turned_on_and_completedAllStoreOnboardingTasks_is_not_set() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = DashboardViewModel(featureFlags: MockFeatureFlagService(isDashboardStoreOnboardingEnabled: true),
                                           userDefaults: defaults)
        // Then
        XCTAssertTrue(viewModel.showOnboarding)
    }

    func test_showOnboarding_is_set_to_false_upon_calling_didCompleteAllOnboardingTasks() {
        // Given
        let viewModel = DashboardViewModel()

        // Then
        XCTAssertTrue(viewModel.showOnboarding)

        // When
        viewModel.didCompleteAllOnboardingTasks()

        // Then
        XCTAssertFalse(viewModel.showOnboarding)
    }
}
