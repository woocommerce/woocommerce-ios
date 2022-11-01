import XCTest
import enum Networking.DotcomError
import enum Yosemite.StatsActionV4
import enum Yosemite.ProductAction
import enum Yosemite.JustInTimeMessageAction
import struct Yosemite.YosemiteJustInTimeMessage
@testable import WooCommerce

final class DashboardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 122

    func test_default_statsVersion_is_v4() {
        // Given
        let viewModel = DashboardViewModel()

        // Then
        XCTAssertEqual(viewModel.statsVersion, .v4)
    }

    func test_statsVersion_changes_from_v4_to_v3_when_store_stats_sync_returns_noRestRoute_error() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
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
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            if case let .retrieveStats(_, _, _, _, _, _, completion) = action {
                completion(.failure(DotcomError.empty))
            } else if case let .retrieveSiteVisitStats(_, _, _, _, completion) = action {
                completion(.failure(DotcomError.noRestRoute))
            } else if case let .retrieveTopEarnerStats(_, _, _, _, _, _, completion) = action {
                completion(.failure(DotcomError.noRestRoute))
            }
        }
        let viewModel = DashboardViewModel(stores: stores)
        XCTAssertEqual(viewModel.statsVersion, .v4)

        // When
        viewModel.syncStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init(), forceRefresh: false)
        viewModel.syncSiteVisitStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init())
        viewModel.syncTopEarnersStats(for: sampleSiteID, siteTimezone: .current, timeRange: .thisMonth, latestDateToInclude: .init(), forceRefresh: false)

        // Then
        XCTAssertEqual(viewModel.statsVersion, .v4)
    }

    func test_statsVersion_changes_from_v3_to_v4_when_store_stats_sync_returns_success() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
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

    func test_products_onboarding_announcements_take_precedence() {
        // Given
        MockABTesting.setVariation(.treatment(nil), for: .productsOnboardingBanner)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .checkProductsOnboardingEligibility(_, completion):
                completion(.success(true))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        stores.whenReceivingAction(ofType: JustInTimeMessageAction.self) { action in
            switch action {
            case let .loadMessage(_, _, _, completion):
                completion(.success(YosemiteJustInTimeMessage.fake()))
            }
        }
        let viewModel = DashboardViewModel(stores: stores)

        // When
        viewModel.syncAnnouncements(for: sampleSiteID)

        // Then (check announcement image because it is unique and not localized)
        XCTAssertEqual(viewModel.announcementViewModel?.image, .emptyProductsImage)
    }

    func test_view_model_syncs_just_in_time_messages_when_ineligible_for_products_onboarding() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
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
                completion(.success(YosemiteJustInTimeMessage.fake().copy(title: "JITM Message")))
            }
        }
        let viewModel = DashboardViewModel(stores: stores)

        // When
        viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertEqual(viewModel.announcementViewModel?.title, "JITM Message")
    }

    func test_no_announcement_to_display_when_no_announcements_are_synced() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
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
                completion(.success(nil))
            }
        }
        let viewModel = DashboardViewModel(stores: stores)

        // When
        viewModel.syncAnnouncements(for: sampleSiteID)

        // Then
        XCTAssertNil(viewModel.announcementViewModel)
    }
}
