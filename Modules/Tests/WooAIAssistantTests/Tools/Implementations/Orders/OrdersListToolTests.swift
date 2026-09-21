import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct OrdersListToolTests {
    @Test
    func test_orders_list_definition_documents_latest_order_card_flow() {
        // Given
        let tool = OrdersListTool.make()

        // Then
        #expect(tool.definition.description.contains("latest/last single-order"))
        #expect(tool.definition.description.contains("per_page=1"))
        #expect(tool.definition.description.contains("then pass the result to `show_cards`"))
    }

    @Test
    func test_orders_list_when_response_is_array_then_structured_summary_lists_ids_and_total_range() async throws {
        // Given
        let body = """
        [
            {"id": 3551, "number": "3551", "status": "processing", "total": "120.00", "currency": "USD", "customer_id": 11},
            {"id": 3548, "number": "3548", "status": "on-hold", "total": "12.00", "currency": "USD", "customer_id": 22},
            {"id": 3540, "number": "3540", "status": "completed", "total": "480.00", "currency": "USD", "customer_id": 0}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersListTool.make()

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
        #expect(fields["ids"] == .array([.int(3551), .int(3548), .int(3540)]))
        #expect(fields["status_counts"] == .object([
            "completed": .int(1),
            "on-hold": .int(1),
            "processing": .int(1)
        ]))
        #expect(fields["total_range"] == .object([
            "min": .string("12"),
            "max": .string("480"),
            "currency": .string("USD")
        ]))
        guard case .array(let orders) = fields["orders"] else {
            Issue.record("expected orders array")
            return
        }
        #expect(orders.count == 3)
    }

    @Test
    func test_orders_list_when_rows_present_then_orders_array_carries_per_row_widened_fields() async throws {
        // Given
        let body = """
        [
            {
                "id": 3551, "number": "3551", "status": "processing", "total": "120.00", "currency": "USD",
                "payment_method_title": "Stripe",
                "billing": {"first_name": "Jane", "last_name": "Doe", "email": "j@example.com"},
                "line_items": [{"id": 1, "name": "A", "quantity": 1}]
            }
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor(#"{"per_page": 1}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        guard case .object(let fields) = success.structured,
              case .array(let orders) = fields["orders"],
              case .object(let first) = orders.first else {
            Issue.record("expected first order object")
            return
        }
        #expect(first["payment_method_title"] == .string("Stripe"))
        #expect(first["customer_name"] == .string("Jane Doe"))
        #expect(first["customer_email"] == .string("j@example.com"))
        guard case .array(let items) = first["line_items"] else {
            Issue.record("expected line_items")
            return
        }
        #expect(items.count == 1)
    }

    @Test
    func test_orders_list_when_row_line_items_exceed_five_then_line_items_truncated_is_true_for_that_row() async throws {
        // Given
        let items = (0..<7).map { idx in
            "{\"id\": \(idx), \"name\": \"Item \(idx)\", \"quantity\": 1}"
        }.joined(separator: ", ")
        let body = """
        [
            {"id": 1, "status": "processing", "total": "10.00", "currency": "USD", "line_items": [\(items)]}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let orders) = fields["orders"],
              case .object(let first) = orders.first,
              case .array(let lineItems) = first["line_items"] else {
            Issue.record("expected line_items in first order")
            return
        }
        #expect(lineItems.count == 5)
        #expect(first["line_items_truncated"] == .bool(true))
        #expect(first["line_items_count"] == .int(7))
    }

    @Test
    func test_orders_list_when_row_customer_note_exceeds_500_chars_then_row_customer_note_truncated_is_true() async throws {
        // Given
        let note = String(repeating: "x", count: 600)
        let body = """
        [
            {"id": 1, "status": "processing", "total": "10.00", "currency": "USD", "customer_note": "\(note)"}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let orders) = fields["orders"],
              case .object(let first) = orders.first else {
            Issue.record("expected first order")
            return
        }
        #expect(first["customer_note_truncated"] == .bool(true))
    }

    @Test
    func test_orders_list_when_per_page_above_50_then_query_clamps_to_50() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        _ = await tool.executor(#"{"per_page": 500}"#, client)

        // Then
        #expect(await client.calls.first?.query["per_page"] == "50")
    }

    @Test
    func test_orders_list_when_after_and_before_are_bare_dates_then_query_pads_to_iso_day_boundaries() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        _ = await tool.executor(#"{"after": "2026-05-14", "before": "2026-05-14"}"#, client)

        // Then
        #expect(await client.calls.first?.query["after"] == "2026-05-14T00:00:00")
        #expect(await client.calls.first?.query["before"] == "2026-05-14T23:59:59")
    }

    @Test
    func test_orders_list_when_after_is_invalid_date_then_returns_failed_with_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor(#"{"after": "last week"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
    }

    @Test
    func test_orders_list_when_status_is_any_then_status_param_omitted() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        _ = await tool.executor(#"{"status": "any"}"#, client)

        // Then
        #expect(await client.calls.first?.query["status"] == nil)
    }

    @Test
    func test_orders_list_when_response_is_500_then_returns_failed_with_upstream_failure() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 500, body: "boom"))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .upstreamFailure)
    }

    @Test
    func test_orders_list_when_arguments_not_json_then_returns_failed_with_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor("not json", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
    }
}
