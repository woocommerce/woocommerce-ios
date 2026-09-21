import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductsUpdateToolTests {
    @Test
    func test_productsUpdate_when_name_set_then_sends_minimal_body() async throws {
        // Given
        let body = """
        {"id": 12, "name": "Wool Sweater", "type": "simple", "status": "publish"}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 12, "name": "Wool Sweater"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        #expect(call.method == "PUT")
        #expect(call.path == "wc/v3/products/12")
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["name"] as? String == "Wool Sweater")
        #expect(parsed["regular_price"] == nil)
    }

    @Test
    func test_productsUpdate_when_field_outside_allowlist_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let arguments = #"""
        {"id": 12, "name": "X", "categories": [{"id": 99}], "tags": ["spring"]}
        """#
        let result = await tool.executor(arguments, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("categories"))
        #expect(failed.reason.contains("tags"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_productsUpdate_when_stock_quantity_set_then_request_also_carries_manage_stock_true() async throws {
        // Given
        let body = """
        {"id": 12, "stock_quantity": 5, "type": "simple"}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 12, "stock_quantity": 5}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let call = try #require(await client.calls.first)
        let parsed = try #require(call.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(parsed["stock_quantity"] as? Int == 5)
        #expect(parsed["manage_stock"] as? Bool == true)
    }

    @Test
    func test_productsUpdate_when_variable_product_and_regularPrice_then_returns_validationError_pointing_at_variations_tool() async throws {
        // Given
        let probe = """
        {"id": 12, "name": "Tee", "type": "variable"}
        """
        let client = MockWCRESTClient(responses: [
            StubResponses.ok(probe),
            StubResponses.ok(probe)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 12, "regular_price": "19.99"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("product_variations_update"))
        #expect(await client.calls.count == 1)
        #expect(await client.calls.first?.method == "GET")
    }

    @Test
    func test_productsUpdate_when_simple_product_and_regularPrice_then_dispatches_PUT() async throws {
        // Given
        let probe = """
        {"id": 12, "name": "Tee", "type": "simple"}
        """
        let putResponse = """
        {"id": 12, "name": "Tee", "regular_price": "19.99", "type": "simple"}
        """
        let client = MockWCRESTClient(responses: [
            StubResponses.ok(probe),
            StubResponses.ok(putResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 12, "regular_price": "19.99"}"#, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let methods = await client.calls.map { $0.method }
        #expect(methods == ["GET", "PUT"])
    }

    @Test
    func test_productsUpdate_when_only_id_provided_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 12}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_productsUpdate_when_408_after_upload_then_returns_outcomeUnknown() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 408))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"id": 12, "name": "X"}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
    }
}
