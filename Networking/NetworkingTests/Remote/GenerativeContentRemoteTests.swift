import TestKit
import XCTest
import protocol Alamofire.URLRequestConvertible
@testable import Networking

final class GenerativeContentRemoteTests: XCTestCase {
    /// Mock Network Wrapper
    ///
    let network = MockNetwork()

    /// Sample Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - `generateText`

    func test_generateText_with_success_returns_generated_text() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "text-completion", filename: "generative-text-success")

        // When
        let generatedText = try await remote.generateText(siteID: sampleSiteID,
                                                          base: "generate a product description for wapuu pencil",
                                                          feature: .productDescription)

        // Then
        XCTAssertEqual(generatedText, "The Wapuu Pencil is a perfect writing tool for those who love cute things.")
    }

    func test_generateText_with_failure_returns_error() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "text-completion", filename: "generative-text-failure")

        // When
        await assertThrowsError {
            _ = try await remote.generateText(siteID: sampleSiteID,
                                              base: "generate a product description for wapuu pencil",
                                              feature: .productDescription)
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "inactive", message: "OpenAI features have been disabled")
        }
    }

    func test_generateText_with_failure_returns_error_when_token_generation_fails() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-failure")
        network.simulateResponse(requestUrlSuffix: "text-completion", filename: "generative-text-failure")

        // When
        await assertThrowsError {
            _ = try await remote.generateText(siteID: sampleSiteID,
                                              base: "generate a product description for wapuu pencil",
                                              feature: .productDescription)
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "oauth2_invalid_token", message: "The OAuth2 token is invalid.")
        }
    }

    func test_generateText_retries_after_regenarating_token_upon_receiving_403_error() async throws {
        // Given
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        let textCompletionPath = "text-completion"
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: jwtRequestPath, filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: textCompletionPath, filename: "generative-text-success")

        // When
        _ = try await remote.generateText(siteID: sampleSiteID,
                                          base: "generate a product description for wapuu pencil",
                                          feature: .productDescription)
        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)

        // When
        _ = try await remote.generateText(siteID: sampleSiteID,
                                          base: "generate a product description for wapuu pencil",
                                          feature: .productDescription)

        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)


        // When
        network.simulateResponse(requestUrlSuffix: textCompletionPath, filename: "generative-text-invalid-token")
        _ = try? await remote.generateText(siteID: sampleSiteID,
                                           base: "generate a product description for wapuu pencil",
                                           feature: .productDescription)

        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 2)
        XCTAssertEqual(numberOfTextCompletionRequests(in: network.requestsForResponseData), 4)
    }

    // MARK: - `identifyLanguage`

    func test_identifyLanguage_with_success_returns_language_code() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "text-completion", filename: "identify-language-success")

        // When
        let language = try await remote.identifyLanguage(siteID: sampleSiteID,
                                                              string: "Woo is awesome.",
                                                              feature: .productDescription)

        // Then
        XCTAssertEqual(language, "en")
    }

    func test_identifyLanguage_with_failure_returns_error() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: "text-completion", filename: "identify-language-failure")

        // When
        await assertThrowsError {
            _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                                  string: "Woo is awesome.",
                                                  feature: .productDescription)
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "inactive", message: "OpenAI features have been disabled")
        }
    }

    func test_identifyLanguage_with_failure_returns_error_when_token_generation_fails() async throws {
        // Given
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/jetpack-openai-query/jwt", filename: "jwt-token-failure")
        network.simulateResponse(requestUrlSuffix: "text-completion", filename: "identify-language-failure")

        // When
        await assertThrowsError {
            _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                                  string: "Woo is awesome.",
                                                  feature: .productDescription)
        } errorAssert: { error in
            // Then
            error as? WordPressApiError == .unknown(code: "oauth2_invalid_token", message: "The OAuth2 token is invalid.")
        }
    }

    func test_identifyLanguage_retries_after_regenarating_token_upon_receiving_403_error() async throws {
        // Given
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        let textCompletionPath = "text-completion"
        let remote = GenerativeContentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: jwtRequestPath, filename: "jwt-token-success")
        network.simulateResponse(requestUrlSuffix: textCompletionPath, filename: "identify-language-success")

        // When
        _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                              string: "Woo is awesome.",
                                              feature: .productDescription)
        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)

        // When
        _ = try await remote.identifyLanguage(siteID: sampleSiteID,
                                              string: "Woo is awesome.",
                                              feature: .productDescription)

        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 1)


        // When
        network.simulateResponse(requestUrlSuffix: textCompletionPath, filename: "identify-language-invalid-token")
        _ = try? await remote.identifyLanguage(siteID: sampleSiteID,
                                               string: "Woo is awesome.",
                                               feature: .productDescription)

        // Then
        XCTAssertEqual(numberOfJwtRequests(in: network.requestsForResponseData), 2)
        XCTAssertEqual(numberOfTextCompletionRequests(in: network.requestsForResponseData), 4)
    }
}

// MARK: - Helpers
//
private extension GenerativeContentRemoteTests {
    func numberOfJwtRequests(in array: [URLRequestConvertible]) -> Int {
        let jwtRequestPath = "sites/\(sampleSiteID)/jetpack-openai-query/jwt"
        return array.filter({ request in
            guard let dotcomRequest = request as? DotcomRequest else {
                return false
            }
            return dotcomRequest.path == jwtRequestPath
        }).count
    }

    func numberOfTextCompletionRequests(in array: [URLRequestConvertible]) -> Int {
        let textCompletionPath = "text-completion"
        return array.filter({ request in
            guard let dotcomRequest = request as? DotcomRequest else {
                return false
            }
            return dotcomRequest.path == textCompletionPath
        }).count
    }
}
