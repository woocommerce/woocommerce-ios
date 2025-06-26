import Networking
import XCTest

/// Mock for `GenerativeContentRemote`.
///
final class MockGenerativeContentRemote {
    private(set) var generateTextBase: String?
    private(set) var generateTextFeature: GenerativeContentRemoteFeature?
    private(set) var generateTextResponseFormat: GenerativeContentRemoteResponseFormat?

    /// The results to return in `generateText`.
    private var generateTextResult: Result<String, Error>?

    /// Returns the value when `generateText` is called.
    func whenGeneratingText(thenReturn result: Result<String, Error>) {
        generateTextResult = result
    }

    private(set) var identifyLanguageString: String?
    private(set) var identifyLanguageFeature: GenerativeContentRemoteFeature?

    /// The results to return in `identifyLanguage`.
    private var identifyLanguageResult: Result<String, Error>?

    /// Returns the value when `identifyLanguage` is called.
    func whenIdentifyingLanguage(thenReturn result: Result<String, Error>) {
        identifyLanguageResult = result
    }

    /// The results to return in `generateAIProduct`.
    private var generateAIProduct: Result<AIProduct, Error>?

    /// Returns the value when `generateProduct` is called.
    func whenGeneratingAIProduct(thenReturn result: Result<AIProduct, Error>) {
        generateAIProduct = result
    }
}

extension MockGenerativeContentRemote: GenerativeContentRemoteProtocol {
    func generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature,
                      responseFormat: GenerativeContentRemoteResponseFormat) async throws -> String {
        generateTextBase = base
        generateTextFeature = feature
        generateTextResponseFormat = responseFormat
        guard let result = generateTextResult else {
            XCTFail("Could not find result for generating text.")
            throw NetworkError.notFound()
        }
        return try result.get()
    }

    func identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature) async throws -> String {
        identifyLanguageString = string
        identifyLanguageFeature = feature
        guard let result = identifyLanguageResult else {
            XCTFail("Could not find result for generating text.")
            throw NetworkError.notFound()
        }
        return try result.get()
    }

    func generateAIProduct(siteID: Int64,
                           productName: String?,
                           keywords: String,
                           language: String,
                           tone: String,
                           currencySymbol: String,
                           dimensionUnit: String?,
                           weightUnit: String?,
                           categories: [ProductCategory],
                           tags: [ProductTag]) async throws -> AIProduct {
        guard let result = generateAIProduct else {
            XCTFail("Could not find result for generating product.")
            throw NetworkError.notFound()
        }
        return try result.get()
    }
}
