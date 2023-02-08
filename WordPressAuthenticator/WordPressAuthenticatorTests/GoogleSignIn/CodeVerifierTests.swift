@testable import WordPressAuthenticator
import XCTest

class CodeVerifierTests: XCTestCase {

    func testCodeVerifierIsRandomString() {
        XCTAssertNotEqual(
            ProofKeyForCodeExchange.CodeVerifier().value,
            ProofKeyForCodeExchange.CodeVerifier().value
        )
    }

    func testCodeVerifierIsRandomStringOfLength128ByDefault() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier().value.count, 128)
    }

    func testCodeVerifierMinLengthIs43() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: Int.min).value.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 0).value.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 42).value.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 43).value.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 44).value.count, 44)
    }

    func testCodeVerifierMaxLengthIs128() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 127).value.count, 127)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 128).value.count, 128)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 129).value.count, 128)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: Int.max).value.count, 128)
    }

    func testCodeVerifierIsRandomStringWithURLSafeCharacters() {
        // Notice we call `inverted` and assert nil to make sure none of the characters that are
        // not URL safe are in the generated string.
        //
        // Given the generation is random, we repeat the test twice to increase reliability.
        XCTAssertNil(
            ProofKeyForCodeExchange.CodeVerifier().value
                .rangeOfCharacter(from: CharacterSet.urlQueryAllowed.inverted)
        )
        XCTAssertNil(
            ProofKeyForCodeExchange.CodeVerifier().value
                .rangeOfCharacter(from: CharacterSet.urlQueryAllowed.inverted)
        )
    }
}
