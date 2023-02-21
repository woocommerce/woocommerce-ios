@testable import WordPressAuthenticator
import Foundation
import XCTest

class Character_URLSafeTests: XCTestCase {

    func testURLSafeCharacters() throws {
        // Ensure `Character.urlSafeCharacters` maps 1:1 to `CharacterSet.urlQueryAllowed` by
        // checking that `urlQueryAllowed` contains every character in `urlSafeCharacters`.
        try Character.urlSafeCharacters.forEach { character in
            let unicodeCharacter = try XCTUnwrap(character.unicodeScalars.first)
            XCTAssertTrue(
                CharacterSet.urlQueryAllowed.contains(unicodeCharacter),
                "Expected \(character) to be part of the URL safe set"
            )
        }
    }
}
