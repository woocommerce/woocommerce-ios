import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
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
        #expect(fields["line_items"] == .array([]))
        #expect(fields["line_items_count"] == .int(0))
    }

    @Test
    func test_show_cards_when_order_resolved_then_resolved_ref_summary_includes_payment_method_title_and_customer_id() {
        // Given
        let entity: AnyCodableJSON = .object([
            "id": .int(7),
            "payment_method_title": .string("Stripe"),
            "customer_id": .int(99)
        ])

        // When
        let summary = CardFamily.order.summarize(entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object")
            return
        }
        #expect(fields["payment_method_title"] == .string("Stripe"))
        #expect(fields["customer_id"] == .int(99))
    }

    @Test
    func test_show_cards_when_order_payment_method_title_is_blank_then_field_is_omitted() {
        // Given
        let entity: AnyCodableJSON = .object([
            "id": .int(7),
            "payment_method_title": .string("")
        ])

        // When
        let summary = CardFamily.order.summarize(entity)

        // Then
        if case .object(let fields) = summary {
            #expect(fields["payment_method_title"] == nil)
        } else {
            Issue.record("expected object")
        }
    }

    @Test
    func test_show_cards_when_order_has_line_items_then_resolved_ref_summary_carries_line_items_capped_at_five() {
        // Given
        let items = (1...7).map { idx in
            AnyCodableJSON.object(["id": .int(Int64(idx)), "name": .string("Item \(idx)"), "quantity": .int(1)])
        }
        let entity: AnyCodableJSON = .object([
            "id": .int(7),
            "line_items": .array(items)
        ])

        // When
        let summary = CardFamily.order.summarize(entity)

        // Then
        guard case .object(let fields) = summary, case .array(let projected) = fields["line_items"] else {
            Issue.record("expected line_items array")
            return
        }
        #expect(projected.count == 5)
        #expect(fields["line_items_count"] == .int(7))
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
