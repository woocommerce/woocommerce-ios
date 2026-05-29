import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ToolArgumentValidationTests {
    @Test
    func test_validate_when_args_are_subset_of_allowed_then_nil_is_returned() {
        // Given
        let arguments = #"{"id": 42, "status": "completed"}"#
        let allowed: Set<String> = ["id", "status", "customer_note"]

        // When
        let failed = ToolArgumentValidation.validate(arguments: arguments,
                                                     allowed: allowed,
                                                     toolName: "orders_update")

        // Then
        #expect(failed == nil)
    }

    @Test
    func test_validate_when_args_contain_unknown_key_then_failed_with_invalidToolCall_kind_is_returned() {
        // Given
        let arguments = #"{"id": 1, "discount_total": "9.00"}"#
        let allowed: Set<String> = ["id", "status"]

        // When
        let failed = ToolArgumentValidation.validate(arguments: arguments,
                                                     allowed: allowed,
                                                     toolName: "orders_update")

        // Then
        let unwrapped = try? #require(failed)
        #expect(unwrapped?.kind == .invalidToolCall)
        #expect(unwrapped?.reason == "Unsupported orders_update argument(s): discount_total")
    }

    @Test
    func test_validate_when_args_contain_multiple_unknown_keys_then_message_lists_them_comma_separated() {
        // Given
        let arguments = #"{"id": 1, "_method": "delete", "discount_total": "9.00"}"#
        let allowed: Set<String> = ["id"]

        // When
        let failed = ToolArgumentValidation.validate(arguments: arguments,
                                                     allowed: allowed,
                                                     toolName: "orders_update")

        // Then
        let unwrapped = try? #require(failed)
        #expect(unwrapped?.reason.contains("_method, discount_total") == true)
    }

    @Test
    func test_validate_when_args_are_empty_then_nil_is_returned() {
        // Given
        let arguments = "{}"
        let allowed: Set<String> = ["id"]

        // When
        let failed = ToolArgumentValidation.validate(arguments: arguments,
                                                     allowed: allowed,
                                                     toolName: "orders_update")

        // Then
        #expect(failed == nil)
    }

    @Test
    func test_validate_when_arguments_string_is_not_an_object_then_nil_is_returned() {
        // Given
        let arguments = "[1, 2, 3]"
        let allowed: Set<String> = ["id"]

        // When
        let failed = ToolArgumentValidation.validate(arguments: arguments,
                                                     allowed: allowed,
                                                     toolName: "orders_update")

        // Then
        #expect(failed == nil)
    }

    @Test
    func test_validate_patch_when_object_has_unknown_key_then_failed_is_returned() {
        // Given
        let patch: AnyCodableJSON = .object([
            "status": .string("completed"),
            "discount_total": .string("9.00")
        ])

        // When
        let failed = ToolArgumentValidation.validate(patch: patch,
                                                     allowed: ["status", "customer_note"],
                                                     toolName: "orders_bulk_update")

        // Then
        let unwrapped = try? #require(failed)
        #expect(unwrapped?.kind == .invalidToolCall)
        #expect(unwrapped?.reason.contains("discount_total") == true)
    }
}
