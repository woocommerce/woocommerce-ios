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

    /// Generates text from an image to answer a question or as the caption.
    /// - Parameters:
    ///   - siteID: WPCOM ID of the site.
    ///   - imageURL: URL of the image.
    ///   - question: If `nil`, a caption is generated for the image instead of answering a question.
    /// - Returns: AI-generated text based on the image.
    func generateTextFromImage(siteID: Int64, imageURL: String, question: String?) async throws -> String
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

    public func generateTextFromImage(siteID: Int64, imageURL: String, question: String?) async throws -> String {
        let url = "https://api.replicate.com/v1/predictions"
        let headers = [
            "Authorization": ""
        ]
        // Ref: https://replicate.com/andreasjansson/blip-2/api
        let questionOrCaptionParameter: [String: Any] = question.map { ["question": $0, "caption": false] } ?? ["caption": true]
        let parameters: [String: Any] = [
            "version": "4b32258c42e9efd4288bb9910bc532a69727f9acd26aa08e175713a0a857a608",
            "input": [
                "image": imageURL,
                "context": "product of an eCommerce store"
            ].merging(questionOrCaptionParameter) { (current, _) in current }
        ]
        let request = ExternalRequest(method: .post, url: url, parameters: parameters, headers: headers)
        let response: ReplicatePredictionResponse = try await enqueue(request)

        // Fetches result every 1 second until a result is available.
        var output: String?
        while output == nil {
            try await Task.sleep(nanoseconds: UInt64(1 * NSEC_PER_SEC))
            let url = "https://api.replicate.com/v1/predictions/\(response.id)"
            let request = ExternalRequest(method: .get, url: url, headers: headers)
            do {
                let predictionResult: ReplicatePredictionResult = try await enqueue(request)
                guard predictionResult.status == "succeeded", let outputResult = predictionResult.output else {
                    continue
                }
                output = outputResult
            } catch {
                print("Replicate fetch error: \(error)")
            }
        }

        guard let output else {
            throw NetworkError.timeout
        }
        return output
    }
}

private struct ReplicatePredictionResponse: Decodable {
    let id: String
}

private struct ReplicatePredictionResult: Decodable {
    let status: String
    let output: String?
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
