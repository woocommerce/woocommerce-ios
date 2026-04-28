import Foundation
import Testing
@testable import WooAIAssistant

struct OrdersBulkUpdateToolTests {
    @Test
    func test_ordersBulkUpdate_when_status_set_then_each_entry_carries_id_and_status() async throws {
        // Given
        let body = """
        {"update": [{"id": 1, "status": "completed"}, {"id": 2, "status": "completed"}]}
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let arguments = #"""
        {"ids": [1, 2], "patch": {"status": "completed"}}
        """#
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(client.calls.first)
        #expect(call.method == "POST")
        #expect(call.path == "wc/v3/orders/batch")
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let updates = try #require(parsed["update"] as? [[String: Any]])
        #expect(updates.count == 2)
        let ids = updates.compactMap { $0["id"] as? Int }.sorted()
        #expect(ids == [1, 2])
        for entry in updates {
            #expect(entry["status"] as? String == "completed")
        }
    }

    @Test
    func test_ordersBulkUpdate_when_ids_empty_then_returns_invalidToolCall_without_calling_client() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [], "patch": {"status": "completed"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(client.calls.isEmpty)
    }

    @Test
    func test_ordersBulkUpdate_when_ids_count_exceeds_100_then_returns_invalidToolCall() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersBulkUpdateTool.make()
        let ids = (1...101).map { String($0) }.joined(separator: ", ")

        // When
        let result = await tool.executor(#"{"ids": [\#(ids)], "patch": {"status": "processing"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(client.calls.isEmpty)
    }

    @Test
    func test_ordersBulkUpdate_when_patch_has_no_field_then_returns_invalidToolCall() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(client.calls.isEmpty)
    }

    @Test
    func test_ordersBulkUpdate_when_408_after_upload_then_returns_outcomeUnknown_with_uuid_correlation_id() async throws {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.failure(statusCode: 408))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1, 2], "patch": {"status": "completed"}}"#, client)

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
