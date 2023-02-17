@testable import WordPressAuthenticator
import XCTest

class CodeVerifierTests: XCTestCase {

    func testCodeVerifierIsRandomString() {
        XCTAssertNotEqual(
            ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier().rawValue,
            ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier().rawValue
        )
    }

    func testCodeVerifierIsRandomStringOfLength128ByDefault() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier().rawValue.count, 128)
    }

    func testCodeVerifierMinLengthIs43() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(length: Int.min).rawValue.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(length: 0).rawValue.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(length: 42).rawValue.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(length: 43).rawValue.count, 43)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(length: 44).rawValue.count, 44)
    }

    func testCodeVerifierMaxLengthIs128() {
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(length: 127).rawValue.count, 127)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(length: 128).rawValue.count, 128)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(length: 129).rawValue.count, 128)
        XCTAssertEqual(ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier(length: Int.max).rawValue.count, 128)
    }

    func testCodeVerifierIsRandomStringWithURLSafeCharacters() {
        // Notice we call `inverted` and assert nil to make sure none of the characters that are
        // not URL safe are in the generated string.
        //
        // Given the generation is random, we repeat the test twice to increase reliability.
        XCTAssertNil(
            ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier().rawValue
                .rangeOfCharacter(from: CharacterSet.urlQueryAllowed.inverted)
        )
        XCTAssertNil(
            ProofKeyForCodeExchange.CodeVerifier.makeRandomCodeVerifier().rawValue
                .rangeOfCharacter(from: CharacterSet.urlQueryAllowed.inverted)
        )
    }
}
