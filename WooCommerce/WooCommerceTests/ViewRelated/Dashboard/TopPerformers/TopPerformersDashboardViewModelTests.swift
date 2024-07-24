import XCTest
import Yosemite
@testable import WooCommerce

final class TopPerformersDashboardViewModelTests: XCTestCase {

    @MainActor
    func test_dates_for_custom_range_are_correct_for_non_custom_time_range() throws {
        // Given
        let viewModel = TopPerformersDashboardViewModel(siteID: 123, usageTracksEventEmitter: .init())

        // When
        viewModel.didSelectTimeRange(.thisWeek)

        // Then
        let now = Date()
        let startDateForCustomRange = viewModel.startDateForCustomRange
        let endDateForCustomRange = viewModel.endDateForCustomRange
        XCTAssertTrue(now.isSameDay(as: endDateForCustomRange))
        XCTAssertTrue(try XCTUnwrap(now.adding(days: -30)).isSameDay(as: startDateForCustomRange))
    }

    @MainActor
    func test_dates_for_custom_range_are_correct_for_custom_time_range() throws {
        // Given
        let viewModel = TopPerformersDashboardViewModel(siteID: 123, usageTracksEventEmitter: .init())

        // When
        let startDate = try XCTUnwrap(Date().adding(days: -100))
        let endDate = try XCTUnwrap(Date().adding(days: -10))
        viewModel.didSelectTimeRange(.custom(from: startDate, to: endDate))

        // Then
        XCTAssertEqual(viewModel.startDateForCustomRange, startDate)
        XCTAssertEqual(viewModel.endDateForCustomRange, endDate)
    }

    @MainActor
    func test_loadLastTimeRange_is_fetched_upon_initialization() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadLastSelectedTopPerformersTimeRange(_, onCompletion):
                onCompletion(StatsTimeRangeV4.thisWeek)
            default:
                break
            }
        }

        // When
        let viewModel = TopPerformersDashboardViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())

        // Then
        XCTAssertEqual(viewModel.timeRange, .today) // initial value
        waitUntil {
            viewModel.timeRange == .thisWeek
        }
    }

    @MainActor
    func test_saveLastTimeRange_is_triggered_when_updating_time_range() {
        // Given
        var savedTimeRange: StatsTimeRangeV4?
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .setLastSelectedTopPerformersTimeRange(_, timeRange):
                savedTimeRange = timeRange
            default:
                break
            }
        }
        let viewModel = TopPerformersDashboardViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())

        // When
        viewModel.didSelectTimeRange(.thisYear)

        // Then
        XCTAssertEqual(savedTimeRange, .thisYear)
    }

    @MainActor
    func test_dismissTopPerformers_triggers_onDismiss() {
        // Given
        let viewModel = TopPerformersDashboardViewModel(siteID: 123, usageTracksEventEmitter: .init())
        var onDismissTriggered = false
        viewModel.onDismiss = {
            onDismissTriggered = true
        }

        // When
        viewModel.dismissTopPerformers()

        // Then
        XCTAssertTrue(onDismissTriggered)
    }

    @MainActor
    func test_dismissTopPerformers_triggers_tracking_event() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = TopPerformersDashboardViewModel(siteID: 123, usageTracksEventEmitter: .init(), analytics: analytics)

        // When
        viewModel.dismissTopPerformers()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "dynamic_dashboard_hide_card_tapped" }))
        let properties = analyticsProvider.receivedProperties[index] as? [String: AnyHashable]
        XCTAssertEqual(properties?["type"], "top_performers")
    }
}
