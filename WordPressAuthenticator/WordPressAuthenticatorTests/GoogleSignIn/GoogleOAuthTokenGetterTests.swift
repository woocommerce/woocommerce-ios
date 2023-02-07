@testable import WordPressAuthenticator
import XCTest

class GoogleOAuthTokenGetterTests: XCTestCase {

    func testThrowsWhenReceivingAnError() async throws {
        let dataGettingStub = DataGettingStub(error: TestError(id: 1))

        let getter = GoogleOAuthTokenGetter(dataGetter: dataGettingStub)

        do {
            _ = try await getter.getToken(
                clientId: GoogleClientId(string: "a.b.c")!,
                audience: "audience",
                authCode: "abc",
                pkce: ProofKeyForCodeExchange(codeVerifier: "code", method: .plain)
            )
            XCTFail("Expected error to be thrown")
        } catch {
            let error = try XCTUnwrap(error as? TestError)
            XCTAssertEqual(error.id, 1)
        }
    }

    func testReturnsTokenWhenReceivingOne() async throws {
        let expectedResponse = OAuthTokenResponseBody(
            accessToken: "a",
            expiresIn: 1,
            idToken: .none,
            refreshToken: .none,
            scope: "s",
            tokenType: "t"
        )
        let dataGettingStub = DataGettingStub(data: try JSONEncoder().encode(expectedResponse))
        let getter = GoogleOAuthTokenGetter(dataGetter: dataGettingStub)

        let response = try await getter.getToken(
            clientId: GoogleClientId(string: "a.b.c")!,
            audience: "audience",
            authCode: "abc",
            pkce: ProofKeyForCodeExchange(codeVerifier: "code", method: .plain)
        )

        XCTAssertEqual(response, expectedResponse)
    }
}

struct TestError: Equatable, Error {
    let id: Int
}
