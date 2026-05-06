import Foundation
import Testing
@testable import WooAIAssistant

struct ProductSummaryTests {
    @Test
    func test_make_when_entity_has_multiple_images_then_summary_keeps_only_first_image() {
        // Given
        let entity = AnyCodableJSON.object([
            "id": .int(101),
            "name": .string("Hoodie"),
            "images": .array([
                .object(["id": .int(1), "src": .string("https://example.com/1.jpg")]),
                .object(["id": .int(2), "src": .string("https://example.com/2.jpg")]),
                .object(["id": .int(3), "src": .string("https://example.com/3.jpg")])
            ])
        ])

        // When
        let summary = ProductSummary.make(from: entity)

        // Then
        guard case .object(let fields) = summary, case .array(let images) = fields["images"] else {
            Issue.record("expected images array on summary")
            return
        }
        #expect(images.count == 1)
        #expect(images.first == .object(["id": .int(1), "src": .string("https://example.com/1.jpg")]))
    }
}
