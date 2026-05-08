import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct OrdersBulkUpdateToolTests {
    @Test
    func test_ordersBulkUpdate_when_status_set_then_each_entry_carries_id_and_status() async throws {
        // Given
        let body = """
        {"update": [{"id": 1, "status": "completed"}, {"id": 2, "status": "completed"}]}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
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
        let call = try #require(await client.calls.first)
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
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [], "patch": {"status": "completed"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_ordersBulkUpdate_when_ids_count_exceeds_100_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
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
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_ordersBulkUpdate_when_patch_has_no_field_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_ordersBulkUpdate_when_any_status_is_refunded_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1, 2], "patch": {"status": "refunded"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("Refunds cannot be issued"))
        #expect(failed.reason.contains("Tap an order"))
        #expect(!failed.reason.contains("WP-admin"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_ordersBulkUpdate_when_408_after_upload_then_returns_outcomeUnknown() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 408))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1, 2], "patch": {"status": "completed"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
    }

    @Test
    func test_execute_when_all_patch_fields_succeed_then_receipt_includes_requested_count_and_updated_ids() async {
        // Given
        let body = #"{"update": [{"id": 1, "status": "completed"}, {"id": 2, "status": "completed"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1, 2], "patch": {"status": "completed"}}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["requested_count"] == .int(2))
        #expect(summary["updated_count"] == .int(2))
        #expect(summary["updated_ids"] == .array([.int(1), .int(2)]))
        #expect(summary["partial_success"] == .bool(false))
    }

    @Test
    func test_execute_when_some_entries_fail_then_partial_success_is_true() async {
        // Given
        let body = #"{"update": [{"id": 1, "status": "completed"}, {"id": 2, "error": {"code": "x"}}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1, 2], "patch": {"status": "completed"}}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["partial_success"] == .bool(true))
        #expect(summary["failed_count"] == .int(1))
    }

    @Test
    func test_execute_when_all_entries_succeed_then_partial_success_is_false() async {
        // Given
        let body = #"{"update": [{"id": 1, "status": "completed"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"status": "completed"}}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["partial_success"] == .bool(false))
    }

    @Test
    func test_execute_when_no_entries_succeed_then_partial_success_is_false_and_updated_ids_is_empty_array() async {
        // Given
        let body = #"{"update": [{"id": 1, "error": {"code": "x"}}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"status": "completed"}}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["partial_success"] == .bool(false))
        #expect(summary["updated_ids"] == .array([]))
    }

    @Test
    func test_execute_when_patch_has_status_and_customer_note_then_patch_keys_lists_them_in_canonical_order() async {
        // Given
        let body = #"{"update": [{"id": 1}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"ids": [1], "patch": {"customer_note": "Hi", "status": "completed"}}"#,
            client
        )

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["patch_keys"] == .array([.string("status"), .string("customer_note")]))
    }

    @Test
    func test_execute_when_patch_has_only_billing_email_then_patch_keys_contains_only_billing_email() async {
        // Given
        let body = #"{"update": [{"id": 1}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"billing_email": "a@b.c"}}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["patch_keys"] == .array([.string("billing_email")]))
    }

    @Test
    func test_execute_when_patch_has_unknown_key_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"discount_total": "9.00"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("discount_total"))
    }

    @Test
    func test_execute_when_response_succeeds_then_failed_is_emitted_as_array_even_when_empty() async {
        // Given
        let body = #"{"update": [{"id": 1, "status": "completed"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"status": "completed"}}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["failed"] == .array([]))
    }

    @Test
    func test_execute_when_patch_customer_note_exceeds_1000_chars_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersBulkUpdateTool.make()
        let oversize = String(repeating: "a", count: 1001)

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"customer_note": "\#(oversize)"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason == "customer_note must be at most 1000 characters.")
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_execute_when_patch_billing_email_exceeds_254_chars_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersBulkUpdateTool.make()
        let oversize = String(repeating: "a", count: 245) + "@example.com"

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"billing_email": "\#(oversize)"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason == "billing_email must be at most 254 characters.")
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_execute_when_patch_billing_email_is_malformed_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersBulkUpdateTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1], "patch": {"billing_email": "not-an-email"}}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason == "billing_email must be a valid email address.")
        #expect(await client.calls.isEmpty)
    }
}
