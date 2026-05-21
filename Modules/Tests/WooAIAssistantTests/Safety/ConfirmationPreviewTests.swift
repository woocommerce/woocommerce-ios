import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ConfirmationPreviewTests {
    @Test
    func test_field_when_priorValue_is_nil_then_only_value_is_set() {
        // Given
        let field = ConfirmationPreviewField(name: "status",
                                             label: .raw("Status"),
                                             value: .raw("processing"))

        // When / Then
        #expect(field.priorValue == nil)
        #expect(field.value == .raw("processing"))
    }

    @Test
    func test_text_when_quantity_then_carries_singular_plural_and_args() {
        // Given
        let text: ConfirmationPreviewText = .quantity(
            3,
            singular: "1 order",
            plural: "%lld orders",
            args: [.raw("3")]
        )

        // When / Then
        guard case .quantity(let count, _, _, let args) = text else {
            Issue.record("expected .quantity, got \(text)")
            return
        }
        #expect(count == 3)
        #expect(args == [.raw("3")])
    }

    @Test
    func test_preview_when_no_fields_then_isBulk_defaults_to_false() {
        // Given
        let preview = ConfirmationPreview(summary: .raw("Update order #42"))

        // When / Then
        #expect(preview.isBulk == false)
        #expect(preview.fields.isEmpty)
    }

    @Test
    func test_showsSummaryInBody_when_bulk_entries_present_then_false() {
        // Given
        let preview = ConfirmationPreview(summary: .raw("Update 2 orders"),
                                          isBulk: true,
                                          bulkEntries: [ConfirmationBulkEntry(id: 1)])

        // When / Then
        #expect(preview.showsSummaryInBody == false)
    }

    @Test
    func test_showsSummaryInBody_when_fields_present_then_false() {
        // Given
        let field = ConfirmationPreviewField(name: "status", label: .raw("Status"), value: .raw("processing"))
        let preview = ConfirmationPreview(summary: .raw("Update order #42"), fields: [field])

        // When / Then
        #expect(preview.showsSummaryInBody == false)
    }

    @Test
    func test_showsSummaryInBody_when_only_summary_then_true() {
        // Given
        let preview = ConfirmationPreview(summary: .raw("Update order #42"))

        // When / Then
        #expect(preview.showsSummaryInBody == true)
    }
}
