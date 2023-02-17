@testable import WordPressAuthenticator
import Foundation
import XCTest

class Character_URLSafeTests: XCTestCase {

    func testURLSafeCharacters() {
        Character.urlSafeCharacters.forEach { character in
            XCTAssertFalse(
                CharacterSet.urlQueryAllowed.inverted.contains(character.unicodeScalars.first!),
                "Expected \(character) to be part of the URL safe set, but it was found in its inverted set"
            )
        }
    }
}
