import Foundation
import Testing
@testable import WooAIAssistant

struct OrdersUpdateToolTests {
    @Test
    func test_ordersUpdate_when_status_completed_then_sends_status_body() async throws {
        // Given
        let body = """
        {"id": 7, "status": "completed", "total": "10.00", "currency": "USD"}
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 7, "status": "completed"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(client.calls.first)
        #expect(call.method == "PUT")
        #expect(call.path == "wc/v3/orders/7")
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["status"] as? String == "completed")
    }

    @Test
    func test_ordersUpdate_when_status_outside_allowlist_then_returns_invalidToolCall_without_calling_client() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 1, "status": "shipped"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(client.calls.isEmpty)
    }

    @Test
    func test_ordersUpdate_when_field_outside_allowlist_then_dropped_silently_and_request_excludes_it() async throws {
        // Given
        let body = """
        {"id": 8, "status": "processing"}
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersUpdateTool.make()

        // When
        let arguments = #"""
        {"id": 8, "status": "processing", "discount_total": "99.99", "_method": "delete"}
        """#
        let result = await tool.executor(arguments, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["discount_total"] == nil)
        #expect(parsed["_method"] == nil)
        #expect(parsed["status"] as? String == "processing")
    }

    @Test
    func test_ordersUpdate_when_only_id_provided_then_returns_invalidToolCall() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 1}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(client.calls.isEmpty)
    }

    @Test
    func test_ordersUpdate_when_billing_email_set_then_body_nests_under_billing_object() async throws {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.ok(#"{"id":2}"#))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 2, "billing_email": "buyer@example.com"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let billing = try #require(parsed["billing"] as? [String: Any])
        #expect(billing["email"] as? String == "buyer@example.com")
    }

    @Test
    func test_ordersUpdate_when_url_timedOut_after_upload_then_returns_outcomeUnknown_with_uuid_correlation_id() async throws {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.failure(statusCode: 408))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 1, "status": "processing"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
        let code = try #require(failed.code)
        #expect(UUID(uuidString: code) != nil)
    }

    @Test
    func test_ordersUpdate_when_two_writes_time_out_then_each_gets_a_unique_correlation_id() async throws {
        // Given
        let client = RecordingWCRESTClient(responses: [
            StubResponses.failure(statusCode: 408),
            StubResponses.failure(statusCode: 408)
        ])
        let tool = OrdersUpdateTool.make()

        // When
        let firstResult = await tool.executor(#"{"id": 1, "status": "processing"}"#, client)
        let secondResult = await tool.executor(#"{"id": 2, "status": "processing"}"#, client)

        // Then
        guard case .failed(let firstFailed) = firstResult,
              case .failed(let secondFailed) = secondResult else {
            Issue.record("expected both failed, got \(firstResult) and \(secondResult)")
            return
        }
        let firstCode = try #require(firstFailed.code)
        let secondCode = try #require(secondFailed.code)
        #expect(UUID(uuidString: firstCode) != nil)
        #expect(UUID(uuidString: secondCode) != nil)
        #expect(firstCode != secondCode)
    }
}
