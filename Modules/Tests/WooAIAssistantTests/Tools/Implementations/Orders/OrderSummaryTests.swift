import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct OrderSummaryTests {
    @Test
    func test_make_when_order_has_billing_and_shipping_then_addresses_are_projected_with_blank_fields_dropped() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(7),
            "billing": .object([
                "first_name": .string("Jane"),
                "last_name": .string("Doe"),
                "email": .string("jane@example.com"),
                "phone": .string(""),
                "city": .string("Berlin"),
                "country": .string("DE"),
                "state": .string(""),
                "postcode": .string("")
            ]),
            "shipping": .object([
                "first_name": .string("Jane"),
                "last_name": .string("Doe"),
                "city": .string("Berlin"),
                "country": .string("DE")
            ])
        ])

        // When
        let summary = OrderSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary,
              case .object(let billing) = fields["billing"],
              case .object(let shipping) = fields["shipping"] else {
            Issue.record("expected billing and shipping objects")
            return
        }
        #expect(billing["first_name"] == .string("Jane"))
        #expect(billing["email"] == .string("jane@example.com"))
        #expect(billing["city"] == .string("Berlin"))
        #expect(billing["country"] == .string("DE"))
        #expect(billing["phone"] == nil)
        #expect(billing["state"] == nil)
        #expect(billing["postcode"] == nil)
        #expect(shipping["email"] == nil)
        #expect(shipping["country"] == .string("DE"))
    }

    @Test
    func test_make_when_customer_note_exceeds_500_chars_then_value_is_truncated_and_flag_is_true() {
        // Given
        let note = String(repeating: "a", count: 600)
        let entity = AnyCodableJSON.object(["id": .int(7), "customer_note": .string(note)])

        // When
        let summary = OrderSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary, case .string(let projected) = fields["customer_note"] else {
            Issue.record("expected customer_note string")
            return
        }
        #expect(projected.count == 500)
        #expect(fields["customer_note_truncated"] == .bool(true))
    }

    @Test
    func test_make_when_customer_note_is_short_then_truncated_flag_is_absent() {
        // Given
        let entity = AnyCodableJSON.object(["id": .int(7), "customer_note": .string("Thanks!")])

        // When
        let summary = OrderSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object")
            return
        }
        #expect(fields["customer_note"] == .string("Thanks!"))
        #expect(fields["customer_note_truncated"] == nil)
    }

    @Test
    func test_make_when_order_has_more_than_ten_line_items_then_line_items_truncated_is_true() {
        // Given
        let items = (0..<12).map { idx in
            AnyCodableJSON.object(["id": .int(Int64(idx)), "name": .string("Item \(idx)"), "quantity": .int(1)])
        }
        let entity = AnyCodableJSON.object(["id": .int(7), "line_items": .array(items)])

        // When
        let summary = OrderSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary,
              case .array(let projected) = fields["line_items"] else {
            Issue.record("expected line_items array")
            return
        }
        #expect(projected.count == 10)
        #expect(fields["line_items_count"] == .int(12))
        #expect(fields["line_items_truncated"] == .bool(true))
    }

    @Test
    func test_make_when_order_has_no_coupons_then_coupon_lines_field_is_empty_array() {
        // Given
        let entity = AnyCodableJSON.object(["id": .int(7)])

        // When
        let summary = OrderSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object")
            return
        }
        #expect(fields["coupon_lines"] == .array([]))
    }

    @Test
    func test_make_when_order_has_coupons_then_each_coupon_line_carries_code_and_discount() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(7),
            "coupon_lines": .array([
                .object([
                    "id": .int(11),
                    "code": .string("SAVE10"),
                    "discount": .string("5.00"),
                    "discount_tax": .string("0.50")
                ])
            ])
        ])

        // When
        let summary = OrderSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary,
              case .array(let coupons) = fields["coupon_lines"],
              case .object(let first) = coupons.first else {
            Issue.record("expected coupon_lines array")
            return
        }
        #expect(first["code"] == .string("SAVE10"))
        #expect(first["discount"] == .string("5.00"))
        #expect(first["discount_tax"] == .string("0.50"))
    }

    @Test
    func test_make_when_order_has_fees_then_fee_lines_capped_at_ten() {
        // Given
        let fees = (0..<15).map { idx in
            AnyCodableJSON.object([
                "id": .int(Int64(idx)),
                "name": .string("Fee \(idx)"),
                "total": .string("1.00")
            ])
        }
        let entity = AnyCodableJSON.object(["id": .int(7), "fee_lines": .array(fees)])

        // When
        let summary = OrderSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary,
              case .array(let projected) = fields["fee_lines"] else {
            Issue.record("expected fee_lines array")
            return
        }
        #expect(projected.count == 10)
    }

    @Test
    func test_make_when_order_has_tax_lines_then_tax_lines_carry_rate_code_and_total() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(7),
            "tax_lines": .array([
                .object([
                    "id": .int(99),
                    "rate_id": .int(1),
                    "rate_code": .string("DE-VAT-19"),
                    "label": .string("VAT"),
                    "tax_total": .string("19.00"),
                    "shipping_tax_total": .string("0.95")
                ])
            ])
        ])

        // When
        let summary = OrderSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary,
              case .array(let taxes) = fields["tax_lines"],
              case .object(let first) = taxes.first else {
            Issue.record("expected tax_lines array")
            return
        }
        #expect(first["rate_code"] == .string("DE-VAT-19"))
        #expect(first["tax_total"] == .string("19.00"))
        #expect(first["shipping_tax_total"] == .string("0.95"))
    }

    @Test
    func test_orderRow_when_lineItemLimit_is_five_then_only_first_five_returned() {
        // Given
        let items = (0..<7).map { idx in
            AnyCodableJSON.object(["id": .int(Int64(idx))])
        }
        let entity = AnyCodableJSON.object(["id": .int(7), "line_items": .array(items)])

        // When
        let summary = OrderSummary.orderRow(from: entity, lineItemLimit: 5)

        // Then
        guard case .object(let fields) = summary,
              case .array(let projected) = fields["line_items"] else {
            Issue.record("expected line_items array")
            return
        }
        #expect(projected.count == 5)
        #expect(fields["line_items_truncated"] == .bool(true))
        #expect(fields["line_items_count"] == .int(7))
    }
}
