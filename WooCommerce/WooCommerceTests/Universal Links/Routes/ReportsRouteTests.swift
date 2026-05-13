import Testing
import Foundation
import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider
import Yosemite

@testable import WooCommerce

@Suite(.timeLimit(.minutes(5)))
struct ReportsRouteTests {

    @Test
    func test_canHandle_returns_true_for_analytics_subpath() {
        // Given
        let navigator = MockDeepLinkNavigator()
        let sut = ReportsRoute(deepLinkNavigator: navigator, analytics: SpyAnalytics())

        // When / Then
        #expect(sut.canHandle(subPath: "analytics"))
    }

    @Test
    func test_canHandle_returns_false_for_unrelated_subpath() {
        // Given
        let navigator = MockDeepLinkNavigator()
        let sut = ReportsRoute(deepLinkNavigator: navigator, analytics: SpyAnalytics())

        // When / Then
        #expect(!sut.canHandle(subPath: "orders"))
        #expect(!sut.canHandle(subPath: "analytics/foo"))
        #expect(!sut.canHandle(subPath: ""))
    }

    @Test
    func test_performAction_with_unrecognised_subpath_then_returns_false_and_does_not_navigate() {
        // Given
        let navigator = MockDeepLinkNavigator()
        let sut = ReportsRoute(deepLinkNavigator: navigator, analytics: SpyAnalytics())

        // When
        let handled = sut.perform(for: "orders", with: ["metric": "revenue", "range": "today"])

        // Then
        #expect(handled == false)
        #expect(navigator.spyDidNavigate == false)
    }

    @Test(arguments: [
        ("revenue", AnalyticsCard.CardType.revenue),
        ("netSales", .revenue),
        ("orders", .orders),
        ("averageOrderValue", .orders),
        ("itemsSold", .products),
        ("visitors", .sessions),
        ("conversion", .sessions)
    ])
    func test_performAction_with_known_metric_then_navigates_to_matching_focused_card(metric: String,
                                                                                       expectedCard: AnalyticsCard.CardType) throws {
        // Given
        let navigator = MockDeepLinkNavigator()
        let sut = ReportsRoute(deepLinkNavigator: navigator, analytics: SpyAnalytics())

        // When
        let handled = sut.perform(for: "analytics", with: ["metric": metric, "range": "today"])

        // Then
        #expect(handled)
        let destination = try #require(navigator.spyNavigatedDestination as? AnalyticsHubDestination)
        guard case let .focusedCard(card, _) = destination else {
            Issue.record("Expected focusedCard destination, got \(destination)")
            return
        }
        #expect(card == expectedCard)
    }

    @Test(arguments: [
        ("today", AnalyticsHubTimeRangeSelection.SelectionType.today),
        ("yesterday", .yesterday),
        ("lastWeek", .lastWeek),
        ("lastMonth", .lastMonth),
        ("weekToDate", .weekToDate),
        ("monthToDate", .monthToDate)
    ])
    func test_performAction_with_known_range_then_navigates_with_matching_selection_type(range: String,
                                                                                         expectedRange: AnalyticsHubTimeRangeSelection.SelectionType) throws {
        // Given
        let navigator = MockDeepLinkNavigator()
        let sut = ReportsRoute(deepLinkNavigator: navigator, analytics: SpyAnalytics())

        // When
        let handled = sut.perform(for: "analytics", with: ["metric": "revenue", "range": range])

        // Then
        #expect(handled)
        let destination = try #require(navigator.spyNavigatedDestination as? AnalyticsHubDestination)
        guard case let .focusedCard(_, resolvedRange) = destination else {
            Issue.record("Expected focusedCard destination, got \(destination)")
            return
        }
        #expect(resolvedRange == expectedRange)
    }

    @Test
    func test_performAction_with_no_query_params_then_navigates_to_default_hub() throws {
        // Given
        let navigator = MockDeepLinkNavigator()
        let sut = ReportsRoute(deepLinkNavigator: navigator, analytics: SpyAnalytics())

        // When
        let handled = sut.perform(for: "analytics", with: [:])

        // Then
        #expect(handled)
        let destination = try #require(navigator.spyNavigatedDestination as? AnalyticsHubDestination)
        #expect(destination == .defaultHub)
    }

    @Test
    func test_performAction_with_unknown_metric_then_navigates_to_default_hub() throws {
        // Given
        let navigator = MockDeepLinkNavigator()
        let sut = ReportsRoute(deepLinkNavigator: navigator, analytics: SpyAnalytics())

        // When
        let handled = sut.perform(for: "analytics", with: ["metric": "moonRevenue", "range": "today"])

        // Then
        #expect(handled)
        let destination = try #require(navigator.spyNavigatedDestination as? AnalyticsHubDestination)
        #expect(destination == .defaultHub)
    }

    @Test
    func test_performAction_with_unknown_range_then_navigates_to_default_hub() throws {
        // Given
        let navigator = MockDeepLinkNavigator()
        let sut = ReportsRoute(deepLinkNavigator: navigator, analytics: SpyAnalytics())

        // When
        let handled = sut.perform(for: "analytics", with: ["metric": "revenue", "range": "lastDecade"])

        // Then
        #expect(handled)
        let destination = try #require(navigator.spyNavigatedDestination as? AnalyticsHubDestination)
        #expect(destination == .defaultHub)
    }

    @Test
    func test_performAction_tracks_widget_deep_link_tapped_with_raw_query_values() {
        // Given
        let analytics = SpyAnalytics()
        let sut = ReportsRoute(deepLinkNavigator: MockDeepLinkNavigator(), analytics: analytics)

        // When
        _ = sut.perform(for: "analytics", with: ["metric": "revenue", "range": "today"])

        // Then
        #expect(analytics.trackedEvents.contains(where: { $0.name == "widget_deep_link_tapped" }))
        let event = analytics.trackedEvents.first(where: { $0.name == "widget_deep_link_tapped" })
        #expect(event?.properties?["metric"] as? String == "revenue")
        #expect(event?.properties?["range"] as? String == "today")
    }

    @Test
    func test_performAction_tracks_widget_deep_link_tapped_even_with_unknown_values() {
        // Given
        let analytics = SpyAnalytics()
        let sut = ReportsRoute(deepLinkNavigator: MockDeepLinkNavigator(), analytics: analytics)

        // When
        _ = sut.perform(for: "analytics", with: ["metric": "futureMetric", "range": "nextWeek"])

        // Then
        let event = analytics.trackedEvents.first(where: { $0.name == "widget_deep_link_tapped" })
        #expect(event?.properties?["metric"] as? String == "futureMetric")
        #expect(event?.properties?["range"] as? String == "nextWeek")
    }
}

// MARK: - Test doubles

private final class SpyAnalytics: Analytics {
    struct TrackedEvent {
        let name: String
        let properties: [AnyHashable: Any]?
    }

    private(set) var trackedEvents: [TrackedEvent] = []
    var userHasOptedIn: Bool = true
    let analyticsProvider: AnalyticsProvider = SpyAnalyticsProvider()

    func initialize() {}
    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        trackedEvents.append(TrackedEvent(name: eventName, properties: properties))
    }
    func refreshUserData() {}
    func setUserHasOptedOut(_ optedOut: Bool) { userHasOptedIn = !optedOut }
}

private final class SpyAnalyticsProvider: AnalyticsProvider {
    func refreshUserData() {}
    func track(_ eventName: String) {}
    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {}
    func clearEvents() {}
    func clearUsers() {}
}
