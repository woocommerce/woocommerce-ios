import Foundation
import Testing
import Yosemite
import WooAIAssistant
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AIAssistantTimeRangeTests {

    @Test
    func test_timeRange_when_payload_has_iso_dates_then_returns_custom_range() {
        // Given
        let sut = makeSUT()
        let payload = AnyCodableJSON.object([
            "after": .string("2026-04-01"),
            "before": .string("2026-04-30")
        ])

        // When
        let range = sut.timeRange(fromAnalyticsPayload: payload)

        // Then
        guard case .custom = range else {
            Issue.record("Expected custom range, got \(range)")
            return
        }
    }

    @Test
    func test_timeRange_when_site_timezone_is_negative_utc_then_preserves_payload_dates() throws {
        // Given
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let sut = makeSUT(timeZone: losAngeles)
        let payload = AnyCodableJSON.object([
            "after": .string("2026-05-04"),
            "before": .string("2026-05-05")
        ])

        // When
        let range = sut.timeRange(fromAnalyticsPayload: payload)

        // Then
        guard case .custom(let from, let to) = range else {
            Issue.record("Expected custom range, got \(range)")
            return
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = losAngeles
        let fromComponents = calendar.dateComponents([.year, .month, .day], from: from)
        let toComponents = calendar.dateComponents([.year, .month, .day], from: to)
        #expect(fromComponents.year == 2026)
        #expect(fromComponents.month == 5)
        #expect(fromComponents.day == 4)
        #expect(toComponents.year == 2026)
        #expect(toComponents.month == 5)
        #expect(toComponents.day == 5)
    }

    @Test
    func test_timeRange_when_payload_has_no_dates_then_returns_today() {
        // Given
        let sut = makeSUT()

        // When
        let range = sut.timeRange(fromAnalyticsPayload: .object([:]))

        // Then
        #expect(range == .today)
    }
}

private extension AIAssistantTimeRangeTests {
    func makeSUT(timeZone: TimeZone = .current) -> AIAssistantExternalNavigationAdaptor {
        let stores = MockStoresManager(sessionManager: SessionManager.makeForTesting(authenticated: true))
        let host = AIAssistantNavigationHost()
        return AIAssistantExternalNavigationAdaptor(siteID: 123,
                                                    navigationHost: host,
                                                    stores: stores,
                                                    timeZone: timeZone)
    }
}
