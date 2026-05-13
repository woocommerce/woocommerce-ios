import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
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
    func test_ordersUpdate_when_field_outside_allowlist_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()

        // When
        let arguments = #"""
        {"id": 8, "status": "processing", "discount_total": "99.99", "_method": "delete"}
        """#
        let result = await tool.executor(arguments, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("_method"))
        #expect(failed.reason.contains("discount_total"))
        #expect(await client.calls.isEmpty)
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

    @Test
    func test_descriptor_when_inspected_then_id_is_required_and_status_is_optional() {
        // Given
        let tool = OrdersUpdateTool.make()

        // Then
        guard case .object(let schema) = tool.definition.parametersSchema,
              case .array(let required) = schema["required"] else {
            Issue.record("expected schema required array")
            return
        }
        #expect(required == [.string("id")])
    }

    @Test
    func test_descriptor_when_inspected_then_status_enum_excludes_refunded() {
        // Given
        let tool = OrdersUpdateTool.make()

        // Then
        guard case .object(let schema) = tool.definition.parametersSchema,
              case .object(let properties) = schema["properties"],
              case .object(let status) = properties["status"],
              case .array(let values) = status["enum"] else {
            Issue.record("expected status enum")
            return
        }
        let strings = values.compactMap { value -> String? in
            if case .string(let s) = value { return s }
            return nil
        }
        #expect(!strings.contains("refunded"))
    }

    @Test
    func test_execute_when_no_editable_field_provided_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 1}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
    }

    @Test
    func test_execute_when_only_customer_note_provided_then_request_body_contains_customer_note_only() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok(#"{"id":7}"#))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 7, "customer_note": "Thanks"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success")
            return
        }
        let call = try #require(await client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["customer_note"] as? String == "Thanks")
        #expect(parsed["status"] == nil)
        #expect(parsed["billing"] == nil)
    }

    @Test
    func test_execute_when_only_billing_email_provided_then_request_body_contains_billing_object_with_email() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok(#"{"id":7}"#))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 7, "billing_email": "x@y.z"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success")
            return
        }
        let call = try #require(await client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["status"] == nil)
        #expect(parsed["customer_note"] == nil)
        let billing = try #require(parsed["billing"] as? [String: Any])
        #expect(billing["email"] as? String == "x@y.z")
    }

    @Test
    func test_execute_when_status_and_customer_note_provided_then_post_write_summary_includes_widened_fields() async throws {
        // Given
        let body = """
        {
            "id": 7, "status": "processing", "total": "100.00", "currency": "USD",
            "customer_note": "Thanks!",
            "billing": {"first_name": "Jane", "last_name": "Doe", "email": "j@e.com"},
            "line_items": [{"id": 1, "name": "Item", "quantity": 1}]
        }
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"id": 7, "status": "processing", "customer_note": "Hi"}"#,
            client
        )

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(summary["customer_note"] == .string("Thanks!"))
        guard case .array(let items) = summary["line_items"] else {
            Issue.record("expected line_items")
            return
        }
        #expect(items.count == 1)
    }

    @Test
    func test_execute_when_customer_note_exceeds_1000_chars_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()
        let oversize = String(repeating: "a", count: 1001)

        // When
        let result = await tool.executor(#"{"id": 7, "customer_note": "\#(oversize)"}"#, client)

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
    func test_execute_when_billing_email_exceeds_254_chars_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()
        let oversize = String(repeating: "a", count: 245) + "@example.com"

        // When
        let result = await tool.executor(#"{"id": 7, "billing_email": "\#(oversize)"}"#, client)

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
    func test_execute_when_billing_email_is_malformed_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = OrdersUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 7, "billing_email": "not-an-email"}"#, client)

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
