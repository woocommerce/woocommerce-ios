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
        #expect(tool.definition.description.contains("Analytics stats are card-backed"))
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

    @Test
    func test_descriptor_when_inspected_then_compare_to_enum_contains_only_previous_period() {
        // Given
        let tool = AnalyticsOrdersTool.make()

        // Then
        guard case .object(let schema) = tool.definition.parametersSchema,
              case .object(let properties) = schema["properties"],
              case .object(let compareTo) = properties["compare_to"],
              case .array(let values) = compareTo["enum"] else {
            Issue.record("expected compare_to enum")
            return
        }
        #expect(values == [.string("previous_period")])
    }

    @Test
    func test_execute_when_compare_to_is_invalid_value_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor(
            #"{"after":"2026-04-01","before":"2026-04-30","compare_to":"last_year"}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("compare_to must be previous_period"))
    }

    @Test
    func test_execute_when_compare_to_is_omitted_then_summary_has_no_previous_period_fields() async {
        // Given
        let body = #"{"totals": {"orders_count": 1}}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["previous_period_totals"] == nil)
        #expect(fields["previous_period_partial"] == nil)
    }

    @Test
    func test_execute_when_compare_to_is_previous_period_and_secondary_fetch_succeeds_then_previous_period_totals_is_emitted() async {
        // Given
        let primary = #"{"totals": {"orders_count": 10}}"#
        let secondary = #"{"totals": {"orders_count": 5}}"#
        let client = MockWCRESTClient(responses: [
            StubResponses.ok(primary),
            StubResponses.ok(secondary)
        ])
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor(
            #"{"after":"2026-05-01","before":"2026-05-07","compare_to":"previous_period"}"#,
            client
        )

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        guard case .object(let previous) = fields["previous_period_totals"] else {
            Issue.record("expected previous_period_totals")
            return
        }
        #expect(previous["orders_count"] == .int(5))
        #expect(fields["previous_period_partial"] == nil)
        #expect(await client.calls.count == 2)
    }

    @Test
    func test_execute_when_compare_to_is_previous_period_and_secondary_fetch_fails_then_primary_succeeds_with_previous_period_partial_true_and_warning() async {
        // Given
        let primary = #"{"totals": {"orders_count": 10}}"#
        let client = MockWCRESTClient(responses: [
            StubResponses.ok(primary),
            StubResponses.failure(statusCode: 500)
        ])
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor(
            #"{"after":"2026-05-01","before":"2026-05-07","compare_to":"previous_period"}"#,
            client
        )

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["previous_period_partial"] == .bool(true))
        if case .string(let warning) = fields["previous_period_warning"] {
            #expect(warning.contains("could not be fetched"))
        } else {
            Issue.record("expected previous_period_warning string")
        }
        #expect(fields["previous_period_totals"] == nil)
    }

    @Test
    func test_execute_when_primary_fetch_fails_then_call_fails_regardless_of_compare_to() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 500))
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor(
            #"{"after":"2026-05-01","before":"2026-05-07","compare_to":"previous_period"}"#,
            client
        )

        // Then
        guard case .failed = result else {
            Issue.record("expected failed")
            return
        }
    }

    @Test
    func test_summary_when_built_then_interval_is_always_emitted() async {
        // Given
        let body = #"{"totals": {"orders_count": 1}}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor(#"{"after":"2026-04-01","before":"2026-04-30"}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["interval"] == .string("day"))
    }

    @Test
    func test_execute_when_unknown_argument_provided_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = AnalyticsOrdersTool.make()

        // When
        let result = await tool.executor(
            #"{"after":"2026-04-01","before":"2026-04-30","orderby":"date"}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }
}
