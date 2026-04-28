import Foundation
import Testing
@testable import WooAIAssistant

struct CardReferenceResolverTests {
    @Test
    func test_resolve_when_three_mixed_family_references_then_all_resolved_in_input_order() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[{\"id\": 3551, \"status\": \"processing\", \"total\": \"120.00\"}]"))
        client.stub(path: "wc/v3/products",
                    response: StubResponses.ok("[{\"id\": 42, \"name\": \"Beanie\", \"price\": \"19.99\", \"stock_status\": \"instock\"}]"))
        client.stub(path: "wc/v3/customers",
                    response: StubResponses.ok("[{\"id\": 7, \"first_name\": \"Jane\", \"email\": \"jane@example.com\"}]"))
        let resolver = CardReferenceResolver(client: client)
        let references: [CardReference] = [
            CardReference(family: .order, id: "3551"),
            CardReference(family: .product, id: "42"),
            CardReference(family: .customer, id: "7")
        ]

        // When
        let result = await resolver.resolve(references)

        // Then
        #expect(result.resolutions.count == 3)
        #expect(isResolved(result.resolutions[0], family: .order, id: "3551"))
        #expect(isResolved(result.resolutions[1], family: .product, id: "42"))
        #expect(isResolved(result.resolutions[2], family: .customer, id: "7"))
    }

    @Test
    func test_resolve_when_multiple_orders_then_uses_single_batched_fetch() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("""
                    [{"id": 1, "status": "processing", "total": "10.00"},
                     {"id": 2, "status": "processing", "total": "20.00"},
                     {"id": 3, "status": "processing", "total": "30.00"}]
                    """))
        let resolver = CardReferenceResolver(client: client)
        let references = [1, 2, 3].map { CardReference(family: .order, id: String($0)) }

        // When
        let result = await resolver.resolve(references)

        // Then
        #expect(result.resolutions.count == 3)
        #expect(client.calls.filter { $0 == "wc/v3/orders" }.count == 1)
    }

    @Test
    func test_resolve_when_eleven_references_then_first_ten_processed_and_overflow_rejected_as_malformed() async {
        // Given
        let client = StubbedWCRESTClient()
        let rows = (1...10).map { "{\"id\": \($0), \"status\": \"processing\", \"total\": \"10.00\"}" }.joined(separator: ",")
        client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[\(rows)]"))
        let resolver = CardReferenceResolver(client: client)
        let references = (1...11).map { CardReference(family: .order, id: String($0)) }

        // When
        let result = await resolver.resolve(references)

        // Then
        #expect(result.resolutions.count == 11)
        for index in 0..<10 {
            #expect(isResolved(result.resolutions[index], family: .order, id: String(index + 1)),
                    "expected resolution \(index) to be resolved")
        }
        if case .rejected(_, _, let reason) = result.resolutions[10] {
            #expect(reason == .malformed)
        } else {
            Issue.record("expected overflow to be rejected.malformed")
        }
    }

    @Test
    func test_resolve_when_same_reference_twice_then_first_resolves_and_second_rejected_as_duplicate() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[{\"id\": 3551, \"status\": \"processing\", \"total\": \"120.00\"}]"))
        let resolver = CardReferenceResolver(client: client)
        let references: [CardReference] = [
            CardReference(family: .order, id: "3551"),
            CardReference(family: .order, id: "3551")
        ]

        // When
        let result = await resolver.resolve(references)

        // Then
        #expect(isResolved(result.resolutions[0], family: .order, id: "3551"))
        if case .rejected(let family, let id, let reason) = result.resolutions[1] {
            #expect(family == .order)
            #expect(id == "3551")
            #expect(reason == .duplicate)
        } else {
            Issue.record("expected second to be rejected.duplicate")
        }
        #expect(client.calls.filter { $0 == "wc/v3/orders" }.count == 1)
    }

    @Test
    func test_resolve_when_id_is_zero_then_rejects_as_malformed() async {
        // Given
        let client = StubbedWCRESTClient()
        let resolver = CardReferenceResolver(client: client)

        // When
        let result = await resolver.resolve([CardReference(family: .order, id: "0")])

        // Then
        if case .rejected(_, _, let reason) = result.resolutions[0] {
            #expect(reason == .malformed)
        } else {
            Issue.record("expected rejected.malformed")
        }
        #expect(client.calls.isEmpty)
    }

    @Test
    func test_resolve_when_id_is_non_numeric_then_rejects_as_malformed() async {
        // Given
        let client = StubbedWCRESTClient()
        let resolver = CardReferenceResolver(client: client)

        // When
        let result = await resolver.resolve([CardReference(family: .order, id: "abc")])

        // Then
        if case .rejected(_, _, let reason) = result.resolutions[0] {
            #expect(reason == .malformed)
        } else {
            Issue.record("expected rejected.malformed")
        }
        #expect(client.calls.isEmpty)
    }

    @Test
    func test_resolve_when_family_missing_from_registry_then_rejects_as_unsupportedFamily() async {
        // Given
        let client = StubbedWCRESTClient()
        let registry = CardFamilyRegistry([.order])
        let resolver = CardReferenceResolver(registry: registry, client: client)

        // When
        let result = await resolver.resolve([CardReference(family: .product, id: "42")])

        // Then
        if case .rejected(_, _, let reason) = result.resolutions[0] {
            #expect(reason == .unsupportedFamily)
        } else {
            Issue.record("expected rejected.unsupportedFamily")
        }
    }

    @Test
    func test_resolve_when_id_missing_from_response_then_rejects_as_notFound() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders", response: StubResponses.ok("[]"))
        let resolver = CardReferenceResolver(client: client)

        // When
        let result = await resolver.resolve([CardReference(family: .order, id: "9999")])

        // Then
        if case .rejected(_, _, let reason) = result.resolutions[0] {
            #expect(reason == .notFound)
        } else {
            Issue.record("expected rejected.notFound")
        }
    }

    @Test
    func test_resolve_when_remote_returns_403_then_rejects_all_in_family_as_notPermitted() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/products", response: StubResponses.failure(statusCode: 403))
        let resolver = CardReferenceResolver(client: client)
        let references = [
            CardReference(family: .product, id: "1"),
            CardReference(family: .product, id: "2")
        ]

        // When
        let result = await resolver.resolve(references)

        // Then
        for index in 0..<2 {
            if case .rejected(_, _, let reason) = result.resolutions[index] {
                #expect(reason == .notPermitted)
            } else {
                Issue.record("expected rejected.notPermitted at slot \(index)")
            }
        }
    }

    @Test
    func test_resolve_when_entity_status_trash_then_rejects_as_staleReference() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[{\"id\": 3551, \"status\": \"trash\"}]"))
        let resolver = CardReferenceResolver(client: client)

        // When
        let result = await resolver.resolve([CardReference(family: .order, id: "3551")])

        // Then
        if case .rejected(_, _, let reason) = result.resolutions[0] {
            #expect(reason == .staleReference)
        } else {
            Issue.record("expected rejected.staleReference")
        }
    }

    @Test
    func test_resolve_when_remote_returns_410_then_rejects_as_staleReference() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders", response: StubResponses.failure(statusCode: 410))
        let resolver = CardReferenceResolver(client: client)

        // When
        let result = await resolver.resolve([CardReference(family: .order, id: "3551")])

        // Then
        if case .rejected(_, _, let reason) = result.resolutions[0] {
            #expect(reason == .staleReference)
        } else {
            Issue.record("expected rejected.staleReference")
        }
    }

    @Test
    func test_resolve_when_remote_returns_500_then_rejects_as_fetchFailed() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders", response: StubResponses.failure(statusCode: 500))
        let resolver = CardReferenceResolver(client: client)

        // When
        let result = await resolver.resolve([CardReference(family: .order, id: "1")])

        // Then
        if case .rejected(_, _, let reason) = result.resolutions[0] {
            #expect(reason == .fetchFailed)
        } else {
            Issue.record("expected rejected.fetchFailed")
        }
    }

    @Test
    func test_resolve_when_response_is_unparseable_then_rejects_as_internalError() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders", response: StubResponses.ok("not json at all"))
        let resolver = CardReferenceResolver(client: client)

        // When
        let result = await resolver.resolve([CardReference(family: .order, id: "1")])

        // Then
        if case .rejected(_, _, let reason) = result.resolutions[0] {
            #expect(reason == .internalError)
        } else {
            Issue.record("expected rejected.internalError")
        }
    }

    @Test
    func test_resolve_when_mixed_resolved_and_rejected_then_preserves_input_order() async {
        // Given
        let client = StubbedWCRESTClient()
        client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[{\"id\": 3551, \"status\": \"processing\", \"total\": \"120.00\"}]"))
        let resolver = CardReferenceResolver(client: client)
        let references: [CardReference] = [
            CardReference(family: .order, id: "3551"),
            CardReference(family: .order, id: "9999"),
            CardReference(family: .order, id: "3551")
        ]

        // When
        let result = await resolver.resolve(references)

        // Then
        #expect(isResolved(result.resolutions[0], family: .order, id: "3551"))
        if case .rejected(_, _, let reason) = result.resolutions[1] {
            #expect(reason == .notFound)
        } else {
            Issue.record("expected slot 1 to be rejected.notFound")
        }
        if case .rejected(_, _, let reason) = result.resolutions[2] {
            #expect(reason == .duplicate)
        } else {
            Issue.record("expected slot 2 to be rejected.duplicate")
        }
    }

    private func isResolved(_ resolution: Resolution, family: CardFamilyID, id: String) -> Bool {
        if case .resolved(let resolvedFamily, let resolvedID, _, _) = resolution {
            return resolvedFamily == family && resolvedID == id
        }
        return false
    }
}
