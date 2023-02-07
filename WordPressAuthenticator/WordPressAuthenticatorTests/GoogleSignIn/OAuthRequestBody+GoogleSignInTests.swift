@testable import WordPressAuthenticator
import XCTest

class OAuthRequestBodyGoogleSignInTests: XCTestCase {

    func testGoogleSignInTokenRequestBody() throws {
        let pkce = ProofKeyForCodeExchange(codeVerifier: "test", method: .plain)
        let body = OAuthTokenRequestBody.googleSignInRequestBody(
            clientId: GoogleClientId(string: "com.app.123-abc")!,
            audience: "audience",
            authCode: "codeValue",
            pkce: pkce
        )

        XCTAssertEqual(body.clientId, "com.app.123-abc")
        XCTAssertEqual(body.clientSecret, "")
        XCTAssertEqual(body.codeVerifier, pkce.codeVerifier)
        XCTAssertEqual(body.grantType, "authorization_code")
        XCTAssertEqual(body.redirectURI, "123-abc.app.com:/oauth2callback")
    }
}
