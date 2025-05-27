import XCTest
@testable import Networking

final class CookieNonceAuthenticatorTests: XCTestCase {

    private let loginURL = URL(string: "https://example.com/wp-login.php")!
    private let adminURL = URL(string: "https://example.com/wp-admin/")!
    private let apiRequest = URLRequest(url: URL(string: "https://example.com/wp-json/")!)
    private let sampleUser = "user123"
    private let samplePassword = "password *+/$&=2+é"

    func test_cookie_nonce_authenticator_encode_parameters_correctly() throws {
        // Given
        let config = CookieNonceAuthenticatorConfiguration(username: sampleUser,
                                                           password: samplePassword,
                                                           loginURL: loginURL,
                                                           adminURL: adminURL)
        let authenticator = CookieNonceAuthenticator(configuration: config)


        let generatedBodyAsData = try XCTUnwrap(authenticator.authenticatedRequest().urlRequest?.httpBody)
        let generatedBodyAsString = try XCTUnwrap(String(data: generatedBodyAsData, encoding: .utf8))
        let generatedBodyParameters = generatedBodyAsString.split(separator: Character("&"))

        // When
        /// Expected parameters with encoded data
        ///
        let expectedParameters = ["log": "user123", "pwd": "password%20*%2B/$%26%3D2%2B%C3%A9", "rememberme": "true"]

        // Then
        /// Note: As of iOS 12 the parameters were being serialized at random positions. That's *why* this test is a bit extra complex!
        ///
        for parameter in generatedBodyParameters {
            let components = parameter.split(separator: Character("="))
            let key = String(components[0])
            let value = String(components[1])

            XCTAssertEqual(value, expectedParameters[key])
        }
    }
}
