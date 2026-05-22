import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct OrdersGetToolTests {
    @Test
    func test_orders_get_when_response_ok_then_structured_carries_pruned_order_summary() async throws {
        // Given
        let body = """
        {
            "id": 3551,
            "number": "3551",
            "status": "processing",
            "total": "120.00",
            "currency": "USD",
            "date_created": "2026-04-20T10:00:00",
            "payment_method_title": "Credit Card (Stripe)",
            "billing": {"first_name": "Jane", "last_name": "Doe", "email": "jane@example.com"},
            "_links": {"self": [{"href": "https://example.com/wp-json/wc/v3/orders/3551"}]},
            "meta_data": [{"id": 1, "key": "_pmpro_pin", "value": "abc"}]
        }
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersGetTool.make()

        // When
        let result = await tool.executor(#"{"id": 3551}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(success.uiStructured == nil)
        if case .object(let summary) = success.structured {
            #expect(summary["status"] == .string("processing"))
            #expect(summary["total"] == .string("120.00"))
            #expect(summary["customer_name"] == .string("Jane Doe"))
            #expect(summary["payment_method_title"] == .string("Credit Card (Stripe)"))
            #expect(summary["customer_email"] == .string("jane@example.com"))
        } else {
            Issue.record("expected object structured")
        }
    }

    @Test
    func test_orders_get_when_response_is_404_then_returns_failed_with_unknown_kind() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 404, body: "{\"code\":\"woocommerce_rest_shop_order_invalid_id\"}"))
        let tool = OrdersGetTool.make()

        // When
        let result = await tool.executor(#"{"id": 99999}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .unknown)
    }

    @Test
    func test_orders_get_when_more_than_15_line_items_then_keeps_15() async {
        // Given
        let items = (0..<18).map { idx in
            "{\"id\": \(idx), \"name\": \"Item \(idx)\", \"quantity\": 1, \"product_id\": \(100 + idx)}"
        }.joined(separator: ", ")
        let body = """
        {"id": 3551, "status": "processing", "total": "120.00", "currency": "USD", "line_items": [\(items)]}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersGetTool.make()

        // When
        let result = await tool.executor(#"{"id": 3551}"#, client)

        // Then
        guard case .success(let success) = result,
              case .object(let summary) = success.structured,
              case .array(let lineItems) = summary["line_items"] else {
            Issue.record("expected line_items array, got \(result)")
            return
        }
        #expect(lineItems.count == 15)
        #expect(summary["line_items_count"] == .int(18))
        #expect(summary["line_items_truncated"] == .bool(true))
    }

    @Test
    func test_orders_get_when_id_missing_then_returns_failed_with_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersGetTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }
}
