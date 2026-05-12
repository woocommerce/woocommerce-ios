import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductVariationsUpdateToolTests {
    @Test
    func test_productVariationsUpdate_when_regular_price_set_then_path_includes_both_ids() async throws {
        // Given
        let body = """
        {"id": 33, "regular_price": "29.99"}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductVariationsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 12, "id": 33, "regular_price": "29.99"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        #expect(call.method == "PUT")
        #expect(call.path == "wc/v3/products/12/variations/33")
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["regular_price"] as? String == "29.99")
    }

    @Test
    func test_productVariationsUpdate_when_success_then_card_family_is_productVariation() async throws {
        // Given
        let body = """
        {"id": 33, "regular_price": "29.99"}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductVariationsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 12, "id": 33, "regular_price": "29.99"}"#, client)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let cards = try #require(success.uiStructured?.cards)
        #expect(cards.allSatisfy { $0.family == .productVariation })
    }

    @Test
    func test_productVariationsUpdate_when_stock_quantity_set_then_request_carries_manage_stock_true() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok(#"{"id":33}"#))
        let tool = ProductVariationsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 12, "id": 33, "stock_quantity": 7}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["stock_quantity"] as? Int == 7)
        #expect(parsed["manage_stock"] as? Bool == true)
    }

    @Test
    func test_productVariationsUpdate_when_stock_status_outside_allowlist_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductVariationsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 1, "id": 2, "stock_status": "delayed"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_productVariationsUpdate_when_field_outside_allowlist_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductVariationsUpdateTool.make()

        // When
        let arguments = #"""
        {"product_id": 12, "id": 33, "regular_price": "1.00", "weight": "5", "dimensions": {"length": "1"}}
        """#
        let result = await tool.executor(arguments, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_variations_update_when_write_succeeds_then_summary_uses_variation_detail_projection_with_attributes_and_image() async throws {
        // Given
        let body = """
        {
            "id": 33, "regular_price": "29.99", "stock_status": "instock",
            "attributes": [{"id": 7, "name": "Color", "option": "Red"}],
            "image": {"id": 9, "src": "v.jpg"}
        }
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductVariationsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 12, "id": 33, "regular_price": "29.99"}"#, client)

        // Then
        guard case .success(let success) = result, case .object(let summary) = success.structured else {
            Issue.record("expected success object")
            return
        }
        guard case .array(let attrs) = summary["attributes"], case .object(let firstAttr) = attrs.first else {
            Issue.record("expected attributes")
            return
        }
        #expect(firstAttr["option"] == .string("Red"))
        guard case .object(let image) = summary["image"] else {
            Issue.record("expected image")
            return
        }
        #expect(image["src"] == .string("v.jpg"))
    }

    @Test
    func test_productVariationsUpdate_when_only_required_ids_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductVariationsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 1, "id": 2}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_productVariationsUpdate_when_408_after_upload_then_returns_outcomeUnknown() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 408))
        let tool = ProductVariationsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"product_id": 1, "id": 2, "regular_price": "1.00"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
    }
}
