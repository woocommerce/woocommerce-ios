import XCTest
@testable import WooCommerce

final class BlazeAddParameterViewModelTests: XCTestCase {
    func test_when_entering_view_with_no_parameters_then_save_button_disabled() {
        // Given
        let sut = BlazeAddParameterViewModel(
            remainingCharacters: 100,
            parameter: nil,
            onCancel: { },
            onCompletion: { _, _ in }
        )

        // Then
        XCTAssertTrue(sut.shouldDisableSaveButton)
    }

    func test_when_entering_view_with_existing_parameters_then_save_button_enabled() {
        // Given
        let sut = BlazeAddParameterViewModel(
            remainingCharacters: 100,
            parameter: BlazeAdURLParameter(key: "key", value: "value"),
            onCancel: { },
            onCompletion: { _, _ in }
        )

        // Then
        XCTAssertFalse(sut.shouldDisableSaveButton)
    }

    func test_when_either_key_or_value_is_empty_then_save_button_disabled() {
        // Given
        let sut = BlazeAddParameterViewModel(
            remainingCharacters: 100,
            parameter: nil,
            onCancel: { },
            onCompletion: { _, _ in }
        )

        // When
        sut.key = "key"
        sut.value = ""

        // Then
        sut.validateInputs()
        XCTAssertTrue(sut.shouldDisableSaveButton)
    }

    func test_when_inputs_are_valid_then_save_button_enabled() {
        // Given
        let sut = BlazeAddParameterViewModel(
            remainingCharacters: 100,
            parameter: nil,
            onCancel: { },
            onCompletion: { _, _ in }
        )

        // When
        // No invalid character, not exceeding characters count
        sut.key = "key"
        sut.value = "value"

        // Then
        sut.validateInputs()
        XCTAssertFalse(sut.shouldDisableSaveButton)
    }

    func test_when_entered_parameters_exceed_remaining_characters_then_hasCountError_is_true() {
        // Given
        let sut = BlazeAddParameterViewModel(
            remainingCharacters: 1, // Intentionally set small to make it easy to exceed.
            parameter: nil,
            onCancel: { },
            onCompletion: { _, _ in }
        )

        // When
        sut.key = "AAA"
        sut.value = "BBB"

        // Then
        sut.validateInputs()
        XCTAssertTrue(sut.hasCountError)
    }


    func test_when_entered_parameters_has_invalid_characters_then_hasValidationError_is_true() {
        // Given
        let sut = BlazeAddParameterViewModel(
            remainingCharacters: 100,
            parameter: nil,
            onCancel: { },
            onCompletion: { _, _ in }
        )

        // When
        // "space" is one of the invalid characters.
        sut.key = "A "
        sut.value = "B "

        // Then
        sut.validateInputs()
        XCTAssertTrue(sut.hasValidationError)
    }
}
