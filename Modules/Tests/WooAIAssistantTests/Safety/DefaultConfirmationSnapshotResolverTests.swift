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
    func test_resolve_when_products_update_then_hits_products_include_endpoint_with_bulk_entries() async throws {
        // Given
        let body = """
        [{"id":7,"name":"Cap"},{"id":8,"name":"Hat"}]
        """
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products", body: body)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"id":7,"sale_price":"5"},{"id":8,"sale_price":"5"}]}"#
        )

        // Then
        let calls = await client.recordedCalls
        #expect(calls.map(\.path) == ["wc/v3/products"])
        let entries = try #require(snapshot?.bulkEntries)
        #expect(entries.map(\.id) == [7, 8])
        #expect(entries.compactMap(\.displayName) == ["Cap", "Hat"])
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
    func test_resolve_when_response_body_is_malformed_then_returns_id_only_entries() async {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products", body: "not json")
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(toolName: ProductsUpdateTool.name,
                                              arguments: #"{"updates":[{"id":7,"sale_price":"5"}]}"#)

        // Then
        #expect(snapshot?.bulkEntries.map(\.id) == [7])
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
