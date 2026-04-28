import Foundation
import Testing
@testable import WooAIAssistant

struct ProductVariationsListToolTests {
    @Test
    func test_product_variations_list_when_response_is_array_then_summary_carries_parent_id_and_ids() async throws {
        // Given
        let body = """
        [
            {"id": 1001, "stock_status": "instock", "price": "20.00"},
            {"id": 1002, "stock_status": "outofstock", "price": "25.00"}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductVariationsListTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 555}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        #expect(success.uiStructured == nil)
        #expect(await client.calls.first?.path == "wc/v3/products/555/variations")
        if case .object(let fields) = success.structured {
            #expect(fields["product_id"] == .int(555))
            #expect(fields["count"] == .int(2))
            #expect(fields["ids"] == .array([.int(1001), .int(1002)]))
            #expect(fields["stock_status_counts"] == .object([
                "instock": .int(1),
                "outofstock": .int(1)
            ]))
        } else {
            Issue.record("expected object structured")
        }
    }

    @Test
    func test_product_variations_list_when_product_id_missing_then_returns_failed_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductVariationsListTool.make()

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
    func test_product_variations_list_when_per_page_above_50_then_query_clamps_to_50() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductVariationsListTool.make()

        // When
        _ = await tool.executor(#"{"product_id": 555, "per_page": 250}"#, client)

        // Then
        #expect(await client.calls.first?.query["per_page"] == "50")
    }
}
