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
    func test_orders_list_definition_documents_product_filter() {
        // Given
        let tool = OrdersListTool.make()

        // Then
        #expect(tool.definition.description.contains("prefer the `product` filter over `search`"))
        #expect(tool.definition.description.contains("resolve the product id"))
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
    func test_orders_list_when_row_line_items_exceed_list_limit_then_line_items_truncated_is_true_for_that_row() async throws {
        // Given
        let items = (0..<10).map { idx in
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
        #expect(lineItems.count == 7)
        #expect(first["line_items_truncated"] == .bool(true))
        #expect(first["line_items_count"] == .int(10))
    }

    @Test
    func test_orders_list_when_typical_full_page_then_summary_stays_under_llm_cap() async throws {
        // Given a realistic full window of 50 orders carrying the common 1-3 line items each,
        // which is the everyday shape the raised list cap must keep well under the payload budget.
        let orders = (0..<50).map { orderIndex -> String in
            let itemCount = (orderIndex % 3) + 1
            let lineItems = (0..<itemCount).map { itemIndex in
                """
                {"id": \(itemIndex), "name": "Merino Wool Crew Neck Sweater \(itemIndex)", \
                "quantity": 2, "sku": "MWCNS-\(orderIndex)-\(itemIndex)", "total": "129.00", \
                "product_id": \(1000 + itemIndex), "variation_id": \(5000 + itemIndex)}
                """
            }.joined(separator: ", ")
            return """
            {"id": \(3000 + orderIndex), "number": "\(3000 + orderIndex)", "status": "processing", \
            "total": "258.00", "currency": "USD", "date_created": "2026-05-20T10:00:00", \
            "payment_method_title": "Stripe Credit Card", \
            "billing": {"first_name": "Firstname", "last_name": "Lastname", "email": "buyer\(orderIndex)@example.com", \
            "phone": "+1 555 0100", "city": "Portland", "state": "OR", "postcode": "97201", "country": "US"}, \
            "line_items": [\(lineItems)]}
            """
        }.joined(separator: ", ")
        let client = MockWCRESTClient(response: StubResponses.ok("[\(orders)]"))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor(#"{"per_page": 50}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        let encoded = try JSONEncoder().encode(success.structured)
        #expect(encoded.count < LLMPayloadCap.maxBytes)
        // No truncation marker means the real summary survived rather than being dropped.
        if case .object(let fields) = success.structured {
            #expect(fields["truncated"] == nil)
            #expect(fields["count"] == .int(50))
        } else {
            Issue.record("expected object structured")
        }
    }

    @Test
    func test_orders_list_when_pathological_full_page_then_cap_fires_and_nudges_show_cards() async throws {
        // Given the worst case the raised caps allow: 50 orders each maxed at the list line-item
        // cap with long names/skus. This exceeds 64KB, so the cap must protect the context window.
        let orders = (0..<50).map { orderIndex -> String in
            let lineItems = (0..<OrderSummary.listLineItemLimit).map { itemIndex in
                """
                {"id": \(itemIndex), "name": "Merino Wool Crew Neck Sweater Extra Long Title \(itemIndex)", \
                "quantity": 2, "sku": "MWCNS-LONG-SKU-\(orderIndex)-\(itemIndex)", "total": "129.00", \
                "product_id": \(1000 + itemIndex), "variation_id": \(5000 + itemIndex)}
                """
            }.joined(separator: ", ")
            return """
            {"id": \(3000 + orderIndex), "number": "\(3000 + orderIndex)", "status": "processing", \
            "total": "258.00", "currency": "USD", "date_created": "2026-05-20T10:00:00", \
            "payment_method_title": "Stripe Credit Card", \
            "billing": {"first_name": "Firstname", "last_name": "Lastname", "email": "buyer\(orderIndex)@example.com", \
            "phone": "+1 555 0100", "city": "Portland", "state": "OR", "postcode": "97201", "country": "US"}, \
            "line_items": [\(lineItems)]}
            """
        }.joined(separator: ", ")
        let client = MockWCRESTClient(response: StubResponses.ok("[\(orders)]"))
        let tool = OrdersListTool.make()

        // When
        let result = await tool.executor(#"{"per_page": 50}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        let encoded = try JSONEncoder().encode(success.structured)
        #expect(encoded.count < LLMPayloadCap.maxBytes)
        if case .object(let fields) = success.structured {
            #expect(fields["truncated"] == .bool(true))
        } else {
            Issue.record("expected object structured")
        }
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
    func test_orders_list_when_product_provided_then_query_carries_product_id() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        _ = await tool.executor(#"{"product": 3903}"#, client)

        // Then
        #expect(await client.calls.first?.query["product"] == "3903")
    }

    @Test
    func test_orders_list_when_product_and_status_provided_then_query_carries_both() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        _ = await tool.executor(#"{"product": 3903, "status": "completed"}"#, client)

        // Then
        #expect(await client.calls.first?.query["product"] == "3903")
        #expect(await client.calls.first?.query["status"] == "completed")
    }

    @Test
    func test_orders_list_when_product_omitted_then_query_has_no_product_param() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = OrdersListTool.make()

        // When
        _ = await tool.executor("{}", client)

        // Then
        #expect(await client.calls.first?.query["product"] == nil)
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
