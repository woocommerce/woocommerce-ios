@testable import WordPressAuthenticator
import Foundation
import XCTest

class Character_URLSafeTests: XCTestCase {

    func testURLSafeCharacters() throws {
        try Character.urlSafeCharacters.forEach { character in
            let unicodeCharacter = try XCTUnwrap(character.unicodeScalars.first)
            XCTAssertFalse(
                CharacterSet.urlQueryAllowed.inverted.contains(unicodeCharacter),
                "Expected \(character) to be part of the URL safe set, but it was found in its inverted set"
            )
        }
    }
}
