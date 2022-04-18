import Foundation
@testable import WooCommerce
import XCTest

class StringHelpersTests: XCTestCase {
    func test_removeLastCharacterIfWhitespace_when_string_has_whitespace_as_last_character_then_it_is_removed() {
        // Given
        let testString = "test "

        // When
        let result = String.removeLastCharacterIfWhitespace(from: testString)

        // Then
        XCTAssertEqual(result, String(testString.dropLast()))
    }

    func test_removeLastCharacterIfWhitespace_when_string_has_no_whitespace_as_last_character_then_it_returns_the_same_string() {
        // Given
        let testString = "test"

        // When
        let result = String.removeLastCharacterIfWhitespace(from: testString)

        // Then
        XCTAssertEqual(result, testString)
    }
}
