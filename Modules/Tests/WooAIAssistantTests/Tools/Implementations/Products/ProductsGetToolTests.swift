import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductsGetToolTests {
    @Test
    func test_definition_limits_variation_lookup_to_explicit_variation_questions() {
        // Given
        let tool = ProductsGetTool.make()

        // Then
        #expect(tool.definition.description.contains("explicitly asks about variations"))
        #expect(tool.definition.description.contains("variation-level stock"))
        #expect(tool.definition.description.contains("Do NOT call this tool to render a card after products_list"))
    }

    @Test
    func test_products_get_when_response_ok_then_structured_carries_pruned_product_summary() async throws {
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
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsGetTool.make()

        // When
        let result = await tool.executor(#"{"id": 555}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        #expect(success.uiStructured == nil)
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
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsGetTool.make()

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
    func test_products_get_when_response_is_404_then_returns_failed() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 404))
        let tool = ProductsGetTool.make()

        // When
        let result = await tool.executor(#"{"id": 9999}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }    }
}
