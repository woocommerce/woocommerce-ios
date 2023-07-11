import Foundation

/// Used by backend to track AI-generation usage and measure costs
public enum GenerativeContentRemoteFeature: String {
    case productDescription = "woo_ios_product_description"
    case productSharing = "woo_ios_share_product"
    case productDetailsFromScannedTexts = "woo_ios_product_details_from_scanned_texts"
}

/// Protocol for `GenerativeContentRemote` mainly used for mocking.
///
public protocol GenerativeContentRemoteProtocol {
    /// Generates text based on the given prompt using Jetpack AI. Currently, Jetpack AI is only supported for sites hosted on WPCOM.
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - base: Prompt for the AI-generated text.
    ///   - feature: Used by backend to track AI-generation usage and measure costs
    /// - Returns: AI-generated text based on the prompt if Jetpack AI is enabled.
    func generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature) async throws -> String

    /// Identifies the language from the given string
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - string: String from which we should identify the language
    ///   - feature: Used by backend to track AI-generation usage and measure costs
    /// - Returns: ISO code of the language
    func identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature) async throws -> String
}

/// Product: Remote Endpoints
///
public final class GenerativeContentRemote: Remote, GenerativeContentRemoteProtocol {
    public func generateText(siteID: Int64,
                             base: String,
                             feature: GenerativeContentRemoteFeature) async throws -> String {
        let token = try await generateJetpackAIToken(siteID: siteID)

        /// We are skipping cache entirely to avoid showing outdated/duplicated text.
        let parameters = ["prompt": base,
                          "token": token, // completion
                          ParameterKey.feature: feature.rawValue]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: Path.wooAIText, parameters: parameters)
        let response: TextCompletionResponse = try await enqueue(request)
        return response.completion
    }

    public func identifyLanguage(siteID: Int64,
                                 string: String,
                                 feature: GenerativeContentRemoteFeature) async throws -> String {
        let path = "sites/\(siteID)/\(Path.text)"
        let prompt = [
            "What is the ISO language code of the language used in the below text?" +
            "Do not include any explanations and only provide the ISO language code in your response.",
            "Text: ```\(string)```"
        ].joined(separator: "\n")

        /// We are skipping cache entirely to avoid showing outdated/duplicated text.
        let parameters = [ParameterKey.textContent: prompt,
                          ParameterKey.skipCache: "true",
                          ParameterKey.feature: feature.rawValue]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path, parameters: parameters)
        return try await enqueue(request)
    }
}

private extension GenerativeContentRemote {
    func generateJetpackAIToken(siteID: Int64) async throws -> String {
        let path = Path.token(siteID: siteID)
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path)
        let response: TokenResponse = try await enqueue(request)
        guard response.success else {
            throw GenerateTokenError.unsuccessful
        }
        return response.token
    }
}

// MARK: - Constants
//
private extension GenerativeContentRemote {
    enum Path {
        static let text = "jetpack-ai/completions"
        static let wooAIText = "text-completion"
        static func token(siteID: Int64) -> String {
            "sites/\(siteID)/jetpack-openai-query/jwt"
        }
    }

    enum ParameterKey {
        static let textContent = "content"
        static let skipCache = "skip_cache"
        static let feature = "feature"
    }
}

private enum GenerateTokenError: Error {
    case unsuccessful
}

private struct TextCompletionResponse: Decodable {
    let completion: String
}

private struct TokenResponse: Decodable {
    let success: Bool
    let token: String
}
