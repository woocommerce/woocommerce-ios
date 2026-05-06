import Foundation
import Testing
@testable import WooAIAssistant

struct ProductVariationsBulkUpdateToolTests {

    @Test
    func test_productVariationsBulkUpdate_when_called_with_multiple_variations_then_uses_batch_endpoint() async throws {
        // Given
        let response = """
        {"update": [{"id": 33, "regular_price": "29.99"}, {"id": 34, "regular_price": "29.99"}]}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(response))
        let tool = ProductVariationsBulkUpdateTool.make()
        let arguments = #"""
        {"product_id": 12, "variations": [
            {"id": 33, "regular_price": "29.99"},
            {"id": 34, "regular_price": "29.99"}
        ]}
        """#

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        #expect(call.method == "POST")
        #expect(call.path == "wc/v3/products/12/variations/batch")
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let updates = try #require(parsed["update"] as? [[String: Any]])
        #expect(updates.count == 2)
        let ids = updates.compactMap { $0["id"] as? Int }.sorted()
        #expect(ids == [33, 34])
        for entry in updates {
            #expect(entry["regular_price"] as? String == "29.99")
        }
        #expect(success.uiStructured == nil)
    }

    @Test
    func test_productVariationsBulkUpdate_when_stock_quantity_set_then_each_entry_has_manage_stock_true() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok(#"{"update":[]}"#))
        let tool = ProductVariationsBulkUpdateTool.make()
        let arguments = #"""
        {"product_id": 5, "variations": [
            {"id": 1, "stock_quantity": 4},
            {"id": 2, "stock_quantity": 7}
        ]}
        """#

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let updates = try #require(parsed["update"] as? [[String: Any]])
        for entry in updates {
            #expect(entry["manage_stock"] as? Bool == true)
        }
    }

    @Test
    func test_productVariationsBulkUpdate_when_variations_empty_then_returns_invalidToolCall_without_calling_client() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductVariationsBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 12, "variations": []}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_productVariationsBulkUpdate_when_a_variation_has_no_field_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductVariationsBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 12, "variations": [{"id": 33}]}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_productVariationsBulkUpdate_when_status_outside_allowlist_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductVariationsBulkUpdateTool.make()
        let arguments = #"""
        {"product_id": 12, "variations": [{"id": 33, "status": "archived"}]}
        """#

        // When
        let result = await tool.executor(arguments, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_productVariationsBulkUpdate_when_count_exceeds_max_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductVariationsBulkUpdateTool.make()
        let entries = (1...101).map { #"{"id": \#($0), "regular_price": "1.00"}"# }.joined(separator: ", ")

        // When
        let result = await tool.executor(#"{"product_id": 9, "variations": [\#(entries)]}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }
}
