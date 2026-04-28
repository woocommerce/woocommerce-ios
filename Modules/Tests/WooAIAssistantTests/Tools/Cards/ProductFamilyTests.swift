import Foundation
import Testing
@testable import WooAIAssistant

struct ProductFamilyTests {
    @Test
    func test_summarize_then_projects_only_summary_fields() {
        // Given
        let entity: AnyCodableJSON = .object([
            "id": .int(42),
            "name": .string("Beanie"),
            "sku": .string("BNY-001"),
            "price": .string("19.99"),
            "stock_status": .string("instock"),
            "description": .string("Long description here ..."),
            "images": .array([])
        ])

        // When
        let summary = CardFamily.product.summarize(entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object summary")
            return
        }
        #expect(fields["id"] == .int(42))
        #expect(fields["name"] == .string("Beanie"))
        #expect(fields["sku"] == .string("BNY-001"))
        #expect(fields["price"] == .string("19.99"))
        #expect(fields["stock_status"] == .string("instock"))
        #expect(fields["description"] == nil)
        #expect(fields["images"] == nil)
    }

    @Test
    func test_fetch_when_response_ok_then_returns_pruned_entity() async {
        // Given
        let body = """
        {"id": 42, "name": "Beanie", "_links": {}, "meta_data": []}
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))

        // When
        let outcome = await CardFamily.product.fetch(id: 42, client: client)

        // Then
        guard case .found(let entity) = outcome else {
            Issue.record("expected found, got \(outcome)")
            return
        }
        if case .object(let dict) = entity {
            #expect(dict["_links"] == nil)
            #expect(dict["meta_data"] == nil)
            #expect(dict["name"] == .string("Beanie"))
        }
        #expect(client.calls.first?.path == "wc/v3/products/42")
    }

    @Test
    func test_fetch_when_status_is_trash_then_returns_stale_reference() async {
        // Given
        let body = """
        {"id": 42, "status": "trash"}
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))

        // When
        let outcome = await CardFamily.product.fetch(id: 42, client: client)

        // Then
        if case .rejected(let reason) = outcome {
            #expect(reason == .staleReference)
        } else {
            Issue.record("expected rejected, got \(outcome)")
        }
    }

    @Test
    func test_fetch_when_response_is_403_then_returns_not_permitted() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.failure(statusCode: 403))

        // When
        let outcome = await CardFamily.product.fetch(id: 1, client: client)

        // Then
        if case .rejected(let reason) = outcome {
            #expect(reason == .notPermitted)
        } else {
            Issue.record("expected rejected, got \(outcome)")
        }
    }
}
