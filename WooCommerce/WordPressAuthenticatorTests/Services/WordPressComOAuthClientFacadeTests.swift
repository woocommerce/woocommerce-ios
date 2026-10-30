import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest
@testable import WordPressAuthenticator

// Stays on XCTest: OHHTTPStubs stubs are process-wide, so they would leak into Swift Testing tests running in parallel.
final class WordPressComOAuthClientFacadeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        WordPressAuthenticator.initializeForTesting()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    private var isOAuthTokenRequest: HTTPStubsTestBlock {
        { request in
            request.url?.path == "/oauth2/token"
        }
    }

    func test_authenticate_when_400_requires_two_factor_then_passes_supported_methods_without_nonce() {
        // Given
        let response = Data(#"{"error":"needs_2fa","two_step_supported_auth_types":["backup","sms"]}"#.utf8)
        stub(condition: isOAuthTokenRequest) { _ in
            HTTPStubsResponse(data: response, statusCode: 400, headers: ["Content-Type": "application/json"])
        }
        let callback = expectation(description: "The 2FA callback receives the available methods")
        let facade = WordPressComOAuthClientFacade(client: "Fake", secret: "Fake")

        // When
        facade.authenticate(username: "fakeUser", password: "fakePassword", multifactorCode: nil, success: { _ in
            XCTFail("The login should require a 2FA code")
        }, needsMultifactor: { userID, nonceInfo, supportedAuthTypes in
            // Then
            XCTAssertEqual(userID, 0)
            XCTAssertNil(nonceInfo)
            XCTAssertEqual(supportedAuthTypes, ["backup", "sms"])
            callback.fulfill()
        }, failure: { _ in
            XCTFail("The 2FA response should use the multifactor callback")
        })

        wait(for: [callback], timeout: 2)
    }

    func test_authenticate_when_200_returns_two_factor_challenge_then_passes_methods_with_nonce() {
        // Given
        let response = Data("""
        {"success":true,"data":{"user_id":1234,
        "two_step_nonce_backup":"backup-nonce","two_step_nonce_webauthn":"webauthn-nonce",
        "two_step_supported_auth_types":["backup","webauthn"]}}
        """.utf8)
        stub(condition: isOAuthTokenRequest) { _ in
            HTTPStubsResponse(data: response, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        let callback = expectation(description: "The 2FA callback receives the challenge and methods")
        let facade = WordPressComOAuthClientFacade(client: "Fake", secret: "Fake")

        // When
        facade.authenticate(username: "fakeUser", password: "fakePassword", multifactorCode: nil, success: { _ in
            XCTFail("The login should require a 2FA code")
        }, needsMultifactor: { userID, nonceInfo, supportedAuthTypes in
            // Then
            XCTAssertEqual(userID, 1234)
            XCTAssertEqual(nonceInfo?.nonceWebauthn, "webauthn-nonce")
            XCTAssertEqual(supportedAuthTypes, ["backup", "webauthn"])
            callback.fulfill()
        }, failure: { _ in
            XCTFail("The challenge response should use the multifactor callback")
        })

        wait(for: [callback], timeout: 2)
    }
}
