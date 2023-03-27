@testable import WordPressAuthenticator
import XCTest

class IDTokenTests: XCTestCase {

    func testInitWithJWTWithoutEmail() throws {
        XCTAssertNil(IDToken(jwt: try XCTUnwrap(JSONWebToken(encodedString: JSONWebToken.validJWTString))))
    }

    func testInitWithJWTWithEmail() throws {
        let jwt = try XCTUnwrap(JSONWebToken(encodedString: JSONWebToken.validJWTStringWithEmailOnly))
        let token = try XCTUnwrap(IDToken(jwt: jwt))

        XCTAssertEqual(token.email, JSONWebToken.emailFromValidJWTStringWithEmail)
    }

}
