import Foundation
import Testing
@testable import WooAIAssistant

struct ProductsListToolTests {
    @Test
    func test_products_list_when_response_is_array_then_structured_summary_lists_ids_and_price_range() async throws {
        // Given
        let body = """
        [
            {"id": 101, "name": "Hoodie", "sku": "HOOD-1", "price": "49.00", "stock_status": "instock"},
            {"id": 102, "name": "Tee", "sku": "TEE-1", "price": "19.00", "stock_status": "outofstock"},
            {"id": 103, "name": "Jacket", "sku": "JAC-1", "price": "120.00", "stock_status": "instock"}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

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
        #expect(fields["ids"] == .array([.int(101), .int(102), .int(103)]))
        #expect(fields["stock_status_counts"] == .object([
            "instock": .int(2),
            "outofstock": .int(1)
        ]))
        #expect(fields["price_range"] == .object([
            "min": .string("19"),
            "max": .string("120")
        ]))
    }

    @Test
    func test_products_list_when_search_passed_then_query_carries_search_param() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        _ = await tool.executor(#"{"search": "scarf"}"#, client)

        // Then
        #expect(client.calls.first?.query["search"] == "scarf")
        #expect(client.calls.first?.path == "wc/v3/products")
    }

    @Test
    func test_products_list_when_response_is_403_then_returns_failed_with_auth_kind() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 403))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .auth)
    }
}
