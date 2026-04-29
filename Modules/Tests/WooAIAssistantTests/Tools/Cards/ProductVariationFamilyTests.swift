import Foundation
import Testing
@testable import WooAIAssistant

struct ProductVariationFamilyTests {
    @Test
    func test_summarize_then_projects_only_summary_fields_including_parent_id() {
        // Given
        let entity: AnyCodableJSON = .object([
            "id": .int(822),
            "name": .string("Black"),
            "sku": .string("BNY-BLK"),
            "price": .string("74.99"),
            "stock_status": .string("instock"),
            "parent_id": .int(821),
            "description": .string("Long description here ..."),
            "image": .object([:])
        ])

        // When
        let summary = CardFamily.productVariation.summarize(entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object summary")
            return
        }
        #expect(fields["id"] == .int(822))
        #expect(fields["name"] == .string("Black"))
        #expect(fields["sku"] == .string("BNY-BLK"))
        #expect(fields["price"] == .string("74.99"))
        #expect(fields["stock_status"] == .string("instock"))
        #expect(fields["parent_id"] == .int(821))
        #expect(fields["description"] == nil)
        #expect(fields["image"] == nil)
    }

    @Test
    func test_fetchNested_when_response_returns_object_then_returns_entity() async {
        // Given
        let body = """
        {"id": 822, "name": "Black", "price": "74.99", "stock_status": "instock", "parent_id": 821}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))

        // When
        let outcomes = await CardFamily.productVariation.fetchNested(refs: [(id: 822, parentID: 821)], client: client)

        // Then
        guard case .found(let entity) = outcomes[822] else {
            Issue.record("expected found, got \(String(describing: outcomes[822]))")
            return
        }
        if case .object(let dict) = entity {
            #expect(dict["name"] == .string("Black"))
            #expect(dict["parent_id"] == .int(821))
        }
        let call = await client.calls.first
        #expect(call?.path == "wc/v3/products/821/variations/822")
    }

    @Test
    func test_fetchNested_when_remote_returns_404_then_rejects_as_notFound() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 404))

        // When
        let outcomes = await CardFamily.productVariation.fetchNested(refs: [(id: 9999, parentID: 821)], client: client)

        // Then
        guard case .rejected(let reason) = outcomes[9999] else {
            Issue.record("expected rejected outcome")
            return
        }
        #expect(reason == .notFound)
    }

    @Test
    func test_fetchNested_when_response_is_unparseable_then_rejects_as_internalError() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("not json"))

        // When
        let outcomes = await CardFamily.productVariation.fetchNested(refs: [(id: 822, parentID: 821)], client: client)

        // Then
        guard case .rejected(let reason) = outcomes[822] else {
            Issue.record("expected rejected outcome")
            return
        }
        #expect(reason == .internalError)
    }

    @Test
    func test_fetchNested_when_response_is_array_instead_of_object_then_rejects_as_internalError() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))

        // When
        let outcomes = await CardFamily.productVariation.fetchNested(refs: [(id: 822, parentID: 821)], client: client)

        // Then
        guard case .rejected(let reason) = outcomes[822] else {
            Issue.record("expected rejected outcome")
            return
        }
        #expect(reason == .internalError)
    }

    @Test
    func test_fetchNested_when_status_trash_then_rejects_as_staleReference() async {
        // Given
        let body = """
        {"id": 822, "status": "trash", "parent_id": 821}
        """
        let client = MockWCRESTClient(response: StubResponses.ok(body))

        // When
        let outcomes = await CardFamily.productVariation.fetchNested(refs: [(id: 822, parentID: 821)], client: client)

        // Then
        guard case .rejected(let reason) = outcomes[822] else {
            Issue.record("expected rejected outcome")
            return
        }
        #expect(reason == .staleReference)
    }
}
