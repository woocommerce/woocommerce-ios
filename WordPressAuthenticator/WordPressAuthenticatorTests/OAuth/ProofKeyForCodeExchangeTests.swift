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
}
