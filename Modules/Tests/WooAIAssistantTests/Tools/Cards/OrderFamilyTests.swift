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
}
