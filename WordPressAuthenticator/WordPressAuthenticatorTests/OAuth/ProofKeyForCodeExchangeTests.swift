@testable import WordPressAuthenticator
import XCTest

class ProofKeyForCodeExchangeTests: XCTestCase {

    func testCodeChallengeInPlainModeIsTheSameAsCodeVerifier() {
        XCTAssertEqual(
            ProofKeyForCodeExchange(codeVerifier: "abc", method: .plain).codeCallenge,
            "abc"
        )
    }

    func testCodeChallengeInS256ModeIsEncodedAsPerSpec() {
        // TODO:
    }

    func testMethodURLQueryParameterValuePlain() {
        XCTAssertEqual(ProofKeyForCodeExchange.Method.plain.urlQueryParameterValue, "plain")
    }

    func testMethodURLQueryParameterValueS256() {
        XCTAssertEqual(ProofKeyForCodeExchange.Method.s256.urlQueryParameterValue, "S256")
    }
}
