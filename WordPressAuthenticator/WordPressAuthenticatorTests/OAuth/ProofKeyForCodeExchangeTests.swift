@testable import WordPressAuthenticator
import XCTest

class ProofKeyForCodeExchangeTests: XCTestCase {

    func testCodeChallengeInPlainModeIsTheSameAsCodeVerifier() {
        let codeVerifier = ProofKeyForCodeExchange.CodeVerifier()

        XCTAssertEqual(
            ProofKeyForCodeExchange(codeVerifier: codeVerifier, method: .plain).codeCallenge,
            codeVerifier.value
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
