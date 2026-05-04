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
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 7, "status": "completed"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        #expect(call.method == "PUT")
        #expect(call.path == "wc/v3/orders/7")
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["status"] as? String == "completed")
    }

    @Test
    func test_ordersUpdate_when_status_outside_allowlist_then_returns_invalidToolCall_without_calling_client() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 1, "status": "shipped"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_ordersUpdate_when_field_outside_allowlist_then_dropped_silently_and_request_excludes_it() async throws {
        // Given
        let body = """
        {"id": 8, "status": "processing"}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
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
        let call = try #require(await client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["discount_total"] == nil)
        #expect(parsed["_method"] == nil)
        #expect(parsed["status"] as? String == "processing")
    }

    @Test
    func test_ordersUpdate_when_only_id_provided_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 1}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_ordersUpdate_when_billing_email_set_then_body_nests_under_billing_object() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok(#"{"id":2}"#))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 2, "billing_email": "buyer@example.com"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let billing = try #require(parsed["billing"] as? [String: Any])
        #expect(billing["email"] as? String == "buyer@example.com")
    }

    @Test
    func test_ordersUpdate_when_status_is_refunded_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 1, "status": "refunded"}"#, client)

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
    func test_ordersUpdate_when_url_timedOut_after_upload_then_returns_outcomeUnknown() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 408))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 1, "status": "processing"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
    }

}
