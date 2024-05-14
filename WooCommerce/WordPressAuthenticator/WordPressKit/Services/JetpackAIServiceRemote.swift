import Foundation

public final class JetpackAIServiceRemote: SiteServiceRemoteWordPressComREST {
    /// Returns short-lived JWT token (lifetime is in minutes).
    public func getJWT() async throws -> String {
        struct Response: Decodable {
            let token: String
        }
        let path = path(forEndpoint: "sites/\(siteID)/jetpack-openai-query/jwt", withVersion: ._2_0)
        let response = await wordPressComRestApi.perform(.post, URLString: path, type: Response.self)
        return try response.get().body.token
    }
}
