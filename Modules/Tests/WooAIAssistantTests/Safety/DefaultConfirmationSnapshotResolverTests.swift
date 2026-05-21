import Foundation
import Testing
import enum Networking.ProductStatus
import enum Networking.ProductStockStatus
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
            arguments: #"{"updates":[{"target":{"kind":"product","id":7},"sale_price":"5"},{"target":{"kind":"product","id":8},"sale_price":"5"}]}"#
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
                                              arguments: #"{"updates":[{"target":{"kind":"product","id":7},"sale_price":"5"}]}"#)

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
    func test_resolveProductsUpdate_when_single_product_then_snapshot_carries_prior_field_values() async throws {
        // Given
        let body = """
        [{"id":7,"name":"Cap","regular_price":"1000","sale_price":"500","stock_quantity":12,\
        "status":"publish","stock_status":"instock","sku":"CAP-1"}]
        """
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products", body: body)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":7},"sale_price":"15"}]}"#
        )

        // Then
        let values = try #require(snapshot?.currentValues)
        #expect(values["name"] == .raw("Cap"))
        #expect(values["regular_price"] == .raw("1000"))
        #expect(values["sale_price"] == .raw("500"))
        #expect(values["stock_quantity"] == .raw("12"))
        #expect(values["status"] == .raw(ProductStatus(rawValue: "publish").description))
        #expect(values["stock_status"] == .raw(ProductStockStatus(rawValue: "instock").description))
        #expect(values["sku"] == .raw("CAP-1"))
        #expect(snapshot?.displayName == "Cap")
        #expect(snapshot?.bulkEntries.map(\.id) == [7])
    }

    @Test
    func test_resolveProductsUpdate_when_bulk_then_snapshot_currentValues_stays_empty() async throws {
        // Given
        let body = """
        [{"id":7,"name":"Cap","regular_price":"1000","sale_price":"500"},\
        {"id":8,"name":"Hat","regular_price":"800","sale_price":"400"}]
        """
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products", body: body)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":7},"sale_price":"5"},{"target":{"kind":"product","id":8},"sale_price":"5"}]}"#
        )

        // Then
        #expect(snapshot?.currentValues.isEmpty == true)
        #expect(snapshot?.bulkEntries.map(\.id) == [7, 8])
    }

    @Test
    func test_resolveProductsUpdate_when_no_scoped_fanout_then_no_variation_endpoint_hit() async {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":50,"name":"Tee"}]"#)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        _ = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"product","id":50},"name":"Renamed"}]}
            """#
        )

        // Then
        let calls = await client.recordedCalls
        #expect(!calls.contains(where: { $0.path == "wc/v3/products/50/variations" }))
    }

    @Test
    func test_resolveProductsUpdate_when_variation_targets_then_snapshot_includes_variation_names_by_parent() async throws {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":41,"name":"Hoodie"}]"#)
        let variationsBody = """
        [{"id":58,"name":"Hoodie - Red","attributes":[{"id":1,"name":"Color","option":"Red"}]},\
        {"id":59,"name":"Hoodie - Blue","attributes":[{"id":1,"name":"Color","option":"Blue"}]}]
        """
        await client.setResponse(forPath: "wc/v3/products/41/variations", body: variationsBody)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"variation","id":58,"parent_id":41},"sale_price":"5"},
              {"target":{"kind":"variation","id":59,"parent_id":41},"sale_price":"5"}
            ]}
            """#
        )

        // Then
        let entries = try #require(snapshot?.bulkEntries)
        #expect(entries.map(\.id) == [58, 59])
        #expect(entries.compactMap(\.displayName) == ["Hoodie - Red", "Hoodie - Blue"])
    }

    @Test
    func test_resolveProductsUpdate_when_variation_name_is_bare_attributes_then_label_prepends_parent() async throws {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":820,"name":"Heavyweight Wool Cardigan"}]"#)
        let variationsBody = """
        [{"id":840,"name":"L, Gray","attributes":[{"id":1,"name":"Size","option":"L"},\
        {"id":2,"name":"Color","option":"Gray"}]}]
        """
        await client.setResponse(forPath: "wc/v3/products/820/variations", body: variationsBody)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"variation","id":840,"parent_id":820},"sale_price":"5"}]}
            """#
        )

        // Then
        let entries = try #require(snapshot?.bulkEntries)
        #expect(entries.compactMap(\.displayName) == ["Heavyweight Wool Cardigan - L, Gray"])
    }

    @Test
    func test_resolveProductsUpdate_when_all_product_ids_missing_then_returns_refusal_with_all_listed() async throws {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products", body: "[]")
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":3859},"regular_price":"25"},
              {"target":{"kind":"product","id":3860},"regular_price":"25"},
              {"target":{"kind":"product","id":3861},"regular_price":"25"}
            ]}
            """#
        )

        // Then
        let reason = try #require(snapshot?.refusalReason)
        #expect(reason.contains("3859"))
        #expect(reason.contains("3860"))
        #expect(reason.contains("3861"))
        #expect(snapshot?.bulkEntries.isEmpty == true)
    }

    @Test
    func test_resolveProductsUpdate_when_one_of_three_ids_missing_then_returns_refusal_naming_just_that_id() async throws {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":3859,"name":"A"},{"id":3861,"name":"C"}]"#)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[
              {"target":{"kind":"product","id":3859},"regular_price":"25"},
              {"target":{"kind":"product","id":3860},"regular_price":"25"},
              {"target":{"kind":"product","id":3861},"regular_price":"25"}
            ]}
            """#
        )

        // Then
        let reason = try #require(snapshot?.refusalReason)
        #expect(reason.contains("3860"))
        #expect(!reason.contains("3859"))
        #expect(!reason.contains("3861"))
    }

    @Test
    func test_resolveProductsUpdate_when_variation_target_parent_missing_then_returns_refusal() async throws {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products", body: "[]")
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"variation","id":99,"parent_id":41},"sale_price":"5"}]}
            """#
        )

        // Then
        let reason = try #require(snapshot?.refusalReason)
        #expect(reason.contains("41"))
    }

    @Test
    func test_resolveProductsUpdate_when_variation_target_variation_missing_under_parent_then_returns_refusal() async throws {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":41,"name":"Hoodie"}]"#)
        // Parent fetch succeeds; per-parent variations fetch returns a different variation id so 99 is missing.
        await client.setResponse(forPath: "wc/v3/products/41/variations",
                                 body: #"[{"id":58,"name":"Hoodie - Red"}]"#)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"variation","id":99,"parent_id":41},"sale_price":"5"}]}
            """#
        )

        // Then
        let reason = try #require(snapshot?.refusalReason)
        #expect(reason.contains("99"))
        #expect(reason.contains("41"))
    }

    @Test
    func test_resolveProductsUpdate_when_all_ids_present_then_no_refusal() async {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":7,"name":"Cap"},{"id":8,"name":"Hat"}]"#)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"product","id":7},"sale_price":"5"},{"target":{"kind":"product","id":8},"sale_price":"5"}]}"#
        )

        // Then
        #expect(snapshot?.refusalReason == nil)
    }

    @Test
    func test_resolveProductsUpdate_when_variation_endpoint_fails_then_no_refusal_for_missing_variations() async {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":41,"name":"Hoodie"}]"#)
        await client.setResponse(forPath: "wc/v3/products/41/variations",
                                 body: "[]",
                                 statusCode: 500)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"{"updates":[{"target":{"kind":"variation","id":99,"parent_id":41},"sale_price":"5"}]}"#
        )

        // Then
        #expect(snapshot?.refusalReason == nil)
    }

    @Test
    func test_resolveProductsUpdate_when_scoped_fanout_then_snapshot_carries_variation_count_from_rows() async throws {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":50,"name":"Tee"}]"#)
        let variationsBody = """
        [{"id":101,"name":"Tee - S"},{"id":102,"name":"Tee - M"},{"id":103,"name":"Tee - L"}]
        """
        await client.setResponse(forPath: "wc/v3/products/50/variations", body: variationsBody)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"product","id":50,"scope":"all_variations"},"percent_discount":10}]}
            """#
        )

        // Then
        let counts = try #require(snapshot?.parentVariationCounts)
        #expect(counts[50] == 3)
        let calls = await client.recordedCalls
        #expect(calls.contains(where: { $0.path == "wc/v3/products/50/variations" }))
    }

    @Test
    func test_resolveProductsUpdate_when_scoped_fanout_and_endpoint_fails_then_count_is_absent() async throws {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":50,"name":"Tee"}]"#)
        await client.setResponse(forPath: "wc/v3/products/50/variations",
                                 body: "[]",
                                 statusCode: 500)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"product","id":50,"scope":"all_variations"},"percent_discount":10}]}
            """#
        )

        // Then
        #expect(snapshot?.parentVariationCounts[50] == nil)
    }

    @Test
    func test_resolveProductsUpdate_when_variable_parent_with_scope_then_snapshot_includes_variation_names() async throws {
        // Given
        let client = StubRESTClient()
        await client.setResponse(forPath: "wc/v3/products",
                                 body: #"[{"id":50,"name":"Tee"}]"#)
        let variationsBody = """
        [{"id":101,"name":"Tee - Red, S","attributes":[{"id":1,"name":"Color","option":"Red"},\
        {"id":2,"name":"Size","option":"S"}]},\
        {"id":102,"name":"Tee - Red, M","attributes":[{"id":1,"name":"Color","option":"Red"},\
        {"id":2,"name":"Size","option":"M"}]},\
        {"id":103,"name":"Tee - Blue, S","attributes":[{"id":1,"name":"Color","option":"Blue"},\
        {"id":2,"name":"Size","option":"S"}]},\
        {"id":104,"name":"Tee - Blue, M","attributes":[{"id":1,"name":"Color","option":"Blue"},\
        {"id":2,"name":"Size","option":"M"}]}]
        """
        await client.setResponse(forPath: "wc/v3/products/50/variations", body: variationsBody)
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(
            toolName: ProductsUpdateTool.name,
            arguments: #"""
            {"updates":[{"target":{"kind":"product","id":50,"scope":"all_variations"},"percent_discount":10}]}
            """#
        )

        // Then
        let entries = try #require(snapshot?.bulkEntries)
        let parent = try #require(entries.first)
        #expect(parent.id == 50)
        #expect(parent.displayName == "Tee")
        let subLabels = parent.subEntries.compactMap(\.displayName)
        #expect(subLabels == ["Tee - Red, S", "Tee - Red, M", "Tee - Blue, S", "Tee - Blue, M"])
        #expect(snapshot?.parentVariationCounts[50] == 4)
    }

    @Test
    func test_resolve_when_unknown_tool_then_returns_nil() async {
        // Given
        let client = StubRESTClient()
        let resolver = DefaultConfirmationSnapshotResolver(client: client)

        // When
        let snapshot = await resolver.resolve(toolName: "future_unknown_tool",
                                              arguments: #"{"target":{"kind":"product","id":1}}"#)

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

    func setResponse(forPath path: String,
                     body: String,
                     statusCode: Int = 200,
                     headers: [String: String] = [:]) {
        responsesByPath[path] = WCRESTResponse(data: Data(body.utf8), statusCode: statusCode, headers: headers)
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
