import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductsListToolTests {
    @Test
    func test_products_list_definition_documents_unified_entity_surface() {
        // Given
        let tool = ProductsListTool.make()

        // Then
        #expect(tool.definition.description.contains("parent_id"))
        #expect(tool.definition.description.contains("kind"))
        #expect(tool.definition.description.contains("pass returned ids to `show_cards`"))
        #expect(tool.definition.description.contains("no match was found"))
    }

    @Test
    func test_products_list_when_response_is_array_then_structured_summary_lists_ids_and_price_range() async throws {
        // Given
        let body = """
        [
            {"id": 101, "name": "Hoodie", "sku": "HOOD-1", "price": "49.00", "stock_status": "instock"},
            {"id": 102, "name": "Tee", "sku": "TEE-1", "price": "19.00", "stock_status": "outofstock"},
            {"id": 103, "name": "Jacket", "sku": "JAC-1", "price": "120.00", "stock_status": "instock"}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

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
        #expect(fields["ids"] == .array([.int(101), .int(102), .int(103)]))
        #expect(fields["stock_status_counts"] == .object([
            "instock": .int(2),
            "outofstock": .int(1)
        ]))
        #expect(fields["price_range"] == .object([
            "min": .string("19"),
            "max": .string("120")
        ]))
        guard case .array(let products) = fields["products"] else {
            Issue.record("expected products array")
            return
        }
        #expect(products.count == 3)
    }

    @Test
    func test_products_list_summary_when_row_is_top_level_product_then_target_is_product_kind() async throws {
        // Given
        let body = """
        [{"id": 42, "name": "Hoodie", "type": "simple"}]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let products) = fields["products"],
              case .object(let first) = products.first,
              case .object(let target) = first["target"] else {
            Issue.record("expected target object on product row")
            return
        }
        #expect(target["kind"] == .string("product"))
        #expect(target["id"] == .int(42))
        #expect(target["parent_id"] == nil)
    }

    @Test
    func test_products_list_summary_when_row_is_variation_then_target_carries_parent_id() async throws {
        // Given
        let body = """
        [{"id": 58, "parent_id": 41, "name": "Red / L"}]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"parent_id": 41}"#, client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let products) = fields["products"],
              case .object(let first) = products.first,
              case .object(let target) = first["target"] else {
            Issue.record("expected target object on variation row")
            return
        }
        #expect(target["kind"] == .string("variation"))
        #expect(target["id"] == .int(58))
        #expect(target["parent_id"] == .int(41))
    }

    @Test
    func test_execute_when_response_carries_per_page_rows_then_can_load_more_is_true() async {
        // Given
        let body = """
        [{"id": 1}, {"id": 2}]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"per_page": 2}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success")
            return
        }
        #expect(fields["can_load_more"] == .bool(true))
    }

    @Test
    func test_execute_when_response_has_fewer_rows_than_per_page_then_can_load_more_is_false() async {
        // Given
        let body = """
        [{"id": 1}]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"per_page": 5}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success")
            return
        }
        #expect(fields["can_load_more"] == .bool(false))
    }

    @Test
    func test_products_list_when_search_passed_then_query_carries_search_param() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        _ = await tool.executor(#"{"search": "scarf"}"#, client)

        // Then
        #expect(await client.calls.first?.query["search"] == "scarf")
        #expect(await client.calls.first?.path == "wc/v3/products")
    }

    @Test
    func test_list_when_page_2_requested_then_query_carries_page_param() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        _ = await tool.executor(#"{"page": 2}"#, client)

        // Then
        #expect(await client.calls.first?.query["page"] == "2")
    }

    @Test
    func test_list_when_results_empty_then_summary_has_zero_count_and_empty_arrays() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success")
            return
        }
        #expect(fields["count"] == .int(0))
        #expect(fields["ids"] == .array([]))
        #expect(fields["products"] == .array([]))
        #expect(fields["can_load_more"] == .bool(false))
    }

    @Test
    func test_products_list_when_response_is_403_then_returns_failed_with_auth_kind() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 403))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .auth)
    }

    @Test
    func test_descriptor_when_inspected_then_matches_consolidated_list_surface() {
        // Given Android parity lands with its own consolidation; this pins the iOS-leading surface.
        let tool = ProductsListTool.make()

        // Then
        guard case .object(let schema) = tool.definition.parametersSchema,
              case .object(let properties) = schema["properties"] else {
            Issue.record("expected schema properties")
            return
        }
        let keys = Set(properties.keys)
        #expect(keys == [
            "search", "status", "category", "sku", "ids", "parent_id", "stock_status",
            "orderby", "order", "page", "per_page"
        ])
    }

    @Test
    func test_descriptor_when_inspected_then_tag_is_not_exposed() {
        // Given
        let tool = ProductsListTool.make()

        // Then
        guard case .object(let schema) = tool.definition.parametersSchema,
              case .object(let properties) = schema["properties"] else {
            Issue.record("expected schema")
            return
        }
        #expect(properties["tag"] == nil)
    }

    @Test
    func test_descriptor_when_inspected_then_orderby_enum_excludes_id_price_rating() {
        // Given
        let tool = ProductsListTool.make()

        // Then
        guard case .object(let schema) = tool.definition.parametersSchema,
              case .object(let properties) = schema["properties"],
              case .object(let orderby) = properties["orderby"],
              case .array(let values) = orderby["enum"] else {
            Issue.record("expected orderby enum")
            return
        }
        let strings = values.compactMap { value -> String? in
            if case .string(let s) = value { return s }
            return nil
        }
        #expect(Set(strings) == ["date", "title", "popularity"])
    }

    @Test
    func test_execute_when_tag_arg_provided_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"tag": 5}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("tag"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_execute_when_ids_is_empty_array_then_invalidToolCall_with_at_least_one_id_message_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"ids": []}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("at least one"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_execute_when_ids_combined_with_search_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"ids": [1, 2], "search": "scarf"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("ids cannot be combined"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_validateCombinations_when_invalid_status_then_fails() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"status": "trashed"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("trashed"))
        #expect(failed.reason.contains("not an allowed status"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_validateCombinations_when_invalid_stock_status_then_fails() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"stock_status": "lowstock"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("lowstock"))
        #expect(failed.reason.contains("not an allowed stock_status"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_list_when_parent_id_set_then_routes_to_variations_endpoint() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        _ = await tool.executor(#"{"parent_id": 42}"#, client)

        // Then
        #expect(await client.calls.first?.path == "wc/v3/products/42/variations")
    }

    @Test
    func test_list_when_ids_set_then_uses_include_filter() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        _ = await tool.executor(#"{"ids": [10, 11, 12]}"#, client)

        // Then
        #expect(await client.calls.first?.query["include"] == "10,11,12")
        #expect(await client.calls.first?.query["orderby"] == "include")
    }

    @Test
    func test_list_response_rows_carry_kind_discriminator() async throws {
        // Given
        let body = """
        [{"id": 101, "name": "Hoodie", "type": "simple"}]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let products) = fields["products"],
              case .object(let first) = products.first else {
            Issue.record("expected first product object")
            return
        }
        #expect(first["kind"] == .string("product"))
    }

    @Test
    func test_list_response_variations_include_parent_id_and_kind() async throws {
        // Given
        let body = """
        [
            {"id": 201, "parent_id": 99, "sku": "RED-S", "price": "19.00", "stock_status": "instock"},
            {"id": 202, "parent_id": 99, "sku": "RED-M", "price": "19.00", "stock_status": "outofstock"},
            {"id": 203, "parent_id": 99, "sku": "BLUE-L", "price": "21.00", "stock_status": "instock"}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"parent_id": 99}"#, client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let rows) = fields["products"] else {
            Issue.record("expected variation rows")
            return
        }
        #expect(rows.count == 3)
        for row in rows {
            guard case .object(let fields) = row else {
                Issue.record("expected variation row object")
                return
            }
            #expect(fields["kind"] == .string("variation"))
            #expect(fields["parent_id"] == .int(99))
        }
    }
}
