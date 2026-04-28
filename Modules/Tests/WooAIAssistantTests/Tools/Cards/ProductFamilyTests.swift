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
}
