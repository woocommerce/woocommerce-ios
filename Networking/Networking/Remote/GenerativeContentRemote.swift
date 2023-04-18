import Foundation

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
        let parameters = [ParameterKey.textContent: base]
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
    }
}
