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
}
