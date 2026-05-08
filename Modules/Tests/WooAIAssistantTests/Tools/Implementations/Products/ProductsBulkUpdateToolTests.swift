import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductsBulkUpdateToolTests {
    @Test
    func test_productsBulkUpdate_when_status_set_then_each_entry_carries_id_and_status() async throws {
        // Given
        let body = """
        {"update": [{"id": 10, "status": "draft"}, {"id": 11, "status": "draft"}]}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [10, 11], "patch": {"status": "draft"}}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        #expect(call.method == "POST")
        #expect(call.path == "wc/v3/products/batch")
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let updates = try #require(parsed["update"] as? [[String: Any]])
        #expect(updates.count == 2)
        let ids = updates.compactMap { $0["id"] as? Int }.sorted()
        #expect(ids == [10, 11])
        for entry in updates {
            #expect(entry["status"] as? String == "draft")
        }
    }

    @Test
    func test_productsBulkUpdate_when_stock_quantity_set_then_each_entry_carries_manage_stock_true() async throws {
        // Given
        let body = """
        {"update": [{"id": 1, "stock_quantity": 0}]}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"stock_quantity": 0}}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let updates = try #require(parsed["update"] as? [[String: Any]])
        #expect(updates.first?["manage_stock"] as? Bool == true)
        #expect(updates.first?["stock_quantity"] as? Int == 0)
    }

    @Test
    func test_productsBulkUpdate_when_ids_count_exceeds_100_then_returns_validationError() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsBulkUpdateTool.make()
        let ids = (1...101).map { String($0) }.joined(separator: ", ")

        // When
        let result = await tool.executor(#"{"ids": [\#(ids)], "patch": {"status": "draft"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_productsBulkUpdate_when_ids_empty_then_returns_validationError() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [], "patch": {"status": "draft"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_productsBulkUpdate_when_408_after_upload_then_returns_outcomeUnknown() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 408))
        let tool = ProductsBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"status": "draft"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
    }

    @Test
    func test_execute_when_products_bulk_succeeds_then_patch_keys_uses_name_regular_price_sale_price_stock_quantity_status_order() async {
        // Given
        let body = #"{"update": [{"id": 10}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsBulkUpdateTool.make()

        // When
        let arguments = #"""
        {"ids": [10], "patch": {"status": "draft", "stock_quantity": 5, "sale_price": "9", "regular_price": "10", "name": "X"}}
        """#
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["patch_keys"] == .array([
            .string("name"),
            .string("regular_price"),
            .string("sale_price"),
            .string("stock_quantity"),
            .string("status")
        ]))
    }

    @Test
    func test_execute_when_products_bulk_succeeds_then_receipt_includes_requested_count_and_updated_ids() async {
        // Given
        let body = #"{"update": [{"id": 10, "name": "X"}, {"id": 11, "name": "X"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [10, 11], "patch": {"name": "X"}}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["requested_count"] == .int(2))
        #expect(summary["updated_ids"] == .array([.int(10), .int(11)]))
        #expect(summary["partial_success"] == .bool(false))
        #expect(summary["failed"] == .array([]))
    }
}
