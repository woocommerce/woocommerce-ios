import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct DefaultConfirmationSnapshotResolverTests {

    @Test
    func test_resolve_when_orders_update_then_hits_orders_endpoint_and_strips_status_prefix() async {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/orders/42",
                                 body: #"{"id":42,"status":"wc-processing"}"#)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(toolName: OrdersUpdateTool.name,
                                              arguments: #"{"id":42}"#)

        // Then
        let calls = await client.recordedCalls
        #expect(calls.map(\.path) == ["wc/v3/orders/42"])
        #expect(snapshot?.currentValues["status"] == .raw("processing"))
    }

    @Test
    func test_resolve_when_products_update_then_hits_products_endpoint_with_typed_values() async {
        // Given
        let body = """
        {"id":7,"name":"Cap","regular_price":"24.99","sale_price":"19.99",\
        "stock_quantity":12.0,"status":"publish"}
        """
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products/7", body: body)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(toolName: ProductsUpdateTool.name,
                                              arguments: #"{"id":7}"#)

        // Then
        #expect(snapshot?.currentValues["name"] == .raw("Cap"))
        #expect(snapshot?.currentValues["regular_price"] == .raw("24.99"))
        #expect(snapshot?.currentValues["sale_price"] == .raw("19.99"))
        #expect(snapshot?.currentValues["stock_quantity"] == .raw("12"))
        #expect(snapshot?.currentValues["status"] == .raw("publish"))
    }

    @Test
    func test_resolve_when_product_variation_update_then_hits_variation_endpoint() async {
        // Given
        let body = """
        {"id":15,"regular_price":"19.99","sale_price":"","stock_quantity":2.5,\
        "stock_status":"instock","sku":"CAP-RED","status":"publish"}
        """
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products/7/variations/15", body: body)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(toolName: ProductVariationsUpdateTool.name,
                                              arguments: #"{"product_id":7,"id":15}"#)

        // Then
        let calls = await client.recordedCalls
        #expect(calls.map(\.path) == ["wc/v3/products/7/variations/15"])
        #expect(snapshot?.currentValues["regular_price"] == .raw("19.99"))
        #expect(snapshot?.currentValues["sale_price"] == .raw(""))
        #expect(snapshot?.currentValues["stock_quantity"] == .raw("2.5"))
        #expect(snapshot?.currentValues["stock_status"] == .raw("instock"))
        #expect(snapshot?.currentValues["sku"] == .raw("CAP-RED"))
        #expect(snapshot?.currentValues["status"] == .raw("publish"))
    }

    @Test
    func test_resolve_when_endpoint_returns_404_then_returns_nil() async {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/orders/99", body: "{}", statusCode: 404)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(toolName: OrdersUpdateTool.name,
                                              arguments: #"{"id":99}"#)

        // Then
        #expect(snapshot == nil)
    }

    @Test
    func test_resolve_when_response_body_is_malformed_then_returns_nil() async {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products/7", body: "not json")
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(toolName: ProductsUpdateTool.name,
                                              arguments: #"{"id":7}"#)

        // Then
        #expect(snapshot == nil)
    }

    @Test
    func test_resolve_when_arguments_missing_id_then_returns_nil_without_calling_client() async {
        // Given
        let client = StubRESTClient()
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(toolName: OrdersUpdateTool.name,
                                              arguments: "{}")

        // Then
        let calls = await client.recordedCalls
        #expect(calls.isEmpty)
        #expect(snapshot == nil)
    }

    @Test
    func test_resolve_when_unknown_tool_then_returns_nil() async {
        // Given
        let client = StubRESTClient()
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(toolName: "future_unknown_tool",
                                              arguments: #"{"id":1}"#)

        // Then
        let calls = await client.recordedCalls
        #expect(calls.isEmpty)
        #expect(snapshot == nil)
    }
}

private actor StubRESTClient: WCRESTClient {

    struct Recorded: Sendable, Equatable {
        let method: String
        let path: String
    }

    private(set) var recordedCalls: [Recorded] = []
    private var responsesByPath: [String: WCRESTResponse] = [:]

    func setResponse(forPath path: String, body: String, statusCode: Int = 200) {
        responsesByPath[path] = WCRESTResponse(data: Data(body.utf8), statusCode: statusCode)
    }

    nonisolated func request(method: String,
                             path: String,
                             query: [String: String]?,
                             body: Data?) async -> WCRESTResponse {
        await record(method: method, path: path)
    }

    private func record(method: String, path: String) -> WCRESTResponse {
        recordedCalls.append(.init(method: method, path: path))
        return responsesByPath[path] ?? WCRESTResponse(data: Data(), statusCode: 0)
    }
}
