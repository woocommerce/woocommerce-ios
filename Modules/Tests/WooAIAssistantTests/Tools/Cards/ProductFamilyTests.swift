import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
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
    func test_show_cards_when_product_resolved_then_resolved_ref_summary_includes_type_manage_stock_on_sale_stock_quantity() {
        // Given
        let entity: AnyCodableJSON = .object([
            "id": .int(42),
            "name": .string("Beanie"),
            "type": .string("simple"),
            "manage_stock": .bool(true),
            "on_sale": .bool(false),
            "stock_quantity": .int(8)
        ])

        // When
        let summary = CardFamily.product.summarize(entity)

        // Then
        guard case .object(let fields) = summary else {
            Issue.record("expected object")
            return
        }
        #expect(fields["type"] == .string("simple"))
        #expect(fields["manage_stock"] == .bool(true))
        #expect(fields["on_sale"] == .bool(false))
        #expect(fields["stock_quantity"] == .int(8))
    }
}
