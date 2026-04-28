import Foundation
import Testing
@testable import WooAIAssistant

struct CustomerFamilyTests {
    @Test
    func test_summarize_then_projects_only_summary_fields() {
        // Given
        let entity: AnyCodableJSON = .object([
            "id": .int(7),
            "first_name": .string("Jane"),
            "last_name": .string("Doe"),
            "email": .string("jane@example.com"),
            "orders_count": .int(12),
            "total_spent": .string("3000.00"),
            "billing": .object([:])
        ])

        // When
        let summary = CardFamily.customer.summarize(entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object summary")
            return
        }
        #expect(fields["id"] == .int(7))
        #expect(fields["first_name"] == .string("Jane"))
        #expect(fields["email"] == .string("jane@example.com"))
        #expect(fields["orders_count"] == .int(12))
        #expect(fields["total_spent"] == nil)
        #expect(fields["billing"] == nil)
    }

    @Test
    func test_fetch_when_include_returns_one_row_then_returns_entity() async {
        // Given
        let body = """
        [{"id": 7, "first_name": "Jane", "_links": {}}]
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))

        // When
        let outcomes = await CardFamily.customer.fetch(ids: [7], client: client)

        // Then
        guard case .found(let entity) = outcomes[7] else {
            Issue.record("expected found, got \(String(describing: outcomes[7]))")
            return
        }
        if case .object(let dict) = entity {
            #expect(dict["first_name"] == .string("Jane"))
            #expect(dict["_links"] == nil)
        }
        let call = client.calls.first
        #expect(call?.path == "wc/v3/customers")
        #expect(call?.query["include"] == "7")
    }

    @Test
    func test_fetch_when_multiple_ids_then_uses_comma_joined_include() async {
        // Given
        let body = """
        [{"id": 7, "first_name": "Jane"}, {"id": 8, "first_name": "John"}]
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))

        // When
        let outcomes = await CardFamily.customer.fetch(ids: [7, 8], client: client)

        // Then
        guard case .found = outcomes[7], case .found = outcomes[8] else {
            Issue.record("expected both ids resolved")
            return
        }
        let call = client.calls.first
        #expect(call?.query["include"] == "7,8")
        #expect(client.calls.count == 1)
    }
}
