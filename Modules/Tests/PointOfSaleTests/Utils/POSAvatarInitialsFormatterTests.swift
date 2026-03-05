import Foundation
import Testing
@testable import PointOfSale

struct POSAvatarInitialsFormatterTests {
    @Test func test_initials_when_name_is_nil_then_returns_nil() {
        // Given
        let name: String? = nil

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == nil)
    }

    @Test func test_initials_when_name_is_empty_then_returns_nil() {
        // Given
        let name = ""

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == nil)
    }

    @Test func test_initials_when_name_is_whitespace_only_then_returns_nil() {
        // Given
        let name = "     "

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == nil)
    }

    @Test func test_initials_when_single_word_name_then_returns_first_letter_uppercased() {
        // Given
        let name = "John"

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == "J")
    }

    @Test func test_initials_when_two_word_name_then_returns_both_initials_uppercased() {
        // Given
        let name = "John Doe"

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == "JD")
    }

    @Test func test_initials_when_three_word_name_then_returns_first_two_initials() {
        // Given
        let name = "John Michael Doe"

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == "JM")
    }

    @Test func test_initials_when_lowercase_name_then_returns_uppercased() {
        // Given
        let name = "jane smith"

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == "JS")
    }

    @Test func test_initials_when_name_has_leading_trailing_spaces_then_returns_correct_initials() {
        // Given
        let name = "  Alice  "

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == "A")
    }

    @Test func test_initials_when_single_character_name_then_returns_that_character_uppercased() {
        // Given
        let name = "j"

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == "J")
    }

    @Test func test_initials_when_name_has_multiple_spaces_between_words_then_returns_correct_initials() {
        // Given
        let name = "John   Doe"

        // When
        let result = POSAvatarInitialsFormatter.initials(from: name)

        // Then
        #expect(result == "JD")
    }
}
