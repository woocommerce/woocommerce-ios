import XCTest
@testable import Networking

final class JWTokenMapperTests: XCTestCase {
    func test_it_maps_JWToken_correctly_from_token_response() throws {
        // Given
        let data = try retrieveJWTResponse()
        let mapper = JWTokenMapper()

        // When
        let jwtoken = try mapper.map(response: data)

        // Then
        XCTAssertEqual(jwtoken.expiryDate.timeIntervalSince1970, 7282344061)
        XCTAssertEqual(jwtoken.siteID, 1234)
        XCTAssertEqual(jwtoken.token,
                       "123abc." +
                       // swiftlint:disable:next line_length
                       "ew0KICAiaXNzIjogImpldHBhY2suY29tIiwNCiAgImlhdCI6IDEyMzEyMywNCiAgImJsb2dfaWQiOiAxMjM0LA0KICAidXNlcl9pZCI6IDEyMzEyMywNCiAgImF1dGgiOiAiamV0cGFja19vcGVuYWkiLA0KICAiYWNjZXNzIjogIm9wZW5haSIsDQogICJleHAiOiA3MjgyMzQ0MDYxLA0KICAiZXhwaXJlcyI6IDcyODIzNDQwNjENCn0" +
                       ".abc123")
    }
}

// MARK: - Test Helpers
///
private extension JWTokenMapperTests {
    func retrieveJWTResponse() throws -> Data {
        guard let response = Loader.contentsOf("jwt-token-success") else {
            throw FileNotFoundError()
        }

        return response
    }

    struct FileNotFoundError: Error {}
}
