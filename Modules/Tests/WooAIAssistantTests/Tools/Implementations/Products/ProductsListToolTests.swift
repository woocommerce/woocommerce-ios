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
            "search", "status", "category", "sku", "ids", "parent_id", "stock_status",
            "low_in_stock", "min_price", "max_price",
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

    @Test
    func test_list_when_low_in_stock_then_routes_to_wc_analytics_stock_report() async throws {
        // Given
        let reportBody = """
        [{"id": 21, "stock_quantity": 4}, {"id": 22, "stock_quantity": 2}]
        """
        let enrichBody = """
        [
            {"id": 21, "name": "Hoodie", "price": "49.00", "stock_status": "instock"},
            {"id": 22, "name": "Tee", "price": "19.00", "stock_status": "instock"}
        ]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(reportBody),
            "GET wc/v3/products": StubResponses.ok(enrichBody)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([.int(21), .int(22)]))
        let calls = await client.calls
        #expect(calls.count == 2)
        #expect(calls.first?.path == "wc-analytics/reports/stock")
        #expect(calls.first?.query["type"] == "lowstock")
        #expect(calls.last?.path == "wc/v3/products")
        #expect(calls.last?.query["include"] == "21,22")
        #expect(calls.last?.query["orderby"] == "include")
    }

    @Test
    func test_list_when_low_in_stock_then_falls_back_to_heuristic_when_stock_report_fails() async throws {
        // Given
        let heuristicBody = """
        [
            {"id": 1, "stock_quantity": 3},
            {"id": 2, "stock_quantity": 50},
            {"id": 3, "stock_quantity": 11}
        ]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.failure(statusCode: 404),
            "GET wc/v3/products": StubResponses.ok(heuristicBody)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([.int(1)]))
        let calls = await client.calls
        #expect(calls.first?.path == "wc-analytics/reports/stock")
        #expect(calls.dropFirst().allSatisfy { $0.path == "wc/v3/products" })
    }

    @Test
    func test_list_when_low_in_stock_empty_then_returns_empty_without_enrichment() async throws {
        // Given
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok("[]"),
            "GET wc/v3/products": StubResponses.ok("[\"should_not_be_used\"]")
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([]))
        let calls = await client.calls
        #expect(calls.count == 1)
        #expect(calls.first?.path == "wc-analytics/reports/stock")
    }

    @Test
    func test_list_when_low_in_stock_heuristic_full_page_then_can_load_more_is_true() async throws {
        // Given
        let fullPage = (1...20).map { #"{"id": \#($0), "stock_quantity": 50}"# }.joined(separator: ",")
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.failure(statusCode: 404),
            "GET wc/v3/products": StubResponses.ok("[\(fullPage)]")
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([]))
        #expect(fields["can_load_more"] == .bool(true))
    }

    @Test(arguments: [
        LowInStockFilterCase(
            label: "category",
            reportBody: """
            [{"id": 21, "stock_quantity": 1}, {"id": 22, "stock_quantity": 2}, {"id": 23, "stock_quantity": 3}]
            """,
            enrichBody: """
            [
                {"id": 21, "name": "Hoodie", "categories": [{"id": 7, "name": "Apparel", "slug": "apparel"}]},
                {"id": 22, "name": "Mug", "categories": [{"id": 9, "name": "Kitchen", "slug": "kitchen"}]},
                {"id": 23, "name": "Tee", "categories": [{"id": 7, "name": "Apparel", "slug": "apparel"}]}
            ]
            """,
            arguments: #"{"low_in_stock": true, "category": 7}"#,
            expectedIDs: [21, 23]
        ),
        LowInStockFilterCase(
            label: "sku",
            reportBody: #"[{"id": 21, "stock_quantity": 1}, {"id": 22, "stock_quantity": 2}]"#,
            enrichBody: """
            [
                {"id": 21, "name": "Hoodie", "sku": "HOOD-1"},
                {"id": 22, "name": "Tee", "sku": "TEE-1"}
            ]
            """,
            arguments: #"{"low_in_stock": true, "sku": "TEE-1"}"#,
            expectedIDs: [22]
        ),
        LowInStockFilterCase(
            label: "min_max_price",
            reportBody: """
            [{"id": 21, "stock_quantity": 1}, {"id": 22, "stock_quantity": 1}, {"id": 23, "stock_quantity": 1}]
            """,
            enrichBody: """
            [
                {"id": 21, "name": "Cheap", "price": "5.00"},
                {"id": 22, "name": "Mid", "price": "20.00"},
                {"id": 23, "name": "Pricey", "price": "150.00"}
            ]
            """,
            arguments: #"{"low_in_stock": true, "min_price": "10.00", "max_price": "100.00"}"#,
            expectedIDs: [22]
        ),
        LowInStockFilterCase(
            label: "search",
            reportBody: """
            [{"id": 21, "stock_quantity": 1}, {"id": 22, "stock_quantity": 1}, {"id": 23, "stock_quantity": 1}]
            """,
            enrichBody: """
            [
                {"id": 21, "name": "Hoodie", "sku": "HOOD-1"},
                {"id": 22, "name": "Tee Shirt", "sku": "TS-1"},
                {"id": 23, "name": "Mug", "sku": "MUG-TEE-1"}
            ]
            """,
            arguments: #"{"low_in_stock": true, "search": "tee"}"#,
            expectedIDs: [22, 23]
        ),
        LowInStockFilterCase(
            label: "ids",
            reportBody: """
            [{"id": 21, "stock_quantity": 1}, {"id": 22, "stock_quantity": 1}, {"id": 23, "stock_quantity": 1}]
            """,
            enrichBody: """
            [
                {"id": 21, "name": "A"},
                {"id": 22, "name": "B"},
                {"id": 23, "name": "C"}
            ]
            """,
            arguments: #"{"low_in_stock": true, "ids": [22, 23, 999]}"#,
            expectedIDs: [22, 23]
        )
    ])
    func test_list_when_low_in_stock_with_filter_then_filters_report_rows(testCase: LowInStockFilterCase) async throws {
        // Given
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(testCase.reportBody),
            "GET wc/v3/products": StubResponses.ok(testCase.enrichBody)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(testCase.arguments, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object for \(testCase.label)")
            return
        }
        let expected = AnyCodableJSON.array(testCase.expectedIDs.map { .int(Int64($0)) })
        #expect(fields["ids"] == expected)
    }

    @Test
    func test_list_when_low_in_stock_returns_variation_rows_then_enriches_via_parent_scoped_variations() async throws {
        // Given
        let reportBody = """
        [
            {"id": 11, "stock_quantity": 2},
            {"id": 12, "stock_quantity": 1},
            {"id": 501, "parent_id": 42, "stock_quantity": 1},
            {"id": 502, "parent_id": 42, "stock_quantity": 2}
        ]
        """
        let productsBody = """
        [
            {"id": 11, "name": "Hoodie", "type": "simple"},
            {"id": 12, "name": "Tee", "type": "simple"}
        ]
        """
        let variationsBody = """
        [
            {"id": 501, "parent_id": 42, "sku": "RED-S", "stock_status": "instock"},
            {"id": 502, "parent_id": 42, "sku": "RED-M", "stock_status": "outofstock"}
        ]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(reportBody),
            "GET wc/v3/products": StubResponses.ok(productsBody),
            "GET wc/v3/products/42/variations": StubResponses.ok(variationsBody)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([.int(11), .int(12), .int(501), .int(502)]))
        guard case .array(let products) = fields["products"] else {
            Issue.record("expected products array")
            return
        }
        let kinds = products.compactMap { row -> String? in
            guard case .object(let dict) = row, case .string(let kind) = dict["kind"] else { return nil }
            return kind
        }
        #expect(kinds == ["product", "product", "variation", "variation"])
        let calls = await client.calls
        #expect(calls.contains { $0.path == "wc/v3/products/42/variations" })
    }

    @Test
    func test_list_when_low_in_stock_variation_enrichment_fails_for_one_parent_then_keeps_rest() async throws {
        // Given
        let reportBody = """
        [
            {"id": 501, "parent_id": 42, "stock_quantity": 1},
            {"id": 601, "parent_id": 88, "stock_quantity": 1}
        ]
        """
        let okVariations = """
        [{"id": 501, "parent_id": 42, "sku": "RED-S", "stock_status": "instock"}]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(reportBody),
            "GET wc/v3/products/42/variations": StubResponses.ok(okVariations),
            "GET wc/v3/products/88/variations": StubResponses.failure(statusCode: 500)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([.int(501)]))
    }

    @Test
    func test_list_when_low_in_stock_combined_filters_apply_to_both_products_and_variations() async throws {
        // Given
        let reportBody = """
        [
            {"id": 11, "stock_quantity": 1},
            {"id": 12, "stock_quantity": 1},
            {"id": 501, "parent_id": 42, "stock_quantity": 1},
            {"id": 502, "parent_id": 42, "stock_quantity": 1}
        ]
        """
        let productsBody = """
        [
            {"id": 11, "name": "Cheap Product", "price": "5.00"},
            {"id": 12, "name": "Pricey Product", "price": "55.00"}
        ]
        """
        let variationsBody = """
        [
            {"id": 501, "parent_id": 42, "price": "8.00"},
            {"id": 502, "parent_id": 42, "price": "60.00"}
        ]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(reportBody),
            "GET wc/v3/products": StubResponses.ok(productsBody),
            "GET wc/v3/products/42/variations": StubResponses.ok(variationsBody)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true, "min_price": "10.00"}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([.int(12), .int(502)]))
    }

    @Test
    func test_list_when_max_price_set_then_passes_to_rest() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        _ = await tool.executor(#"{"max_price": "49.99"}"#, client)

        // Then
        #expect(await client.calls.first?.query["max_price"] == "49.99")
    }

    @Test
    func test_list_when_min_price_set_then_passes_to_rest() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsListTool.make()

        // When
        _ = await tool.executor(#"{"min_price": "10.00"}"#, client)

        // Then
        #expect(await client.calls.first?.query["min_price"] == "10.00")
    }

    @Test
    func test_list_when_low_in_stock_product_enrichment_fails_then_returns_toolFailed() async {
        // Given
        let reportBody = """
        [{"id": 21, "stock_quantity": 4}, {"id": 22, "stock_quantity": 2}]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(reportBody),
            "GET wc/v3/products": StubResponses.failure(statusCode: 503)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .toolFailed)
    }

    @Test
    func test_list_when_min_and_max_price_boundary_then_inclusive_at_bounds() async throws {
        // Given
        let reportBody = """
        [{"id": 21, "stock_quantity": 1}, {"id": 22, "stock_quantity": 1}, {"id": 23, "stock_quantity": 1}]
        """
        let enrichBody = """
        [
            {"id": 21, "name": "AtMin", "price": "10.00"},
            {"id": 22, "name": "Inside", "price": "55.00"},
            {"id": 23, "name": "AtMax", "price": "100.00"}
        ]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(reportBody),
            "GET wc/v3/products": StubResponses.ok(enrichBody)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true, "min_price": "10.00", "max_price": "100.00"}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([.int(21), .int(22), .int(23)]))
    }

    @Test
    func test_list_when_low_in_stock_price_filter_uses_regular_price_when_price_blank() async throws {
        // Given
        let reportBody = """
        [{"id": 21, "stock_quantity": 1}, {"id": 22, "stock_quantity": 1}]
        """
        let enrichBody = """
        [
            {"id": 21, "name": "BlankPrice", "price": "", "regular_price": "20.00"},
            {"id": 22, "name": "Cheap", "price": "", "regular_price": "5.00"}
        ]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(reportBody),
            "GET wc/v3/products": StubResponses.ok(enrichBody)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true, "min_price": "10.00"}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([.int(21)]))
    }

    @Test
    func test_list_when_low_in_stock_with_status_filter_then_filters_rows() async throws {
        // Given
        let reportBody = """
        [{"id": 21, "stock_quantity": 1}, {"id": 22, "stock_quantity": 1}]
        """
        let enrichBody = """
        [
            {"id": 21, "name": "Published", "status": "publish"},
            {"id": 22, "name": "Drafted", "status": "draft"}
        ]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(reportBody),
            "GET wc/v3/products": StubResponses.ok(enrichBody)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true, "status": "draft"}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([.int(22)]))
    }

    @Test
    func test_list_when_low_in_stock_with_stock_status_filter_then_filters_rows() async throws {
        // Given
        let reportBody = """
        [{"id": 21, "stock_quantity": 1}, {"id": 22, "stock_quantity": 1}]
        """
        let enrichBody = """
        [
            {"id": 21, "name": "InStock", "stock_status": "instock"},
            {"id": 22, "name": "OnBackorder", "stock_status": "onbackorder"}
        ]
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc-analytics/reports/stock": StubResponses.ok(reportBody),
            "GET wc/v3/products": StubResponses.ok(enrichBody)
        ])
        let tool = ProductsListTool.make()

        // When
        let result = await tool.executor(#"{"low_in_stock": true, "stock_status": "onbackorder"}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success object")
            return
        }
        #expect(fields["ids"] == .array([.int(22)]))
    }
}

struct LowInStockFilterCase: Sendable {
    let label: String
    let reportBody: String
    let enrichBody: String
    let arguments: String
    let expectedIDs: [Int]
}
