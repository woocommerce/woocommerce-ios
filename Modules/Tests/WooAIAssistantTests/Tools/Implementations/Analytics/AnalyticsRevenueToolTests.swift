import Foundation
import Testing
@testable import WooAIAssistant

struct AnalyticsRevenueToolTests {
    @Test
    func test_analytics_revenue_when_response_ok_then_summary_keeps_totals_and_interval_count() async throws {
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
        let tool = AnalyticsRevenueTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        #expect(success.uiStructured == nil)
        if case .object(let fields) = success.structured {
            #expect(fields["after"] == .string("2026-04-01"))
            #expect(fields["before"] == .string("2026-04-30"))
            #expect(fields["interval_count"] == .int(2))
            if case .object(let totals) = fields["totals"] {
                #expect(totals["net_revenue"] == .string("12345.67"))
            } else {
                Issue.record("expected totals object")
            }
        } else {
            Issue.record("expected object structured")
        }
        #expect(client.calls.first?.query["after"] == "2026-04-01T00:00:00")
        #expect(client.calls.first?.query["before"] == "2026-04-30T23:59:59")
        #expect(client.calls.first?.query["interval"] == "day")
    }

    @Test
    func test_analytics_revenue_when_dates_invalid_then_returns_failed_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = AnalyticsRevenueTool.make()

        // When
        let result = await tool.executor(#"{"after":"04/01/2026","before":"04/30/2026"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(client.calls.isEmpty)
    }

    @Test
    func test_analytics_revenue_when_response_is_429_then_returns_failed_with_rate_limit_kind() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 429))
        let tool = AnalyticsRevenueTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .rateLimit)
    }
}
