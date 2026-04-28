import Foundation
import Testing
@testable import WooAIAssistant

struct OrdersListToolTests {
    @Test
    func test_orders_list_when_response_is_array_then_structured_summary_lists_ids_and_total_range() async throws {
        // Given
        let body = """
        [
            {"id": 3551, "number": "3551", "status": "processing", "total": "120.00", "currency": "USD"},
            {"id": 3548, "number": "3548", "status": "on-hold", "total": "12.00", "currency": "USD"},
            {"id": 3540, "number": "3540", "status": "completed", "total": "480.00", "currency": "USD"}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor(#"{"per_page": 3}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(success.uiStructured == nil)
        guard case .object(let fields) = success.structured else {
            Issue.record("expected object structured")
            return
        }
        #expect(fields["count"] == .int(3))
        #expect(fields["ids"] == .array([.int(3551), .int(3548), .int(3540)]))
        #expect(fields["status_counts"] == .object([
            "completed": .int(1),
            "on-hold": .int(1),
            "processing": .int(1)
        ]))
        #expect(fields["total_range"] == .object([
            "min": .string("12"),
            "max": .string("480"),
            "currency": .string("USD")
        ]))
    }

    @Test
    func test_orders_list_when_per_page_above_50_then_query_clamps_to_50() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        _ = await tool.executor(#"{"per_page": 500}"#, client)

        // Then
        #expect(await client.calls.first?.query["per_page"] == "50")
    }

    @Test
    func test_orders_list_when_status_is_any_then_status_param_omitted() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        _ = await tool.executor(#"{"status": "any"}"#, client)

        // Then
        #expect(await client.calls.first?.query["status"] == nil)
    }

    @Test
    func test_orders_list_when_response_is_500_then_returns_failed_with_upstream_failure() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 500, body: "boom"))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .upstreamFailure)    }

    @Test
    func test_orders_list_when_arguments_not_json_then_returns_failed_with_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor("not json", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
    }
}
