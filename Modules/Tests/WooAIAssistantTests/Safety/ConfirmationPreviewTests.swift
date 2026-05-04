import Foundation
import Testing
@testable import WooAIAssistant

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
}
