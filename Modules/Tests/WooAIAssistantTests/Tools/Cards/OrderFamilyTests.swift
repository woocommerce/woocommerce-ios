import Foundation
import Testing
@testable import WooAIAssistant

struct OrderFamilyTests {
    @Test
    func test_summarize_when_billing_present_then_projects_summary_fields() {
        // Given
        let entity: AnyCodableJSON = .object([
            "id": .int(3551),
            "number": .string("3551"),
            "status": .string("processing"),
            "total": .string("120.00"),
            "currency": .string("USD"),
            "date_created": .string("2026-04-20T10:00:00"),
            "billing": .object([
                "first_name": .string("Jane"),
                "last_name": .string("Doe")
            ]),
            "line_items": .array([])
        ])

        // When
        let summary = CardFamily.order.summarize(entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object summary")
            return
        }
        #expect(fields["id"] == .int(3551))
        #expect(fields["number"] == .string("3551"))
        #expect(fields["status"] == .string("processing"))
        #expect(fields["total"] == .string("120.00"))
        #expect(fields["currency"] == .string("USD"))
        #expect(fields["date_created"] == .string("2026-04-20T10:00:00"))
        #expect(fields["customer_name"] == .string("Jane Doe"))
        #expect(fields["line_items"] == nil)
    }

    @Test
    func test_summarize_when_billing_names_blank_then_omits_customer_name() {
        // Given
        let entity: AnyCodableJSON = .object([
            "id": .int(7),
            "billing": .object([
                "first_name": .string(""),
                "last_name": .string("")
            ])
        ])

        // When
        let summary = CardFamily.order.summarize(entity)

        // Then
        if case .object(let fields) = summary {
            #expect(fields["customer_name"] == nil)
        } else {
            Issue.record("expected object summary")
        }
    }

    @Test
    func test_fetch_when_response_ok_then_returns_pruned_entity() async {
        // Given
        let body = """
        {"id": 3551, "status": "processing", "total": "120.00", "_links": {}}
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))

        // When
        let outcome = await CardFamily.order.fetch(id: 3551, client: client)

        // Then
        guard case .found(let entity) = outcome else {
            Issue.record("expected found, got \(outcome)")
            return
        }
        if case .object(let dict) = entity {
            #expect(dict["status"] == .string("processing"))
            #expect(dict["_links"] == nil)
        }
        let call = client.calls.first
        #expect(call?.method == "GET")
        #expect(call?.path == "wc/v3/orders/3551")
    }

    @Test
    func test_fetch_when_status_is_trash_then_returns_stale_reference() async {
        // Given
        let body = """
        {"id": 3551, "status": "trash"}
        """
        let client = RecordingWCRESTClient(response: StubResponses.ok(body))

        // When
        let outcome = await CardFamily.order.fetch(id: 3551, client: client)

        // Then
        if case .rejected(let reason) = outcome {
            #expect(reason == .staleReference)
        } else {
            Issue.record("expected rejected, got \(outcome)")
        }
    }

    @Test
    func test_fetch_when_response_is_404_then_returns_not_found() async {
        // Given
        let client = RecordingWCRESTClient(response: StubResponses.failure(statusCode: 404))

        // When
        let outcome = await CardFamily.order.fetch(id: 99999, client: client)

        // Then
        if case .rejected(let reason) = outcome {
            #expect(reason == .notFound)
        } else {
            Issue.record("expected rejected, got \(outcome)")
        }
    }
}
