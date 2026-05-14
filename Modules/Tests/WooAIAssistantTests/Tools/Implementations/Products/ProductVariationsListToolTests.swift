import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductVariationsListToolTests {
    @Test
    func test_definition_limits_use_to_explicit_variation_level_questions() {
        // Given
        let tool = ProductVariationsListTool.make()

        // Then
        #expect(tool.definition.description.contains("explicitly"))
        #expect(tool.definition.description.contains("product-level inventory"))
        #expect(tool.definition.description.contains("separate WooCommerce concepts"))
    }

    @Test
    func test_definition_documents_optional_variation_id_for_single_fetch() {
        // Given
        let tool = ProductVariationsListTool.make()

        // Then
        #expect(tool.definition.description.contains("or fetch a single variation"))
        guard case .object(let schema) = tool.definition.parametersSchema,
              case .object(let properties) = schema["properties"],
              case .object(let variationID) = properties["variation_id"] else {
            Issue.record("expected variation_id property")
            return
        }
        #expect(variationID["type"] == .string("integer"))
    }

    @Test
    func test_product_variations_list_when_variation_id_set_then_fetches_single_variation_detail() async throws {
        // Given
        let body = """
        {"id": 1002, "status": "publish", "sku": "BNY-BLK", "price": "25.00",
         "regular_price": "25.00", "stock_status": "outofstock", "parent_id": 555,
         "attributes": [{"id": 7, "name": "Color", "option": "Black"}]}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductVariationsListTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 555, "variation_id": 1002}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        #expect(success.uiStructured == nil)
        #expect(await client.calls.first?.path == "wc/v3/products/555/variations/1002")
        guard case .object(let fields) = success.structured else {
            Issue.record("expected object structured")
            return
        }
        #expect(fields["id"] == .int(1002))
        #expect(fields["stock_status"] == .string("outofstock"))
        // Detail summary mirrors parent_id into product_id and is not a list wrapper.
        #expect(fields["product_id"] == .int(555))
        #expect(fields["variations"] == nil)
    }

    @Test
    func test_product_variations_list_when_variation_id_set_and_remote_404_then_returns_failed() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 404))
        let tool = ProductVariationsListTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 555, "variation_id": 9999}"#, client)

        // Then
        guard case .failed = result else {
            Issue.record("expected failed")
            return
        }
        #expect(await client.calls.first?.path == "wc/v3/products/555/variations/9999")
    }

    @Test
    func test_product_variations_list_when_response_is_array_then_summary_carries_parent_id_and_ids() async throws {
        // Given
        let body = """
        [
            {"id": 1001, "stock_status": "instock", "price": "20.00"},
            {"id": 1002, "stock_status": "outofstock", "price": "25.00"}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductVariationsListTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 555}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success")
            return
        }
        #expect(success.uiStructured == nil)
        #expect(await client.calls.first?.path == "wc/v3/products/555/variations")
        if case .object(let fields) = success.structured {
            #expect(fields["product_id"] == .int(555))
            #expect(fields["count"] == .int(2))
            #expect(fields["ids"] == .array([.int(1001), .int(1002)]))
            #expect(fields["stock_status_counts"] == .object([
                "instock": .int(1),
                "outofstock": .int(1)
            ]))
        } else {
            Issue.record("expected object structured")
        }
    }

    @Test
    func test_product_variations_list_when_product_id_missing_then_returns_failed_invalid_tool_call() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductVariationsListTool.make()

        // When
        let result = await tool.executor("{}", client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_product_variations_list_when_per_page_above_50_then_query_clamps_to_50() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductVariationsListTool.make()

        // When
        _ = await tool.executor(#"{"product_id": 555, "per_page": 250}"#, client)

        // Then
        #expect(await client.calls.first?.query["per_page"] == "50")
    }

    @Test
    func test_variations_list_summary_when_rows_present_then_wrapper_uses_variations_key_with_widened_per_row_shape() async throws {
        // Given
        let body = """
        [
            {
                "id": 1001, "stock_status": "instock", "price": "20.00",
                "attributes": [{"id": 7, "name": "Color", "option": "Red"}],
                "image": {"id": 9, "src": "v.jpg"}
            }
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductVariationsListTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 555}"#, client)

        // Then
        guard case .success(let success) = result,
              case .object(let fields) = success.structured,
              case .array(let variations) = fields["variations"],
              case .object(let first) = variations.first else {
            Issue.record("expected variations array")
            return
        }
        #expect(fields["rows"] == nil)
        guard case .array(let attrs) = first["attributes"], case .object(let firstAttr) = attrs.first else {
            Issue.record("expected attributes on first variation")
            return
        }
        #expect(firstAttr["option"] == .string("Red"))
        guard case .object(let image) = first["image"] else {
            Issue.record("expected image")
            return
        }
        #expect(image["src"] == .string("v.jpg"))
    }

    @Test
    func test_variations_list_summary_when_per_row_price_present_then_price_range_uses_widened_rows() async throws {
        // Given
        let body = """
        [
            {"id": 1, "price": "10.00", "stock_status": "instock"},
            {"id": 2, "price": "30.00", "stock_status": "instock"}
        ]
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductVariationsListTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 555}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let fields) = success.structured else {
            Issue.record("expected success")
            return
        }
        #expect(fields["price_range"] == .object([
            "min": .string("10"),
            "max": .string("30")
        ]))
    }
}
