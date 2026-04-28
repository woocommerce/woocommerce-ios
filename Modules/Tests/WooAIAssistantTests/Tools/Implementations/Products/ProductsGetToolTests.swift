import Foundation
import Testing
@testable import WooAIAssistant

struct ProductsGetToolTests {
    @Test
    func test_products_get_when_response_ok_then_uiStructured_carries_product_card_with_pruned_entity() async throws {
        // Given
        let body = """
        {
            "id": 555,
            "name": "Cashmere Scarf",
            "sku": "SCARF-CSH",
            "price": "89.00",
            "regular_price": "99.00",
            "sale_price": "89.00",
            "stock_status": "instock",
            "stock_quantity": 12,
            "type": "simple",
            "status": "publish",
            "description": "<p>Soft &amp; warm cashmere scarf.</p>",
            "_links": {"self": []},
            "meta_data": [{"id": 1, "key": "_x", "value": "y"}],
            "images": [{"src": "https://example.com/scarf.jpg"}]
        }
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsGetTool.make()

        // When
        let result = await tool.executor(#"{"id": 555}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        let cards = try #require(success.uiStructured?.cards)
        #expect(cards.count == 1)
        #expect(cards[0].family == .product)
        #expect(cards[0].id == 555)
        if case .object(let element) = cards[0].element {
            #expect(element["_links"] == nil)
            #expect(element["meta_data"] == nil)
            #expect(element["description"] == .string("Soft & warm cashmere scarf."))
        } else {
            Issue.record("expected object element")
        }
        if case .object(let summary) = success.structured {
            #expect(summary["sku"] == .string("SCARF-CSH"))
            #expect(summary["stock_status"] == .string("instock"))
            #expect(summary["stock_quantity"] == .int(12))
            #expect(summary["regular_price"] == .string("99.00"))
            #expect(summary["sale_price"] == .string("89.00"))
            #expect(summary["description"] == nil)
        } else {
            Issue.record("expected object structured")
        }
    }

    @Test
    func test_products_get_when_id_missing_then_returns_failed_invalid_tool_call() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsGetTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(client.calls.isEmpty)
    }

    @Test
    func test_products_get_when_response_is_404_then_returns_failed() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.failure(statusCode: 404))
        let tool = ProductsGetTool.make()

        // When
        let result = await tool.executor(#"{"id": 9999}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.code == "404")
    }
}
