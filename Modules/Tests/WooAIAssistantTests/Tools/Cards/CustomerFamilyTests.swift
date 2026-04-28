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
        let summary = CustomerFamily().summarize(entity)

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
        let outcome = await CustomerFamily().fetch(id: 7, client: client)

        // Then
        guard case .found(let entity) = outcome else {
            Issue.record("expected found, got \(outcome)")
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
    func test_fetch_when_include_returns_empty_array_then_returns_not_found() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.ok("[]"))

        // When
        let outcome = await CustomerFamily().fetch(id: 999, client: client)

        // Then
        if case .rejected(let reason) = outcome {
            #expect(reason == .notFound)
        } else {
            Issue.record("expected rejected, got \(outcome)")
        }
    }

    @Test
    func test_fetch_when_response_is_401_then_returns_not_permitted() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.failure(statusCode: 401))

        // When
        let outcome = await CustomerFamily().fetch(id: 7, client: client)

        // Then
        if case .rejected(let reason) = outcome {
            #expect(reason == .notPermitted)
        } else {
            Issue.record("expected rejected, got \(outcome)")
        }
    }

    @Test
    func test_fetch_when_payload_is_object_not_array_then_returns_internal_error() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.ok("{\"id\": 7}"))

        // When
        let outcome = await CustomerFamily().fetch(id: 7, client: client)

        // Then
        if case .rejected(let reason) = outcome {
            #expect(reason == .internalError)
        } else {
            Issue.record("expected rejected, got \(outcome)")
        }
    }
}
