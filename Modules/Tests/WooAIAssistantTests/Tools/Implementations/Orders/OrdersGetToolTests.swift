import Foundation
import Testing
@testable import WooAIAssistant

struct OrdersGetToolTests {
    @Test
    func test_orders_get_when_response_ok_then_uiStructured_carries_full_entity_card() async throws {
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
        let cards = try #require(success.uiStructured?.cards)
        #expect(cards.count == 1)
        #expect(cards[0].family == .order)
        #expect(cards[0].id == 3551)
        if case .object(let element) = cards[0].element {
            #expect(element["_links"] == nil)
            #expect(element["meta_data"] == nil)
            #expect(element["billing"] != nil)
            #expect(element["status"] == .string("processing"))
        } else {
            Issue.record("expected object element")
        }
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
        #expect(failed.code == "404")
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
