import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AnalyticsOrdersToolTests {
    @Test
    func test_analytics_orders_definition_documents_grain_separate_from_window() {
        // Given
        let tool = AnalyticsOrdersTool.make()

        // Then
        #expect(tool.definition.description.contains("grouping grain with a date window"))
        #expect(tool.definition.description.contains("interval follows the grouping grain"))
        #expect(tool.definition.description.contains("Order stats are card-backed"))
        #expect(tool.definition.description.contains("do not stop with prose"))
        #expect(tool.definition.description.contains("family analytics_stats"))
        #expect(tool.definition.description.contains("currency:none"))
    }

    @Test
    func test_analytics_orders_when_response_ok_then_summary_keeps_totals_and_interval_count() async throws {
        // Given
        let body = """
        {
            "totals": {"orders_count": 42, "avg_order_value": "85.30"},
            "intervals": [
                {"interval": "week-2026-15", "date_start": "2026-04-07 00:00:00", "subtotals": {"orders_count": 12}}
            ]
        }
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30","interval":"week"}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        #expect(success.uiStructured == nil)
        if case .object(let fields) = success.structured {
            #expect(fields["interval_count"] == .int(1))
            if case .object(let totals) = fields["totals"] {
                #expect(totals["orders_count"] == .int(42))
                #expect(totals["avg_order_value"] == .string("85.30"))
            } else {
                Issue.record("expected totals object")
            }
        } else {
            Issue.record("expected object structured")
        }
        #expect(await client.calls.first?.path == "wc-analytics/reports/orders/stats")
        #expect(await client.calls.first?.query["interval"] == "week")
    }

    @Test
    func test_analytics_orders_when_required_dates_missing_then_returns_failed_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_analytics_orders_when_response_is_500_then_returns_failed_with_upstream_failure() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 500))
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .upstreamFailure)
    }
}
