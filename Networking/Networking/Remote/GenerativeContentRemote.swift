import Foundation

/// Used by backend to track AI-generation usage and measure costs
public enum GenerativeContentRemoteFeature: String {
    case productDescription = "woo_ios_product_description"
    case productSharing = "woo_ios_share_product"
}

/// Protocol for `GenerativeContentRemote` mainly used for mocking.
///
public protocol GenerativeContentRemoteProtocol {
    /// Generates text based on the given prompt using Jetpack AI. Currently, Jetpack AI is only supported for sites hosted on WPCOM.
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - base: Prompt for the AI-generated text.
    /// - Returns: AI-generated text based on the prompt if Jetpack AI is enabled.
    func generateText(siteID: Int64, base: String) async throws -> String
}

/// Product: Remote Endpoints
///
public final class GenerativeContentRemote: Remote, GenerativeContentRemoteProtocol {
    public func generateText(siteID: Int64, base: String) async throws -> String {
        let path = "sites/\(siteID)/\(Path.text)"
        /// We are skipping cache entirely to avoid showing outdated/duplicated text.
        let parameters = [ParameterKey.textContent: base, ParameterKey.skipCache: "true"]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .post, path: path, parameters: parameters)
        return try await enqueue(request)
    }
}

// MARK: - Constants
//
private extension GenerativeContentRemote {
    enum Path {
        static let text = "jetpack-ai/completions"
    }

    enum ParameterKey {
        static let textContent = "content"
        static let skipCache = "skip_cache"
    }
}
