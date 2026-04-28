import Foundation
import Testing
@testable import WooAIAssistant

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
    func test_productsBulkUpdate_when_408_after_upload_then_returns_outcomeUnknown_with_uuid_correlation_id() async throws {
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
        let code = try #require(failed.code)
        #expect(UUID(uuidString: code) != nil)
    }
}
