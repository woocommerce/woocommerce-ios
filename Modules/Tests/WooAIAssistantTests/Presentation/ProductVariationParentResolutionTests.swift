import Testing
@testable import WooAIAssistant

@MainActor
struct ProductVariationParentResolutionTests {

    @Test
    func test_resolveParentID_when_row_has_parent_id_then_uses_row_value() {
        // Given
        let row = ProductVariationCardPayload(id: 101, parentID: 7)
        let parent = AnyCodableJSON.object([
            "product_id": .int(99),
            "rows": .array([])
        ])

        // When
        let parentID = ProductVariationCardPayload.resolveParentID(row: row, parent: parent)

        // Then
        #expect(parentID == 7)
    }

    @Test
    func test_resolveParentID_when_row_missing_parent_id_then_falls_back_to_parent_product_id() {
        // Given
        let row = ProductVariationCardPayload(id: 101)
        let parent = AnyCodableJSON.object([
            "product_id": .int(42),
            "rows": .array([])
        ])

        // When
        let parentID = ProductVariationCardPayload.resolveParentID(row: row, parent: parent)

        // Then
        #expect(parentID == 42)
    }

    @Test
    func test_resolveParentID_when_neither_payload_carries_parent_then_returns_nil() {
        // Given
        let row = ProductVariationCardPayload(id: 101)
        let parent = AnyCodableJSON.object(["rows": .array([])])

        // When
        let parentID = ProductVariationCardPayload.resolveParentID(row: row, parent: parent)

        // Then
        #expect(parentID == nil)
    }
}
