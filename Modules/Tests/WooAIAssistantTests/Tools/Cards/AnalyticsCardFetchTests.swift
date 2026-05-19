import Foundation
import Testing
@testable import WooAIAssistant

struct AnalyticsCardFetchTests {
    @Test
    func test_fetch_when_response_ok_then_returns_summary_with_totals_and_interval_count() async {
        // Given
        let body = """
        {
            "totals": {"net_revenue": "12345.67", "orders_count": 42, "gross_sales": "13000.00"},
            "intervals": [
                {"interval": "2026-04-01", "date_start": "2026-04-01 00:00:00", "subtotals": {"orders_count": 5}},
                {"interval": "2026-04-02", "date_start": "2026-04-02 00:00:00", "subtotals": {"orders_count": 7}}
            ]
        }
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let spec = AnalyticsCardSpec(kind: .orders, after: "2026-04-01", before: "2026-04-30",
                                     interval: nil, currency: nil)
        let fetch = AnalyticsCardFetch(client: client)

        // When
        let outcome = await fetch.fetch(spec)

        // Then
        guard case .found(let summary) = outcome else {
            Issue.record("expected found, got \(outcome)")
            return
        }
        if case .object(let fields) = summary {
            #expect(fields["after"] == .string("2026-04-01"))
            #expect(fields["before"] == .string("2026-04-30"))
            #expect(fields["interval_count"] == .int(2))
            if case .object(let totals) = fields["totals"] {
                #expect(totals["net_revenue"] == .string("12345.67"))
            } else {
                Issue.record("expected totals object")
            }
        } else {
            Issue.record("expected object summary")
        }
    }

    @Test
    func test_fetch_when_kind_is_orders_then_uses_orders_stats_path() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok(#"{"totals":{},"intervals":[]}"#))
        let spec = AnalyticsCardSpec(kind: .orders, after: "2026-04-01", before: "2026-04-30",
                                     interval: nil, currency: nil)
        let fetch = AnalyticsCardFetch(client: client)

        // When
        _ = await fetch.fetch(spec)

        // Then
        let calls = await client.calls
        #expect(calls.first?.path == "wc-analytics/reports/orders/stats")
    }

    @Test
    func test_fetch_when_interval_omitted_then_defaults_to_day_and_uses_day_boundaries() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok(#"{"totals":{},"intervals":[]}"#))
        let spec = AnalyticsCardSpec(kind: .orders, after: "2026-04-01", before: "2026-04-30",
                                     interval: nil, currency: nil)
        let fetch = AnalyticsCardFetch(client: client)

        // When
        _ = await fetch.fetch(spec)

        // Then
        let calls = await client.calls
        #expect(calls.first?.query["interval"] == "day")
        #expect(calls.first?.query["after"] == "2026-04-01T00:00:00")
        #expect(calls.first?.query["before"] == "2026-04-30T23:59:59")
    }

    @Test
    func test_fetch_when_currency_provided_then_forwards_currency_query_param() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok(#"{"totals":{},"intervals":[]}"#))
        let spec = AnalyticsCardSpec(kind: .orders, after: "2026-04-01", before: "2026-04-30",
                                     interval: nil, currency: "EUR")
        let fetch = AnalyticsCardFetch(client: client)

        // When
        _ = await fetch.fetch(spec)

        // Then
        let calls = await client.calls
        #expect(calls.first?.query["currency"] == "EUR")
    }

    @Test
    func test_fetch_when_dates_are_invalid_then_rejects_as_malformed_without_calling_client() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let spec = AnalyticsCardSpec(kind: .orders, after: "04/01/2026", before: "04/30/2026",
                                     interval: nil, currency: nil)
        let fetch = AnalyticsCardFetch(client: client)

        // When
        let outcome = await fetch.fetch(spec)

        // Then
        guard case .rejected(let reason) = outcome else {
            Issue.record("expected rejected")
            return
        }
        #expect(reason == .malformed)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_fetch_when_endpoint_returns_403_then_rejects_as_notPermitted() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 403))
        let spec = AnalyticsCardSpec(kind: .orders, after: "2026-04-01", before: "2026-04-30",
                                     interval: nil, currency: nil)
        let fetch = AnalyticsCardFetch(client: client)

        // When
        let outcome = await fetch.fetch(spec)

        // Then
        if case .rejected(let reason) = outcome {
            #expect(reason == .notPermitted)
        } else {
            Issue.record("expected rejected")
        }
    }

    @Test
    func test_fetch_when_response_body_is_unparseable_then_rejects_as_internalError() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("not json"))
        let spec = AnalyticsCardSpec(kind: .orders, after: "2026-04-01", before: "2026-04-30",
                                     interval: nil, currency: nil)
        let fetch = AnalyticsCardFetch(client: client)

        // When
        let outcome = await fetch.fetch(spec)

        // Then
        if case .rejected(let reason) = outcome {
            #expect(reason == .internalError)
        } else {
            Issue.record("expected rejected")
        }
    }
}
