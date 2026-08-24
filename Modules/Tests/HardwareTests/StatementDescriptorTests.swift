import Testing
@testable import Hardware

struct StatementDescriptorTests {
    @Test func test_wrappedValue_when_value_is_nil_then_returns_nil() {
        // Given
        let value: String? = nil

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == nil)
    }

    @Test func test_wrappedValue_when_value_is_empty_then_returns_nil() {
        // Given
        let value = ""

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == nil)
    }

    @Test func test_wrappedValue_when_value_is_valid_then_returns_value_unchanged() {
        // Given
        let value = "MY.FANCY.STORE"

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == value)
    }

    @Test func test_wrappedValue_when_value_is_at_length_boundaries_then_returns_value() {
        // Given
        let minimumLengthValue = "Store"
        let maximumLengthValue = "A DESCRIPTION LONGER T"

        // When
        let minimumLengthResult = sanitizedDescriptor(minimumLengthValue)
        let maximumLengthResult = sanitizedDescriptor(maximumLengthValue)

        // Then
        #expect(minimumLengthResult == minimumLengthValue)
        #expect(maximumLengthResult == maximumLengthValue)
    }

    @Test func test_wrappedValue_when_value_exceeds_maximum_length_then_truncates_value() {
        // Given
        let value = "A DESCRIPTION LONGER THAN 22 CHARACTERS"

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == "A DESCRIPTION LONGER T")
    }

    @Test func test_wrappedValue_when_value_contains_forbidden_characters_then_replaces_them() {
        // Given
        let value = "A<B>C\\D'E\"F*G"

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == "A-B-C-D-E-F-G")
    }

    @Test func test_wrappedValue_when_value_contains_latin_diacritics_then_folds_them_to_ASCII() {
        // Given
        let value = "Café Øresund Łódź"

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == "Cafe Oresund Lodz")
    }

    @Test func test_wrappedValue_when_value_contains_non_ASCII_characters_then_replaces_them() {
        // Given
        let value = "Store 店 😀"

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == "Store - -")
    }

    @Test func test_wrappedValue_when_value_contains_control_characters_then_replaces_them() {
        // Given
        let value = "Store\nName\t"

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == "Store-Name-")
    }

    @Test func test_wrappedValue_when_sanitized_value_is_too_short_then_returns_nil() {
        // Given
        let value = "Shop"

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == nil)
    }

    @Test func test_wrappedValue_when_value_does_not_contain_a_letter_then_returns_nil() {
        // Given
        let value = "12345"

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == nil)
    }

    @Test func test_wrappedValue_when_sanitization_produces_an_invalid_value_then_returns_nil() {
        // Given
        let value = "店名"

        // When
        let result = sanitizedDescriptor(value)

        // Then
        #expect(result == nil)
    }
}

private extension StatementDescriptorTests {
    func sanitizedDescriptor(_ value: String?) -> String? {
        StatementDescriptor(wrappedValue: value).wrappedValue
    }
}
