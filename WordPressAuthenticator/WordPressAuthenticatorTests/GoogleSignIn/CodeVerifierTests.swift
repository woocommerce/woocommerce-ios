@testable import WordPressAuthenticator
import XCTest

class CodeVerifierTests: XCTestCase {

    func testCodeVerifierIsRandomString() {
        XCTAssertNotEqual(
            ProofKeyForCodeExchange.CodeVerifier().rawValue,
            ProofKeyForCodeExchange.CodeVerifier().rawValue
        )
    }

    func testCodeVerifierIsRandomStringOfLength128ByDefault() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier().rawValue.count, 128)
    }

    func testCodeVerifierMinLengthIs43() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: Int.min).rawValue.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 0).rawValue.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 42).rawValue.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 43).rawValue.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 44).rawValue.count, 44)
    }

    func testCodeVerifierMaxLengthIs128() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 127).rawValue.count, 127)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 128).rawValue.count, 128)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: 129).rawValue.count, 128)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier(length: Int.max).rawValue.count, 128)
    }

    func testCodeVerifierIsRandomStringWithURLSafeCharacters() {
        // Notice we call `inverted` and assert nil to make sure none of the characters that are
        // not URL safe are in the generated string.
        //
        // Given the generation is random, we repeat the test twice to increase reliability.
        XCTAssertNil(
            ProofKeyForCodeExchange.CodeVerifier().rawValue
                .rangeOfCharacter(from: CharacterSet.urlQueryAllowed.inverted)
        )
        XCTAssertNil(
            ProofKeyForCodeExchange.CodeVerifier().rawValue
                .rangeOfCharacter(from: CharacterSet.urlQueryAllowed.inverted)
        )
    }
}
