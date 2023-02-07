@testable import WordPressAuthenticator

extension JSONWebToken {

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
    private(set) static var validJWTString = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJ2YWx1ZSIsIm90aGVyX2tleSI6Im90aGVyX3ZhbHVlIn0.Koc07zTGuATtQK7EvfAuwgZ-Nsr6P6J3HV4h3QLlXpM"

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
    private(set) static var validJWTStringWithEmail = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJ2YWx1ZSIsImVtYWlsIjoidGVzdEBlbWFpbC5jb20ifQ.b-2oTvjpc_qHM5dU6akk_ESe3eWUZwL21pvTsCmW2gE"

    // For convenience, this exposes the email value used in validJWTStringWithEmail.
    // This allows us to use raw strings in tests, rather than having to implement encoding the JWT from an arbitrary string.
    private(set) static var emailFromValidJWTStringWithEmail = "test@email.com"
}
