@testable import WordPressAuthenticator
import XCTest

class ProofKeyForCodeExchangeTests: XCTestCase {

    func testCodeChallengeInPlainModeIsTheSameAsCodeVerifier() {
        XCTAssertEqual(
            ProofKeyForCodeExchange(codeVerifier: "abc", mode: .plain).codeCallenge,
            "abc"
        )
    }

    func testCodeChallengeInS256ModeIsEncodedAsPerSpec() {
        // TODO:
    }

    func testModePlainMethod() {
        XCTAssertEqual(ProofKeyForCodeExchange.Mode.plain.method, "plain")
    }

    func testModeS256Method() {
        XCTAssertEqual(ProofKeyForCodeExchange.Mode.s256.method, "S256")
    }
}
