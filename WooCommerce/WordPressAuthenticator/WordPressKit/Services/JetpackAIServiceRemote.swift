import Foundation

public final class JetpackAIServiceRemote: SiteServiceRemoteWordPressComREST {
    /// Returns short-lived JWT token (lifetime is in minutes).
    public func getAuthorizationToken() async throws -> String {
        struct Response: Decodable {
            let token: String
        }
        let path = path(forEndpoint: "sites/\(siteID)/jetpack-openai-query/jwt", withVersion: ._2_0)
        let response = await wordPressComRestApi.perform(.post, URLString: path, type: Response.self)
        return try response.get().body.token
    }

    /// - parameter token: Token retrieved using ``JetpackAIServiceRemote/getAuthorizationToken``.
    public func transcribeAudio(from fileURL: URL, token: String) async throws -> String {
        let path = path(forEndpoint: "jetpack-ai-transcription?feature=voice-to-content", withVersion: ._2_0)
        let file = FilePart(parameterName: "audio_file", url: fileURL, fileName: "voice_recording", mimeType: "audio/m4a")
        let result = await wordPressComRestApi.upload(URLString: path, httpHeaders: [
            "Authorization": "Bearer \(token)"
        ], fileParts: [file])
        guard let body = try result.get().body as? [String: Any],
              let text = body["text"] as? String else {
            throw URLError(.unknown)
        }
        return text
    }
}
