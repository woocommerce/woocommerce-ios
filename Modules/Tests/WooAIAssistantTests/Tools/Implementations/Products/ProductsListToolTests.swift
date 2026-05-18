import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductsListToolTests {
    @Test
    func test_products_list_definition_documents_top_products_card_flow() {
        // Given
        let tool = ProductsListTool.make()

        // Then
        #expect(tool.definition.description.contains("orderby=popularity"))
        #expect(tool.definition.description.contains("latest/last single-product"))
        #expect(tool.definition.description.contains("per_page=1"))
        #expect(tool.definition.description.contains("pass returned ids to"))
        #expect(tool.definition.description.contains("Terse merchant phrases"))
        #expect(tool.definition.description.contains("never say no match was found unless the returned count is zero"))
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
    func test_products_list_summary_when_rows_present_then_products_array_carries_per_row_widened_fields() async throws {
        // Given
        let body = """
        [
            {
                "id": 101, "name": "Hoodie", "sku": "HOOD-1", "price": "49.00",
                "stock_status": "instock",
                "type": "simple", "status": "publish",
                "regular_price": "59.00", "sale_price": "49.00", "on_sale": true,
                "manage_stock": false,
                "categories": [{"id": 1, "name": "Apparel", "slug": "apparel"}],
                "images": [{"id": 1, "src": "https://example.com/h.jpg"}]
            }
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"per_page": 1}"#, client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let products) = fields["products"],
              case .object(let first) = products.first else {
            Issue.record("expected first product object")
            return
        }
        #expect(first["on_sale"] == .bool(true))
        #expect(first["manage_stock"] == .bool(false))
        guard case .object(let image) = first["image"] else {
            Issue.record("expected first product image object")
            return
        }
        #expect(image["src"] == .string("https://example.com/h.jpg"))
        guard case .array(let categories) = first["categories"], case .object(let firstCat) = categories.first else {
            Issue.record("expected categories array")
            return
        }
        #expect(firstCat["slug"] == .string("apparel"))
    }

    @Test
    func test_products_list_summary_when_row_has_image_array_then_first_image_is_projected_as_image_field() async throws {
        // Given
        let body = """
        [{"id": 1, "images": [{"id": 9, "src": "first.jpg"}, {"id": 10, "src": "second.jpg"}]}]
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
              case .object(let image) = first["image"] else {
            Issue.record("expected single image field")
            return
        }
        #expect(image["src"] == .string("first.jpg"))
        #expect(first["images"] == nil)
    }

    @Test
    func test_products_list_summary_when_can_load_more_provided_then_field_is_emitted_in_wrapper() async throws {
        // Given - 3 rows with per_page=3 means can_load_more=true (rows.count >= per_page)
        let body = """
        [{"id": 1}, {"id": 2}, {"id": 3}]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"per_page": 3}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success")
            return
        }
        #expect(fields["can_load_more"] == .bool(true))
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
    func test_descriptor_when_inspected_then_supported_query_args_match_android_parity() {
        // Given
        let tool = ProductsListTool.make()

        // Then
        guard case .object(let schema) = tool.definition.parametersSchema,
              case .object(let properties) = schema["properties"] else {
            Issue.record("expected schema properties")
            return
        }
        let keys = Set(properties.keys)
        #expect(keys == [
            "search", "status", "category", "sku", "include", "stock_status",
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
    func test_execute_when_include_is_empty_array_then_invalidToolCall_with_at_least_one_id_message_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"include": []}"#, client)

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
    func test_execute_when_include_has_more_than_100_ids_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()
        let ids = (1...101).map(String.init).joined(separator: ", ")

        // When
        let result = await tool.executor(#"{"include": [\#(ids)]}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_execute_when_include_combined_with_search_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"include": [1, 2], "search": "scarf"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("include cannot be combined"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_execute_when_search_combined_with_orderby_then_invalidToolCall_is_returned() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"search": "tee", "orderby": "popularity"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("orderby and order cannot be combined"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_execute_when_stock_status_is_outofstock_then_query_string_carries_stock_status_outofstock() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        _ = await tool.executor(#"{"stock_status": "outofstock"}"#, client)

        // Then
        #expect(await client.calls.first?.query["stock_status"] == "outofstock")
    }

    @Test
    func test_execute_when_orderby_is_popularity_then_query_string_carries_orderby_popularity() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        _ = await tool.executor(#"{"orderby": "popularity"}"#, client)

        // Then
        #expect(await client.calls.first?.query["orderby"] == "popularity")
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
    func test_validateCombinations_when_valid_status_then_passes() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"status": "draft"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success")
            return
        }
        #expect(await client.calls.first?.query["status"] == "draft")
    }

    @Test
    func test_validateCombinations_when_valid_stock_status_then_passes() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"stock_status": "onbackorder"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success")
            return
        }
        #expect(await client.calls.first?.query["stock_status"] == "onbackorder")
    }
}
