@testable import WordPressAuthenticator
import XCTest

class JWTokenTests: XCTestCase {

    func testJWTokenDecodingFromInvalidStringFails() {
        XCTAssertNil(JSONWebToken(encodedString: "invalid"))
    }

    func tsetJWTokenDecodingWithoutHeaderFails() {
        // split validJWTString by . and remove the first
        let inputWithoutHeader = validJWTString.split(separator: ".").dropFirst().joined(separator: ".")
        XCTAssertNil(JSONWebToken(encodedString: inputWithoutHeader))
    }

    func testJWTokenDecodingFromValidString() throws {
        let token = try XCTUnwrap(JSONWebToken(encodedString: validJWTString))

        XCTAssertEqual(
            token.header as? [String: String],
            ["alg": "HS256", "typ": "JWT"]
        )

        XCTAssertEqual(
            token.payload as? [String: String],
            ["key": "value", "other_key": "other_value"]
        )
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
//   "other_key": "other_value"
// }
let validJWTString = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJ2YWx1ZSIsIm90aGVyX2tleSI6Im90aGVyX3ZhbHVlIn0.Koc07zTGuATtQK7EvfAuwgZ-Nsr6P6J3HV4h3QLlXpM"
