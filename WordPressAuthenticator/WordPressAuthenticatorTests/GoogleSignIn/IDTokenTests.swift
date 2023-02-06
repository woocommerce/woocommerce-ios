@testable import WordPressAuthenticator
import XCTest

class IDTokenTests: XCTestCase {

    func testInitWithJWTWithoutEmail() throws {
        XCTAssertNil(IDToken(jwt: try XCTUnwrap(JWToken(encodedString: validJWTString))))
    }

    func testInitWithJWTWithEmail() throws {
        let jwt = try XCTUnwrap(JWToken(encodedString: validJWTStringWithEmail))
        let token = try XCTUnwrap(IDToken(jwt: jwt))

        XCTAssertEqual(token.email, "test@email.com")
    }

}

// Created with https://jwt.io/ with input:
//
// header: {
//   "alg": "HS256",
//   "typ": "JWT"
// }
// payload: {
//   "key": "value",
//   "email": "test@email.com"
// }
let validJWTStringWithEmail = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJ2YWx1ZSIsImVtYWlsIjoidGVzdEBlbWFpbC5jb20ifQ.b-2oTvjpc_qHM5dU6akk_ESe3eWUZwL21pvTsCmW2gE"
