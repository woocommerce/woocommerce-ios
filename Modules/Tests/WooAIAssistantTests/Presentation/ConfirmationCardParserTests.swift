import Testing
@testable import WooAIAssistant

struct ConfirmationCardParserTests {

    @Test
    func test_parsedPreview_when_preview_has_only_arrow_clauses_then_parses_fields() {
        // Given
        let preview = "Update order #3479: status processing → completed"

        // When
        let parsed = ParsedPreview(text: preview)

        // Then
        #expect(parsed?.fields.count == 1)
        #expect(parsed?.fields.first?.before == "Processing")
        #expect(parsed?.fields.first?.after == "Completed")
    }

    @Test
    func test_parsedPreview_when_preview_has_mixed_arrow_and_text_clauses_then_returns_nil_so_view_renders_full_preview_verbatim() {
        // Given
        let preview = "Update order #3479: status processing → completed, customer note updated"

        // When
        let parsed = ParsedPreview(text: preview)

        // Then
        #expect(parsed == nil)
    }

    @Test
    func test_parsedPreview_when_preview_has_only_text_clauses_then_returns_nil() {
        // Given
        let preview = "Update order #3479: customer note updated"

        // When
        let parsed = ParsedPreview(text: preview)

        // Then
        #expect(parsed?.fields == nil)
    }
}
