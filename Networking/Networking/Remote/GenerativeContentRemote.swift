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
    private enum GenerativeContentRemoteError: Error {
        case tokenNotFound
    }

    private var token: String?

    public func generateText(siteID: Int64,
                             base: String,
                             feature: GenerativeContentRemoteFeature) async throws -> String {
        do {
            guard let token else {
                throw GenerativeContentRemoteError.tokenNotFound
            }
            return try await generateText(siteID: siteID, base: base, feature: feature, token: token)
        } catch GenerativeContentRemoteError.tokenNotFound,
                    WordPressApiError.unknown(code: TokenExpiredError.code, message: TokenExpiredError.message) {
            let token = try await fetchToken(siteID: siteID)
            self.token = token
            return try await generateText(siteID: siteID, base: base, feature: feature, token: token)
        }
    }

    public func identifyLanguage(siteID: Int64,
                                 string: String,
                                 feature: GenerativeContentRemoteFeature) async throws -> String {
        do {
            guard let token else {
                throw GenerativeContentRemoteError.tokenNotFound
            }
            return try await identifyLanguage(siteID: siteID, string: string, feature: feature, token: token)
        } catch GenerativeContentRemoteError.tokenNotFound,
                    WordPressApiError.unknown(code: TokenExpiredError.code, message: TokenExpiredError.message) {
            let token = try await fetchToken(siteID: siteID)
            self.token = token
            return try await identifyLanguage(siteID: siteID, string: string, feature: feature, token: token)
        }
    }
}

private extension GenerativeContentRemote {
    func fetchToken(siteID: Int64) async throws -> String {
        let path = "sites/\(siteID)/\(Path.jwtToken)"
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path)
        let mapper = JWTTokenResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }

    func generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature,
                      token: String) async throws -> String {
        let parameters = [ParameterKey.token: token,
                          ParameterKey.prompt: base,
                          ParameterKey.feature: feature.rawValue]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: Path.textCompletion,
                                    parameters: parameters)
        let mapper = TextCompletionResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }

    func identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature,
                          token: String) async throws -> String {
        let prompt = [
            "What is the ISO language code of the language used in the below text?" +
            "Do not include any explanations and only provide the ISO language code in your response.",
            "Text: ```\(string)```"
        ].joined(separator: "\n")
        let parameters = [ParameterKey.token: token,
                          ParameterKey.prompt: prompt,
                          ParameterKey.feature: feature.rawValue]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: Path.textCompletion,
                                    parameters: parameters)
        let mapper = TextCompletionResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

// MARK: - Constants
//
private extension GenerativeContentRemote {
    enum Path {
        static let textCompletion = "text-completion"
        static let jwtToken = "jetpack-openai-query/jwt"
    }

    enum ParameterKey {
        static let token = "token"
        static let prompt = "prompt"
        static let feature = "feature"
    }

    enum TokenExpiredError {
        static let code = "rest_forbidden"
        static let message = "Sorry, you are not allowed to do that."
    }
}

// MARK: - Mapper to parse the JWT token
//
private struct JWTTokenResponseMapper: Mapper {
    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()
        return try decoder.decode(JWTTokenResponse.self, from: response).token
    }

    struct JWTTokenResponse: Decodable {
        let token: String
    }
}

// MARK: - Mapper to parse the `text-completion` endpoint response
//
private struct TextCompletionResponseMapper: Mapper {
    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()
        return try decoder.decode(TextCompletionResponse.self, from: response).completion
    }

    struct TextCompletionResponse: Decodable {
        let completion: String
    }
}
